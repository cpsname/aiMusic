# Catalog BC HTTP API

> **Module**: `internal/catalog/port/http`  Prefix: `/v1` JWT required (no public routes).
>
> **Sources of truth**: `routes.go` for routing, `api.go` for DTO contracts, `errors.go` for code mapping.

## 路由总览 (43 endpoints: agent 18 + workflow 20 + skill 5)

### Agent 面 (18)

| Method | Path | Operation | Permission |
|---|---|---|---|
| `POST` | `/workspaces/:ws_bid/agents` | `CreateAgent` | `agent:create_draft` |
| `GET` | `/workspaces/:ws_bid/agents` | `ListAgents` | `agent:view` |
| `GET` | `/agents/:bid` | `GetAgent` | `agent:view` |
| `PATCH` | `/agents/:bid` | `UpdateAgentMetadata` (retrofit2) | `agent:update_draft` |
| `PATCH` | `/agents/:bid/draft` | `UpdateAgentDraft` (alias of `UpdateAgentMetadata`) | `agent:update_draft` |
| `DELETE` | `/agents/:bid` | `DeleteAgent` (soft) (retrofit2) | `agent:delete` |
| `POST` | `/agents/:bid/archive` | `ArchiveAgent` (terminal) | `agent:archive` |
| `POST` | `/agents/:bid/unpublish` | `UnpublishAgent` (published → draft) (retrofit2) | `agent:unpublish` |
| `POST` | `/agents/:bid/versions` | `CreateAgentVersion` (snapshot draft) | `agent:create_version` |
| `GET` | `/agents/:bid/versions` | `ListAgentVersions` | `agent:view` |
| `POST` | `/agents/:bid/versions/:version_bid/publish` | `PublishAgentVersion` | `agent:publish` |
| `POST` | `/agents/:bid/rollback` | `RollbackAgent` | `agent:publish` |
| `GET` | `/agents/:bid/deployments` | `ListDeploymentHistory` | `agent:view` |
| `POST` | `/agents/:bid/canary` | `SetCanary` (initial set) | `agent:publish` |
| `PATCH` | `/agents/:bid/canary` | `UpdateCanaryPercent` (retrofit2) | `agent:publish` |
| `DELETE` | `/agents/:bid/canary` | `ClearCanary` | `agent:publish` |
| `POST` | `/agents/:bid/canary/promote` | `PromoteCanary` (retrofit2) | `agent:publish` |
| `POST` | `/agents/:bid/canary/abort` | `AbortCanary` (retrofit2) | `agent:publish` |

### Workflow 面 (20) — 与 agent 同构 (P4-01)

| Method | Path | Operation |
|---|---|---|
| `POST` | `/workspaces/:ws_bid/workflows` | `CreateWorkflow` |
| `GET` | `/workspaces/:ws_bid/workflows` | `ListWorkflows` |
| `GET` | `/workflows/:bid` | `GetWorkflow` |
| `PATCH` | `/workflows/:bid` | `UpdateWorkflowMetadata` |
| `PUT` | `/workflows/:bid/draft` | `UpdateWorkflowDraft`(DSL 草稿, ValidateStatic 早反馈)|
| `POST` | `/workflows/:bid/archive` | `ArchiveWorkflow` |
| `POST` | `/workflows/:bid/unpublish` | `UnpublishWorkflow` |
| `DELETE` | `/workflows/:bid` | `DeleteWorkflow`(soft)|
| `POST` | `/workflows/:bid/versions` | `CreateWorkflowVersion`(三阶段编译 + 静态分析落库)|
| `GET` | `/workflows/:bid/versions` | `ListWorkflowVersions` |
| `POST` | `/workflows/:bid/versions/:version_bid/publish` | `PublishWorkflowVersion`(llm ref pin-at-publish)|
| `POST` | `/workflows/:bid/rollback` | `RollbackWorkflow` |
| `GET` | `/workflows/:bid/deployments` | `ListWorkflowDeploymentHistory` |
| `GET` | `/workflow-versions/:version_bid` | `GetWorkflowVersion` |
| `GET` | `/workflow-versions/:version_bid/compiled-dag` | `GetCompiledDAG` |
| `POST/DELETE/PATCH` | `/workflows/:bid/canary` | Set / Clear / UpdatePercent |
| `POST` | `/workflows/:bid/canary/{promote,abort}` | Promote / Abort |

### Skill 面 (5) — WK-11 市场化 (D-12)

| Method | Path | Operation |
|---|---|---|
| `POST` | `/skills/match` | `MatchSkills`(触发词匹配 + 工具可用性交集标注)|
| `GET` | `/marketplace/skills` | `ListMarketSkills`(跨租户发现, 附安装量/已装标记)|
| `POST` | `/workspaces/:ws_bid/skill-installations` | `InstallSkill`(幂等; disabled 复用启用)|
| `GET` | `/workspaces/:ws_bid/skill-installations` | `ListInstalledSkills` |
| `DELETE` | `/skill-installations/:bid` | `UninstallSkill`(软删)|

