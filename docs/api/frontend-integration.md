# 前端对接接口文档 · 对话创作工作台

> **读者**:对接对话创作界面(六部件)的前端工程师。本文覆盖**从鉴权到一次完整创作闭环**所需的全部 HTTP 端点、SSE 协议、数据契约与错误处理。
> **事实源纪律**:每个字段/端点均标注对应 Go 类型或路由文件;机器可读契约见 `api/openapi/openapi.yaml`(OpenAPI 3.1,装配面增量覆盖),TS 客户端生成命令见文末 §11。
> **配套**:通用机制 [overview.md](overview.md) · 错误码全表 [error-codes.md](error-codes.md) · 交互规格 `docs/云工作台企业级架构/对话创作界面交互规格.md`。
> **最后更新**:2026-07-06(ADR-012/013 装配 + 审计整改批一/批二)。

---

## 0. 一分钟速览:一次创作闭环

```
① 建会话          POST /v1/conversations                 → { bid }
② 订阅会话事件流   GET  /v1/conversations/:bid/events (SSE) ← run.status / task.slot / approval.requested
③ 预估成本(确认卡)POST /v1/tasks/estimate                → { credits, breakdown }   (成本前置铁律)
④ 提交创作(确认即提交) POST /v1/tasks                     → 202 { task_id, poll_url }
⑤ 查任务终态       GET  /v1/tasks/:bid  或  GET /v1/tasks/:bid/stream (SSE)
⑥ 选取候选         POST /v1/tasks/:bid/select              → 采用稿
钱包胶囊           GET  /v1/wallet                        ← balance / frozen
积分流水(账本面板) GET  /v1/wallet/ledger                  ← 每笔充值/预扣/结算/退款可回溯
```

**对话式(Agent/workflow)另一条链**:`POST /v1/conversations/:conv_bid/messages` → 返回 `{message, run}` → 订阅 `GET /v1/runs/:bid/events` 或会话统一事件流看 Run 推进。workflow(技能骨架)模式提交前可 `POST /v1/plan-previews` 拿计划卡。

---

## 1. 基础契约(所有端点通用)

### 1.1 BaseURL 与前缀

| 环境 | BaseURL |
|---|---|
| 生产 | `https://api.aigc.example.com/v1` |
| 开发 | `http://localhost:9999/v1` |

所有下文路径省略 `/v1` 前缀书写为 `/tasks` 等,实际请求为 `/v1/tasks`。

### 1.2 双重鉴权(两层 header 都必须带)

**① App 签名**(`AppSignatureMiddleware`,全局 `/v1/*` 生效;webhook/internal 除外):

| Header | 说明 |
|---|---|
| `X-Distribution-Code` | 分发版本编码(全局唯一) |
| `X-Timestamp` | Unix **秒级**时间戳 |
| `X-Nonce` | UUID,防重放 |
| `X-App-Signature` | `HMAC-SHA256(distribution.secret_key, timestamp + nonce + sorted(body))` |

签名算法与服务端 middleware **byte-for-byte 一致**,权威实现 `pkg/aigcsign/`;若走 BFF(如 Nebula web 的 `bff/`),签名由 BFF 注入,前端不接触密钥。

**② 用户 JWT**(`JWTAuthMiddleware`,认证路由组):

```
Authorization: Bearer <access_jwt>
```

Access JWT 短时(15min),中间件解出 `account_id / account_role / tenant_id / account_bid` 注入 ctx。**前端严禁在 body 里传 `app_id / tenant_id / distribution_code`**——服务端只认签名/JWT 推导值,body 里带了也会被忽略(防越权计费)。

> **公开端点**(仅 App 签名、无需 JWT):`POST /app/init`、`GET /app/config`。其余业务端点均需两层。

### 1.3 统一响应信封(Envelope)

所有 JSON 响应(无论 HTTP 200/202/4xx/5xx)体格式一致:

```json
{
  "code": 0,
  "message": "success",
  "data": { },
  "request_id": "0b9c…uuid",
  "timestamp": 1751808000
}
```

- **`code == 0` 才是成功**;非 0 是 5 位业务错误码(见 §10),此时 `data` 通常为 null,`message` 是人读文案。
- **HTTP 状态码与 code 分工**:提交类成功返 **HTTP 202**(`code:0, message:"accepted"`),查询类返 200。前端应以 `code` 判成败,HTTP 状态仅作传输层参考。
- `request_id`:排障关联键,报错时请带上给后端。

### 1.4 幂等

所有产生副作用/扣费的 POST 应带幂等键(见各端点)。**确认卡生成的 `idempotency_key` 一路带到任务与账本**——同键重复提交返回既有任务,不重复扣费。付费意图**必须**带幂等键(契约强制,见 §5)。

⚠️ **重放有边界(2026-09-15 收窄,见 `docs/adr/ADR-023`)**:
① **70 分钟窗口** —— 超窗按新任务受理并正常扣费;
② **已失败/超时/取消的任务不重放** —— 它们没有交付物且积分已退,重放只会把用户锁死在一次失败上。
⇒ 客户端**不能**把幂等键当"这组输入只会扣一次费"的长期凭证。

---

## 2. 六部件 → 端点/事件映射总表

对齐《对话创作界面交互规格》的六部件,每个部件的数据来源:

| 部件 | 主要数据源 | 关键事件/端点 |
|---|---|---|
| **① 复合输入器** Composer | `GET /wallet`(积分胶囊)· 意图对象(§5)驱动 chips | 提交 → `POST /tasks` 或 `POST /conversations/:id/messages` |
| **② 生成卡片** Card | `GET /tasks/:bid`(轮询)或 `GET /tasks/:bid/stream`(SSE) | `progress` / `candidate_ready` / `completed` / `failed` 事件 |
| **③ 焦点槽** Focus Slot | 前端本地状态 + 候选选取结果 | `POST /tasks/:bid/select` |
| **④ 资产面板** Panel | `GET /assets` · `GET /tasks/:bid/candidates` · 任务托盘 = 非终态任务列表 | `GET /tasks`(ListTasks) |
| **⑤ 覆盖层** Overlay | `GET /tasks/:bid/lineage`(版本树)· `GET /tasks/:bid/compare` | 产出新命令 → `POST /tasks` |
| **⑥ 意图确认卡** Confirm Card | 意图对象契约(§5)· `POST /tasks/estimate`(费用行) | 确认 = `POST /tasks`(command 段原样提交) |
| **计划卡**(工作台) | `POST /plan-previews`(§7) | 确认 = `POST /conversations/:id/messages`{workflow} |
| **会话动态**(横切) | **`GET /conversations/:bid/events`**(会话统一 SSE,§4.1) | `run.status` / `task.slot` / `approval.requested` / `system.notice` |

---

## 3. 会话与消息

### 3.1 创建会话

```
POST /v1/conversations
```

请求体(`internal/runtime/port/http/conversation_handler.go`):

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `workspace_bid` | string | 否 | 工作区 bid;个人场景可空 |
| `agent_bid` | string | ⚠️ 见下 | 绑定的 Agent(平台已发布);对话式创作填 |
| `title` | string | 否 | 会话标题 |
| `end_user_id` | int64 | 否 | 终端用户维度(agent_user_pair 记忆用) |

> ⚠️ **agent_bid 前置契约更正(2026-07-17 实证)**:创建会话时 `agent_bid` **可空**(裸会话合法),但**裸会话 `POST /conversations/:bid/messages` 发消息返 40935** `conversation must be bound to an agent`——发消息路径要求会话已绑 agent,且**无补绑端点**。原表述"否"仅指创建期,发消息期实为必绑。
>
> **工作台用法(B-2 裁决 = 平台通用对话 agent)**:创建会话时带**平台通用助手** `workbench-assistant`(tenant_id=0 共享,direct 单轮)的 `agent_bid`。该 agent 承载 chat/text_create 类**直接对话回复**;创作类意图(media_generate/video_generate/media_edit)**不经会话 agent**,走确认卡 → `POST /v1/tasks`。
> - agent_bid 下发:`SELECT bid FROM cat_agents WHERE tenant_id=0 AND code='workbench-assistant'`(seed `docs/migrations/20260717_seed_workbench_assistant_agent.sql`);dev 实例 = `019f6ec7-01a1-757c-9d97-85200cd1e849`(prod apply 后另取,勿硬编码跨环境)。

响应 `data`(`ConversationPublicDTO`,`internal/runtime/port/http/public_dto.go` — 内部 int64 FK 不透出,只暴露 bid):

```json
{
  "bid": "…", "workspace_bid": "…", "agent_bid": "…",
  "owner_account_bid": "…", "title": "", "status": "active",
  "total_messages": 0, "last_message_at": null,
  "created_at": "…", "updated_at": "…"
}
```

> 归属:会话 owner 必须 = 当前 JWT 账号(服务端按内部 account_id 校验,响应仅回显 `owner_account_bid`);会话事件流端点(§4.1)据此做归属校验。

### 3.2 会话历史消息

```
GET  /v1/conversations/:bid                → ConversationDTO
GET  /v1/conversations/:bid/messages        → { items: MessageDTO[], total }
```

`MessagePublicDTO`(`run_bid` = 消息关联的 Run,可用于订阅 `/v1/runs/:bid/events`):

```json
{
  "bid": "…", "conversation_bid": "…", "run_bid": "…",
  "role": "user | assistant | system | tool",
  "content": "…",
  "tool_calls": [ {…} ], "tool_call_id": "",
  "tokens_used": 0, "created_at": "…"
}
```

> 分页:`?limit=`(1–500,默认 50)+ `?offset=`(默认 0);响应 `total` 为会话内总条数。

### 3.3 发送消息(创建 Run)

```
POST /v1/conversations/:conv_bid/messages
```

请求体(`sendMsgReq`):

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `content` | string | 是 | 用户消息文本 |
| `execution_mode` | string | 否 | 覆盖 Agent 默认:`react` / `plan_execute` / `direct` / `workflow` |
| `estimated_credits` | int64 | 否 | 客户端自报冻结额估算(服务端钳制 `[max(cfg,100), 10000]`) |
| `idempotency_key` | string | 否 | 连点去重 |
| `variables` | object | 否 | **workflow 模式**的槽位实例化入参(技能骨架);服务端按 workflow DSL 声明校验,失败返 **40043**;非 workflow 模式携带即报错 |
| `runtime_options` | array | 否 | 单次 Run 运行时参数覆盖;受灰度门 `runtime.call_options_enabled`(默认关)控制,关时静默忽略 |
| `steer_expected_state` | string | 否 | **M-B 转向期望态**(会话 `run_policy=inject` 时生效):声明"我期望 run 当前处于该状态"(如 `acting`);拍间吸收时与实际状态比对,不符 ⇒ 消息**不注入**,其 `structured` 落 `{disposition:"rejected", steer_actual_state:"<实际态>"}`(拉消息列表可见,客户端据实际态重新决策)。空=无条件注入(存量行为) |

