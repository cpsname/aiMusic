# Memory BC HTTP API

> **Module**: `internal/memory/port/http`  Prefix: `/v1/memories`  JWT required.
>
> **Sources of truth**:
> - 路由:`internal/memory/port/http/routes.go`
> - 业务契约:`internal/memory/api.go`(`MemoryAPI` interface + 15+ DTO)
> - 错误码映射:`internal/memory/port/http/errors.go`(`mapDomainErr` 46000–46099)
> - 数据库 DDL:`docs/migrations/p5_02_memory_bc.sql`
> - 架构文档:`docs/architecture/memory/README.md`
> - 上层规划:`docs/plan/Prompt Engine（系统提示词引擎）+ 复杂记忆体系（三层 Memory BC）.md` §三-八

## 一、Memory 三层模型

```
L1 Working Memory — Runtime BC Run.Scratchpad (Memory BC 不管)
L2 Session Memory — mem_session_summaries (滚动摘要 + 抽取事实, immutable)
L3 Long-Term     — mem_facts (结构化 KV) + Knowledge BC (语义向量)
```

热路径 (Run 前同步, p95 < 200ms) 由 ExecutorBase 直调 `MemoryAPI.Retrieve` 拿三层产物注入 system_prompt;异步路径 (Run 后) 由 MemoryWorker 经 outbox 触发 `MemoryAPI.UpdateAfterRun` 做摘要 + L3 归档。

## 二、路由总览(12 endpoints)

| Method | Path | Operation | 鉴权 | 错误段 |
|---|---|---|---|---|
| `GET` | `/v1/memories/spaces/:bid` | 查 MemorySpace 详情(含 stats) | JWT | 46001/46301 |
| `POST` | `/v1/memories/spaces/:bid/purge` | 清空记忆(GDPR 删除/重置;含 force 标志) | JWT | 46001/46011/46301 |
| `GET` | `/v1/memories/spaces/:bid/summaries?conversation_bid=` | 列会话摘要 | JWT | 46001/46013 |
| `POST` | `/v1/memories/spaces/:bid/facts` | 显式写入事实(HTTP 强制 source=explicit + confidence=1.0) | JWT | 46001/46005/46014/46017 |
| `GET` | `/v1/memories/spaces/:bid/facts?category=&limit=&offset=` | 列事实(分页 + category 过滤) | JWT | 46001 |
| `PUT` | `/v1/memories/spaces/:bid/facts/:fbid` | 更新事实(走 UPSERT 同接口) | JWT | 46001/46002/46017 |
| `DELETE` | `/v1/memories/spaces/:bid/facts/:fbid` | 删除事实(软删) | JWT | 46001/46002/46301 |
| `POST` | `/v1/memories/spaces/:bid/retrieve` | 调试检索(传 query,返三层产物) | JWT | 46001 |
| `GET` | `/v1/memories/agents/:agent_bid/spaces` | 列该 Agent 下所有 spaces | JWT | 50100 (待 P5-02-D) |
| `POST` | `/v1/memories/agents/:agent_bid/spaces` | 显式创建 space (ResolveSpace 路径) | JWT | 46013/46015 |
| `PATCH` | `/v1/memories/agents/:agent_bid/spaces/:bid` | 更新 space config | JWT | 50100 (待 P5-02-D) |
| `GET` | `/v1/memories/spaces/:bid/timeline` | facts + summaries 时间线视图 | JWT | 46001 |

> **统一签名 + JWT**:全部端点走全局 `/v1/*` 中间件链(App 签名 HMAC + JWTAuthMiddleware)。
>
> ⚠ **当前已知问题(P5-02-A)**:HTTP 路由层代码完整,但 Hertz radix tree 在 `/v1/m` 共享前缀(memories + marketplace + models)场景下 lookup miss(注册成功但 find 返 nil → 默认 404 plain text)。同款问题 P5-01-A prompt 已遇,留 P5-02-D 加固阶段排查 Hertz routing edge case。
>
> **不影响**:BC 间内部消费(Runtime BC / Catalog BC 通过 fx 直接注入 `MemoryAPI`,零 HTTP 开销),P5-02-B Runtime × Memory 集成走此路径。

## 三、关键概念

### MemorySpace OwnerType

| 类型 | 用途 | 必填字段 |
|---|---|---|
| `agent_global` | 整个 Agent 共享(产品知识/品牌) | owner_agent_id |
| `agent_user_pair` | (agent, end_user) 个性化 — **最常用** | owner_agent_id + end_user_id |
| `workspace_user` | 同一 workspace user 跨 Agent | owner_account_id |

### MemorySpaceConfig

```json
{
  "l2_summary_threshold": 20,         // 每 20 轮触发 LLM 摘要压缩
  "l2_summary_model_bid": "uuid",     // 摘要使用的模型版本 (默认平台首选)
  "l2_max_summaries_kept": 5,         // 保留最近 N 条摘要
  "l3_enabled": true,                 // 是否开启 L3 长期语义记忆
  "l3_top_k": 5,                      // 语义检索 top-k
  "l3_consolidation_threshold": 3,    // 累积 N 条 pending 触发归档
  "fact_max_count": 100,              // 单 space 事实上限
  "fact_ttl_days": 180,               // 默认 TTL (0=永久)
  "inject_summary": true,             // 注入 memory_summary 变量
  "inject_facts": true,               // 注入 memory_facts 变量
  "inject_semantic": true             // 注入 memory_context 变量
}
```

