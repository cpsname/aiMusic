# 后端协作契约（Backend Coordination）

> 模板的客户端基建有若干能力**必须后端配合**才能闭环。本文件把所有后端侧义务集中列出，便于直接交付后端团队。
> 重头是 §2 **App Store Server Notifications V2**——它是订阅"服务端唯一真相源"的落脚点，没有它，续订/退款/撤销只能靠客户端碰巧在线时才反映（参见 `STOREKIT2_PURCHASE_SPEC.md` §8.1）。

---

## 0. 总览：客户端需求 ↔ 后端义务

| 客户端需求 | 后端义务 | 本文件 |
|---|---|---|
| HMAC 签名抗时钟偏移 | `/app/init` 回权威服务器时间 + 放宽时间窗 | §1 |
| 订阅权益准确（续订/退款/宽限期） | 接 ASSN V2 webhook，服务端维护 entitlement | §2 |
| 恢复购买 / 对账 | App Store Server API 查询订阅状态/交易历史 | §3 |
| 取消孤儿单回收（SPEC 纠偏点） | 明确订单生命周期与过期作废语义 + verify 幂等 | §4 |
| 宽限期感知门控 | `/me`、`/wallet` 暴露 `renewalState` | §5 |
| 生产可观测性对账 | 稳定回传 `request_id`；可选事件 ingestion | §6 |
| 远程配置/kill-switch/维护态 | `/app/init` 下发开关与最小版本 | §7 |
| App 内账号删除（App Store 强制） | 账号删除 + 数据导出端点 | §8 |
| 推送 + 深链 | 设备 token 注册 + 通知 payload 约定 | §9 |
| 媒体预览/下载 | 预签名（短时效）下载 URL | §10 |

---

## 1. 服务器权威时间

- `/app/init` 响应包含 `server_time`（Unix epoch **毫秒**，UTC）。
- 建议每个响应附 `X-Server-Time` 头，供客户端持续滑动校正时钟 offset。
- 签名校验：时间戳容忍窗 **±N 分钟**（建议 ±5），配合 `nonce` 去重防重放（服务端缓存近窗 nonce）。
- 客户端据此计算 offset 并用于后续所有 HMAC 签名（见 `DEEP_FOUNDATIONS_SPEC.md` §1）。

---

## 2. App Store Server Notifications V2（订阅服务端真相源）⭐

后端在 App Store Connect 配置 **生产 + 沙盒两个** HTTPS webhook URL，接收 V2 通知并据此维护用户订阅 entitlement。客户端不再依赖本地交易判断权益。

### 2.1 安全与解析
- 通知体 `signedPayload` 为 **JWS**，须用 Apple `x5c` 证书链验签（根证书钉到 Apple Root CA）。
- 解码 `data.signedTransactionInfo` 与 `data.signedRenewalInfo`（亦为 JWS）。
- 按 `notificationUUID` **幂等去重**；区分 `environment`（Sandbox/Production）分别入对应账本。

### 2.2 须处理的通知类型 → entitlement 动作

| notificationType | subtype | entitlement 动作 |
|---|---|---|
| `SUBSCRIBED` | `INITIAL_BUY` / `RESUBSCRIBE` | 开通/重开权益 |
| `DID_RENEW` | 空 / `BILLING_RECOVERY` | 续期权益到新到期日（recovery=计费重试后恢复）|
| `DID_FAIL_TO_RENEW` | `GRACE_PERIOD` | **继续供权益**，进入宽限期 |
| `DID_FAIL_TO_RENEW` | 空 | 进入计费重试、**未在宽限期 → 停止供权益** |
| `GRACE_PERIOD_EXPIRED` | — | 宽限期满仍未付 → **移除权益** |
| `EXPIRED` | `VOLUNTARY`/`BILLING_RETRY`/`PRICE_INCREASE` | 订阅到期 → 移除权益 |
| `DID_CHANGE_RENEWAL_STATUS` | `AUTO_RENEW_ENABLED/DISABLED` | 记录自动续订开关（权益维持到期日不变）|
| `DID_CHANGE_RENEWAL_PREF` | `UPGRADE`/`DOWNGRADE` | 升降级：升级即时、降级下周期生效 |
| `OFFER_REDEEMED` | — | 优惠/促销码兑换入账 |
| `REFUND` | — | 退款 → 立即移除对应权益 |
| `REFUND_DECLINED` / `REFUND_REVERSED` | — | 退款被拒/撤销 → 相应恢复 |
| `REVOKE` | — | Family Sharing 撤销 → 移除被授予权益 |
| `PRICE_INCREASE` / `RENEWAL_EXTENDED(_STATUS)` | — | 记录/通知，按需调整 |
| `CONSUMPTION_REQUEST` | — | （如有消耗型）按退款消耗信息请求响应 |

> 完整且权威的类型/子类型以 Apple 文档为准；上表覆盖订阅生命周期主干。

### 2.3 已知坑（务必容错）
- `DID_FAIL_TO_RENEW` 即便子类型为 `GRACE_PERIOD`，`gracePeriodExpiresDate` **也可能为 null** → 不能直接用它写库；回退到 App Store Server API 查 `Get All Subscription Statuses` 取准确状态/到期。
- 一次用户操作可能伴随多条通知 → 全程以 `notificationUUID` + 状态机收敛，不重复入账。

---

## 3. App Store Server API（对账与恢复）

- 后端可用 originalTransactionId 调：
  - **Get All Subscription Statuses** — 拉某用户全部订阅组当前状态（恢复购买、ASSN 缺字段时的真相回退）。
  - **Get Transaction History** — 交易历史对账。
