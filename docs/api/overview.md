# API Overview — 公共契约与机制

> 本文档汇总 AIGC 平台所有 HTTP API 的**通用机制**:BaseURL、请求头、鉴权、签名、响应 Envelope、错误码。各 BC 的具体端点契约见 [creation.md](creation.md)、[provider.md](provider.md) 等 BC 文档,以及 [endpoint-inventory.md](endpoint-inventory.md) 全量索引。
>
> **前端对接**:对话创作工作台(六部件)的端到端接口文档见 [frontend-integration.md](frontend-integration.md)——覆盖鉴权/信封、会话与消息、三条 SSE 流协议、意图对象契约、计划卡、任务与候选、钱包、错误码速查、状态管理建议。
>
> **机器可读契约(ADR-012 D3,2026-07-05 起)**:`api/openapi/openapi.yaml`(OpenAPI 3.1)是对外契约的机器事实源,**增量覆盖**——云工作台装配面先行(tasks/estimate、会话消息、会话事件流 SSE、wallet、意图对象 schema);新装配端点必须随 PR 补录,CI 守卫 `tests/contract/openapi_validate_test.go`(加载校验 + intent_type 枚举与 Go 权威定义 `internal/creation/app/dto/intent.go` 防漂移)。TS 客户端生成(前端立项后接线):`npx openapi-typescript api/openapi/openapi.yaml`。
>
> **事实驱动**:每条事实标注源代码文件 + 行号,无任何臆测。最后扫描时间 2026-04-29。

## 1. BaseURL 与版本前缀

| 项 | 值 | 来源 |
|---|---|---|
| 路径前缀 | `/v1` | `internal/platform/httpserver/router/router.go:48` |
| 默认监听 | `:9999`(dev) | `cfg.Server.Port`(`internal/platform/config/config.go:248`)|
| 健康检查 | `GET /`(根路径,非 `/v1`)→ `200 "ok"` | `router/router.go:43` |

**生产 BaseURL**:`https://api.aigc.example.com/v1`
**开发 BaseURL**:`http://localhost:9999/v1`

API 版本仅一档(v1),无多版本路径并存。

## 2. 中间件链(执行顺序)

| 层 | Hertz 挂载点 | 中间件 | 来源 |
|---|---|---|---|
| Root | `h.Use()` | CORS | `router/router.go:40` |
| `/v1` 组(全部) | `v1.Use(GetGlobalHandlers()...)` | RequestID → TraceID → Recovery → Logger → SecurityHeaders → **AppSignature** | `middleware/manager.go:114-123` |
| `/v1/...`(JWT) | `authenticated.Use(GetAuthMiddleware())` | JWTAuthMiddleware | `router/router.go:52-53` |
| `/v1/auth/guest-register` 单点 | 该路由 handler 链头部 | GuestRateLimit + AnomalyDetection | `identity/port/http/routes.go:26-28` |

**CORS 必须挂在 root**(不能挂 group)— Hertz 路由树对未注册 method 的 OPTIONS 预检会短路 404,挂 group 内 OPTIONS 收不到回包。注释见 `router/router.go:38-39`。

## 3. 公共请求 Headers

### 3.1 鉴权 / 签名(分类必填)

| Header | 说明 | 何时必填 |
|---|---|---|
| `Authorization` | `Bearer <jwt>` | JWT 鉴权端点(详见 §4) |
| `X-Distribution-Code` | 分发渠道编码(`iap_app_distributions.distribution_code`)| 全部 `/v1/*`(除 `/v1/webhook/` + `/v1/internal/`)|
| `X-Timestamp` | Unix 秒级时间戳 | 同上 |
| `X-Nonce` | UUID v4 防重放 | 同上 |
| `X-App-Signature` | HMAC-SHA256 hex 64 字符 | 同上 |

详见 §5(App 签名机制)。

### 3.2 RequestMeta(可选,但建议带)

由 `internal/platform/httpserver/middleware/request_meta.go::BuildRequestMeta` 提取(纯函数,非中间件,各 handler 主动调用)。

| Header | Go field | 用途 |
|---|---|---|
| `X-Device-ID` | `DeviceID` | 设备唯一标识,Guest 注册幂等键 |
| `X-Platform` | `Platform` | `web` / `ios` / `android` 等 |
| `X-App-Version` | `AppVersion` | 客户端版本号 |
| `X-App-Build` | `AppBuild` | 构建号(可选) |
| `X-Os-Version` | `OsVersion` | 操作系统版本 |
| `X-Device-Model` | `DeviceModel` | 设备型号(`iPhone14,3` 等) |
| `X-Language` | `Language` | 语言偏好(`zh-CN`)|
| `X-Timezone` | `Timezone` | `Asia/Shanghai` |

来源:`request_meta.go:9-19`(常量定义)+ `request_meta.go:31-44`(BuildRequestMeta 函数)。

### 3.3 追踪(中间件自动注入,客户端可选透传)

| Header | 说明 |
|---|---|
| `X-Request-ID` | 客户端可传入追踪 ID;未传则后端生成 UUID;响应头会回写。来源 `middleware/request_id.go:13-36` |
| `X-Trace-Id` | 分布式追踪 ID(同上语义,来自 `trace_id.go`)|

## 4. JWT 鉴权机制

### 4.1 算法 + 颁发

