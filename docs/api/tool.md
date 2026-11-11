# Tool BC API 参考

> 设计:`internal/tool/api.go` + `port/http/`
> 三层防线:`docs/architecture/tool/three-layer-defense.md`

所有路径前缀 `/v1`,全 JWT 鉴权(无公开路径)。

## Marketplace + Tool Definition

### GET /v1/marketplace/tools
列 marketplace 工具(平台 + 当前 tenant 自研)。

Query:
- `kind` — `function` / `http` / `sandbox`
- `category` — `data` / `code` / `communication` / `productivity` / `creative` / ...
- `author_type` — `system` / `platform` / `community`
- `status` — `active` / `draft` / `archived`(默认 `active`)
- `limit`(1-200,默认 50)/ `offset`

返:
```json
{
  "items": [
    {
      "tool_id": 1,
      "bid": "uuid",
      "code": "calculator",
      "name": "Calculator",
      "slug": "calculator",
      "category": "productivity",
      "description": "Evaluate expressions",
      "icon_url": "...",
      "kind": "function",
      "author_type": "system",
      "latest_version_id": 10,
      "published_version_id": 10,
      "install_count": 1234,
      "status": "active"
    }
  ],
  "total": 42
}
```

平台内置工具(11 个):`calculator` / `datetime` / `text_translate` / `image_generate` / `http_request`(egress,LLM 目录默认排除)/ `seeded_draw` / `rule_table_eval` / `ephemeris_chart` / `register_character` / `delegate_to_agent`(E4 子代理委派 —— 真实执行在 Runtime worker,Tool BC 内仅防御桩,直调 ExecuteTool 返 blocked `runtime_dispatch_only`)/ `code_interpreter`(R5-W6 沙箱代码执行:python/javascript 白名单,一次性隔离沙箱,无网络;**开闸三步** = `cmd/e2bprobe` 探针存档 → 校准 adapter → `E2B_API_KEY` + `tool.sandbox.enabled: true`;未开闸调用确定性 blocked `sandbox_unavailable`;执行审计恒落 `tool_sandbox_sessions`)。

### POST /v1/tools
注册工具(community / platform)。

```json
{
  "code": "my_search_tool",
  "name": "My Search Tool",
  "slug": "my-search",
  "category": "data",
  "description": "...",
  "icon_url": "...",
  "kind": "http",
  "author_type": "community",
  "actor_account_id": 0           // 由 JWT 注入
}
```

`code` 在 tenant 内唯一(平台级 tenant_id=0)。返 `ToolDefinitionDTO`。

### GET /v1/tools/:bid
取工具详情。

## Versions(版本管理)

### POST /v1/tools/:bid/versions
创建工具版本(从 draft 快照 + 提交审核)。

```json
{
  "schema": { ... },                  // JSON Schema for tool input params
  "config_schema": { ... },           // 安装时填的配置项 schema (API key 等)
  "capability_flags": ["network", "filesystem"],   // Layer 1 声明式能力
  "allowed_domains": ["api.example.com"],          // HTTP 工具用
  "resource_limits": { "cpu_ms": 1000, "mem_mb": 128 },  // 沙箱 cap
  "pricing_cents_per_call": 1,        // 0 = 免费
  "release_notes": "v1.2 改进..."
}
```

行为:
- 版本号 max+1 单调
- `review_status: pending_review` 入审核队列
- 平台级工具(`tenant_id=0`)由 admin 调 `/v1/versions/:bid/review` 审核
- approved 后可被 install

返 `ToolVersionDTO`。

### POST /v1/versions/:bid/review
审核工具版本(admin 操作)。

```json
{
  "decision": "approved",          // approved / rejected
  "comment": "..."
}
```

行为:
- approved → 落 `tool_versions.review_status='approved'` + `reviewed_at` + `reviewed_by_account_id`
- 写 `tool_marketplace_reviews` 行(P2-01 Phase E1.3 已建表)
- approved 版本的 `tool_definitions.published_version_id / latest_version_id` 自动更新

