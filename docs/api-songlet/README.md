<!-- 此文件由 genaistudio-products 的 scripts/api-bundle.sh 生成, 请勿手改 -->

> **这份包**:产品 `songlet` · 源版本 `8a44d52-dirty` · 打包于 2026-09-24 21:53 UTC
> **内容**:`_common/overview.md`(共用约定)+ `bc/songlet/` + 本文(产品入口)
> **不含**:其它产品的分册, 以及产品仓 `docs/api/internal/`(中台契约与跨仓契约, 不面向 App)
>
> 🔄 **怎么拿到新版**:找产品仓的人跑 `make api-bundle PRODUCT=songlet` 重出一份。
> **不要手工改这份拷贝** —— 改了之后它既不是契约也不是事实, 而下一次重出会覆盖掉。
> 发现文档与接口行为对不上时, **先比对上面的源版本**, 再判断是文档错了还是这份拷贝旧了。

---

# Songlet(小曲)— 客户端对接入口

> **这是导航与时序, 不是端点手册。** 端点明细在 [bc/songlet](bc/songlet/README.md),
> 字段形状以平台仓 `docs/contracts/songlet/02-openapi.yaml` 为准。
>
> 共用约定(信封 / 双层鉴权 / 错误码分段)见 [overview.md](_common/overview.md)。

---

## 0. 三十秒版

| 域名 | 服务 | 你从这里拿什么 |
|---|---|---|
| `genaistudio-products.showsapp.org` | **产品层**(本仓) | **全部** —— attest · 远程配置 · 生成 · 轮询 · 取消 · 模板 · 权益同步 · 许可 · 上传 |

🔑 **Songlet 是唯一的单 BaseURL 产品。** 其它产品 App 登录与上传打平台域;
Songlet 客户端只配一个 BaseURL(产品域),本仓把 attest / 远程配置 / 上传**代理**到平台。
所以 Songlet 客户端**不需要知道平台域**。

签名用的分发码:生产 `com.songlet.ios`。本仓只对 `songlet.distributions` 里登记的分发
开放这些路由(其它 App 打过来是 404,见 [bc/songlet](bc/songlet/README.md) §1.1)。

### 当前可用性(2026-09-25)

| 能力 | 状态 |
|---|---|
| 全部 10 个端点 | 🟡 **服务端已实现**, 等平台侧开闸 —— 见 §4 |

🔴 **分发 `com.songlet.ios` 已铸种但处于 `disabled`**,5 个内购商品处于未上架 ⇒ 现在签名过不去。
开闸是平台侧数据的事,不需要改客户端代码。

---

## 1. 该读哪几本(按这个顺序)

| # | 文档 | 为什么在这个位置 |
|---|---|---|
| 1 | [overview.md](_common/overview.md) | 信封 / App 签名 / JWT / §3.4 身份纪律 |
| 2 | **本文 §2 · §3** | 启动、生成、购买三条时序 + 必须遵守的约束 |
| 3 | [bc/songlet](bc/songlet/README.md) | 10 个端点、分发闸、本仓产生的错误码 |
| 4 | 平台仓 `docs/contracts/songlet/04-errors.md` | 错误码总表(含平台透传码与客户端动作) |

---

## 2. 时序

### 2.1 启动

```
GET  /v1/app/config                      (签名)     kill switch / 维护态
POST /v1/attest                          (签名)     App Attest → device_token(= 平台游客账号令牌)
POST /v1/entitlements/sync {signed_transactions: []}   取层级与余额
```

`device_token` 的 `abid` claim 是账户 UUID,购买时写进 StoreKit 的 `appAccountToken`。

### 2.2 生成

```
POST   /v1/generate {client_ref, …}      → job_id + credits_charged
GET    /v1/jobs/:bid                     轮询到终态;成功带 audio_url / lyrics / structure / balances
DELETE /v1/jobs/:bid                     排队中取消会退款;运行中不退
GET    /v1/license/:bid                  下载前先调:它同时是下载门禁
```

照片歌先走 `POST /v1/uploads/sign` → 直传对象存储 → `POST /v1/uploads/finalize`,
再把得到的上传 key 放进 `images`。

### 2.3 购买

```
StoreKit 购买(appAccountToken = abid)
POST /v1/entitlements/sync {app_account_token: <设备 UUID>, signed_transactions: [...]}
```

核验、发放积分、订阅续期全在平台。换设备时提交旧账户的交易,服务端会把本设备重绑到旧账户,
当前令牌随之失效:下一请求 40102 → 重新 attest 即得旧账户。

---

## 3. 必须遵守的约束

1. **`client_ref` 每次提交新生成、重试时复用**。它是提交幂等键,重发同一个值不会重复扣费。
2. **平台不可达时 `POST /v1/generate` 返 200 + 50360**,不是 5xx。只读端点返 503,可以自动重试。
3. **按 `details.error_code` 字符串分派**,不要按数字码或 `message`。
4. **音频 URL 是临时签名链接**,每次轮询都可能换新;保存作品要把文件落到设备上。
5. **请求体里的 `app_account_token` 不是身份**,只与 `X-Device-ID` 比对。

---

## 4. 上线自检(平台侧开闸之后)

| # | 检查 | 期望 |
|---|---|---|
| 1 | 不带签名打 `GET /v1/templates` | 401 |
| 2 | 用别的产品分发签名打 `GET /v1/templates` | 404 + `40404` |
| 3 | `POST /v1/attest` 后打 `GET /v1/templates` | 16 个模板 |
| 4 | 免费档提交片段后轮询到终态 | `succeeded`,余额减少一个片段价 |
| 5 | 免费档请求 `GET /v1/license/:bid` | `49307 DOWNLOAD_LOCKED` |
