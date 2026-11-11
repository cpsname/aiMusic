# Wallet BC API 参考

> 设计:`internal/wallet/api.go`(主要是 Module API 跨 BC 调用,HTTP 端点最小)
> 模式:`Wallet → CreditPocket → CreditPricingRule + WalletLedger`

所有路径前缀 `/v1`。

## 鉴权端点(JWT)

### GET /v1/wallet
取当前账号 `(account_id, app_id)` 维度的积分余额 + 活跃权益。`app_id` 由 App 签名中间件注入,**不收请求体**。

返(权威结构 = `WalletHandler.GetWallet` 组装的 payload,机器契约见 `api/openapi/openapi.yaml#/components/schemas/WalletResponse`):
```json
{
  "balance": 49800,          // 可用积分 = 总额 - 冻结 (domain Wallet.Available())
  "frozen": 200,             // 冻结中(进行中的 task 预扣)
  "total_credited": 100000,  // 累计获得
  "total_debited": 50200,    // 累计消耗
  "features": [
    { "feature_code": "…", "feature_name": "…", "source": "iap_purchase", "granted_at": 1730000000, "expires_at": 1760000000 }
  ]
}
```

**读面三态契约(2026-08-17 钱包生命周期整改,三态严格互斥)**:

| 服务端状态 | 响应 | 客户端应做什么 |
|---|---|---|
| 钱包行存在 | `code=0` + 真实余额 | 正常展示 |
| **钱包行不存在**(账号尚无任何资金动作) | `code=0` + 全 0 + `features: []` | 正常展示为 0 积分,引导充值 |
| **查询故障**(DB 不可达 / 唯一索引失效致多行) | `code=50000` | 提示稍后重试,**不要**渲染成 0 积分 |

> 个人钱包是 `(account_id, app_id)` 维度的**懒创建**行 —— 全仓唯一创建入口是充值到账
> (`CreditHandler.CreditWallet` → `FindOrCreateByAccountAndApp`),注册 / 读面 / 冻结都不建。
> 所以"新账号余额 0"是正常领域事实,不是错误。
>
> 整改前仓储层把 not-found 与故障压成同一种 error,查询层一律吞成"无钱包",
> **钱包库故障时接口照样下发余额 0 且无任何日志** —— 用户看到"积分清零"而服务端毫无信号。
> 现故障显式失败并落 ERROR 日志(带 `account_id` / `app_id`)。守卫:
> `internal/wallet/app/query/wallet_summary_handler_test.go`、
> `internal/wallet/infra/persistence/wallet_lookup_classify_test.go`。

- 新访客钱包行尚未创建时返回**全 0 + 空 features**,`code` 仍为 0(不报错、无 `40410`)。
- **不返回** pocket 明细 / `wallet_id` / `account_id` / `app_id` / `*_cents` 字段——内部 int64 主键不出面(bid 红线),pocket 分桶是内部消费顺序实现细节。前端要看资金明细走下面的 `/v1/wallet/ledger`。
- 失败统一返 `50000`(Wallet BC 错误码未细分,KTD 项)。

**与 `GET /v1/auth/me` 的分工(避免重复接入)**:两个端点的积分字段同源——都走
`WalletSummaryHandler.GetWalletDetail` + `GetActiveFeatures`,`/auth/me` 经
`identityPort.WalletQueryPort` 桥接,`/v1/wallet` 直连 `WalletAPI`,**字段集完全一致,不存在两套口径**。分工:

| 端点 | 定位 | 何时调 |
|---|---|---|
| `GET /v1/auth/me` | 冷启动一次性聚合(账号 + 会话 + 订阅 + 钱包 + 权益,4 路并行扇出,各路失败降级为 `null`) | App 启动 / 登录后 / 重新拉用户上下文 |
| `GET /v1/wallet` | 单一职责轻查询(只打钱包表) | 积分胶囊刷新、提交任务后轮询 `frozen` 变化、充值回来对余额 |

> 不要为了刷余额调 `/auth/me`——它额外查会话计数与订阅,代价远高于本端点。
> 反之也不要用 `/v1/wallet` 拼用户上下文。

**app 维度红线(排"余额恒 0"客诉必看)**

