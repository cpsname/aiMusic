# genaistudio-products API 总览 — 跨 BC 共用约定

> 读者:各产品客户端工程师 —— **divination**(占卜 + 咨询师)· **echonote**(听语)
> · fashiondress(Muse)· feastly。
> 本文件是**唯一的共用约定源**:信封、鉴权、错误码分段、分页、幂等、i18n。
> 各 BC 的端点明细见下表的分册,分册**不重复**本文内容。
>
> ⚠️ 本仓是**产品层**。AI 能力(生成 / 计费 / 钱包 / IAP / 上传)全部在下游平台
> `genaistudio`(:9999),其契约见平台仓 `docs/api/`。两者是**不同的服务**,
> 只是经 nginx 落在同一个域名下 —— 见 §7。

---

## 1. 我该读哪几本?

### 1.1 按产品(客户端从这里进)

**分册是按 BC 切的, 而一个产品用到好几个 BC。** 下表是产品 → 分册的映射;
`products/*.md` 是**对接指南**(跨服务时序 + 该读哪几本 + 上线自检),它**不重复端点明细**。

🔧 **这张表是机器可读的单一来源** —— `make api-bundle PRODUCT=<产品>` 就读它来决定
打哪些包(`scripts/api-bundle.sh`)。判据是每行里出现的 `bc/<名>/` ——
所以**共用分册也必须写成链接**,写成裸文字会让那个 BC 从包里静默消失。

| 产品 | 专属分册 | 共用分册 | 从哪开始 |
|---|---|---|---|
| **divination**(AI 占卜 + 咨询师) | bc/divination(未随包提供 —— 见仓内 docs/api/bc/divination/README.md) | bc/feedback(未随包提供 —— 见仓内 docs/api/bc/feedback/README.md) · bc/promotion(未随包提供 —— 见仓内 docs/api/bc/promotion/README.md) | 🚩 **products/divination(未随包提供 —— 见仓内 docs/api/products/divination.md)** |
| **songcraft**(AI 写歌) | bc/songcraft(未随包提供 —— 见仓内 docs/api/bc/songcraft/README.md) | bc/feedback(未随包提供 —— 见仓内 docs/api/bc/feedback/README.md) · bc/promotion(未随包提供 —— 见仓内 docs/api/bc/promotion/README.md) | 🚩 **products/songcraft(未随包提供 —— 见仓内 docs/api/products/songcraft.md)** |
| **echonote**(听语) | bc/echonote(未随包提供 —— 见仓内 docs/api/bc/echonote/README.md) | bc/feedback(未随包提供 —— 见仓内 docs/api/bc/feedback/README.md) · bc/promotion(未随包提供 —— 见仓内 docs/api/bc/promotion/README.md) | 🚩 **products/echonote(未随包提供 —— 见仓内 docs/api/products/echonote.md)** |
| **fashiondress**(Muse) | bc/fashiondress(未随包提供 —— 见仓内 docs/api/bc/fashiondress/README.md) | bc/feedback(未随包提供 —— 见仓内 docs/api/bc/feedback/README.md) · bc/promotion(未随包提供 —— 见仓内 docs/api/bc/promotion/README.md) | 🚩 **products/muse(未随包提供 —— 见仓内 docs/api/products/muse.md)** |
| **feastly** | bc/feastly(未随包提供 —— 见仓内 docs/api/bc/feastly/README.md) | bc/feedback(未随包提供 —— 见仓内 docs/api/bc/feedback/README.md) · bc/promotion(未随包提供 —— 见仓内 docs/api/bc/promotion/README.md) | 🚩 **products/feastly(未随包提供 —— 见仓内 docs/api/products/feastly.md)** |
| **songlet**(小曲) | [bc/songlet](../bc/songlet/README.md) | — | 🚩 **[products/songlet](../README.md)** |

songlet 行没有共用分册:它的客户端契约里没有反馈与营销端点。

