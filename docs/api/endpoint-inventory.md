# HTTP Endpoint Inventory

> 自动扫描自 `internal/*/port/http/routes.go` + handler 文件交叉验证。
> **2026-08-24 增量**:+1(runtime `GET /v1/live/quote` 语音拨号前预检)→ 脚本对账 **245**(含 2026-08-20 语音 WS 面 +1)。
> **2026-08-18 增量**:+5(听语平台批 — creation 分片直传 ×4 + iap 免费额度领取 ×1)→ **243**。
> **2026-08-11 全量对账**:**238 路由 / 16 业务 BC + 1 平台**(权威计数脚本
> `scripts/tools/extract-endpoints.py` — 本日修复其空路径漏计缺陷:`g.POST("", ...)` 组根
> 形态此前不计,修后 221→238;本文档明细表为人工维护,计数不一致时以脚本+routes.go 为准)。
> 历史快照:2026-07-04 R3 出仓 201(fashiondress 15 端点迁 products 仓)· 2026-05-20 P7-02 160。
>
> **演进**:2026-05-16 P7 Phase 5 候选层(creation 11→20 endpoints,+6 `/v1/candidates/*`)· 2026-05-17 P5-01-A Prompt BC +12 + P5-02-A→D Memory BC +12 · 2026-05-10 Capability BC +5 admin · 强化项 #1 Phase E +1 SSE 流式 · 2026-05-09 +1 schema 健康检查 · 2026-05-20 P7-02 Showcase 灵感库发现端 +5(Catalog BC 扩展)· **2026-05-28 p9_05 Creation BC +3**(Phase 3 GAP-P3-002 `gen_prompt_templates` 发现端 ×2 + p9_05 移动端「增强 / 扩写」按钮 `POST /v1/prompt-assist` ×1)。
>
> 全部已实装，无待实现接口或占位。

> **产品级客户端契约**:AI 写歌 → [`aisinger-client-contract-v1.0.md`](aisinger-client-contract-v1.0.md)(冷启动→出歌→付费完整闭环)。

## 端点分布(19 段,2026-09-25 脚本对账 = **251**;2026-09-20 = 249;2026-08-31 244;2026-08-11 曾为 238)

> 2026-08-31:短剧分镜链退役(D-10),故事板/分镜子域 **9 个端点已移除**;
> 其余增量来自其后各批。计数由 `scripts/tools/extract-endpoints.py` 直出。

| BC | 注册数 | 备注 |
|---|---:|---|
| identity | 8 | login / refresh / guest-register(ADR-026 attest)/ logout ×2 / me / DELETE me / **claim-entitlement(ADR-027)** |
| tenancy | 16 | org / workspace / membership / invitation / iso-change |
| catalog | 43 | agent 18 + workflow 20 + **skill 5(WK-11 market/install)**;D-2 合表后同存 cat_artifacts,契约零变 |
| catalog/showcase | 5 | 发现端(公开)|
| **creation** | **70** | task / asset(+生命周期)/ upload / candidate / character / lineage / compose / analysis / prompt-templates / prompt-assist / **项目池 / 故事板 / intent**(明细表为节选,以 routes.go 为权威)|
| runtime | 18 | conversation / message / run / SSE / approval / 会话事件流 / plan-previews(ADR-012) / **planned 计划契约链 4 端(M-C:draft·quote·confirm·card)** / **实时语音会话(WebSocket)+ 拨号前预检 quote** |
| tool | 12 | marketplace / install(+approve)/ execute |
| knowledge | 10 | KB / document / retrieve / grounded-generate |
| provider | 1 | GET /models(admin 路由已全量移除,见下)|
| iap | 11 | app/init / webhook(apple×2+google+wechat+alipay)/ orders / verify / restore / payment-channels |
| prompt | 12 | P5-01-A(模板存储含 D-14 收编的 task_preset 层)|
| memory | 13 | P5-02-A→D + facts resolve |
| capability | 8 | invoke(+stream)+ read-model + **settle(延迟结算)** |
| wallet | 4 | wallet / ledger / **pool-approvals ×2(项目池 Phase A)** |
| **integration** | **5** | **WK-12 IM 渠道绑定(新分册 `integration.md`)** |
| **notification** | **5** | **移动推送客户端面**(端点上报/解绑/列表 + 偏好读写);管理面与运维只读面**不开 HTTP** |
| appconfig | 1 | GET /app/config(公开签名组)|
| observability | 2 | traces/:trace_id/spans + tasks/:task_bid/spans(admin gate)|
| platform | 6 | health / ping / debug ×3 / observability/health/schema |
| **合计** | **202** | |

## 鉴权矩阵速查

| 类别 | 中间件链 | 端点数 |
|---|---|---:|
| 完全公开 | (仅全局基础链;platform 6 + showcase 发现端 5) | 11 |
| 公开 + 限流防刷 | `GuestRateLimit` + `AnomalyDetection` | 1 |
| 公开 SSE | JWT(query string) | 1 |
| 上游平台通知 | 上游 JWS / 内网信任(**跳过 App 签名**) | 3 |
| Dev-only(JWT)| `JWTAuthMiddleware` + `isDev` 路由 gate | 3 |
| **JWT(标准用户)** | `JWTAuthMiddleware` | **114** |
| **JWT + admin role gate** | `JWTAuthMiddleware` + `requireAdmin` | **5**(全部 capability 端点)|

> **App 签名(HMAC)**:全局 `/v1/*` 默认启用,跳过前缀 `/v1/webhook/` + `/v1/internal/`。详见末段。

## 完整端点清单

### Catalog BC(43 endpoints,P1-01 + P4-01 + P7-02 Showcase)

#### Agent CRUD + 版本

| Method | Path | Auth | Handler |
|---|---|---|---|
| POST | `/v1/workspaces/:ws_bid/agents` | JWT | `AgentHandler.Create` |
| GET | `/v1/workspaces/:ws_bid/agents` | JWT | `AgentHandler.List` |
| GET | `/v1/agents/:bid` | JWT | `AgentHandler.Get` |
| PATCH | `/v1/agents/:bid` | JWT | `AgentHandler.UpdateMetadata` |
| DELETE | `/v1/agents/:bid` | JWT | `AgentHandler.Delete` |
| PATCH | `/v1/agents/:bid/draft` | JWT | `AgentHandler.UpdateDraft` |
| POST | `/v1/agents/:bid/archive` | JWT | `AgentHandler.Archive` |
| POST | `/v1/agents/:bid/unpublish` | JWT | `AgentHandler.Unpublish` |
| POST | `/v1/agents/:bid/versions` | JWT | `VersionHandler.Create` |
| GET | `/v1/agents/:bid/versions` | JWT | `VersionHandler.List` |
| POST | `/v1/agents/:bid/versions/:version_bid/publish` | JWT | `VersionHandler.Publish` |
| POST | `/v1/agents/:bid/rollback` | JWT | `VersionHandler.Rollback` |
| GET | `/v1/agents/:bid/deployments` | JWT | `VersionHandler.ListDeployments` |
| POST | `/v1/agents/:bid/canary` | JWT | `CanaryHandler.Set` |
| PATCH | `/v1/agents/:bid/canary` | JWT | `CanaryHandler.UpdatePercent` |
| DELETE | `/v1/agents/:bid/canary` | JWT | `CanaryHandler.Clear` |
| POST | `/v1/agents/:bid/canary/promote` | JWT | `CanaryHandler.Promote` |
| POST | `/v1/agents/:bid/canary/abort` | JWT | `CanaryHandler.Abort` |