- 客户端"恢复购买"流：`restorePurchases()` → 客户端拿到 `originalTransactionId` 提交 → 后端用 Server API 核验并刷新 entitlement（见 SPEC §8.6）。
- 客户端 `verify` 提交的交易凭证，后端同样用 Server API/JWS 验签确认，**不信任客户端自报权益**。

### 3.1 `appAccountToken` 直查账户(客户端已接入,需后端配套)⭐

客户端现在**每次购买都把账户 BID(UUID)绑定到交易**,免去后端用 `originalTransactionId` 反查账户:

- **客户端已做**:① 发起 StoreKit 2 购买时把账户 `abid`(UUID)设为 `appAccountToken`(Apple 会写进 `Transaction.appAccountToken` 并在**每条 ASSN V2 通知**的 JWSTransaction 回显);② `POST /iap/orders` 携带 `push_token = <abid>`(同一 UUID)。仅当 `abid` 是合法 UUID 才发送(游客用其 UUID `abid`,非 `guest_id`)。
- **需后端配套**:
  1. `POST /iap/orders` 接收并落库 `push_token`(把订单预绑定到账户)。
  2. **Webhook 处理器从 JWSTransaction 读 `appAccountToken`,优先据此直查账户**;缺失时(本次改动前的历史交易无此字段)回落 `originalTransactionId` 反查。续订/恢复的通知同样携带原购买的 `appAccountToken`。
- **命名**:客户端请求字段叫 `push_token`(沿用你的叫法);对应 Apple 字段是 `appAccountToken`。如需统一可改名 `app_account_token`,请与客户端对齐。
- **账号迁移**:游客升级为正式账户后,历史交易的 `appAccountToken` 仍指向游客 `abid` → 后端按账号迁移锚点映射。

---

## 4. 订单生命周期语义（解决 SPEC 的【纠偏】点）

`STOREKIT2_PURCHASE_SPEC.md` §6 留了一个待定：**用户取消产生的孤儿 pending 单**如何回收。需后端明确：

- 订单状态机与字段：`created → paid → verified` / `expired` / `cancelled`，含 `expires_at`。
- **未支付订单是否在 `expires_at` 后自动作废**？客户端据此决定取消时是立即删本地 pending，还是保留带 TTL 等服务端作废。
- `verify` **幂等**保证：同一 `orderNo` 重复校验返回一致结果（`40011` 交易已用即幂等体现）。
- `40912`(乐观锁)/`50000/50301/50302` 等可重试码的语义与建议退避，确认与客户端退避一致。

---

## 5. 权益 / 订阅态契约

- `/me` 订阅段 与 `/wallet` 须暴露由 ASSN 维护的 **`renewalState`**：`subscribed / expired / inBillingRetryPeriod / inGracePeriod / revoked`，及 `expiresAt`、`autoRenew`。
- 客户端据此做**宽限期感知门控**：宽限期内仍放行，计费重试期提示更新支付方式，而非立即锁权益。
- features/flags 的 `active + expiresAt` 语义与 `hasFeatureProvider` 对齐。

---

## 6. 可观测性对账

- 错误响应稳定回传 `request_id`（已在 envelope），客户端将其带入遥测便于支持端到端定位。
- （可选）提供客户端事件 ingestion 端点，或后端在 order/verify 生命周期自发 IAP 漏斗事件，与客户端漏斗对账（见 `DEEP_FOUNDATIONS_SPEC.md` §2）。

---

## 7. 远程配置 / Kill-switch / 维护态

- **维护 / kill-switch / 远程配置** 现由独立端点 **`GET /app/config`**(`appconfig.md`,
  与 `/app/init` 严格分离、零字段重叠)下发。**客户端已接入**(`app_config` 包):App 签名读取、
  fail-open、启动 + 前台节流刷新(≥60s)、维护门(优先级 **强更 > 维护**)、kill-switch 入口门控、
  远程参数(`config`)。
- `/app/init` 仅保留 `min_supported_version` / 强制更新(版本治理启动快照);**严禁**把维护/开关塞入。
- 出事可远程关功能而不发版;运营写侧(SetMaintenance/SetKillSwitches/Upsert)经 IAM-admin
  Module API(非本端职责,见 `appconfig.md`)。

---

## 8. 账号删除 / 数据导出（合规）

- App Store 要求：有账号体系则必须 **App 内可发起账号删除** → 后端提供删除端点（含游客→正式账号的处理）。
- 数据导出端点（GDPR/隐私法规域）。
- 与 `DEEP_FOUNDATIONS_SPEC.md` §4 隐私清单配套。

**客户端现状（2026-08-27）**：游客生命周期的删除已在客户端交付——
`AuthController.deleteAccount()` 销毁 Keychain `device_id`（游客注册按该 id 幂等，
旧游客自此永久不可达）并立即注册全新游客；Profile 仅对游客显示删除入口。
**仍需后端**：① 正式账号（用户名/密码及未来第三方登录）的删除端点——本地擦除对
正式账号只是伪删除；② 被遗弃游客的服务端数据清退策略（孤儿数据仍留在服务端）。
端点落地后，其调用应加在 `deleteAccount()` 顶部（本地擦除之前）。

---

## 9. 推送 token 注册 + 深链

- 设备 token 注册/注销端点（按 deviceId + userId）。
- 通知 payload 约定深链 schema（如跳 paywall / restore / 某 task），映射到 `StudioShell`。

---

## 10. 媒体预签名下载 URL

- AIGC 产物（图/视频/音频）经**短时效预签名 URL** 下发，客户端用于预览/下载/分享（配合 `gal` / `share_plus`）。
- 约定有效期、续签方式与防盗链策略。