⚠️ **`feedback` 与 `promotion` 不是"每个产品各一套端点"** —— 是同一套端点,
服务端按 App 签名注入的 `X-Distribution-Code` 分产品
(`fb_submissions.distribution_code` / `promo_campaigns.distribution_scope`)。
客户端**不传**任何产品标识, 传了也会被忽略(见 §3.4)。

⚠️ **咨询师目录只有一个**:六位 AI 咨询师在 `GET /v1/divination/consultants`。
曾并存的 `/v1/consultants`(consultation BC, 人工语音咨询师目录 + 在线态)已于
2026-08-23 退役 —— 人工咨询功能从未立项, 目录自建表起恒为空。
打旧路径会得到 404;错误码段 48990-48994 已标退役, 不复用。

### 1.2 按 BC(端点明细在这里)

| BC | 前缀 | 错误段 | 文档 | 状态 |
|---|---|---|---|---|
| fashiondress | `/v1/wardrobes` `/v1/style-profile` `/v1/collections` | 48000-48099 | bc/fashiondress(未随包提供 —— 见仓内 docs/api/bc/fashiondress/README.md) | ✅ 已上线 |
| feastly | `/v1/feastly` | 48100-48199 | bc/feastly(未随包提供 —— 见仓内 docs/api/bc/feastly/README.md) | ✅ 已上线 |
| promotion | `/v1/promotions` | 48850-48949 | bc/promotion(未随包提供 —— 见仓内 docs/api/bc/promotion/README.md) | ⚠️ 部分交付(核销未开放,见分册 §0) |
| feedback | `/v1/feedback` | 48950-48989 | bc/feedback(未随包提供 —— 见仓内 docs/api/bc/feedback/README.md) | ⚠️ 部分交付(仅 bug/suggestion,见分册 §0) |
| divination | `/v1/divination` | 48995-48999 | bc/divination(未随包提供 —— 见仓内 docs/api/bc/divination/README.md) | ✅ 只读(玩法路由 + 建议问题 + **咨询师体系**) |
| echonote | `/v1/echonote` | 49000-49099 | bc/echonote(未随包提供 —— 见仓内 docs/api/bc/echonote/README.md) | ✅ 已交付(29 端点;含免 JWT 的分享面) |
| songcraft | `/v1/songcraft` | 49100-49299 | bc/songcraft(未随包提供 —— 见仓内 docs/api/bc/songcraft/README.md) | ✅ 已交付(21 端点;含免 JWT 的分享面) |
| songlet | 客户端冻结契约的顶层段(`/v1/generate` `/v1/jobs` …,见分册 §1.1) | 49300-49349 | [bc/songlet](../bc/songlet/README.md) | 🟡 已实现,等平台开闸(10 端点;两条免 JWT;只服务 Songlet 分发) |

> `docs/api/internal/consumer/` 是**另一回事** —— 那是中台 `genaistudio-console` 提供给本仓
> **管理面**的契约(登录 / 菜单 / 权限判定),不面向 App 客户端。

---

## 2. 统一响应信封

**所有**端点返回同一形状:

```json
{ "code": 0, "message": "success", "data": { … },
  "request_id": "019e…", "timestamp": 1785600000 }
```

| 字段 | 说明 |
|---|---|
| `code` | **0 = 成功**;非零见 §4。⚠️ 客户端必须按 `code` 分支,**不要**按 `message` 判断(message 会随文案调整而变) |
| `message` | 英文短句,面向工程师排障,**不适合直接展示给用户** |
| `data` | 业务载荷;失败时为 `null` |
| `request_id` | 本次请求标识。⚠️ **请在客户端日志里保留它** —— 它是把用户问题对到服务端日志的唯一线索(见 §6) |
| `timestamp` | 服务端 Unix 秒 |

### HTTP 状态码与 code 的关系

| 情形 | HTTP | code |
|---|---|---|
| 成功 | 200 | 0 |
| **业务错误** | **200** | 非零 |
| 鉴权失败(未登录 / token 无效 / 签名失败) | 401 | 40102 / 40110-40114 / 40304 |
| 限流 | 429 | 42901 |
| 依赖不可达(fail-closed) | 503 | 50350 |
| **未捕获的内部错误(panic)** | **500** | 50000 |

