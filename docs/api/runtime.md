# Runtime BC API 参考

> Catalog Workflow CRUD 见 [catalog.md](catalog.md)
> 设计文档见 [../architecture/runtime/workflow-runtime.md](../architecture/runtime/workflow-runtime.md)

所有路径前缀 `/v1`。除明示外全 JWT 鉴权。

## Conversation

### POST /v1/conversations
创建会话。

```json
{
  "workspace_bid": "uuid",
  "agent_bid": "uuid",
  "title": "...",
  "end_user_id": 0,
  "run_policy": "queue"        // E5 可选: queue(默认) | inject | parallel; 非法值 40030
}
```

返 `ConversationDTO`(含 `run_policy`)。

**run_policy(E5, 2026-08-29)— 会话级 Run 并发策略**:同会话已有 active run 时,新 SendMessage 的行为——

| 值 | 行为 | 客户端观察 |
|---|---|---|
| `queue`(默认) | 消息落库排队(不建 run、零计费);active run 终态后按序自动出队建 run(完整闸链重走) | 发消息响应 `queued:true, run:null`;后续经 SSE `run.status` 观察出队 run |
| `inject` | 消息落库标记注入;active run 下一拍吸收为追加输入(模型即时可见) | 同上 `queued:true`;无新 run |
| `parallel` | E5 前历史行为:并发建 run(共享历史但互不知晓,显式选择才用) | 每条消息各返一个 run |

无 active run 时三种策略行为一致(直通建 run)。

**workspace_bid 可空(FT-PRE-0,B2C 链路)**:空 → 服务端懒创建/复用账号**个人空间**默认 workspace(tenancy `EnsurePersonalWorkspace`,幂等:org slug `u{accountID}` 全局 UNIQUE;首调原子创建 org+tenant 自绑+default workspace+owner membership,并发竞态经 UNIQUE 冲突恢复)。移动端个人用户跑平台 Agent(tenant_id=0 Agent 行全员可读)零前置步骤:会话建在用户自己的租户,引用平台 `agent_bid`。`u{数字}` 形态 slug 对用户侧 CreateOrganization 是保留形态(防抢注劫持)。

### GET /v1/conversations/:bid
取会话详情。

### GET /v1/conversations/:bid/messages
列消息。Query:`limit`(1-200,默认 20)/ `offset` / `before_message_id`。

## Run lifecycle

### POST /v1/conversations/:conv_bid/messages
发送用户消息,创建 Run。

```json
{
  "content": "...",
  "execution_mode": "react|plan_execute|direct|workflow",
  "estimated_credits": 100,
  "idempotency_key": "...",
  "runtime_options": [ /* 见下文「RuntimeOptions」 */ ],
  "variables": { "idea": "雨夜便利店的告白", "shots_count": 8 }
}
```

注: `app_id` 不从 body 接收, 由 `AppSignatureMiddleware` 从已签名 `X-Distribution-Code` header 解析后注入 ctx (防客户端越权计费)。

**variables(FT-PRE-1)**: workflow 模式的结构化业务入参(旗舰模板表单参数)→ `$workflow.variables` 初值。服务端按 workflow DSL 顶层 `variables` 声明做白名单/类型/required 校验, 与 DSL `default` 合并(用户值优先), 合并后总量 ≤512KB。校验失败返 **40043**(发生在 Wallet Freeze 之前, 零计费副作用)。非 workflow 模式携带该字段同样返 40043(拒绝静默丢弃)。无灰度门 — DSL 声明即闸。

返:
```json
{
  "user_message": { ... },
  "run": { "bid": "...", "execution_mode": "workflow", "state": "queued", ... }
}
```

**排队响应(E5)**:会话 `run_policy` 为 `queue`/`inject` 且已有 active run 时,不建 run、零计费,返:
```json
{
  "user_message": { ... },
  "run": null,
  "queued": true
}
```
`queue` 的消息在当前 run 终态后按序自动出队建 run(经 SSE `run.status` 观察);`inject` 的消息被 active run 下一拍吸收。详见上文「run_policy」表。

**delegate_to_agent(E4, 2026-08-29)— 聊天类执行器子代理**:Agent 定义 `tools[]` 列入平台内置工具 `delegate_to_agent`(input:`agent_bid`/`message`/`context_note`)后,ReAct/plan_execute/direct 执行器可把子任务委派给另一 Agent:

- 派发 = 合成节点 `delegate:<call_id>` 登记 + Run 挂起(`awaiting_creation` 家族复用),子 Run 经 WK-02 `StartSubRunHandler` 全链创建(深度 ≤2 / 环检测 / **子自持 freeze 即计费闸**,均在 Freeze 前零计费副作用拒绝);
- 子 Run 终态唤醒父 Run,恢复拍把结果注入观察面 —— 成功 = 子 `final_answer` 全文;失败 = **固定事实诊断**(`delegation failed: <category>`,不透内部错误链)+「勿盲重」提示。**子失败永不作为父 Run 的 error**(never-reject);
- 深度达上限的 Run 工具清单中自动隐藏此工具(能力先验);对客无新端点 —— 挂起/恢复经既有 SSE `run.status` 观察。工具经 worker 启动期 `SyncBuiltinCatalog`(config 门 `tool.catalog_sync_enabled`)登记后方可被 `tool_ref` 解析。

**workflow mode 行为**:
- `agent_bid` 对应 Agent 的 `definition.execution.mode='workflow'` + `workflow_version_ref`
- SendMessageHandler 调 `catalog.GetWorkflowVersionDefinition` 拉子定义
- 注入 `run.Scratchpad.Extra["workflow_def"]` + `["__tenant_id"]`
- `variables` 入参校验合并后作为初始 `WorkflowState.Variables` 写 `Extra["workflow"]`(FT-PRE-1; 含零入参时的 DSL default 初始化)
- Worker 拉起后 WorkflowExecutor 驱动 14 节点 DAG

#### RuntimeOptions(强化项 #3 CallOption 三层作用域)

可选数组字段, 单次 Run 临时覆盖 Agent 定义中的 LLM/Tool/Retriever 参数, 不修改 AgentVersion(避免 publish 新版本)。

**灰度 flag**: `runtime.call_options_enabled` 默认 `false` — 关闭时 body 中 `runtime_options` 字段被**静默忽略**(graceful degrade), 沿用 Agent 定义默认值。开启后才生效。配置见 `config/config.dev.yaml::runtime.call_options_enabled`。

**Wire format** — JSON 数组, 每项形如:

```json
{
  "override_type": "chat_model" | "tool" | "retriever",
  "override":      { /* 对应 Override 结构, 字段全可选 */ },
  "node_keys":     ["chat", "summary"],         // 可选, 限定生效节点 (OR-within)
  "component_types": ["ChatModel"],              // 可选, 限定 component 类型 (OR-within)
  "paths":         [["wf", "chat"]]             // 可选, 限定 workflow/subflow 嵌套路径
}
```

**优先级** (低 → 高, 后者覆盖前者): 无限定 < `component_types` < `node_keys` < `paths`。同 level 内按数组顺序后者覆盖前者; 跨 level 高 level 覆盖低 level。多个限定字段同时存在时 AND-across (e.g. ForNode + ForComponent 都需命中)。

**Override 类型 + 字段范围** (越界返 `40030`, 错误信息含字段名 + 越界值 + 期望区间, 如 `option[1] validate: ChatModelOverride.Temperature 5 超出 [0, 2] 范围`):

| override_type | 字段 | 类型 | 范围 |
|---|---|---|---|
| `chat_model` | `temperature` | float64 | `[0, 2]` (OpenAI/Gemini 通用上限) |
| `chat_model` | `max_tokens` | int | `> 0` |
| `chat_model` | `top_p` | float64 | `[0, 1]` |
| `chat_model` | `response_format` | string | `text` \| `json` \| `""` (空值视为未设) |
| `tool` | `timeout_ms` | int | `(0, 300000]` (5 分钟上限, 与 `sandbox_guard` 一致) |
| `tool` | `dry_run` | bool | (Tool BC 内消费者待 P+1) |
| `retriever` | `top_k` | int | `(0, 100]` |
| `retriever` | `score_threshold` | float64 | `[0, 1]` (cosine similarity 区间, 当前 Knowledge BC 字段未启用) |

**端到端透传链路**:
1. HTTP body → `MessageHandler.Send`
2. `encodeRuntimeOptionsWithGate(cfg, body)` 检查 `runtime.call_options_enabled` flag
3. `runtimeopt.UnmarshalOptions` 反序列化 + `Validate()` 字段范围校验 (失败返 `40030`)
4. 序列化为 string 写入 `run.Scratchpad.Extra["runtime_options"]` (jsonb)
5. Worker (`RunConsumer.runOneStep`) 反序列化 + `runtimeopt.WithOptions(ctx, opts)` 注入 ctx
6. `LLMInvoker.Invoke` 调 `runtimeopt.ResolveChatModel(opts, scope)` → `applyChatModelOverride(req)` 真实改写 `LLMInvokeRequest.Temperature/MaxTokens/ResponseFormat`
7. Tool BC: `bridge.runtimeToolPortBridge.Execute` 调 `applyToolOverrideToInput` 注入 `inv.Input["timeout_ms"]` (Tool BC `builtin_http_request` 已读此字段)
8. Knowledge BC: `bridge.runtimeKnowledgePortBridge.Retrieve` 调 `runtimeopt.ResolveRetriever` 覆盖 `req.TopK`