## Installations(workspace 级安装)

### POST /v1/workspaces/:ws_bid/installations
安装工具到 workspace。

```json
{
  "tool_bid": "...",
  "tool_version_id": 10,           // 必须 review_status=approved
  "config_values": {                // 由 tool_version.config_schema 校验
    "api_key": "sk-...",
    "endpoint": "https://api.example.com"
  }
}
```

行为:
- `config_values` 经 `ConfigCipher` AES-256-GCM 加密 → `tool_installations.config_cipher bytea`
- 高权限工具(`capability_flags` 含 `filesystem` / `shell` 等)`install_status: pending_approval` 待 owner/admin 二次审批
- 普通工具直接 `active`

返 `ToolInstallationDTO`。

### GET /v1/workspaces/:ws_bid/installations
列 workspace 已装工具。

Query:`enabled`(true/false)/ `install_status`(active / pending_approval / disabled)/ `limit/offset`。

### GET /v1/installations/:bid
取 installation 详情。`config_values` 不返(仅返字段名)。

### PATCH /v1/installations/:bid
更新 installation 配置。

```json
{
  "config_values": { ... },
  "enabled": true
}
```

config 重新加密;触发 `tool.installation_config_updated` Outbox 事件。

### DELETE /v1/installations/:bid
卸载(软删 `deleted_at`)。Run 中工具仍能完成(读 cipher 时已加载),后续 Run 不可见。

### POST /v1/tools/execute
**Admin / debug** — 直接执行工具(Runtime worker 走 `ToolPort` 不走此路径)。

```json
{
  "workspace_id": 10,
  "tool_code": "calculator",
  "call_id": "test-1",
  "tool_call_bid": "uuid",
  "input": { "expression": "1+1" },
  "end_user_account_id": 0
}
```

返 `ExecuteToolResponse`:
```json
{
  "output": { "result": 2 },
  "status": "succeeded",        // succeeded / failed / blocked / timeout
  "cost_cents": 1,
  "duration_ms": 12,
  "blocked_reason": "",
  "error_message": ""
}
```

**`blocked_reason` 词表(计费相关,2026-08-17 整改后)**

| 值 | 含义 | 用户能否自助 |
|---|---|---|
| `billing_unconfigured` | 付费工具的计费前置不就绪:缺可计费账号 / wallet 未接线 / **app 计费维度未解析** | 否(服务端配置问题) |
| `budget_exceeded` | 可用余额不足(**含钱包尚未创建** —— 个人钱包懒创建,唯一创建入口是充值到账) | 能,去充值 |
| `wallet_unavailable` | 钱包被风控停用,或钱包服务故障 | 否,需联系支持 |