⚠️ **业务错误走 HTTP 200**。客户端若只按 HTTP 状态码判成败,会把"券已过期""今日反馈已达上限"
这类**正常的业务结果**当成网络异常处理 —— 表现为该弹的提示不弹、该走的分支不走。
**先看 HTTP,再看 `code`,两者都要看。**

---

## 3. 鉴权

### 3.1 两层,缺一不可

```
全局:   RequestID → AccessLog → AppSignature(HMAC;仅 /healthz 豁免)
鉴权组: JWTAuth(HS256 验签 + 平台 token 黑名单)→ RateLimitByAccount
```

**免 JWT 的业务端点**:`GET /v1/echonote/shared/:token`(听语分享面)、songcraft 分享面,
以及 Songlet 的 `POST /v1/attest` 与 `GET /v1/app/config`(签名即可;attest 本身就是取令牌的那一步)。
它免 JWT 是因为分享的收件人没有听语账户 —— 那正是分享的意义。
但 **App 签名仍然强制**(只有 `/healthz` 豁免),另有令牌熵、按 IP 限流与密码并发闸三层防护,
详见 bc/echonote(未随包提供 —— 见仓内 docs/api/bc/echonote/README.md) §5。其余全部端点都在鉴权组内(需 JWT + 签名)。

### 3.2 App 签名(每个请求)

| 头 | 说明 |
|---|---|
| `X-Distribution-Code` | 分发码(如 `com.magiccontent.muse`) |
| `X-Timestamp` | Unix 秒 |
| `X-Nonce` | 每次请求新生成的随机串 |
| `X-App-Signature` | `hex(HMAC-SHA256(secret, timestamp + nonce + sortedJSON(body)))` |

`sortedJSON` 归一:空 body → `{}`;JSON object → key **按字典序递归排序**后序列化。
与平台 `pkg/aigcsign` **逐字节一致** —— 平台侧签名怎么算,这里就怎么算。

失败一律 **HTTP 401**,`code` 按失败原因**细分**(见 §4)。

⚠️ **2026-08-21 起细分,此前全部折叠为 `40110`。** 判据是「客户端能不能据此做不同的事」:
`40112`(时钟偏移)与 `40113`(重放)是**两条可自愈且互不相同**的路径 ——
折叠时想实现自愈的客户端只能靠 `message` 文本匹配,那是最脆的耦合(文案一改就断且不报错)。
仍按 `40110` 一刀切处理的客户端**不会坏**(它只是拿不到那两条自愈路径)。

⚠️ **验签先于 nonce 落库** —— 否则未认证者可以打爆共享的 nonce 存储。

### 3.3 JWT

```
Authorization: Bearer <access_token>
```

由**平台** `identity` 签发(HS256),claims 含 `abid`。本仓验签后额外查平台的 token 黑名单:

| 情形 | 结果 |
|---|---|
| 命中黑名单(已登出 / 已吊销) | 401 + **40102** |
| 黑名单存储不可达 | 503 + **50350**(**fail-closed** —— 安全边界不可用时拒绝) |

### 3.4 🔴 身份纪律(客户端最容易踩的一条)

> **账户身份只来自 JWT,分发码只来自签名头。
> 请求体里传 `account_id` / `account_bid` / `tenant_id` / `app_id` / `distribution_code` 一律被忽略。**

不是"传了会报错",是**传了没用** —— 服务端只认已验证的上下文。
若你发现某个接口"传了 account 却不生效",那是设计如此,不是 bug。

---

## 4. 错误码分段

