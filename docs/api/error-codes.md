# 错误码段完整参考

> **API 信封** `code` 字段。`code = 0` 表示成功,非 0 走 5 位错误码分段。
> **更新**: 2026-05-20 P7-02 Showcase 灵感库 BC +15 sentinel(47000-47099 + 47301);2026-05-18 P5-02-E.4 prompt (45xxx) + memory (46xxx)

> ⚠️ **本文档 ≠ 任务失败原因**。本文覆盖的是**接口调用本身**失败时信封里的 5 位数字 `code`。
> AI 生成任务执行失败的原因是另一套**字符串**诊断码,落在 `gen_generation_tasks.error_code`
> 并经 `GET /v1/tasks/:bid` 的 `error_code` 字段下发(`content_filtered` / `submit_timeout` /
> `poll_timeout` / ...)。前端做失败话术请查
> **[`creation.md` §任务失败诊断码](./creation.md#任务失败诊断码taskerror_code2026-08-02-起保证非空)**
> ——那里有取值表 + 可重试性 + 建议话术方向。此处不复制该表以免两份漂移。

---

## 一、段位总览(14 BC)

| BC | 段位范围 | sentinel 数 | 关键文件 |
|---|---|---:|---|
| identity | 401xx + 403xx + 404xx + 429xx | 12 | `internal/identity/domain/errors.go` |
| tenancy | 409xx + 400xx + 403xx | 23 | `internal/tenancy/domain/errors.go` |
| iam | 40xxx 共享段 | 7 | `internal/iam/domain/errors.go` |
| catalog | 404xx + 409xx + 400xx | 28 | `internal/catalog/domain/errors.go` |
| runtime | 404xx + 409xx + 500xx | 16 | `internal/runtime/domain/errors.go` |
| tool | 404xx + 409xx + 400xx | 26 | `internal/tool/domain/errors.go` |
| knowledge | 404xx + 403xx + 400xx + 429xx + 502xx | 17 | `internal/knowledge/domain/errors.go` |
| provider | 404xx + 403xx + 400xx + 429xx + 451xx + 502xx | 13 | `internal/provider/domain/errors.go` |
| iap | 404xx + 403xx + 400xx + 503xx | 15 | `internal/iap/domain/errors.go` |
| creation | 404xx + 409xx + 400xx + 402xx + 451xx + 459xx | 33 | `internal/creation/domain/errors.go` |
| wallet | 共享段 | 4 | `internal/wallet/domain/errors.go` |
| safety | 共享段 | 4 | `internal/safety/domain/errors.go` |
| observability | 共享段 | 5 | `internal/observability/domain/errors.go` |
| integration | 共享段 | 6 | `internal/integration/domain/errors.go` |
| capability | 共享段 | 9 | `internal/capability/domain/errors.go` |
| **prompt** | **45000-45099 + 45301** ⭐ | 24 | `internal/prompt/domain/errors.go` |
| **memory** | **46000-46099 + 46301** ⭐ | 20 | `internal/memory/domain/errors.go` |
| **showcase** | **47000-47099 + 47301** ⭐ | 15 | `internal/catalog/showcase/domain/errors.go`(Catalog BC 扩展)|

**合计**:**334 sentinel**(14 BC + Showcase 扩展段)

---

## 二、段位分类

### 通用 4xx(各 BC 共享)

| Range | 类别 | HTTP | 含义 |
|---|---|---|---|
| 400xx | 通用客户端错误 | 400 | Validation / Bad Request |
| 401xx | 认证 | 401 | invalid password / token expired / missing signature(例外:40115 签名校验暂不可用随 **503** 返回 —— 基础设施故障 fail-close,与业务拒绝严格区分,详见 overview.md §5.7)|
| 402xx | 支付 | 402 | insufficient credits |
| 403xx | 授权 | 403 | account/app/distribution locked-disabled |
| 404xx | 资源不存在 | 404 | account / agent / workflow / version 等 |
| 409xx | 冲突 | 409 | 版本冲突 / 已存在 / 状态机非法 |
| 429xx | 限流 | 429 | login attempts / device rate / task submit (42920) / SSE conn limit (42921) / account concurrent runs (42922) / **live voice concurrent sessions (42923)** / daily submit limit (42924) / capability+knowledge quota (42930, 两 BC 共用需靠 message 区分) |
| 451xx | 法律 | 451 | content filtered / prompt rejected |
| 459xx | creation 候选 | 4xx | candidate 状态(P7 Phase 5)|

### 通用 5xx

| Range | 类别 | HTTP | 含义 |
|---|---|---|---|
| 500xx | 通用服务端 | 500 | internal / grant failed |
| 502xx | 上游故障 | 502 | upstream failed / transient |
| 503xx | 服务不可用 | 503 | store unavailable / backpressure |

### 专属段(2 个 BC 独占)

| BC | 段 | 设计理由 |
|---|---|---|
| **prompt** | **45000-45099** | 与 Memory 配对,Memory L2 摘要 Prompt 引用,需独立段防冲突 |
| **memory** | **46000-46099** | Memory BC 错误数 ≥ 20,独立段易追溯 |

---

## 三、完整 sentinel 清单(按 BC)

### capability (9)

`ErrCapabilityNotFound / ErrCapabilityAlreadyExists / ErrVersionConflict / ErrVersionNotFound / ErrVersionAlreadyExists / ErrInvalidStatusTransition / ErrReviewNotApproved / ErrUnauthorizedActor / ErrInvalidInvocationMode`

### catalog (28)

`ErrNotFound / ErrWorkspaceNotFound (40421) / ErrVersionNotFound (40422) / ErrAgentNotFound (40420) / ErrInvalidStatusTransition (40923) / ErrVersionConflict (40901) / ErrSlugConflict (40920) / ErrDuplicateAgentCode (40921) / ErrAgentArchived (40922) / ErrVersionImmutable (40924) / ErrVersionNumberConflict (40925) / ErrRollbackTargetInvalid (40926) / ErrCanaryPercentInvalid (40041) / ErrCanaryVersionNotPublished (40927) / ErrCanaryNotSet (40928) / ErrWorkflowNotFound (40430) / ErrWorkflowVersionNotFound (40431) / ErrWorkflowSchemaInvalid (40050) / ErrWorkflowSemanticInvalid (40051) / ErrWorkflowCompileFailed (40052) / ErrWorkflowNeedsCycle (40055) / ErrWorkflowSubflowCycle (40057) / ErrWorkflowSubflowDepthExceeded (40058) / ErrWorkflowExpressionInvalid (40059) / ErrWorkflowTemplateInvalid (40060) / ErrWorkflowCreationConfigConflict (40063, WF-T2: model_version_bid×pipeline_code 互斥/双缺・pipeline×character_bids 互斥) / ErrWorkflowCreationInLoopBody (40064, creation 节点禁入 loop/parallel body — 子分支 inline 丢挂起信号, 批量用节点级 batch) / ErrWorkflowCreationBatchInvalid (40065) / ErrWorkflowPromptRefInvalid (40066, FT-PRE-2: llm 节点 prompt_template_ref 结构/role 冲突/template 不存在或未发布/variables keys 超 schema) / ErrPublishGateRejected (40068, 治理 P2 发布硬门禁: safety.content_categories_blocked 空 / 聊天类 mode inline persona 或缺 system_prompt_ref / workflow persona 占位 >200 字符 / latest pin 解析失败 — 结构性前置失败拒绝发布, 修 definition 后重试)`

### creation (53)

> **`40876` ErrMVSongNotLocked · `40877` ErrMVPhotoExpired · `40878` ErrMVSongTooLong**(2026-09-28,ADR-043 `MVSubmitValidator`,
> 复用 4087x 段尾):音乐 → MV 管线提交期。40876 = `song_candidate_bid` 指向的候选未 save 成资产(D-5:MV 只能建在**已保存**的歌上,
> 候选 7 天会过期);40877 = 参考照片资产已过期;40878 = 歌曲 > 190 s(与 L4 模板 12 段 × 15 s + 10 s 尾量对齐)。
> 全部在冻结之前拒绝,零经济副作用。跨账号 / 不存在的候选仍是 `45400`(同码不泄漏存在性)。

> **`50325` ErrCancelSignalUnavailable**(2026-09-28,ADR-037):对 processing 的管线任务请求协作式取消时,信号存储(Redis)不可达。
> **这次取消没有发生**,如实返回让客户端重试 —— 不能返回成功(那会让用户以为已停、实际继续扣费跑完)。
> `POST /v1/tasks/:bid/cancel` 的成功响应带 `data.outcome = cancelled | cancel_requested`,见 `docs/api/creation.md`。

> **管线失败码(`error_code`,非 HTTP 码)新增 MV 族**(2026-09-28,`shared/failure` 登记表):`mv_storyboard_invalid` / `mv_keyframe_failed` /
> `mv_segment_render_failed`(平台侧,可重试)· `mv_no_capable_model`(平台侧,等待)· `mv_assemble_failed` / `mv_plan_uncoverable`(平台侧,联系客服)。
> 全部平台侧 → 结算按 D2 系统性失败全退。`user_cancelled` 现在也会出现在 **processing 中被取消的管线任务**上(ADR-037,D2 路径③按已完成权重分摊)。

> **`50324` ErrUploadRetentionUnavailable**(2026-09-25,ADR-025):分发声明了上传留存期,但 finalize
> 时读不到(配置库故障)或配置值非法 —— **fail-close**,资产仍是 pending,客户端稍后重试 finalize。
> 与 kill-switch 读失败放行的方向**相反**:留存期是对终端用户的承诺,读不到时放行 = 这批上传永久保存。

> **`45120` ErrReferenceImageRejected**(2026-09-25,ADR-030):管线模板声明了 `moderation.reference_images`,
> 提交期对确权后的参考图逐张做图片安全审核,某张被拦截。冻结之前拒绝,零经济副作用;对客固定 `reference image rejected`,
> 命中标签只进日志。审核器故障 / 未装配 → **放行**(与提示词审核 45100 同款 fail-open)。审核是否真正执行取决于
> config `safety.provider`(`noop` 时全放行;回滚矩阵 §3.2)。

> **`42924` ErrDailySubmitLimitReached**(2026-09-25,ADR-028):分发在 acfg `limits.daily_submits`
> 声明了按账号每日提交上限(键 = 管线模板码 / 模型码 / `*`,具体键优先),本账号当日(UTC)已用尽。
> 冻结之前拒绝,零经济副作用;UTC 次日自动恢复。幂等重放不计数,提交最终没受理成任务会把额度还回去。
> 读不到配置 / 计数存储故障 → **放行**(反滥用闸不是账务,与 kill-switch 同方向)。

> 冻结积分失败的三段式分流 (2026-06-08): 历史上 `FreezeCredits` 的任何失败都被映射为
> `ErrInsufficientCredits (40200 余额不足)`, 导致"钱包 balance 数据漂移 / 钱包停用 / 系统错误"
> 全部误报余额不足 (用户视角余额充足却被拒, 排障无从区分)。现按成因拆分:
> `ErrInsufficientCredits (40200)` = 真实余额不足 · `ErrWalletDataAnomaly (50231)` = balance
> 虚高于可扣口袋 (数据完整性漂移, 非用户责任, 需对账修复) · `ErrWalletUnavailable (50230)` =
> 钱包停用/其他系统错误。翻译链: wallet 域 sentinel → `creationPort.ErrFreeze*` (bridge) →
> creation 域错误 (`mapFreezeError`)。
>
> **钱包不存在归 40200 而非 50230 (2026-08-17 钱包生命周期整改, 契约变更)**:
> 个人钱包是 `(account_id, app_id)` 维度的**懒创建**行 —— 全仓唯一创建入口是充值到账
> (`CreditHandler.CreditWallet`), 注册 / 读面 / 冻结都不建。因此 `ErrWalletNotFound` ≡
> 该账号在此 app 维度尚无任何资金动作 ≡ 可用余额 0, 是**用户侧可行动**的余额不足 (去充值)。
> 整改前它与"钱包停用"合并成 50230 `wallet service temporarily unavailable, please retry` ——
> 新用户第一次提交任务就被告知"服务临时不可用请重试", 而重试永远不会成功: 既误导用户,
> 又把最普通的"没充过值"计入 5xx 污染告警。风控停用 (`ErrWalletDisabled`) 仍留 50230。
> 守卫: `internal/bootstrap/wallet_freeze_error_bridge_test.go`。
>
> **四个消费方 BC 口径统一**:creation(40200) · runtime(40200,新增 `ErrInsufficientCredits`,
> 此前一律 50040 "wallet freeze failed") · capability(40200 `insufficient_credits`) ·
> tool(`blocked: budget_exceeded`)。钱包停用另走各自的不可自助码
> (creation/capability 50230 · runtime 50040 · tool `blocked: wallet_unavailable`) ——
> 二者必须分开:提示被风控冻结的账号"去充值",充了依然用不了。

### 响应内容红线:内部 int64 绝不出现在对外文案(2026-08-17 审计)

**`message` / `error_message` / `blocked_reason` 一律只放固定英文语义,禁止拼接原始 error 或内部 ID。**

服务端为排障会在错误链里带内部维度(wallet 的 `account=%d app=%d`、仓储的 `tenant=%d` /
`capability_id=%d`、creation 的 `asset=%d` / `task %d` / `candidate %d`)。这些**只进 slog**;
任何把它们 `%v` 拼进响应的写法都违反「API 只暴露 bid」红线。已清理并加守卫的历史泄漏面:

| 面 | 泄漏内容 | 现状 |
|---|---|---|
| tool `ExecuteToolResult.ErrorMessage` | `account/app` int64 | 按 port 哨兵取固定文案 |
| capability `FinalErrorMessage`(invoke / invoke-stream / live-session 三出口) | `account/app`、`tenant` int64 | 固定文案 |
| creation `/prompt-assist`、`/intent-classify` | 透传 capability 上游 msg | `fallbackMsg` 语义反转为「固定文案优先」 |
| 6 BC `port/http/errors.go` 的 `return 50000, "internal error: "+err.Error()` | SQL 片段 / 内部路径 / 任意内部 ID | 5xx 只进 slog,响应固定文案 |
| creation `gen_generation_tasks.error_message`(任务详情 / 列表 / SSE snapshot) | `asset=%d` / `task %d` | `PublicTaskErrorMessage` 白名单收口 |
| creation 候选批量 `error_message` | `candidate %d` / `task_id=%d` | 按 status 取常量文案 |
| catalog 技能安装行、memory fact resolve | `workspace_id` / `installed_by_account_id` / `confirmed_by` | 改走 public mapper(*_bid) |
| runtime SSE `error` 帧 | provider 报文 / 内部错误链 | 固定文案 + slog |

守卫(CI 阻断):`tests/archtest/no_internal_id_leak_to_client_test.go` 三道
—— ①wallet 冻结错误必须在 bootstrap 桥翻译成消费方哨兵(治本,消费方结构上拿不到内部 ID)
· ②对外字段不得内嵌内部 ID 变量 · ③`port/http/errors.go` 的 5xx 分支不得回吐 `err.Error()`。
另有 `tests/archtest/catalog_public_dto_test.go` 守 public DTO 只用 `*_bid`。

> 4xx 校验类**保留**原始文案(那是调用方自己的输入,回传才能改对);只有 5xx 与数据字段收口。
>
> 计费 fail-open 收口 (Plan-Billing, 2026-06-12): **40201/40202 = 定价缺失/非法硬拒段**
> (`ErrModelPricingMissing 40201` 规则零命中 — 运维补行, 显式免费用 credit_cost=0 行 ·
> `ErrModelPricingInvalid 40202` 规则命中但 cost_unit 不支持等 — 运维改行)。
> **项目池计费双码 (ADR-016 D3, 2026-07-20)**: `40203` = 项目池余额不足 (Q2 红线: 不回落
> 个人钱包, 前端引导池管理员追加预算或改用个人计费) · `40332` = 项目池不可用/未授权
> (workspace 未开池 / 非活跃成员 / bid 无效 — 统一一码防 workspace 枚举)。
>
> 三码边界: 40200=余额不足(用户) / 40201=缺失(补行) / 40202=非法(改行); 基础设施错误
> fail-close → 50230。历史"fallback 静态价"(恒 0 → 免费执行) 已删除; capability 同语义
> (`pricing_missing`→40201 / `pricing_unavailable`→50230)。发布 gate:
> `scripts/deploy/check-pricing-coverage.sh`; runbook: `docs/ops/billing-pricing-coverage.md`。
>
> > 管线定价 strict 化 (2026-06-10): 管线 (`pipeline_code` 提交) 查无 `pipeline:{code}` 定价规则
> → `ErrPipelinePricingMissing (50830)` 硬拒绝, 不再 fail-open 免费执行 (媒体合成等 CPU 密集
> 管线免费放行即真实成本流失); 显式免费须用 `credit_cost=0` 规则行表达。
> **40800-40849 / 50830-50839 为媒体合成 (compose) 专属段**, 后续 compose 输入/spec 校验类
> 错误在 40810-40829 内分配。具体码 (2026-07-17 实证补记):
> `ErrComposeAssetNotFound (40810)` 引用 asset 不存在 / 不属当前账号 (**资产确权** — 不泄漏归属) ·
> `ErrComposeAssetNotReady (40811)` upload_state≠uploaded · `ErrComposeAssetNoDuration (40812)`
> 时长未回填 (MediaProbeWorker 滞后) · `ErrComposeAssetMediaMismatch (40813)` content_type 与用途不符 ·
> `ErrComposeSpecInvalid (40820)` **合成参数无效** (结构/枚举校验失败) ·
> `ErrComposeSpecLimitExceeded (40821)` 超限 (trim 越界 / 输出 >300s)。
> **5 条原子编辑管线** (video_trim/video_speed/video_filter/video_crop_frame/bg_fill) 归一为
> compose spec 后**复用同组校验器**, 故 `source_asset_bid` 确权失败返 **40810**、管线 params
> (keep/speed/filter/crop_frame/color) 非法返 **40820**; 参数格式错 (假 bid / 枚举外值) 在
> validator 前置返 **40001** (ErrInvalidParam)。
>
> 免确认阈值段 (PRD §7.1, 2026-07-17): `ErrAutoConfirmNotAllowed (40952)` — `confirmation.mode=auto`
> 声明被服务端拒 (预估超客户端阈值 / 阈值超硬上限 50 / 视频生成一律确认); 客户端收到应回退弹确认卡
> 以 `mode=confirmed` 重提。**注: 40950 已被 tool BC `ErrToolNotInstalled` 占用, auto-confirm 用 40952**。
>
> 音频任务段 (Plan-Audio ST6, 2026-06-10): **40830-40849 = creation 媒体输入校验**
> (原名"音频输入校验", 2026-09-15 通用化为媒体输入 —— 判据本就与模态无关)
> (`ErrAudioAssetNotFound 40830 / ErrAudioAssetNotReady 40831 / ErrAudioAssetNoDuration 40832 /
> ErrAudioAssetMediaMismatch 40833 / ErrAudioInputTooLong 40834` — ASR 专用, 哨兵名带 audio
> 已进对客契约不改名);
> provider 侧新增 `ErrVoiceNotAvailable (40362)` / `ErrAudioFormatUnsupported (40363)`。
>
> 媒体引用校验 (2026-09-15, 40830-40849 段的通用化扩展): 任何模型的任何媒体输入参数
> (`reference_images/videos/audios` · `first/last_frame_image` · `media` · `source_video` …)
> 由 **MediaReferenceValidator** 按模型 `param_schema` 的媒体声明在**提交期**统一校验
> (冻结积分之前, 零经济副作用):
> `ErrMediaRefNotFound (40835)` 素材不存在**或不属于当前账号** — 同码同文案不泄漏存在性;
> 亦用于"字段声明了时长约束但取值不可反查成平台素材"(data: URI / 外部 URL) ·
> `ErrMediaRefNotReady (40836)` upload_state != uploaded ·
> `ErrMediaRefMetadataPending (40837)` 需判时长但 duration_seconds=0 (MediaProbeWorker 未回填)
> —— **可重试**语义, 不是素材非法 ·
> `ErrMediaRefTypeMismatch (40838)` MIME 不在字段 `accept` 白名单内 ·
> `ErrMediaRefDurationOutOfRange (40839)` 时长超出字段/角色声明的
> `max_duration_seconds`/`min_duration_seconds` 值域。
> 体积超限复用 `ErrFileSizeExceeded (40035)`; 竞品素材复用 `ErrCompetitorAssetRestricted (40336)`。
> 客户端可据 `GET /v1/models` 返回的 `x-max-duration-seconds` / `x-min-duration-seconds`
> 在**提交前**预检, 不必等 400。
>
> 迭代谱系段 (Plan-Lineage v1, 2026-06-12): **40870-40879 = creation 派生谱系**:
> `ErrDerivationTypeInvalid (40870)` 派生类型未注册 (DerivationTypeRegistry, W1 注册即生效) ·
> `ErrDerivationLimitExceeded (40871)` 深度 >32 / 单树 >500 写侧硬卡 ·
> `ErrDerivationSourceNotFound (40872)` 派生源不存在**或跨账号/跨租户 — 同码同文案不泄漏存在性** ·
> `ErrDerivationSourceMismatch (40873)` 类型×源矩阵违例 (candidate⊕asset 互斥 / model_switch 未换模型 /
> shot_regen 父无 workflow_context / 候选不属父任务 / fanout 子任务作父) ·
> `ErrDerivationSourceState (40874)` 源状态不可用 (v1=discarded 候选; expired 放行作信息性引用 — D7 墓碑)。
>
> EchoNote 平台批 (2026-08-26): `ErrSubmissionDisabled (50831)` 运营 kill-switch 命中
> (acfg kill_switches 码约定 `submit:<task_type>` / `submit:<model_code>` /
> `submit:pipeline[:<template>]`, 服务端提交准入, 503 语义; 恢复=删开关码) ·
> `ErrTooManyInflightUploads (40932)` 单账户在途 multipart 会话超上限
> (acfg `upload_limits.max_inflight_uploads`, DB pending 行计数为唯一事实源, 429 语义) ·
> 40035/40834 复用: acfg 按档字节/时长上限与 policy/编译期硬顶同哨兵 (客户端无需区分是哪层拒的)。
>
> 主体库段 (Plan-Subject T4, 2026-06-10): **40850-40869 = creation 主体 (Subject ≡ Character) 一致性**:
> `ErrSubjectRefLimitExceeded (40850)` 主体参考集超上限 / 注入裁剪后仍超模型约束 ·
> `ErrSubjectInjectExclusive (40851)` 注入目标字段与用户已占用互斥键冲突 ·
> `ErrAssetReferencedBySubject (40852)` 资产被未删主体锚定, 丢弃/归档被拦截 (409 语义, 先解绑;
> AssetCleanupWorker 对应路径为 skip+warn 保活) · `ErrSubjectPhotoRejected (40853)` 参考图未过
> 内容审核 (D7 挂载点, Safety Noop 现状放行) · `ErrCharacterAssetNotUploaded (40854)` 锚定仅收
> `upload_state=uploaded` 且非 TTL 候选 (R3/R11)。
>
> 竞品素材拆解段 (Plan-M1 material_analysis_v1, 2026-06-13): **40470-40479 = creation 拆解报告**:
> `ErrAnalysisReportNotFound (40470)` 报告不存在 / 跨账号越权 (同码不泄漏存在性) ·
> `ErrAnalysisMaterialInvalid (40471)` 素材不可拆解 (不存在 / 不属当前账号 / 未完成上传 / 非视频, GET 详情态机非 completed 复用此码) ·
> `ErrAnalysisDeriveKindInvalid (40472)` derive kind 非法 (仅 reverse_prompt / replication_plan)。
> 合规红线 R7 跨段: `ErrCompetitorAssetRestricted (40336)` 竞品导入素材 (`asset_source='competitor_import'`)
> 禁入分发/生成输入链路 (compose/asr submit validator 提交期硬拒, 403 授权段)。
> 拆解步骤内部信号 (不外漏客户端, 经 Orchestrator RetryPolicy 重跑 step4): `ErrAnalysisSchemaInvalid` (结构/枚举违例) /
> `ErrAnalysisSemanticInvalid` (Σpercent / 分镜时序 / 越界违例); 管线终态失败统一记报告 `status=failed`。
> 拆解管线计费走 `pipeline:material_analysis_v1` (缺价 50830) + derive 走 capability (缺价 40201)。
>
> media role 级校验段 (2026-08-09 实证补记): `media_array` 元素按模型 schema `x-roles` 服务端强制
> (词表 / 每角色 `max_items` / `accept` MIME, provider `validateMediaArrayRoles`, 冻结之前)。
> **`ErrInvalidParam` 的呈现按端点分两种**: `POST /v1/tasks` 端点特化返 **40001** ValidationFailed
> + `details.params` 逐项明细; 走通用 `GetErrorCode` 的面 (如 `/v1/tasks/estimate`) 返 **40033**
> 无字段明细。起因: 客户端 3 图全标 `first_frame` 此前会通过冻结直到上游终态拒绝
> (DashScope `Multiple first_frame items are not allowed`), 现创建期即拒、零经济副作用。

`ErrTaskNotFound (40420) / ErrInvalidStatusTransition (40920) / ErrDuplicateIdempotencyKey (40921) / ErrInsufficientCredits (40200) / ErrWalletDataAnomaly (50231) / ErrWalletUnavailable (50230) / ErrPipelinePricingMissing (50830) / ErrInvalidParam (40033) / ErrPromptRejected (45100) / ErrUnsupportedMimeType (40034) / ErrFileSizeExceeded (40035) / ErrUploadNotPending (40922) / ErrInvalidFileHash (40037) / ErrUploadSizeMismatch (40038) / ErrInvalidQuantity (40036) / ErrProjectNotFound (40440) / ErrInvalidProjectStatus (40930) / ErrProjectAccessDenied (40330) / ErrAlreadyMember (40931) / ErrCandidateNotFound (45400) / ErrCandidateNotReady (45901) / ErrCandidateAlreadySelected (45902) / ErrCandidateExpired (45903) / ErrCandidateAlreadyDiscarded (45904) / ErrCandidateModerationPending (45905) / ErrCandidateModerationRejected (45906) / ErrSubjectRefLimitExceeded (40850) / ErrSubjectInjectExclusive (40851) / ErrAssetReferencedBySubject (40852) / ErrSubjectPhotoRejected (40853) / ErrCharacterAssetNotUploaded (40854) / ErrDerivationTypeInvalid (40870) / ErrDerivationLimitExceeded (40871) / ErrDerivationSourceNotFound (40872) / ErrDerivationSourceMismatch (40873) / ErrDerivationSourceState (40874) / ErrModelPricingMissing (40201) / ErrModelPricingInvalid (40202) / ErrAnalysisReportNotFound (40470) / ErrAnalysisMaterialInvalid (40471) / ErrAnalysisDeriveKindInvalid (40472) / ErrCompetitorAssetRestricted (40336) + 11 more`

### iam (7)

`ErrNotFound / ErrPermissionDenied / ErrTenantMismatch / ErrVersionConflict / ErrDuplicateRole / ErrPermissionCodeInvalid / ErrPermissionNotRegistered / ErrRoleNotFound / ErrInvalidPrincipal`

### iap (16)

`ErrAppNotFound (40402) / ErrAppDisabled (40304) / ErrDistributionNotFound (40403) / ErrDistributionDisabled (40305) / ErrProductNotFound (40404) / ErrProductInactive (40306) / ErrOrderNotFound (40405) / ErrOrderNotPending (40010) / ErrOrderAlreadyExists (40011) / ErrReceiptInvalid (40012) / ErrReceiptExpired (40013) / ErrSubscriptionExpired (40014) / ErrStoreUnavailable (50301) / ErrSignatureInvalid (40015) / ErrAccountMismatch / ErrNotificationInvalid`

> 订单 verify 并发收口 (2026-06-13): **`ErrOrderVerifying (40016)` = verify 并发在途的可重试态**
> —— 同一 order_no 已有 verify 在处理 (持分布式串行锁), 后到的并发请求返 40016 让客户端**退避重试**,
> 区别于 `ErrOrderNotPending (40010)` 的终态硬拒。根因: verify 把订单瞬时置 `verifying` 等 Apple
> 回包 (~0.7s), 期间并发重复请求旧逻辑误报 40010; 现以 `OrderLock`(redis SET NX EX)串行化 +
> `CanVerify` 放行锁内 `verifying`(卡死自愈) + `store_transaction_id`/钱包 SourceRef 幂等防重发放。
> 客户端应对 40010/40016 均按"处理中"退避重试或转查订单状态, 不直接报购买失败。

> **`50304` ErrGrantConfigInvalid**(2026-09-25,ADR-029):商品 `grant_config.storefront_tiers` 不合法
> (档内未知键 / 国家重复 / 非正整数额度等)。建单即拒;verify / 续费遇到则**不发放**且不落任何状态
> (订单留 `verifying` / 通知返错由 Apple 重投), 运维修正商品后自动恢复 —— 不按错误的档发钱。
> 对客文案固定 `product is temporarily unavailable`(配置细节只进日志)。

### identity (12)

`ErrInvalidPassword (40101) / ErrAccountNotFound (40401) / ErrAccountLocked (40301) / ErrSessionNotFound (40105) / ErrTokenRevoked (40104) / ErrTooManyAttempts (42901) / ErrPasswordTooWeak (40002) / ErrAppNotFound (40402) / ErrDeviceRateLimited (42902) / ErrAppDisabled (40304) / ErrGuestAccountExists / ErrInvalidParam (40003)`

> **`40140` ErrDeviceAttestationFailed**(2026-09-25,ADR-026):分发 acfg `attest.mode=required` 时 guest-register 的
> App Attest 证据缺失 / `unsupported` / 校验失败,或分发未登记 `apple_team_id`(配置错误同码)。不建号、不签令牌;
> 对客文案固定 `device attestation failed`,具体原因只进日志。`optional` / `off` 档永不产生此码。

> **`40917` ErrEntitlementClaimConflict**(2026-09-25,ADR-027):`POST /v1/auth/claim-entitlement` 的业务冲突 ——
> 申请者有付费历史(不自动合并钱包)· 目标账号不是游客或已注销 · 当前设备不属于申请者。对客固定 `entitlement claim conflict`。

### integration (6)

`ErrNotFound / ErrPermissionDenied / ErrTenantMismatch / ErrVersionConflict / ErrWebhookDelivery / ErrOAuthUnauthorized`

### knowledge (17)

`ErrKnowledgeBaseNotFound (40430) / ErrDocumentNotFound (40431) / ErrDocumentOperationNotFound (40432) / ErrKnowledgeBaseAccessDenied (40330) / ErrInvalidKnowledgeBaseConfig (40030) / ErrInvalidMetadataSchema (40031) / ErrMetadataValidationFailed (40032) / ErrInvalidMetadataFilter (40033) / ErrInvalidChunkingPolicy (40034) / ErrInvalidDocumentSource (40035) / ErrKBNameDuplicate (40930) / ErrKBStateTransition (40931) / ErrDocStateTransition (40932) / ErrQuotaExceeded (42930) / ErrSingleFileTooLarge (42931) / ErrCapabilityUnsupported (50032) / ErrUpstreamTransient (50230)`

### memory (20) ⭐ 46000-46099 + 46301

`ErrSpaceNotFound (46001) / ErrFactNotFound (46002) / ErrSpaceArchived (46003) / ErrFactKeyConflict (46004) / ErrFactLimitExceeded (46005) / ErrInvalidCategory (46006) / ErrInvalidConfidence (46007) / ErrSummarizationFailed (46008) / ErrConsolidationFailed (46009) / ErrKBCreationFailed (46010) / ErrPurgeNotEmpty (46011) / ErrOwnerTypeMismatch (46012) / ErrInvalidArgument (46013) / ErrInvalidFactKey (46014) / ErrInvalidOwnerType (46015) / ErrInvalidSourceType (46016) / ErrSourcePrecedenceViolation (46017) / ErrInvalidConsolidationState (46018) / ErrConversationMismatch (46019) / ErrPermissionDenied (46301)`

### observability (5)

`ErrNotFound / ErrPermissionDenied / ErrTenantMismatch / ErrVersionConflict / ErrInvalidRule`

### prompt (24) ⭐ 45000-45099

`ErrTemplateNotFound (45001) / ErrVersionNotFound (45002) / ErrSlugConflict (45003) / ErrTemplateArchived (45004) / ErrVersionImmutable (45005) / ErrVersionNumberConflict (45006) / ErrContentHashDuplicate (45007) / ErrVariableSchemaInvalid (45008) / ErrTemplateBodyTooLarge (45009) / ErrTemplateBodySyntax (45010) / ErrRenderTimeout (45011) / ErrMissingRequiredVariable (45012) / ErrUndeclaredVariable (45013) / ErrVersionNotPublished (45014) / ErrRollbackTargetInvalid (45015) / ErrTemplateRefInvalid (45016) / ErrWorkspaceMismatch (45017) / ErrAutoInjectUnknown (45018) / ErrReservedVariableName (45019) / ErrTemplateSlugInvalid (45020) / ErrEnumInvalid (45021) / ErrInvalidArgument (45022) / ErrTemplateDeprecated (45023) / ErrVersionConflict (45024)`

### provider (13)

`ErrProviderNotFound / ErrProviderDisabled (40310) / ErrProviderMaintenance (40311) / ErrChannelNotFound (40410) / ErrChannelDisabled (40310) / ErrChannelExpired (40312) / ErrNoAvailableChannel (40313) / ErrModelNotFound (40410) / ErrModelOffline (40310) / ErrVersionDeprecated (40314) / ErrQuotaExhausted (42910) / ErrInvalidParam (40010) / ErrUpstreamFailed (50210) / ErrContentFiltered (45110)`

> **实时语音会话(2026-08-20 新增 3 码)**:`42923` 并发会话超限(成本闸 —— 一条会话
> 就是一条真实计费的上游长连接)· `50322` 语音面未开启或配置不完整(**不区分**这两者
> 对外暴露:对客户端是同一件事 —— 现在拨不通且重试没用)· `50323` 依赖不可用(钱包/DB/
> Redis/上游,可重试)。余额不足沿用四 BC 统一的 `40200`,会话不存在沿用 `40430`。
>
> ⚠️ 该端点是 WebSocket 握手,**回真实 HTTP 状态码**(401/402/404/429/503)而非
> 200 + 信封码 —— WS 客户端在握手阶段读的是状态行,拿不到也不会去解析 JSON 信封。
> 信封仍照发,便于 curl 排查时看到与其余端点一致的结构。映射见
> `internal/runtime/port/http/live_handler.go::mapLiveAdmitError`(哨兵 → 固定英文文案,
> 零 `err.Error()` 拼接)。
>
> **拨号前预检 `GET /v1/live/quote`(2026-08-24)**:普通 REST 面,恒 200 + 标准信封。
> 确定性结论(余额不足/面未开启/定价缺行)是 `data.available/reason` **状态**而非错误码。
> 主用途 = T0 费用展示数据源(单价拨号前唯一可查面);判因**兜底**(同日勘误:客户端
> 实测握手栈可直读 402/40200,判因首选直读,契约 §3.1)。仅基础设施故障回
> `50323`(可重试,客户端**不得**据此弹购买)。

### runtime (18)

`ErrConversationNotFound (40430) / ErrMessageNotFound (40431) / ErrRunNotFound (40432) / ErrPersonaStyleNotFound (40433, 人设 B 段风格 ref 不可用: 不存在/已归档/无已发布版本/类型不是 persona_style —— 四种成因同码, 客户端补救动作相同: 清本地已选风格 → 重拉目录 → 用默认风格重试) / ErrPersonaStyleNotAccepted (40938, 该 Agent 未声明 persona.style_slot 不接受运行期风格 —— 与 40433 分开是因为重拉目录无效, 客户端应对该 Agent 隐藏风格选择器并上报) / ErrConversationEnded (40934) / ErrConversationAgentRequired (40935) / ErrMessageEmpty (40040) / ErrRunTerminated (40930) / ErrRunNotActive (40931) / ErrRunNotAwaitingHuman (40932) / ErrInvalidStateTransition (40933) / ErrInvalidExecutionMode (40041) / ErrStepIdempotencyConflict (40936) / ErrWorkflowVariablesInvalid (40043, FT-PRE-1: SendMessage.variables 未声明 key/类型不匹配/required 缺失/总量超 512KB/非 workflow 模式携带) / ErrPremiumFeatureRequired (40303, FT-6: agent feature_flags.required_feature 权益未持有, Freeze 前拒) / ErrReconciliationNotFound / ErrReconciliationAlreadyResolved / ErrWalletFreezeFailed (50040)`

**M-C 计划契约链(D-003,2026-08-29 新增 7 码;号段核对:404xx 已用 40401/40420-40422/40430-40433,409xx 已用 40901/40930-40939,400xx 已用 40040-40043/40045 —— 新码均落空位)**:
`ErrPlanNotFound (40434, 不存在/bid 非法/他人计划 —— 归属不通过按不存在处理, 不泄漏存在性) /
ErrPlanCyclicDependency (40044, 建稿步骤依赖必须指向更小且存在的步骤号; 拓扑编号即结构性无环, DB 端 ck_pln_dep_topo 同义兜底) /
ErrPlanVersionConflict (40940, 确认与修订并发 CAS 落败 —— 客户端重拉计划卡后重试) /
ErrQuoteNotAcceptable (40941, 报价已过期/已被重报价 superseded/已接受/与计划不匹配 —— 重新请求报价) /
ErrPlanConfirmPrecond (40942, **成本前置铁律**: confirm 需已接受报价 ∧ 预算信封已开) /
ErrPlanTerminal (40943) / ErrPlanInvalidTransition (40944) /
ErrSelfApprovalForbidden (40946, M-G/G2 职责分离: 请求者不得批准自己的请求 —— **换一个人来批**, 流程问题) /
ErrApproverListRequired (40947, M-G/G2: 该审批未声明审批人名单 —— 名单为空时「任何持角色者可批」会兜底到请求者本人, 分离形同虚设; **在 DSL/审批单里声明名单**, 配置问题。与 40946 分开是因为补救动作不同) /
ErrPlanStepInFlight (40945, M-D/K4 修订前置: 有步骤在途不得修订 —— 修订要结旧信封, 而在途步骤的用量尚未落库, 此刻结账等于白送那部分工作。处置: 先取消该步 run 或等它终态, 再 revise。**时序性拒绝**, 原样重试恒失败)`

### safety (4)

`ErrContentBlocked / ErrPromptRejected / ErrOutputRejected / ErrReviewTimeout`

### showcase (15) ⭐ 47000-47099 + 47301

`ErrShowcaseNotFound (47001) / ErrCategoryNotFound (47002) / ErrTagNotFound (47003) / ErrShowcaseArchived (47004) / ErrInvalidStatusTransition (47005) / ErrVersionConflict (47006) / ErrPresetPrimaryDuplicate (47007) / ErrInvalidPresetParams (47008) / ErrEntityTypeMismatch (47009) / ErrI18nLangDuplicate (47010) / ErrI18nRequired (47011) / ErrPresetModelRequired (47012) / ErrInvalidParam (47013) / ErrPermissionDenied (47301) / ErrTenantMismatch (47301)`

### tenancy (23)

`ErrNotFound (40401) / ErrPermissionDenied (40301) / ErrVersionConflict (40901) / ErrAlreadyMember (40902) / ErrSlugConflict (40903) / ErrDefaultWorkspaceExists (40904) / ErrOrganizationDeleted (40905) / ErrInvalidStatusTransition (40906) / ErrMembershipInTerminalStatus (40907) / ErrInvitationInvalid (40908) / ErrInvitationExpired (40909) / ErrInvitationExhausted (40910) / ErrIsolationChangeStateInvalid (40911) / ErrIsolationLevelTransitionInvalid (40912) / ErrCannotRemoveLastOwner (40303) / ErrSlugInvalid (40033) / ErrSlugReserved (40034) / ErrRoleUnknown (40035) / ErrIsolationLevelInvalid (40036) / ErrInvitationEmailRequired (40037) / ErrInvitationMaxUsesInvalid (40038) / ErrInvitationMismatchedEmail (40039) / ErrAccountNotFound / ErrTenantMismatch (40302)`

### tool (26)

`ErrToolNotFound (40440) / ErrVersionNotFound (40441) / ErrInstallationNotFound (40442) / ErrToolCodeConflict (40940) / ErrToolSlugConflict (40941) / ErrToolArchived (40942) / ErrToolCodeInvalid (40060) / ErrToolSlugInvalid (40061) / ErrToolDefinitionInvalid (40062) / ErrCapabilityFlagInvalid (40063) / ErrPricingNegative (40064) / ErrVersionNotApproved (40944) / ErrVersionAlreadyReviewed (40945) / ErrAlreadyInstalled (40946) / ErrInvalidReviewTransition (40947) / ErrInvalidInstallTransition (40948) / ErrToolDisabled (40949) / ErrToolNotInstalled (40950) / ErrToolExecutionBlocked (40951) + more`

### wallet (4)

`ErrWalletNotFound / ErrWalletDisabled / ErrInsufficientFunds / ErrFeatureExists`

---

## 四、段位约定

- `40x` 为客户端错误,HTTP status 对齐 4xx;`50x` 为服务端,对齐 5xx
- 中间 2 位粗分领域(`00`=通用 / `01`=auth / `30`=validation / `41`=auth-token / ...)
- 末 2 位精确事件,**永不复用**(下线码也不重用,避免客户端缓存命中错语义)
- **专属 BC 段**(45xxx prompt / 46xxx memory / 47xxx showcase)互不冲突;新 BC 若需独立段优先选 48xxx 起

---

## 五、Domain → HTTP 映射

各模块在 `internal/<bc>/domain/errors.go` 定义 `var Err* = ...`,通过 `GetErrorCode(err) int` 映射到上表 code。

新增 domain 错误流程:
1. `domain/errors.go` 添 `var ErrNewKind = errors.New("...")`
2. `domain/error_codes.go` 在 `errorCodeMap` 表添映射
3. 测试在 `domain/errors_test.go` 加 case 覆盖
4. HTTP 层 `port/http/errors.go::mapDomainErr` 同步加 case

---

## 六、中间件统一 wrap

`internal/platform/httpserver/response/error.go` 的 `Error(c, ctx, code, msg)` 是唯一 4xx/5xx 出口。

```go
// ✗ 禁止 — 绕过 wrap 失去 request_id + timestamp
ctx.JSON(http.StatusBadRequest, ...)

// ✓ 统一
response.Error(c, ctx, code, msg)
```

---

## 七、跨 BC 防冲突表

新 BC 接入前查此表,避免段位冲突:

| 段位 | 已占用 BC |
|---|---|
| 40000-40099 | 通用 validation(各 BC 共享)|
| 40100-40199 | 401 auth(identity)|
| 40200-40299 | 402 payment(creation insufficient credits)|
| 40300-40399 | 403 forbidden(各 BC)|
| 40400-40499 | 404 not found(各 BC)|
| 40900-40999 | 409 conflict(各 BC,版本/状态)|
| 42900-42999 | 429 rate limit(identity / provider / knowledge / creation 42920-42921 · 42924;runtime 42922-42923)|
| **45000-45099** | **prompt 专属** ⭐ |
| 45300-45399 | prompt permission(45301,与 46301/47301 同模式)|
| 45100-45199 | 451 content(creation/provider/safety;45100 提示词审核 · 45110 上游内容过滤 · 45120 参考图审核)|
| 45400-45499 | candidate 段(creation P7)|
| 45900-45999 | candidate 状态机段(creation P7)|
| **46000-46099** | **memory 专属** ⭐ |
| 46300-46399 | memory permission(46301)|
| **47000-47099** | **showcase 专属** ⭐(Catalog BC 扩展)|
| 47300-47399 | showcase permission(47301)|
| **48000-48099** | **fashiondress 专属** ⭐(潮流换装,**已迁出** genaistudio-products;明细见产品仓 `docs/api/fashiondress.md`)|
| **48100-48199** | **feastly 专属** ⭐(锋味十足,genaistudio-products 产品仓;明细 `genaistudio-products/docs/api/feastly.md`)|
| **48200-48849** | **genaistudio-growth 增长仓段块**(2026-07-24 登记;明细 `genaistudio-growth/docs/api/overview.md`):48200-48299 ads 投放 / 48300-48399 crt 素材 / 48400-48499 trk 追踪 / 48500-48599 atr 归因 / 48600-48699 cvr 转化 / 48700-48799 mtr 指标 / 48800-48849 growth shared(ingest/inbound)|
| **48850-48949** | **promotion 专属**(genaistudio-products;明细 `genaistudio-products/docs/api/promotion.md`)|
| **48950-48989** | **feedback 专属**(genaistudio-products;明细 `.../docs/api/feedback.md`)|
| **48990-48994** | ⛔ **已退役, 勿复用**(原 consultation 专属, genaistudio-products;该 BC 2026-08-23 整体退役 —— 人工语音咨询师功能从未立项、目录数据从未存在。段不释放:旧客户端可能仍按原义处理这些码。表前缀 `csl_` 同批退役同样不释放。裁决见产品仓 `docs/migrations/20260823_consultation_retire.sql` 头注释)|
| **48995-48999** | **divination 专属**(genaistudio-products;明细 `.../docs/api/divination.md`)|
| ⛔ **48xxx 已用尽** | 上面五段封顶后 48000-48999 **无连续可用区间** —— 新 BC 请从 49xxx 取段并先查下方 49xxx 行 |

> **⚠️ 5xx 段同样需要登记。** 2026-08-21 发现 genaistudio-products 自造了 `50301`
> (JWT 黑名单 Redis 不可达)而该码平台已占用(iap 商店上游)—— 两边都是 503,
> **不会有任何类型错误**,但客户端按码分支会把两件事混为一谈,监控按码聚合也会混。
>
> 此前只有 4xx 的 48xxx 段做了外部仓登记,5xx 没有 —— 于是外部仓「从空段里挑一个」
> 时无从知道哪些已被占用。上表因此把 50300-50399 也做了分段。
> **新增 5xx 码的外部仓请从自己的段块内取,并在此登记。**
| **49000-49099** | **echonote 听语 专属**(genaistudio-products,2026-08-19 交付 26 码;明细 `.../docs/api/echonote.md`)|
| **49100-49149** | **notification 移动推送 专属**(平台自用,2026-09-20 登记;明细见下方「49100 段 · 移动推送」)|
| ⚠️ 49100-49199 | **已知撞段(2026-09-24 勘察登记)**:genaistudio-products `songcraft` 自 2026-09-08 起在代码中占用 49100-49199(产品仓 `CLAUDE.md:670`),早于本表 49100-49149 的 notification 登记。两边都是 4xx 业务码,**客户端按码分支会串义**。裁决:notification 段保持不动(平台已发布客户端契约);songcraft 迁段属产品仓议题(须双端客户端同步),在其迁段前**任何新 BC 禁取 49100-49299**。|
| **49300-49349** | **songlet 小曲 专属**(genaistudio-products,2026-09-24 登记;明细 `docs/contracts/songlet/04-errors.md`;2026-09-28 阶段二 MV 占 49312-49316)|
| 49900 | **平台内部占用,勿取** —— `codeCanceled` 调用方主动取消 / ctx 取消(`capability/port/http/invoke_handler.go:27` · `creation/port/http/prompt_assist_handler.go:236`)|
| 50000-50099 | 500 internal |
| 50200-50299 | 502 upstream(provider / knowledge)|
| **50300-50349** | 503 service unavailable · **平台自用**(50301 iap 商店上游 / **50302 钱包台账依赖不可达 — free-quota claim, 听语 P-6 2026-08-18**)|
| **50350-50379** | 503 · **genaistudio-products 段块**(2026-08-21 登记)—— 产品仓的依赖不可达类。明细 `genaistudio-products/docs/api/overview.md` |
| 50360 | 503 · **songlet**(产品仓段块内):平台上游不可达 / 熔断开。`POST /v1/generate` 以 HTTP 200 + 50360 返回(防客户端对 5xx 重发 POST)|
| **50380-50399** | 503 · **genaistudio-growth 段块**(2026-08-21 预留,与 48200-48849 同仓)|
| 50400-50499 | 504 timeout(provider)|

> **49xxx 现状(2026-09-24 更新)**:平台自身在 49xxx 段占用 **49100-49149**(移动推送)
> 与 **49900**(内部取消);产品仓占用 49000-49099(echonote)、49100-49199(songcraft,撞段见上)、
> 49300-49349(songlet)。新 BC 从 **49350 起**选,且先查本表。

### 49100 段 · 移动推送(notification BC)

客户端面只有端点上报与偏好两类,所以码也只有这两类 —— 管理面(凭证 / 规则 / 模板)
按组织红线**不开 HTTP**,只暴露 `NotificationAPI` 方法,因此不占码。

| 码 | HTTP | 对外语义(固定英文) | 什么时候出现 |
|---|---|---|---|
| 49101 | 400 | `push environment mismatch` | 客户端自报的推送环境与该分发已配置凭证的环境无交集 |
| 49102 | 400 | `bundle identifier mismatch` | 客户端自报 bundle 与分发解析值不一致。**这是配置事故的早期信号**,不是普通业务拒绝 —— 同时告警 |
| 49103 | 400 | `device token invalid` | 设备令牌非十六进制 / 超出上限保护。**不做长度断言**(厂商明示令牌长度可变)|
| 49104 | 400 | `notification category unknown` | 偏好更新里的类目不在 transactional / system / marketing 之内 |
| 49105 | 400 | `consent evidence incomplete` | 表态为「同意」但没给界面标识或文案版本 —— 合规举证要能回答「他当时看到的是哪一版」|
| 49106 | 404 | `push endpoint not found` | 解绑一个不存在的端点(**注意**:登出是幂等动作,正常路径返回 0 而非此码)|

> ⚠️ 对外文案**只放上表的固定英文语义**。账户 id / 端点 id / 规则 id 等内部维度
> 只进结构化日志 —— 守卫 `no_internal_id_leak_to_client_test`。
>
> **⚠️ `49552` 是误报,不予登记** —— 跨仓交接件曾要求把它登记为「平台内部占用」,
> 核实后该数字在全仓的**唯一**出现是 `internal/tool/infra/ephemeris/astro.go:102`
> 的 `const kappa = 20.49552 * arcsec`(光行差常数,浮点字面量的小数部分),
> **不是错误码**。把它登记成占用会平白冻结 49500-49599 整段。
> 教训沉淀:核占用请用带词边界的检索(`rg '\b49552\b'` 仍会命中该浮点数,
> 需再确认命中处是否真是错误码常量),不要仅凭裸数字匹配下结论。

---

## 八、总览索引

- 完整端点 + 错误码示例:`docs/api/endpoint-inventory.md`
- API 信封 + 通用规范:`docs/api/overview.md`
- BC 各 API 详细:`docs/api/<bc>.md`
- HTTP 测试样例:`docs/api/http-requests/*.http`
