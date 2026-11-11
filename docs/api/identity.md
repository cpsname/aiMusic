# Identity BC API 参考

> 设计:见 `internal/identity/api.go` + `internal/identity/port/http/`
> 端到端 E2E:`tests/e2e/identity/`(真实 PG)/ `http-requests/identity.http`(真 HTTP + 中间件链手工验证)。历史 `scripts/e2e/` shell 套件已于 2026-08-23 退役删除。

所有路径前缀 `/v1`。

## 公开端点(无 JWT)

### POST /v1/auth/login
密码登录。

```json
{
  "username": "alice",
  "password": "secret123"
}
```

返:
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "expires_in": 1800,
  "token_type": "Bearer",
  "account_type": "personal",
  "user_id": "uuid"
}
```

错误:
- `40101` 用户名或密码错
- `40301` 账号被锁定 / 禁用
- `42901` 登录失败次数过多(`auth.login.max_failures` 配置)

实现:`LoginHandler` → `LoginUseCase`(密码 bcrypt 验证 + Session 创建 + Token 对生成)。

### POST /v1/auth/refresh
Token 轮换。

```json
{ "refresh_token": "eyJ..." }
```

返:同 `/login` 的 `LoginResponse`(新 token 对,旧 refresh_token 加入黑名单),并回显 `account_type` / `user_id`;**游客账户额外带 `guest_id`** —— 客户端刷新后据此同步本地账户状态,无需另调 `/me`。

### POST /v1/auth/guest-register
游客注册(签名校验)。

**Header 必填**(签名链):
- `X-Device-ID` / `X-Platform` / `X-App-Version` / `X-Os-Version` / `X-Device-Model`
- `X-Signature`(HMAC-SHA256)/ `X-Timestamp` / `X-Nonce`

```json
{
  "app": {
    "distribution_code": "ios_global",
    "app_code": "studio_app",
    "bundle_id": "com.example.studio",
    "channel": "appstore"
  }
}
```

返:
```json
{
  "user_id": "uuid",
  "guest_id": "guest_a1b2c3",
  "is_new_user": true,
  "access_token": "...",
  "refresh_token": "...",
  "expires_in": 1800,
  "token_type": "Bearer"
}
```

幂等键:`(auth_type='guest_device', auth_identifier='<device_id>:<distribution_id>')` UNIQUE。同设备同分发重复调用返 `is_new_user: false`。

**App Attest(可选 `attest` 块,ADR-026)**:

```json
{
  "app": { "...": "同上" },
  "attest": {
    "key_id": "<Apple key identifier>",
    "attestation": "<标准 base64 CBOR>",        // 首次;后续改发 "assertion"
    "challenge": "<device_id>.<unix_ms>.<uuid>"  // 客户端 clientDataHash = SHA256(challenge)
  }
}
```

- 分发 acfg `attest.mode`:`off`(缺省)· `optional`(观测:失败只记日志)· `required`(缺失 / `unsupported:true` / 校验失败 → **40140**,不建号不签令牌);
  `attest.allow_development`(缺省 false)决定是否接受 Xcode 调试包的 development 环境。
- 校验:x5c 链到 Apple App Attestation Root CA · nonce 扩展 · 公钥 ↔ key_id · rpIdHash = SHA256(`<apple_team_id>.<bundle_id>`) ·
  attestation 计数 0 · aaguid 环境 · 启动校验类别(新系统带;只认 App Store / TestFlight,开发环境只认开发签名)。
  断言:签名 + 计数严格单调。challenge:device_id 与 `X-Device-ID` 一致、±5 min、单次使用。
- 密钥存 `id_device_attest_keys`(按分发 × 设备,**不随账号删除**:删号 / 重绑后设备上的密钥仍在)。
  收到 attestation 在任何档位下都校验并存钥 —— 日后切 `required` 时老安装的断言才找得到公钥。
- 分发声明 `required` 而 `iap_app_distributions.apple_team_id` 为空 → **按 optional 放行**,平台记 ERROR `device attest DEGRADED`(巡检 S16);填上 team id 后自动恢复 required(2026-09-28 修订,此前一律 40140)。
- attest 证明的是「未篡改的正版 App 实例」,**不**证明 `X-Device-ID` 归属(同一 device_id 可凭新 attestation 换钥,重装的正常路径)。

安全链:`GuestRateLimitMiddleware` → `AnomalyDetectionMiddleware` → `AppSignatureMiddleware`。

错误:
- `40140` 设备完整性校验失败(分发要求 App Attest;原因只进日志)
- `40110` 签名 header 缺失
- `40111` 签名校验失败
- `40304` app 被禁用
- `40305` distribution 被禁用
- `42902` device 限流

### POST /v1/auth/claim-entitlement
凭 Apple 签名交易把**当前设备**改绑到交易所属的游客账号(换设备恢复购买,ADR-027)。JWT(申请者 B)+ App 签名 + `X-Device-ID`。

```json
{ "signed_transaction": "<StoreKit 2 Transaction.jwsRepresentation>" }
```

返 `{"rebound": true}`;交易本就属于当前账号时 `{"rebound": false}`。

- 证据链:本地验签(x5c → Apple Root CA G3)证明「这台设备持有该交易」· App Store Server API 权威核对(存在且未撤销,
  标识字段须与本地一致)· `appAccountToken` 证明「交易归 A」· `bundleId` 须等于签名分发的 bundle。
- 改绑:`id_account_auths` 的 guest_device 行 `('<X-Device-ID>:<distribution_id>')` 从 B 改指 A(CAS:仍指向 B 才改)。
  B 的会话全部吊销(令牌随后 40104 → 客户端重新 attest → 拿到 A 的令牌);B 若**无付费订单且余额(含冻结)为 0** 则按平台既有语义软删
  (`identity.account_deleted`,各 BC 消费者照常清理)。**不合并钱包**。
- 一个账号可被多台设备的认证行指向(正式支持形态)。

错误:
- `40917` 冲突:B 有付费历史(订单 verified / completed / refunded / revoked)· A 不是游客或已注销 · 当前设备在该分发上不属于 B
- `40003` 证据不成立:签名 / 链不对 · 与 App Store 记录不一致 · 非本 App · 交易已撤销 · 无 appAccountToken · 非 Apple 分发
- 5xx 类:商店不可达 / 分发未配置 Apple 支付通道(原因见服务端日志)

## 客户端 Token 决策树

客户端发起需鉴权请求前,应按「三道防线」逐级降级 —— 而非 token 一过期就重调 `guest-register`(后者在 `device_id` 漂移时会误造新游客账号)。

```
App 启动 / 发起需鉴权请求
  │
  ▼