| 项 | 值 | 来源 |
|---|---|---|
| 算法 | HS256(HMAC-SHA256)| `internal/platform/config/config.go:176-182` |
| 颁发端点 | `POST /v1/auth/login` / `POST /v1/auth/refresh` / `POST /v1/auth/guest-register` | identity BC |

### 4.2 Claims 结构

来源:`internal/identity/app/port/auth_port.go:22-31`

```json
{
  "abid":  "019dd70f-fb37-7f98-...",   // Account 业务 BID (UUID)
  "role":  "user",                      // user / creator / developer / admin / super_admin
  "sid":   "session-uuid",              // 会话 ID, 用于黑名单与并发控制
  "iat":   1735689600,
  "exp":   1735693200
}
```

### 4.3 Token 流转

| 阶段 | 行为 | 来源 |
|---|---|---|
| 客户端附加 | `Authorization: Bearer <jwt>` (case-insensitive) | `middleware/jwt_auth.go:54-66` |
| 服务端验签 | HS256 + `cfg.Auth.Token.Secret` | 同上 |
| 黑名单查询 | `tokenHash = sha256(jwt)`,Redis hash 查 `IsBlacklisted` | `jwt_auth.go:79-94` |
| 账户解析 | `AccountResolver.ByBID(abid)` 走 Redis 缓存(99% 命中,5min TTL + jitter) | `identity/app/port/account_resolver.go:15-25` |
| Context 注入 | `account_id`(int64)、`account_bid`、`account_role`、`account_session_id`、`account_claims`、`raw_access_token` | `jwt_auth.go:107-115` |

**Fail-closed**:Redis 故障时 JWT 中间件**拒绝**请求(防止黑名单绕过)。

### 4.4 黑名单触发

| 触发 | 行为 |
|---|---|
| `POST /v1/auth/logout` | 当前 session 黑名单 |
| `POST /v1/auth/logout/all` | 该账号所有 session 批量黑名单 |
| `POST /v1/auth/refresh` | 旧 token 自动黑名单(token rotation) |

## 5. App 签名机制(HMAC-SHA256)

全局生效,**单渠道密钥泄露不影响其他渠道**(基于 `iap_app_distributions` 表前缀隔离设计)。

### 5.1 必填请求头

| Header | 来源 | 约束 |
|---|---|---|
| `X-Distribution-Code` | `iap_app_distributions.distribution_code` | 全局唯一 |
| `X-Timestamp` | Unix 秒(字符串)| 服务端窗口 ±5 分钟 |
| `X-Nonce` | UUID v4 | Redis SET NX 防重放,TTL 10 分钟;key 按分发隔离 `nonce:{distribution_code}:{nonce}`;**验签通过后才消费**(2026-08-18 整改,验签失败不烧 nonce);nonce 存储故障 fail-open(签名+时间窗仍强制)|
| `X-App-Signature` | HMAC 结果(hex 小写,64 字符)| 见 §5.2 |

### 5.2 签名公式

```
canonical = timestamp + nonce + sortedJSON(body)
signature = hex( HMAC_SHA256(secret, canonical) )
```

**关键事实**(代码核实):
- **无分隔符**:三段直接拼接(不是 `\n` / `:`)
- `sortedJSON(body)`:Go `json.Marshal(map[string]any)` 自动按 key 字典序递归排序
- **空 body** / nil:返字面量 `"{}"`(不是空字符串)
- **非合法 JSON 体**:fall-back 原文参与拼接(服务端会因 JSON 解析失败拒签,行为对齐)
- `signature` 是 **hex 小写**(64 字符),不是 base64

来源:`middleware/app_signature.go:194-198` + `pkg/aigcsign/sign.go:113-137`

### 5.3 Secret 来源

| 字段 | 备注 |
|---|---|
| `iap_app_distributions.secret_key_hash`(varchar 128)| 字段名带 `hash` 但**实为 HMAC 密钥本身**(明文,直接进 `HMAC.New`)。命名是历史遗留 |

服务端流程:`X-Distribution-Code` → `AppSecretResolver.ResolveSecret` → 单表查 `iap_app_distributions`(无 JOIN)→ 缓存到 Redis(5 min)。

### 5.4 时间戳 / Nonce 默认窗口

| 配置 | 默认 | 来源 |
|---|---|---|
| `TimestampMaxAge` | 5 分钟 | `app_signature.go:39` |
| `NonceTTL` | 10 分钟(≥ 2× TimestampMaxAge,防重放窗口完全覆盖)| `app_signature.go:40` |
| `Enabled` | `true`(默认全局启用)| `app_signature.go:38` |

### 5.5 SkipPaths(免签路径前缀)

```
/v1/webhook/      —— 上游平台 webhook(Apple S2S / Stripe / Google RTDN), 走各自 JWS 验签
/v1/internal/     —— 内网回调(供应商 task complete 等), 内网信任 / IP 白名单
```

来源:`app_signature.go:41-46`(默认 `SkipPaths`)。

### 5.6 客户端实现参考

- **Go**:`pkg/aigcsign.Sign(secret, distCode, body, opts)` → 返 `Headers{}`
- **TypeScript / Node.js**:见 `pkg/aigcsign/README.md` 内的等价实现
- **CLI 调试**:`go run ./cmd/signtool/ -secret '<key>' -dist '<code>' -json '...' -headers`

**Parity 保证**:`internal/platform/httpserver/middleware/signature_pkg_parity_test.go` 用 `pkg/aigcsign.Sign` 生成的 headers 灌进真实 middleware,5 个 case 全 pass。任一边公式漂移立即 fail CI。

