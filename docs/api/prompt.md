# Prompt BC HTTP API

> **Module**: `internal/prompt/port/http`  Prefix: `/v1/prompts`  JWT required (no public routes).
>
> **Sources of truth**:
> - 路由:`internal/prompt/port/http/routes.go`
> - 业务契约:`internal/prompt/api.go`(`PromptAPI` interface + DTO)
> - 错误码映射:`internal/prompt/port/http/errors.go`(`mapDomainErr`)
> - 数据库 DDL:`docs/migrations/p5_01_prompt_bc.sql`
> - 架构文档:`docs/plan/Prompt Engine（系统提示词引擎）+ 复杂记忆体系（三层 Memory BC）.md` §二
>
> Prompt BC 负责 "系统提示词" 的版本化管理 + Go template 渲染。被以下 BC 消费:
> - **Runtime BC** (ExecutorBase.buildContext): 调 `ResolveVersion` + `Render` 构造 `system_prompt`
> - **Catalog BC** (DefinitionValidator): 调 `ValidateTemplateRef` 校验 AgentDefinition 中的 template_ref
> - **Memory BC** P5-02-A 起: 引用内置 `__sys_session_summarizer` / `__sys_fact_extractor` 模板做摘要 + 事实抽取
>
> **内部消费**:LLM 推理 / Workflow / Memory 摘要等直接走 Go interface `PromptAPI`,**不经过 HTTP**(零开销)。HTTP API 主要给:
> ① 管理后台 / 模板作者 UI、② 第三方 SDK、③ 调试渲染。

---

## 路由总览(12 endpoints)

| Method | Path | Operation | 鉴权 | 错误段 |
|---|---|---|---|---|
| `POST` | `/v1/prompts/workspaces/:ws_bid/templates` | 创建模板(status=draft) | JWT | 45003/45020/45021/45022/45301 |
| `GET` | `/v1/prompts/workspaces/:ws_bid/templates` | 列模板(分页 + status/type/is_shared 过滤) | JWT | 45301 |
| `GET` | `/v1/prompts/templates/:bid` | 查模板详情(含 live_version 展开) | JWT | 45001 |
| `PATCH` | `/v1/prompts/templates/:bid` | 更新元数据(name/description/is_shared, 乐观锁) | JWT | 45001/45004/45024 |
| `POST` | `/v1/prompts/templates/:bid/archive` | 归档模板(终态) | JWT | 45001/45301 |
| `POST` | `/v1/prompts/templates/:bid/deprecate` | 标记 deprecated(允许已引用 Agent 继续用) | JWT | 45001/45004/45301 |
| `POST` | `/v1/prompts/templates/:bid/versions` | 创建版本草稿(content_hash 幂等返已有) | JWT | 45004/45008/45009/45010/45023 |
| `GET` | `/v1/prompts/templates/:bid/versions` | 列版本(version_number ASC, 分页) | JWT | 45001 |
| `GET` | `/v1/prompts/versions/:vbid` | 查版本详情 | JWT | 45002 |
| `POST` | `/v1/prompts/templates/:bid/versions/:vbid/publish` | 发布版本(已 live 时返 already_live=true 幂等) | JWT | 45001/45002/45005/45301 |
| `POST` | `/v1/prompts/templates/:bid/rollback` | 回滚到历史版本(指针式 — 修改 live_version_id) | JWT | 45001/45002/45015/45301 |
| `POST` | `/v1/prompts/versions/:vbid/render` | 调试渲染(传 variables,返 RenderedPrompt) | JWT | 45002/45010/45011/45012/45013 |

> **统一签名 + JWT**:12 个端点全部走全局 `/v1/*` 中间件链(App 签名 HMAC + JWTAuthMiddleware)。

---

## 关键概念

### 模板状态机

```
draft → published → deprecated/archived
draft → archived
```

- `draft` → `published`: 首次 PublishVersion 时自动转
- `published` → `deprecated`: 软下线;允许已有 Agent 继续 Render
- `published` → `archived`: 硬归档;CreateVersion / Update 拒绝
- `archived` 是终态

### 版本不可变性 + content_hash 幂等

- 版本一旦 `published_at` 非空即 **immutable**(无 Update 路径)
- `content_hash = SHA-256(body || canonical schema JSON)`
- `(template_id, content_hash)` DB 层 UNIQUE
- **红线 #6**:CreateVersion 检测重复 hash → 返已有版本 `AlreadyExists=true`(不报错)
- PublishVersion 已 live 版本 → 返 `AlreadyLive=true`(不报错)

### 变量优先级(高覆盖低)

```
P4 (highest)  x-auto-inject 注入的运行时变量 (date / memory_summary / ...)
P3            AgentDefinition.persona.system_prompt.variable_overrides
P2            variable_schema.default 值
P1 (lowest)   系统保留 __ 变量 (由 Renderer 强行设置, 不可被 Variables 覆盖)
```

### 渲染沙箱约束

- 模板正文上限 **64KB**(domain.MaxTemplateBodyBytes)
- 单次 Render **100ms 超时**(domain.DefaultRenderTimeout)
- `text/template` `missingkey=error` 模式 — 引用未声明变量返 45013
- 白名单 FuncMap:`upper/lower/trim/trimPrefix/trimSuffix/replace/printf/now/dateFormat/join/default`
- 系统保留变量前缀 `__` 不可在 variable_schema 中声明(45019)

---

## DTOs

### CreateTemplateRequest (POST 创建)

```json
{
  "name": "客服模板",
  "slug": "customer-support",
  "description": "...",
  "template_type": "system_prompt",
  "is_shared": false
}
```