> skill 生命周期(create/save-draft/submit/publish SoD/deprecate/market 上下架)走
> facade `CatalogAPI.{CreateSkill,SaveSkillDraft,...}` 供内部/管理侧调用, 未开 HTTP 面。
> D-2 合表后三面同存 `cat_artifacts`(kind 判别), 对外契约零变化。

## Lifecycle 状态机

```
            ┌─────────┐ Publish ┌────────────┐  Archive   ┌──────────┐
   Create → │  draft  │ ──────→ │  published │ ─────────→ │ archived │ (terminal)
            └─────────┘         └────────────┘            └──────────┘
                ↑   Unpublish        │
                └────────────────────┘
                              Delete (soft) any state → tombstoned
```

## Canary 子状态机 (published 内)

```
SetCanary(version,percent)         PromoteCanary
   ┌──────────────────────────────────────────────────┐
   │                                                  ↓
no canary ────→ canary running (version, percent) ─→ canary becomes published
                  │     │                              ↓
                  │     │                       no canary (back to start)
                  │     │
       UpdateCanaryPercent  /  AbortCanary or ClearCanary
       (only percent)         (canary discarded, published unchanged)
```

`SetCanary` 与 `UpdateCanaryPercent` 区别:
- `SetCanary`: 必传 `version_bid` + `percent`; 可在 canary 已 running 时调整 version (替换金丝雀目标).
- `UpdateCanaryPercent`: 仅传 `percent`; 不允许换 version, 仅调流量比例.
- `PromoteCanary`: canary version 升级为 published; canary 清零.
- `AbortCanary` / `ClearCanary`: canary 撤销, published 不变. `Abort` 强制传 reason 入审计.

## Request / Response shapes

### CreateAgent
```http
POST /v1/workspaces/{ws_bid}/agents
{ "code": "support_bot", "name": "Support Bot", "slug": "support",
  "category": "service", "avatar_url": "https://..." }
```
返回 `AgentDTO`.

### UpdateAgentMetadata (PATCH /agents/:bid) / UpdateAgentDraft (PATCH /agents/:bid/draft)
```http
{ "name"?: string, "slug"?: string, "category"?: string, "avatar_url"?: string }
```
任一字段省略 = 不变. 两个端点等价 (历史命名遗留).

### CreateAgentVersion
```http
POST /v1/agents/{bid}/versions
{ "definition": { ... 见 agent-definition-spec.md ... },
  "release_notes": "v1 first release" }
```
返回 `AgentVersionDTO`. 同 `definition_hash` 命中既有版本 → 幂等返回, 不写新行.

### PublishAgentVersion
```http
POST /v1/agents/{bid}/versions/{version_bid}/publish
{ "notes": "ship to all users" }
```
返回 `{ version, already_live }`. `already_live=true` 表示该版本已是 published, 幂等无副作用.

### RollbackAgent
```http
POST /v1/agents/{bid}/rollback
{ "target_version_bid": "<历史 published 版本 bid>", "notes": "incident-2026-04-21" }
```
深拷贝目标定义 → 新版本 (max+1) → publish; `is_rollback_of_version_id` 指向被回滚到的版本.

### SetCanary
```http
POST /v1/agents/{bid}/canary
{ "version_bid": "<已 publish 的版本 bid>", "percent": 30 }
```
`percent ∈ (0, 100]`; canary version 必须 `published_at != NULL` 且 ≠ 当前 published_version.

### UpdateCanaryPercent (retrofit2)
```http
PATCH /v1/agents/{bid}/canary
{ "percent": 70 }
```
仅当 canary 已 running 时合法. 不能换 version (要换 version 用 `SetCanary`).

### PromoteCanary (retrofit2)
```http
POST /v1/agents/{bid}/canary/promote
{ "notes": "soak passed" }
```
canary_version_id → published_version_id; canary 清零. history.action=`canary_promote`.

### AbortCanary (retrofit2)
```http
POST /v1/agents/{bid}/canary/abort
{ "reason": "metric regression" }
```
canary 清零, published 不变. history.action=`canary_abort`. reason 写入 `notes`.

### UnpublishAgent (redux)
```http
POST /v1/agents/{bid}/unpublish
{ "reason": "compliance pause" }
```
status: published → draft; 清 published_version_id + canary. 历史版本保留 (可后续再 publish).

### DeleteAgent (retrofit2)
```http
DELETE /v1/agents/{bid}
{ "reason": "user requested" }
```
软删 (deleted_at 设置). RLS 隐藏. 与 `Archive` 区别: Archive 是 status=archived, 行可见.

## Errors

按 sentinel 错误映射 HTTP code, 见 `internal/catalog/port/http/errors.go`.

| Sentinel | HTTP | Code |
|---|---|---|
| `ErrAgentNotFound` / `ErrVersionNotFound` | 404 | 40404 |
| `ErrPermissionDenied` | 403 | 40301 |
| `ErrSlugConflict` / `ErrDuplicateAgentCode` | 409 | 40901 |
| `ErrVersionConflict` (乐观锁) | 409 | 40902 |
| `ErrInvalidStatusTransition` | 422 | 42202 |
| `ErrCanaryPercentInvalid` / `ErrCanaryNotSet` / `ErrCanaryVersionNotPublished` | 422 | 42203 |
| `ErrDefinitionInvalid` | 422 | 42201 |
| `ErrRollbackTargetInvalid` | 422 | 42204 |