> `app_id` 不从 body 收 —— 由 App 签名 header 注入。

响应 `data`(`SendMessageResponse`):

```json
{ "message": { …MessageDTO(role=user) }, "run": { …RunPublicDTO } }
```

**拿到 `run.bid` 后**:订阅 `GET /v1/runs/:bid/events`(§4.2)或看会话统一流(§4.1)。

#### planned 计划契约链(M-C,2026-08-29)——"先看价再动手"

重交付场景(多步生成、长耗时编排)可先建计划、看报价、确认后再执行;**轻交互对话不受影响**(服务端内部自动走 `direct` 退化形态,对客零变化)。

```
POST /v1/plans                    {conversation_bid, steps:[{no,title,exec_kind,exec_ref?,est_credits,depends_on?}]}  → PlanCard(draft)
POST /v1/plans/:bid/quote                                                                                            → PlanCard(quoted, quote_bid/total_credits)
POST /v1/plans/:bid/confirm       {quote_bid}                                                                        → PlanCard(confirmed, envelope_open=true)
GET  /v1/plans/:bid                                                                                                  → PlanCard
```

`PlanCard`:`{plan_bid, state(draft|quoted|confirmed|running|paused|completed|cancelled|failed), mode(direct|planned), version, steps[], quote_bid?, quote_state?, total_credits, envelope_open}`

客户端纪律:
- **步骤号即拓扑序**:`depends_on` 只能指向**更小**且存在的步骤号(否则 `40044`,零写入);
- **确认前必先报价**:`confirm` 需带**当前**报价的 `quote_bid` —— 重报价会把旧报价置 `superseded`,拿旧的确认返 `40941`(重新 `quote` 即可);报价有默认 24h 有效期,过期同 `40941`;
- **确认 = 开信封**:成功即按报价总额冻结额度(`envelope_open=true`);确认过程任一步失败,冻结**必被退还**,不会留下"扣了钱没有计划"的中间态;
- **并发确认恰一生效**:多端同时确认同一计划,只有一个成功,其余返 `40940`(重拉计划卡后按最新状态处理);
- `40942` = 缺已接受报价或信封未开(成本前置铁律);`40434` = 计划不存在或非本人。

> **流式变体** `POST /v1/conversations/:conv_bid/messages/stream`:轻量 Direct 直出 LLM token,**不建 Run、不冻结、不落库**,受灰度门 `runtime.streaming.enabled`(默认关)控制;客户端须显式传 `model_version_bid`。生产开启前不可依赖。

### 3.4 Run 生命周期

```
GET  /v1/runs/:bid              → RunPublicDTO
POST /v1/runs/:bid/cancel        → 取消(退款按策略)
POST /v1/runs/:bid/resume        → 恢复(挂起态)
POST /v1/runs/:bid/approvals      → 人工审批/预算增补(§7.2)
GET  /v1/runs/:bid/events (SSE)   → Run 推进事件(§4.2)
```

`RunPublicDTO`(`internal/runtime/port/http/public_dto.go`):

```json
{
  "bid": "…", "conversation_bid": "…", "agent_bid": "…",
  "execution_mode": "workflow",
  "state": "created|planning|acting|observing|reflecting|awaiting_human_input|awaiting_creation|succeeded|failed|cancelled|timeout",
  "token_budget_max": 0, "timeout_seconds": 0,
  "prompt_tokens": 0, "completion_tokens": 0, "total_tokens": 0,
  "total_credits_charged": 0,
  "error_code": "", "error_message": "",
  "pending_human_prompt": "…",         // awaiting_human_input 时:审批/预算增补提示文案
  "citations": [ CitationDTO ],         // RAG 溯源(带脚注渲染用)
  "workflow_nodes": [ WorkflowNodeDTO ],// workflow 类 Run 的节点级进度
  "queued_at": "…", "started_at": "…", "completed_at": "…",
  "created_at": "…", "updated_at": "…"
}
```

`WorkflowNodeDTO`:`{ node_id, status(pending/running/succeeded/failed/skipped/awaiting_creation), reason, attempts, started_at, finished_at }`
`CitationDTO`:`{ index, document_bid, document_title, uri, snippet, score, first_page, last_page }`

> **归属校验**(2026-07-06 审计加固):`GET /runs/:bid` 与 `/events` 只能读本人的 Run(`end_user_id` 不匹配返 404);headless/系统 Run(无归属主体)不受限。

---

## 4. SSE 协议(三条流)

平台有**三条独立 SSE 流**,前端按场景选:

| 流 | 端点 | 粒度 | 续传 | 用途 |
|---|---|---|---|---|
| **会话统一流** ⭐ | `GET /conversations/:bid/events` | 会话 | ✅ Last-Event-ID=conv_seq | run 状态 / 任务槽位 / 审批请求 汇聚一条连接 |
| Run 事件流 | `GET /runs/:bid/events` | 单 Run | ❌(轮询实现) | 单次对话/workflow Run 推进 |
| 任务事件流 | `GET /tasks/:bid/stream` | 单任务 | ✅ Last-Event-ID | 单次生成任务进度/候选就绪 |