#### Workflow CRUD + 版本(P4-01)

| Method | Path | Auth | Handler |
|---|---|---|---|
| POST | `/v1/workspaces/:ws_bid/workflows` | JWT | `WorkflowHandler.Create` |
| GET | `/v1/workspaces/:ws_bid/workflows` | JWT | `WorkflowHandler.List` |
| GET | `/v1/workflows/:bid` | JWT | `WorkflowHandler.Get` |
| PATCH | `/v1/workflows/:bid` | JWT | `WorkflowHandler.UpdateMetadata` |
| DELETE | `/v1/workflows/:bid` | JWT | `WorkflowHandler.Delete` |
| PUT | `/v1/workflows/:bid/draft` | JWT | `WorkflowHandler.UpdateDraft` |
| POST | `/v1/workflows/:bid/archive` | JWT | `WorkflowHandler.Archive` |
| POST | `/v1/workflows/:bid/unpublish` | JWT | `WorkflowHandler.Unpublish` |
| POST | `/v1/workflows/:bid/versions` | JWT | `WorkflowHandler.CreateVersion` |
| GET | `/v1/workflows/:bid/versions` | JWT | `WorkflowHandler.ListVersions` |
| POST | `/v1/workflows/:bid/versions/:version_bid/publish` | JWT | `WorkflowHandler.Publish` |
| POST | `/v1/workflows/:bid/rollback` | JWT | `WorkflowHandler.Rollback` |
| GET | `/v1/workflows/:bid/deployments` | JWT | `WorkflowHandler.ListDeployments` |
| GET | `/v1/workflow-versions/:version_bid` | JWT | `WorkflowHandler.GetVersion` |
| GET | `/v1/workflow-versions/:version_bid/compiled-dag` | JWT | `WorkflowHandler.GetCompiledDAG` |
| POST | `/v1/workflows/:bid/canary` | JWT | `WorkflowHandler.SetCanary` |
| PATCH | `/v1/workflows/:bid/canary` | JWT | `WorkflowHandler.UpdateCanaryPercent` |
| DELETE | `/v1/workflows/:bid/canary` | JWT | `WorkflowHandler.ClearCanary` |
| POST | `/v1/workflows/:bid/canary/promote` | JWT | `WorkflowHandler.PromoteCanary` |
| POST | `/v1/workflows/:bid/canary/abort` | JWT | `WorkflowHandler.AbortCanary` |

#### Showcase 灵感库发现端(P7-02,5 endpoints)