### 5.7 鉴权失败错误码

| Code | HTTP | 含义 | 来源 |
|---|---|---|---|
| 40110 | 401 | 缺签名头(任一缺) | `app_signature.go:120-123` |
| 40111 | 401 | `X-Timestamp` 格式无效(strconv 严格全串解析) | `app_signature.go:130-132` |
| 40112 | 401 | 请求已过期(超出时间窗) | `app_signature.go:136-138` |
| 40113 | 401 | Nonce 重复(防重放命中;**仅对验签通过的请求判定**) | `app_signature.go:226-228` |
| 40114 | 401 | 签名验证失败 | `app_signature.go:204-206` |
| 40115 | **503** | 签名校验暂不可用(密钥解析基础设施故障,fail-close;≠40304)| `app_signature.go:165-167` |
| 40304 | 403 | 分发版本不存在(确定性,依据 `port.ErrDistributionNotFound` 哨兵)| `app_signature.go:153-155` |
| 40305 | 403 | 分发版本已禁用(`status='disabled'`)| `app_signature.go:177-179` |
| 40306 | 403 | 分发版本未配置签名密钥(`secret_key_hash=''`)| `app_signature.go:188-190` |

> **降级语义(2026-08-18 事故整改)**:nonce 存储(Redis)故障时**不返回 40113**,
> 而是放行已验签请求并落节流 ERROR(`replay guard DEGRADED`,巡检口径见
> `docs/ops/log-alert-patrol.md`)。40113 从此只代表真实重放。

### 5.8 注入到 Context(供下游 handler 使用)

签名通过后,`middleware/app_signature.go:233-237` 注入:

| Context Key | 类型 | 来源 |
|---|---|---|
| `distribution_info` | `*AppSecretInfo` | 完整分发信息 |
| `distribution_code` | `string` | 分发 code |
| `distribution_id` | `int64` | 分发内部 ID |
| `app_id` | `int64` | 关联 App ID |
| `bundle_id` | `string` | iOS Bundle / Android Package。Web 端约定:`bundle_id == distribution_code`(如 `aigc.studio.web`),不能空字符串(后端 GuestRegister 等校验 `cmd.BundleID != dist.BundleID` 会 reject)|

## 6. 统一响应 Envelope

来源:`internal/platform/httpserver/response/response.go:19-50`

### 6.1 成功 / 默认错误

```json
{
  "code": 0,
  "message": "success",
  "data": {  },
  "request_id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": 1735689600
}
```

| 字段 | 类型 | 说明 |
|---|---|---|
| `code` | int | 0 = 成功;非 0 见错误码段(§7) |
| `message` | string | 人类可读消息(成功时 `"success"`)|
| `data` | any(`omitempty`)| 业务载荷,由具体端点定义 |
| `request_id` | string | 优先取 `ctx.Get("request_id")`(由 RequestID 中间件注入),次取请求头 `X-Request-ID`,均无则生成 UUID |
| `timestamp` | int64 | **Unix 秒**(不是毫秒) |

### 6.2 ValidationFailed(特殊形态)

来源:`response.go:236-246`

```json
{
  "code": 40001,
  "message": "参数校验失败",
  "details": {
    "duration_sec": "duration_sec must be in [4,12]",
    "tags": "tags cannot be empty"
  },
  "request_id": "...",
  "timestamp": 1735689600
}
```

特点:
- HTTP 状态码 = **400 Bad Request**
- 固定 `code=40001` / `message="参数校验失败"`
- 字段级错误 map 在 `details`(`map[string]string`),不在 `data`
- 无 `data` 字段

### 6.3 Helper 函数与 HTTP 状态码

来源:`response/response.go`

| Helper | HTTP 状态 | `code` 字段 | 用途 |
|---|---|---|---|
| `Success(c, ctx, data)` | 200 | 0 | 默认成功 |
| `SuccessWithMessage(c, ctx, msg, data)` | 200 | 0 | 自定义 message |
| `SuccessWithoutData(c, ctx)` | 200 | 0 | 无 data 成功(如 cancel)|
| `Accepted(c, ctx, data)` | **202** | 0 | 异步接受(SubmitTask 异步路径)|
| `BadRequest(c, ctx, msg)` | 400 | 400 | 请求格式错 |
| `Unauthorized(c, ctx, msg)` | 401 | 401 | JWT / 签名失败 |
| `Forbidden(c, ctx, msg)` | 403 | 403 | 权限不足 |
| `NotFound(c, ctx, msg)` | 404 | 404 | 资源不存在 |
| `InternalServerError(c, ctx, msg)` | 500 | 500 | 服务器错误 |
| `ValidationFailed(c, ctx, details)` | 400 | 40001 | 字段级校验失败(§6.2)|
| `Error(c, ctx, code, msg)` | **200** | 自定义 | 通用业务错误(★ 多数 BC 用此 — HTTP 200,业务码在 `code`)|
| `FromError(c, ctx, err)` | 由 AppError 决定 | 由 AppError 决定 | 推荐:自动映射 domain error → 错误码 |

**重要约定**:**多数业务错误返回 HTTP 200**,通过 `code` 字段区分。仅以下 helper 返真实 HTTP 错误码:`BadRequest` / `Unauthorized` / `Forbidden` / `NotFound` / `ValidationFailed` / `InternalServerError`。

> 这是后端故意约定:让 nginx / CDN 等中间层不会把业务级 4xx 当成异常吞掉日志。OpenAPI spec 内的 `responses` 块按真实 HTTP 状态码声明。