> `budget_exceeded` 与 `wallet_unavailable` 此前合并为前者 —— 被风控冻结的账号会被提示
> "预算超限"去充值,充了依然用不了。现按成因分流(哨兵由 bootstrap 桥翻译,Tool BC 不
> import wallet domain)。
>
> `error_message` 只放固定英文语义,**不含**任何内部 ID 或原始错误链(红线见
> [error-codes.md](error-codes.md#响应内容红线内部-int64-绝不出现在对外文案2026-08-17-审计));
> 排障看服务端日志。

## Module API(跨 BC)

`tool.ToolAPI` 主入口给 Runtime BC:

```go
ExecuteTool(ctx, *ExecuteToolRequest) (*ExecuteToolResponse, error)
```

由 `internal/bootstrap/bridges.go::runtimeToolPortBridge` 适配为 `runtimePort.ToolPort.Execute`。

Workflow `tool` 节点 / Agent ReAct/PlanExecute Executor 走 ToolPort,Runtime 内部不直接 import Tool BC。

### 统一工具注册表(ADR-012 Phase A,2026-07-05)

```go
// 面向 LLM 规划/function-calling 的目录导出 (active 定义 × approved published 版本;
// egress 分级默认排除, IncludeEgress 显式纳入)。
ListLLMToolCatalog(ctx, *ListLLMToolCatalogRequest) (*ListLLMToolCatalogResponse, error)

// 平台既有能力幂等登记 (tool builtin 静态清单 + capability executor 经
// CapabilityCatalogPort, 按 app/service/catalog_taxonomy.go 允许清单分级)。
// worker 启动期经 config `tool.catalog_sync_enabled` 触发 (默认关); 无 /admin HTTP 端点。
SyncBuiltinCatalog(ctx) (*SyncBuiltinCatalogResult, error)
```

注册表五维分级(对齐云工作台工具调度规格 §3):`family`(定义级)+ `side_effect / cost_model / execution / output_schema`(版本级)。迁移 `docs/migrations/20260705_tool_registry_unification.sql`(expand-only);`runtime_type` 增值 `capability`(执行收敛留 M4-2,当前登记+导出用)。**计价语义注**:`pricing_cents_per_call` 字段名带 cents,但计费链原值传 `wallet.Freeze` —— 事实语义 = 积分/次(历史命名债)。

## 三层防线(brief 红线)

每次 `ExecuteTool` 调用经过:

1. **Layer 1 — Capability**:`PermissionChecker.Require(ctx, actorID, orgID, "tool:invoke")`;`tool_version.capability_flags` 声明式校验
2. **Layer 2 — Sandbox**:HTTP 工具走 `SafeFetcher`(11 段 blocked CIDR + DNS pin + redirect 重 validate);DB 工具走 `SQLValidator`(pg_query_go AST,拒非 SELECT);Code 工具走 sandbox(P2-01 后续 E2B 实装)
3. **Layer 3 — Guardrail**:输入 prompt injection 检测(rule-based,76% red-team coverage);输出凭证 redact(13 pattern,JWT/sk-/AKIA/ghp 等)

详见 `docs/architecture/tool/three-layer-defense.md`。

## 数据模型

| 表 | 主键 | 说明 |
|---|---|---|
| `tool_definitions` | id, (tenant_id, code) UNIQUE | 工具定义聚合根 |
| `tool_versions` | id, (tool_id, version_number) UNIQUE | 不可变版本 + 审核 |
| `tool_installations` | id, (workspace_id, tool_id) UNIQUE | workspace 级安装(覆盖式更新) |
| `tool_sandbox_sessions` | id | 沙箱执行审计(分区表) |
| `tool_db_connections` | id, tool_installation_id UNIQUE | runtime_type=db 工具的连接条目(P2-01 Phase E1.3 表已建,sql_query builtin 接入留 P2-01 后续) |
| `tool_marketplace_reviews` | id | 版本审核历史(P2-01 Phase E1.3) |

## IAM 权限(P2-01 Phase C-5 注册 9 个)

- `tool:list_marketplace` / `tool:create` / `tool:update`
- `tool:install` / `tool:uninstall` / `tool:configure`
- `tool:invoke`
- `tool:approve_review`(admin)
- `tool:audit_logs`

## 错误码段

详见 `internal/tool/port/http/errors.go`。Workflow http SSRF 红线 #14 错误段(40050-40062 + 40430/40431)与 Catalog 共享。

## 起跳点

- E2B 真沙箱接入(P2-01 后续)
- LLM Guardrail E-2 实装(Provider GuardrailLLMCaller bypass SemanticCache)
- sql_query builtin + tool_db_connections 真连接
- Tool 计费 batch 优化(目前每 ExecuteTool 单独 Freeze/Confirm)

## OpenAPI 3.1 Specification

> 基于代码事实生成。来源:`internal/tool/port/http/{routes,tool_handler,installation_handler,errors}.go` + `tool/api.go` (DTO) + `domain/valueobject/{tool_kind,review_status,install_status,capability}.go`。
>
> 公共契约见 [overview.md](overview.md)。所有错误返 HTTP 200 + 业务码(`mapDomainErr`)。

```yaml
openapi: 3.1.0
info:
  title: AIGC Platform — Tool Domain API
  description: |
    Tool BC 11 endpoints:
      - Marketplace: list / register / get / create-version / review
      - Installation: install / list / get / update-config / uninstall
      - Execute (admin debug, runtime worker 走 ToolPort 不走 HTTP)
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

    ToolDefinitionDTO:
      type: object
      required: [tool_id, bid, code, name, kind, author_type, status]
      properties:
        tool_id: { type: integer, format: int64 }
        bid: { type: string, format: uuid }
        tenant_id: { type: integer, format: int64, description: 0 = 平台级 }
        code: { type: string, description: snake_case, 2-64 字符 }
        name: { type: string }
        slug: { type: string }
        category: { type: string }
        description: { type: string }
        icon_url: { type: string, format: uri }
        kind:
          type: string
          enum: [function, http, sandbox]
        author_type:
          type: string
          enum: [system, platform, community]
        latest_version_id: { type: integer, format: int64, nullable: true }
        published_version_id: { type: integer, format: int64, nullable: true }
        install_count: { type: integer, format: int64 }
        status:
          type: string
          enum: [draft, active, archived]
        created_at: { type: integer, format: int64 }
        updated_at: { type: integer, format: int64 }

    ToolVersionDTO:
      type: object
      required: [version_id, bid, tool_id, version_number, runtime_type, review_status]
      properties:
        version_id: { type: integer, format: int64 }
        bid: { type: string, format: uuid }
        tool_id: { type: integer, format: int64 }
        version_number: { type: integer }
        runtime_type:
          type: string
          enum: [builtin, http, code, db]
        schema:
          type: object
          additionalProperties: true
          description: 工具输入参数 JSON Schema
        config_schema:
          type: object
          additionalProperties: true
          description: 安装配置 JSON Schema (API key 等)
        capability_flags:
          type: array
          description: Layer 1 声明式能力 ([]string, 非 jsonb)
          items:
            type: string
            enum: [network, filesystem, database, shell]
        allowed_domains:
          type: array
          items: { type: string }
          description: HTTP 工具的出站白名单 (仅 kind=http)
        pricing_cents_per_call: { type: integer, format: int64, description: 0 = 免费 }
        review_status:
          type: string
          enum: [pending_review, approved, rejected]
        review_notes: { type: string }
        release_notes: { type: string }
        created_at: { type: integer, format: int64 }

    ToolInstallationDTO:
      type: object
      required: [installation_id, bid, workspace_id, tool_id, tool_version_id, enabled, install_status]
      properties:
        installation_id: { type: integer, format: int64 }
        bid: { type: string, format: uuid }
        workspace_id: { type: integer, format: int64 }
        tool_id: { type: integer, format: int64 }
        tool_version_id: { type: integer, format: int64 }
        enabled: { type: boolean }
        has_config:
          type: boolean
          description: 不回传密文 config_values, 仅标记是否已配置
        installed_by_account_id: { type: integer, format: int64, nullable: true }
        installed_at: { type: integer, format: int64, nullable: true }
        install_status:
          type: string
          enum: [pending_approval, active, disabled]
        created_at: { type: integer, format: int64 }
        updated_at: { type: integer, format: int64 }

    RegisterToolRequest:
      type: object
      required: [code, name]
      properties:
        tenant_id: { type: integer, format: int64, description: 0 = 平台 (上层鉴权) }
        code: { type: string, description: snake_case, 2-64 字符 }
        name: { type: string }
        slug: { type: string }
        category: { type: string }
        description: { type: string }
        icon_url: { type: string, format: uri }
        kind:
          type: string
          enum: [function, http, sandbox]
          default: function
        author_type:
          type: string
          enum: [system, platform, community]
          default: community

    CreateVersionRequest:
      type: object
      properties:
        runtime_type:
          type: string
          enum: [builtin, http, code, db]
          default: builtin
        schema: { type: object, additionalProperties: true }
        config_schema: { type: object, additionalProperties: true }
        capability_flags:
          type: array
          items: { type: string, enum: [network, filesystem, database, shell] }
        allowed_domains:
          type: array
          items: { type: string }
        cpu_ms: { type: integer, description: CPU 上限 (毫秒) }
        mem_mb: { type: integer, description: 内存上限 (MB) }
        duration_ms: { type: integer, description: 执行超时 (毫秒) }
        pricing_cents_per_call: { type: integer, format: int64 }
        release_notes: { type: string }

    ReviewVersionRequest:
      type: object
      required: [decision]
      properties:
        decision:
          type: string
          enum: [approve, reject]
        review_notes:
          type: string
          description: 拒绝时必填 (40065 ErrReviewNotesRequired)

    InstallToolRequest:
      type: object
      required: [tool_bid]
      properties:
        tool_bid: { type: string, format: uuid }
        version_bid:
          type: string
          format: uuid
          description: 未指定则用 latest approved
        config_values:
          type: object
          additionalProperties: true
          description: 安装配置值, 须符合 version.config_schema

    UpdateInstallationConfigRequest:
      type: object
      required: [config_values]
      properties:
        config_values:
          type: object
          additionalProperties: true

    ExecuteToolRequest:
      type: object
      required: [workspace_id, tool_code]
      properties:
        workspace_id: { type: integer, format: int64 }
        tool_code: { type: string }
        input:
          type: object
          additionalProperties: true

    ExecuteToolResponse:
      type: object
      required: [status]
      properties:
        output:
          type: object
          additionalProperties: true
        status:
          type: string
          enum: [succeeded, failed, blocked, timeout]
        cost_cents: { type: integer, format: int64 }
        duration_ms: { type: integer }
        blocked_reason: { type: string, description: status=blocked 时填(三层防线哪层拦截) }
        error_message: { type: string }

paths:
  /marketplace/tools:
    get:
      summary: 列 marketplace 工具
      operationId: listMarketplaceTools
      tags: [Tool]
      parameters:
        - { name: tenant_id, in: query, schema: { type: integer, format: int64 } }
        - { name: category, in: query, schema: { type: string } }
        - { name: status, in: query, schema: { type: string, enum: [draft, active, archived] } }
        - { name: kind, in: query, schema: { type: string, enum: [function, http, sandbox] } }
        - { name: limit, in: query, schema: { type: integer, default: 50, maximum: 200 } }
        - { name: offset, in: query, schema: { type: integer, default: 0 } }
      responses:
        '200':
          description: 工具列表
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
                            items: { $ref: '#/components/schemas/ToolDefinitionDTO' }
                          total: { type: integer }

  /tools:
    post:
      summary: 注册工具 (commmunity / platform)
      operationId: registerTool
      tags: [Tool]
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/RegisterToolRequest' }
      responses:
        '200':
          description: 注册成功
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/ToolDefinitionDTO' }

  /tools/{bid}:
    get:
      summary: 取工具详情
      operationId: getTool
      tags: [Tool]
      parameters:
        - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
      responses:
        '200':
          description: 工具详情
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/ToolDefinitionDTO' }

  /tools/{bid}/versions:
    post:
      summary: 创建工具版本 (提交审核)
      operationId: createToolVersion
      tags: [Tool]
      parameters:
        - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/CreateVersionRequest' }
      responses:
        '200':
          description: 版本已创建 (review_status=pending_review)
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/ToolVersionDTO' }

  /versions/{bid}/review:
    post:
      summary: 审核工具版本 (admin 操作)
      operationId: reviewToolVersion
      tags: [Tool]
      parameters:
        - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/ReviewVersionRequest' }
      responses:
        '200':
          description: 审核完成 (review_status 变更为 approved / rejected)
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/ToolVersionDTO' }

  /workspaces/{ws_bid}/installations:
    parameters:
      - { name: ws_bid, in: path, required: true, schema: { type: string, format: uuid } }
    post:
      summary: 安装工具到 workspace
      operationId: installTool
      tags: [Installation]
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/InstallToolRequest' }
      responses:
        '200':
          description: 安装成功
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/ToolInstallationDTO' }
    get:
      summary: 列 workspace 已装工具
      operationId: listInstallations
      tags: [Installation]
      parameters:
        - { name: workspace_id, in: query, schema: { type: integer, format: int64 } }
        - { name: enabled, in: query, schema: { type: boolean } }
        - { name: limit, in: query, schema: { type: integer, default: 50, maximum: 200 } }
        - { name: offset, in: query, schema: { type: integer, default: 0 } }
      responses:
        '200':
          description: 已装列表
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
                            items: { $ref: '#/components/schemas/ToolInstallationDTO' }
                          total: { type: integer }

  /installations/{bid}:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
    get:
      summary: 取 installation 详情 (config 不回传)
      operationId: getInstallation
      tags: [Installation]
      responses:
        '200':
          description: installation 详情
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/ToolInstallationDTO' }
    patch:
      summary: 更新 installation 配置
      operationId: updateInstallationConfig
      tags: [Installation]
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/UpdateInstallationConfigRequest' }
      responses:
        '200':
          description: 更新成功 (config 重新加密 + 触发 outbox)
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/ToolInstallationDTO' }
    delete:
      summary: 卸载 (软删 deleted_at)
      operationId: uninstallTool
      tags: [Installation]
      responses:
        '200':
          description: "卸载成功 (data: null)"
          content:
            application/json:
              schema: { $ref: '#/components/schemas/StandardResponse' }

  /tools/execute:
    post:
      summary: Admin / debug — 直接执行工具
      operationId: executeTool
      tags: [Installation]
      description: |
        Runtime worker 走 ToolPort (内部 RPC) 不走此 HTTP 端点.
        本端点用于 admin 调试 / 验证 schema.
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/ExecuteToolRequest' }
      responses:
        '200':
          description: "执行结果 (status: succeeded / failed / blocked / timeout)"
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/ExecuteToolResponse' }

# 错误码段 (来源 internal/tool/port/http/errors.go::mapDomainErr L20-90)
# 全部返 HTTP 200 + 业务码 (overview.md §6.3 设计约定)
#
# 40030 通用 BindAndValidate 失败
# 40060 ErrToolCodeInvalid              tool code 格式无效
# 40061 ErrToolSlugInvalid              tool slug 格式无效
# 40062 ErrToolDefinitionInvalid        工具定义无效
# 40063 ErrCapabilityFlagInvalid        能力标志无效
# 40064 ErrPricingNegative              价格不能为负
# 40065 ErrReviewNotesRequired          拒绝时必须提供审核备注
# 40066 ErrInstallationInvalidConfig    安装配置 config_schema 校验失败
# 40067 ErrVersionToolMismatch          版本不属于该工具
# 40301 ErrPermissionDenied             权限不足
# 40302 ErrTenantMismatch               租户上下文不匹配
# 40401 ErrNotFound                     实体不存在
# 40440 ErrToolNotFound                 工具不存在
# 40441 ErrVersionNotFound              工具版本不存在
# 40442 ErrInstallationNotFound         安装不存在
# 40443 ErrUnknownTool                  工具无注册的执行器
# 40901 ErrVersionConflict              并发更新冲突
# 40940 ErrToolCodeConflict             tool code 已被占用
# 40941 ErrToolSlugConflict             tool slug 已被占用
# 40942 ErrToolArchived                 工具已归档
# 40943 ErrVersionNumberConflict        并发版本号冲突
# 40944 ErrVersionNotApproved           版本未审核通过
# 40945 ErrVersionAlreadyReviewed       版本已审核 (不可重复)
# 40946 ErrAlreadyInstalled             该 workspace 已安装此工具
# 40947 ErrInvalidReviewTransition      审核状态转移非法
# 40948 ErrInvalidInstallTransition     安装状态转移非法
# 40949 ErrToolDisabled                 工具安装已禁用
# 40950 ErrToolNotInstalled             工具未在 workspace 安装
# 40951 ErrToolExecutionBlocked         执行被三层防线策略阻止
# 50000 (default)                       服务内部错误
```

## 执行八步(M-E/C1 顺序契约)

工具调用的**顺序本身就是安全语义**:审批必须在一切副作用之前、互斥必须在计费之前、
输出护栏必须在落库之前。这些约束此前只活在注释里(且注释步号有重号),现由
`tests/archtest/tool_pipeline_order_test.go` 钉死——每个环节在
`execute_tool_handler.go` 用 `[step:N ...]` 标记登记,测试要求标记按 N 单调不减出现。

| 步 | 名称 | 归属 | 说明 |
|---|---|---|---|
| 1 | 解析准入 | Tool BC | 工具→安装→版本三步(`ToolAccessResolver`,与只读预检共享实现) |
| 2 | 权限判定 | **调用方(Runtime)** | Tool BC **不重做** ——重做会造出第二套授权语义,且两处判定必然漂移。守卫用反向断言钉:执行链出现 `PermissionChecker` 即红 |
| 3 | 审批拦截 | Tool BC | `side_effect.RequiresConfirmation() ∧ 无票据` → `blocked(approval_required)`,零计费副作用 |
| 4 | 冲突键排队 | Tool BC | 声明了 `conflict_key_template` 的工具按渲染后的资源键取互斥租约;**非阻塞**——抢不到回 `blocked(resource_busy)` 让模型改做别的,而不是拿着 goroutine 等锁 |
| 5 | 配额闸 | **席位(未实装)** | 见下「为什么没有 tool 侧配额」 |
| 6 | 执行 | Tool BC | 6a 解密 config → 6b 输入护栏 → 6c executor 查找 → 6d 计费前置(fail-close)→ 6e Freeze → 6f 上游调用(hook 五时机) |
| 7 | 结果规整 | Tool BC | status 语义判定 + 输出护栏(凭证脱敏) |
| 8 | 落库 | Tool BC | 钱包结算 + outbox 事件(幂等键 = tool_call_bid) |

### 效果声明(并发与失败时怎么办)

`tool_versions` 三列,与 `side_effect` 分工明确——那一维是**策略**输入(要不要人工确认),
这三项是**机制**输入(锁谁 / 怎么去重 / 怎么回滚):

| 列 | 语义 | 空值含义 |
|---|---|---|
| `conflict_key_template` | 资源互斥键模板,如 `asset:{asset_bid}` | 不参与互斥 |
| `idempotency_key_template` | 外部调用幂等键模板 | 提交五态 `unknown` 后不可安全重放(只能转人工) |
| `compensation_ref` | 补偿工具 code | 不可补偿 |

**注册期强制**(`ValidateEffectDeclaration`):`irreversible` ⇒ 必须声明冲突键;
`irreversible`/`egress` ⇒ 必须声明幂等键;模板占位符必须存在于入参 schema。
空冲突键**不**按"保守默认 exclusive"处理——那会退化成按 `tool_code` 串行(把同一
工具的全部调用排成一队);安全性改由注册期强制保证,于是危险类恒有互斥、无害类不付代价。

**锁服务故障/未接线的分面处置**:`irreversible`/`egress` → fail-close(宁可拒绝也不
并发跑不可逆动作);其余 → fail-open(锁服务故障不该挡住可重做的工作)。两者都落日志——
静默的 fail-open 与静默的 fail-close 一样危险。

### 为什么没有 tool 侧配额(步 5 席位)

原设计想给 tool 补 per-run / per-conversation 配额,并预期"`cap_quotas` 加行不加表"。
实施期侦察否定了这条路:`cap_quotas` 的 scope 是 `(tenant, capability, pricing_tier)`
三元组,**没有 run/conversation/workspace 维度**,要支持得扩维——那就是在 F5 配额家族里
再造一套方言。

而且这一层的约束**已由调用方承担**:工具扇出上限(`maxConcurrentTools=8`)、ReAct 迭代
上限、run 级预算信封、共享 AttemptBudget(M-A)四重。再加一层 tool 侧计数,是在已有约束
之上叠一个口径不同的第五重。故登记为席位:确有需求时(如按租户售卖工具调用包)一并
决定是扩 `cap_quotas` 维度还是建 tool 侧配额表,不在此提前造。
