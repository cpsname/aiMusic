# IAP BC API 参考

> 设计:`internal/iap/api.go` + `internal/iap/port/http/`
> 关联:`docs/architecture/iap/grant-model.md`(权益授予模型)

所有路径前缀 `/v1`。

## 公开端点(无 JWT)

### POST /v1/app/init
应用初始化 — 客户端启动时拉取 app + distribution + 商品列表 + 配置。

```json
{
  "distribution_code": "ios_global",
  "client_version": "1.2.0"
}
```

返:`AppInitResponse`(server_time / 产品列表 / **支付通道列表** / 合规链接 / 强制更新提示)。

**支付通道下发**(2026-07-23):响应含 `payment_channels` —— 本分发**启用**的支付方式列表(按 `sort_order` 升序),客户端据此渲染支付方式选择器(如 web 分发 `[支付宝, 微信支付]`)。商品 `products[].store_platform`:`apple`/`google`=商店内购(走 StoreKit/BillingClient,用 `store_product_id`);**`native`**=支付无关商品(任何扫码/网页支付方式都能买),客户端展示 `native` 商品 + 支付方式选择器,下单时带 `payment_method`(见 create-order)。**安全**:`payment_channels` 只暴露 `store_platform`+`sort_order`,商户凭证等内部结算维度绝不下发;展示文案由客户端按 `store_platform` 本地映射。空 `payment_channels` = 纯 Apple/Google 商店内购。热路径经 Redis 缓存(2min TTL,与商品同纪律)。

**web 商品阶梯参考**(`aigc.studio.web` 分发,native 积分消耗包;seed `docs/migrations/20260723_iap_web_native_credits_seed.sql`)。定价 = `round(价CNY × (1−0.006) / 0.036)`(web 渠道费率 0.6%,`v_credit=0.036` 宪法常数;`cmd/creditcalc -commission 0.006 <价>` 核算),面值/积分全档 ≈¥0.0362(线性无赠送 → 不亏,结构性 64% 毛利):

| product_code | store_platform | price_cents | currency | grant_type | quota_amount(积分) |
|---|---|---|---|---|---|
| `credits_12`  | native | 1200  | CNY | quota | 331  |
| `credits_30`  | native | 3000  | CNY | quota | 828  |
| `credits_68`  | native | 6800  | CNY | quota | 1878 |
| `credits_128` | native | 12800 | CNY | quota | 3534 |
| `credits_298` | native | 29800 | CNY | quota | 8228 |

web 分发的 `app/init` 响应示例(`native` 商品 + `payment_channels`):
```json
{
  "server_time": 1753257600000,
  "products": [
    { "product_code": "credits_12", "store_product_id": "", "store_platform": "native",
      "product_kind": "consumable", "name": "Credits Pack XS",
      "price_cents": 1200, "currency": "CNY", "grant": { "type": "quota", "credits": 331 } },
    { "product_code": "credits_68", "store_product_id": "", "store_platform": "native",
      "product_kind": "consumable", "name": "Credits Pack M", "highlight_tag": "popular",
      "price_cents": 6800, "currency": "CNY", "grant": { "type": "quota", "credits": 1878 } }
  ],
  "payment_channels": [ { "store_platform": "alipay", "sort_order": 0 } ],
  "legal": { "privacy_url": "...", "terms_url": "..." }
}
```
客户端拿到 `native` 商品 + `payment_channels=[alipay]` → 渲染「¥12 / 331 积分」等档位 + 「支付宝」按钮 → 下单带 `payment_method=alipay`(见 create-order)。**禁止**建 `store_platform=wechat/alipay` 的商品(支付方式属通道维度,商品不按其特化)。

### POST /v1/webhook/apple/:distribution_code
Apple Server-to-Server (S2S) 通知 webhook(StoreKit 2 / App Store Server Notifications V2)。

也支持 `POST /v1/webhook/apple`(不带 path 参数,从 payload 解析 bundleID 反查 distribution)。

**Header**:
- `Content-Type: application/json`
- 内含 JWS signed payload(Apple 签名)

**Body**(Apple 标准 V2):
```json
{
  "signedPayload": "eyJhbGc..."
}
```