账号是**全局**的(`id_accounts` 无 app 列),钱包却按 `(account_id, app_id)` 分掌。
读侧 `app_id` 由 App 签名中间件从 `distribution_code` 解析注入,**不可伪造也不可缺省**;
写侧来源则有多处:IAP 订单 `iap_orders.app_id` · outbox `evt.AppID` ·
runtime `scratchpad.__app_id` · 人工运维脚本(手填)。

任一写侧与读侧不一致,钱就进了一只该用户永远读不到的钱包 —— 表现为 `GET /v1/wallet`
恒返 0 而 DB 里明明有余额。排查时若只问"这账号有钱包吗"会得到"有啊余额好好的"的错误结论,
**必须连 `app_id` 一起比对**。

- 巡检与修复:`docs/ops/wallet-app-scope-audit.sql`(§1 只读巡检 / §2 迁移模板,默认 ROLLBACK)
- 手工开钱包:`docs/ops/wallet-init-and-set-balance.sql` 已内置 app 维度一致性闸
  (与 `id_account_registrations.app_id` 交叉校验,不一致直接中止)
- 服务端已消除的硬编码:Tool BC 付费工具冻结此前写死 `app_id=1`,现改由 Run 上下文解析,
  未解析则 fail-close 拒执行(`blocked: billing_unconfigured`)而非猜一只钱包

### GET /v1/wallet/ledger(P0-4 账本读面)
倒序 keyset 分页读当前账号钱包流水(账本面板数据源)。**成本前置铁律的事后可见性半边** — 每笔充值/预扣/结算/退款/过期/调整可回溯。

Query 参数:
- `cursor`(int64,可选):keyset 游标,取 `id < cursor` 的下一页;首页省略/传 0
- `limit`(int,可选):默认 20,上限 100

返(`LedgerPageDTO`):
```json
{
  "entries": [
    {
      "bid": "…",
      "ledger_type": "debit",          // credit充值/debit结算/freeze预扣/unfreeze退款/expire过期/revoke撤销/adjust调整
      "source": "creation_task",       // iap_purchase / creation_task / admin_grant / ...
      "amount": -80,                    // 正=充入, 负=扣减(前端按符号上色)
      "balance_after": 49720,           // 该笔后余额快照
      "frozen_after": 0,                // 该笔后冻结额快照
      "description": "…",
      "model_code": "seedance-2.0",
      "credit_cost": 80,
      "group_bid": "freeze-bid-…",      // ★ 冻结生命周期分组键(见下)
      "created_at": "…"
    }
  ],
  "next_cursor": 81                     // 0/缺省 = 没有更多
}
```

**`group_bid` 链路核对(checklist §7)**:一次生成的 **预扣(freeze)→ 结算(debit)→ 差额退(unfreeze)** 三条流水**共享同一 `group_bid`**(= 该次 freeze 流水的 bid)。前端在**并发多任务流水交错**时,按 `group_bid` 聚合即得完整链路,核对"预扣 100 → 结算 80 → 退 20"。充值/过期/调整(无冻结关联)`group_bid` 为空,各自独立。
> 全 bid 合规(不暴露内部 int64);反查 fail-open(极端故障 group_bid 空,前端退化为不分组,不误分)。

**双源说明**:当前 `GET /v1/wallet` + ledger 为**个人源**;项目池(workspace 级)双源卡为 P2,`source` 字段已预留区分维度。

### POST /v1/wallet/pool-approvals · GET /v1/wallet/pool-approvals  ★ 项目池 Phase A

项目池(wallet owner 泛化)审批面:提交池划拨审批 / 列出本人相关审批单。
池冻结不回落个人钱包(双 sentinel);详源:ADR-016 + 云工作台项目池批(efd6a96)。

## Module API(跨 BC 主战场)

Wallet 作为 freeze-confirm-refund 提供方,被以下 BC 大量使用:

| 调用方 | 场景 | 方法 |
|---|---|---|
| Creation | 生成任务计费 | Freeze → Confirm/Refund |
| Catalog (Workflow) | LLM 节点 / 工具调用计费(P4-01 SendMessage 入口) | Freeze + ConfirmFreeze 在 Run 终态 |
| Tool BC | 工具调用计费(P2-01 Phase C-4) | Freeze → Confirm/Refund |
| Knowledge BC | (未来)检索计费 | Freeze 留位 |

