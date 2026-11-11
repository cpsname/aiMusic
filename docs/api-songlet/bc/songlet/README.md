# Songlet(小曲)BC — 端点契约

> **读者**:Songlet iOS 客户端工程师 · 本仓运维
> **前置**:先读 [`_common/overview.md`](../../_common/overview.md)(信封 / 双层鉴权 / 错误段)。
> **契约事实源**:平台仓 `docs/contracts/songlet/02-openapi.yaml`(字段形状)与 `04-errors.md`(错误码总表)。
> 本文只写**本仓实现层**的事实:哪条路由在哪、闸门与限流、哪些码由本仓产生。字段形状以契约为准,不在这里抄第二份。
>
> **错误码段**:49300-49349 + 50360 · **表前缀**:`sgl_` · **路由**:客户端冻结契约的**顶层段**(见 §1.1)

---

## 0. 本 BC 做什么、不做什么

Songlet 是一个 **BFF**:客户端只认一个 BaseURL(产品域),本 BC 把它的请求翻成平台调用。

| 做 | 不做(全在平台) |
|---|---|
| 请求校验 · 服务端预检(艺人名 / 模仿句式 / 歌词指纹) | 内容审核(平台 45100 / 45120) |
| 提示词装配(`infra/promptcfg/prompt.yaml`) | 生成、排队、重试、超时 |
| 层级投影(已同步交易台账 `sgl_synced_transactions`) | 积分冻结 / 结算 / 退款、订单核验、发放 |
| 作业流水(`sgl_generation_events`,append-only) | 音频字节与签名 URL |
| 商用许可 PDF(编号由任务 bid 确定性派生,无表) | 下载资助撤销标记(平台 `billing.funding_revoked`) |

**本仓没有任何钱包 / 积分代码**。`credits_charged`、`songs_left`、`clips_left` 全部来自平台的读数。

---

## 1. 🔴 三条会让你写错的边界

### 1.1 路由是通用顶层段,且**只服务 Songlet 分发**

客户端按 `/v1/generate`、`/v1/jobs/:bid` 这类顶层路径实现(冻结契约,零改动接后端)。
这些段落在**全部产品 App 共用**的产品域上,所以每条路由首个中间件都是分发闸:
签名里的分发码不在 `songlet.distributions` 配置内 → **HTTP 404 + `40404`**。
对别的 App 来说这些路由不存在。

`/v1/app/config` 与 `/v1/uploads/*` 同时是**平台**的段:本 BC 只代理契约里那三条,
平台同段下的其它端点在产品域上**不存在**(它们只在平台域)。

### 1.2 提交类遇平台不可达返 **200 + 50360**,不是 503

客户端对 5xx 会透明重发请求。只读端点返 503 正是想要的(自动重试);
`POST /v1/generate` 返 503 会让客户端重发提交 —— 虽然 `client_ref` 让重发幂等,
契约仍按「提交类不借传输层重试」处理。

### 1.3 `app_account_token` 不是身份

请求体里的 `app_account_token` 只用来与 `X-Device-ID` 比对(不一致 → `40001`)。
身份**只**来自 JWT 的 `abid`。StoreKit 购买时写进交易的 `appAccountToken` 是 **abid**(不是设备 ID)。

---

## 2. 端点

鉴权列:**签名** = App 签名四头;**JWT** = 签名 + `Authorization: Bearer <device_token>`。
全部端点先过 §1.1 的分发闸。

| 方法 | 路径 | 鉴权 | 限流 | 说明 |
|---|---|---|---|---|
| POST | `/v1/attest` | 签名 | 按 IP(`songlet.public_rate_per_minute`) | App Attest → 平台游客注册 → `device_token`(平台 HS256 令牌) |
| GET | `/v1/app/config` | 签名 | 按 IP(同上) | 平台 `GET /v1/app/config` 原样透传(BFF 以同一分发重签) |
| POST | `/v1/generate` | JWT | 按账户(全局) | 提交片段 / 完整歌 / 图片歌;`client_ref` 幂等 |
| GET | `/v1/jobs/:bid` | JWT | 按账户 | 轮询;终态带结果与余额 |
| DELETE | `/v1/jobs/:bid` | JWT | 按账户 | 取消(排队中退款;运行中不退) |
| GET | `/v1/templates` | JWT | 按账户 | 16 个模板的 30 秒示例音频 |
| POST | `/v1/entitlements/sync` | JWT | 按账户 | 提交 Apple 签名交易 → 层级与余额 |
| GET | `/v1/license/:bid` | JWT | 按账户 | 商用许可 PDF(同时是下载门禁) |
| POST | `/v1/uploads/sign` | JWT | 按账户 | 平台上传预签名透传 |
| POST | `/v1/uploads/finalize` | JWT | 按账户 | 平台完成上传透传 |