**SSE 通用**:`Content-Type: text/event-stream`;帧格式 `id: <n>\nevent: <name>\ndata: <json>\n\n`;心跳注释帧 `: ka\n\n` 每 15s;会话上限 5 分钟自动 `done`;`X-Accel-Buffering: no`(前端/nginx 勿缓冲)。

> **传输层修复(2026-07-06)**:此前三条流因 hertz 默认内存缓冲**非真流式且断连不感知**,已改 chunked hijack + `WithSenseClientDisconnection` + 心跳。前端应正常使用 EventSource / fetch-stream;客户端断开后服务端会及时释放连接。真机流式冒烟待后端 `.env` 就绪验证(不影响契约)。

### 4.1 会话统一事件流 ⭐(ADR-013,推荐主连接)

```
GET /v1/conversations/:bid/events
Header: Last-Event-ID: <conv_seq>   (可选,断线重连时带上次收到的 seq)
```

**语义**:单会话一条连接复用推送该会话全部动态。SSE `id` = `conv_seq`(会话内单调递增)。断线重连带 `Last-Event-ID` → 服务端从持久层补传缺口(**除 progress 类外零丢失**),再接热路径。缺省(首连不带)从头全量回放。

**payload 契约版本(R6, 2026-08-29)**:每条事件 payload 恒带 `schema_version`(当前 `1`)。客户端纪律:未知字段忽略(additive 增字段不升版);`schema_version` 大于自身支持版本 → 降级为通用展示,不按已知结构解析。

**事件封闭集**(`event` 字段):

| event | data 载荷 | 触发 |
|---|---|---|
| `run.status` | `{ run_bid, state, error_code?, credits_charged? }` | Run 终态(succeeded/failed/cancelled) |
| `task.slot` | `{ run_bid, task_bid, node_id, status, batch_index, batch_total, candidates:[{bid,asset_bid,url}] }` | workflow creation 任务候选就绪 |
| `approval.requested` | `{ run_bid, prompt, approval_node_id? }` | Run 转 awaiting_human_input(人工审批 / 预算增补 / E1 强确认工具审批);恢复走 `POST /runs/:bid/approvals`。`approval_node_id` E1 起对合成审批单显式下发(additive;缺省时按既有约定从 prompt 文案取) |
| `system.notice` | `{ … }` | 降级横幅/系统通知(载荷随场景) |
| `stream.gap` | `{ cursor, dropped_count, recovery_action }` | **M-B gap 契约**:`Last-Event-ID` 早于最早可补传事件(归档/保留清理)时服务端**必发**本帧,绝不静默从可用段续(假连续流=0)。`recovery_action:"resume_from_cursor"` → 客户端以 `cursor` 为新锚继续接流,并自行对缺失区间走快照重拉(如重新拉取会话消息列表);`dropped_count` = 不可补传的事件数。additive 新事件类型,不升 `schema_version`(未知 event 忽略纪律的正向应用) |
| `done` | `{ reason:"session timeout" }` | 5min 会话上限 |
| `error` | `{ message }` | 补传失败等 |

- **交付语义 = at-least-once**:同一 conv_seq 不重复(前端按 seq 去重),但极端重试下可能出现 payload 相同、seq 不同的重复投影行 → **前端按 payload 幂等应用**(如按 `run_bid+state` 收敛)。
- **连接配额**:每会话最多 **10** 条并发 SSE(超限返 `code 42921`);正常一个会话一条即可。
- **progress 不走此流**:高频进度看任务事件流(§4.3)。

**鉴权(B-1 修复 2026-07-17)**:EventSource 无法设 `Authorization` header。**SSE 端点(路径以 `/events` 结尾)现支持 `?access_token=` query 回退**:header 缺失时读 query token,仍过全部校验(签名/黑名单/BID/resolve,安全等价);query token 面**精确限制在 SSE 端点**(其余端点保持 header-only)。⚠️ 运维须确保 access log 不记 query string(脱敏),防短 TTL token 落盘。BFF 注入 header 的方案仍可用(二选一)。

**前端接法(EventSource)**:

```js
// access_token = 当前 JWT access token (短 TTL); 仅 /events 端点接受 query token
const es = new EventSource(`/v1/conversations/${bid}/events?access_token=${accessToken}`);
// Last-Event-ID 由浏览器在重连时自动带(基于上条 id:)。EventSource 重连会重发同一 URL,
// 故 access_token 刷新后需重建 EventSource(旧 token 过期时服务端返 40102, 前端重连)。
es.addEventListener('run.status', e => applyRunStatus(JSON.parse(e.data)));
es.addEventListener('task.slot',  e => appendCandidateSlot(JSON.parse(e.data)));
es.addEventListener('approval.requested', e => showApprovalCard(JSON.parse(e.data)));
```

### 4.2 Run 事件流(单 Run 推进)

```
GET /v1/runs/:bid/events
```

| event | data |
|---|---|
| `state_changed` | `{ state, bid }`(首帧)/ `{ state, pending_human_prompt }`(迁移时) |
| `step_completed` | `{ sequence, phase, state, observation }` |
| `workflow_progress` | `{ nodes: WorkflowNodeDTO[] }`(workflow 类 Run) |
| `done` | `{ state, total_tokens, total_charged, error_code, citations, workflow_nodes }` |
| `error` | `{ message }` |

> 实现为轮询(500ms/2s+wake),无 Last-Event-ID 续传;断线重连会重推一次全量当前态。适合"发一条消息看这一次 Run 跑完"。长期主连接建议用会话统一流(§4.1)。