### MemoryFact 优先级

UPSERT 时按 `SourceType.Priority()` 判定是否覆盖:

```
Explicit (3) > Inferred (2) > Extracted (1)
```

- HTTP 写入 → 强制 `source=explicit, confidence=1.0`(防外部伪造低优先级)
- LLM 自动抽取 → `source=extracted` (≤ 0.95);不能覆盖人工 explicit 事实
- 同优先级:`incoming.confidence >= existing.confidence` 才覆盖

### 6 种 Outbox 事件

| EventName | 触发 |
|---|---|
| `memory.space_created` | ResolveSpace 懒创建 |
| `memory.fact_upserted` | UpsertFact / SummarizationService |
| `memory.fact_deleted` | DeleteFact (CleanupWorker 过期清理不发) |
| `memory.session_summarized` | MemoryWorker 调 SummarizationService 完成 |
| `memory.consolidated_to_l3` | MemoryWorker 调 ConsolidationService 完成 |
| `memory.space_purged` | GDPR PurgeSpace(含 force 标志 + reason) |

### 三类 Redis 缓存

| Key | TTL | 失效时机 |
|---|---|---|
| `mem:space:{agent_id}:{user_id}` | 5min | UpdateSpace |
| `mem:space:{space_bid}:config` | 5min | UpdateSpace / SetKB |
| `mem:summary:{space_bid}:{conv_bid}` | 2min | SummarizationService 写入 |
| `mem:facts:{space_bid}` | 30s | UpsertFact / DeleteFact |

## 四、DTOs

### POST /v1/memories/agents/:agent_bid/spaces (Resolve/Create)

```json
{
  "workspace_id": 100,
  "owner_type": "agent_user_pair",
  "owner_agent_id": 42,
  "end_user_id": 9527,
  "config": { /* MemorySpaceConfigDTO 可选, 不填用 default */ }
}
```

### POST /v1/memories/spaces/:bid/facts

```json
{
  "fact_key": "user_name",
  "fact_value": "张伟",
  "category": "identity",
  "confidence": 1.0,
  "expires_at": null,
  "is_verified": true
}
```

### POST /v1/memories/spaces/:bid/retrieve (调试)

```json
{
  "conversation_bid": "uuid",
  "query": "用户上次提到的预算是多少?",
  "inject_summary": true,
  "inject_facts": true,
  "inject_semantic": true,
  "top_k_semantic": 5,
  "max_facts_return": 50
}
```

响应:
```json
{
  "code": 0,
  "data": {
    "session_summary": "...",
    "facts": [{ "key": "user_name", "value": "张伟", "category": "identity", ... }],
    "semantic_chunks": [{ "content": "...", "score": 0.87, "source_kind": "session_summary" }],
    "memory_summary": "...(以上为历史对话摘要)",
    "memory_facts": "- user_name: 张伟\n- ...",
    "memory_context": "...",
    "retrieved_at": "..."
  }
}
```

### POST /v1/memories/spaces/:bid/facts/:fbid/resolve

事实冲突处置:对 L3 fact 的 pending 冲突做保留/覆盖/合并裁决(source priority
规则见 UpsertFact;裁决幂等,重复 resolve 返当前态)。

## 五、错误码段(46000–46099)

| 码 | 含义 |
|---|---|
| 46001 | memory space not found |
| 46002 | memory fact not found |
| 46003 | memory space archived |
| 46004 | fact key conflict in space |
| 46005 | fact limit exceeded |
| 46006 | fact category invalid |
| 46007 | confidence out of range |
| 46008 | summarization failed (LLM 失败) |
| 46009 | consolidation to L3 failed |
| 46010 | knowledge base creation failed |
| 46011 | purge not allowed; space has active conversations (use force=true) |
| 46012 | owner_type mismatch |
| 46013 | invalid argument |
| 46014 | fact_key format invalid |
| 46015 | owner_type invalid |
| 46016 | source_type invalid |
| 46017 | source precedence violation (explicit > inferred > extracted) |
| 46018 | consolidation_state transition invalid |
| 46019 | conversation does not belong to space |
| 46301 | permission denied |

## 六、跨 BC 消费示意

```go
// Runtime BC ExecutorBase.buildContext — Run 前同步调用 (P5-02-B 集成)
space, err := memoryAPI.ResolveSpace(ctx, &memory.ResolveSpaceRequest{
    TenantID:     run.TenantID,
    WorkspaceID:  run.WorkspaceID,
    OwnerType:    "agent_user_pair",
    OwnerAgentID: agent.ID,
    EndUserID:    run.EndUserID,
})

retrieval, err := memoryAPI.Retrieve(ctx, &memory.RetrieveMemoryRequest{
    TenantID:        run.TenantID,
    SpaceBID:        space.BID,
    ConversationBID: conv.BID,
    Query:           latestUserMessage,
    InjectSummary:   true,
    InjectFacts:     true,
    InjectSemantic:  true,
})

// 注入 system_prompt 变量
variables["memory_summary"] = retrieval.MemorySummary
variables["memory_facts"]   = retrieval.MemoryFacts
variables["memory_context"] = retrieval.MemoryContext

// Run 完成后异步 (MemoryWorker 触发, 走 outbox runtime.run_succeeded 事件):
//   memoryAPI.UpdateAfterRun(ctx, &memory.UpdateAfterRunRequest{...})
```