**示例**:

```json
{
  "content": "用一句话回答,温度 0.3 + tool 超时 5s",
  "runtime_options": [
    {
      "override_type": "chat_model",
      "override": { "temperature": 0.3, "max_tokens": 256 },
      "node_keys": ["chat"]
    },
    {
      "override_type": "tool",
      "override": { "timeout_ms": 5000 },
      "component_types": ["Tool"]
    },
    {
      "override_type": "retriever",
      "override": { "top_k": 5 }
    }
  ]
}
```

**向后兼容**: 老客户端不传 `runtime_options` 完全不受影响。flag 关闭时即使传也静默忽略 (不返错), 灰度切换期客户端无感知。

详细实施: [`internal/runtime/app/runtimeopt/`](../../internal/runtime/app/runtimeopt/) + [`internal/runtime/port/http/message_handler.go`](../../internal/runtime/port/http/message_handler.go)

### POST /v1/conversations/:conv_bid/messages/stream  ★ 强化项 #1 Phase E

SSE (Server-Sent Events) 流式 LLM 调用, 客户端实时接收 token 流。

**灰度 flag**: `runtime.streaming.enabled` 默认 `false` — 关闭时直接返 `50320`。配置见 `config/config.dev.yaml::runtime.streaming`:

```yaml
runtime:
  streaming:
    enabled: false              # 灰度开关
    keepalive_seconds: 15        # SSE 长连接保活注释行间隔 (与 nginx proxy_read_timeout 协调)
```

**请求 body**:

```json
{
  "content": "请用中文回答",
  "model_version_bid": "uuid-v7",        // 必填; 客户端显式指定模型版本
  "system_prompt": "You are helpful.",   // 可选, 作为 system role 消息前置
  "temperature": 0.3,                     // 可选; 0 表示 provider 默认
  "max_tokens": 1024                      // 可选; 0 表示 provider 默认
}
```

注: 当前流式路径**不**反查 Conversation→AgentBID (现有 P1-02 SendMessageHandler 的 agent_bid 解析依赖 stub 返空), 客户端显式提供 `model_version_bid` 走最短链路。完整 Run 持久化 + Wallet freeze/confirm 闭环留 P+1。

**SSE 响应**:

```
event: chunk
data: {"frame_type":"chunk","delta":"你"}

event: chunk
data: {"frame_type":"chunk","delta":"好"}

event: finish
data: {"frame_type":"finish","finish_reason":"STOP","prompt_tokens":12,"completion_tokens":8}

event: done
data: null
```

每 15 秒发一条注释行 `: ka\n\n` 保活 (防 nginx idle timeout)。客户端断连时后端 goroutine 检测 ctx.Done 退出, Reader.Close 触发 Provider.StreamLLM 内部 ctx 取消传递。

**错误**:
- `50320` 流式服务未启用 (flag=false)
- `40030` model_version_bid 必填
- `40330` conversation owner mismatch
- `40430` conversation 不存在
- 流中错误 → SSE `event: error\ndata: {"message": "..."}\n\n` + 关闭流

**仅支持 Provider**: 当前仅 Gemini (`google_ai`) adapter 实装 `ExecuteStream`; 其他 provider 返 `provider: model does not support streaming` 错误。

详细实施: [`internal/runtime/port/http/message_handler.go::SendStream`](../../internal/runtime/port/http/message_handler.go)

### GET /v1/runs/:bid
取 Run 详情。

### GET /v1/runs/:bid/attempts(R5-W7)
Attempt 审计读面:按 `sequence` 聚合该 Run 每一步的全部尝试。返 `{sequences:[{sequence, attempts:[{attempt, phase, state, served_model_version_bid, error_code, prompt_tokens, completion_tokens, duration_ms}]}]}`。`served_model_version_bid` = failover 后**实际服务**该次尝试的模型(可能非 Agent 定义的请求模型);空 = 该步无 LLM 调用或历史行。供应商侧深审计经该列与 provider 调用日志对齐。

### POST /v1/runs/:bid/cancel
取消 Run(任何活跃状态 → cancelled)。

### POST /v1/runs/:bid/pause(R5-W2)
用户级暂停:active 五态 → `paused`(持久化,崩溃不丢;拍间生效——在跑的一拍被中断且不落盘,resume 从上一 checkpoint 续)。已暂停重复调用幂等成功;awaiting_* 挂起中返 **40939**(已在等外部输入,不可再暂停);终态返 40930。**计费**:冻结保持在途、超时钟不停 —— 超过 run 期限由系统置 timeout 并按退款矩阵收口(见 `run-lifecycle.md` §2)。SSE `run.status` 推 `state:"paused"`。