### 4.3 任务事件流(单生成任务)

```
GET /v1/tasks/:bid/stream
Header: Last-Event-ID: <redis-stream-id>   (可选续传)
```

事件与各自 data 载荷:

| event | data | 说明 |
|---|---|---|
| `snapshot` | `TaskResponse` | 首帧任务当前完整快照(与 `GET /tasks/:bid` 同形,**非** TaskStreamEvent) |
| `progress` | `TaskStreamEvent` | 任务推进;`{ task_status, progress(0-100), … }` |
| `candidate_ready` | `TaskStreamEvent` | 单候选生成完成;`{ candidate_index, payload:{ asset_url,… } }` |
| `completed` | `TaskStreamEvent` | 终态成功 |
| `failed` | `TaskStreamEvent` | 终态失败;`payload:{ error_code }` |
| `done` | `{ reason }` | 会话结束:`already_terminal`(连上已终态任务)/ `terminal`(终态推完)/ `session_timeout`(10min 会话上限,应重连) |
| `error` | `{ message }` | 流内读取错误 |

`TaskStreamEvent` 结构:`{ event_type, task_status, candidate_index, progress, payload:{k:v}, occurred_at }`。收到 `done` 后连接关闭;仅 `reason=session_timeout` 需带 Last-Event-ID 重连续传。单任务并发连接超限返 code 42921。

---

## 5. 意图对象契约(确认卡数据源)

**定位**:意图对象是"用户话语 → 可执行命令"的**版本化契约**,也是**确认卡(部件⑥)的数据结构**。核心设计:**零翻译层** —— 意图对象的 `command` 段**就是** `SubmitTaskRequest`(§6.1)同一结构,用户在确认卡上就地修改直接写回 command,点确认即把 command 原样 `POST /tasks`,中间无二次语义转换。

Go 权威定义:`internal/creation/app/dto/intent.go`;机读 schema:`api/openapi/openapi.yaml` `#/components/schemas/IntentObject`。

```jsonc
{
  "intent_schema_version": 1,                 // 版本;不匹配→前端降级为通用确认卡
  "intent_type": "media_generate",            // 见下枚举
  "sub_type": "text2img",                      // 归属本 intent_type 的子类型(封闭集)
  "confidence": 0.95,                          // 分类置信度 [0,1]
  "target_assets": [                           // 目标资产解析(编辑类)
    { "asset_bid": "…", "source": "explicit_ref|focus|described", "confidence": 0.9 }
  ],
  "prompt": { "original": "画一只猫", "rewritten": "…", "final": "a cat, studio light" },
  "est_credits": 30,                           // 预估积分(由 /tasks/estimate 补算,分类器不填)
  "ambiguities": [ { "kind": "target_unclear|intent_unclear|param_missing", "candidates": ["…"] } ],
  "command": { …SubmitTaskRequest }            // 确认即提交段(见 §6.1);chat/command/ambiguous 为 null
}
```

**顶层 `intent_type` 枚举**(七类,封闭集):

| 值 | 含义 | 是否带 command | 确认策略(产品层) |
|---|---|---|---|
| `chat` | 问答闲聊 | 否 | 直接执行 |
| `text_create` | 文本创作 | 是 | 低成本直接执行 |
| `media_generate` | 从无到有生成图像 | 是 | 视成本/置信度 |
| `media_edit` | 已有资产修改 | 是 | 视成本/置信度 |
| `video_generate` | 视频生成 | 是 | 一律确认 |
| `command` | 元操作(切模型/查余额) | 否 | 直接执行 |
| `ambiguous` | 无法归类 | 否 | 反问选择题 |

**子类型 → task_type 映射**(按 intent_type 分组,归属校验强制):

| intent_type | sub_type | 提交为 |
|---|---|---|
| media_generate | `text2img` / `ref2img` / `batch` | image_gen |
| media_edit(生成式) | `instruct_edit` / `mask_inpaint` / `outpaint` / `variation` / `bg_remove` / `bg_replace` / `style_transfer` | image_edit |
| media_edit | `upscale` | image_upscale |
| media_edit(**确定性**) | `video_trim` / `video_speed` / `video_crop_frame` / `video_filter` / `bg_fill` | **pipeline**(command 必须走 `pipeline_code`,非 model) |
| video_generate | `text2video` / `img2video` / `extend` | video_gen |

**契约校验规则**(前端应对齐,后端 `Validate` 强制):
- `intent_schema_version` 必须 = 1,否则降级通用卡;
- `sub_type` 必须**属于**其 `intent_type` 分组(跨组如 `media_generate + text2video` 会被拒);
- `est_credits > 0` 时 `command.idempotency_key` **必填**(零静默扣费:确认动作→任务→账本三点一线);
- 确定性编辑子类型(→pipeline)的 command 必须带 `pipeline_code`;
- `chat/command/ambiguous` 不得带 command;`text_create/media_*/video_generate` 必须带 command。

> **分类器端点状态**:产出意图对象的**意图分类器**尚未作为平台 HTTP 端点上线(ADR-012 D1:分类将实现为 capability,卡片 UI 归前端仓)。当前前端从**结构化入口**(chips / 命令面板 / @引用)直接构造确认卡的 command 段即可——结构化入口本就跳过分类器直达命令(规格原则)。意图对象 schema 是自然语言解析上线后的对接契约,提前锁定字段。
> **v1 裁剪**:指代规格的 `target_ref` 描述子与 `ops[]` 操作链("裁到 1-6 秒并加黑白滤镜"单句多操作)不在 v1,留 schema v2。v1 的确定性编辑以单操作(sub_type + pipeline_code)表达。