### Freeze 链路

```go
// 1. 任务开始: 冻结预估额度
freezeID, err := wallet.FreezeCredits(ctx, accountID, appID, taskID, amount, reason)
// → 写 wal_wallet_ledgers freeze 流水行 + frozen 递增 (文档勘正 2026-08-11)

// 2a. 任务成功: 全额结算
err := wallet.ConfirmFreeze(ctx, freezeID, taskID)
// → 写 ledger (debit + unfreeze 双条) + 扣 balance_cents + pocket 逐个回退

// 2b. 任务失败: 退回
err := wallet.RefundFreeze(ctx, freezeID, taskID)
// → 写 ledger (unfreeze 单条) + 加回 available_cents

// 2c. 部分结算 (如 LLM 实际用量 < 预估)
err := wallet.PartialConfirmFreeze(ctx, freezeID, taskID, confirmAmount)
// → 写 debit (confirmAmount) + unfreeze (frozen - confirmAmount) 双条 ledger
//   按 allocations 逐 pocket 精确扣减 (PartialConfirmFreeze 实装见 wallet_repository.go:389)
```

幂等键:`(freeze_id, task_id)` UNIQUE。`task_id` 可后置回填(`LinkFreezeToTask`)。

### 权益(Features)授予

Outbox 事件驱动 — IAP `iap.purchase_completed` / `iap.subscription_renewed` → `WalletEventConsumer` 消费 → `GrantFeatures` / `CreditWallet`。

`WalletEventConsumer` 幂等校验(`(event_id, account_id)`)防重复授予。

```go
// 授予积分
wallet.CreditWallet(ctx, &CreditWalletRequest{
    AccountID:   456,
    AppID:       1,
    AmountCents: 10000,
    Source:      "purchase",
    SourceRef:   "ORD-...",
    ExpiresAt:   &t,             // optional
})

// 授予 feature (如 vip / unlimited_chat)
wallet.GrantFeatures(ctx, &GrantFeaturesRequest{
    AccountID:    456,
    AppID:        1,
    FeatureCodes: []string{"vip"},
    ValidUntil:   &t,
})
```

退款反向操作:
- `RevokeCredits` — 反向扣减(可能负余额,业务需决策是否限流后续消费)
- `RevokeFeatures` — feature 立即失效

### 定价查询

```go
rule, err := wallet.FindPricingRule(ctx, modelCode, taskType, pricingTier)
// 返 PricingRuleDTO{ unit_credits, billing_unit, model_id, ... }
```

Creation BC 在 Provider 调用前查 pricing rule 决定 freeze 多少。

### 查询接口

```go
// 用户上下文聚合(Identity /me 用)
GetWalletSummary(ctx, accountID, appID) (*WalletSummaryDTO, error)
GetWalletDetail(ctx, accountID, appID) (*WalletDetailDTO, error)

// Feature 校验(业务前置 gate)
HasFeature(ctx, accountID, appID, featureCode) (bool, error)
GetActiveFeatures(ctx, accountID, appID) ([]*FeatureDTO, error)

// 订阅查询(IAP BC 调)
GetActiveSubscription → 见 IAP API
```

## 数据模型

| 表 | 主键 | 说明 |
|---|---|---|
| `wal_wallets` | id, (account_id, app_id) UNIQUE | 单账号单 app 一个 wallet |
| `wal_credit_pockets` | id, wallet_id | 积分桶(可过期);FIFO 消费 |
| `wal_credit_pricing_rules` | id, (model_code, task_type, pricing_tier) UNIQUE | 单价(分/单位)规则 |
| ~~`wal_freezes`~~(不存在 — 文档漂移 2026-08-11 勘正:冻结即 `wal_wallet_ledgers` freeze 流水行)| id, freeze_id, (account_id, task_id) | 任务级冻结;状态机 active → confirmed/refunded/expired |
| ~~`wal_freeze_allocations`~~(不存在 — 现行为 freeze 流水 `ref_id` 内嵌分配 JSON;W-2 立项后将建 `wal_credit_freeze_allocations` 明细表, 见 KTD 十二)| id, freeze_id, pocket_id | 冻结分配到具体 pocket |
| `wal_wallet_ledgers` | id, wallet_id, ref_type, ref_id | 全交易流水(credit / debit / unfreeze / refund) |
| `wal_features` | id, account_id, feature_code | 已授予 feature(可过期) |