> 匿名可访问(public 路由,无 JWT);灵感运营管理由独立后台承担,不在本仓库。详见 [`showcase.md`](showcase.md)。

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/v1/showcases` | 公开 | `ShowcaseHandler.List`(支持 `q` + 全部过滤维度 + 分页) |
| GET | `/v1/showcases/search` | 公开 | `ShowcaseHandler.Search` — **DEPRECATED**,内部转发至 `List`,响应附 `Deprecation` header |
| GET | `/v1/showcases/:bid` | 公开 | `ShowcaseHandler.Get` |
| GET | `/v1/showcase-categories` | 公开 | `CategoryHandler.List` |
| GET | `/v1/showcase-tags` | 公开 | `TagHandler.List` |

### Runtime BC(12 endpoints,P1-02 + P4-01 + 强化项 #1 + ADR-012/013)

| Method | Path | Auth | Handler |
|---|---|---|---|
| POST | `/v1/conversations` | JWT | `ConversationHandler.Create` |
| GET | `/v1/conversations/:bid` | JWT | `ConversationHandler.Get` |
| GET | `/v1/conversations/:bid/messages` | JWT | `ConversationHandler.ListMessages` |
| GET | `/v1/conversations/:bid/events` | JWT (SSE) | `ConversationEventsHandler.Events` ★ ADR-013 会话级统一事件流(Last-Event-ID=conv_seq 续传;PG 补传事实源 + Redis 热路径)|
| POST | `/v1/conversations/:conv_bid/messages` | JWT | `MessageHandler.Send`(支持 `runtime_options` 字段;受 `runtime.call_options_enabled` 灰度 flag 控制,默认关闭) |
| POST | `/v1/conversations/:conv_bid/messages/stream` | JWT (SSE) | `MessageHandler.SendStream` ★ 强化项 #1 Phase E(受 `runtime.streaming.enabled` 灰度 flag 控制,默认关闭) |
| GET | `/v1/live/sessions/:bid/stream` | JWT + App 签名 (**WebSocket**) | `LiveHandler.Stream` ★ 实时语音会话。`:bid` = conversation_bid(与文字对话共用会话身份)。握手失败回**真实 HTTP 状态码**(401/404/429/402/503)而非 200 信封 —— WS 客户端读的是状态行。受 `runtime.live_audio.enabled` 控制,默认关闭;`credit_per_minute` 未定值时启动期硬拒。契约见 `live-audio-client-contract-v1.0.md` |
| GET | `/v1/live/quote` | JWT + App 签名 | `LiveHandler.Quote` ★ 拨号前预检(2026-08-24):单价/余额/可通话分钟 + `available` 状态,纯读零副作用。主用途:详情页 T0 费用展示数据源(单价拨号前唯一可查面)+ 拨号前把按钮切「去充值」;判因**兜底**(2026-08-24 勘误:xing_yuan 实测可直读握手 402/40200,判因首选直读,与其他计费路径共用 paywall 处置)。确定性结论走状态,仅基础设施故障回 50323。契约 §3.1.1 |
| GET | `/v1/runs/:bid` | JWT | `RunHandler.Get` |
| POST | `/v1/runs/:bid/cancel` | JWT | `RunHandler.Cancel` |
| POST | `/v1/runs/:bid/resume` | JWT | `RunHandler.Resume` |
| GET | `/v1/runs/:bid/events` | JWT (SSE) | `RunHandler.Events` |
| GET | `/v1/runs/:bid/attempts` | JWT | `RunHandler.Attempts` ★ R5-W7 Attempt 审计读面(按 sequence 聚合各次尝试 + `served_model_version_bid`)|
| GET | `/v1/assets/:bid/lineage` | JWT | `AssetHandler.Lineage` ★ M-F/V3 产物血缘(Run/节点 → 任务 → 模型 → **参数指纹** → 内容指纹 → 参考输入)。**零冗余列**:全部由既有 `asset → task` 外键链现算 —— 把这些事实复制到资产行上,它们会在补写失败/回填遗漏时与源头分叉且无人报警。参数指纹 = `input_params` 的规范化 sha256(键序/数值形态/空值三归一,jsonb round-trip 后仍同指纹)。**下溯**(以本资产为源的派生)走 `idx_tasks_lineage_source_asset`——派生族(`derivation_type` 即边类型 + `root_task_bid`/`derivation_depth` 物化路径)早在 `gen_generation_tasks`,不另建边表|
| GET | `/v1/runs/:bid/delegation-tree` | JWT | `RunHandler.DelegationTree` ★ M-D/K3 委派成本上卷(本 Run 及子代逐层展开;**预留与实扣分列**——在途节点的钱可能退,终态节点的钱已结,合并成一个数就没法判断哪部分还能退。零新表:按 `rt_runs.parent_run_id` 展开,子成本只在视图上卷、不改写父账。归属校验同 pause/cancel)|
| POST | `/v1/runs/:bid/approvals` | JWT | `RunHandler.SubmitApproval` ★ P4-01 |
| POST | `/v1/plan-previews` | JWT | `RunHandler.PlanPreview` ★ ADR-012 Phase D 计划卡预览(技能骨架+槽位+预算信封,零副作用)|
| POST | `/v1/plans` | JWT | `PlanHandler.Create` ★ M-C/D-003 planned 计划契约链建稿(步骤+依赖;拓扑编号 DAG 校验,非法依赖 40044 零写入)|
| GET | `/v1/plans/:bid` | JWT | `PlanHandler.Get` ★ 计划卡投影(步骤/估算/报价/状态/信封是否已开;归属校验,他人计划 40434)|
| POST | `/v1/plans/:bid/quote` | JWT | `PlanHandler.Quote` ★ 报价(行冻结报价时刻单价;重报价使旧 offered → superseded)|
| POST | `/v1/plans/:bid/revise` | JWT | `PlanHandler.Revise` ★ M-D/K4 中断矩阵 revise:旧版本未执行步骤落零成本占位终态 + 旧报价全部作废 + 追加新版本 → 回 `draft` 重报价;旧信封按**已执行用量**结清(未执行部分自动退回)。`steps` 是新版本的**完整**步骤集(非增量 —— 增量语义会让"定稿冻结"失效)。**有步骤在途时拒绝 40945**:修订要结旧信封,而在途步骤的用量尚未落库,此刻结账等于白送那部分工作 |
| POST | `/v1/plans/:bid/confirm` | JWT | `PlanHandler.Confirm` ★ **成本前置铁律执行点**:接受报价 + `Wallet.Freeze(cap=报价总额)` 开信封 → confirmed;任一失败退冻结零残留。并发确认恰一胜出(`ux_pln_quotes_one_accepted` + CAS)|

### Tenancy BC(16 endpoints,P0-02)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/v1/invitations/:token` | **公开** | `InvitationHandler.GetByToken` |
| POST | `/v1/orgs` | JWT | `OrganizationHandler.Create` |
| GET | `/v1/orgs` | JWT | `OrganizationHandler.List` |
| GET | `/v1/orgs/:bid` | JWT | `OrganizationHandler.Get` |
| PATCH | `/v1/orgs/:bid` | JWT | `OrganizationHandler.Update` |
| DELETE | `/v1/orgs/:bid` | JWT | `OrganizationHandler.Delete` |
| POST | `/v1/orgs/:bid/workspaces` | JWT | `WorkspaceHandler.Create` |
| GET | `/v1/orgs/:bid/workspaces` | JWT | `WorkspaceHandler.List` |
| DELETE | `/v1/workspaces/:bid` | JWT | `WorkspaceHandler.Delete` |
| POST | `/v1/orgs/:bid/invitations` | JWT | `InvitationHandler.Create` |
| POST | `/v1/invitations/:token/accept` | JWT | `InvitationHandler.Accept` |
| POST | `/v1/invitations/:token/revoke` | JWT | `InvitationHandler.Revoke` |
| GET | `/v1/orgs/:bid/members` | JWT | `MembershipHandler.List` |
| PATCH | `/v1/orgs/:bid/members/:member_bid` | JWT | `MembershipHandler.UpdateStatus` |
| POST | `/v1/orgs/:bid/isolation-level` | JWT | `IsolationHandler.Request` |
| PATCH | `/v1/orgs/:bid/isolation-level/:req_bid` | JWT | `IsolationHandler.Review` |

### Tool BC(11 endpoints,P2-01;M6 W12 起 5 个平台 builtin 已迁至 Capability)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/v1/marketplace/tools` | JWT | `ToolHandler.ListMarketplace` |
| POST | `/v1/tools` | JWT | `ToolHandler.Register` |
| GET | `/v1/tools/:bid` | JWT | `ToolHandler.Get` |
| POST | `/v1/tools/:bid/versions` | JWT | `ToolHandler.CreateVersion` |
| POST | `/v1/versions/:bid/review` | JWT | `ToolHandler.ReviewVersion` |
| POST | `/v1/workspaces/:ws_bid/installations` | JWT | `InstallationHandler.Install` |
| GET | `/v1/workspaces/:ws_bid/installations` | JWT | `InstallationHandler.ListByWorkspace` |
| GET | `/v1/installations/:bid` | JWT | `InstallationHandler.Get` |
| PATCH | `/v1/installations/:bid` | JWT | `InstallationHandler.UpdateConfig` |
| DELETE | `/v1/installations/:bid` | JWT | `InstallationHandler.Uninstall` |
| POST | `/v1/tools/execute` | JWT | `InstallationHandler.Execute` |

### Capability Platform BC(8 endpoints,P7 + M6 W12 完整 + 实时会话用户面)

> 详细 API 契约见 [`capability.md`](capability.md);`/v1/capabilities/*` 全部要求 **JWT + admin role gate**(`requireAdmin = GetRoleMiddleware("admin","super_admin")`)。
>
> **例外**:`/v1/live-sessions*` 是**终端用户功能**,不挂 admin gate —— 门禁靠数据驱动的
> `cap_invocation_surfaces`(`surface_kind='direct_api'` 未配行即拒绝)+ 服务端写死 capability code。
> 客户端对接文档见 [`live-session.md`](live-session.md)。

