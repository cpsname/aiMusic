# Tenancy BC API 参考

> 设计:`internal/tenancy/api.go` + `internal/tenancy/port/http/`
> 锁定决策见 `memory/p0_01_design_decisions.md`
> 真实 RLS 双租户隔离已端到端验证(见 CLAUDE.md Tenancy BC 段)

Tenancy BC 是 Agent 平台多租户根基:`tenant_id = organization.id`。所有 BC 数据靠 RLS POLICY + `SetTenantOnTx` 在 SQL 事务起始处绑定 GUC 隔离。

路径前缀 `/v1`。除 `GET /invitations/:token` 外全 JWT 鉴权。

## Organization

### POST /v1/orgs
创建组织(原子写 3 聚合 + 1 Outbox 事件)。

```json
{
  "name": "Acme Corp",
  "slug": "acme-corp",
  "default_workspace_name": "Acme Default"
}
```

行为(同一事务):
1. INSERT `ten_organizations` (tenant_id=0 占位)
2. UPDATE org 设 `tenant_id = id`(自绑)
3. INSERT default `ten_workspaces` (`is_default=true`,组织内唯一)
4. INSERT owner `ten_memberships` (`status=active`, `role_bid=<owner builtin uuid>`)
5. Outbox `tenancy.organization_created`

返:
```json
{
  "organization": { "bid": "...", "tenant_id": 42, "name": "...", "slug": "...", "isolation_level": "l1", ... },
  "default_workspace": { "bid": "...", "is_default": true, ... },
  "owner_membership": { "bid": "...", "role_code": "owner", "status": "active" }
}
```

### GET /v1/orgs
列当前账号的所有组织(按 active membership 过滤)。

Query: `limit`(1-200,默认 50)/ `offset`。

### GET /v1/orgs/:bid
取详情。仅活跃成员可见(否则 403)。

### PATCH /v1/orgs/:bid
更新 metadata:`name` / `slug` / `sso_config` / `compliance_config`。乐观锁 `version`。

```json
{
  "name": "Acme Corporation",
  "sso_config": { "provider": "oidc", "issuer": "https://sso.acme.example.com" }
}
```

> 注:`isolation_level` 走单独审批流(见下),不能在此直接改。

### DELETE /v1/orgs/:bid
软删组织 + 级联软删 5 张表(workspaces / memberships / invitations / isolation_requests + Org 自身)+ Outbox `tenancy.organization_deleted`。

下游 BC 订阅此事件级联清自家资源(目前 Catalog/Runtime 已订阅 `RuntimeEventConsumer`)。

仅 owner 可删。

## Workspace

### POST /v1/orgs/:bid/workspaces
创建非 default workspace。

```json
{
  "slug": "dev-env",
  "name": "Development Environment"
}
```

`slug` 在组织内唯一。返 `WorkspaceDTO`。

### GET /v1/orgs/:bid/workspaces
列组织下所有 workspace(default 排前)。

### DELETE /v1/workspaces/:bid
软删 workspace。**default workspace 禁删**(返 4xx)。

### Module API: GetWorkspaceByBID(ctx, wsBID)
跨 BC 调用(Catalog/Runtime 等用 ws_bid 解析 → org_id + tenant_id)。

## Invitation

邮件投递 = 只发 Outbox `tenancy.invitation_created`(含明文 token),无 SMTP infra;真实 email 投递由未来 notification BC 消费。

### POST /v1/orgs/:bid/invitations
创建邀请(email 单次 / link 多次)。

```json
{
  "invite_type": "email",          // email | link
  "email": "newbie@acme.example.com",
  "target_role_code": "member",     // owner / admin / member / viewer
  "max_uses": 1,                    // email 固定 1, link 可大
  "expires_in_sec": 604800
}
```

返 `InvitationDTO`(含 `token`,32 字节 base64url)。

### GET /v1/invitations/:token
**公开**(无需 auth)— 受邀人点链接看邀请元数据。

返:
```json
{
  "bid": "...",
  "org_name": "Acme Corp",
  "inviter_nickname": "Alice",
  "target_role_code": "member",
  "expires_at": "2026-05-05T..."
}
```