## Outbox 事件 (10 种)

每次写命令在同 tx 内 Save 一条 `shared_outbox_messages` 记录:

| Event Name | 触发命令 |
|---|---|
| `catalog.agent_created` | CreateAgent |
| `catalog.agent_draft_updated` | UpdateAgentMetadata / UpdateAgentDraft |
| `catalog.agent_version_created` | CreateAgentVersion |
| `catalog.agent_published` | PublishAgentVersion |
| `catalog.agent_rolled_back` | RollbackAgent |
| `catalog.agent_canary_updated` | SetCanary / ClearCanary / UpdateCanaryPercent |
| `catalog.agent_canary_promoted` | PromoteCanary |
| `catalog.agent_canary_aborted` | AbortCanary |
| `catalog.agent_unpublished` | UnpublishAgent |
| `catalog.agent_deleted` | DeleteAgent |

## ResolveForRuntime (in-process API, 无 HTTP)

```go
catalogAPI.ResolveForRuntime(ctx, &ResolveForRuntimeRequest{
    AgentBID: "<uuid>", EndUserID: 12345,
})  // → *ResolvedAgent
```

确定性灰度: `FNV-1a(agent_bid + endUserID_be_bytes) % 100 < canary_percent ? canary : published`.
同 `endUserID` 在 `canary_percent` 不变时永远命中同一版本 (避免闪烁).

## OpenAPI 3.1 Specification

> 基于代码事实生成。来源:`internal/catalog/port/http/{routes,agent_handler,canary_handler,version_handler,workflow_handler,errors}.go` + `catalog/api.go` (DTO) + `domain/{entity/agent_status,valueobject/{agent_definition,deployment_action,workflow_definition,workflow_status,compiled_dag}}.go`。
>
> 公共契约见 [overview.md](overview.md)。Catalog 是最大的 BC: **38 endpoints** = Agent 18 + Workflow 20.