## 7. 错误码体系

### 7.1 区段约定

| 段 | 语义 | 典型错误码 |
|---|---|---|
| **400xx** | 参数校验失败 | 40001(`ValidationFailed`)、40002(密码弱)、40003(参数无效)|
| **401xx** | 认证(JWT / Session)| 40101(密码错)、40102(token 过期)、40110-40115(签名失败;40115 随 503 返回)|
| **402xx** | 计费 / 积分(Plan-Billing 收口)| 40200(余额不足)、40201(定价缺失 — 硬拒,运维补规则行)、40202(定价配置非法)|
| **403xx** | 授权 / 账户 / 应用状态 | 40301(权限不足 / 账户锁定)、40304(应用禁用)、40305(分发禁用)|
| **404xx** | 资源不存在 | 40401(账户)、40402(应用)、40410(provider)、40420(任务)、40430(知识库)|
| **409xx** | 状态机冲突 / 并发 | 40901(乐观锁冲突)、40920(状态转换非法)、40921(幂等冲突)|
| **42xxx** | 限流 / 配额 | 42901(登录频率)、42902(设备限流)、42910(配额耗尽)|
| **45xxx (45100-45199)** | 内容审核 | 45100(prompt 拒绝)、45110(供应商内容过滤)|
| **45xxx (45400-45499/4590x/45920)** | **候选层 (P7 Phase 5)** | 45401(批量上限超)、45400(候选不存在)、45901(未就绪)、45902(已 Save)、45903(已过期)、45904(已丢弃)、45905-45906(审核)、45920(状态转换) |
| **50000** | 通用服务器错误 | — |
| **500xx** | 特定服务错误 | 50020(凭证解密失败)、50032(能力不支持)、50040(钱包冻结失败)|
| **502xx** | 上游调用失败 | 50210(上游不可用)、50230(暂时不可用)|
| **503xx** | 第三方不可用 | 50301(商店不可用)|
| **504xx** | 上游超时 | 50410 |

### 7.2 各 BC 错误码总表(摘选)

详见各 BC 的 `domain/errors.go` 或 `port/http/errors.go`(后者多用 `mapDomainErr` 函数)。

#### Identity(`internal/identity/domain/errors.go:31-97`)

| 错误 | Code |
|---|---|
| `ErrInvalidPassword` | 40101 |
| `ErrTokenInvalid` / `ErrTokenExpired` | 40102 |
| `ErrTokenRevoked` | 40104 |
| `ErrSessionExpired` / `ErrSessionNotFound` | 40105 |
| `ErrRefreshTokenReused` | 40106 |
| `ErrAccountLocked` | 40301 |
| `ErrAccountFrozen` | 40302 |
| `ErrAccountDisabled` | 40303 |
| `ErrAccountNotFound` | 40401 |
| `ErrAppNotFound` | 40402 |
| `ErrAppDisabled` | 40304 |
| `ErrPasswordTooWeak` | 40002 |
| `ErrTooManyAttempts` | 42901 |
| `ErrDeviceRateLimited` | 42902 |

#### Creation(`internal/creation/domain/errors.go:22-45`)

| 错误 | Code |
|---|---|
| `ErrTaskNotFound` | 40420 |
| `ErrInvalidStatusTransition` | 40920 |
| `ErrDuplicateIdempotencyKey` | 40921 |
| `ErrInsufficientCredits` | 40200 |
| `ErrInvalidParam` | 40033 |
| `ErrUnsupportedMimeType` | 40034 |
| `ErrFileSizeExceeded` | 40035 |
| `ErrInvalidQuantity` | 40036 |
| `ErrInvalidFileHash`(P6-04) | 40037 |
| `ErrProviderUnavailable` | 50210 |
| `ErrPromptRejected` | 45100 |
| `ErrUploadNotPending` | 40922 |
| `ErrUploadObjectMissing` | 40430 |
| `ErrUploadNotConfigured` | 50100 |
| **P7 Phase 5 候选层** | |
| `ErrCandidateBatchSizeExceeded` | 45401 |
| `ErrCandidateNotFound` | 45400 |
| `ErrInvalidCandidateTransition` | 45920 |
| `ErrCandidateNotReady` | 45901 |
| `ErrCandidateAlreadySelected` | 45902 |
| `ErrCandidateExpired` | 45903 |
| `ErrCandidateAlreadyDiscarded` | 45904 |
| `ErrCandidateModerationPending` | 45905 |
| `ErrCandidateModerationRejected` | 45906 |

#### Provider(`internal/provider/domain/errors.go:31-66`)

| 错误 | Code |
|---|---|
| `ErrProviderNotFound` / `ErrModelNotFound` / `ErrVersionNotFound` / `ErrChannelNotFound` | 40410 |
| `ErrProviderDisabled` / `ErrChannelDisabled` / `ErrModelOffline` | 40310 |
| `ErrProviderMaintenance` | 40311 |
| `ErrChannelExpired` | 40312 |
| `ErrNoAvailableChannel` | 40313 |
| `ErrVersionDeprecated` | 40314 |
| `ErrInvalidParam` | 40010 |
| `ErrQuotaExhausted` | 42910 |
| `ErrUpstreamFailed` | 50210 |
| `ErrUpstreamTimeout` | 50410 |
| `ErrContentFiltered` | 45110 |
| `ErrCredentialDecrypt` | 50020 |