### POST /v1/invitations/:token/accept
受邀人接受(JWT)→ 创建活跃 membership。

行为:
- 幂等:`(org_id, account_id) WHERE deleted_at IS NULL AND status<>'removed'` UNIQUE 兜底
- 写 Outbox `tenancy.invitation_accepted` + `tenancy.membership_status_changed`

> RLS 语义:受邀人尚未归属目标 org,handler 调用时**不**SET GUC,依赖 POLICY"GUC 未设置 bypass"分支。P1 HTTP 中间件若自动 SET GUC 需豁免此路径。

### POST /v1/invitations/:token/revoke
创建者(或 admin/owner)撤销邀请。token 立即失效。

## Membership

### GET /v1/orgs/:bid/members
列组织成员。Query:`limit` / `offset` / `include_removed`(默认 false)。

返:
```json
{
  "items": [
    { "bid": "...", "account_bid": "...", "nickname": "Alice", "role_code": "owner", "status": "active", "joined_at": "..." }
  ]
}
```

### PATCH /v1/orgs/:bid/members/:member_bid
状态机切换:`pending_invite → active → suspended → removed`。

```json
{
  "target_status": "suspended",     // pending_invite / active / suspended / removed
  "trigger": "admin_suspend"        // self_leave / admin_suspend / admin_remove / reactivate / ...
}
```

业务规则(`domain/valueobject/membership_status.go`):
- 状态机校验:from/to 合法组合(如 `removed → active` 拒)
- **最后一个 active owner 保护**:删/降级 owner 前 `CountActiveOwners` 必须 ≥ 2,否则返 `ErrCannotRemoveLastOwner`
- 不能改自己的 status(用专门"主动退组"路径)

写 Outbox `tenancy.membership_status_changed`。

## Isolation Level 审批流

`organization.isolation_level` 枚举(`l1 / l2 / l3`),不做物理迁移,仅存枚举 + 审批状态机。

### POST /v1/orgs/:bid/isolation-level
申请变更(member+ 可发起)。

```json
{
  "to_level": "l2",
  "notes": "流量上来了, 申请独占 schema"
}
```

行为:
- 创建 `ten_isolation_level_change_requests` 行,`state=requested`
- Outbox `tenancy.isolation_level_change_requested`
- 同 org 同时只能有一个 pending 请求(否则 4xx)

### PATCH /v1/orgs/:bid/isolation-level/:req_bid
平台 admin 审批。

```json
{
  "decision": "approve",            // approve | reject
  "notes": "LGTM - 运维排期下周"
}
```

行为:
- approve → state=`approved` + 改 `organization.isolation_level`(标志位,真实迁移由 P2+ 运维工具消费)
- reject → state=`rejected`,不改 org
- Outbox `tenancy.isolation_level_change_reviewed`

> `executing/completed/failed` 状态留 P2+(运维工具触发实际迁移流水线时再用)。

## Module API(跨 BC)

`tenancy.TenancyAPI` 给 Catalog/Runtime/Knowledge 等用。轻量便捷方法:

```go
// 组织/workspace 解析
GetWorkspaceByBID(ctx, wsBID) (*WorkspaceDTO, error)
ResolveActiveMembership(ctx, accountID, orgID) (*MembershipDTO, error)

// 权限便利
IsMember(ctx, accountID, orgID) (bool, error)
GetMemberRole(ctx, accountID, orgID) (string, error)              // 非成员返 ""
AuthorizeWorkspaceAccess(ctx, accountID, wsID, action) (bool, error)
```

`AuthorizeWorkspaceAccess` 当前仅做"是否成员 + role_code 查询",细粒度判决在调用方 BC 的 PermissionChecker。P0-03 IAM Casbin 上线后内部升级为走 PolicyEngine。

## Outbox 事件清单(8 种)

| Event | Aggregate | Payload 关键字段 |
|---|---|---|
| `tenancy.organization_created` | org_bid | tenant_id / owner_account_id / default_workspace_bid |
| `tenancy.organization_deleted` | org_bid | tenant_id / deleter_account_id |
| `tenancy.workspace_created` | workspace_bid | org_bid / is_default |
| `tenancy.invitation_created` | invitation_bid | org_bid / email / target_role_code / token / expires_at |
| `tenancy.invitation_accepted` | invitation_bid | acceptor_account_id / membership_bid |
| `tenancy.membership_status_changed` | membership_bid | from_status / to_status / trigger |
| `tenancy.isolation_level_change_requested` | request_bid | from_level / to_level / requester_id |
| `tenancy.isolation_level_change_reviewed` | request_bid | decision / reviewer_id |