| 段 | 归属 |
|---|---|
| 40102 | token 无效 / 过期 / 已吊销 → **重新登录** |
| 40110 | 签名头缺失 / 未分类的签名失败(**兜底码**) |
| **40111** | `X-Timestamp` 不是合法 Unix 秒 → 客户端 bug,**重试无用** |
| **40112** | 时间戳超出 ±5min 窗 → ✅ **可自愈:重同步本地时钟后重试** |
| **40113** | nonce 已被消费(确定性重放)→ ✅ **可自愈:换一个 nonce 重试** |
| **40114** | HMAC 不符 → 密钥或算法错,**重试无用** |
| **40304** | 分发码未知 → 配置错,**重试无用** |
| 42901 | 限流(429 + `Retry-After`) |
| **50350** | 鉴权依赖(token 黑名单)不可达(503)→ 稍后重试 |
| 48000-48099 | fashiondress |
| 48100-48199 | feastly |
| 48850-48949 | promotion |
| 48950-48989 | feedback |
| 48990-48994 | ⛔ 已退役(原 consultation,2026-08-23;**勿复用** —— 旧客户端可能仍按原义处理) |
| 48995-48999 | divination(星缘;**本段已用尽剩 1 位**,新码从 49100-49199 申请) |
| 49000-49099 | echonote |
| **49100-49299** | songcraft(AI 写歌;两段 —— 对象多于听语)|
| **49300-49349** | songlet(小曲) |
| 50000 | 未映射内部错误 → 提示重试 |

⚠️ **50000 不携带任何细节**。内部错误串含数据库表名/列名/约束名,泄漏出去等于免费提供一份 schema。
排障请用 `request_id` 找服务端日志(§6)。

### 5xx 分段(2026-08-21 新增登记)

| 段 | 归属 |
|---|---|
| 50300-50349 | 平台自用(含 `50301` IAP 商店上游不可用) |
| **50350-50379** | **本仓** —— `50350` 鉴权依赖不可达 · `50360` songlet 平台上游不可达 |
| 50380-50399 | 增长仓(预留) |

⚠️ **`50301` 曾被本仓用作「JWT 黑名单不可达」,2026-08-21 已改为 `50350`。**
两边都是 HTTP 503,所以撞码时**不会有任何类型错误** —— 但客户端按码分支会把
「黑名单不可达」当成「商店不可用」。若你的代码里还留着 `50301` 的分支,请改。
机器执法:`tests/archtest/TestFiveXXCodesAreInProductSegment`。

> 48200-48849 属**增长仓** `genaistudio-growth`,不会出现在本仓响应里。
> 各段在平台仓 `docs/api/error-codes.md` 统一登记防冲突。

---

## 5. 通用约定

### 5.1 只出 BID,永不出内部 ID

对外标识一律 `bid`(UUID)。**没有任何接口返回数据库自增 id** ——
那些 id 跨环境不稳定(重 seed 会变),客户端一旦拿它当稳定标识,后端就再也改不动了。

**例外只有两类**,都是 `string` 且跨环境稳定:

| 形态 | 例 | 为什么可以 |
|---|---|---|
| **稳定 code** | `suggestions[].id` · `consultants[].code` | 运营定义的 slug,重 seed 不变 —— 埋点口径就锚在它上面 |
| **平台透传的外部标识** | `vocabulary_id`(上游 ASR 词表) | 它本来就是给上游用的,本仓只转发 |

⚠️ **内部维度键一律不出 wire**:`tenant_id` / `account_id` / `app_id` / `agent_id` /
`end_user_id` / `user_id`。§3.4 写了请求方向传它们会被忽略;**响应方向同样不会有它们**。
其中 `app_id` 尤其危险 —— 它在 dev 与 prod 是**反的**,照着用会在某个环境指向另一个 App 且不报错。

🔒 机器执法(2026-08-21):`TestWireLayerDoesNotImportEnt`(禁对外层拿到 ent 类型 ——
那是泄漏的物理通路)· `TestWireIDFieldsAreNotNumeric` · `TestNoInternalDimensionOnWire`。

### 5.2 分页:游标式 `has_more`,**无 `total`**

```json
{ "items": [ … ], "has_more": true }
```

| BC | `limit` 上界 | `offset` 上界 |
|---|---|---|
| fashiondress / feastly / promotion / echonote | 200 | 10000 |
| feedback | 50 | **2000** |

⚠️ **列表接口一律不返回总数**。`count(*)` 会随数据量增长成为每次请求的固定成本,
而"共 137 条"对用户几乎没有价值。要判断"还有没有下一页"请用 `has_more`。