| Method | Path | Auth | Handler |
|---|---|---|---|
| POST | `/v1/capabilities/:code/invoke` | JWT + admin | `InvokeHandler.Invoke`(经 12-step middleware chain) |
| POST | `/v1/capabilities/:code/invoke/stream` | JWT + admin | `InvokeHandler.StreamInvoke`(**P8-02 D2**:SSE 流式,经 14-step 链)|
| GET | `/v1/capabilities` | JWT + admin | `QueryHandler.ListCapabilities`(分页 + category/status 过滤) |
| GET | `/v1/capabilities/:code` | JWT + admin | `QueryHandler.GetCapability`(含全部版本)|
| GET | `/v1/capabilities/:code/executions` | JWT + admin | `QueryHandler.ListExecutions`(status / since / until / 分页)|
| GET | `/v1/capabilities/:code/executions/:bid` | JWT + admin | `QueryHandler.GetExecution`(单条流水)|
| POST | `/v1/live-sessions` | JWT + App 签名 | `LiveSessionHandler.Start` — 签发实时语音会话临时令牌(客户端直连上游),按授予时长**预扣**积分 |
| POST | `/v1/live-sessions/:execution_bid/settle` | JWT + App 签名 | `LiveSessionHandler.Settle` — 上报真实用时并结算,差额自动退回;**幂等**(重复上报返 `settled=false`)|