详见 `internal/tenancy/app/events/events.go`。所有 idempotency_key 复合 `<aggregate_bid>:<action>:<n>`。

## 数据模型

| 表 | 主键 | 关键约束 |
|---|---|---|
| `ten_organizations` | id, bid UNIQUE | tenant_id=id 自绑;5 mixin |
| `ten_workspaces` | id, (tenant_id, slug) UNIQUE WHERE deleted_at IS NULL | `(org_id) WHERE is_default=true` UNIQUE |
| `ten_memberships` | id, (org_id, account_id) UNIQUE WHERE not removed | role_bid 软引用 iam_roles |
| `ten_invitations` | id, token UNIQUE | (org_id, email) WHERE pending UNIQUE(防重复) |
| `ten_isolation_level_change_requests` | id | (org_id) WHERE state IN (requested,executing) UNIQUE |

全部启用 RLS:
- USING:`tenant_id = GUC OR tenant_id=0 OR GUC 未设置`
- WITH CHECK:`tenant_id = GUC OR GUC 未设置`(**不含** `OR tenant_id=0`)

## 4 个内置角色

`internal/tenancy/domain/service/builtin_roles.go` 硬编码 4 个 UUID(由 P0-02 migration seed 到 `iam_roles`):

| role_code | 默认权限范围 |
|---|---|
| `owner` | 全部(改组织 + 删组织 + 改成员 + 审批)|
| `admin` | 改组织 metadata + 改成员 + 装工具 + 改 Agent published(不删组织)|
| `member` | 改 draft + 调用工具 + 触发 Run |
| `viewer` | 只读 |

> P0-03 IAM Casbin 上线后,可加自定义 role(继承 4 个内置之一)。

## 错误码段(典型)

| Code | 含义 |
|---|---|
| `40301` | 不是组织成员 |
| `40331` | 角色权限不足 |
| `40404` | org / workspace / membership / invitation 不存在 |
| `40901` | 乐观锁冲突(并发改 org)|
| `40920` | last active owner 保护 |
| `40921` | default workspace 禁删 |
| `40922` | 邀请已被使用 / 已过期 / 已撤销 |
| `40923` | 同 org 已有 pending isolation 请求 |

详见 `internal/tenancy/domain/errors.go`。

## RLS 端到端验证(已通过)

Docker PG 18.3 实测:
- tenant=1 session 只见 Alpha 行 / tenant=2 session 只见 Beta 行
- 跨租户 INSERT 被 WITH CHECK 拦截
- 伪造 `tenant_id=0` 平台行被拦截(只有 superuser/migration 能写)
- superuser + 无 GUC bypass 看全部(用于运维)

`internal/platform/postgres.SetTenantOnTx(ctx, tx, tenantID)` 在事务起始处 `SET LOCAL app.current_tenant_id`,tx 结束自动失效。**不**提供 ClearTenantOnTx —— 跨租户维护必须开独立 superuser 事务。

## 起跳点

- HTTP 中间件自动 SET GUC(P1+,需豁免 invitation accept 跨边界路径)
- IAM Casbin PolicyEngine 接入 → `AuthorizeWorkspaceAccess` 升级(P0-03)
- Isolation level 真物理迁移流水线(P2+ 运维工具)
- SMTP/notification BC 消费 `tenancy.invitation_created` 真发邮件

## OpenAPI 3.1 Specification

> 基于代码事实生成。来源:`internal/tenancy/port/http/{routes,*_handler,errors}.go` + `tenancy/api.go` + `domain/{valueobject/{membership_status,invitation_status,isolation_level,isolation_change_status},service/builtin_roles}.go`。
>
> 公共契约见 [overview.md](overview.md)。