⚠️ `offset` 上界不是建议是**硬拒**:`OFFSET 1000000` 的深分页会拖垮与平台共享的数据库实例。
需要看更早的数据请用时间过滤,不要靠翻页。

### 5.3 i18n:`{code, label}` 双字段

所有目录/枚举型配置返回两个字段:

```json
{ "code": "bug.crash", "label": "闪退 / 卡死" }
```

- **`code` 稳定,驱动一切逻辑** —— 存储、判断、埋点都用它;
- **`label` 由服务端按 `X-Language` 本地化** —— 客户端**直接展示,不要自己翻译**。

语言归一:`zh-*` → 中文,其余 → 英文;缺失回落 en → zh → 任一非空。

这条契约的价值:**后端加一个分类,客户端免发版**。反过来,若客户端把 `label` 硬编码成判断条件,
一次文案调整就会让逻辑失效。

#### ⚠️ 唯一的例外:星缘咨询师体系走**双语透传**

| 适用面 | 形态 |
|---|---|
| 其余全部端点 | `label` 是**服务端已本地化的单串**(上文) |
| `GET /v1/divination/consultants`<br>`GET /v1/divination/consultants/:bid/prompts` | 文案字段是**语言映射** `{"zh":"…","en":"…"}`,**locale 解析归客户端** |

**为什么有这个例外**:跨仓契约 `consultant-persona-contract-v1.md` §6 要求
「文案 `{en,zh}` 双语透传,locale 解析归客户端」,经产品方裁决按契约执行。

**边界是硬的**:例外**只覆盖 `/v1/divination/consultants` 与
`/v1/divination/consultants/:bid/prompts` 这两个端点**。同一个 BC 里的
`GET /v1/divination/bootstrap` 的 `suggestions[].content` **仍是服务端单串**(已发布契约,不动)。

⚠️ **但「两键都要有」这条纪律覆盖两种形态。** 单串那条链上,`NormalizeLang`
把所有非中文语言映射到 `en`,所以中文设备拿到 zh、其余全部拿到 en,客户端从 en 翻译 ——
目标一致,只是取值发生在服务端。`en` 缺席时服务端会**静默回落成中文**而响应形状不变,
所以它也有装载期 fail-close 门(`docs/migrations/seed/10_dvn_suggestions.sql`)。
wire 类型收敛在 `internal/platform/i18n.LabelMap` 一处 ——
散着写 `map[string]string` 的话,三年后没人说得清哪些端点是哪种形态。

🔴 **客户端代价(必读)**:双语透传把两件事转移给了客户端 —— **取值**与**翻译**。

**数据源恒为 `{en, zh}` 二键,不会出现第三个键**:中文系语言取 `zh`、
**其余全部语言取 `en`**。`en` 是非中英语言的映射 key,后端不会为第三种语言新增键。

🔴 **其余语言的翻译由客户端做**(2026-08-21 裁决)。这与本节的**主规则刚好相反** ——
`{code, label}` 那条是「服务端已本地化,客户端**不要**自己翻译」。
判据是「这段文案会不会被后端加新值」:分类目录会(后端加一个分类,客户端免发版),
所以归服务端;咨询师文案不会(六位是固定资产),所以交给客户端。

**两键都会有,这是纪律**:带外装载件在事务里 fail-close 校验
(`docs/ops/xingyuan-consultants-load.sql` §3④),配了一半就整批回滚。

⚠️ **但回落仍然必须实现。** 那道门只管装载件这一条通路,绕过它手工 `INSERT` 仍可能
产生缺键的行。而缺键是**静默**的:服务端剔除空串键 ⇒ 缺的键在响应里根本不出现 ⇒
不回落就是英文用户看到一个没有名字的咨询师,**没有任何报错**。
缺失时互为回落;两个都缺则该字段视为未配置、不渲染。
取值表与参考实现见 bc/divination(未随包提供 —— 见仓内 docs/api/bc/divination/README.md)。

### 5.4 幂等:`X-Idempotency-Key`