行为:
- JWS 验签(Apple 公钥链 X5C)
- 解码 `notificationType`(SUBSCRIBED / DID_RENEW / EXPIRED / REFUND / DID_CHANGE_RENEWAL_STATUS / ...)
- 落 `iap_store_notifications`(分区表)
- 同 tx 触发对应权益操作:
  - `SUBSCRIBED` / `DID_RENEW` → `iap.subscription_renewed` Outbox 事件 → Wallet BC 消费授予积分
  - `REFUND` → **退款终局一致性**(2026-08-02):订单转 refunded(审计三字段落库)+
    积分回收 + features 双 scope 撤销 + **当期订阅交易同事务终结订阅(→revoked)**并发
    `iap.subscription_expired`;已退款用户 `/me` 立即显示 `revoked`,不再"订阅中"。
    旧周期退款只退订单不动订阅;本地无订单的孤儿退款仍终结订阅(退款是权威事实)。
    设计:`docs/architecture/design/iap-refund-subscription-termination.md`
  - `REFUND_REVERSED` → 对偶恢复:订单还原 + 积分/features 重发 + 订阅按
    `RestoreFromRevoke` 推导恢复(周期已过→expired / 曾关续订→canceled / 否则→active);
    与 `REVOKE` 并存时不自动恢复,留人工复核(fail-safe)
  - `EXPIRED` → 标记订阅 expired
  - `CONSUMPTION_REQUEST` → 退款仲裁消费数据回报(见下)+ **仲裁期定点冻结**
    (config `platform.iap.arbitration_hold`,设计 `iap-arbitration-hold.md`,2026-08-02
    裁决**整钱包**):冻结账户全部剩余积分,堵"申请退款后狂烧"套利;报在前冻在后
    (防污染消费比例,第 2/3 次通知的比例经 hold 中归属本订单的份额 OrderHeld 还原);
    REFUND → 单事务**拆分结算**(被退订单份额回收,其余订单份额还回 — 不没收未退款
    订单的付费积分)/ REFUND_DECLINED → 全额释放 / 用户撤回(苹果无通知)→ TTL(72h)
    worker 兜底释放。wallet 账本即唯一真相源(freeze 流水 description
    `arbitration:order:<id>` 前缀),iap 零台账

幂等:`(distribution_id, transaction_id, notification_type)` 复合 UNIQUE。

实现:`WebhookHandler.HandleAppleNotification` → `ProcessAppleNotificationCommand`。

#### CONSUMPTION_REQUEST 消费数据回报(退款仲裁,2026-08-02)

用户向苹果申请退款 → 苹果发 `CONSUMPTION_REQUEST`,商户 **12 小时内**可调
Send Consumption Information **V2**(`PUT /inApps/v2/transactions/consumption/{transactionId}`)
回报消费数据参与仲裁。偏好只是苹果的"参考因素之一,非保证"——不存在字面"硬拒绝",
本实装把拒绝胜率最大化:真实消费证据 + `DECLINE` 偏好 + 窗口内必达。

回报策略(`handleConsumptionRequest` → `buildConsumptionInfo`)。**两类字段两套纪律**:事实字段
(`deliveryStatus` / `consumptionPercentage` / `sampleContentProvided`)必须照实上报;立场字段
(`refundPreference`)由 config 方针**全场景一致表态**,与交付状态解耦。

| 场景 | deliveryStatus | consumptionPercentage | refundPreference |
|---|---|---|---|
| 订单存在且 `grant_status=granted` | `DELIVERED` | Wallet 口袋 `(granted−remaining)/granted` 千分单位(过期口袋/查询失败/纯 feature 商品 → 不申报) | config 方针(现网 `DECLINE`) |
| 无本地订单 / 发放失败 | `UNDELIVERED_OTHER` | 显式 `0`(苹果硬性要求) | **同为 config 方针**(2026-08-02 硬拒绝立场:未交付不等于放弃表态) |
| **自动续订订阅**(覆盖以上两行) | 同上 | **整字段省略** | 同上 |

> ⚠️ **订阅硬约束**(2026-08-02 沙盒真机验收实测):`consumptionPercentage` **不支持自动续订订阅**,
> 上送即整个请求被苹果拒收(`4000209 The consumption percentage field is not supported for
> auto-renewable subscription transactions`),苹果按订阅时长自行计算消耗。**未交付路径的显式 0 同样不能带**。
> 判定见 `port.IsAutoRenewableSubscription`(匹配 Apple 原值 `Auto-Renewable Subscription`)。
> 现网 4 起真实退款中 3 起是订阅——漏此闸等于多数场景回报照样发不出去。
> 双向守卫:`TestAcceptance_AppleConsumptionV2_PercentageRejectedForSubscription`(负向对照,
> 锁住加闸依据;若苹果放开限制该测试会失败并提示可放开闸)+ `_Sandbox_AutoRenewable`(正向,已实测 2xx)。

> 苹果侧**不存在商户否决权**——`refundPreference` 官方定位是仲裁的"参考因素之一,非保证"。
> 未交付场景苹果看得到我们自报的 `UNDELIVERED_OTHER`,大概率仍会准退;表态本身零成本,
> 但事实字段不得为迎合立场而粉饰(苹果有 StoreKit 侧信号可交叉核对,伪造反噬整条证据链)。
> config `refund_preference` 留空即全场景不表态(方针始终可回退,有 `TestConsumptionRequest_PreferenceStillConfigDriven` 守卫)。

配置(`platform.iap.consumption_report`):
- `customer_consent_obtained`:**合规闸**。苹果契约 `customerConsented` 非 true 必 400
  (4000035 InvalidCustomerConsentedError),且要求用户协议/隐私政策含**显式 opt-in**
  "同意向 Apple 分享消费数据用于退款审核"条款(不接受 ATT 弹窗替代)。
  false = 跳过回报仅记审计(prod 默认 false,补齐协议条款后开 true)。
- `refund_preference`:`decline` / `grant_full` / `grant_prorated` / 空=不表态;未知值 WARN + 不表态。
- `sample_content_provided`:购买前是否提供过免费样品/试用内容(产品事实)。

**真机验收**(2026-08-02 已跑通,门控默认跳过):