```yaml
openapi: 3.1.0
info:
  title: AIGC Platform — Tenancy Domain API
  description: |
    Tenancy BC 16 endpoints:
      - Organization CRUD (5)
      - Workspace CRUD (3)
      - Invitation 流转 (3)
      - Membership 列表 + 状态机更新 (2)
      - IsolationLevel 审批流 (2)
      - 公开邀请查询 (1)

    tenant_id = organization.id (Organization 自绑). 16 endpoints 中只 1 公开 (查邀请元数据).
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

    OrganizationDTO:
      type: object
      required: [bid, tenant_id, name, slug, status, isolation_level]
      properties:
        bid: { type: string, format: uuid }
        tenant_id: { type: integer, format: int64, description: "= organization.id (自绑)" }
        name: { type: string }
        slug: { type: string }
        status: { type: string, enum: [active, suspended, archived] }
        isolation_level: { type: string, enum: [l1, l2, l3], default: l1 }
        sso_config:
          type: object
          additionalProperties: true
        compliance_config:
          type: object
          additionalProperties: true
        created_at: { type: string, format: date-time }
        updated_at: { type: string, format: date-time }

    WorkspaceDTO:
      type: object
      required: [workspace_id, bid, tenant_id, organization_id, slug, name, is_default]
      properties:
        workspace_id: { type: integer, format: int64, description: 内部 ID, 供下游 BC 软引用 }
        bid: { type: string, format: uuid }
        tenant_id: { type: integer, format: int64 }
        organization_id: { type: integer, format: int64 }
        slug: { type: string }
        name: { type: string }
        is_default: { type: boolean }
        created_at: { type: string, format: date-time }
        updated_at: { type: string, format: date-time }

    MembershipDTO:
      type: object
      required: [bid, tenant_id, organization_id, account_id, role_bid, status]
      properties:
        bid: { type: string, format: uuid }
        tenant_id: { type: integer, format: int64 }
        organization_id: { type: integer, format: int64 }
        account_id: { type: integer, format: int64 }
        role_bid: { type: string, format: uuid, description: 软引用 iam_roles.bid }
        role_code:
          type: string
          enum: [owner, admin, member, viewer]
          description: 4 内置角色 (api_local 反查填充)
        status:
          type: string
          enum: [pending_invite, active, suspended, removed]
        invited_at: { type: string, format: date-time }
        joined_at: { type: string, format: date-time, nullable: true }
        created_at: { type: string, format: date-time }
        updated_at: { type: string, format: date-time }

    InvitationDTO:
      type: object
      required: [bid, organization_id, token, invite_type, target_role_bid, status, max_uses, use_count, expires_at]
      properties:
        bid: { type: string, format: uuid }
        tenant_id: { type: integer, format: int64 }
        organization_id: { type: integer, format: int64 }
        email: { type: string }
        token: { type: string }
        invite_type:
          type: string
          enum: [email, link, batch]
        target_role_bid: { type: string, format: uuid }
        target_role_code:
          type: string
          enum: [owner, admin, member, viewer]
        status:
          type: string
          enum: [pending, accepted, revoked, expired]
        max_uses: { type: integer }
        use_count: { type: integer }
        expires_at: { type: string, format: date-time }
        invited_by_account_id: { type: integer, format: int64 }
        created_at: { type: string, format: date-time }

    IsolationChangeRequestDTO:
      type: object
      required: [bid, tenant_id, organization_id, from_level, to_level, status, requested_by_account_id]
      properties:
        bid: { type: string, format: uuid }
        tenant_id: { type: integer, format: int64 }
        organization_id: { type: integer, format: int64 }
        from_level: { type: string, enum: [l1, l2, l3] }
        to_level: { type: string, enum: [l1, l2, l3] }
        status:
          type: string
          enum: [requested, approved, rejected, executing, completed, failed]
          description: P0-02 仅实装 requested→approved/rejected; executing/completed/failed 留 P2+
        requested_by_account_id: { type: integer, format: int64 }
        approved_by_account_id: { type: integer, format: int64, nullable: true }
        reviewed_at: { type: string, format: date-time, nullable: true }
        notes: { type: string }
        created_at: { type: string, format: date-time }

    CreateOrgRequest:
      type: object
      required: [name, slug]
      properties:
        name: { type: string }
        slug: { type: string, description: 经 ValidateSlug 校验, 不可保留字 }
        default_workspace_name: { type: string, default: "Default Workspace" }

    CreateOrganizationResponse:
      type: object
      required: [organization, default_workspace, owner_membership]
      properties:
        organization: { $ref: '#/components/schemas/OrganizationDTO' }
        default_workspace: { $ref: '#/components/schemas/WorkspaceDTO' }
        owner_membership: { $ref: '#/components/schemas/MembershipDTO' }

    UpdateOrgRequest:
      type: object
      description: 全部字段 optional, 不传不修改. isolation_level 不在此修改 (走专门审批流)
      properties:
        name: { type: string }
        slug: { type: string }
        sso_config: { type: object, additionalProperties: true }
        compliance_config: { type: object, additionalProperties: true }

    CreateWsRequest:
      type: object
      required: [slug, name]
      properties:
        slug: { type: string }
        name: { type: string }

    CreateInvRequest:
      type: object
      required: [invite_type, target_role_code]
      properties:
        invite_type: { type: string, enum: [email, link, batch] }
        email: { type: string, description: "email 类型必填" }
        target_role_code: { type: string, enum: [owner, admin, member, viewer] }
        max_uses: { type: integer, default: 1, description: "email 固定 1; link/batch 可 >1" }
        expires_in_sec: { type: integer, default: 604800, description: "默认 7 天" }

    AcceptInvitationResponse:
      type: object
      required: [invitation, new_membership, invitation_saturated]
      properties:
        invitation: { $ref: '#/components/schemas/InvitationDTO' }
        new_membership: { $ref: '#/components/schemas/MembershipDTO' }
        invitation_saturated:
          type: boolean
          description: "true = max_uses 已达到, invitation 转 accepted"

    UpdateMembershipStatusRequest:
      type: object
      required: [target_status, trigger]
      properties:
        target_status: { type: string, enum: [active, suspended, removed] }
        trigger:
          type: string
          enum: [accept_invitation, admin_revoke_invite, admin_suspend, admin_reactivate, admin_remove]
          description: 触发器, 用于状态机校验

    RequestIsolationLevelRequest:
      type: object
      required: [to_level]
      properties:
        to_level: { type: string, enum: [l1, l2, l3] }
        notes: { type: string }

    ReviewIsolationLevelRequest:
      type: object
      required: [decision]
      properties:
        decision: { type: string, enum: [approve, reject] }
        notes: { type: string }

paths:
  /invitations/{token}:
    get:
      summary: 受邀人查邀请元数据 (公开)
      operationId: getInvitationByToken
      tags: [Invitation]
      security:
        - DistributionCode: []
          Timestamp: []
          Nonce: []
          AppSignature: []
      parameters:
        - { name: token, in: path, required: true, schema: { type: string } }
      responses:
        '200':
          description: 邀请详情
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/InvitationDTO' }
        '404':
          description: token 无效 (40908) / 已过期 (40909)

  /orgs:
    post:
      summary: "创建组织 (3 聚合原子: org + default workspace + owner membership)"
      operationId: createOrganization
      tags: [Organization]
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/CreateOrgRequest' }
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
                      data: { $ref: '#/components/schemas/CreateOrganizationResponse' }
        '400':
          description: slug 无效 (40033) / slug 保留字 (40034)

    get:
      summary: 列当前账号的组织
      operationId: listOrganizations
      tags: [Organization]
      parameters:
        - { name: limit, in: query, schema: { type: integer, default: 20, maximum: 200 } }
        - { name: offset, in: query, schema: { type: integer, default: 0 } }
      responses:
        '200':
          description: 组织列表
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
                            items: { $ref: '#/components/schemas/OrganizationDTO' }
                          total: { type: integer }

  /orgs/{bid}:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
    get:
      summary: 取组织详情
      operationId: getOrganization
      tags: [Organization]
      responses:
        '200':
          description: 组织详情
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/OrganizationDTO' }
        '404':
          description: 不存在 (40401) / 跨租户 (40302)
    patch:
      summary: 更新组织 metadata
      operationId: updateOrganization
      tags: [Organization]
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/UpdateOrgRequest' }
      responses:
        '200':
          description: "更新成功 (data: null)"
          content:
            application/json:
              schema: { $ref: '#/components/schemas/StandardResponse' }
        '409':
          description: 乐观锁冲突 (40901)
    delete:
      summary: 删除组织 (级联软删 + Outbox)
      operationId: deleteOrganization
      tags: [Organization]
      description: |
        级联软删: org + workspaces + memberships + invitations + isolation_change_requests.
        发 OrganizationDeleted 事件供下游 BC (catalog/runtime) 级联清理.
      responses:
        '200':
          description: "删除成功 (data: null)"
          content:
            application/json:
              schema: { $ref: '#/components/schemas/StandardResponse' }
        '409':
          description: 已删除 (40905)

  /orgs/{bid}/workspaces:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
    post:
      summary: 创建 workspace
      operationId: createWorkspace
      tags: [Workspace]
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/CreateWsRequest' }
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
                      data: { $ref: '#/components/schemas/WorkspaceDTO' }
    get:
      summary: 列 workspace
      operationId: listWorkspaces
      tags: [Workspace]
      parameters:
        - { name: limit, in: query, schema: { type: integer, default: 20, maximum: 200 } }
        - { name: offset, in: query, schema: { type: integer, default: 0 } }
      responses:
        '200':
          description: workspace 列表
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
                            items: { $ref: '#/components/schemas/WorkspaceDTO' }
                          total: { type: integer }

  /workspaces/{bid}:
    delete:
      summary: 删除 workspace (default 禁删)
      operationId: deleteWorkspace
      tags: [Workspace]
      parameters:
        - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
      responses:
        '200':
          description: "删除成功 (data: null)"
          content:
            application/json:
              schema: { $ref: '#/components/schemas/StandardResponse' }
        '403':
          description: default workspace 禁删 (40301)

  /orgs/{bid}/invitations:
    post:
      summary: 创建邀请 (邮箱 / 链接)
      operationId: createInvitation
      tags: [Invitation]
      description: |
        token 32 字节 base64url. 邮件投递只发 Outbox tenancy.invitation_created
        (含明文 token), 真实 SMTP 由未来 notification BC 消费.
      parameters:
        - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/CreateInvRequest' }
      responses:
        '200':
          description: 邀请已创建
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/InvitationDTO' }
        '400':
          description: role_code 非法 (40035) / email 缺失 (40037) / max_uses 非法 (40038)

  /invitations/{token}/accept:
    post:
      summary: 接受邀请 (创建 active membership)
      operationId: acceptInvitation
      tags: [Invitation]
      description: |
        幂等: 同 account 已是成员返 40902. 达 max_uses 后 invitation 转 accepted.
        ★ RLS 语义: 受邀人尚未归属目标 org, handler 不 SET GUC, 走"未设置 bypass"分支.
      parameters:
        - { name: token, in: path, required: true, schema: { type: string } }
      responses:
        '200':
          description: 已加入组织
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/AcceptInvitationResponse' }
        '404':
          description: token 无效 (40908) / 已过期 (40909) / max_uses 已用尽 (40910)
        '409':
          description: 已是成员 (40902)

  /invitations/{token}/revoke:
    post:
      summary: 撤销邀请 (token 立即失效)
      operationId: revokeInvitation
      tags: [Invitation]
      parameters:
        - { name: token, in: path, required: true, schema: { type: string } }
      responses:
        '200':
          description: "撤销成功 (data: null)"
          content:
            application/json:
              schema: { $ref: '#/components/schemas/StandardResponse' }
        '404':
          description: 邀请无效 (40908)

  /orgs/{bid}/members:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
    get:
      summary: 列组织成员
      operationId: listMembers
      tags: [Membership]
      parameters:
        - { name: limit, in: query, schema: { type: integer, default: 20, maximum: 200 } }
        - { name: offset, in: query, schema: { type: integer, default: 0 } }
        - { name: include_removed, in: query, schema: { type: boolean, default: false } }
      responses:
        '200':
          description: 成员列表
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
                            items: { $ref: '#/components/schemas/MembershipDTO' }
                          total: { type: integer }

  /orgs/{bid}/members/{member_bid}:
    patch:
      summary: 更新成员状态 (状态机)
      operationId: updateMembershipStatus
      tags: [Membership]
      description: |
        状态机:
          pending_invite → active (accept_invitation) / removed (admin_revoke_invite)
          active         → suspended (admin_suspend) / removed (admin_remove)
          suspended      → active (admin_reactivate) / removed (admin_remove)
          removed        终态

        ★ 删除 owner 前强制校验 "不能移除最后一个 active owner" (40303).
      parameters:
        - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
        - { name: member_bid, in: path, required: true, schema: { type: string, format: uuid } }
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/UpdateMembershipStatusRequest' }
      responses:
        '200':
          description: "状态变更成功 (data: null)"
          content:
            application/json:
              schema: { $ref: '#/components/schemas/StandardResponse' }
        '403':
          description: 最后一个 owner 保护 (40303)
        '409':
          description: 状态转移非法 (40906) / 已终态 (40907)

  /orgs/{bid}/isolation-level:
    parameters:
      - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
    post:
      summary: 申请隔离级别变更
      operationId: requestIsolationLevelChange
      tags: [Isolation]
      description: |
        升级约束:
          L1 → L2 在线
          L2 → L3 需停服 (requiresDowntime)
          禁止: 同级 / 任何降级

        同 org 同时只能有 1 个 pending request.
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/RequestIsolationLevelRequest' }
      responses:
        '200':
          description: 申请已创建 (state=requested)
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data: { $ref: '#/components/schemas/IsolationChangeRequestDTO' }
        '400':
          description: 等级无效 (40036)
        '409':
          description: 升级方向非法 (40912) / 已有 pending 申请 (40911)

  /orgs/{bid}/isolation-level/{req_bid}:
    patch:
      summary: 审批隔离级别变更 (admin)
      operationId: reviewIsolationLevelChange
      tags: [Isolation]
      description: |
        approve → state=approved + 改 organization.isolation_level (标志位).
        真实物理迁移由 P2+ 运维工具消费 (executing → completed/failed).
      parameters:
        - { name: bid, in: path, required: true, schema: { type: string, format: uuid } }
        - { name: req_bid, in: path, required: true, schema: { type: string, format: uuid } }
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/ReviewIsolationLevelRequest' }
      responses:
        '200':
          description: "审批完成 (data: null)"
          content:
            application/json:
              schema: { $ref: '#/components/schemas/StandardResponse' }
        '409':
          description: 非 requested 状态 / decision 非法 (40911)

# 错误码段 (来源 internal/tenancy/port/http/errors.go::mapDomainErr L21-81)
#
# 40033 ErrSlugInvalid                 slug 格式无效
# 40034 ErrSlugReserved                 slug 是保留字
# 40035 ErrRoleUnknown                  role 不存在
# 40036 ErrIsolationLevelInvalid        隔离级别无效
# 40037 ErrInvitationEmailRequired      email 邀请必须传 email
# 40038 ErrInvitationMaxUsesInvalid     max_uses 非法
# 40039 ErrInvitationMismatchedEmail    邀请 email 不匹配
# 40301 ErrPermissionDenied             权限不足
# 40302 ErrTenantMismatch               租户不匹配
# 40303 ErrCannotRemoveLastOwner        不能移除最后一个 owner
# 40401 ErrNotFound / ErrAccountNotFound  实体不存在
# 40901 ErrVersionConflict              乐观锁并发冲突
# 40902 ErrAlreadyMember                 已是成员
# 40903 ErrSlugConflict                 slug 已被占用
# 40904 ErrDefaultWorkspaceExists       default workspace 已存在
# 40905 ErrOrganizationDeleted          组织已删除
# 40906 ErrInvalidStatusTransition      状态转移非法
# 40907 ErrMembershipInTerminalStatus   成员已 removed
# 40908 ErrInvitationInvalid            邀请无效或非 pending
# 40909 ErrInvitationExpired            邀请已过期
# 40910 ErrInvitationExhausted          邀请已用尽
# 40911 ErrIsolationChangeStateInvalid  审批状态机非法
# 40912 ErrIsolationLevelTransitionInvalid  升级方向非法
```