---

## 6. 任务(生成/编辑/视频/管线)

### 6.1 提交任务(确认即提交)

```
POST /v1/tasks
```

请求体 `SubmitTaskRequest`(= 意图对象 command 段):

| 字段 | 类型 | 说明 |
|---|---|---|
| `model_version_bid` | string | 模型版本 bid(与 `pipeline_code` 互斥) |
| `params` | object | 模型参数(prompt/尺寸/数量/时长/档位/seed…按模型 param_schema) |
| `preset_code` | string | 参数预设码(可替代 params) |
| `idempotency_key` | string | 确认卡生成;付费**必填**;连点去重 + 账本回溯锚 |
| `pipeline_code` | string | 管线任务(确定性媒体编辑等);与 model 互斥 |
| `character_bids` | string[] | 引用的主体 bid(≤14),注入模型参考字段 |
| `derivation` | object | 派生声明 `{ derived_from_task_bid, type(rerun/param_adjust/model_switch/shot_regen), source_candidate_bid?, source_asset_bid? }` |
| `source_showcase_bid` | string | "制作同款"来源(运营归因弱标记) |

响应 **HTTP 202** `data`(`SubmitTaskResponse`):

```json
{
  "task_id": "…", "status": "processing",
  "poll_url": "/v1/tasks/…", "estimate_ms": 8000,
  "derivation": { "root_task_bid": "…", "depth": 1 }   // 派生任务才有
}
```

拿到 `task_id` 后:轮询 `GET /tasks/:bid`(按 `poll.next_poll_after_ms` 节奏)或订阅 `GET /tasks/:bid/stream`。

### 6.2 成本预估(费用行数据源)

```
POST /v1/tasks/estimate
```

请求:`{ model_version_bid, params, preset_code? }`(无副作用、不冻结)。
响应 `data`:

```json
{ "credits": 132, "unit_cost": 100, "unit": "per_second",
  "quantity": 8, "breakdown": "8s × 100 credits/s = 800 credits", "applied_tier": "member" }
```

**成本前置铁律**:任何会扣费的提交点,提交前必须先调 estimate 展示 `credits`;确认卡费用行、余额不足变体都消费此结果。

### 6.3 查询任务(生成卡片数据源)

```
GET /v1/tasks/:bid
```

响应 `data`(`TaskResponse`):

```jsonc
{
  "task_bid": "…", "status": "pending|processing|completed|failed|timeout|cancelled|partial",
  "model_code": "…", "task_type": "image_gen",
  "output_content": "…",        // 文本类
  "output_metadata": { },
  "error_code": "", "error_message": "",
  "created_at": 1751808000, "started_at": null, "completed_at": null,
  "billing": {                  // 计费明细
    "quota_consumed": 132, "quantity_requested": 4,
    "quantity_completed": 4, "quantity_failed": 0,
    "resources": [ { "asset_bid":"…","file_path":"…","content_type":"image/png","credit_cost":33 } ]
  },
  "candidates": [ CandidateResponse ],       // 见 §6.5
  "candidate_summary": { "total":4,"ready":4,"pending":0,"selected":0,"discarded":0,"expired":0 },
  "poll": { "next_poll_after_ms": 2000, "should_continue": true, "elapsed_ms": 3000, "estimate_total_ms": 8000 }
}
```

> **轮询停止**:`poll == null`(终态)即停止轮询。`poll.next_poll_after_ms` 是服务端建议的下次间隔。

### 6.4 任务列表 / 取消 / 谱系 / 对比

```
GET  /v1/tasks?page=&size=&task_type=&status=&created_from=&created_to=  → 任务托盘 + 历史
POST /v1/tasks/:bid/cancel                          → 取消(pending 全退 / processing 按策略)
GET  /v1/tasks/:bid/lineage                          → 谱系树(≤500 节点扁平表;覆盖层版本树)
GET  /v1/tasks/:bid/compare?with=<bid>               → A/B 对比
```

`task_type` 过滤闭集:`text_gen / image_gen / image_edit / image_upscale / video_gen / audio_gen / tts / stt / code_gen / embedding / translation / multimodal / pipeline`。

### 6.5 候选与选取(焦点槽 / 资产面板)

```
GET  /v1/tasks/:bid/candidates          → { task_bid, candidates: CandidateResponse[], total }
GET  /v1/tasks/:bid/selected             → { task_bid, selected: TaskOutput[], total }
POST /v1/tasks/:bid/select               → 选取为采用稿  body: { asset_bids:[…] }
GET  /v1/candidates/:bid                  → 单候选
POST /v1/candidates/:bid/save             → 固化为资产
POST /v1/candidates/:bid/discard          → 丢弃
POST /v1/candidates/batch_save            → 批量固化
POST /v1/candidates/batch_discard         → 批量丢弃
```

`CandidateResponse`:

```json
{
  "bid": "…", "task_bid": "…", "index": 0,
  "status": "…", "moderation_status": "…", "content_type": "image/png",
  "url": "…",           // 主文件可下载 URL(画廊渲染用;pending 可能空串)
  "primary_url": "…"    // 兼容字段,值同 url
}
```

> AIGC 域无缩略图概念:候选即模型完整产出(图/视频/音频),无 thumbnail 派生物。

### 6.6 资产与上传