写接口(提交反馈、兑换券)支持该头。**重试时必须复用同一个 key**:

- 同 key 重复提交 → 返回**第一次那条**(HTTP 200 + 同一 bid),不是报错;
- 客户端因此可以在弱网下安全重试。

⚠️ 不带此头的重试会产生**两条真实记录**。移动网络下重试是常态,请务必带上。

### 5.5 时间

一律 RFC3339 带时区(`2026-08-05T12:00:00Z`)。信封的 `timestamp` 是 Unix 秒。

### 5.6 数组与映射字段**恒存在**

所有集合型字段(`items` / `attachment_keys` / `attachment_urls` / `timeline` /
`task_types` / `model_codes` …)在响应里**一定出现**,空时是 `[]` 或 `{}`,
**不会是 `null`,也不会缺字段**。

→ 可以无条件 `for...of` / `.length` / `map[key]`,不必先判空。

⚠️ 这条是**契约**不是巧合。反过来说:若你在某个响应里看到某个集合字段缺失或为 `null`,
那是服务端的缺陷,请报给我们 —— 不要在客户端加防御性判空把它掩盖过去,
那会让同一个问题在其他端继续存在。

---

## 6. 排障:`request_id` 与 `X-Request-ID`

服务端为每个请求生成 `request_id` 并在信封里返回;客户端也可主动传 `X-Request-ID` 覆盖。

**它会被透传到平台** —— 一次"上传失败"横跨产品层与平台两个服务,只有这个 id 能把两边的日志串起来。

强烈建议客户端:
1. 在本地日志里记录每次请求的 `request_id`;
2. 提交用户反馈时把**最近几个** `request_id` 放进 `context.session_request_ids`
   (见 bc/feedback(未随包提供 —— 见仓内 docs/api/bc/feedback/README.md))。

没有它,"我刚才那次失败了"这类反馈基本无法定位。

---

## 7. 与平台的分工(客户端必须理解)

产品层与平台是**两个服务、两个域名**:

| 域名 | 服务 | 契约 |
|---|---|---|
| `genaistudio-products.showsapp.org` | **产品层**(本仓,:9910)—— 该域下 `/v1/*` **全部**归本仓 | 本目录 |
| `genaistudio.showsapp.org` | **平台**(:9999)—— 登录 / 生成任务 / 上传 / 钱包 / 内购 / 模型… | 平台仓 `docs/api/` |

⚠️ **2026-08-19 起本仓有了专属域**。此前产品层寄生在平台域下,靠一条硬编码的
`location ~ ^/v1/(wardrobes|feastly|…)` 正则分流 —— 那个机制有一个不会报错的失败形态:
新增 BC 时漏加前缀 → 该 BC 全部请求落进 catch-all 打到平台 → **全部 404**,
而探活走同一条 catch-all → **200 绿灯**。功能全死、探活全绿,零信号。
平台域的那两处前缀块已于同日删除(旧路径现由平台返 404,删除前 71 天日志实测零真实客户端流量)。

**对客户端的推论**:本目录列出的全部端点请打**产品域**;
平台端点(登录/任务/上传/钱包)打平台域。两者的 App 签名与 JWT 是同一套。

⚠️ **Songlet 是唯一例外**:它的客户端只有一个 BaseURL(冻结契约),所以本仓为它代理了
attest / 远程配置 / 上传三类平台能力,见 [products/songlet](../README.md)。

三条推论:

1. **登录、注册、token 刷新在平台** —— 本仓不签发任何 token,只验证。
2. **文件上传在平台** —— 本仓的接口只接收上传后的 `key`,**从不接收文件本身**
   (见 bc/feedback §2 的附件章节)。
3. **一切计费在平台** —— 本仓不碰钱包。券的核销也是发起平台的能力,由平台在其事务内完成扣减。

---

## 8. 变更纪律

- 新增字段:直接加,客户端按需读取(**请务必忽略未知字段**,不要严格模式解析);
- 删除/改语义:走版本协商,不会静默变更;
- 错误码:只增不改。已发布的 code 不会被复用为其他含义。