```bash
# source .env 带主密钥;打真实 Apple sandbox 网关
RUN_APPLE_CONSUMPTION_ACCEPTANCE=1 go test ./tests/e2e/iap/ -run TestAcceptance_AppleConsumptionV2 -v
# 可选 APPLE_ACCEPTANCE_TXN_ID=<沙盒 transactionId> 覆盖标的(沙盒交易有生命周期)
```

沙盒也支持完整退款流程验收(苹果会在沙盒发 `CONSUMPTION_REQUEST`,但回复窗口是
**5 分钟**而非生产的 12 小时);在 refund sheet 的 Issue 选 Other 并输入 `DECLINE`
可让苹果回 `REFUND_DECLINED`。⚠️ 沙盒裁决由测试者输入决定,**不受**我方 `refundPreference`
影响——沙盒只能验证链路通,胜率只能看生产统计。步骤详见测试文件尾部注释。

可靠性(12h 窗口硬约束):
- 发送失败 → 通知标 `failed` + webhook 返 5xx → 苹果官方节奏重投(1h/12h/...);
- 幂等检查对「failed 的 CONSUMPTION_REQUEST 且距首次落库 < 12h」**放行重处理**
  (复用已有行不重插;其余通知幂等语义不变),超窗后幂等跳过;
- 环境路由:通知 `environment` 决定打 prod / sandbox host(退款仲裁须回到交易环境);
- 消耗数据源:`WalletAPI.GetPocketConsumptionBySourceOrder`(iap→wallet 只读桥,
  与 `RevokeCredits` 的口袋回收判据同源)。
- 审计:每次请求发 `iap.consumption_request_received` Outbox 事件(SourceRef 幂等);
  仲裁结果由后续 `REFUND` / `REFUND_DECLINED` 通知闭环。

### POST /v1/webhook/wechat  (回调自描述,无分包参数)
微信支付 v3 Native 支付结果回调(2026-07-05,`wechat-native-pay-plan.md`)。公开端点,`/v1/webhook/` 在 SkipPaths 跳过 App 签名;验签走微信支付**公钥模式**。

> **回调自描述(支付通道解耦 P1,2026-07-22)**:路由**去掉 `:distribution_code`** —— 回调不带分包参数。v3 回调体经商户 APIv3 密钥加密,处理前无从知商户,故 handler **遍历启用微信凭证逐一试解密**(GCM tag 天然筛出正确密钥),命中后**二次校验解密出的 `appid`/`mchid` == 本凭证**(跨商户注入防线)。单商户时 O(1)。旧带参路由 `/v1/webhook/wechat/:distribution_code` 暂保留兼容(内部同解析)。详见 `docs/architecture/design/iap-payment-channel-decoupling.md` §6.2/§6.3。

**Header**(微信注入,验签材料):`Wechatpay-Serial` / `Wechatpay-Signature` / `Wechatpay-Timestamp` / `Wechatpay-Nonce`

行为(`ProcessWechatPaymentHandler`,骨架 = verify §9.6 一次性支付镜像):
- 验签:serial 与凭证 `public_key_id` 精确匹配 + 时间戳 ±5min 窗 + RSA-SHA256(**raw body 逐字节**,handler 用 `ctx.Body()` 不重序列化)
- 解密:`resource.ciphertext` 经 APIv3 密钥 AES-256-GCM → 交易明文(`transaction_id`/`out_trade_no`/`trade_state`/`amount.total`)
- 落 `iap_store_notifications`(通知 id `EV-xxx` 经 uuidv5 规整)
- 仅处理 `TRANSACTION.SUCCESS`;按 `out_trade_no`(=我方 `order_no`)找单
- **金额红线**:`amount.total ≠ order.amount_cents` → 拒入账 + 订单 failed + 告警(应答 SUCCESS 止血)
- 同 tx:订单转 verified + `iap.purchase_completed` Outbox + 审计事件 → 同步发放(SourceRef 与异步 byte-identical,`uk_pocket_source_ref` 两路只发一次)→ completed

应答契约:成功 `200 {"code":"SUCCESS"}`;验签/格式错 4xx;基础设施错 5xx(微信重投,幂等吸收)。

幂等三层:订单 `IsCompleted` 短路 · `uk_order_store_txn(store_transaction_id, 'wechat')` · outbox `purchase:{order_no}` + Wallet SourceRef。

兜底:`NativePaymentReconcileWorker`(platform=wechat,仅 worker 进程)扫超期未发放微信单主动查单,**按 `order.credential_id` 取商户 client**(一分发挂 N 通道时 distribution.credential_id 只指向其一),与回调同一结算路径;迟到支付照常入账。

### POST /v1/webhook/alipay  (回调自描述,无分包参数)
支付宝**电脑网站支付**(`alipay.trade.page.pay`)异步通知(2026-07-23 真机验收 ¥1.00 通过)。公开端点,`/v1/webhook/` 跳过 App 签名;验签用支付宝公钥(RSA2)。

> **回调自描述**:同微信,路由**无 `:distribution_code`**。支付宝通知 form 明文携带 `app_id` → handler 按 `FindEnabledByPlatformAppID('alipay', app_id)` 反查结算商户凭证 → 验签(adapter 内 `app_id == 商户` 校验天然满足,跨商户防线)→ 按 `out_trade_no` 找单结算。旧带参路由暂保留兼容。