读安全存储 (Keychain / KeyStore) → device_id + refresh_token
  │
  ▼
防线①  access_token 本地有效? (解码 JWT exp, 提前 60s 预判)
  ├─ 是 → ✅ 直接使用 access_token
  └─ 否 ↓
防线②  refresh_token 存在且本地未过期?
  ├─ 是 → POST /v1/auth/refresh
  │         ├─ 成功 → ✅ 持久化新 token 对并使用
  │         └─ 失败 (40103 / 40104 / 40105 / 40106) → 转防线③
  └─ 否 → 转防线③
防线③  安全存储中有 device_id?
  ├─ 是 → POST /v1/auth/guest-register → ✅ 幂等命中原游客 (is_new_user=false)
  └─ 否 → 生成新 device_id → 写入 Keychain (永久保留)
            → POST /v1/auth/guest-register → ⚠️ 新游客 (is_new_user=true), 原账号不可恢复
```

**三道防线**

1. **防线① access_token 本地校验** —— 解码 JWT `exp`,提前 ~60s 判过期。有效即直接使用,不发网络请求。
2. **防线② refresh 轮换** —— access 失效时用 `refresh_token` 调 `/v1/auth/refresh`。**refresh 失败(`40103`/`40104`/`40105`/`40106`)必须回落防线③,不得直接重注册。** `40106`(refresh 已被使用)多由并发刷新引起 —— 客户端须对 refresh 加互斥,同一时刻仅一个请求在途。
3. **防线③ guest-register 幂等兜底** —— refresh 亦失效时,用持久化的 `device_id` 调 `/v1/auth/guest-register`,同设备同分发**幂等命中原游客**(`is_new_user=false`)。

**关键不变量 —— `device_id` 必须持久化**

防线③ 的幂等完全依赖 `device_id` 稳定:`device_id` **必须**存入 iOS Keychain / Android KeyStore 等安全持久存储(iOS Keychain 卸载重装后保留)。`device_id` 一旦丢失或漂移,`guest-register` 将创建**新游客账号且原账号无法找回**(`is_new_user=true`)—— 这是决策树唯一不可恢复的出口。

**服务端配套**:游客 `refresh_token` TTL 90 天(降低防线② 失守概率,见 §JWT 设计)+ refresh 响应回显 `account_type`/`guest_id`(客户端据此同步本地状态)。根治"新游客不可避免"出口 → 游客账户升级流程(绑定 email/手机迁移幂等锚点),立项见 `docs/requirements/b4-guest-account-upgrade.md`。

## 鉴权端点(JWT)

### POST /v1/auth/logout
登出当前会话。Session delete + access/refresh token 加黑名单。

返 `{ "code": 0 }`。

### POST /v1/auth/logout/all
登出账号所有会话。批量 session delete + 批量 token 黑名单。

### GET /v1/auth/me
**企业级聚合** — 一次性返 7 类用户上下文。

返(`CurrentAccountResponse`):
```json
{
  "user_id": "uuid",
  "nickname": "alice",
  "avatar_url": "...",
  "account_type": "personal",
  "email": "a***@example.com",      // 脱敏
  "phone": "138****5678",            // 脱敏
  "role": "user",
  "created_at": 1730000000,

  "status": "active",
  "is_guest": false,
  "email_verified": true,
  "phone_verified": false,
  "profile_complete": true,

  "subscription": { ... },           // 可选: SubscriptionDTO, nil = 从未订阅
  "wallet": { ... },                 // 可选: WalletDetailDTO {balance,frozen,total_credited,total_debited}
  "features": [ ... ],               // FeatureDTO[], 总是数组(可空)
  "session": { ... },                // 可选: SessionInfoDTO, 查询降级时 nil
  "guidance": { ... },               // GuidanceDTO, 纯计算总是返回
  "degraded": ["subscription"]       // 可选: 本次查询失败而置空的分支(闭集 session/wallet/features/subscription);无降级时缺席
}
```

> 🔴 **`subscription` / `wallet` 为 `null` 有两种含义**:业务上「从未订阅 / 无钱包」, 或该分支查询失败。
> 二者只能靠 `degraded` 区分 —— 列在 `degraded` 里的分支, 其 `null` **不得**当作业务事实
> (例:据此把付费用户判成免费档)。2026-09-25 起提供(Songlet 契约执行偏差 X-13);加法字段, 既有客户端无感。
> 同批修正:账号查询的**存储故障**不再被压成 `40401 账号不存在`(那会让客户端误清凭证), 改为原样 500 可重试。

> 字段以 `internal/identity/app/dto/auth.go::CurrentAccountResponse` 为权威。
> **不返回** `tenant_id`(2026-05 安全审计移除:内部 int64 且违反 bid 约定,租户上下文走 tenancy BC 的 `org_bid`),
> 也**不返回** `iap_apps` / `tenants` / `permissions`(此三项为历史文档遗留,DTO 从未含有)。

设计:**前端冷启动一次请求即可拼出用户上下文**。包含基础信息 + 账号状态 + 订阅 + 积分配额 + 功能权益 + 会话安全 + 前台引导。

实现:`AuthHandler.Me` → `GetCurrentAccountHandler.Handle`(`internal/identity/app/query/me_handler.go`)——
**4 路并行扇出**:Account(必须,失败即错)/ Session(可选)/ Wallet + Features(可选,经
`identityPort.WalletQueryPort` 桥接 `wallet.WalletAPI`)/ Subscription(可选,经 `SubscriptionQueryPort` 桥接 `iap`)。
可选路失败**降级为 `null` 不阻断**(WARN 日志)。

> **积分字段与 `GET /v1/wallet` 同源不同用**:`data.wallet` 与 `/v1/wallet` 都出自
> `WalletSummaryHandler.GetWalletDetail`,字段集一致,**不是两套口径**。本端点是冷启动聚合(还要查会话计数与订阅),
> **不要拿它做余额轮询** —— 刷积分胶囊/看 `frozen` 变化走 `GET /v1/wallet`,看流水走 `GET /v1/wallet/ledger`。
> 分工表见 [wallet.md](wallet.md#get-v1wallet)。

## Module API(跨 BC 调用)

`identity.IdentityAPI` interface 仅 2 方法:

```go
ResolveAccountByBID(ctx, bid string) (*AccountInfoDTO, error)
ResolveAccountByID(ctx, accountID int64) (*AccountInfoDTO, error)
```

`AccountInfoDTO`:
```go
type AccountInfoDTO struct {
    AccountID    int64
    BID          string  // UUID, 对外暴露
    Nickname     string
    Status       string
    AccountType  string  // personal / guest / developer
    Role         string
    TenantID     int64
}
```

调用方:Tenancy(membership 关联)/ Catalog(actor 解析)/ Wallet(account 校验)等。

## JWT 设计

- 算法:HS256
- Claims:`abid`(account BID UUID)/ `role` / `sid`(session id)
- access_token TTL:1800s(默认,可配)
- refresh_token TTL:普通账户 **7 天** / 游客账户 **90 天**(均可配:`auth.token.refresh_token_ttl` / `auth.token.guest_refresh_token_ttl`)。游客无凭据可重登,长窗口降低 refresh 过期后回落 guest-register 的概率
- Sessions 持久化:Redis Hash,key = `session:<sid>`,绑定 `device_id` + `distribution_id`
- Token 哈希:SHA-256 入 sessions 和黑名单,**绝不**存 raw JWT

## RequestMeta(中间件注入)

公开 + 鉴权路径都经过 `RequestMetaMiddleware` 解析以下 Header → context:
- `X-Device-ID` / `X-Platform`(`ios/android/web`)/ `X-App-Version`
- `X-Os-Version` / `X-Device-Model`
- `X-Language` / `X-Timezone`

handler 通过 `middleware.GetRequestMeta(ctx)` 读取。

## 错误码段

- `401xx` Authentication 失败
- `403xx` 账号 / app 状态(locked / disabled)
- `404xx` Not Found(account 不存在)
- `429xx` Rate Limit
- `400xx` Validation(weak password / invalid param / 签名 header)
- `500xx` Server

详见 `internal/identity/domain/errors.go` + `port/http/errors.go`(域 sentinel → HTTP code 映射)。

## 审计

`id_audit_logs`(分区表)记录登录 / 登出 / 黑名单事件。`EntAuditLogRepository` 用 raw SQL 写入,fallback to logger。

## 起跳点(留下次)

- SSO / LDAP 集成(P5-01)
- 多因素认证(MFA)
- API Key(明确不做开放平台 / brief 锁定)

## OpenAPI 3.1 Specification

> 基于代码事实生成。来源:`internal/identity/port/http/{routes,auth_handler}.go` + `app/dto/{login,auth,guest_register}.go` + `app/command/*_handler.go` + `domain/errors.go::GetErrorCode`。
>
> 公共契约见 [overview.md](overview.md)。多数业务错误返 HTTP 200 + 业务码(响应头与 nginx/CDN 友好)。

```yaml
openapi: 3.1.0
info:
  title: AIGC Platform — Identity Domain API
  description: |
    Identity BC 6 endpoints: 登录 / 刷新 / 游客注册 / 登出 / 全端登出 / 当前账号详情.
    JWT HS256 颁发. Guest 注册走专属限流 + 异常检测中间件.
  version: "1.0.0"

servers:
  - url: https://api.aigc.example.com/v1
  - url: http://localhost:9999/v1

# 默认全部要求 App 签名 (JWT 各端点单独覆盖)
security:
  - DistributionCode: []
    Timestamp: []
    Nonce: []
    AppSignature: []

components:
  securitySchemes:
    BearerAuth: { type: http, scheme: bearer, bearerFormat: JWT }
    DistributionCode: { type: apiKey, in: header, name: X-Distribution-Code }
    Timestamp: { type: apiKey, in: header, name: X-Timestamp }
    Nonce: { type: apiKey, in: header, name: X-Nonce }
    AppSignature: { type: apiKey, in: header, name: X-App-Signature }

  schemas:
    StandardResponse:
      type: object
      required: [code, message, request_id, timestamp]
      properties:
        code: { type: integer, example: 0 }
        message: { type: string, example: success }
        data: {}
        request_id: { type: string, format: uuid }
        timestamp: { type: integer, format: int64, description: Unix 秒 }

    ErrorResponse:
      type: object
      required: [code, message, request_id, timestamp]
      properties:
        code: { type: integer }
        message: { type: string }
        details:
          type: object
          additionalProperties: { type: string }
          description: 仅 ValidationFailed 返
        request_id: { type: string }
        timestamp: { type: integer, format: int64 }

    LoginRequest:
      type: object
      required: [username, password]
      properties:
        username: { type: string }
        password: { type: string, minLength: 6 }

    RefreshTokenRequest:
      type: object
      required: [refresh_token]
      properties:
        refresh_token: { type: string }

    AppRequest:
      type: object
      required: [distribution_code, app_code, bundle_id, channel]
      properties:
        distribution_code: { type: string, description: 分发版本唯一码 }
        app_code: { type: string }
        bundle_id: { type: string }
        channel: { type: string, description: 分包渠道 }

    GuestRegisterRequest:
      type: object
      required: [app]
      properties:
        app: { $ref: '#/components/schemas/AppRequest' }

    LoginResponse:
      type: object
      required: [access_token, refresh_token, expires_in, token_type]
      description: 登录 / 刷新共用响应 (dto.TokenResponse = LoginResponse).
      properties:
        access_token: { type: string, description: JWT HS256 (Claims abid/role/sid/iat/exp) }
        refresh_token: { type: string }
        expires_in: { type: integer, format: int64, description: 秒级 TTL (access token) }
        token_type: { type: string, example: Bearer }
        account_type: { type: string, description: "回显账户类型: personal / guest / enterprise / service (omitempty)" }
        user_id: { type: string, format: uuid, description: "账户 BID (omitempty)" }
        guest_id: { type: string, description: "游客用户名 guest_<hex>; 仅 account_type=guest 时返回 (omitempty)" }

    GuestRegisterResponse:
      type: object
      required: [user_id, guest_id, is_new_user, access_token, refresh_token, expires_in, token_type]
      description: dto.GuestRegisterResponse — 独立结构 (非 LoginResponse 派生; 无 account_type 字段).
      properties:
        user_id: { type: string, format: uuid, description: Account BID }
        guest_id: { type: string, description: 游客用户名 guest_<hex> }
        is_new_user: { type: boolean, description: 幂等性标记; 同设备同分发重复调用为 false }
        access_token: { type: string }
        refresh_token: { type: string }
        expires_in: { type: integer, format: int64, description: 秒级 TTL (access token) }
        token_type: { type: string, example: Bearer }

    SubscriptionDTO:
      type: object
      properties:
        status: { type: string }
        billing_cycle: { type: string }
        is_auto_renew: { type: boolean }
        current_period_end: { type: integer, format: int64 }
        trial_end_at: { type: integer, format: int64, nullable: true }

    WalletDetailDTO:
      type: object
      properties:
        balance: { type: integer, format: int64 }
        frozen: { type: integer, format: int64 }
        total_credited: { type: integer, format: int64 }
        total_debited: { type: integer, format: int64 }

    FeatureDTO:
      type: object
      required: [feature_code, source]
      properties:
        feature_code: { type: string }
        feature_name: { type: string }
        source: { type: string, description: iap_purchase / iap_subscription / admin_grant }
        granted_at: { type: integer, format: int64 }
        expires_at: { type: integer, format: int64, nullable: true, description: 永久权益时为空 }

    SessionInfoDTO:
      type: object
      properties:
        login_time: { type: integer, format: int64 }
        login_ip: { type: string }
        login_auth_type: { type: string }
        device_id: { type: string }
        active_session_count: { type: integer }

    GuidanceDTO:
      type: object
      required: [needs_profile_complete, has_active_subscription, has_credits]
      properties:
        needs_profile_complete: { type: boolean }
        has_active_subscription: { type: boolean }
        has_credits: { type: boolean }

    CurrentAccountResponse:
      type: object
      required: [user_id, nickname, account_type, role, status, is_guest, features, guidance]
      properties:
        user_id: { type: string, format: uuid }
        nickname: { type: string }
        avatar_url: { type: string }
        account_type: { type: string, enum: [personal, guest] }
        email: { type: string, description: "脱敏: a***@example.com" }
        phone: { type: string, description: "脱敏: 138****5678" }
        role: { type: string, enum: [user, creator, developer, admin, super_admin] }
        created_at: { type: integer, format: int64 }
        status: { type: string, enum: [active, frozen, disabled] }
        is_guest: { type: boolean }
        email_verified: { type: boolean }
        phone_verified: { type: boolean }
        profile_complete: { type: boolean }
        subscription:
          $ref: '#/components/schemas/SubscriptionDTO'
          nullable: true
        wallet:
          $ref: '#/components/schemas/WalletDetailDTO'
          nullable: true
        features:
          type: array
          items: { $ref: '#/components/schemas/FeatureDTO' }
          description: 总是非 nil 数组(可为空)
        session:
          $ref: '#/components/schemas/SessionInfoDTO'
          nullable: true
          description: 降级时 nil
        guidance:
          $ref: '#/components/schemas/GuidanceDTO'
          description: 纯计算, 总是返回
        degraded:
          type: array
          items: { type: string, enum: [session, wallet, features, subscription] }
          description: 查询失败而置空的可选分支;无降级时缺席。列在其中的分支, 其 null 不是业务事实

paths:
  /auth/login:
    post:
      summary: 用户名密码登录
      operationId: login
      tags: [Auth]
      security:
        - DistributionCode: []
          Timestamp: []
          Nonce: []
          AppSignature: []
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/LoginRequest' }
      responses:
        '200':
          description: 登录成功
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/LoginResponse' }
        '400':
          description: 参数无效 (40003) / 密码弱 (40002)
        '401':
          description: 登录失败 (40101 用户名或密码错误)
        '403':
          description: 账户锁定 (40301) / 冻结 (40302) / 禁用 (40303)
        '429':
          description: 登录尝试次数过多 (42901)

  /auth/refresh:
    post:
      summary: 刷新 access token (refresh token rotation)
      operationId: refresh
      tags: [Auth]
      security:
        - DistributionCode: []
          Timestamp: []
          Nonce: []
          AppSignature: []
      description: |
        Refresh Token 在 Body 中传递 (非 Cookie). 验证后旧 Session 标记已消费,
        旧 Token 加入黑名单, 创建新 Session.
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/RefreshTokenRequest' }
      responses:
        '200':
          description: 刷新成功
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/LoginResponse' }
        '401':
          description: |
            40103 refresh token 无效 / 过期
            40104 token 已撤销
            40105 session 不存在
            40106 refresh token 已被使用 (重放保护)

  /auth/guest-register:
    post:
      summary: 游客注册 (基于 device + distribution 幂等)
      operationId: guestRegister
      tags: [Auth]
      security:
        - DistributionCode: []
          Timestamp: []
          Nonce: []
          AppSignature: []
      description: |
        额外中间件: GuestRateLimit (设备维度 10 req/min) + AnomalyDetection (告警不阻断).
        同设备同分发再调返已存在账号 (is_new_user=false).
        必填 X-Device-ID + X-Platform header.
      parameters:
        - in: header
          name: X-Device-ID
          required: true
          schema: { type: string }
        - in: header
          name: X-Platform
          required: true
          schema: { type: string, enum: [ios, android, web, desktop] }
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/GuestRegisterRequest' }
      responses:
        '200':
          description: 注册或登录成功
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/GuestRegisterResponse' }
        '404':
          description: 应用不存在 (40402)
        '403':
          description: 应用已禁用 (40304)
        '429':
          description: 请求过频 (42902)

  /auth/logout:
    post:
      summary: 登出当前会话
      operationId: logout
      tags: [Auth]
      description: |
        当前 SessionID 对应的 token 加入 Redis 黑名单. 不需 body.
      responses:
        '200':
          description: "登出成功 (data: null)"
          content:
            application/json:
              schema: { $ref: '#/components/schemas/StandardResponse' }
      security:
        - BearerAuth: []
          DistributionCode: []
          Timestamp: []
          Nonce: []
          AppSignature: []

  /auth/logout/all:
    post:
      summary: 全设备登出
      operationId: logoutAll
      tags: [Auth]
      description: 该 Account 的所有 Session 批量加黑名单
      responses:
        '200':
          description: "全端登出成功 (data: null)"
          content:
            application/json:
              schema: { $ref: '#/components/schemas/StandardResponse' }
      security:
        - BearerAuth: []
          DistributionCode: []
          Timestamp: []
          Nonce: []
          AppSignature: []

  /auth/me:
    get:
      summary: 当前账号详情 (4 路并行聚合)
      operationId: getCurrentAccount
      tags: [Auth]
      description: |
        4 路并行查询: Account (必须) + Session (可选) + Wallet+Features (可选) + Subscription (可选).
        非 Account 失败时降级返 nil, 不阻断主响应.
      responses:
        '200':
          description: 账号详情
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/CurrentAccountResponse' }
        '404':
          description: 账号不存在 (40401)

# 错误码段 (来源 internal/identity/domain/errors.go::GetErrorCode L37-97)
# 注: 多数业务错误返 HTTP 200 + 业务码 (overview.md §6.3 设计约定)
#
# 40002 ErrPasswordTooWeak           密码强度不足
# 40003 ErrInvalidParam              请求参数不合法
# 40101 ErrInvalidPassword           用户名或密码错误
# 40102 ErrTokenInvalid/Expired      访问令牌无效或已过期
# 40103 ErrRefreshTokenInvalid       刷新令牌无效或已过期
# 40104 ErrTokenRevoked              令牌已被撤销
# 40105 ErrSessionExpired/NotFound   会话无效或已过期
# 40106 ErrRefreshTokenReused        刷新令牌已被使用 (重放保护)
# 40107 ErrRefreshTokenMismatch      刷新令牌无效
# 40301 ErrAccountLocked             账户已锁定
# 40302 ErrAccountFrozen             账户已冻结
# 40303 ErrAccountDisabled           账户已禁用
# 40304 ErrAppDisabled               应用已禁用
# 40401 ErrAccountNotFound           账户不存在
# 40402 ErrAppNotFound               应用不存在
# 42901 ErrTooManyAttempts           登录尝试次数过多
# 42902 ErrDeviceRateLimited         请求过于频繁
```