```yaml
openapi: 3.1.0
info:
  title: AIGC Platform — Catalog Domain API
  description: |
    Catalog BC 38 endpoints:
      - Agent: CRUD + Draft + Archive/Unpublish + Versioning + Canary (18)
      - Workflow: CRUD + Versioning + Canary + CompiledDAG (20, P4-01)

    版本不可变: AgentVersion / WorkflowVersion UNIQUE(aggregate_id, version_number) 单调.
    灰度: canary_version_id + canary_percent 字段 + Outbox 事件; 真实流量分流由 Runtime BC 实现
         (FNV-1a hash(end_user_id) % 100 < percent).
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

    AgentDTO:
      type: object
      required: [bid, tenant_id, workspace_id, name, slug, status, version]
      properties:
        agent_id: { type: integer, format: int64 }
        bid: { type: string, format: uuid }
        tenant_id: { type: integer, format: int64 }
        workspace_id: { type: integer, format: int64 }
        code: { type: string }
        name: { type: string }
        slug: { type: string }
        category: { type: string }
        avatar_url: { type: string, format: uri }
        status: { type: string, enum: [draft, published, archived] }
        latest_version_id: { type: integer, format: int64, nullable: true }
        published_version_id: { type: integer, format: int64, nullable: true }
        canary_version_id: { type: integer, format: int64, nullable: true }
        canary_percent: { type: integer, minimum: 0, maximum: 100 }
        version: { type: integer, description: 乐观锁版本号 }
        created_at: { type: string, format: date-time }
        updated_at: { type: string, format: date-time }

    AgentVersionDTO:
      type: object
      required: [version_id, bid, agent_id, version_number, definition]
      properties:
        version_id: { type: integer, format: int64 }
        bid: { type: string, format: uuid }
        tenant_id: { type: integer, format: int64 }
        agent_id: { type: integer, format: int64 }
        version_number: { type: integer }
        definition:
          type: object
          additionalProperties: true
          description: |
            AgentDefinition jsonb (强类型校验, 见 valueobject/agent_definition.go):
              { model {model_version_ref, temperature, max_tokens, top_p, fallback_chain},
                persona {system_prompt, variables, greeting},
                tools[] {tool_ref, config, enabled},
                knowledge_bases[], sub_agents[],
                execution {mode (direct/react/plan_execute/workflow), max_iterations, timeout_seconds, workflow_version_ref},
                safety {input_filter_enabled, output_filter_enabled, pii_redaction, content_categories_blocked},
                output_schema, feature_flags }
        release_notes: { type: string }
        published_at: { type: string, format: date-time, nullable: true }
        published_by_account_id: { type: integer, format: int64 }
        created_by_account_id: { type: integer, format: int64 }
        created_at: { type: string, format: date-time }

    DeploymentHistoryDTO:
      type: object
      required: [bid, agent_id, action, created_at]
      properties:
        bid: { type: string, format: uuid }
        agent_id: { type: integer, format: int64 }
        action:
          type: string
          enum: [publish, rollback, canary_set, canary_clear, canary_promote, canary_abort, unpublish, agent_deleted]
        from_version_id: { type: integer, format: int64 }
        to_version_id: { type: integer, format: int64 }
        target_original_version_id: { type: integer, format: int64 }
        canary_percent: { type: integer }
        actor_account_id: { type: integer, format: int64 }
        notes: { type: string }
        created_at: { type: string, format: date-time }

    WorkflowDTO:
      type: object
      required: [bid, tenant_id, workspace_id, name, slug, status, version]
      properties:
        workflow_id: { type: integer, format: int64 }
        bid: { type: string, format: uuid }
        tenant_id: { type: integer, format: int64 }
        workspace_id: { type: integer, format: int64 }
        name: { type: string }
        slug: { type: string }
        description: { type: string }
        category: { type: string }
        status: { type: string, enum: [draft, published, archived] }
        latest_version_id: { type: integer, format: int64, nullable: true }
        published_version_id: { type: integer, format: int64, nullable: true }
        canary_version_id: { type: integer, format: int64, nullable: true }
        canary_percent: { type: integer, minimum: 0, maximum: 100 }
        draft_updated_at: { type: string, format: date-time, nullable: true }
        version: { type: integer }
        created_at: { type: string, format: date-time }
        updated_at: { type: string, format: date-time }

    WorkflowVersionDTO:
      type: object
      required: [version_id, bid, workflow_id, version_number, definition, definition_hash]
      properties:
        version_id: { type: integer, format: int64 }
        bid: { type: string, format: uuid }
        tenant_id: { type: integer, format: int64 }
        workflow_id: { type: integer, format: int64 }
        version_number: { type: integer }
        display_version: { type: string }
        definition:
          type: object
          additionalProperties: true
          description: |
            WorkflowDefinition v1.0 jsonb. 15 节点类型 (trigger/llm/tool/retrieval/code/http/
            condition/loop/parallel/wait/human_approval/variable_set/template_render/subflow/end).
        definition_hash: { type: string, description: "SHA-256 of normalized definition (幂等去重)" }
        release_notes: { type: string }
        published_at: { type: string, format: date-time, nullable: true }
        published_by_account_id: { type: integer, format: int64 }
        created_by_account_id: { type: integer, format: int64 }
        node_count: { type: integer, description: "静态分析: 节点数" }
        edge_count: { type: integer }
        max_depth: { type: integer }
        has_loop_node: { type: boolean }
        has_human_approval_node: { type: boolean }
        has_subflow_node: { type: boolean }
        referenced_tools:
          type: array
          items: { type: string, format: uuid }
        referenced_kbs:
          type: array
          items: { type: string, format: uuid }
        referenced_models:
          type: array
          items: { type: string, format: uuid }
        referenced_subflows:
          type: array
          items: { type: string, format: uuid }
        created_at: { type: string, format: date-time }

    WorkflowDeploymentHistoryDTO:
      type: object
      required: [bid, workflow_id, action, created_at]
      properties:
        bid: { type: string, format: uuid }
        workflow_id: { type: integer, format: int64 }
        action:
          type: string
          enum: [publish, rollback, canary_set, canary_clear, unpublish]
        from_version_id: { type: integer, format: int64 }
        to_version_id: { type: integer, format: int64 }
        target_original_version_id: { type: integer, format: int64 }
        canary_percent: { type: integer }
        actor_account_id: { type: integer, format: int64 }
        notes: { type: string }
        created_at: { type: string, format: date-time }

    CompiledDAGDTO:
      type: object
      required: [version_bid, node_count, edge_count]
      properties:
        version_bid: { type: string, format: uuid }
        node_count: { type: integer }
        edge_count: { type: integer }
        max_depth: { type: integer }
        order:
          type: array
          items: { type: string }
          description: 拓扑序节点 id 列表
        entry_node_ids:
          type: array
          items: { type: string }
        exit_node_ids:
          type: array
          items: { type: string }
        barrier_count: { type: integer }
        loop_count: { type: integer }
        gate_count: { type: integer }
        definition:
          type: object
          additionalProperties: true
          nullable: true

    CreateAgentRequest:
      type: object
      required: [name, slug]
      properties:
        code: { type: string, description: "缺时用 slug 补" }
        name: { type: string }
        slug: { type: string }
        category: { type: string }
        avatar_url: { type: string, format: uri }

    UpdateAgentDraftRequest:
      type: object
      description: 全部字段 optional, 不传不修改
      properties:
        name: { type: string }
        slug: { type: string }
        category: { type: string }
        avatar_url: { type: string }

    UpdateAgentMetadataRequest:
      type: object
      properties:
        name: { type: string }
        slug: { type: string }
        category: { type: string }
        avatar_url: { type: string }

    CreateAgentVersionRequest:
      type: object
      required: [definition]
      properties:
        definition:
          type: object
          additionalProperties: true
          description: 完整 AgentDefinition (DefinitionValidator 校验)
        release_notes: { type: string }

    PublishAgentVersionRequest:
      type: object
      properties:
        notes: { type: string }

    PublishAgentVersionResponse:
      type: object
      required: [version, already_live]
      properties:
        version: { $ref: '#/components/schemas/AgentVersionDTO' }
        already_live:
          type: boolean
          description: definition_hash 命中已发布版本时 true (幂等返)

    RollbackAgentRequest:
      type: object
      required: [target_version_bid]
      properties:
        target_version_bid: { type: string, format: uuid }
        notes: { type: string }

    RollbackAgentResponse:
      type: object
      required: [new_version, target_original_version]
      properties:
        new_version:
          $ref: '#/components/schemas/AgentVersionDTO'
          description: 新建版本(definition 深拷贝自 target)
        target_original_version: { $ref: '#/components/schemas/AgentVersionDTO' }

    SetCanaryRequest:
      type: object
      required: [version_bid, percent]
      properties:
        version_bid: { type: string, format: uuid }
        percent: { type: integer, minimum: 1, maximum: 100 }

    UpdateCanaryPercentRequest:
      type: object
      required: [percent]
      properties:
        percent: { type: integer, minimum: 1, maximum: 100 }

    CreateWorkflowRequest:
      type: object
      required: [name, slug]
      properties:
        name: { type: string }
        slug: { type: string }
        description: { type: string }
        category: { type: string }

    UpdateWorkflowDraftRequest:
      type: object
      required: [definition]
      properties:
        definition:
          type: object
          additionalProperties: true

    CreateWorkflowVersionRequest:
      type: object
      properties:
        definition:
          type: object
          additionalProperties: true
          description: 缺时用当前 draft
        display_version: { type: string }
        release_notes: { type: string }

paths:
  # ──────────────────── Agent ────────────────────
  /workspaces/{ws_bid}/agents:
    parameters:
      - { name: ws_bid, in: path, required: true, schema: { type: string, format: uuid } }
    post:
      summary: 创建 Agent
      operationId: createAgent
      tags: [Agent]
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/CreateAgentRequest' }
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
                      data: { $ref: '#/components/schemas/AgentDTO' }
        '409':
          description: slug 冲突 (40920) / code 冲突 (40921)

    get:
      summary: 列 workspace 内的 Agent
      operationId: listAgents
      tags: [Agent]
      parameters:
        - { name: category, in: query, schema: { type: string } }
        - { name: status, in: query, schema: { type: string, enum: [draft, published, archived] } }
        - { name: limit, in: query, schema: { type: integer, default: 20, maximum: 200 } }
        - { name: offset, in: query, schema: { type: integer, default: 0 } }
      responses:
        '200':
          description: Agent 列表
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
                            items: { $ref: '#/components/schemas/AgentDTO' }
                          total: { type: integer }

  /agents/{bid}:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
    get:
      summary: 取 Agent 详情
      operationId: getAgent
      tags: [Agent]
      responses:
        '200':
          description: Agent 详情
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/AgentDTO' }
        '404':
          description: 不存在 (40420)

    patch:
      summary: 更新 Agent metadata (P1-01 redux)
      operationId: updateAgentMetadata
      tags: [Agent]
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/UpdateAgentMetadataRequest' }
      responses:
        '200':
          description: "更新成功 (data: null)"
          content:
            application/json:
              schema: { $ref: '#/components/schemas/StandardResponse' }

    delete:
      summary: 软删 Agent
      operationId: deleteAgent
      tags: [Agent]
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                reason: { type: string }
      responses:
        '200':
          description: "删除成功 (data: null)"
          content:
            application/json:
              schema: { $ref: '#/components/schemas/StandardResponse' }

  /agents/{bid}/draft:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
    patch:
      summary: 更新 draft (基础字段)
      operationId: updateAgentDraft
      tags: [Agent]
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/UpdateAgentDraftRequest' }
      responses:
        '200':
          description: "更新成功 (data: null)"
          content:
            application/json:
              schema: { $ref: '#/components/schemas/StandardResponse' }

  /agents/{bid}/archive:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
    post:
      summary: 归档 Agent (终态)
      operationId: archiveAgent
      tags: [Agent]
      responses:
        '200':
          description: "归档成功 (data: null)"
          content:
            application/json:
              schema: { $ref: '#/components/schemas/StandardResponse' }
        '409':
          description: 已归档 (40922)

  /agents/{bid}/unpublish:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
    post:
      summary: 取消发布 (回 draft, 历史版本保留)
      operationId: unpublishAgent
      tags: [Agent]
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                reason: { type: string }
      responses:
        '200':
          description: "取消发布成功 (data: null)"
          content:
            application/json:
              schema: { $ref: '#/components/schemas/StandardResponse' }
        '409':
          description: 状态转换非法 (40923)

  /agents/{bid}/versions:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
    post:
      summary: 创建 Agent 版本 (从 draft 快照)
      operationId: createAgentVersion
      tags: [AgentVersion]
      description: |
        DefinitionValidator 校验 (40040 ErrDefinitionInvalid).
        version_number = max(existing) + 1, UNIQUE(agent_id, version_number) 保证.
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/CreateAgentVersionRequest' }
      responses:
        '200':
          description: 版本已创建
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/AgentVersionDTO' }
        '400':
          description: definition 校验失败 (40040)

    get:
      summary: 列 Agent 版本
      operationId: listAgentVersions
      tags: [AgentVersion]
      parameters:
        - { name: only_published, in: query, schema: { type: boolean, default: false } }
        - { name: limit, in: query, schema: { type: integer, default: 20, maximum: 200 } }
        - { name: offset, in: query, schema: { type: integer, default: 0 } }
      responses:
        '200':
          description: 版本列表
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
                            items: { $ref: '#/components/schemas/AgentVersionDTO' }
                          total: { type: integer }

  /agents/{bid}/versions/{version_bid}/publish:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
      - { name: version_bid, in: path, required: true, schema: { type: string, format: uuid } }
    post:
      summary: 发布 Agent 版本
      operationId: publishAgentVersion
      tags: [AgentVersion]
      description: |
        相同 definition_hash 命中已发布版本时返已有 (already_live=true), 不增版本号.
      requestBody:
        content:
          application/json:
            schema: { $ref: '#/components/schemas/PublishAgentVersionRequest' }
      responses:
        '200':
          description: 发布成功
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/PublishAgentVersionResponse' }
        '400':
          description: version 不属于 agent (40321)

  /agents/{bid}/rollback:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
    post:
      summary: 回滚 (创建新版本, definition 深拷贝自 target + publish)
      operationId: rollbackAgent
      tags: [AgentVersion]
      description: |
        target_version 必须已发布 (40926 ErrRollbackTargetInvalid).
        version_number 单调不跳号.
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/RollbackAgentRequest' }
      responses:
        '200':
          description: 回滚成功
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/RollbackAgentResponse' }

  /agents/{bid}/deployments:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
    get:
      summary: 部署历史 (publish/rollback/canary 全审计)
      operationId: listDeploymentHistory
      tags: [AgentVersion]
      parameters:
        - { name: action, in: query, schema: { type: string, enum: [publish, rollback, canary_set, canary_clear, canary_promote, canary_abort, unpublish, agent_deleted] } }
        - { name: limit, in: query, schema: { type: integer, default: 20, maximum: 200 } }
        - { name: offset, in: query, schema: { type: integer, default: 0 } }
      responses:
        '200':
          description: 部署历史
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
                            items: { $ref: '#/components/schemas/DeploymentHistoryDTO' }
                          total: { type: integer }

  /agents/{bid}/canary:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
    post:
      summary: 设灰度 (canary_version_id + percent)
      operationId: setCanary
      tags: [Canary]
      description: 真实流量分流由 Runtime BC 实现 (FNV-1a hash(end_user_id) % 100 < percent)
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/SetCanaryRequest' }
      responses:
        '200':
          description: "设置成功 (data: null)"
          content:
            application/json:
              schema: { $ref: '#/components/schemas/StandardResponse' }
        '409':
          description: version 未发布 (40927)
    patch:
      summary: 调整灰度百分比
      operationId: updateCanaryPercent
      tags: [Canary]
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/UpdateCanaryPercentRequest' }
      responses:
        '200':
          description: "更新成功 (data: null)"
          content:
            application/json:
              schema: { $ref: '#/components/schemas/StandardResponse' }
    delete:
      summary: 清除灰度
      operationId: clearCanary
      tags: [Canary]
      responses:
        '200':
          description: "清除成功 (data: null)"
          content:
            application/json:
              schema: { $ref: '#/components/schemas/StandardResponse' }

  /agents/{bid}/canary/promote:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
    post:
      summary: 灰度晋级 (canary_version_id → published_version_id, canary 清空)
      operationId: promoteCanary
      tags: [Canary]
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties: { notes: { type: string } }
      responses:
        '200':
          description: "晋级成功 (data: null)"
          content:
            application/json:
              schema: { $ref: '#/components/schemas/StandardResponse' }

  /agents/{bid}/canary/abort:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
    post:
      summary: 灰度撤销 (canary 清空, published 不变)
      operationId: abortCanary
      tags: [Canary]
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties: { reason: { type: string } }
      responses:
        '200':
          description: "撤销成功 (data: null)"
          content:
            application/json:
              schema: { $ref: '#/components/schemas/StandardResponse' }

  # ──────────────────── Workflow (P4-01) ────────────────────
  /workspaces/{ws_bid}/workflows:
    parameters:
      - { name: ws_bid, in: path, required: true, schema: { type: string, format: uuid } }
    post:
      summary: 创建 Workflow
      operationId: createWorkflow
      tags: [Workflow]
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/CreateWorkflowRequest' }
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
                      data: { $ref: '#/components/schemas/WorkflowDTO' }
    get:
      summary: 列 Workflow
      operationId: listWorkflows
      tags: [Workflow]
      parameters:
        - { name: category, in: query, schema: { type: string } }
        - { name: status, in: query, schema: { type: string, enum: [draft, published, archived] } }
        - { name: limit, in: query, schema: { type: integer, default: 20, maximum: 200 } }
        - { name: offset, in: query, schema: { type: integer, default: 0 } }
      responses:
        '200':
          description: Workflow 列表
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
                            items: { $ref: '#/components/schemas/WorkflowDTO' }
                          total: { type: integer }

  /workflows/{bid}:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
    get:
      summary: 取 Workflow 详情
      operationId: getWorkflow
      tags: [Workflow]
      responses:
        '200':
          description: Workflow 详情
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/WorkflowDTO' }
        '404':
          description: 不存在 (40430)
    patch:
      summary: 更新 Workflow metadata
      operationId: updateWorkflowMetadata
      tags: [Workflow]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                name: { type: string }
                slug: { type: string }
                category: { type: string }
                description: { type: string }
      responses:
        '200':
          description: 更新成功
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data:
                        type: object
                        properties: { updated: { type: boolean } }
    delete:
      summary: 软删 Workflow
      operationId: deleteWorkflow
      tags: [Workflow]
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties: { reason: { type: string } }
      responses:
        '200':
          description: 删除成功
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data:
                        type: object
                        properties: { deleted: { type: boolean } }

  /workflows/{bid}/draft:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
    put:
      summary: 保存 Workflow draft (DSL 校验)
      operationId: updateWorkflowDraft
      tags: [Workflow]
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/UpdateWorkflowDraftRequest' }
      responses:
        '200':
          description: 保存成功
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data:
                        type: object
                        properties: { saved: { type: boolean } }
        '400':
          description: DSL 校验失败 (40050-40062)

  /workflows/{bid}/archive:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
    post:
      summary: 归档 Workflow
      operationId: archiveWorkflow
      tags: [Workflow]
      responses:
        '200':
          description: 归档成功
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data:
                        type: object
                        properties: { archived: { type: boolean } }

  /workflows/{bid}/unpublish:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
    post:
      summary: 取消发布
      operationId: unpublishWorkflow
      tags: [Workflow]
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties: { reason: { type: string } }
      responses:
        '200':
          description: 已下线
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data:
                        type: object
                        properties: { unpublished: { type: boolean } }

  /workflows/{bid}/versions:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
    post:
      summary: 创建 Workflow 版本 (DSL 编译 + 静态分析)
      operationId: createWorkflowVersion
      tags: [WorkflowVersion]
      description: |
        编译三阶段: JSON Schema 校验 → 语义校验 (needs 环 / CEL / template / subflow 递归)
        → 编译为 CompiledDAG + StaticAnalysis (落库).
      requestBody:
        content:
          application/json:
            schema: { $ref: '#/components/schemas/CreateWorkflowVersionRequest' }
      responses:
        '200':
          description: 版本已创建
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/WorkflowVersionDTO' }
        '400':
          description: DSL 校验失败 (40050-40062)
    get:
      summary: 列 Workflow 版本
      operationId: listWorkflowVersions
      tags: [WorkflowVersion]
      parameters:
        - { name: only_published, in: query, schema: { type: boolean, default: false } }
        - { name: limit, in: query, schema: { type: integer, default: 20, maximum: 200 } }
        - { name: offset, in: query, schema: { type: integer, default: 0 } }
      responses:
        '200':
          description: 版本列表
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
                            items: { $ref: '#/components/schemas/WorkflowVersionDTO' }
                          total: { type: integer }

  /workflows/{bid}/versions/{version_bid}/publish:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
      - { name: version_bid, in: path, required: true, schema: { type: string, format: uuid } }
    post:
      summary: 发布 Workflow 版本
      operationId: publishWorkflowVersion
      tags: [WorkflowVersion]
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties: { notes: { type: string } }
      responses:
        '200':
          description: 发布成功 (含 already_live 幂等标记)
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
                          version: { $ref: '#/components/schemas/WorkflowVersionDTO' }
                          already_live: { type: boolean }

  /workflows/{bid}/rollback:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
    post:
      summary: 回滚 Workflow
      operationId: rollbackWorkflow
      tags: [WorkflowVersion]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [target_version_bid]
              properties:
                target_version_bid: { type: string, format: uuid }
                notes: { type: string }
      responses:
        '200':
          description: 回滚成功
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
                          new_version: { $ref: '#/components/schemas/WorkflowVersionDTO' }
                          target_original_version: { $ref: '#/components/schemas/WorkflowVersionDTO' }

  /workflow-versions/{version_bid}:
    parameters:
      - { name: version_bid, in: path, required: true, schema: { type: string, format: uuid } }
    get:
      summary: 取 Workflow 版本详情
      operationId: getWorkflowVersion
      tags: [WorkflowVersion]
      responses:
        '200':
          description: 版本详情
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/WorkflowVersionDTO' }
        '404':
          description: 不存在 (40431)

  /workflow-versions/{version_bid}/compiled-dag:
    parameters:
      - { name: version_bid, in: path, required: true, schema: { type: string, format: uuid } }
    get:
      summary: 取已编译 DAG (拓扑序 + 静态分析)
      operationId: getCompiledDAG
      tags: [WorkflowVersion]
      responses:
        '200':
          description: CompiledDAG
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/CompiledDAGDTO' }

  /workflows/{bid}/canary:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
    post:
      summary: 设 Workflow 灰度
      operationId: setWorkflowCanary
      tags: [WorkflowCanary]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [version_bid, percent]
              properties:
                version_bid: { type: string, format: uuid }
                percent: { type: integer, minimum: 1, maximum: 100 }
                notes: { type: string }
      responses:
        '200':
          description: 设置成功
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data:
                        type: object
                        properties: { canary_set: { type: boolean } }
    patch:
      summary: 调整 Workflow 灰度百分比
      operationId: updateWorkflowCanaryPercent
      tags: [WorkflowCanary]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [percent]
              properties:
                percent: { type: integer, minimum: 1, maximum: 100 }
      responses:
        '200':
          description: 更新成功
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data:
                        type: object
                        properties: { updated: { type: boolean } }
    delete:
      summary: 清 Workflow 灰度
      operationId: clearWorkflowCanary
      tags: [WorkflowCanary]
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties: { notes: { type: string } }
      responses:
        '200':
          description: 清除成功
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data:
                        type: object
                        properties: { canary_cleared: { type: boolean } }

  /workflows/{bid}/canary/promote:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
    post:
      summary: Workflow 灰度晋级
      operationId: promoteWorkflowCanary
      tags: [WorkflowCanary]
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties: { notes: { type: string } }
      responses:
        '200':
          description: 晋级成功
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data:
                        type: object
                        properties: { promoted: { type: boolean } }

  /workflows/{bid}/canary/abort:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
    post:
      summary: Workflow 灰度撤销
      operationId: abortWorkflowCanary
      tags: [WorkflowCanary]
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties: { reason: { type: string } }
      responses:
        '200':
          description: 撤销成功
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data:
                        type: object
                        properties: { aborted: { type: boolean } }

  /workflows/{bid}/deployments:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
    get:
      summary: Workflow 部署历史
      operationId: listWorkflowDeployments
      tags: [WorkflowVersion]
      parameters:
        - { name: action, in: query, schema: { type: string, enum: [publish, rollback, canary_set, canary_clear, unpublish] } }
        - { name: limit, in: query, schema: { type: integer, default: 20, maximum: 200 } }
        - { name: offset, in: query, schema: { type: integer, default: 0 } }
      responses:
        '200':
          description: 部署历史
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
                            items: { $ref: '#/components/schemas/WorkflowDeploymentHistoryDTO' }
                          total: { type: integer }

# 错误码段 (来源 internal/catalog/port/http/errors.go::mapDomainErr L21-111)
#
# 40030 通用 BindAndValidate 失败
# 40033 ErrSlugInvalid                   slug 格式无效
# 40040 ErrDefinitionInvalid             AgentDefinition 校验失败
# 40041 ErrCanaryPercentInvalid          canary_percent ∉ (0,100]
# 40050 ErrWorkflowSchemaInvalid         workflow JSON Schema 失败
# 40051 ErrWorkflowSemanticInvalid       workflow 语义校验失败
# 40052 ErrWorkflowCompileFailed         workflow 编译失败
# 40053 ErrWorkflowDuplicateNodeID       重复 node id
# 40054 ErrWorkflowUnknownNodeType       节点类型未知
# 40055 ErrWorkflowNeedsCycle            needs 形成环
# 40056 ErrWorkflowNeedsUnknown          needs 引用未知节点
# 40057 ErrWorkflowSubflowCycle          subflow 形成环
# 40058 ErrWorkflowSubflowDepthExceeded  subflow 深度超限
# 40059 ErrWorkflowExpressionInvalid    CEL 表达式无效
# 40060 ErrWorkflowTemplateInvalid      template 无效
# 40061 ErrWorkflowTemplateUndeclaredRef template 引用节点未声明 needs
# 40062 ErrWorkflowMissingEndNode        缺少 end 节点
# 40301 ErrPermissionDenied              权限不足
# 40302 ErrTenantMismatch                租户不匹配
# 40320 ErrWorkspaceMismatch             agent 不属于 workspace
# 40321 ErrVersionAgentMismatch          version 不属于 agent
# 40401 ErrNotFound                      实体不存在
# 40420 ErrAgentNotFound                 agent 不存在
# 40421 ErrWorkspaceNotFound             workspace 不存在
# 40422 ErrVersionNotFound               agent version 不存在
# 40430 ErrWorkflowNotFound              workflow 不存在
# 40431 ErrWorkflowVersionNotFound       workflow version 不存在
# 40901 ErrVersionConflict               乐观锁冲突
# 40920 ErrSlugConflict                  slug 在 workspace 已被占用
# 40921 ErrDuplicateAgentCode            agent code 已存在
# 40922 ErrAgentArchived                 agent 已归档
# 40923 ErrInvalidStatusTransition       状态转换非法
# 40924 ErrVersionImmutable              已发布版本不可变
# 40925 ErrVersionNumberConflict         version 并发 insert 冲突
# 40926 ErrRollbackTargetInvalid         rollback target 必须已发布
# 40927 ErrCanaryVersionNotPublished     canary version 必须先发布
# 40928 ErrCanaryNotSet                  无 canary 配置
```