路径参数 `:bid` = 平台任务 bid(客户端契约里叫 `job_id`,同一个值)。

### 2.1 `POST /v1/generate` 的服务端流程

1. **校验**:取值集(model / occasion / template / region)、长度上界、图片数与模型匹配。
2. **预检**(零上游调用、零扣费):艺人名黑名单、「in the style of …」类模仿句式、
   对收件人的模仿、歌词指纹(与客户端同算法)。命中 → `49301`,`details.stage = "preflight"`,
   **不回显**命中的规则或词。
3. **付费墙**:完整歌只对付费档开放(免费档 → `49303`)。
4. **装配**提示词并提交平台管线(片段 / 完整歌 / 图片歌三条),幂等键 = 账户 + `client_ref`。
5. 平台冻结积分;余额不足 → `49303`,每日上限 → `49311`,平台审核拒绝 → `49301` / `49302`。

### 2.2 `GET /v1/license/:bid`

仅当任务 `succeeded`、**付费档**、且资助订单未退款时返回 PDF。响应头:

| 头 | 值 |
|---|---|
| `X-License-Id` | `SL-YYYYMMDD-XXXXXX`(由任务 bid 确定性派生,重复下载同一编号) |
| `X-License-Issued-At` | 任务完成时间(RFC 3339) |
| `Content-Disposition` | `attachment; filename="songlet-license-<任务 bid>.pdf"` |

---

## 3. 错误码(本 BC 产生)

HTTP:业务拒绝 **200**;鉴权类 **401**;分发闸 **404**;平台不可达见 §1.2。
客户端按 `details.error_code` **字符串**分派,数字码用于日志与监控。

| 码 | HTTP | `details.error_code` | 触发 |
|---|---|---|---|
| 40001 | 200 | — | 校验失败;`details` 是字段 → 固定英文原因的 map |
| 40102 | 401 | — | 缺少或无效的账户身份 |
| 40140 | 401 | `ATTEST_FAILED` | 平台 App Attest 校验失败 |
| 40401 | 200 | — | 任务不存在或不属本账户(两者不区分) |
| 40404 | 404 | — | 分发闸:非 Songlet 分发(§1.1) |
| 49301 | 200 | `SAFETY_BLOCKED` | 预检命中(`stage=preflight`)或平台审核拒绝(`stage=platform`) |
| 49302 | 200 | `IMAGE_REJECTED` | 平台参考图审核拒绝 |
| 49303 | 200 | `QUOTA_EXHAUSTED` | 余额不足 / 免费档请求完整歌 |
| 49307 | 200 | `DOWNLOAD_LOCKED` | 许可门禁:免费档或资助订单已退款 |
| 49309 | 200 | `JOB_ALREADY_FINISHED` / `JOB_NOT_FINISHED` | 取消已终态任务 / 为未成功任务索取许可 |
| 49311 | 200 | `DAILY_LIMIT_REACHED` | 平台分发级每日提交上限 |

另有两个 5xx 码:`50360`(平台不可达或平台配置事故,`details.error_code = UPSTREAM_TIMEOUT`)
与 `50000`(本仓内部缺陷)。

**任务终态的 `error_code`**(`GET /v1/jobs/:bid` 的 `error_code` 字段,不是信封码)按平台失败族归类:
`SAFETY_BLOCKED` · `IMAGE_REJECTED`(有参考图时的内容过滤)· `UPSTREAM_RATE_LIMITED` · `USER_CANCELLED` ·
其余一律 `UPSTREAM_TIMEOUT`。

**平台码透传**:平台给出本 BC 未专门分派的确定性业务拒绝时,原码与原文案透传(鉴权族用 401)。
可能出现的码与客户端动作见契约 `04-errors.md` §2.1。

---

## 4. 运维须知

| 事实 | 出处 |
|---|---|
| 分发闸与游客注册读同一份 `songlet.distributions`;prod 缺它进程启动即失败 | `internal/platform/config/config.go` 的 songlet 校验 |
| 商品目录 `songlet.products`(code → 档位 / 种类)只做层级投影;发多少积分由平台商品行决定 | 同上 |
| 作业流水表 400 天保留,由超级用户带外删除 | [`docs/ops/songlet-events-retention.sql`](../../../ops/songlet-events-retention.sql) |
| 本 BC 没有后台循环(无 worker);平台不可达时一切失败都在请求内返回 | `internal/songlet/fx_module.go` |