行为(`ProcessAlipayPaymentHandler`,复用共享 `nativePaymentSettler`,结算矩阵与微信同构):落审计 → 仅处理 `TRADE.SUCCESS` → 金额红线 → verified + outbox + 审计事件 → 同步发放 → completed。**验签基于 form-urlencoded 内嵌 `sign`**(无 HTTP header 依赖,`ctx.Body()` 逐字节)。

应答契约(与微信/Apple 均不同):**纯文本** `success`(支付宝止投)/ `failure`(触发重投,约 8 次/24h)。验签失败/格式错/查无此单(不可自愈)→ `success`(证据已落审计,防重投风暴);基础设施错(可自愈)→ `failure`。

兜底:`NativePaymentReconcileWorker`(platform=alipay)按 `order.credential_id` 主动查单(`alipay.trade.query`)。

## 鉴权端点(JWT)

### POST /v1/iap/orders
创建订单(用户主动购买流程入口)。

```json
{
  "distribution_code": "ios_global",
  "product_code": "premium_monthly"
}
```

返:
```json
{
  "order_no": "ORD-202604280001",
  "amount_cents": 998,
  "currency": "USD",
  "product_code": "premium_monthly",
  "expires_at": 1735689600,        // 订单创建后 30 分钟未支付自动失效
  "iap_product_id": "com.example.premium.monthly"
}
```

返回的 `iap_product_id` 用于客户端(iOS/Android)向 App Store 发起购买。

**支付无关商品分支**(商品 `store_platform = native`,P2 商品支付无关化):`native` 商品(如"1000积分")**任何**扫码/网页支付方式都能买。客户端下单时**必须带 `payment_method`**(取自 `app/init` 的 `payment_channels`,如 `alipay`/`wechat`)。服务端按 `(distribution, payment_method) → iap_payment_channels → credential_id` 解析结算商户,`order.store_platform` 记**实际所选方式**(非 native),随订单落 `order.credential_id`,完成下单,响应**额外**返回 `code_url`:
```json
{
  "code_url": "..."   // 按所选 payment_method 分支处理; 商店内购(apple/google)恒缺省
}
```
- **微信 Native**:`code_url = weixin://wxpay/bizpayurl?pr=...`(有效期 2h)→ 前端**转二维码**,用户扫码付款。
- **支付宝电脑网站支付**(`alipay.trade.page.pay`):`code_url = https://openapi.alipay.com/gateway.do?...`(**已签名的收银台跳转 URL**)→ 前端 `window.location` **跳转**到支付宝收银台(扫码/登录付款)。注意:支付宝返回的是**跳转 URL**(非二维码串),前端不要当二维码渲染。

> **`return_url`(可选,仅支付宝)**:下单时前端可传 `return_url` —— 付款成功后浏览器**同步回跳**的落地页(如 `/studio`,回跳后触发余额到账轮询)。纯 UX,**非资金路径**(到账权威走异步 `notify_url` + 查单;回跳与否不影响发放)。**由客户端传、不做 host 白名单**(任意 https 站均可回跳;dev 放行 `http://localhost`)。后端仅做格式/协议卫生(挡 `javascript:`/`data:`/畸形串),**不合规则静默丢弃**(当未传,不回跳,**不阻断下单**)。不传 = 不回跳。微信(二维码)/ Apple / Google 忽略该字段。

> **模型澄清**:`alipay`/`wechat` 是**支付方式**(通道维度,`iap_payment_channels.store_platform`),**不是商店**——商品不按其特化。一个 `native` 商品可经该分发**任一启用**的扫码/网页支付方式购买(加支付方式=加一行 payment_channel,零代码)。Apple/Google 才是"商店"(商品 ⟷ store SKU,`store_platform=apple/google`)。
> **错误**:`native` 商品缺 `payment_method` → `40012`;`payment_method` 非法或该分发未开通(无启用通道)→ `40013`。

下单失败 → 订单转 failed 并返错(不留悬挂 pending)。支付结果经 S2S 回调异步入账(微信见 `/v1/webhook/wechat`,支付宝见 `/v1/webhook/alipay`),客户端轮询订单状态或等积分余额变化。

错误:
- `40004` distribution_code 必填
- `40402` app 不存在 / disabled
- `40410` product 不存在
- `50304` 商品发放配置写错(`grant_config.storefront_tiers` 不合法,ADR-029)—— 拒单,不让用户为发不出正确额度的商品付款

### POST /v1/iap/orders/:order_no/verify
凭证验证(客户端完成 App Store 购买后回调)。

```json
{
  "transaction_id": "2000000123456789",
  "receipt_data": "..."             // 已废弃, 审计归档用
}
```

行为:
- 通过 `PlatformCredential`(P8 私钥)生成 Apple JWT
- 调 Apple API `GET /verifyReceipt` 或 StoreKit 2 `getTransactionInfo`
- 验证通过 → 落 `iap_orders` + `OrderEvent` + 触发 `iap.purchase_completed` Outbox → Wallet 授予积分
- 验证失败 → 标记订单 failed

返:
```json
{
  "order_status": "completed",
  "subscription": { ... }            // 若是订阅型商品
}
```

错误:
- `40410` 订单不存在
- `40411` 订单已完成 / 已退款(幂等)
- `40503` Apple API 不可达(可重试)
- `40012` 凭证验证失败
- `50304` 商品分档配置写错 —— 不发放、订单留 `verifying`,运维修正商品后客户端重试 verify 即恢复