#### IAP(`internal/iap/domain/errors.go:31-79`)

| 错误 | Code |
|---|---|
| `ErrAppNotFound` | 40402 |
| `ErrDistributionNotFound` | 40403 |
| `ErrProductNotFound` | 40404 |
| `ErrOrderNotFound` | 40405 |
| `ErrAppDisabled` | 40304 |
| `ErrDistributionDisabled` | 40305 |
| `ErrProductInactive` | 40306 |
| `ErrCredentialDisabled` | 40307 |
| `ErrAccountMismatch` | 40301 |
| `ErrSignatureInvalid` | 40015 |
| `ErrReceiptInvalid` | 40012 |
| `ErrConcurrentUpdate` | 40912 |
| `ErrStoreUnavailable` | 50301 |
| `ErrStorePlatformError` | 50302 |

> Tenancy / Catalog / Runtime / Tool / Knowledge BC 错误码段同样规整,详见各自 `port/http/errors.go::mapDomainErr`。

### 7.3 推荐 handler 错误处理

```
err := someUseCase.Handle(...)
if err != nil {
    response.FromError(c, ctx, err)   // ★ 自动映射 AppError → 业务码 + 日志
    return
}
```

`FromError` 内部:
1. `apperrors.AsAppError(err)` 转换;若是 `ValidationError` 子类返 `ErrorResponse{details}`
2. 按 `AppError.LogLevel()` 记日志(Info / Warn / Error)
3. 非 AppError 兜底返 `code:50000`

部分 BC(Tenancy / Catalog / Runtime / Tool)在 port/http 层用 `mapDomainErr(err)` → `(code, msg)` 手动映射。

## 8. 限流与异常检测

### 8.1 Guest 限流(`/v1/auth/guest-register` 单点)

来源:`middleware/guest_rate_limit.go:32-43`(`DefaultGuestRateLimitConfig`)

| 维度 | 限值 | 窗口 |
|---|---|---|
| Device(`device_id`)| 10 req | 1 min |
| IP(`c.ClientIP()`)| 60 req | 1 min |
| Distribution(`X-Distribution-Code`)| 1000 req | 1 min |

任一维度超限 → `HTTP 429` + `code:42902` + `Retry-After` + `X-RateLimit-Dimension` header。

### 8.2 异常检测(同端点,告警不阻断)

来源:`middleware/anomaly_detection.go:27-36`

| 维度 | 阈值 | 窗口 |
|---|---|---|
| 同 IP 注册不同设备数 | 20 | 10 min |
| 同设备跨 App 注册数 | 5 | 1 hour |

超阈值仅记录告警 + `c.Set("risk_flag", ...)`,**不阻断请求**(由限流层兜底)。

## 9. CORS / 安全响应头

### 9.1 CORS(挂在 root,详见 §2)

来源:`middleware/cors.go:26-55`(`DefaultCORSConfig`)

| 项 | Dev | Prod |
|---|---|---|
| `AllowedOrigins` | `["*"]`(回显请求 Origin)| 严格白名单(配置 `cfg.Security.CORS.AllowedOrigins`)|
| `AllowedMethods` | `GET POST PUT PATCH DELETE OPTIONS` | 同 |
| `AllowedHeaders` | 含全部 RequestMeta + 签名 + Trace headers | 同 |
| `AllowCredentials` | `false` | `false`(Prod 与 `*` 同时用会 warn)|
| `MaxAge` | 600s | 600s |

### 9.2 SecurityHeaders

来源:`middleware/security_headers.go:20-31`

```http
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Content-Security-Policy: default-src 'self'
Strict-Transport-Security: max-age=31536000; includeSubDomains
Referrer-Policy: strict-origin-when-cross-origin
```

Prod 默认启用,Dev 禁用(per `manager.go:97-99`)。

## 10. 鉴权决策树

```
请求到达 → /v1 group
  ├─ App 签名: 路径在 SkipPaths(/v1/webhook/, /v1/internal/)?
  │   ├─ 是: 跳过签名验证, 走 handler 自身验签 / 内网信任
  │   └─ 否: 校验 X-Distribution-Code + X-Timestamp + X-Nonce + X-App-Signature
  │       ├─ 失败 → 40110-40115 / 40304-40306
  │       └─ 通过 → 注入 distribution_id / app_id / bundle_id 到 ctx
  │
  ├─ JWT(只在 authenticated 子组 — 即 RegisterAuthenticatedRoutes 注册的端点):
  │   ├─ 解析 Authorization: Bearer
  │   ├─ HS256 验签
  │   ├─ Redis 查黑名单(fail-closed)
  │   ├─ 解析 Account(走缓存)
  │   └─ 注入 account_id / account_bid / account_role / session_id 到 ctx
  │
  └─ Guest 路径(/v1/auth/guest-register):
      ├─ 限流(三维)→ 42902
      └─ 异常检测(告警, 不阻断)
```

## 10.5 强化项灰度 flag(P-now 三项)

P-now 三项强化项均要求 feature flag, 默认关闭, 客户端调用前需确认服务端配置:

| flag | 关联强化项 | 默认 | 受影响端点 / 行为 | 关闭时行为 |
|---|---|---|---|---|
| `runtime.streaming.enabled` | #1 SSE 流式 | `false` | `POST /v1/conversations/:conv_bid/messages/stream` | 端点返 `50320` (流式服务未启用) |
| `observability.runtime_hook_enabled` | #2 Callback Hook | `false` | 全 BC 自动 trace 落 `obs_trace_spans` | 不注册 ObservabilityHook,不落 trace span,业务调用零开销 |
| `runtime.call_options_enabled` | #3 RuntimeOptions | `false` | `POST /v1/conversations/:conv_bid/messages` body 中 `runtime_options` 字段 | 静默忽略 body 中 `runtime_options`(graceful degrade,不返错),沿用 Agent 定义默认值 |

**配置位置**: `config/config.dev.yaml`(env > config 优先级)

**灰度策略**: 三 flag 互不依赖,可独立切换。建议顺序见 [`docs/research/eino/07-final-audit-report.md §10`](../research/eino/07-final-audit-report.md)。

**向后兼容保证**: 所有 flag 关闭时,客户端**老调用代码完全不受影响**(老 SendMessage 不传新字段、不依赖新端点)。客户端代码可以**先发布**支持新字段/新端点的实现,服务端在生产环境按租户/分发 dimension 逐步切开。

## 11. 文件上传(两条通道)

平台提供**两条互补**的文件上传通道,**两条都落 `gen_assets`**(确保 BFF 始终能枚举/清理 R2 对象,无孤儿)。差异在数据流方向 + 状态机推进时机:

| 端点组 | 模式 | 文件路径 | upload_state 时序 | 适用场景 |
|---|---|---|---|---|
| `/v1/uploads/sign` + `/v1/uploads/finalize` | presigned PUT 双段式 | 客户端 → R2(绕过 BFF) | sign 落 `pending` → finalize 推 `uploaded` | 瞬态参数输入 / 大文件 / 移动端弱网 |
| `/v1/assets/upload` | 服务端 multipart 直传 | 客户端 → BFF → R2 | 同步落 `uploaded`(单步) | 用户素材库(头像 / 文档持久化 / 跨任务复用素材) |

> 选择原则:**带宽敏感走 sign;一步到位走 upload**。两端最终在 `gen_assets` 留下同样形态的行,前端列表 / 删除 UI 无需区分。

### 通道 A:presigned PUT (`POST /v1/uploads/sign`)

> **来源**:`internal/creation/port/http/upload_handler.go` · `internal/creation/app/command/request_upload_url_handler.go` · `internal/creation/domain/service/upload_policy.go` · `internal/creation/infra/storage/r2_client.go::GeneratePresignedPutURL`

### 11.1 设计原则

| 原则 | 说明 |
|---|---|
| **双段式 (BFF + R2 直传)** | BFF 只生成签名,文件 bytes 不经过 BFF;客户端直接 PUT 到 R2 |
| **零持久化** | 仅签名,不创建 Asset 行(参数文件是瞬态输入,Asset 仅落 AI 生成产物) |
| **零新依赖** | 复用 `creation.ObjectStorage` 端口 + 现有 R2Client(`s3.PresignClient.PresignPutObject`)|
| **公网可达** | 上传后 `public_url` = `{R2.public_url}/{key}`,直接可用于跨服务调用 |
| **白名单 + 大小上限** | `domain.UploadPolicy` 默认 50 MiB + 主流图/视频/音频/文档 mime;Office 宏文档 / 可执行文件被拒 |

### 11.2 客户端使用流程

```
1. POST /v1/uploads/sign     body={ mime_type, size, filename, content_type? }
                        ↓ 返回 { bid, put_url, public_url, expires_at, key }
                        BFF: INSERT gen_assets (upload_state='pending')
2. PUT  put_url         body=<bytes>   header=Content-Type: <同 mime_type>
                        ↓ R2 200 OK
3. POST /v1/uploads/finalize body={ bid }
                        ↓ BFF: storage.Exists(key) HEAD 校验
                        ↓ UPDATE gen_assets SET upload_state='uploaded'
                        ↓ 返回完整 Asset DTO (与 /v1/assets/upload 同 schema)
4. 任何 BC 接口        params={..., my_image: public_url}
                        ↓ 后端把 public_url 透传给 Provider
```

### 11.3 端点契约速查

| 项 | sign(Step 1) | finalize(Step 2) |
|---|---|---|
| Method · Path | `POST /v1/uploads/sign` | `POST /v1/uploads/finalize` |
| 鉴权 | JWT Bearer + 全局 App 签名 | 同左 |
| 请求体 | `{ mime_type, size, filename, content_type?, access_level?, file_hash? }`(P6-04 起 `file_hash` 可选) | `{ bid }` |
| 响应 (`data`) | `{ bid, put_url, public_url, expires_at, key, dedup_hit? }` | 完整 Asset DTO(与 `/v1/assets/upload` 同,含 `dedup_hit?`) |
| TTL | 5 分钟(`uploadSignTTL`) | — |
| Key 模板 | `uploads/<tenant_id>/<account_bid>/<yyyy>/<mm>/<dd>/<uuidv7>.<ext>` | — |
| 副作用 | INSERT `gen_assets` (`upload_state='pending'`) + R2 PresignClient 签名;hash 命中时不 INSERT 不签名直接返已有 BID | R2 HEAD 校验 + UPDATE `upload_state` `pending`→`uploaded`;UNIQUE 撞时软删本 pending + 删 R2 对象 + 返 winner BID |
| 错误码 | 40033 参数 · 40034 mime · 40035 size · 40037 file_hash 格式非法(P6-04)· 50100 本地模式 | 40420 bid 不存在 · 40430 R2 对象不存在 · 40922 已 finalize / 状态异常 |