`wal_wallet_ledgers.ref_task_id` 全交易场景(freeze / confirm / partial / refund)都填 — Creation/Catalog 任务计费可全链路追溯。

## 错误码段

- `404xx` wallet / freeze / rule 不存在
- `403xx` 余额不足 / freeze 已结算 / feature 已过期
- `40907` 并发冲突(乐观锁)

详见 `internal/wallet/domain/errors.go`。

## 已修复项(历史保留)

- ✅ `wal_wallet_ledgers.ref_task_id` 填充(`FreezeSpec.RefTaskID` + Confirm/Refund/PartialConfirm 全填 + freeze 继承)
- ✅ `PartialConfirmFreeze` 实装(`wallet_repository.go:389`,按 confirmAmount 精确扣 + 按 allocations 逐 pocket 回退,double ledger 写入 debit + unfreeze)

## 起跳点

- 三维配额(账号 / app / feature)+ 熔断(P5-04 brief)
- 账单导出(CSV / 月报)
- 跨 app 积分迁移

## OpenAPI 3.1 Specification

> 基于代码事实生成。来源:`internal/wallet/port/http/{routes,wallet_handler}.go` + `wallet/api.go::WalletAPI.{GetWalletDetail,GetActiveFeatures}`。Wallet BC 当前**仅 1 个 HTTP 端点**;跨 BC 的 freeze/confirm/refund 走 Module API,不暴露 HTTP。
>
> 公共契约见 [overview.md](overview.md)。

```yaml
openapi: 3.1.0
info:
  title: AIGC Platform — Wallet Domain API
  description: |
    Wallet BC 1 HTTP endpoint:
      - GET /v1/wallet 拉当前账号钱包详情 + 已激活的 features

    冻结 / 确认 / 退还 / 账本写入等核心操作走 Module API (Wallet API), 不暴露 HTTP.
  version: "1.0.0"

servers:
  - url: https://api.aigc.example.com/v1
  - url: http://localhost:9999/v1

security:
  - BearerAuth: []
    DistributionCode: []
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

    FeatureDTO:
      type: object
      required: [feature_code, source]
      properties:
        feature_code: { type: string, description: 特性 code (如 hd_output / no_watermark) }
        feature_name: { type: string }
        source:
          type: string
          description: |
            权益来源: iap_purchase (一次性购买) / iap_subscription (订阅) /
            admin_grant (后台发放) 等
        granted_at: { type: integer, format: int64, description: Unix 秒 }
        expires_at:
          type: integer
          format: int64
          nullable: true
          description: 永久权益时不返此字段

    WalletResponse:
      type: object
      required: [balance, frozen, total_credited, total_debited, features]
      properties:
        balance:
          type: integer
          format: int64
          description: 可用余额 (= balance - frozen)
        frozen:
          type: integer
          format: int64
          description: 冻结额度
        total_credited:
          type: integer
          format: int64
          description: 生命周期累计入账
        total_debited:
          type: integer
          format: int64
          description: 生命周期累计扣款
        features:
          type: array
          description: 当前生效的 features 列表 (可为空, 但不为 nil)
          items: { $ref: '#/components/schemas/FeatureDTO' }

paths:
  /wallet:
    get:
      summary: 当前账号钱包详情 + 已激活的 features
      operationId: getWallet
      tags: [Wallet]
      description: |
        合并两次调用:
          - WalletAPI.GetWalletDetail() → balance / frozen / total_*
          - WalletAPI.GetActiveFeatures() → features 数组

        新游客首次调用时 detail 为 nil, balance / frozen / total_* 都返 0 (非 500).
      responses:
        '200':
          description: 钱包详情
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/WalletResponse' }
        '401':
          description: 缺失认证

# 错误码段
# 注: Wallet BC 当前没有 GetErrorCode / mapDomainErr 函数,
# handler 把所有错误统一返 50000 "获取钱包信息失败" (wallet_handler.go:34).
# 详细错误细分留 P5.
#
# 50000 服务内部错误 (默认)
```