### POST /v1/runs/:bid/resume
三分支复用同一端点:
1. **awaiting_human_input**(ReAct/PlanExecute)— 提交文本输入,`human_input` 必填;
2. **awaiting_creation** — 「唤醒丢失」手工恢复面(任务真在途则拒);
3. **paused(R5-W2)** — 恢复续跑,`human_input` 可选(作为续跑附言:落消息表 + 下一拍模型可见)。

```json
{ "human_input": "用户回答/续跑附言(分支 3 可省)" }
```

**Workflow 审批不走此** — 走 `/approvals` 端点(见下)。

### GET /v1/runs/:bid/events
SSE 流式事件(Run 状态 + RunStep 进度)。

### POST /v1/runs/:bid/approvals  ★ P4-01 / E1

提交人工审批决策。三类审批单共用本端点:

| 审批单来源 | `approval_node_id` 形态 | 挂起态 |
|---|---|---|
| Workflow `human_approval` 节点 | DSL 节点 id(如 `gate`) | `awaiting_human_input` |
| 预算增补(G-B) | `__budget_topup__` | 同上 |
| **强确认工具调用(E1, 2026-08-28)** | `__tool_approval__:<sequence>` | 同上 |

E1 工具审批:ReAct/PlanExecute 执行器调用 `side_effect=irreversible/egress` 工具时,
Tool BC 强确认矩阵拦下 → Run 转挂起并生成合成审批单(approvers 锁定 Run 归属者本人)。
`approved` → 恢复拍携票据重放该调用(结果进入模型观察);`rejected`/超时 →
拒绝作为固定语义观察注入,模型换路,Run 继续(不留死 Run)。
node id 随 `approval.requested` SSE 事件的 `approval_node_id` 字段下发(E1 起;
workflow/预算增补维持「node id 在 prompt 文案」的既有约定)。

```json
{
  "approval_node_id": "gate",      // DSL 节点 id / __budget_topup__ / __tool_approval__:<seq>
  "decision": "approved",           // approved | rejected
  "comment": "ok"
}
```

返:
```json
{
  "status": "approved",            // pending | approved | rejected | timeout
  "received_count": 1,
  "required_count": 1,
  "woke_up": true                   // Run 是否被唤醒重新入队
}
```

**行为**(`SubmitHumanApprovalHandler`):
1. `ApprovalStore.RecordDecision`(m-of-n + reject 短路)
2. status 离开 pending 且 Run 处 `awaiting_human_input`:
   - `RunStateMachine.Transition(awaiting → acting)`
   - 清 `PendingHumanPrompt`
   - `resetWorkflowPendingNodes`(让 Plan 重新选 ready)
   - tx 持久化 + Enqueue
3. status 仍 pending(2-of-2 只提交 1)→ 不唤醒,等下一个 approver

幂等:
- 同 `actor_account_id` 重复决议忽略
- IdempotencyKey:`<run_bid>:resume:approval:<node_id>`

错误:
- `40030` decision 必须 approved/rejected
- `40030` approval_node_id 必填
- `40430` Run 不存在
- `403xx` 权限不足

详细实现:[`internal/runtime/app/command/submit_human_approval_handler.go`](../../internal/runtime/app/command/submit_human_approval_handler.go)

### POST /v1/plan-previews  ★ ADR-012 计划卡

零副作用只读:话语/技能 → 技能骨架 + 槽位规格 + 预算信封(不冻结、不建 run)。
Agent 路径与技能路径同入口;变量缺口上卡不拒(提交路径才硬闸)。
请求/响应契约详源:`frontend-workbench-contracts-20260721.md` §plan-preview。

## Workflow Run 完整流程示例

```bash
# 1. 创建会话(假设 agent 已发布 workflow 模式)
curl -X POST /v1/conversations -d '{
  "workspace_bid": "ws-uuid",
  "agent_bid": "agent-with-workflow-uuid"
}'

# 2. 发消息触发 workflow Run
curl -X POST /v1/conversations/<conv_bid>/messages -d '{
  "content": "处理这个工单"
}'
# → 返 run.bid

# 3. SSE 监听 Run 进度
curl /v1/runs/<run_bid>/events

# 4. Run 进 awaiting_human_input 时 SSE 推送 pending_human_prompt
# → 前端展示审批 UI

# 5. 审批人提交决策
curl -X POST /v1/runs/<run_bid>/approvals -d '{
  "approval_node_id": "gate",
  "decision": "approved",
  "comment": "ok"
}'

# 6. Run 自动 resume,继续执行剩余节点
# 7. SSE 推送 finish + final_answer
```

## DTO 索引