**按 storefront 分档发放(ADR-029)**:商品 `grant_config` 可声明

```json
{"quota_amount": 1596,
 "storefront_tiers": {"T2": {"storefronts": ["BRA","MEX"], "quota_amount": 797},
                      "T3": {"storefronts": ["IND"], "quota_amount": 759, "trial_grant": {"quota_amount": 233}}}}
```

verify 按回执 `storefront`(Apple alpha-3 / Google alpha-2,归一到国家码比较)选档:命中档覆盖
`quota_amount`(档内写了 `trial_grant` 才覆盖试用档),未命中或 storefront 未知走顶层额度。
实际采用的档记入订单快照 `iap_orders.grant_config.storefront_tier_applied = {tier, storefront, quota_amount}`,
此后本订单的发放 / 退款撤销重发一律读它。续费单按**续费当期** storefront 重新选档(通知无 storefront 时用订阅行上一次的值)。
没有 `storefront_tiers` 的商品行为逐字不变。`/v1/app/init` 等目录读口的 `credits` 恒为顶层额度(无 storefront 上下文),
分档商品的对客额度文案应以商店本地化描述为准。

### POST /v1/iap/restore

恢复购买:客户端提交店铺凭证,服务端按凭证内交易全量对账补发(与 verify 同一幂等
判定链 grant_status;跨账号/已退款 → 40011)。Apple/Google 双端同入口。

## Module API(跨 BC 调用)

`iap.IAPAPI` interface:

```go
// Wallet BC 查活跃订阅
GetActiveSubscription(ctx, accountID int64) (*SubscriptionSummaryDTO, error)

// Identity BC GuestRegister 验签时查 distribution + AppSecret
ResolveDistributionSecret(ctx, distributionCode string) (*DistributionSecretDTO, error)

// Identity AppInit / Auth Header bundle 反查
FindDistributionByBundlePlatform(ctx, bundleID, platform string) (*DistributionInfoDTO, error)
```

Outbox 事件清单:
- `iap.purchase_completed` — 订单完成,Wallet 授信
- `iap.subscription_renewed` — 订阅续费
- `iap.refund_issued` — 退款,Wallet 反向操作

## 数据模型(主要)

| 表 | 主键 | 说明 |
|---|---|---|
| `iap_apps` | id | App 元数据 |
| `iap_app_distributions` | id, app_id | App 在不同分发渠道(iOS/Android/Mac App Store)的实例,持有 bundle_id + credential_id |
| `iap_platform_credentials` | id | P8 私钥 AES-GCM 加密 → `private_key_cipher bytea` |
| `iap_products` | id, distribution_id | 商品定义(consumable / non_consumable / subscription) |
| `iap_orders` | id, order_no | 订单生命周期(created → pending → completed / failed / refunded) |
| `iap_order_events` | id, order_id | 订单事件流(create / verify / refund / dispute) |
| `iap_subscriptions` | id, account_id | 订阅状态(active / expired / cancelled) |
| `iap_store_notifications` | id, transaction_id, notification_type | Apple S2S 全量原始记录(分区表 by created_at month) |

## 凭证管理

`iap_platform_credentials.private_key_cipher` 是 P8 文件 AES-GCM 加密(`security.credential_encryption_key` 配置)。

工具链:
- `cmd/aescrypt/` 生成 / 加解密密钥文件
- `cmd/credtool/` 把 P8 文件转为 PostgreSQL bytea hex 或 INSERT SQL

Apple JWT 由 `StoreClientFactory` 缓存(per credential_id),自动按 token TTL 刷新(默认 60 min)。

## 月度免费额度领取(听语 P-6,平台通用件)

### POST /v1/iap/free-quota/claim(JWT + AppSignature;零请求体)

任何在 `iap_apps.metadata.monthly_free.quota_amount` 配置了免费层的 app 均可用。
**惰性领取**:App 在启动 / 额度页显式调用;离线用户零发放浪费。

- 幂等:wallet `source_ref = freecycle:{app_id}:{account_id}:{YYYYMM}`(全局唯一约束收敛并发双领);
- 口袋:`pocket_type=system`(先于付费消耗)· `expires_at=下月首日 00:00 UTC`(PocketExpiry 既有过期收口,不滚存)· `grant_reason=monthly_free`;
- 响应 `{configured, granted, credits?, period?, expires_at?}`:未配置 app → `configured=false`(正常态非错误);重复领取 → `granted=false` + 本周期口袋信息;
- 台账三态查账失败(无法判定是否已领)→ **50302**(拒绝领取,绝不并入"未领" — 重复发放面)。

## 错误码段

- `404xx` Not Found(app / distribution / product / order)
- `403xx` 状态(app / distribution / order disabled)
- `405xx` 上游(Apple API 不可达)
- `400xx` Validation
- `429xx` Rate limit
- `50301` 商店上游不可达(ErrStoreUnavailable)· `50302` 钱包/台账依赖不可达(free-quota claim,听语 P-6)
  · `50304` 商品发放配置写错(ErrGrantConfigInvalid,ADR-029 分档表不合法)

详见 `internal/iap/domain/errors.go::GetErrorCode`(域 sentinel → HTTP code)。