```
GET  /v1/assets?…                → 资产库(缩略图墙数据)
GET  /v1/assets/:bid              → 单资产
POST /v1/assets/upload            → multipart 直传(经 BFF 落 gen_assets)
POST /v1/uploads/sign             → 预签名 PUT(前端直传 OSS,与 upload 互补)
POST /v1/assets/:bid/discard | /archive | /unarchive
```

---

## 7. 计划卡与审批(workflow / 技能骨架)

### 7.1 计划卡预览(提交前的成本前置)

```
POST /v1/plan-previews
```

**零副作用只读**:解析 agent 绑定的 workflow 骨架 → 步骤分项预估 + 预算信封 + 槽位声明。用于渲染计划卡,与最终提交**同一校验器同一估算器**(预览通过⇒提交必过)。

请求:`{ agent_bid, variables?: {…} }`(`agent_bid` 必填;`variables` = 计划槽位填充值)。
响应 `data`(`WorkflowPlanCardDTO`):

```json
{
  "agent_bid": "…", "workflow_version_ref": "…",
  "est_total": 50,          // 聚合预估总额(成本前置铁律的多步形态)
  "run_level_hold": 10,     // run 级实冻结额(非自冻结 LLM 节点之和)
  "envelope_cap": 55,       // 超支闸门上限(est_total × 1.1)
  "steps": [
    { "node_id":"gen_copy","kind":"llm","est_credits":10,"source":"personal","self_frozen":false },
    { "node_id":"gen_image","kind":"creation","est_credits":40,"self_frozen":true }
  ],
  "slots": [
    { "name":"count","type":"integer","required":false,"has_default":true,"default":3 },
    { "name":"topic","type":"string","required":true,"has_default":false }
  ]
}
```

**确认动作**(计划卡上点"按此计划执行"):`POST /v1/conversations/:conv_bid/messages` with `{ execution_mode:"workflow", variables:{…按 slots 填}, idempotency_key }`。`variables` 校验失败返 **40043**(前端把错误映射到对应槽位)。

### 7.2 人工审批 / 预算增补(执行中挂起)

当 Run 转 `awaiting_human_input`(会话流推 `approval.requested`,或 Run DTO 的 `pending_human_prompt`),前端出审批卡,恢复:

```
POST /v1/runs/:bid/approvals
```

请求 `{ approval_node_id, decision:"approved"|"rejected", comment? }`。

- 普通审批节点:`approval_node_id` 取自节点定义;
- **预算增补**:超支挂起时 `approval_node_id` = 固定保留值 **`__budget_topup__`**(prompt 文案含该 ID),`approved` = 抬额续跑,`rejected` = 终止退款。

---

## 8. 钱包(积分胶囊 / 费用来源)

```
GET /v1/wallet
```

响应 `data`:

```json
{
  "balance": 800,          // 可用积分(= 总额 - 冻结)
  "frozen": 132,           // 冻结中(提交任务后)
  "total_credited": 5000, "total_debited": 4068,
  "features": [
    { "feature_code":"…","feature_name":"…","source":"…","granted_at":"…","expires_at":"…"? }
  ]
}
```

> 钱包与任务用**同一** `(account, app)` 维度(app 由签名注入)——提交任务后 `GET /wallet` 能立刻看到 `frozen` 变化。新访客首次调用钱包行未建时返回全 0 值(非报错)。

### 8.1 积分流水 / 账本面板

```
GET /v1/wallet/ledger?cursor=&limit=
```

**已上线端点(2026-07-16 起在册),做账本面板直接接它,不要另建流水接口。** 倒序 keyset 分页:
`cursor` 原样回传上一页的 `next_cursor`(首页省略),`limit` 默认 20 / 服务端钳制上限 100;
`next_cursor` 缺省或 0 = 没有更多。新访客钱包未建返空页(非报错)。

响应 `data`:

```json
{
  "entries": [
    { "bid":"…", "ledger_type":"debit", "source":"creation_task", "amount":-80,
      "balance_after":49720, "frozen_after":0, "description":"…",
      "model_code":"seedance-2.0", "credit_cost":80, "group_bid":"…", "created_at":"…" }
  ],
  "next_cursor": 81
}
```