> **实时会话特有错误段**:`50084 = live_session_unavailable`(服务端未配实时模型 / 渠道是 Vertex 后端 → 不可重试);`40200 = insufficient_credits`(预扣失败, 引导充值);`40033 = quantity_invalid`(计费数量算不出)。
>
> **特有错误段**:`50385 = queue_overloaded`(M6 W11 SchedulerMiddleware backpressure 503,`cap_resource_profiles.backpressure_threshold` 命中触发);`42930 = quota_exceeded`(QuotaMiddleware atomic CTE);`40330 = safety_blocked`(Safety pre/post middleware 拦截)。
>
> **当前 published capability 数**:20(5 utility + 9 App Store 工具 + 5 PostProcess via bridge + 1 mobile-first **p9_05** `prompt_assist` 仅 internal surface)。完整列表见 [`capability.md` § 20 个 Published Capability 速查](capability.md#20-个-published-capability-速查)。

### Prompt BC(12 endpoints,P5-01-A)

> 详细 API 契约见 [`prompt.md`](prompt.md);系统提示词模板版本化管理 + 渲染,供 Runtime/Catalog/Memory BC 经 `PromptAPI` 直接消费(零 HTTP 开销),HTTP API 主要给管理后台 / 第三方 SDK / 调试渲染。12 endpoints 实际可达(401 命中 auth middleware)。

| Method | Path | Auth | Handler |
|---|---|---|---|
| POST | `/v1/prompts/workspaces/:ws_bid/templates` | JWT | `TemplateHandler.Create`(slug 唯一 + tx + Outbox) |
| GET | `/v1/prompts/workspaces/:ws_bid/templates` | JWT | `TemplateHandler.List`(分页 + status/type/is_shared 过滤) |
| GET | `/v1/prompts/templates/:bid` | JWT | `TemplateHandler.Get`(含 live_version 展开) |
| PATCH | `/v1/prompts/templates/:bid` | JWT | `TemplateHandler.Update`(乐观锁) |
| POST | `/v1/prompts/templates/:bid/archive` | JWT | `TemplateHandler.Archive`(终态 + 缓存失效) |
| POST | `/v1/prompts/templates/:bid/deprecate` | JWT | `TemplateHandler.Deprecate` |
| POST | `/v1/prompts/templates/:bid/versions` | JWT | `VersionHandler.Create`(content_hash 幂等) |
| GET | `/v1/prompts/templates/:bid/versions` | JWT | `VersionHandler.List`(version_number ASC) |
| GET | `/v1/prompts/versions/:vbid` | JWT | `VersionHandler.Get` |
| POST | `/v1/prompts/templates/:bid/versions/:vbid/publish` | JWT | `VersionHandler.Publish`(already_live 幂等) |
| POST | `/v1/prompts/templates/:bid/rollback` | JWT | `VersionHandler.Rollback`(指针式) |
| POST | `/v1/prompts/versions/:vbid/render` | JWT | `RenderHandler.Render`(text/template 沙箱) |

> **错误段 45000–45099**;详见 `internal/prompt/port/http/errors.go::mapDomainErr`。
>
> **内置共享模板**:`__sys_session_summarizer` + `__sys_fact_extractor`(tenant_id=0 + is_shared=true,Memory BC P5-02-A 起引用)。

### Memory BC(12 endpoints,P5-02-A/B/C/D 完整实装)

> 详细 API 契约见 [`memory.md`](memory.md);Agent 三层记忆体系(L1 复用 Run.Scratchpad / L2 摘要 / L3 facts+语义)。HTTP API + 跨 BC API (Runtime / Catalog 经 `MemoryAPI` 直接消费,零 HTTP 开销)双通路均可达。
>
> P5-02-D 验证:12 endpoints 全部 lookup 正常(curl 实测返 401 而非 404)。L3 完整接通 Provider+Prompt+Knowledge(配 `modules.memory.l3.*`)。ConversationReader 自动拉对话文本接通 Runtime BC。

| Method | Path | Auth | Handler | 备注 |
|---|---|---|---|---|
| GET | `/v1/memories/spaces/:bid` | JWT | `SpaceHandler.Get` | 含 stats |
| POST | `/v1/memories/spaces/:bid/purge` | JWT | `SpaceHandler.Purge` | GDPR + force flag |
| GET | `/v1/memories/spaces/:bid/summaries?conversation_bid=` | JWT | `SpaceHandler.ListSummaries` | |
| POST | `/v1/memories/spaces/:bid/facts` | JWT | `FactHandler.Upsert` | HTTP 强制 source=explicit + confidence=1.0(防伪造) |
| GET | `/v1/memories/spaces/:bid/facts?category=&limit=` | JWT | `FactHandler.List` | 分页 + category 过滤 |
| PUT | `/v1/memories/spaces/:bid/facts/:fbid` | JWT | `FactHandler.Update` | UPSERT 同接口 |
| DELETE | `/v1/memories/spaces/:bid/facts/:fbid` | JWT | `FactHandler.Delete` | 软删 |
| POST | `/v1/memories/spaces/:bid/retrieve` | JWT | `RetrieveHandler.Retrieve` | 三路并发(L2/L3 facts/L3 semantic) |
| GET | `/v1/memories/agents/:agent_id/spaces?limit=&offset=` | JWT | `AgentSpaceHandler.List` | **P5-02-D 实装** (路径 `:agent_id` 直接 int64,跳过 Catalog 解析) |
| POST | `/v1/memories/agents/:agent_id/spaces` | JWT | `AgentSpaceHandler.Create` | ResolveSpace 显式入口 |
| PATCH | `/v1/memories/agents/:agent_id/spaces/:bid` | JWT | `AgentSpaceHandler.UpdateConfig` | **P5-02-D 实装** (11 字段 PATCH 风格,nil 字段保留原值) |
| GET | `/v1/memories/spaces/:bid/timeline` | JWT | `SpaceHandler.Timeline` | facts + summaries 混合 |

> **MemoryAPI 12 方法**(facade,供跨 BC 直调):Ping / ResolveSpace / Retrieve / UpdateAfterRun / UpsertFact / DeleteFact / PurgeSpace / GetSpace / ListFacts / ListSummaries / **ListSpacesByAgent**(P5-02-D)/ **UpdateSpaceConfig**(P5-02-D)。
>
> **错误段 46000–46099**;详见 `internal/memory/port/http/errors.go::mapDomainErr`。
>
> **6 种 Outbox 事件**:`memory.space_created` · `memory.fact_upserted` · `memory.fact_deleted` · `memory.session_summarized` · `memory.consolidated_to_l3` · `memory.space_purged`。
>
> **CleanupWorker** 24h tick 软删过期 facts(`worker/cleanup_worker.go`,cmd/genaistudio-worker 启动);**MemoryEventConsumer** 订阅 `runtime.run_succeeded` 触发摘要 + 归档(P5-02-D 自动拉对话文本)。
>
> **E2E 集成测试**:`test/e2e/memory/memory_flow_test.go`(P5-02-E.3,8 case 覆盖 ResolveSpace 幂等 / 源优先级 / Retrieve 降级 / UpdateSpaceConfig PATCH / ListSpacesByAgent / PurgeSpace,环境变量 `MEMORY_E2E=1` 启用)。

### Knowledge BC(10 endpoints)

| Method | Path | Auth | Handler |
|---|---|---|---|
| POST | `/v1/knowledge/bases` | JWT | `KBHandler.CreateKB` |
| GET | `/v1/knowledge/bases` | JWT | `KBHandler.ListKBs` |
| GET | `/v1/knowledge/bases/:bid` | JWT | `KBHandler.GetKB` |
| DELETE | `/v1/knowledge/bases/:bid` | JWT | `KBHandler.DeleteKB` |
| POST | `/v1/knowledge/bases/:bid/documents` | JWT | `DocumentHandler.UploadDocument` |
| GET | `/v1/knowledge/bases/:bid/documents` | JWT | `DocumentHandler.ListDocuments` |
| GET | `/v1/knowledge/bases/:bid/documents/:doc_bid` | JWT | `DocumentHandler.GetDocument` |
| DELETE | `/v1/knowledge/bases/:bid/documents/:doc_bid` | JWT | `DocumentHandler.DeleteDocument` |
| POST | `/v1/knowledge/bases/:bid/retrieve` | JWT | `QueryHandler.Retrieve` |
| POST | `/v1/knowledge/bases/:bid/generate` | JWT | `QueryHandler.GroundedGenerate` |

### Creation BC(35 endpoints,含 P7 Phase 5 候选层 6 个 + Phase 3 GAP-P3-002 任务级提示词预设 2 个 + p9_05 移动端提示词辅助 1 个 + Plan-Subject 主体/角色 8 个)

| Method | Path | Auth | Handler |
|---|---|---|---|
| POST | `/v1/internal/tasks/:bid/complete` | **内网回调**(跳过 App 签名) | `TaskHandler.CompleteTask` |
| POST | `/v1/tasks` | JWT | `TaskHandler.SubmitTask` |
| GET | `/v1/tasks` | JWT | `TaskHandler.ListTasks` |
| POST | `/v1/tasks/estimate` | JWT | `TaskHandler.EstimateCost` |
| GET | `/v1/tasks/:bid` | JWT | `TaskHandler.GetTask`(**P7 Phase 5 改造**:响应嵌入 `candidate_summary` + `candidates[]`)|
| GET | `/v1/tasks/:bid/stream` | JWT | `TaskHandler.StreamTask`(**P8-02**:SSE 实时进度推送,替代轮询)|
| POST | `/v1/tasks/:bid/cancel` | JWT | `TaskHandler.CancelTask`(2026-09-28 起 `data.outcome = cancelled \| cancel_requested`,ADR-037)|
| GET | `/v1/tasks/:bid/lineage` | JWT | `TaskHandler.GetTaskLineage`(**Plan-Lineage v1**:谱系树扁平节点表,≤500 一次返回)|
| GET | `/v1/tasks/:bid/compare?with=` | JWT | `TaskHandler.CompareTasks`(**Plan-Lineage v1**:params 结构化 diff + 产物并排)|
| GET | `/v1/tasks/:bid/candidates` | JWT | `AssetLifecycleHandler.ListCandidates`(**P7 Phase 5 重写**:查 `gen_task_candidates` 表) |
| GET | `/v1/tasks/:bid/selected` | JWT | `AssetLifecycleHandler.ListSelected` |
| POST | `/v1/tasks/:bid/select` | JWT | `AssetLifecycleHandler.SelectAssets`(P2 旧端点,候选迁出后空集) |
| GET | `/v1/candidates/:bid` | JWT | `CandidateHandler.GetCandidate` ★ **P7 Phase 5** |
| POST | `/v1/candidates/:bid/save` | JWT | `CandidateHandler.SaveCandidate` ★ **P7 Phase 5** |
| POST | `/v1/candidates/:bid/discard` | JWT | `CandidateHandler.DiscardCandidate` ★ **P7 Phase 5** |
| POST | `/v1/candidates/batch_save` | JWT | `CandidateHandler.BatchSave` ★ **P7 Phase 5**(AIP-136 partial success)|
| POST | `/v1/candidates/batch_discard` | JWT | `CandidateHandler.BatchDiscard` ★ **P7 Phase 5** |
| GET | `/v1/accounts/me/candidates` | JWT | `CandidateHandler.ListMyCandidates` ★ **P7 Phase 5**(我的草稿池) |
| GET | `/v1/assets` | JWT | `AssetHandler.ListAssets` |
| GET | `/v1/assets/:bid` | JWT | `AssetHandler.GetAsset` |
| POST | `/v1/assets/:bid/discard` | JWT | `AssetLifecycleHandler.DiscardAsset` |
| POST | `/v1/assets/:bid/archive` | JWT | `AssetLifecycleHandler.ArchiveAsset` |
| POST | `/v1/assets/:bid/unarchive` | JWT | `AssetLifecycleHandler.UnarchiveAsset` |
| POST | `/v1/assets/upload` | JWT | `AssetHandler.UploadAsset`(multipart 直传 + 落 `gen_assets`,upload_state='uploaded';**P6-04** 账户级 hash 去重,响应 `dedup_hit` 标记复用) |
| POST | `/v1/uploads/sign` | JWT | `UploadHandler.SignUpload`(presigned PUT 双段式 Step 1, 预创建 pending Asset;**P6-04** `file_hash` **必填**(2026-06-20 起, SHA-256 64 lowercase hex), 命中已有 uploaded asset 短路返 `dedup_hit=true + put_url=""`;缺/格式错 → 40001) |
| POST | `/v1/uploads/finalize` | JWT | `UploadHandler.FinalizeUpload`(双段式 Step 2, pending → uploaded;HEAD R2 校验**实际 size == 声明 size**(A2), 不符 → 40038;**P6-04** 并发 race 撞 UNIQUE 自动切 hit fallback,响应 `dedup_hit`) |
| POST | `/v1/uploads/resolve-urls` | JWT | `UploadHandler.ResolveURLs`(批量 uploads/ key → 访问 URL;逐 key 按 JWT abid 归属确权(`UploadKeyOwnedBy` key 第 3 段语法匹配), 不归属/失败该条空串 fail-quiet;下游产品服务转发终端用户 JWT 代调先例) |
| POST | `/v1/uploads/multipart/init` | JWT | `UploadHandler.MultipartInit`(**听语 P-5′** 分片直传 Step 1: 策略校验 + hash 去重短路 + 预建 pending(metadata 持久化 upload_id)+ 开 S3 会话;响应 `{bid, key, upload_id, part_size, part_count}`)|
| POST | `/v1/uploads/multipart/sign-part` | JWT | `UploadHandler.MultipartSignPart`(Step 2 可重复: 单分片 presigned PUT, 1h 有效;客户端 PUT 后记响应头 ETag;除末片外每片 ≥5MiB)|
| POST | `/v1/uploads/multipart/complete` | JWT | `UploadHandler.MultipartComplete`(Step 3: S3 合并 → 委派 finalize(HEAD size 校验/pending→uploaded/去重 fallback 全复用), 响应同 finalize)|
| POST | `/v1/uploads/multipart/abort` | JWT | `UploadHandler.MultipartAbort`(显式取消: 中止会话清理分片 + pending 软删;静默弃传由 PendingUploadCleanup 收口 Abort)|
| POST | `/v1/characters` | JWT | `CharacterHandler.CreateCharacter`(P8-03-B 主体/角色;初始锚定资产须 `upload_state=uploaded`,过 D7 审核挂载点) |
| GET | `/v1/characters` | JWT | `CharacterHandler.ListCharacters` |
| GET | `/v1/characters/:bid` | JWT | `CharacterHandler.GetCharacter`(含 `prompt_anchor/negative_anchor/tags/voice_ref` + assets `view_role`) |
| PATCH | `/v1/characters/:bid` | JWT | `CharacterHandler.UpdateCharacterMeta`(**Plan-Subject T6** 扩 `prompt_anchor/negative_anchor/tags/voice_ref`,部分语义) |
| DELETE | `/v1/characters/:bid` | JWT | `CharacterHandler.DeleteCharacter` |
| POST | `/v1/characters/:bid/three-view` | JWT | `CharacterHandler.GenerateThreeView` ★ **Plan-Subject T3**(模板渲染 + 提交 image_gen,`_subject_gen` 标记;body 必带 `model_version_bid`) |
| POST | `/v1/characters/:bid/assets` | JWT | `CharacterHandler.AddCharacterAsset`(body 可带 `view_role` 回填;40854=未上传完成,40853=审核拒绝) |
| DELETE | `/v1/characters/:bid/assets/:asset_bid` | JWT | `CharacterHandler.RemoveCharacterAsset` |
| GET | `/v1/prompt-templates` | JWT | `GenPromptTemplateHandler.List`(**Phase 3 GAP-P3-002** 任务级提示词预设发现端,可选 `?task_type=` 过滤) |
| GET | `/v1/prompt-templates/:code` | JWT | `GenPromptTemplateHandler.GetByCode`(404 = `ErrGenPromptTemplateNotFound`) |
| POST | `/v1/prompt-assist` | JWT | `PromptAssistHandler.Assist`(**p9_05** 移动端「增强 / 扩写」按钮通用入口;经 `capability.Invoke(SurfaceInternal)` 走 14-step chain) |

### Provider BC(3 endpoints;admin 路由已全量移除)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/v1/models` | JWT | `ModelHandler.ListModels` |
| GET | `/v1/capability-defaults/:code` | JWT | `CapabilityDefaultHandler.ResolveDefault`(能力码 → 当期默认 model_version_bid) |
| POST | `/v1/webhook/minimax/video` | **公开**(跳过 App 签名;回调无签名 → 只回显 challenge / 提前轮询,不改账务事实,ADR-041) | `MiniMaxCallbackHandler.Handle` |

> **2026-05-25 C-cleanup.1**:原 8 条 `/v1/admin/provider/*`(router-rules CRUD / _reload /
> cache invalidate)已删除 — API-Only 定位下 admin 能力仅经 `ProviderAPI` 方法暴露
> (`internal/provider/port/http/routes.go` 注释为准);本仓库另有 archtest
> `TestNoAdminHTTPRoutes` 固化"禁注册 /admin 路由"红线(UPG-D3-002)。

### Identity BC(6 endpoints)

| Method | Path | Auth | Handler |
|---|---|---|---|
| POST | `/v1/auth/login` | **公开** | `AuthHandler.Login` |
| POST | `/v1/auth/refresh` | **公开** | `AuthHandler.Refresh` |
| POST | `/v1/auth/guest-register` | 公开 + RateLimit + Anomaly | `AuthHandler.GuestRegister` |
| POST | `/v1/auth/logout` | JWT | `AuthHandler.Logout` |
| POST | `/v1/auth/logout/all` | JWT | `AuthHandler.LogoutAll` |
| GET | `/v1/auth/me` | JWT | `AuthHandler.Me` |
| DELETE | `/v1/auth/me` | JWT | `AuthHandler.DeleteAccount` |
| POST | `/v1/auth/claim-entitlement` | JWT | `EntitlementClaimHandler.ClaimEntitlement`(ADR-027 凭 Apple 签名交易重绑游客)|

### IAP BC(8 endpoints)

| Method | Path | Auth | Handler |
|---|---|---|---|
| POST | `/v1/app/init` | **公开** | `AppInitHandler.Init` |
| POST | `/v1/webhook/apple` | **Apple JWS**(跳过 App 签名) | `WebhookHandler.HandleAppleNotification` |
| POST | `/v1/webhook/apple/:distribution_code` | **Apple JWS**(跳过 App 签名) | `WebhookHandler.HandleAppleNotification` |
| POST | `/v1/iap/orders` | JWT | `OrderHandler.CreateOrder` |
| POST | `/v1/iap/orders/:order_no/verify` | JWT | `OrderHandler.VerifyReceipt` |
| POST | `/v1/webhook/google/:distribution_code` | **Google 签名**(跳过 App 签名) | `WebhookHandler.HandleGoogleNotification` |
| POST | `/v1/webhook/wechat` | **微信平台证书验签**(跳过 App 签名;回调自描述:试解密枚举凭证) | `WebhookHandler.HandleWechatNotification` |
| POST | `/v1/webhook/wechat/:distribution_code` | 同上(旧带参路由,兼容保留) | `WebhookHandler.HandleWechatNotification` |
| POST | `/v1/webhook/alipay` | **支付宝 RSA2 验签**(跳过 App 签名;回调自描述:form app_id 反查商户) | `WebhookHandler.HandleAlipayNotification` |
| POST | `/v1/webhook/alipay/:distribution_code` | 同上(旧带参路由,兼容保留) | `WebhookHandler.HandleAlipayNotification` |
| POST | `/v1/iap/restore` | JWT(专项限流) | `OrderHandler.RestoreSubscription` |
| POST | `/v1/iap/free-quota/claim` | JWT | `FreeQuotaHandler.Claim`(**听语 P-6** 月度免费额度惰性领取: `iap_apps.metadata.monthly_free` 数据驱动;幂等 = wallet `source_ref=freecycle:{app}:{account}:{YYYYMM}` 全局唯一;未配置 app 返 `configured=false` 正常态;依赖不可达 → 50302)|

### Wallet BC(4 endpoints)

以 `internal/wallet/port/http/routes.go` 为权威。

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/v1/wallet` | JWT | `WalletHandler.GetWallet` |
| GET | `/v1/wallet/ledger` | JWT | `WalletHandler.GetLedger` |
| POST | `/v1/wallet/pool-approvals` | JWT | `PoolApprovalHandler.Request` |
| GET | `/v1/wallet/pool-approvals` | JWT | `PoolApprovalHandler.ListMine` |

> `GET /v1/wallet/ledger` 自 `081367bf`(2026-07-16)起在册并已随后续 release 上线,**不是待建端点**;
> 前端要做积分流水/账本面板直接接这个,禁止另起一套流水接口(契约见 [wallet.md](wallet.md) 与
> `api/openapi/openapi.yaml#/paths/~1wallet~1ledger`)。

### Notification BC(5 endpoints,移动推送客户端面)

以 `internal/notification/port/http/routes.go` 为权威。

| Method | Path | Auth | Handler |
|---|---|---|---|
| POST | `/v1/notifications/endpoints` | JWT + App 签名 | `EndpointHandler.Register` |
| DELETE | `/v1/notifications/endpoints` | JWT | `EndpointHandler.Detach` |
| GET | `/v1/notifications/endpoints` | JWT | `EndpointHandler.List` |
| GET | `/v1/notifications/preferences` | JWT + App 签名 | `PreferenceHandler.Get` |
| PUT | `/v1/notifications/preferences` | JWT + App 签名 | `PreferenceHandler.Update` |

**只有客户端面。** 管理面(凭证灌入 / 规则增改 / 模板发布)与运维只读面
(投递回溯 / 受众预演)**不开 HTTP** —— 它们归独立后台,只经 `NotificationAPI`
方法暴露。判据看「面」的性质不看 URL 前缀:一个 `/v1/notifications/rules`
不带 admin 前缀,但它仍然是管理面(组织红线,守卫 `no_admin_routes_test`)。

🔴 **身份只从 ctx 取。** `account_id` 来自 JWT 中间件,`distribution_code`
来自 App 签名中间件;请求体里的同名字段一律不接受 —— 客户端若能给分发码,
就能把自己的设备登记到另一个 App 的分发下,从而收到那个 App 的推送,
而这类越权在日志里看起来完全正常(200、无异常、无告警)。
守卫 `tests/archtest/http_identity_from_context_test.go`(平台级,扫全部 HTTP 端口层)。

三条形态约定:

- **上报幂等** —— 客户端每次启动都调 `POST /endpoints`;重复上报刷新画像与上报时刻,
  而上报时刻是 410 失效判定的时序基准(不刷新会让过期的 410 杀掉刚上报的新令牌);
- **登出幂等** —— `DELETE /endpoints` 对已解绑的端点返回成功而非 404;
- **偏好返回全量 (类目 × 通道)** —— 只返回已表态的会让客户端无法区分「未表态」
  与「类目不存在」,而营销类的默认是**拒绝**,那个默认值必须被客户端看见。

对外错误码见 [error-codes.md](error-codes.md) 的 49100 段。响应视图**不带设备令牌**
(客户端本就知道自己的令牌,回传只增加泄漏面)。

### AppConfig BC(1 endpoint,客户端协作契约 #8)

| Method | Path | Auth | Handler |
|---|---|---|---|
| GET | `/v1/app/config` | **公开**(App 签名,与 `/v1/app/init` 同组) | `appconfighttp.ConfigHandler.GetConfig` |

读侧返回当前分发的有效配置(维护态 / kill-switch / 远程开关),`distribution_code` 由 App 签名中间件验签注入;响应在内存合并「全局兜底行 ∪ 分发行」(见 `domain.Resolve`)。**fail-open**:配置库故障返安全默认(维护关 / 空集合),绝不阻断 App 启动。写侧(Upsert / SetMaintenance / SetKillSwitches)**不暴露 HTTP** —— 由独立 IAM-admin 项目经 `AppConfigAPI` 写入(API-Only 定位)。

### ~~Fashiondress BC(潮流换装 Muse)~~ —— 已出仓,本仓不再提供

**2026-07-04 R3 已整体迁出到 `genaistudio-products` 产品仓**(平台仓拒收产品 BC,见 CLAUDE.md
「产品层红线」)。`internal/fashiondress/` 已不存在,原 15 个端点(`/v1/wardrobes/*` ·
`/v1/style-profile` · `/v1/collections/*`)在**本仓一律 404**,`docs/api/fashiondress.md` 亦已随之移除。

> 客户端请勿再按本仓契约接这批路径;归属与新契约以产品仓为准。
> 原清单如需考古:`git show aefe36b2~1:docs/api/fashiondress.md`(该 commit = R3 平台清理,删除本文件)。
> 上方合计 202 **不含**这 15 个(历史快照见文首:出仓当时 201)。

### 骨架 BC(无 HTTP 端点)

| BC | 状态 | 备注 |
|---|---|---|
| `iam` | ⏳ P0-01 骨架 | 仅 Module API,Casbin RBAC 待 P0-03 |
| `observability` | ⏳ P0-01 骨架 | AuditLog 入站留 P1+ |
| `integration` | ⏳ P0-01 骨架 | Webhook/OAuth 待 P5+ |
| `safety` | — | 仅 Module API(NoopContentModerator stub) |

## App 签名中间件

### 设计

`internal/platform/httpserver/middleware/app_signature.go::AppSignatureMiddleware`

- **挂载点**:`MiddlewareManager.GetGlobalHandlers()` 链尾,作用于所有 `/v1/*`
- **跳过路径**(前缀匹配):
  - `/v1/webhook/` — Apple S2S / Google RTDN / Stripe webhook(走上游平台 JWS 验签)
  - `/v1/internal/` — 内网回调(供应商 task complete 等,内网信任 / IP 白名单)

### 客户端必填请求头

```http
X-Distribution-Code: com.aigc.creator              # app_distributions.distribution_code (全局唯一)
X-Timestamp:         1735689600                    # Unix 秒级时间戳
X-Nonce:             550e8400-e29b-41d4-a716-446655440000   # UUID, 防重放
X-App-Signature:     <hex>                          # HMAC-SHA256
```

### 签名公式

```
canonical = timestamp + nonce + sortedJSON(body)    // 无分隔符
signature = hex(HMAC_SHA256(distribution.secret_key, canonical))
```

`distribution.secret_key` 在 `iap_app_distributions.secret_key_hash` 存储 hash(原文不落库)。客户端打包时由运营注入到 build-time config。

### 防御维度

1. **时间戳窗口**:`±5 min`(超过则 40112 过期)
2. **Nonce 防重放**:Redis SET NX + 10 min TTL(已用 nonce 拒)
3. **分发隔离**:每个 `distribution_code` 独立 secret_key — 单渠道泄露不影响其他渠道。例:华为渠道包被逆向 → 仅轮换 huawei 分发密钥。

### 错误码段

| Code | 含义 |
|---|---|
| 40110 | 缺签名头 |
| 40111 | X-Timestamp 格式无效 |
| 40112 | 请求已过期(超出时间窗) |
| 40113 | Nonce 重复(防重放命中) |
| 40114 | distribution_code 不存在 / 已下架 |
| 40115 | 签名校验失败 |

### 配置开关

`AppSignatureConfig.Enabled` 默认 `true`(prod / dev 一致)。dev 端如要临时关闭,改 `DefaultAppSignatureConfig` 或注入自定义 config(不建议长期关闭,否则丢失分发隔离)。

### Platform / Health / Debug(6,在 `internal/platform/httpserver/common/routes.go`)

| Method | Path | Auth | Handler | 备注 |
|---|---|---|---|---|
| GET | `/v1/health` | **公开** | `HealthHandler.Health` | 健康检查(LB / k8s liveness probe) |
| GET | `/v1/ping` | **公开** | `HealthHandler.Ping` | 简单 ping |
| GET | `/v1/observability/health/schema` | JWT + admin/super_admin role | `SchemaHealthHandler.Health` | **2026-05-09 新增 / 2026-05-25 C-cleanup.1.b 由 `/admin/health/schema` 重命名(语义对齐"基础设施监控"非业务 admin)**:暴露 13 BC 注册的关键索引 + RLS POLICY 实时存在性。响应 body `{schema_healthy: bool, summary: {total/missing}, by_bc: [...]}`。启动期 hard fail 校验(`schemaassert.VerifyIndexes/VerifyPolicies`)同源数据 |
| GET | `/v1/debug/panic` | JWT(**仅 dev**)| `DebugHandler.TriggerPanic` | string 类型 panic, Recovery 中间件验证用 |
| GET | `/v1/debug/panic/error` | JWT(**仅 dev**)| `DebugHandler.TriggerPanicError` | error 类型 panic |
| GET | `/v1/debug/panic/nil` | JWT(**仅 dev**)| `DebugHandler.TriggerPanicNil` | nil dereference |

> Dev gate:`PlatformRoutes.RegisterAuthenticatedRoutes` 内 `if !r.isDev { return }`(`isDev = cfg.Environment == "dev" || "development"`)。Prod 完全跳过 3 个 `/debug/*` 路由的注册;`/observability/health/schema` 在 prod / dev 都注册。
>
> **`/v1/observability/health/schema` 鉴权**:由 admin/super_admin role middleware 守护(C-cleanup.1.b 2026-05-25 已落实)。本端点暴露内部基础设施细节(索引名 / 表名 / migration 路径 / data invariant 违例样本),由 SRE / 运维工具直接抓取(类比 Prometheus `/metrics`),非业务管理后台。

### `http-requests/*.http` 测试覆盖率

实况(2026-08-17 复核 `docs/api/http-requests/`):**4 个文件**——
`gen_prompt_templates.http`(7)· `live_session.http`(9)· `prompt_assist.http`(8)· `wallet.http`(5,本次补)。
此前记载的「52/123 ≈ 42%」为历史值,已失真。绝大多数 BC 仍无 `.http` 样例,缺口含:
- `catalog`(38 endpoints)· `runtime`(13)· `knowledge`(10)· `tool`(11)· `iap`(11)· `memory`(13)…

> 补样例时注意签名头以 `internal/platform/httpserver/middleware/app_signature.go:74-77` 为准:
> `X-Distribution-Code` / `X-App-Signature` / `X-Timestamp` / `X-Nonce`。
> 存量 `prompt_assist.http` 里的 `X-App-ID` 是历史写法,中间件不读该头。

不影响功能(handler 全实装),但 QA 自动化需补齐。

## 起跳点

1. **iam / observability / integration 暴露 HTTP** — Casbin RBAC + AuditLog 入站 / Webhook 接入(P0-03 / P1+ / P5+)
2. **OpenAPI 自动生成** — 当前无 IDL 文件,后续若需 SDK 自动生成考虑 `swaggo/swag` 注解或 `kin-openapi` 反射式提取
3. **Wallet 错误码细分** — Wallet BC 当前所有 error 返 50000,KTD 项

## 维护提示

- 新增 endpoint 必须更新本文档(同步性靠 PR review,无自动校验)
- 修改 `RouteRegistrar` 后跑 `tests/archtest/` 验证模块边界完整
- App 签名挂载顺序固定(global 链尾 + auth 之前),不要改顺序
- 若新增第三方 webhook 路径,加到 `DefaultAppSignatureConfig.SkipPaths`

## 计数对账(2026-07-02,UPG-D7-002)

权威脚本:`python3 scripts/tools/extract-endpoints.py`(抽取全部 routes.go 的
`.GET/.POST/.PUT/.PATCH/.DELETE` 字面量注册)。本次对账消除的漂移:

- 总数 160(2026-05-20 文档)→ **198**(实测);主要增量在 creation(33→53:
  characters 8 / lineage 2 / compose / analysis 3 / asr / prompt-templates 2 / prompt-assist 等)
- provider 9→1:8 条 `/v1/admin/*` 已删,文档此前未同步(本次修正)
- 新登记:observability 2(trace 查询,admin gate)· catalog/showcase 独立列示
- iap 5→7 / identity 6→7 / tool 11→12(installations approve)

维护约定升级:改动 routes.go 后跑一次脚本并同步"端点分布"表;明细行表仍人工维护,
以 routes.go 为唯一权威。