## 起跳点

- Google Play S2S(`/v1/webhook/google` 留位,未实装)
- 退款决策自动化(当前 refund 触发反向扣减,余额不足走 negative balance + 限制策略)
- IAP 商品组合包(P5+)。~~promo code~~ 已从路线图移除:Apple 于 2026-03-26 停止创建
  IAP promo code(官方公告 developer.apple.com/news `gf6mgrs6`),替代机制 = 订阅/IAP
  offer code(offerType=3,归因已实装 `iap_orders.offer_kind='offer_code'`)
- promotional offer 签名端点(compactJWS,设计已定 `docs/audit/iap-offers-D.md` B3,待产品排期 OQ-3)

## OpenAPI 3.1 Specification

> 基于代码事实生成。来源:`internal/iap/port/http/{routes,app_init,order,webhook}_handler.go` + `app/dto/{app_init,order}.go` + `app/command/*_handler.go` + `domain/errors.go::GetErrorCode`。
>
> 公共契约见 [overview.md](overview.md)。`/v1/webhook/apple*` 在 SkipPaths,**跳过 App 签名**(走 Apple JWS 自身验签)。

```yaml
openapi: 3.1.0
info:
  title: AIGC Platform — IAP Domain API
  description: |
    IAP BC 5 endpoints:
      - app init (公开): 拉商品目录 + 版本检查 + 合规链接
      - Apple S2S webhook (公开 + 跳签名): JWS 通知, Apple 重试 22 次
      - 订单创建 + 校验 (JWT): 创建 → StoreKit/BillingClient → verify
  version: "1.0.0"

servers:
  - url: https://api.aigc.example.com/v1
  - url: http://localhost:9999/v1

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
        message: { type: string }
        data: {}
        request_id: { type: string, format: uuid }
        timestamp: { type: integer, format: int64 }

    AppInitRequest:
      type: object
      required: [distribution_code]
      properties:
        distribution_code: { type: string, description: 分发版本唯一码 }
        client_version: { type: string, description: 客户端版本号(用于版本检查, 可选) }

    UpdateInfo:
      type: object
      properties:
        latest_version: { type: string }
        force_update: { type: boolean }
        update_url: { type: string, format: uri }
        release_notes: { type: string }

    LegalInfo:
      type: object
      properties:
        privacy_url: { type: string, format: uri }
        terms_url: { type: string, format: uri }
        subscription_terms_url: { type: string, format: uri }

    ProductDTO:
      type: object
      required: [product_code, store_product_id, product_name, product_kind, price_cents, currency]
      properties:
        product_code:
          type: string
          description: 内部编码 (pro_monthly / token_500)
        store_product_id:
          type: string
          description: StoreKit / BillingClient 用 (com.aigc.creator.pro_monthly)
        store_platform:
          type: string
          enum: [apple, google, native]
          description: |
            商品支付归属。apple/google=**商店绑定**(商品⟷store SKU, 客户端走 StoreKit/BillingClient);
            native=**支付无关**计费项(任何扫码/网页支付方式都能买, 下单时带 payment_method 从
            payment_channels 里选)。alipay/wechat 是**支付方式**属通道维度, 不出现在商品上。
        product_name: { type: string }
        product_name_zh: { type: string }
        description: { type: string }
        icon_url: { type: string, format: uri }
        product_kind:
          type: string
          enum: [consumable, non_consumable, auto_renewable, non_renewable]
        price_cents: { type: integer }
        original_price_cents: { type: integer, nullable: true }
        currency: { type: string, example: USD }
        billing_cycle:
          type: string
          enum: [one_time, weekly, monthly, quarterly, semi_annual, annual, lifetime]
        trial_days: { type: integer }
        subscription_group: { type: string, description: 同组商品可走 Apple Subscription Group 升降级 }
        highlight_tag: { type: string, example: 推荐 }
        sort_order: { type: integer }
        is_active: { type: boolean }
        is_visible: { type: boolean }

    PaymentChannelDTO:
      type: object
      required: [store_platform, sort_order]
      properties:
        store_platform:
          type: string
          enum: [apple, google, wechat, alipay]
          description: 支付方式标识
        sort_order:
          type: integer
          description: 展示序 (升序), 服务端驱动
      description: |
        客户端可见的支付通道 (支付方式)。**只暴露 store_platform + sort_order** —— 商户凭证
        (credential_id) 等内部结算维度绝不下发。展示文案 (支付宝 / 微信支付 / Apple / Google Play)
        由客户端按 store_platform 本地映射 (后端=数据源, 展示归客户端)。

    AppInitResponse:
      type: object
      required: [server_time, products, payment_channels, legal]
      properties:
        server_time:
          type: integer
          format: int64
          description: 服务器权威时间 (Unix 毫秒 UTC), 客户端校时种子
        update:
          $ref: '#/components/schemas/UpdateInfo'
          nullable: true
          description: 仅当 client_version 传入且检测到新版时返
        products:
          type: array
          items: { $ref: '#/components/schemas/ProductDTO' }
        payment_channels:
          type: array
          items: { $ref: '#/components/schemas/PaymentChannelDTO' }
          description: |
            本分发**启用**的支付通道 (支付方式), 按 sort_order 升序 —— 客户端据此渲染可选支付方式
            (如 web 分发 [支付宝, 微信支付])。空列表 = 无扫码/网页支付通道 (纯 Apple/Google 商店内购,
            客户端走 StoreKit/BillingClient 用 products[].store_product_id)。
        legal: { $ref: '#/components/schemas/LegalInfo' }

    AppleWebhookRequest:
      type: object
      required: [signedPayload]
      properties:
        signedPayload:
          type: string
          description: |
            Apple S2S 通知的 JWS 紧凑格式 (3 部分 . 分隔).
            服务端 ParseNotification 内部验签;
            失败返 40000 (Apple 不重试).

    CreateOrderRequest:
      type: object
      required: [distribution_code, product_code]
      properties:
        distribution_code: { type: string }
        product_code: { type: string }
        payment_method:
          type: string
          enum: [wechat, alipay]
          description: |
            **支付无关商品 (store_platform=native) 必填** —— 客户端所选扫码/网页支付方式
            (取自 app/init 的 payment_channels)。Apple/Google 商店商品无需, 留空。
            缺失→40012;非法/该分发未开通→40013。
        return_url:
          type: string
          description: |
            可选, **仅支付宝 (payment_method=alipay) 生效**: 付款成功后浏览器同步回跳落地页
            (如 /studio 触发余额到账轮询)。纯 UX, 非资金路径 (到账走异步 notify_url + 查单)。
            客户端传、不做 host 白名单 (任意 https 站; dev 放行 http://localhost);
            后端仅格式/协议卫生 (挡 javascript:/data:/畸形), 不合规静默丢弃 (当未传, 不阻断下单)。
            微信/Apple/Google 忽略。

    CreateOrderResponse:
      type: object
      required: [order_no, product_code, store_product_id, amount_cents, currency, expires_at]
      properties:
        order_no:
          type: string
          description: 客户端本地存储, 断网重试用
        product_code: { type: string }
        store_product_id:
          type: string
          description: 客户端调 StoreKit / BillingClient API 用
        amount_cents: { type: integer }
        currency: { type: string }
        expires_at: { type: integer, format: int64, description: Unix 毫秒 }
        code_url:
          type: string
          description: |
            native 商品 (带 payment_method) 才返回; 商店内购 (apple/google) 恒缺省。
            前端按所选 payment_method 分支: 微信 = weixin://... 转二维码扫码; 支付宝 = 电脑网站
            支付 (alipay.trade.page.pay) 收银台跳转 URL (window.location 跳转, 非二维码串)。

    VerifyReceiptRequest:
      type: object
      required: [transaction_id]
      properties:
        transaction_id:
          type: string
          description: Apple transactionId / Google purchaseToken
        receipt_data:
          type: string
          description: |
            ★ 已废弃, 仅审计归档. Apple App Store Server API v2 使用 transaction_id
            而不是 receipt_data 验证. 客户端可不传.

    OrderGrantDTO:
      type: object
      required: [type]
      properties:
        type: { type: string, description: quota / feature / quota_and_feature 等 }
        credits: { type: integer }
        features:
          type: array
          items: { type: string }

    OrderSubscriptionDTO:
      type: object
      required: [original_transaction_id, expires_date, status]
      properties:
        original_transaction_id: { type: string }
        expires_date: { type: integer, format: int64, description: Unix 毫秒 }
        auto_renew: { type: boolean }
        status: { type: string, enum: [active, trialing, expired, canceled] }

    VerifyReceiptResponse:
      type: object
      required: [order_no, status, grant_status]
      properties:
        order_no: { type: string }
        status: { type: string, enum: [completed, failed] }
        grant_status: { type: string, enum: [granted, failed] }
        grant: { $ref: '#/components/schemas/OrderGrantDTO' }
        subscription:
          $ref: '#/components/schemas/OrderSubscriptionDTO'
          nullable: true

paths:
  /app/init:
    post:
      summary: 应用初始化 (拉商品 + 版本检查 + 合规链接)
      operationId: appInit
      tags: [App]
      description: 公开端点, 仅需 App 签名 (无 JWT)
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/AppInitRequest' }
      responses:
        '200':
          description: 初始化数据
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/AppInitResponse' }
        '404':
          description: 应用 (40402) / 分发 (40403) 不存在
        '403':
          description: 应用 (40304) / 分发 (40305) 已禁用

  /webhook/apple:
    post:
      summary: Apple S2S 通知 (默认路径, 从 BundleID 反查分发)
      operationId: appleWebhook
      tags: [Webhook]
      security: []
      description: |
        ★ **公开端点** (无 JWT, **跳过 App 签名** — /v1/webhook/ 在 SkipPaths).
        Apple 直调, 由 Apple JWS 验签保证真实性.
        Apple 重试策略: 4xx 不重试, 5xx 重试 22 次 (~100 天).
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/AppleWebhookRequest' }
      responses:
        '200':
          description: 通知已处理
          content:
            application/json:
              schema:
                type: object
                properties:
                  status: { type: string, example: ok }
        '400':
          description: 通知格式错误 / 签名无效 (40000) — Apple 不重试
        '500':
          description: 内部处理失败 (50000) — Apple 重试

  /webhook/apple/{distribution_code}:
    post:
      summary: Apple S2S 通知 (带分发 code 路径)
      operationId: appleWebhookWithDistribution
      tags: [Webhook]
      security: []
      description: |
        与上端点同 handler, 区别: 路径含 distribution_code 时直接用; 缺则从
        signedPayload 内 BundleID 反查.
      parameters:
        - name: distribution_code
          in: path
          required: true
          schema: { type: string }
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/AppleWebhookRequest' }
      responses:
        '200': { description: 处理成功 }
        '400': { description: 通知无效 }
        '500': { description: 内部错误 }

  /webhook/wechat:
    post:
      summary: 微信支付 v3 回调 (回调自描述, 无分包参数)
      operationId: wechatWebhook
      tags: [Webhook]
      security: []
      description: |
        ★ **公开端点** (无 JWT, 跳过 App 签名). 回调自描述 (支付通道解耦 P1): 无 distribution
        参数 — handler 遍历启用微信凭证试解密 (GCM tag 筛商户) + appid/mchid 二次校验.
        旧带参路由 /webhook/wechat/{distribution_code} 暂保留兼容.
      requestBody:
        required: true
        content:
          application/json: { schema: { type: object, description: 微信 v3 加密回调体 (resource.ciphertext) } }
      responses:
        '200':
          description: '成功: {"code":"SUCCESS"} (微信止投)'
        '400': { description: 验签/格式错 (微信重投, 幂等吸收) }
        '500': { description: 基础设施错 (微信重投) }

  /webhook/alipay:
    post:
      summary: 支付宝电脑网站支付异步通知 (回调自描述, 无分包参数)
      operationId: alipayWebhook
      tags: [Webhook]
      security: []
      description: |
        ★ **公开端点** (无 JWT, 跳过 App 签名). 回调自描述: form 明文 app_id 反查结算商户凭证 →
        验签 (app_id==商户 跨商户防线) → out_trade_no 找单结算. 旧带参路由暂保留兼容.
        **应答契约 = 纯文本** (非 JSON): success (止投) / failure (重投).
      requestBody:
        required: true
        content:
          application/x-www-form-urlencoded:
            schema: { type: object, description: 支付宝 form 通知 (含 app_id / out_trade_no / trade_status / sign) }
      responses:
        '200':
          description: 纯文本 "success" (已处理/不可自愈, 支付宝止投) 或 "failure" (基础设施错, 触发重投)
          content:
            text/plain: { schema: { type: string, example: success } }

  /iap/orders:
    post:
      summary: 创建订单 (返 store_product_id 供客户端 StoreKit 调用)
      operationId: createOrder
      tags: [Order]
      security:
        - BearerAuth: []
          DistributionCode: []
          Timestamp: []
          Nonce: []
          AppSignature: []
      description: |
        ★ 不需要 receipt 字段. 流程:
          1. 调本端点 → 拿 order_no + store_product_id
          2. 客户端调 StoreKit/BillingClient → 拿 transaction_id
          3. 调 /iap/orders/:order_no/verify 完成
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/CreateOrderRequest' }
      responses:
        '200':
          description: 订单创建成功
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/CreateOrderResponse' }
        '404':
          description: 应用 (40402) / 分发 (40403) / 商品 (40404) 不存在
        '403':
          description: 已禁用类错误 (40304 / 40305 / 40306)

  /iap/orders/{order_no}/verify:
    post:
      summary: 校验收据 + 发放权益
      operationId: verifyReceipt
      tags: [Order]
      security:
        - BearerAuth: []
          DistributionCode: []
          Timestamp: []
          Nonce: []
          AppSignature: []
      description: |
        ★ 仅需 transaction_id (Apple App Store Server API v2 不再要 receipt_data).
        幂等: 已 completed 直接返历史结果; transaction_id 冲突拒.
      parameters:
        - name: order_no
          in: path
          required: true
          schema: { type: string }
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/VerifyReceiptRequest' }
      responses:
        '200':
          description: 验证成功 + 权益已发放
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/VerifyReceiptResponse' }
        '404':
          description: 订单不存在 (40405)

# 错误码段 (来源 internal/iap/domain/errors.go::GetErrorCode)
#
# 40000 ErrNotificationInvalid    无效的通知数据
# 40010 ErrOrderNotPending         订单状态不允许此操作
# 40011 ErrOrderAlreadyExists      该交易已被其他订单使用
# 40012 ErrReceiptInvalid          收据无效
# 40013 ErrReceiptExpired          收据已过期
# 40014 ErrSubscriptionExpired     订阅已过期
# 40015 ErrSignatureInvalid        通知签名验证失败
# 40301 ErrAccountMismatch         无权操作此订单
# 40304 ErrAppDisabled             应用已禁用
# 40305 ErrDistributionDisabled    分发版本已禁用
# 40306 ErrProductInactive         商品已下架
# 40307 ErrCredentialDisabled      平台凭证已禁用
# 40402 ErrAppNotFound             应用不存在
# 40403 ErrDistributionNotFound    分发版本不存在
# 40404 ErrProductNotFound         商品不存在
# 40405 ErrOrderNotFound           订单不存在
# 40912 ErrConcurrentUpdate        操作冲突, 请重试
# 50301 ErrStoreUnavailable        商店服务不可用
# 50302 ErrStorePlatformError      商店平台错误
```