- `slug` 格式:`^[a-z][a-z0-9_-]{2,99}$`;`(tenant_id, workspace_id, slug)` UNIQUE
- `template_type`:`system_prompt` / `user_prompt` / `few_shot_prefix`(默认 system_prompt)
- `is_shared=true`:同租户跨 workspace 可读(内置摘要模板用 `tenant_id=0+is_shared=true`)
- **拒绝**:body 中携带 `tenant_id` / `account_id` 字段(由 JWT 注入)

### CreateVersionRequest (POST 创建版本)

```json
{
  "body": "你是 {{ .company_name }} 的客服...今天 {{ .current_date }}",
  "variable_schema": {
    "properties": {
      "company_name": { "type": "string", "x-required": true },
      "current_date": { "type": "string", "x-auto-inject": "date" }
    }
  },
  "model_hints": { "temperature": 0.7 },
  "release_notes": "初版"
}
```

`x-auto-inject` 允许的值:`date` / `datetime` / `end_user_name` / `workspace_name` / `memory_summary` / `memory_facts` / `memory_context`(后 3 个由 Memory BC P5-02-B 起注入)。

### RenderedPrompt (POST /versions/:vbid/render 响应)

```json
{
  "code": 0,
  "data": {
    "content": "你是 Acme 的客服...今天 2026-05-17",
    "template_version_bid": "0190...",
    "variable_snapshot": {
      "company_name": "Acme",
      "current_date": "2026-05-17",
      "__run_bid": "..."
    },
    "estimated_tokens": 42,
    "rendered_at": "2026-05-17T03:30:00+08:00"
  }
}
```

---

## 内置共享模板

`tenant_id=0, is_shared=true` 的内置模板由各阶段 seed,任何租户可读(RLS USING 含 `OR tenant_id=0`):

| Slug | template_type | 用途 | Seed |
|---|---|---|---|
| `__sys_session_summarizer` | system_prompt | Memory BC L2 摘要压缩(对话→summary + facts) | `p5_01_prompt_bc.sql` |
| `__sys_fact_extractor` | system_prompt | Memory BC L3 consolidation(多段摘要→提炼持久事实) | `p5_01_prompt_bc.sql` |
| `prompt_assist_enhance` | system_prompt | ⭐ **p9_05** Capability `prompt_assist` 增强 mode(润色优化,保持原意和长度) | `p9_04_prompt_assist_templates.sql` |
| `prompt_assist_expand` | system_prompt | ⭐ **p9_05** Capability `prompt_assist` 扩写 mode(补充细节,2-4 倍扩展) | `p9_04_prompt_assist_templates.sql` |

调用方:

- Memory BC P5-02-A 起通过 `PromptAPI.ResolveVersion("__sys_session_summarizer", "latest") → Render(...)` 调用 `__sys_*` 模板
- Capability BC `prompt_assist` Executor 经 `capPort.PromptRenderPort`(bootstrap `capPromptRenderBridge`)调用 `prompt_assist_*` 模板;`bridge` 多一层 `cap:pt:slug:*` Redis 24h 长缓存,与 Prompt BC 自身 `pt:*` cache 隔离
- 运营改模板措辞 = Prompt BC `CreateVersion` + `PublishVersion`(content_hash 幂等),live_version 切换 30s 内 Redis 缓存自然失效 — 无需 redeploy

---

## Outbox 事件(7 种)

写路径 handler 在事务内 outbox.Save 对应事件;消费方为空(P5-01-A),后续 P5-01-B Catalog / P5-02-A Memory 接入:

| EventName | 触发 |
|---|---|
| `prompt.template_created` | CreateTemplate |
| `prompt.template_updated` | UpdateTemplate |
| `prompt.template_deprecated` | DeprecateTemplate |
| `prompt.template_archived` | ArchiveTemplate |
| `prompt.version_created` | CreateVersion |
| `prompt.version_published` | PublishVersion |
| `prompt.version_rolled_back` | RollbackToVersion |

---

## 错误码(45000–45099)

完整映射见 `internal/prompt/port/http/errors.go`。常见:

| 码 | 含义 |
|---|---|
| 45001 | template not found |
| 45002 | version not found |
| 45003 | slug already taken in workspace |
| 45004 | template archived; not writable |
| 45005 | published version is immutable |
| 45007 | content hash already exists; idempotent target |
| 45009 | template body exceeds 64KB |
| 45010 | template body syntax error |
| 45011 | render timeout (100ms) |
| 45012 | missing required variable |
| 45013 | undeclared variable in template |
| 45015 | rollback target must be a published version |
| 45019 | variable name uses reserved __ prefix |
| 45301 | permission denied |

---

## 跨 BC 消费示意 (P5-01-B 起)

```go
// Runtime BC ExecutorBase.buildContext 渲染 system_prompt
versionBID, _ := promptAPI.ResolveVersion(ctx, templateBID, "latest")
rendered, _   := promptAPI.Render(ctx, &prompt.RenderRequest{
    VersionBID: versionBID,
    Variables:  vars,
    ReservedVariables: map[string]any{
        "__run_bid":   run.BID,
        "__agent_bid": agent.BID,
        "__tenant_id": run.TenantID,
    },
})
systemPrompt := rendered.Content

// Catalog BC DefinitionValidator 校验 AgentDefinition.persona.system_prompt template_ref
err := promptAPI.ValidateTemplateRef(ctx, &prompt.TemplateRef{
    TemplateBID:       "...",
    VersionPin:        "latest",
    VariableOverrides: map[string]any{"company_name": "Acme"},
})
```