`amount` 正=充入 / 负=扣减(按符号上色)。同一次生成的**预扣 freeze → 结算 debit → 差额退 unfreeze**
三条流水共享同一 `group_bid`,并发多任务交错时按它聚合即得完整链路(充值/过期/调整无关联,`group_bid` 为空,
前端退化为不分组)。字段全集与语义见 [wallet.md](wallet.md#get-v1walletledgerp0-4-账本读面)。

> **不要用 `/auth/me` 或 `/v1/wallet` 刷流水**——那两个只给余额快照;
> 也不要用 `/v1/wallet/ledger` 拿当前余额,余额快照走 `/v1/wallet`。

---

## 9. 工具目录(function-calling / 能力发现)

统一工具注册表提供面向 LLM 规划的目录导出(`ListLLMToolCatalog`),含每工具的 `family / side_effect / cost_model / execution / input_schema`,**egress(出域)工具默认排除**。

> **当前状态**:该导出是 **facade 能力**(供服务端规划器/agent 消费),**尚无对外 HTTP 端点**——前端无需直接调用。工具的用户可见面走既有 marketplace:`GET /v1/marketplace/tools`(注:该端点在无租户上下文时只返回平台工具,2026-07-06 已修租户隔离)。此处列出供前端了解能力分级语义(确认矩阵:`side_effect ∈ {irreversible, egress}` 必须逐次强确认,不进免确认阈值)。

---

## 10. 错误码速查(前端分支依据)

`code` 是稳定枚举,前端按 `code` 分支;`message` 仅展示。全表见 [error-codes.md](error-codes.md)。装配链路高频码:

| code | 场景 | 前端处置 |
|---|---|---|
| `0` | 成功 | — |
| `40030` | 参数校验失败 | 表单标红 |
| `40043` | workflow variables 校验失败 | 计划卡对应槽位标红(§7.1) |
| `40111` | X-Timestamp 格式错 | 检查签名头(通常 BFF 负责) |
| `401xx` | 签名/JWT 缺失或失效 | 重新签名 / 刷新 token |
| `402xx` | 积分不足(creation) | 弹余额不足变体 → 降级模型 / 申请追加 |
| `40420` | agent/任务跨账号或不存在 | 按"不存在"处理(不泄漏) |
| `40430/40432` | 会话/Run 不存在或非本人 | 404 处理 |
| `40932` | Run 非 awaiting 态却提交审批 | 刷新 Run 状态 |
| `42921` | 会话 SSE 连接超配额(每会话 10) | 复用已有连接,勿并发多开 |
| `50230` | 钱包不可用(非余额不足) | 提示系统问题 + request_id 报障 |

**余额不足变体**(`402xx`)是确认卡的规格化交互:费用行变红,主按钮替换为"降级到某模型 / 申请追加"——前端据此码切换卡片形态。

---

## 11. 契约生成与工程建议

### 11.1 OpenAPI / TS 客户端

机器可读契约:`api/openapi/openapi.yaml`(OpenAPI 3.1)**已覆盖本文档全部前端对接端点**(会话/消息/Run/三条 SSE/意图对象/计划卡/任务/候选/对比/资产/上传/生命周期/钱包,34 路径 36 操作、含 SSE 事件载荷 schema)。生成类型安全 TS 客户端:

```bash
npx --yes openapi-typescript@7 api/openapi/openapi.yaml -o src/api/schema.ts
# 或后端仓验证: make openapi-ts   (锁 major @7 保证可重现)
```

生成物:`components["schemas"]["…"]`(全 DTO)+ `operations["…"]`(36 个,按 operationId)+ `paths`。零翻译层在类型层成立:`IntentObject.command?: components["schemas"]["SubmitTaskRequest"]`。

CI 守卫(`tests/contract/openapi_validate_test.go`)保证:① spec 可 libopenapi 加载;② 30 个核心 schema + 31 条前端必备路径全在;③ `IntentObject.command` $ref `SubmitTaskRequest`;④ `intent_type` 枚举与 Go 权威定义 `internal/creation/app/dto/intent.go` 不漂移;⑤ 任务状态枚举(`TaskStatus`)与 creation domain 状态机常量不漂移;⑥ 无「层级相同仅参数名不同」的重复模板路径(OpenAPI 3.x 禁止,redocly 等工具链硬报错)。**平台其余端点**(catalog/tenancy/provider/iap/knowledge/memory/prompt 等)见 `docs/api/*.md` + `endpoint-inventory.md`,按面增量迁入 spec。

### 11.2 状态管理(对齐技术架构 §10)

- **服务端状态归 TanStack Query**:会话/任务/资产/钱包用 query + 失效;资产改名、标采用稿等**即点即改用乐观更新**(失败回滚)。
- **编辑器高频局部状态归 Zustand**:画布、蒙版、参数面板、焦点槽,不进全局 store。
- **SSE 封装为 Hook**:内置重连 + `Last-Event-ID` 续传;会话统一流(§4.1)作主连接,token 增量渲染。
- **单向数据流**:SSE 事件 → 更新 query 缓存 → 组件订阅重渲染;用户动作 → 命令端点 → 乐观更新 + 服务端确认。

### 11.3 四条铁律(前端不得违反)

1. **只追加**:对话流消息/卡片只追加+原位更新,不删改历史(撤销靠版本树);
2. **非破坏性**:一切编辑产生新版本,无"覆盖原图";
3. **成本前置**:任何扣费提交点,提交前必展示 estimate(无预估不出提交按钮);
4. **不锁输入**:任务执行期输入器保持可用(非回合制)。

---

## 12. 已知边界(对接前须知)

- **意图分类器无 HTTP 端点**:自然语言→意图对象的分类器未上线;当前走结构化入口直构 command 段(§5)。
- **messages/stream 与 会话统一流真机验证**:SSE 传输层修复已合入,真机流式冒烟待后端 `.env` 就绪;`messages/stream` 与部分流仍受灰度门控制(默认关)。对接时请与后端确认目标环境的 `runtime.streaming.enabled` / `budget_envelope_enabled` 等开关值。
- **catalog 读面 bid-capability 模型**:agent/workflow 结构经 bid 可读(UUIDv7 不可枚举为唯一屏障),租户隔离方案待裁决——前端不要把 agent_bid/workflow bid 当敏感值明文散播。
- **计划卡确认走 messages**:`/plan-previews` 只预览,确认动作是带 `variables` 的 SendMessage,没有独立"提交计划"端点(技能骨架路线,ADR-012 D2)。

---

*本文档随装配推进增量更新;端点权威计数见 [endpoint-inventory.md](endpoint-inventory.md),通用机制见 [overview.md](overview.md)。*