| DTO | 字段 |
|---|---|
| `ConversationDTO` | bid / tenant_id / workspace_id / agent_id / owner_account_id / status / total_messages / created_at |
| `RunDTO` | bid / state / execution_mode / agent_id / agent_version_id / **workflow_version_id** ★ / scratchpad / pending_human_prompt / total_credits_charged / queued_at / started_at / completed_at |
| `RunStepDTO` | bid / sequence / phase / state / thought / action / observation / prompt_tokens / completion_tokens / cost_cents / duration_ms / error_code / error_message |
| `MessageDTO` | bid / role / content / created_at |
| `SubmitHumanApprovalResponse` | status / received_count / required_count / woke_up |

★ P4-01 Phase A 新增字段。

## 错误码段

Runtime BC 错误码与 Catalog/Tool 错误段隔离。Workflow 触发的错误参见 [Catalog 错误段](catalog.md#错误码段)(40050-40062 + 40430/40431)。

## OpenAPI 3.1 Specification

> 基于代码事实生成。来源:`internal/runtime/port/http/{routes,conversation_handler,message_handler,run_handler,errors}.go` + `runtime/api.go` + `domain/valueobject/run_state.go`。
>
> 公共契约见 [overview.md](overview.md)。所有错误返 HTTP 200 + 业务码(`mapDomainErr`)。

```yaml
openapi: 3.1.0
info:
  title: AIGC Platform — Runtime Domain API
  description: |
    Runtime BC 9 endpoints:
      - Conversation: create / get / list-messages
      - Message: send (创建 user message + Run, 返 run_bid 给前端订 SSE)
      - Run: get / cancel / resume (awaiting_human_input) / events (SSE) / approvals (P4-01 Workflow)

    Run 10 态状态机: created → planning → acting → observing → reflecting → awaiting_human_input
                  → succeeded / failed / cancelled / timeout (4 终态)
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

    CreateConversationRequest:
      type: object
      required: [workspace_bid]
      properties:
        workspace_bid: { type: string, format: uuid }
        agent_bid:
          type: string
          format: uuid
          description: 可空, 表示稍后绑定; SendMessage 时必须已绑定
        title: { type: string }
        end_user_id: { type: integer, format: int64 }
        persona_style_bid:
          type: string
          format: uuid
          description: >-
            可选。运行期选中的人设 B 段(个性)模板 BID —— "同一位咨询师换一种说话方式"。
            缺省 = 沿用 Agent 自身人设(行为与本字段上线前完全一致)。
            **只收不透明 ref, 永不收风格正文**:收正文等于开一条直通系统提示词的注入通道。
            会话级不可变 —— 建成后无任何端点能改它, 换风格 = 新开会话。
            取值由产品目录下发, 客户端不得硬编码。
            非 UUID → 40030;ref 不可用 → 40433;Agent 不接受风格 → 40938。

    ConversationDTO:
      type: object
      required: [bid, tenant_id, workspace_id, status]
      properties:
        bid: { type: string, format: uuid }
        tenant_id: { type: integer, format: int64 }
        workspace_id: { type: integer, format: int64 }
        agent_id: { type: integer, format: int64 }
        owner_account_id: { type: integer, format: int64 }
        end_user_id: { type: integer, format: int64 }
        persona_style_bid:
          type: string
          format: uuid
          readOnly: true
          description: >-
            本会话生效的人设 B 段模板 BID;未选风格时该键缺席(omitempty)。
            只读 —— 无任何端点能改它。回显它是必要的:客户端从历史列表重进会话时,
            只靠本地存会漂移(换设备 / 清缓存), 而"当前会话用的哪个风格"要显示给用户。
        title: { type: string }
        status: { type: string, enum: [active, ended, archived] }
        last_message_at: { type: string, format: date-time }
        total_messages: { type: integer }
        created_at: { type: string, format: date-time }
        updated_at: { type: string, format: date-time }

    MessageDTO:
      type: object
      required: [bid, role, content]
      properties:
        bid: { type: string, format: uuid }
        conversation_id: { type: integer, format: int64 }
        run_id: { type: integer, format: int64 }
        role: { type: string, enum: [user, assistant, tool, system] }
        content: { type: string }
        tool_calls:
          type: array
          items: { type: object, additionalProperties: true }
        tool_call_id: { type: string }
        tokens_used: { type: integer }
        created_at: { type: string, format: date-time }

    RunDTO:
      type: object
      required: [bid, conversation_id, agent_id, execution_mode, state]
      properties:
        bid: { type: string, format: uuid }
        tenant_id: { type: integer, format: int64 }
        conversation_id: { type: integer, format: int64 }
        agent_id: { type: integer, format: int64 }
        agent_version_id: { type: integer, format: int64 }
        execution_mode:
          type: string
          enum: [direct, react, plan_execute, workflow]
        state:
          type: string
          enum:
            - created
            - planning
            - acting
            - observing
            - reflecting
            - awaiting_human_input
            - succeeded
            - failed
            - cancelled
            - timeout
        token_budget_max: { type: integer }
        timeout_seconds: { type: integer }
        prompt_tokens: { type: integer, format: int64 }
        completion_tokens: { type: integer, format: int64 }
        total_tokens: { type: integer, format: int64 }
        total_credits_charged: { type: integer, format: int64 }
        freeze_id: { type: integer, format: int64 }
        error_code: { type: string }
        error_message: { type: string }
        pending_human_prompt: { type: string, description: "awaiting_human_input 时填" }
        queued_at: { type: string, format: date-time, nullable: true }
        started_at: { type: string, format: date-time, nullable: true }
        completed_at: { type: string, format: date-time, nullable: true }
        created_at: { type: string, format: date-time }
        updated_at: { type: string, format: date-time }

    SendMessageRequest:
      type: object
      required: [content]
      properties:
        content: { type: string, description: 用户消息内容 (非空) }
        execution_mode:
          type: string
          enum: [direct, react, plan_execute, workflow]
          description: |
            优先级: 请求体 > agent.execution.mode > react (默认).
            workflow 模式必须 agent.definition.execution.workflow_version_ref 合法.
        estimated_credits:
          type: integer
          format: int64
          default: 100
          description: |
            Wallet 冻结额度。服务端**双向钳制**到 [runtime.default_freeze_credits, 10000] —
            低于下限按下限冻结 (2026-08-02 起; 此前只有上限, 自报 1 即 1 积分跑满整个 run),
            高于上限按上限。workflow 模式且预算信封开启时, 服务端 DAG 推导值覆盖本字段。
        idempotency_key: { type: string, description: 客户端 UUID 防重复提交 }
        runtime_options:
          type: array
          description: |
            强化项 #3 — 单次 Run 临时覆盖 LLM/Tool/Retriever 参数.
            灰度 flag runtime.call_options_enabled 默认 false (关闭时静默忽略).
            字段越界返 40030 (含 option[i] 索引 + 字段名 + 范围).
          items: { $ref: '#/components/schemas/RuntimeOption' }
      additionalProperties: false
      x-notes: |
        app_id 不接受 body 字段 — 由 AppSignatureMiddleware 从已签名
        X-Distribution-Code header 解析后注入 ctx (防客户端伪造越权计费).

    RuntimeOption:
      type: object
      required: [override_type, override]
      description: |
        三层作用域: 优先级 paths > node_keys > component_types > 无限定.
        OR-within (同字段内 OR), AND-across (跨字段 AND).
      properties:
        override_type:
          type: string
          enum: [chat_model, tool, retriever]
          description: 决定 override 字段的 schema (chat_model / tool / retriever).
        override:
          oneOf:
            - $ref: '#/components/schemas/ChatModelOverride'
            - $ref: '#/components/schemas/ToolOverride'
            - $ref: '#/components/schemas/RetrieverOverride'
        node_keys:
          type: array
          items: { type: string }
          description: 限定生效节点 (workflow node ID / 'chat'/'tools' 标签). OR-within.
        component_types:
          type: array
          items: { type: string, enum: [ChatModel, Tool, Retriever] }
          description: 限定生效 component 类型. OR-within.
        paths:
          type: array
          items:
            type: array
            items: { type: string }
          description: 限定 workflow/subflow 嵌套路径. 路径 == 段数组深值比较.

    ChatModelOverride:
      type: object
      additionalProperties: false
      properties:
        temperature: { type: number, minimum: 0, maximum: 2, description: 0..2 OpenAI/Gemini 通用上限 }
        max_tokens:  { type: integer, minimum: 1 }
        top_p:       { type: number, minimum: 0, maximum: 1 }
        response_format:
          type: string
          enum: [text, json, ""]
          description: 仅支持 text/json/空字符串 (空 = 未设)

    ToolOverride:
      type: object
      additionalProperties: false
      properties:
        timeout_ms: { type: integer, minimum: 1, maximum: 300000, description: 1..300000ms (5 分钟上限, 与 sandbox_guard 一致) }
        dry_run:    { type: boolean, description: Tool BC 内消费者待 P+1 }

    RetrieverOverride:
      type: object
      additionalProperties: false
      properties:
        top_k:           { type: integer, minimum: 1, maximum: 100 }
        score_threshold: { type: number, minimum: 0, maximum: 1, description: cosine similarity 区间; KnowledgeRetrieveRequest 待 P+1 接入 }

    SendMessageResponse:
      type: object
      required: [message, run]
      properties:
        message: { $ref: '#/components/schemas/MessageDTO' }
        run:
          $ref: '#/components/schemas/RunDTO'
          description: 新建 Run (state=queued), 用 run.bid 订 SSE 流式

    ResumeRunRequest:
      type: object
      required: [human_input]
      properties:
        human_input: { type: string, description: 人工补充内容 (非空) }

    SubmitHumanApprovalRequest:
      type: object
      required: [approval_node_id, decision]
      properties:
        approval_node_id: { type: string, description: workflow human_approval 节点 id }
        decision: { type: string, enum: [approved, rejected] }
        comment: { type: string }

    SubmitHumanApprovalResponse:
      type: object
      required: [status, received_count, required_count, woke_up]
      properties:
        status: { type: string, enum: [pending, approved, rejected, timeout] }
        received_count: { type: integer, description: 已收到决策数 }
        required_count: { type: integer, description: 需要决策数 (m-of-n 场景) }
        woke_up:
          type: boolean
          description: 是否唤醒了 Run (status 终态 + run.state=awaiting_human_input 才唤醒)

paths:
  /conversations:
    post:
      summary: 创建会话
      operationId: createConversation
      tags: [Conversation]
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/CreateConversationRequest' }
      responses:
        '200':
          description: 创建成功
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/ConversationDTO' }
        '404':
          description: workspace (40421) / agent (40420) 不存在

  /conversations/{bid}:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
    get:
      summary: 取会话详情
      operationId: getConversation
      tags: [Conversation]
      responses:
        '200':
          description: 会话详情
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/ConversationDTO' }
        '404':
          description: 会话不存在 (40430)

  /conversations/{bid}/messages:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
    get:
      summary: 列消息 (分页)
      operationId: listMessages
      tags: [Conversation]
      parameters:
        - { name: limit, in: query, schema: { type: integer, default: 50, minimum: 1, maximum: 500 } }
        - { name: offset, in: query, schema: { type: integer, default: 0 } }
      responses:
        '200':
          description: 消息列表
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data:
                        type: object
                        properties:
                          items:
                            type: array
                            items: { $ref: '#/components/schemas/MessageDTO' }
                          total: { type: integer }

  /conversations/{conv_bid}/messages:
    post:
      summary: 发送消息 (创建 user message + 新 Run)
      operationId: sendMessage
      tags: [Conversation]
      description: |
        必须 conversation 已绑定 agent (否则 40935 ErrConversationAgentRequired).
        返 run.bid 给前端订 SSE (GET /v1/runs/:bid/events).
        Wallet 冻结 estimated_credits, 完成时确认 / 失败时退还.
      parameters:
        - { name: conv_bid, in: path, required: true, schema: { type: string, format: uuid } }
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/SendMessageRequest' }
      responses:
        '200':
          description: 消息已发送 + Run 已入队
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/SendMessageResponse' }
        '400':
          description: content 空 (40040) / mode 非法 (40041)
        '409':
          description: agent 未绑定 (40935) / 会话已结束 (40934)
        '500':
          description: Wallet 冻结失败 (50040)

  /conversations/{conv_bid}/messages/stream:
    post:
      summary: SSE 流式 LLM 调用 (强化项 #1 Phase E)
      operationId: sendMessageStream
      tags: [Conversation, Streaming]
      description: |
        SSE 端点; 流末帧 event=finish 含 token usage. 客户端断开 (ctx done) 后端
        goroutine 应及时退出 (Reader.Close 触发 Provider.StreamLLM 内部 ctx 取消).

        灰度 flag: runtime.streaming.enabled 默认 false → 50320.
        当前仅 Gemini provider 实装 ExecuteStream; 其他返 ErrStreamNotSupported.

        当前流式路径不创建 Run/Message 行, 不 Wallet.Freeze (P+1 完整集成);
        客户端显式提供 model_version_bid 走最短链路, 不反查 Conversation→AgentBID.
      parameters:
        - { name: conv_bid, in: path, required: true, schema: { type: string, format: uuid } }
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [content, model_version_bid]
              properties:
                content: { type: string }
                model_version_bid: { type: string, format: uuid }
                system_prompt: { type: string }
                temperature: { type: number, minimum: 0, maximum: 2 }
                max_tokens: { type: integer, minimum: 0 }
      responses:
        '200':
          description: |
            SSE event-stream. 帧类型:
              event: chunk    data: {"frame_type":"chunk","delta":"..."}
              event: finish   data: {"frame_type":"finish","finish_reason":"STOP","prompt_tokens":N,"completion_tokens":M}
              event: error    data: {"message":"..."}
              event: done     data: null
          content:
            text/event-stream: { schema: { type: string } }
        '400':
          description: content 空 / model_version_bid 必填 (40030)
        '403':
          description: conversation owner mismatch (40330)
        '404':
          description: conversation 不存在 (40430)
        '503':
          description: 流式服务未启用 (50320)

  /runs/{bid}:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
    get:
      summary: 取 Run 详情 (轮询用; 推荐用 SSE)
      operationId: getRun
      tags: [Run]
      responses:
        '200':
          description: Run 详情
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/RunDTO' }
        '404':
          description: Run 不存在 (40432)

  /runs/{bid}/cancel:
    post:
      summary: 取消 Run (退还 Wallet 冻结)
      operationId: cancelRun
      tags: [Run]
      description: |
        已终态 Run 幂等返 (无错). 活跃状态 → cancelled.
        Wallet 退还由事务外调度 (RefundFreeze + 更新 reconciliation).
      parameters:
        - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
      responses:
        '200':
          description: "取消成功 (data: null)"
          content:
            application/json:
              schema: { $ref: '#/components/schemas/StandardResponse' }
        '404':
          description: Run 不存在 (40432)

  /runs/{bid}/resume:
    post:
      summary: 提交人工补充 (awaiting_human_input → acting)
      operationId: resumeRun
      tags: [Run]
      description: |
        Run 必须 awaiting_human_input 状态 (否则 40932 ErrRunNotAwaitingHuman).
        插入一条 user role 消息记录 human_input + 重新入 Redis Stream.
      parameters:
        - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/ResumeRunRequest' }
      responses:
        '200':
          description: "继续执行 (data: null)"
          content:
            application/json:
              schema: { $ref: '#/components/schemas/StandardResponse' }
        '400':
          description: human_input 空 (40040)
        '409':
          description: Run 不在 awaiting_human_input (40932)

  /runs/{bid}/events:
    get:
      summary: SSE 流式订阅 Run 事件
      operationId: streamRunEvents
      tags: [Run]
      description: |
        Content-Type: text/event-stream
        500ms 轮询 + 5 分钟连接上限.
        终态 (succeeded / failed / cancelled / timeout) 自动推 done 事件后断开.

        事件类型 (event 字段):
          - state_changed: { state, bid, pending_human_prompt }
          - step_completed: { sequence, phase (plan/act/observe/reflect/tool_call/final), state, observation, cost_cents }
          - done: { state, total_tokens, total_charged, error_code, reason }
          - error: { message }
      parameters:
        - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
      responses:
        '200':
          description: SSE 流(text/event-stream)
          content:
            text/event-stream:
              schema:
                type: string
                description: |
                  data: {"state":"acting","bid":"...","pending_human_prompt":""}

  /runs/{bid}/approvals:
    post:
      summary: 提交 workflow human_approval 节点决策(P4-01)
      operationId: submitHumanApproval
      tags: [Run]
      description: |
        Phase F.3.A MVP 实现:
          1. 校验 decision ∈ {approved, rejected}
          2. ApprovalStore.RecordDecision 累加 received_count
          3. 若达 required_count + run.state=awaiting_human_input → 唤醒
             (重置 workflow scratchpad pending 节点 + 重新入 Stream)
      parameters:
        - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/SubmitHumanApprovalRequest' }
      responses:
        '200':
          description: 决策已记录
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/SubmitHumanApprovalResponse' }
        '404':
          description: Run 不存在 (40432)

# 错误码段 (来源 internal/runtime/port/http/errors.go::mapDomainErr L20-76)
#
# 40040 ErrMessageEmpty                     消息内容不能为空
# 40041 ErrInvalidExecutionMode             执行模式无效
# 40042 ErrInvalidRunStep                   step 状态转移非法
# 40301 ErrPermissionDenied                 权限不足
# 40302 ErrTenantMismatch                   租户不匹配
# 40401 ErrNotFound                         entity not found
# 40420 ErrAgentNotFound                    agent 不存在
# 40421 ErrWorkspaceNotFound                workspace 不存在
# 40430 ErrConversationNotFound             会话不存在
# 40431 ErrMessageNotFound                  消息不存在
# 40432 ErrRunNotFound                      Run 不存在
# 40433 ErrPersonaStyleNotFound             人设风格 ref 不可用 (不存在/已归档/无已发布版本/类型不符)
# 40901 ErrVersionConflict                  乐观锁并发更新
# 40930 ErrRunTerminated                    Run 已终态
# 40931 ErrRunNotActive                     Run 不活跃 (预留)
# 40932 ErrRunNotAwaitingHuman              Run 非 awaiting_human_input
# 40933 ErrInvalidStateTransition           状态机转移非法
# 40934 ErrConversationEnded                会话已结束
# 40935 ErrConversationAgentRequired        会话未绑定 agent
# 40936 ErrStepIdempotencyConflict          step 幂等键冲突
# 40938 ErrPersonaStyleNotAccepted          该 Agent 未声明 persona.style_slot, 不接受运行期风格
# 50040 ErrWalletFreezeFailed               Wallet 冻结失败
# 50041 ErrProviderCallFailed               Provider 调用失败
```