详细 schema + 字段表 + 示例见 [creation.md §通用文件直传](creation.md#post-v1uploadssign)。

### 11.4 注意事项

- **Content-Type 一致**: 客户端 PUT 请求必须发送与 `sign` 时相同的 `Content-Type`,否则 R2 会返 403(签名校验失败)。
- **finalize 必须调**: PUT 完成后**必须**调 finalize,否则 Asset 永远停在 `pending` 不会出现在 `GET /v1/assets` 列表。
- **本地开发**: `storage.provider=local` 模式不支持直传(sign 返 50100)。开发时切到 `r2`(配置已就绪)。
- **上传后回填**: 表单 onSubmit 时把 `public_url` 作为字段值传给后端;不要传 `put_url`(它含签名,过期即失效)。
- **CORS**: R2 桶需配置 CORS 允许 PUT(平台默认已配置 `*` origin · `PUT, GET, HEAD` methods · `Content-Type, Content-Length` headers)。
- **finalize 失败可重试**: PUT 失败但调 finalize 时返 40430,**重 PUT 后再 finalize** 即可(状态机仍 pending)。
- **不重复实现**: 任何瞬态文件输入场景统一调用本端点组;**不要**自建第二条直传通道。持久素材请用通道 B。

### 11.5 P6-04 账户级素材去重(2026-05-09 起两条通道均生效)

唯一索引:`UNIQUE(account_id, file_hash)` partial WHERE `file_hash<>'' AND deleted_at IS NULL AND upload_state='uploaded'`(`uq_gen_assets_account_file_hash`)。

| 通道 | 客户端动作 | 命中时 server 行为 |
|---|---|---|
| sign(双段式) | 选定文件 → **本地算 SHA-256 hex(64 lowercase)→ 提交到 sign 时附带 `file_hash` 字段** | 短路返 `dedup_hit=true + put_url="" + bid=已有asset_bid`,客户端**不**再 PUT、**不**调 finalize |
| upload(multipart) | 直接传文件到 BFF | server 算完整 hash + 命中时跳过 R2 PUT 与 DB INSERT,响应 `dedup_hit=true + bid=已有 asset_bid` |

**并发兜底**(三层防线):
1. **应用层快路径**:hash lookup 直接命中 → 短路
2. **DB UNIQUE 约束**:并发 race 第二者 INSERT/UPDATE 撞 23505
3. **handler 兜底**:捕获 `ErrAssetDuplicate` → 回查 winner + 软删本 pending + 删 R2 对象 + 返 hit 响应

**错误码**:`40037 ErrInvalidFileHash` — 客户端提交的 `file_hash` 不是 64 字符 lowercase hex。

**向后兼容**:旧客户端不传 `file_hash` 字段时,行为与 P6-04 之前完全一致(不参与去重),响应里 `dedup_hit` 被 `omitempty` 省略。

**安全语义**:去重维度是**账户级**(`account_id`)而非租户级 / 平台级,避免 private 资产被他人通过 hash 探测。

详细 schema + 字段表见 [creation.md POST /v1/uploads/sign](creation.md#post-v1uploadssign--直传签名双段式-step-1) §P6-04 章节。

### 通道 B:服务端 multipart (`POST /v1/assets/upload`)

> **来源**:`internal/creation/port/http/asset_handler.go::UploadAsset` · `internal/creation/app/command/upload_asset_handler.go` · `internal/creation/domain/service/upload_content_policy.go`

适用**用户素材库**场景(头像 / 文档持久化 / 跨任务复用素材):文件流经 BFF + 落 `gen_assets` 行(`source='upload'`),返回的 `bid` 可被 `GET /v1/assets/:bid` 引用。

| 项 | 值 |
|---|---|
| Method · Path | `POST /v1/assets/upload` |
| 鉴权 | JWT Bearer + 全局 App 签名 |
| Content-Type | `multipart/form-data` |
| 必填字段 | `file` (binary) · `content_type` (`image/video/audio/text/file`) |
| 选填字段 | `access_level` (`private`/`public`/`unlisted`) · `group_name` (≤ 128) · `tags` (JSON array) |
| 大小上限 | `storage.upload.max_file_size_mb` (默认 100 MiB) |
| 强校验 | content_type ↔ MIME 一致性(`UploadContentPolicy.ValidateMIMEMatch`) |
| 持久化 | `gen_assets` 行: `source='upload'` + `storage_provider='r2'` + `file_hash` (SHA-256) + 完整 metadata |
| 错误码 | 40001 字段缺失 · 40003 size 超限 / mime↔content_type 不匹配 · 50000 R2 写入失败 |
| 响应 | `{ bid, url, expires_at, file_name, file_size, mime_type, content_type, storage_provider, access_level, tags, group_name, created_at, dedup_hit? }`(P6-04 起 `dedup_hit` 在命中已有 hash 时为 `true`) |
| **去重**(P6-04) | server 端算 SHA-256 → 命中已有 `(account_id, file_hash)` 跳过 R2 PUT + DB INSERT 直接返已有 `bid + dedup_hit=true`;并发 INSERT 撞 UNIQUE 自动 fallback(删刚 PUT 上的 R2 对象 + 回查 + 返 hit) |

详细字段表 + content_type/MIME 映射 + 客户端示例见 [creation.md POST /v1/assets/upload](creation.md#post-v1assetsupload-服务端-multipart-直传)。

**通道选择决策**:

```
客户端有文件需要上传
  ├─ 关心 BFF 带宽(大文件 / 移动端弱网) / 想让客户端走 CDN 边缘?
  │   └─ 是 → 通道 A: POST /v1/uploads/sign + /finalize (R2 直传双段式)
  │   └─ 否 → 通道 B: POST /v1/assets/upload (单步, BFF 中转)
```

> 两端 final state 完全等价(都落 `gen_assets` + `upload_state='uploaded'` + 同样的 DTO 形态),前端 List/Get 不区分。差异**仅在数据流方向**与并发模型。

## 12. 标准 OpenAPI Components(可被各 BC spec 引用)

各 BC 的 OpenAPI spec(creation.md / provider.md / 等)的 `components.securitySchemes` 与 `components.schemas.StandardResponse` / `ErrorResponse` 来自此处统一定义。

```yaml
components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: |
        Identity BC 颁发,HS256 算法。
        Claims: { abid, role, sid, iat, exp }
    DistributionCode:
      type: apiKey
      in: header
      name: X-Distribution-Code
    Timestamp:
      type: apiKey
      in: header
      name: X-Timestamp
    Nonce:
      type: apiKey
      in: header
      name: X-Nonce
    AppSignature:
      type: apiKey
      in: header
      name: X-App-Signature

  schemas:
    StandardResponse:
      type: object
      required: [code, message, request_id, timestamp]
      properties:
        code:
          type: integer
          example: 0
        message:
          type: string
          example: success
        data:
          description: 业务载荷,各端点不同
        request_id:
          type: string
          format: uuid
        timestamp:
          type: integer
          format: int64
          description: Unix 秒(不是毫秒)

    ErrorResponse:
      type: object
      required: [code, message, request_id, timestamp]
      properties:
        code:
          type: integer
          example: 40033
        message:
          type: string
        details:
          type: object
          additionalProperties:
            type: string
          description: 仅 ValidationFailed (code=40001) 返回字段级错误
        request_id:
          type: string
          format: uuid
        timestamp:
          type: integer
          format: int64

# 默认所有 path 走全 5 项安全要求
security:
  - BearerAuth: []
    DistributionCode: []
    Timestamp: []
    Nonce: []
    AppSignature: []
```

**端点级安全覆盖**:
- 公开端点(login / refresh / guest-register / app-init / invitations/:token)用 `security: [{DistributionCode, Timestamp, Nonce, AppSignature}]`(去掉 BearerAuth)
- 通知 / 内部端点(`/webhook/apple` / `/internal/tasks/:bid/complete`)用 `security: []`(全部跳过)

## 租户模型(M-G/G1:把暗默契约显名)

现网是**单租户实态**:`tenant_id = 0` 的平台行贯穿全部业务面。这不是缺陷,是尚未
激活多租户的当前形态 —— 但它此前只活在代码习惯里,没有一处成文,于是每次新增
查询都要重新猜"这里该不该绑租户"。本节把它写死。

### 两类行,两套规则

| 类别 | `tenant_id` | 谁写 | 典型表 |
|---|---|---|---|
| **平台域行** | `0` | 平台运维 / seed / 独立 admin 后台 | `prov_models` · `prov_capability_defaults` · `wal_credit_pricing_rules` · `tool_tool_definitions`(system 作者)|
| **业务行** | 真实租户 id | 业务写路径 | `rt_runs` · `gen_assets` · `wal_wallets` · `mem_facts` … |

**RLS 矩阵**(实际启用面见 CLAUDE.md「Routes / RLS / DDL」):
`USING = tenant_id = GUC OR tenant_id = 0 OR GUC 未设置`(读得到平台行)、
`WITH CHECK = tenant_id = GUC OR GUC 未设置`(**不含** `OR tenant_id = 0` ——
绑了 GUC 的租户 session 不得伪造平台行)。

### 平台回落范式(必须两段解析)

跨租户读平台资源时,**先按租户精确匹配,未命中再回落平台行**:

```
ResolveXxxScoped(code, tenantID) → 命中租户覆写?返回
                                 → 否则 ResolveXxx(code, 0)  // 平台默认
```

**为什么写成红线**:2026-08-27 的实况是 capability 解析只做了精确 tenant 匹配 ——
于是所有带租户上下文的调用都解析不到 `tenant-0` 的平台能力,计费型语音一次都没通。
一段式匹配在单租户下"看起来能跑"(GUC 常为空),恰恰是它掩盖了缺陷。
正典实现:`capability.ResolveByCodeScoped` · `provider.ResolveCapabilityDefaultScoped`。

### 多租户激活清单(触发器条目,不实施)

商业触发出现时按**原子批次**做,半途激活比不激活更危险(部分表隔离 = 数据串门):
①6 个存量 BC 的 RLS 回填(表清单 + 回归)②配额表按租户播种
③公平调度实装(K3 就绪集查询的 `orderBy` 位已预留)④环灰度 ⑤计费隔离验证。
激活前守卫应拒绝新租户写入 —— 宁可拒绝,不可半隔离。

### 服务主体(席位登记)

worker / reconciler / 巡检以什么身份写审计,目前散落为各处的 `actor_account_id=0`。
正统方向:`accounts.account_type=service`(枚举已有,不建表),按 worker 家族分主体
(reconciler / consumer / scheduler 各一),审计可归因。**未实施** —— 现网单租户
且审计写入方有限,归因收益尚不抵改造面;新增审计写入方时一并做。
