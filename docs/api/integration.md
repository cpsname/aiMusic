# Integration BC — IM 渠道绑定 API(WK-12)

> 前缀 `int_`。租户自建群机器人 webhook 通知(飞书/钉钉/企微群 bot),Q1 自持凭证模型
> (租户在 IM 平台自建机器人,平台只存 webhook 地址,host 锁死零 SSRF)。
> 交付背景:WK-12 IM 渠道首批(HS-12 化解);台账 `int_channel_deliveries`(outbox 状态机投影,
> 去重 + 连续失败自动停用)。

## 路由总览(5 endpoints,JWT 鉴权组)

| Method | Path | 语义 |
|---|---|---|
| `POST` | `/v1/integrations/im-bindings` | 创建绑定(webhook URL host 白名单校验;凭证不回显)|
| `GET` | `/v1/integrations/im-bindings` | 列出本工作区绑定 |
| `DELETE` | `/v1/integrations/im-bindings/:bid` | 删除绑定(软删)|
| `POST` | `/v1/integrations/im-bindings/:bid/enable` | 启用 |
| `POST` | `/v1/integrations/im-bindings/:bid/disable` | 停用(连续投递失败达阈值时系统自动停用)|

## 通知语义

- 事件源:runtime run 终态(RunSucceeded / RunFailed — Failed 已补 EndUserID 防 tenant-0 串号)。
- 投递:outbox → `int_channel_deliveries` 台账(幂等去重);重试用 `shared/retry.Backoff`。
- 陷阱(实装记录):httpclient `MaxRetries` 零值会被默认成 3,发送端须 `WithNoRetry`
  (重试责任在台账层);`AgentVersionBID` 从未被 emit 填充,勿据其过滤。

## Module API

`IntegrationAPI.Ping`(骨架保留)。渠道管理为 HTTP 自助面,无跨 BC 方法。

## 起跳点

- 路由:`internal/integration/port/http/routes.go`
- 台账机制:`docs/schema/MECHANISM-REGISTRY.md` F13(重试投递台账家族)
- 开闸:apply wk12 迁移(见交付记忆)
