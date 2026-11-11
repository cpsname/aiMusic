# Creation BC API 参考

> 设计:`internal/creation/api.go` + `port/http/`
> 同步/异步链路设计:[pipeline-api.md](../architecture/creation/pipeline-api.md)
> Provider 路由:[provider-param-schema.md](provider-param-schema.md)

Creation BC 负责 AI 生成任务的全生命周期(text/image/video),核心聚合 `GenerationTask` 含两条路径:**sync**(直接 Execute 返结果)和 **async**(Redis Stream 队列 + Worker 消费 + 内部回调)。

路径前缀 `/v1`。除 `/internal/tasks/:bid/complete` 外全 JWT 鉴权。

## 任务提交

### POST /v1/tasks/estimate
积分预估(不冻结、不扣费)。

```json
{
  "model_version_bid": "...",
  "params": {
    "prompt": "...",
    "aspect_ratio": "16:9",
    "duration_sec": 8
  },
  "preset_code": "veo3-fast-default"   // 可选, 走 ProviderPreset 默认参数
}
```

返:
```json
{
  "credits": 800,
  "unit_cost": 100,
  "unit": "per_second",
  "quantity": 8,
  "breakdown": "8s × 100 credits/s = 800 credits",
  "applied_tier": "premium"
}
```

`unit` 可能值:`per_request` / `per_second` / `per_1k_tokens` / `per_megapixel`。

`applied_tier` 给前端显示"会员价"用。

### POST /v1/tasks
提交任务。**P6-02 起永远返 HTTP 202 + poll_url**,无论 model 同步或异步。
sync model 不再 inline 长持 HTTP — 任务在 worker 端执行,客户端轮询 GET /v1/tasks/:bid 拿终态。

```json
{
  "model_version_bid": "...",
  "params": { ... },
  "preset_code": "...",
  "idempotency_key": "client-uuid-1",  // 可选, 防重复提交
  "derivation": {                       // 可选 (Plan-Lineage v1): 派生声明 — 见下方「迭代谱系」章
    "derived_from_task_bid": "...",     //   必填: 谱系主父任务 bid (同账号同租户, 否则 40872)
    "type": "param_adjust",             //   必填: rerun/param_adjust/model_switch/shot_regen
    "source_candidate_bid": "..."       //   可选: 基于父任务哪个候选 (信息性; 与 source_asset_bid 互斥)
  },
  "source_showcase_bid": "...",         // 可选 (D6): "制作同款"来源 showcase 卡 bid — provenance
                                        //   弱标记 (运营归因), 非谱系边; 无效值忽略不拒提交 (fail-open)
  "intent_ref": "..."                   // 可选 (ADR-015 D5): classify 响应回显的对账句柄 —
                                        //   服务端推导修正回流信号; 无效值静默忽略, 决不影响提交
}
```

派生任务的响应 `data` 增量回带谱系定位:`"derivation": {"root_task_bid": "...", "depth": 3}`。

**`params.prompt_template` 字段(Phase 3 GAP-P3-002,任务级提示词预设)**

客户端可在 `params` 中传 `prompt_template`(模板编码,如 `code_generator`)+ `variables`(嵌套 map,作为模板变量),由服务端经 `prompt.PromptAPI.RenderInline` 渲染后注入 `params.prompt`。详细分层定位见 [audit-prompt-template-overlap.md](../architecture/audit/audit-prompt-template-overlap.md)。

```json
{
  "model_version_bid": "gpt-4o-mini-v1",
  "params": {
    "prompt_template": "code_generator",
    "variables": {"language": "Go", "requirement": "写一个快速排序"},
    "temperature": 0.7,
    "n": 1
  },
  "idempotency_key": "client-uuid-1"
}
```

约束:
- `prompt` 与 `prompt_template` **互斥** — 同时传 → `400 ErrInvalidParam`。
- 渲染失败(模板不存在 / 语法 / 变量缺失 / 100ms 超时 / >64KB)→ `400 ErrInvalidParam`,**远早于 wallet freeze,零经济损失**。
- 渲染产物覆盖 `params.prompt`,然后 `variables` + `prompt_template` 字段被消费删除,剩余 `params` 进入 `ValidateAndMergeParams`。
- 模板发现端见下方 [GET /v1/prompt-templates](#get-v1prompt-templates) 节;与 Prompt BC `pt_prompt_templates`(Agent Builder 层)分属不同业务层次。

行为:
1. ResolveModel(model_version_bid)→ ModelInfo + ProviderTaskType + PlatformParams.P95LatencyMs
2. **(可选)解析 `prompt_template` → 经 Prompt BC RenderInline 渲染 → 写回 `params.prompt`**
3. ValidateAndMergeParams(provider param schema 校验)
4. CalculateCreditCost → Wallet `Freeze(credits)`
4. INSERT `gen_generation_tasks`(status=`processing`)+ reconciliation row(同 tx)
5. `taskQueue.Enqueue` 入 Redis Stream(`queue:{provider}:{media}:{priority}`)
6. 返 202 + `estimate_ms = p95 + queue_wait`(由 `estimateQueueMs` 计算)

worker 端(TaskConsumer)拉到任务后:
   - sync model:`ProviderCallService.Execute` 直接执行(几秒返回)
   - async model:`Execute` 内部 polling 至终态 / 或经 Phase 2 asynq pipeline
   - 任意 model:R2 转存 → 资产落库 → `ConfirmFreeze` → outbox 发 `creation.task_completed`

返(永远 HTTP 202):
```json
{
  "task_id": "<task_bid>",
  "status": "processing",
  "poll_url": "/v1/tasks/<task_bid>",
  "estimate_ms": 8000
}
```

`estimate_ms` = `p95_latency_ms`(model.platform_params)+ 队列等待估算(depth × p95 / worker_concurrency)。
建议客户端首次轮询时机:`estimate_ms / 4`,后续每 1-2s 一次直至 terminal。

幂等(2026-09-15 收窄,见 `docs/adr/ADR-023`):`idempotency_key` 命中已有 task 时**不总是**重放 ——
重放只发生在「还有东西要保护」的情况下:

| 既有 task 状态 | 有交付物? | 冻结去向 | 行为 |
|---|---|---|---|
| `pending` / `processing` | 在途 | 冻结中 | **重放**(返原 `task_id` + `poll_url`,202,不重复扣费) |
| `completed` / `partial` | 有 | 已结算 | **重放**(同上) |
| `failed` / `timeout` / `cancelled` | 无 | **已退款** | **不重放** → 按新任务受理并正常扣费 |

⏱️ **重放窗口 70 分钟**(`domain.IdempotencyReplayWindow` = 客户端放弃点 60min + 10min)。
超窗即使状态可重放也按新任务受理 —— `idempotency_key` 是**列**不是带 TTL 的缓存,
不设窗则内容派生的键等于「这组输入这辈子只能生成一次」。
窗外不是「幂等失效」而是「键已释放」:真正的重复提交(网络重试 / 用户连点)恒在**秒级**发生。

⚠️ **查找故障 fail-close**:幂等查找本身失败(PG 不可达 / ctx 取消)时,平台**拒绝受理**
并返 5xx,而不是当作「没有既有任务」去新建 —— 后者会在故障期重复扣费。

重放响应的 `status` 字段带的是**被重放任务的真实状态**(非恒 `processing`),
调用方无需为此额外 `GET /v1/tasks/:bid`。

**参考图审核(ADR-030)**:管线模板 `pipeline.moderation.reference_images: true` 时,提交期在校验器确权
`reference_image_bids` 之后、冻结积分之前,对每张图调用 Safety 图片审核(每次提交只审一次,估价不审)。
拦截 → `45120` `reference image rejected`(不冻结、不建任务);审核器故障 → 放行并记 WARN。
审核器由 config `safety.provider` 选择(`gemini` = 模型分类,模型取 `prov_capability_defaults('content_moderation')`);
现网为 `noop`,切换是独立发布项。

**分发级每日提交上限(ADR-028)**:分发在 acfg `limits.daily_submits` 声明 `{"<管线模板码>|<模型码>|*": N}`
(具体键优先于 `*`;`N<0` 不限 · `0` 关停 · `>0` 上限;段缺失 = 不限)。本账号当日(UTC)已提交满 N 次 →
返 **`42924` daily submit limit reached**(信封码,限流语义),不冻结积分、不创建任务,UTC 次日恢复。
幂等重放不计数;提交在冻结 / 建任务阶段失败会把额度还回去。配置或计数存储读不到时**放行**。

**P6-03 quantity 上限**:`params.quantity` / `params.n` / `params.number_of_videos` 任一字段 > 9 → 直接返 `40036 ErrInvalidQuantity`,不冻结积分、不创建任务。模型自身 `n.max` 可比 9 小(如 Imagen=4),但平台层硬上限永远 9(防一次扣大额积分 + 防上游 OOM + 防滥用)。前端 stepper 范围已自动收敛到 `[1, min(n.max, 9)]`(由 `param_schema.parameters[].quantity` 暴露)。

**media role 级校验(2026-08-09,线上验收通过)**:`params` 中 `media_array` 类字段(如 wan2.7 `media[]`、veo `reference_images[]`)的元素按模型 schema `x-roles` 目录**服务端强制**:① 元素 `role` ∈ 词表(词表外值先被归一到 default 角色,见 provider.md §3.7 归一兜底);② **每角色元素数 ≤ `x-roles[].max_items`**(如 wan2.7 `first_frame` 上限 1,发 3 张即拒);③ 元素 url 与角色 `accept` MIME 白名单匹配(扩展名无法推断时放行)。违例 → **HTTP 400 / code `40001`**,逐项明细在 `details.params`,**不冻结积分、不创建任务**(此前该类违规会通过创建/冻结,直到上游 DashScope 终态拒绝 `Multiple first_frame items are not allowed` 才暴露)。客户端应把 `details` 展示给用户;多图参考意图请标 `reference_image` 等 tag 角色而非复用单槽位 role。注:`POST /v1/tasks/estimate` 同样校验,但走通用映射返 `40033` 无字段明细。

**P6-03 hybrid fanout**:中台按 `model.platform_params.max_native_batch` 派生上游单调用最大产出量,自动决定单任务 native batch / 多任务 fanout / hybrid 混合。例:用户 `quantity=9` × 模型 `max_native_batch=4` → 3 子任务调用 `[4,4,1]`(`hybrid`,比纯 fanout 少 6 次调用);用户 `quantity=4` × 模型 `max_native_batch=4` → 单任务一次调用产 4 张(`native`)。客户端无感,只看 `task_id` + 进度条。

### GET /v1/tasks/:bid

> 来源:`internal/creation/port/http/task_handler.go::GetTask` · 业务:`internal/creation/app/query/get_task_handler.go`

查任务状态。轮询用。

**P7 Phase 5 改造**:响应内嵌候选列表 + 状态聚合 (`candidates` + `candidate_summary`),取代既往 `outputs` 字段下钻。终态 / processing 都返候选(fanout 子任务渐进式产出,渐进式 UI 直接渲染)。

#### 响应字段(P7 Phase 5 新增)

```json
{
  "code": 0,
  "data": {
    "task_bid":           "0193b9a0-...e3",
    "status":             "completed",
    "model_code":         "seedream-5.0",
    "task_type":          "image_gen",
    "output_content":     null,
    "output_metadata":    {"quantity_actual": 4, "quantity_expected": 4},
    "created_at":         1715760000,
    "started_at":         1715760001,
    "completed_at":       1715760015,

    "candidate_summary": {
      "total":     4,
      "ready":     4,
      "pending":   0,
      "selected":  0,
      "discarded": 0,
      "expired":   0
    },
    "candidates": [
      {
        "bid":              "0193b9a1-aaaa-...",
        "task_bid":         "0193b9a0-...e3",
        "index":            0,
        "status":           "ready",
        "moderation_status":"skipped",
        "content_type":     "image",
        "primary_url":      "https://r2.example.com/gen/0/0193b9a0-7c8d-7e3f-9a01-abcdef012345/2026/05/26/01988f30-1234-7e3f-9a01-aaaaaaaaaaaa.png?sig=...",
        "files": [
          {
            "role":        "original",
            "url":         "https://r2.example.com/gen/0/0193b9a0-7c8d-7e3f-9a01-abcdef012345/2026/05/26/01988f30-1234-7e3f-9a01-aaaaaaaaaaaa.png?sig=...",
            "mime_type":   "image/png",
            "file_size":   245678,
            "width":       1024,
            "height":      1024,
            "duration_ms": 0
          }
        ],
        "asset_bid":  "",
        "expires_at": 1716364800,
        "created_at": 1715760010
      }
    ],

    "billing": {
      "quota_consumed":      400,
      "quantity_requested":  4,
      "quantity_completed":  4,
      "quantity_failed":     0,
      "resources": []
    },

    "poll": null
  }
}
```

| 字段 | 类型 | 说明 |
|---|---|---|
| `candidate_summary` | object | 候选状态聚合(进度条 / 状态切换 UI 用),processing 时也填 |
| `candidate_summary.total` | int | 候选总数(含不可见的 moderation rejected/pending) |
| `candidate_summary.ready` | int | 可见可选数(用户能 Save) |
| `candidate_summary.pending` | int | R2 上传中(Worker 重试),客户端展示"加载中" |
| `candidate_summary.selected` | int | 已保存为 asset 数 |
| `candidate_summary.discarded` | int | 已丢弃数 |
| `candidate_summary.expired` | int | TTL 到期数 |
| `candidates` | array | 可见候选列表(过滤 moderation rejected/pending),按 `index` 升序;processing 时陆续填充 |
| `candidates[].bid` | string | 候选 BID(给 Save / Discard 端点用) |
| `candidates[].task_bid` | string | 所属任务 BID(fanout 子任务的候选这里返**父任务 BID**) |
| `candidates[].index` | int | 全局 `candidate_index`(0-based)。fanout 任务可能非连续 |
| `candidates[].status` | string | `pending` / `ready` / `selected` / `discarded` / `expired` — 客户端按此渲染状态 |
| `candidates[].moderation_status` | string | `pending` / `approved` / `rejected` / `skipped`(P8 Safety BC 启用前默认 `skipped`) |
| `candidates[].url` | string | **完整资源 URL**(AI 最终产出图/视频/音频)— `ready+` 状态为签名 URL(默认 1h 有效),`pending` 可能空串 |
| `candidates[].primary_url` | string | 兼容别名,与 `url` 同值;P7 Phase 5 初版命名,新客户端用 `url` |
| `candidates[].width/height` | int | **主文件像素尺寸**(从 `files[].role='original'` 镜像);Carousel 布局必需 |
| `candidates[].content_type` | string | `image` / `video` / `audio` / `text` / `file` |
| `candidates[].files` | array | 子文件数组 — **AIGC 域只有 `role='original'`**(AI 模型直接产完整资源,无 thumbnail/preview 衍生物概念);ent enum 历史 4 值保留兼容部署,新数据只写 original。每项含 `url/mime_type/file_size/width/height/duration_ms` |
| `candidates[].asset_bid` | string | **"已保存到资产库"标记**:仅 `status=selected` 时填(`gen_assets.bid`);前端凭非空标记禁用 Save + 跳转资产库详情 |
| `candidates[].expires_at` | int64 | 候选 TTL 到期时间 Unix 秒(默认 7 天后) |
| `candidates[].created_at` | int64 | 候选落库 Unix 秒 |
| `poll` | object \| null | 非终态时返轮询建议;终态(completed/partial/failed)为 null |
| `pipeline` | object | **ADR-038**(2026-09-28):仅 `processing` 的管线任务、且模板声明了阶段时下发;与 SSE `progress` 事件**同源同值**(同一次写出的快照)。字段:`stage`(模板阶段名)· `step_done` / `step_total` · `units_done` / `units_total`(当前步内已完成的离散单元,如渲染段;0/0 = 该步无单元语义)· `percent`(已完成步数 + 当前步单元折算,**无按时间插值项**)· `detail`(步骤透传的固定英文键值,如 `segment_index` / `model_code`)· `updated_at`(unix ms)· `cancel_requested`(ADR-037:已请求取消、worker 尚未在空隙确认)。快照读不到(Redis 抖动)时整块缺席,不影响其余字段 |
| `billing.funding_revoked` | bool | **ADR-024**:资助本任务的订单中有资金已撤回的(退款 / revoke);缺席 = false,撤销退款后回到 false。标记由退款事件触发、从钱包分摊与订单**现状**重算,与事件先后无关 |

**进度条**:终态前客户端按 `candidate_summary.ready + selected` / `quantity_requested` 计算进度。

**渐进式渲染**:fanout 任务(`quantity=9, max_native_batch=4` → 3 子任务)子任务陆续完成时 `candidates` 数组陆续填,客户端按 `index` 排序展示骨架屏 / 实图。

异步任务终态时 `candidates[].primary_url` 已 R2 持久化(`pending` 状态例外 — 由 PendingPromotionWorker 异步重试)。

### GET /v1/tasks/:bid/stream

> 来源:`internal/creation/port/http/task_stream_handler.go::StreamTask`(P8-02)

任务进度 **SSE 实时推送**,替代 `GET /v1/tasks/:bid` 轮询。`Content-Type: text/event-stream`。

连接即收 `snapshot` 帧(当前完整任务状态,字段同 `GET /v1/tasks/:bid`);任务已终态则随后 `done` 关闭,否则持续推送增量事件直至终态。

#### 事件类型

| event | 说明 | 带 `id:` |
|---|---|---|
| `snapshot` | 首帧:任务当前完整状态(`TaskResponse`)| 否 |
| `progress` | 任务进入 `processing`;**管线任务**另在每个步骤边界推一条,带 `data.payload.stage` + 真实百分比(见下)| 是 |
| `candidate_ready` | 单个候选落库;`data.candidate_index` + `data.payload.asset_key` | 是 |
| `completed` / `failed` | 任务终态;推送后服务端关闭流 | 是 |
| `done` | 会话结束;`data.reason` = `terminal` / `already_terminal` / `session_timeout` | 否 |
| `error` | 流内错误 | 否 |
| `: hb`(注释行)| 心跳 keep-alive(无新事件时每 15s)| — |

增量事件 `data` 为 `TaskStreamEvent`:`{event_type, task_status, candidate_index, progress, payload, occurred_at}`。

##### 管线任务的阶段进度(`payload.stage`)

管线模板可为每个步骤声明一个阶段名;引擎在该步**开始前**推一条 `progress`,
`payload.stage` = 该阶段名,`progress` = **已完成步数**百分比。

| 管线 | 推送序列 |
|---|---|
| `ai_song_preview_v1`(两段试听) | `0% composing` → `50% composing` → 终态 `completed 100%` |
| `ai_song_full_v1`(完整歌) | `0% composing` → 终态 `completed 100%` |
| `songlet_chorus_mv_v1` / `songlet_full_mv_v1`(MV,ADR-038) | `0% slicing` → `20% storyboarding` → `40% keyframing` → `60% rendering` → 渲染步内每渲完一段推一条(`payload.units_done` / `units_total` / `segment_index` / `model_code`,`progress` 按已完成段折算)→ `80% assembling` → 终态 |

**阶段闭集(V1)**:`composing` · `slicing` · `storyboarding` · `keyframing` · `rendering` · `assembling`。客户端遇到闭集外的取值应按「正在生成」兜底显示。

**步内单元(ADR-038)**:`payload.units_done` / `units_total` 只在步骤报了**真实完成单元**时出现(逐段渲染 / 逐帧生成);
一次上游调用内部不会有中间帧。同一帧同时写进 `GET /v1/tasks/:bid` 的 `pipeline` 块,轮询客户端拿到的是同一个数。

⚠️ **百分比不含步骤内部进度**,也不会随时间自增 —— 上游不给内部进度时,
按本地计时补中间态就是伪造。等待动画请用 `estimate_ms` 驱动,不要拿 `progress` 当秒表。

⚠️ 未声明阶段的管线(全部既有模板)**不推**步骤级 `progress`,行为与本次改动前完全一致。

#### 断线重连

每条增量事件带 SSE `id:`(= Redis Stream 条目 ID)。客户端断线后用标准 `Last-Event-ID` 请求头重连,服务端从该 ID 之后续推,不丢事件;新连接不带该头时从头回放(事件流有界,`MAXLEN ~ 1000`)。

#### 约束

- 单任务并发 SSE 连接上限 **10**,超限返 `42921`。
- 单次会话上限 **10 分钟**,到期发 `done`(reason=`session_timeout`),客户端可立即重连。
- 鉴权同 `GET /v1/tasks/:bid`(JWT + 任务归属校验)。

### POST /v1/tasks/:bid/cancel
取消任务。响应 `data.outcome`(ADR-037,2026-09-28 起;此前 `data` 为 null,旧客户端只看 `code=0` 语义不变):

| 任务状态 | 结果 | `data.outcome` | 钱 |
|---|---|---|---|
| `pending` | 即刻 `cancelled`(`error_code=user_cancelled`)| `cancelled` | 冻结额全退 |
| `processing` **且是管线任务**(`task_type=pipeline`)| 状态不变,记下取消信号;worker 在下一个**空隙**(步骤边界 / 分段之间,此刻没有在途上游调用)把任务终结为 `cancelled` | `cancel_requested` | 已完成的付费步按 `billing_weight` 分摊确认,其余退回(D2 路径③)|
| `processing` 非管线(单步骤模型任务)| **拒绝** `40920`:上游调用无法中断,跑到终态照常结算 | — | — |
| 终态 | `40920` | — | — |

- 取消信号存储不可达 → `50325`(基础设施错误 ≠ 业务拒绝;这次取消**没有发生**,客户端重试)。
- `cancel_requested` 之后继续轮询 / SSE 到终态;`GET /v1/tasks/:bid` 的 `pipeline.cancel_requested=true` 表示已请求、尚未确认,不要重复发。
- 已经入 Redis Stream 但未被消费的 pending 任务 → 标 cancelled,Worker 拉到时 skip。

### GET /v1/tasks

> 来源:`internal/creation/port/http/task_handler.go::ListTasks` · 业务:`internal/creation/app/query/list_tasks_handler.go`

列用户的创作历史(分页),返回每个任务的完整候选列表 + 完整产物 URL(R2 域名已拼接)+ 原始入参(供客户端"重试 / 一键复用")。

**P7 Phase 5 改造**:列表项嵌入 `candidates[]` + `candidate_summary`,与单条 `GET /v1/tasks/:bid` 字段语义完全一致。前端画廊页按任务分组横向平铺候选,"复用"功能直接从 `candidates[].primary_url` 取 URL 回填表单,**无需二次请求**。

#### Query 参数

| 参数 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `page` | int | 1 | 1-based;< 1 视作 1 |
| `size` | int | 20 | 上限 50;> 50 或 ≤ 0 视作 20 |
| `status` | string | "" | 空 = 全部;否则必须 in [`pending`,`processing`,`completed`,`failed`,`timeout`,`cancelled`,`partial`],**非法值返 400**(不再透传到 DB 触发 500) |
| `task_type` | string | "" | 空 = 全部;否则必须 in [`text_gen`,`image_gen`,`image_edit`,`image_upscale`,`video_gen`,`audio_gen`,`tts`,`stt`,`code_gen`,`embedding`,`translation`,`multimodal`,`pipeline`],**非法值返 400** |
| `created_from` | string | — | 时间下界,**闭区间** (`created_at >= from`);接受 **Unix 秒** 或 **RFC3339**(如 `1714694400` / `2026-05-01T00:00:00Z` / `2026-05-01T08:00:00+08:00`);不接受裸 `YYYY-MM-DD`(时区歧义);非法值返 400 |
| `created_to` | string | — | 时间上界,**左开区间** (`created_at < to`);格式同 `created_from`。左开的语义是:传"次日 00:00"可表达"包含今日全部任务"。非法值或 `to < from` 返 400 |

只返回**顶层任务**(N-Gen 父任务列在这里,fan-out 子任务被自动隐藏并聚合到父任务的 `outputs` + `candidates` 数组里)。

**示例**:
```bash
# 仅图像生成 + 近 24h 完成的任务,第 2 页
curl "$BASE/v1/tasks?task_type=image_gen&status=completed&created_from=$(date -u -v-1d +%s)&page=2&size=20"
# RFC3339 替代写法:created_from=2026-05-26T00:00:00Z
```

**索引覆盖**:`(account_id, created_at)` 复合索引(`idx_gen_tasks_account`)天然支持账户 + 时间范围扫描;`task_type` 在索引返回行内做内存过滤,单页 ≤ 50 行成本可忽略,**不需要额外索引**。

#### 响应

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "tasks": [
      {
        "task_bid":      "0193b9a0-...e3",
        "status":        "completed",
        "model_code":    "seedream-5.0",
        "task_type":     "image_gen",
        "scene":         "general",
        "created_at":    1715760000,
        "completed_at":  1715760015,
        "input_params": {
          "prompt":         "a cat in cyberpunk style",
          "aspect_ratio":   "1:1",
          "quantity":       1,
          "seed":           42
        },
        "outputs": [
          {
            "asset_bid":        "0193b9a0-aaaa-...",
            "url":              "https://r2.showsapp.org/gen/0/0193b9a0-7c8d-7e3f-9a01-abcdef012345/2026/05/26/01988f30-1234-7e3f-9a01-aaaaaaaaaaaa.png",
            "content_type":     "image",
            "mime_type":        "image/png",
            "width":            1024,
            "height":           1024,
            "duration_seconds": 0,
            "expires_at":       0
          }
        ],
        "candidates": [
          {
            "bid":               "0193b9a1-cccc-...",
            "task_bid":          "0193b9a0-...e3",
            "index":             0,
            "status":            "ready",
            "moderation_status": "skipped",
            "content_type":      "image",
            "url":               "https://r2.showsapp.org/gen/0/0193b9a0-7c8d-7e3f-9a01-abcdef012345/2026/05/26/01988f30-1234-7e3f-9a01-aaaaaaaaaaaa.png?X-Amz-Signature=...",
            "primary_url":       "https://r2.showsapp.org/gen/0/0193b9a0-7c8d-7e3f-9a01-abcdef012345/2026/05/26/01988f30-1234-7e3f-9a01-aaaaaaaaaaaa.png?X-Amz-Signature=...",
            "width":             1024,
            "height":            1024,
            "files": [
              {
                "role":       "original",
                "url":        "https://r2.showsapp.org/gen/0/0193b9a0-7c8d-7e3f-9a01-abcdef012345/2026/05/26/01988f30-1234-7e3f-9a01-aaaaaaaaaaaa.png?X-Amz-Signature=...",
                "mime_type":  "image/png",
                "file_size":  524288,
                "width":      1024,
                "height":     1024,
                "duration_ms": 0
              }
            ],
            "asset_bid":   "",
            "expires_at":  1716364800,
            "created_at":  1715760015
          }
        ],
        "candidate_summary": {
          "total":     1,
          "ready":     1,
          "pending":   0,
          "selected":  0,
          "discarded": 0,
          "expired":   0
        },
        "output_metadata": {
          "post_process_status": "none"
        }
      }
    ],
    "total": 137
  },
  "request_id": "uuid",
  "timestamp":  1715760123
}
```

#### 字段语义(重点)

| 字段 | 类型 | 说明 |
|---|---|---|
| `total` | int | 该 account 下满足 `status` 过滤的**全表**任务数(用于分页计算 total pages,不是当前页 len) |
| `tasks[].input_params` | object | 用户提交任务时的**原始参数**(透传 domain `gen_generation_tasks.input_params`)。**客户端"再生成 / 重试 / 一键复用"直接拿这个字段填充表单**,无需重新解析参数 schema |
| `tasks[].outputs` | array | 产物列表;`status=completed/partial` 通常非空,其他状态可能为空数组 |
| `tasks[].outputs[].url` | string | **完整 URL(已拼 R2 域名)**;`access_level=public` 是 CDN 长效链;`access_level=private/unlisted` 是预签名短效链 |
| `tasks[].outputs[].asset_bid` | string | 资产 BID;用于后续收藏 / 分享 / 删除等操作 |
| `tasks[].outputs[].expires_at` | int64 | URL 过期 Unix 秒;`0` = 长效(public bucket / CDN 直链);`> 0` = 预签名过期时间,客户端应在到期前重新拉列表刷新 URL |
| `tasks[].outputs[].width/height/duration_seconds` | int | 图像 / 视频维度信息;`0` 表示该媒体类型不适用或未识别 |
| `tasks[].output_metadata` | object | 透传 domain `output_metadata`,可能含 `post_process_status` / `final_urls` / `urls`(N-Gen 父任务聚合)等 provider/pipeline 特定键。**优先使用 `outputs` 字段**,`output_metadata` 视作扩展元数据 |
| `tasks[].candidates` | array | **画廊主数据源** — 候选列表,按 `index` 升序;包含 `pending` / `ready` / `selected` / `discarded` 各 status;过滤 `moderation_status` ∈ {`rejected`,`pending`} 的合规隐藏候选。**空候选返 `[]` 而非 `null`**,前端 `.map()` 可直接遍历无需空检查 |
| `tasks[].candidates[].bid` | string | 候选 BID(给 Save / Discard 端点用) |
| `tasks[].candidates[].task_bid` | string | 所属任务 BID(fanout 子任务的候选这里返**父任务 BID**,前端按父任务分组) |
| `tasks[].candidates[].index` | int | 全局 `candidate_index`(0-based, 按生成顺序),iOS Carousel 横滑翻页直接用此排序;**fanout 父任务**的子任务候选 index 按 `child_generation_index × max_native_batch + slot` 偏移(可能不连续,如 0, 9, 18, ... ;前端只需按值排序,不假设连续) |
| `tasks[].candidates[].status` | string | `pending`(R2 上传重试中,可能无 URL)/ `ready`(可见可选取)/ `selected`(已 Save 为 asset)/ `discarded`(用户丢弃)/ `expired`(TTL 到期,默认 7 天) |
| `tasks[].candidates[].moderation_status` | string | `pending` / `approved` / `rejected` / `skipped`(P8 Safety BC 启用前默认 `skipped`)。`rejected` / `pending` 的候选**不会**出现在 `candidates[]` 数组,但仍计入 `candidate_summary.total` |
| `tasks[].candidates[].url` | string | **画廊主图 URL**(推荐字段,与 `outputs[].url` 命名对齐)— `ready+` 状态为签名 URL(默认 1h),`pending` 可能空串。`primary_url` 为兼容别名(同值,P7 Phase 5 初版命名) |
| `tasks[].candidates[].primary_url` | string | 兼容别名,与 `url` 同值。**新客户端优先用 `url`**,老客户端持续返 `primary_url` 不破坏契约 |
| `tasks[].candidates[].width/height` | int | **顶层主文件像素尺寸**(从 `files[].role='original'` 镜像)— iOS Carousel 布局必需,无需遍历 `files[]` |
| `tasks[].candidates[].content_type` | string | `image` / `video` / `audio` / `text` / `file`(同 `outputs[].content_type`) |
| `tasks[].candidates[].asset_bid` | string | **"已保存到资产库"标记**:仅 `status=selected` 且 asset 行存在时填(`gen_assets.bid` UUID),其它状态为空串。前端凭此**非空即"已加入资产库"** — 禁用 Save 按钮 / 显示已保存徽章 / deep link 跳转 `/assets/:asset_bid` 详情;同一 asset 的多任务复用判重也可缓存此 BID 集合。后端批量 SQL `SELECT id, bid FROM gen_assets WHERE id IN (...)` 翻译,无 N+1 |
| `tasks[].candidates[].expires_at` | int64 | 候选 TTL 到期 Unix 秒(默认 7 天后) |
| `tasks[].candidates[].created_at` | int64 | 候选落库 Unix 秒(与父任务 `completed_at` 接近) |
| `tasks[].candidates[].files[]` | array | 子文件数组 — **AIGC 域只产 `role='original'`**(AI 模型最终产出, 无 thumbnail/preview 衍生概念);ent enum 历史 4 值兼容 DDL 保留,新数据只写 `original`。每项字段:`role/url/mime_type/file_size/width/height/duration_ms`(空字段走 `omitempty` 不返)。**新客户端优先用顶层 `url/width/height`**,无需遍历此数组 |
| `tasks[].candidate_summary` | object \| null | 各 status 计数(`total/ready/pending/selected/discarded/expired`),前端进度条用;无候选时返 `null` |
| `tasks[].candidate_summary.total` | int | 候选总数(**含**被 `moderation_status` 过滤的隐藏候选);因此 `len(candidates) ≤ candidate_summary.total`,差值即被合规过滤的数量 |
| `tasks[].candidate_summary.ready/pending/selected/discarded/expired` | int | 按 `candidates[].status` 分类聚合(不分 moderation 状态)|

**数据完整性契约**(终态任务 `status=completed/partial`):
- `candidate_summary.total === task.quantity_completed`(候选总数 = 实际产出数,由 `CandidatePersister.PersistAsCandidates` 与 `task.MarkCompleted` / `aggregateParent` 协同保证)
- `len(candidates) ≤ candidate_summary.total`(可见数 ≤ 总数,差值 = 被合规过滤数)
- 不等时后端 WARN 日志标记 `data integrity warning`,响应不阻塞;客户端可信任 `candidates[]` 数据。

#### N-Generation 行为

- **Native N**(单次 API 调用返多张,如 seedream `quantity=4`):`tasks[]` 出现 1 行,`outputs` 含 4 个 TaskOutput,`candidates` 含 4 个候选(每个 `index=0..3`)。
- **Fan-out N**(并发派发 N 个子任务,父级聚合):`tasks[]` 出现父任务 1 行,`outputs` 与 `candidates` 自动聚合所有 N 个子任务的资产 + 候选(顺序按子任务 `generation_index` × 候选 `candidate_index`)。子任务**不**作为独立行出现在列表里。

#### 性能

恒定 4 个数据库 round-trip,与 `size` 无关,与候选数量无关:
1. `ListByAccount` 拉顶层任务(走 `idx_gen_tasks_account` 索引)
2. `FindChildrenByParentIDs(parentIDs)` 批查父任务的子任务集合(走 `idx_gen_tasks_parent`)
3. `FindBySourceTaskIDs(ownedTaskIDs)` 批查所有相关资产(走 `idx_gen_assets_source_task`)
4. `ListByTaskIDs(ownedTaskIDs)` 批查所有候选(走 `uq_gtc_task_index` 唯一索引,`ORDER BY task_id, candidate_index`);ent `WithFiles` eager load 触发第 5 个 SQL 拉 `gen_task_candidate_files`(按 `candidate_id IN (...)`,索引覆盖)

`page≤50` 任意 `quantity ≤ 9` 情况下端到端 ≤ 30ms;**无 N+1**(对比 N=20 任务 × 单 SQL 候选查询 = 20 次 round-trip 的旧实现差 10x+)。

#### 错误码

| `code` | 含义 | 触发 |
|---|---|---|
| `401xx` | 未授权 | JWT 缺失或过期 |
| `40110-40114` | 签名错误 | App 签名 header 缺失或失败 |
| `50000` | 服务端内部错误 | DB / R2 异常 |

#### 任务失败诊断码(`task.error_code`,2026-08-02 起保证非空)

⚠️ 与上表的 HTTP 信封 `code`(数字)是**两套东西**:上表是接口调用本身的错误;
本表是**任务执行失败的原因**,出现在 `GET /v1/tasks/:bid` 的 `error_code` 字段
(`status=failed/timeout` 时)。**前端应按本码做话术,不要直接展示 `error_message`**
——后者是上游英文原文(排障用),对终端用户不可读。

| `error_code` | 含义 | 可重试 | 建议话术方向 |
|---|---|---|---|
| `content_filtered` | 上游内容安全策略拒绝(输入图/文命中敏感内容,如"图片疑似含真人肖像") | ❌ 换素材 | 提示更换图片或调整描述,**不要**提示"重试" |
| ↳ *覆盖范围* | 各供应商的审核拒绝已统一归一到本码:火山 `SensitiveContentDetected`/`PrivacyInformation`、百炼 `DataInspectionFailed`/`IPInfringementSuspect`(2026-08-06 补齐)、Gemini `SAFETY`。原始厂商码保留在 `error_message` 供排障 | | 前端只需认 `content_filtered` 一个码 |
| `prompt_blocked` | prompt 级安全拦截 | ❌ 改 prompt | 提示修改描述内容 |
| `content_policy_violation` | 内容审核拒绝 | ❌ | 同上 |
| `invalid_param` | 参数不被上游接受(含 HTTP 400/404 未细分场景) | ❌ 改参数 | 提示参数不受支持,可回参数编辑面板 |
| **`unsupported_by_model`** | 该模型不支持此参数/模式组合(如 veo lite 传参考图、非 Vertex 通道用 upscale) | ❌ 换模型或去掉该参数 | 提示"当前模型不支持 XX,请换用支持的模型或移除该输入"——**不要**提示重试 |
| `region_or_auth_blocked` | 上游鉴权/地域封锁(2026-08-06 前误含部分模型能力拒绝,现已分流到 `unsupported_by_model`) | ❌ 平台修 | 同 `auth_failed` 处理 |
| `auth_failed` | 平台侧凭证问题 | ❌ 平台修 | 提示"服务暂时不可用",**告警已触发,勿引导用户重试** |
| `quota_exhausted` | 上游配额耗尽 | ⏳ 稍后 | 提示稍后再试 |
| `rate_limited` | 上游限流 | ✅ 退避后 | 提示稍后再试(系统通常已自动重试) |
| `upstream_rejected` | 上游确定性拒绝但未能细分 | ❌ | 通用失败话术 |
| **`content_filter_unspecified`** | 上游内容过滤的**非确定性**拒绝(只说 "unspecified policy reason",不给原因) | ✅ **重试** | ⚠️ 与上面 `content_filtered` 处置**完全相反**:提示「稍后重试」,**绝不要**提示改内容。实测同一份无害输入重试约 92% 即过(2026-09-07,120 次调用被拦 8 次);平台侧已在任务预算内自动重试,用户看到此码说明自动重试也已用尽 |
| `upstream_error` / `upstream_empty_response` | 上游异常/返回空产物 | ✅ | 提示重试 |
| `no_available_channel` | 无可用通道 | ⏳ | 提示服务繁忙 |
| **`submit_timeout`** | 超时且**上游从未受理**(无 upstream 句柄) | ✅ | 提示重试;平台侧:通常未产生上游费用 |
| **`poll_timeout`** | 超时但**上游已受理**未出结果(`error_message` 带 `upstream_task_id`) | ⏳ | 提示稍后查看;平台侧:上游**可能已计费**,凭 `upstream_task_id` 追查 |
| **`upstream_submit_unknown`** | 上游**没有回答**:传输层超时,或中间层代答 504/524(2026-09-15 起)。上游可能已处理并计费,平台按纪律**不自动重投**;冻结积分已退回 | ❌ 平台不重投;用户可**重新生成**(失败任务不重放,按新任务受理) | 提示「生成未完成,积分已退回,可重新生成」;`failure.blame=platform_side`、`action=contact_support` |

##### 产物质量族(音乐生成回听校验)

与上面各族的差别是**有没有产物**:上面那些是上游报错或给了空,这三条是上游 200 +
有音频,只是唱的不对 / 有人声 / 长度不对 —— 判定发生在**交付之后**的回听校验步骤。
三条**都归平台侧,冻结积分全额退回**;`Action` 给的是「怎样能提高下次成功率」的建议,
不是归责。

| `error_code` | 含义 | 可重试 | 建议话术方向 |
|---|---|---|---|
| **`lyrics_mismatch`** | 平台内部重试用尽后,实际演唱内容与用户提供的歌词仍差异过大 | ❌ 改输入 | 提示「试试缩短或简化歌词」——长而复杂的歌词是系统性难点,单纯重试收益低 |
| **`vocal_detected`** | 请求纯伴奏(视频 BGM),但重试用尽后回听仍检出人声 | ✅ | 提示重试;用户没做错任何事,不要引导他改输入 |
| **`duration_out_of_range`** | 重试用尽后产物时长仍在目标区间之外 | ❌ 改参数 | 提示「换一个目标时长试试」 |

> ⚠️ 这三个值同时出现在 **aisinger × 平台跨仓契约**里,客户端按它们做话术,
> **改动即破坏契约**。登记项(Class / Blame / Action / 英文默认文案)的唯一事实源是
> `internal/shared/failure/registry.go` 的「产物质量族」一节;判据实现在
> `internal/shared/songverify`(纯函数,探针与线上校验步骤共用一份)。

##### 音乐生成上游族(Lyria,2026-09-25 登记)

上游在生成阶段就失败了(没有产物可校验)。此前这四个值未登记,被兜底成可重试码,
平台会把一次确定性失败重投到预算用尽;现与适配器口径一致:**一律不自动重投**。

| `error_code` | 含义 | 可重试 | 建议话术方向 |
|---|---|---|---|
| **`music_generation_failed`** | 上游交互以失败 / 取消结束,且不是安全拒绝(安全拒绝归 `prompt_blocked`) | ❌ 改输入 | 提示「换个描述再试」;同一输入重试结果相同 |
| **`music_empty_response`** | 上游报完成却没有音频,多为安全过滤的静默丢弃 | ❌ 改输入 | 同 `content_filtered` 的话术方向:引导换内容,不要引导重试 |
| **`music_generation_timeout`** | 已提交给上游但在时限内没有结果,上游可能仍在生成、可能已计费 | ⏳ 平台不重投 | 提示「生成未完成,积分已退回,可重新生成」 |
| **`music_budget_exceeded`** | 上游按请求的算力预算耗尽而中止 | ❌ | 通用失败话术;平台侧需排查请求规格 |

> **积分保证**:以上任何失败/超时,冻结积分均**全额退回**(失败即退,不扣费)。

**管线任务(`task_type=pipeline`)的失败码(ADR-033,2026-09-25)**:缺省对外恒为外层归一化码
`pipeline_failed` / `budget_exceeded` / `attempts_exhausted`(各管线产品的对接文档按它写,不变)。
模板声明 `pipeline.failure.surface_step_code: true` 时,`error_code` 取**失败步的具体码**:
先取步骤自报的码(如回听验收 `lyrics_mismatch` / `vocal_detected` / `duration_out_of_range`),
再取上游规范码(如 `content_filtered` / `rate_limited` / `music_generation_timeout`);
只接受本表(`internal/shared/failure` 登记表)内的码,表外一律回落 `pipeline_failed`;
编排护栏码(`budget_exceeded` / `attempts_exhausted`)不被覆盖。**结算不受声明影响**
(结算归类只看步级台账,声明与否同一次失败的收费结果逐字相同)。现网声明方:Songlet 三条管线(迁移 `20260927c`)。

> **历史背景**(2026-07-31 task 184):此前上游的确定性拒绝(火山 HTTP 400
> `InputImageSensitiveContentDetected`,输入图疑似含真人)被误判为可重试瞬时故障,
> 反复重投至 40 分钟超时兜底,`error_code` 落空,用户只看到无意义的
> "task execution timeout"。现已三层修复:该类请求**秒级**返回
> `content_filtered`;即便真超时也必带 `submit_timeout`/`poll_timeout` 区分卡点。
> 详见 `internal/creation/domain/generation_task.go::MarkTimeout` 与
> `internal/creation/app/command/task_consumer.go::handleUpstreamRejected`。

#### 客户端集成建议

- **画廊页 / iOS Carousel**(按任务分组横滑候选):优先用 `candidates[].url` 渲染,按 `candidates[].index` 升序排序(注意 fanout 任务的 index 可能非连续,只用作排序键不假设连续);`status=pending` 的候选展示骨架屏(URL 可能空串),`ready+` 展示实图;前端 `.map(candidates)` 无需空判,handler 已保证返 `[]` 不返 `null`;`width/height` 直接读顶层无需遍历 `files[]`。
- **任务卡片封面**:若需展示任务卡片代表图,直接从 `candidates[0].url` 取。**AIGC 域无缩略图概念** — AI 模型产出的就是最终完整资源(图/视频/音频),不存在 thumbnail 派生物。任务级 `thumbnail_url` 也已下线,前端不应假设有低分辨率衍生 URL。
- **"再次生成 / 重试 / 复用"按钮**:把 `input_params` 直接传回 `POST /v1/tasks` 的 `params` 字段(可在前端打开参数编辑面板让用户调改后再提交);**复用候选作为图生图输入**:直接读 `candidates[X].url` 作为新任务的 `image_url` 参数,**列表数据已足够,无需调 `GET /v1/tasks/:bid`**。
- **"已保存到资产库"标记**(产品场景):`candidates[].status === "selected"` 即用户已 Save 该候选,前端**禁用 Save 按钮 + 显示"已保存"徽章**;同时 `candidates[].asset_bid` 非空,可 deep link 跳转 `/assets/:asset_bid` 资产库详情页;复用判重可缓存 asset_bid 集合避免同 asset 多任务重复展示。
- **预签名 URL 刷新**:`expires_at > 0` 时,客户端缓存的 URL 应在到期前(建议 5 分钟容差)重新拉一次列表;过期后请求会返 403。
- **失败任务**:`status=failed/timeout` 时通常无 `outputs` 和 `candidates`。**按 `error_code` 映射本地化话术**(取值与建议见上文"任务失败诊断码"表),`error_message` 是上游英文原文,仅作排障/工单附带信息,**不应直接展示给终端用户**。尤其 `content_filtered` 应引导"更换素材"而非"重试"——重试必然同样被拒。
- **Native N 部分成功 (`status=partial`)**:`candidates[]` 长度 = `task.quantity_completed` < `quantity_requested`,服务端已按比例确认积分 + 退款差额。客户端读 `output_metadata.quantity_actual / quantity_expected` 显示"已生成 M/N 张"。

#### Native N 部分成功 (`status=partial`)

Native N 任务(`quantity > 1` 走单次上游 API 多图)在以下条件触发 partial:
- 上游成功响应但返图数 < 请求数(如 Seedream SSE 流半截、Imagen 部分帧解析失败、Wan 部分帧丢失)
- `actual > 0` 且 `actual < expected`

服务端自动行为:
1. `task.status = partial`,`task.quantity_completed = actual`,`task.quantity_failed = expected - actual`
2. `output_metadata.quantity_actual = M`,`output_metadata.quantity_expected = N`(客户端读 + 提示)
3. **积分按比例确认**:`PartialConfirmFreeze(freezeID, taskID, totalFrozen × actual / expected)`,差额自动退回钱包
4. `candidates[]` 落 M 行,前端画廊只显示成功的 M 张(失败的 N-M 张无候选记录)
5. `outputs[]` 长度同步 M(仅在用户 Save 候选后才升级为 asset)

> **部署说明**:`gen_task_status` enum 在 P7 Phase 6 通过 `docs/migrations/p7_phase6_add_partial_task_status.sql` 补加 `'partial'` 值。已部署环境需先跑此 migration 才能产生 partial 状态;新部署直接含此值(源 DDL `creation_domain_pg18.sql` 已 forward-merge)。

数据完整性兜底(R2 转存失败场景):
- 当 `CandidatePersister.persistOne` 把上游 URL 下载到 R2 的步骤失败(R2 短时不可用 / 上游 URL 过期等),仍**建** candidate 行,但:
  - `status = "pending"`,`storage_provider = "external"`
  - `url` / `primary_url` 暂为空串(主文件 key 缺失)或直接返上游 URL(取决于 fallback 策略)
- 服务端 `PendingPromotionWorker` 后台周期重试上传到 R2(指数退避,最多 5 次)
- 客户端处理:`candidates[].status === "pending"` 的候选显示"上传中"骨架屏,定期重新拉列表 → 看到 status 跃迁到 `ready` 后 url 字段被填充

## 资产生命周期(装配块 — 云工作台)

| Method | Path | 语义 |
|---|---|---|
| `POST` | `/v1/assets/:bid/archive` | 归档资产(工作台隐藏, 不删数据)|
| `POST` | `/v1/assets/:bid/unarchive` | 取消归档 |
| `POST` | `/v1/assets/:bid/adopt` | 采用某版本为资产当前版(版本树指针)|

详源:`frontend-workbench-contracts-20260721.md` §资产。

## 项目池(gen_projects — 云工作台项目域, Phase A/B)

| Method | Path | 语义 |
|---|---|---|
| `POST` | `/v1/projects/:bid/transition` | 项目状态机流转 |
| `POST` | `/v1/projects/:bid/favorite` | 切换收藏 |
| `POST` | `/v1/projects/:bid/transfer` | owner 转让 |
| `POST` | `/v1/projects/:bid/members` | 加成员 |
| `PATCH` | `/v1/projects/:bid/members/:account_bid` | 改成员角色 |
| `DELETE` | `/v1/projects/:bid/members/:account_bid` | 移除成员 / 本人退出 |

(CRUD 基础端点见路由总览;池预算/审批面在 Wallet BC `pool-approvals`。)
详源:`frontend-workbench-contracts-20260721.md` §项目。

## 意图分类(intent v2)

### POST /v1/intent/classify

话语 → 意图对象骨架(七类;含 target_ref 指代描述子 + ops 操作归一, S4 v2 descriptor)。
resolver 权重经 `creation.intent_resolver` config(零值=规格默认)。
详源:`frontend-workbench-contracts-20260721.md` §意图 + ADR-015。

**intent_ref 回显契约(ADR-015 D5 修正回流)**:成功响应含 `intent_ref`(本次分类执行流水
的不透明句柄;降级响应无)。客户端在随后的 `POST /v1/tasks` 请求体**原样回显** `intent_ref`,
服务端据此做 classify↔submit 对账、推导修正回流信号(confirm_card / choice 落
`eval_quality_events`)。纯质量采集用途:不回显只损失质量信号、不影响任何功能;无效/伪造值
服务端做归属+时效校验后静默忽略(信号内容全取服务端流水,客户端无法注入语义),决不影响提交。

## 音视频转写管线(transcript_v1 — 听语 P-2)

### 提交(复用 `POST /v1/tasks`,零新端点)

```json
{
  "pipeline_code": "transcript_v1",          // 整段转写;预览切片用 "transcript_preview_v1"(首段 ≤60s,默认免费)
  "params": {
    "audio_asset_bid": "...",                // 必填: 已上传音/视频资产 (须 uploaded + 时长元数据就绪; ≤8h 硬顶 40834)
    "language_hints": ["zh", "en"],          // 可选 ≤4 项 (fun-asr 官方语种码)
    "diarization_enabled": true,             // 可选: 说话人分离 (输出句级 speaker 标签)
    "speaker_count": 4,                      // 可选 1..12, 须配合 diarization_enabled
    "vocabulary_id": "vocab-xxx"             // 可选: 预建热词表 id (阿里词表; 产品侧按订阅档裁剪)
  },
  "conversation_bid": "...", "idempotency_key": "...", "confirmation": {...}, "intent_ref": "..."
}
```

计价 `per_minute`(分钟向上取整;`pipeline:transcript_v1` 定价行),提交/估价同源
(`TranscribeSubmitValidator` 双挂)。任务进度走既有 SSE(`snapshot/completed/failed`)。

### 产物(`GET /v1/tasks/:bid` 终态)

`output_metadata.refs`:

```json
{
  "schema": "transcript_v1",
  "transcript_asset_bid": "...",   // 权威产物 transcript.json (gen_assets, kept/private — 经资产读面长期可取)
  "srt_asset_bid": "...",          // SRT sidecar (备线无时间戳时缺席)
  "source_asset_bid": "...",       // 源素材映射键
  "duration_ms": 3600000, "sentence_count": 412, "speaker_count": 2
}
```

`transcript.json` 结构(**D2 冻结契约**,产品端编辑器坐标系;破坏性变更须双仓评审):

```json
{ "schema": "transcript_v1", "duration_ms": 3600000,
  "sentences": [ { "idx": 0, "t0": 120, "t1": 4380, "text": "…",
                   "speaker": "1",                      // diarization 开启才有 (上游标签透传)
                   "words": [{"t0":120,"t1":480,"w":"…"}] } ],   // 词级时间锚 (上游提供才有)
  "speakers": ["1","2"] }
```

转写完成后正文自动入用户私有 KB(`echonote:transcripts:{account_bid}`,文档
DisplayName=`transcript:{task_bid}`,句级行内 `[HH:MM:SS]` 时间标记)——全局搜正文 /
文档问答 / 生词反向索引经 knowledge 读面直接消费;素材删除时客户端按 DisplayName
双删 KB 文档(契约见 knowledge.md)。预览管线产物同构但**不入 KB**。

## AI 写歌管线(ai_song_preview_v1 / ai_song_full_v1)

> 📘 **客户端对接看这份**:[`aisinger-client-contract-v1.0.md`](aisinger-client-contract-v1.0.md)
> —— 从冷启动到出歌到付费的完整闭环(含签名、时序、六条硬约束、上线自检清单)。
> 本节是平台侧的端点与语义说明,两者冲突以代码为准。

两条独立管线,**两次独立冻结与结算** —— 用户先花小钱看两个方向,选定后再出完整版,
第一步就能停下来。

| `pipeline_code` | 内容 | 回听验收 | 积分(default/free) |
|---|---|---|---|
| `ai_song_preview_v1` | 两段 30 秒方向试听(Lyria 3 Clip ×2) | 否 | 100 |
| `ai_song_full_v1` | 完整歌 + 回听验收 + 词级时间轴(Lyria 3 Pro) | 是 | 115 |

一首歌 = 预览 100 + 成品 115 = **215 积分**。

### 提交(复用 `POST /v1/tasks`,零新端点)

```json
{
  "pipeline_code": "ai_song_full_v1",
  "params": {
    "prompt": "…",                          // 必填。风格/乐器/BPM/情绪/曲式;歌词直接写进来;
                                            //   纯伴奏写 "Instrumental only, no vocals";
                                            //   时长也在这里说(如 "create a 2-minute song")
    "lyrics": "今天是你的生日…",              // 可选。**用户确认的那份词**,仅用于回听比对
    "vocal_mode": "vocal",                  // 可选 vocal|instrumental,默认 vocal
    "target_duration_ms": 150000,           // 可选。仅用于时长判据,1..600000
    "language_hints": ["zh"],               // 可选 ≤4 项,回听语言提示
    "reference_image_bids": ["…"],          // 可选 ≤10 张,**资产 BID 不是 URL**
    "variant_a_label": "温暖",               // 预览管线可选 ≤64 字节,见下「两段试听的名字」
    "variant_b_label": "明亮"
  },
  "idempotency_key": "…", "confirmation": {…}
}
```

### 客户端必须遵守的六条

| # | 约束 | 不遵守的后果 |
|---|---|---|
| **C1** | `prompt` / `lyrics` 上限按**字节**算(各 8000),不是字符 | 3000 个汉字 = 9000 字节 → 40001;而前端「字数」显示是没超的 |
| **C2** | `reference_image_bids` 只收**资产 BID**,不收 URL | 传 URL → 40001。平台不替客户端去取任意地址 |
| **C3** | `lyrics` / `vocal_mode` / `target_duration_ms` 只喂**验收判据**,不进上游 —— 真正决定产物的是 `prompt` | 三者与 `prompt` 说的不一致时,一首正确的歌会被判不合格并重做(照样扣费) |
| **C4** | 缺省即跳过:不给 `lyrics` → 不判歌词保真;不给 `target_duration_ms` → 不判时长 | 以为验了,其实没验 |
| **C5** | 成品时长只许从 `GET /v1/app/config` 的 `song.duration_options_ms` 里选(当前 **90/120/150/180 秒**)。**30 秒只存在于预览**,60 秒及以下不提供 | Pro 有约 60 秒下限(要 45 秒实测给 59–74 秒,18/18 全超);给一个下限附近或以下的档 = 每次都判不合格并重做,而积分照扣 |
| **C6** | 不做高音质档 —— **只出 MP3**,上游不支持 WAV | — |

### 验收与重做

成品管线在生成步骤内部回听产物并判三条:**歌词照唱 / 唱法正确 / 时长在容差内**。
不合格 → 该步骤按 `retry_policy` 重跑(= 重新生成),次数还受全局尝试预算约束;
仍不合格则任务终态失败,`error_code` 为下列之一(客户端据此选话术):

| `error_code` | 含义 | 建议动作 |
|---|---|---|
| `lyrics_mismatch` | 唱的词与提交的词差太多 | 改歌词后重试 |
| `vocal_detected` | 要纯伴奏却唱出了人声 | 直接重试 |
| `duration_out_of_range` | 时长不在容差内 | 改时长参数 |
| `content_filter_unspecified` | 上游安全过滤器**非确定性**拦截(实测 6.7%) | 直接重试,同样的输入多半就过了 |

⚠️ **回听不可用时(ASR 故障)按未验收交付**,不重做 —— 重做对「ASR 挂了」毫无帮助。
此时产物照常返回,`output_metadata` 标注未验收。

### 产物落在候选层(不是资产)

每段音频 = 一个**候选**(`gen_task_candidates`),`content_type=audio`,
词级时间轴作为该候选的 `role=sidecar` 子文件。任务详情里给 `candidate_bids`,
按 `candidate_index` 升序即 A、B。

| 动作 | 端点 | 效果 |
|---|---|---|
| 试听 | `GET /v1/tasks/:bid` → `candidates[]` | 播放 URL presigned |
| 选定这一版 | `POST /v1/candidates/:bid/save` | 音频固化成资产,时间轴作为 sidecar 资产一并固化(`metadata.sidecar_of` 指回音频) |
| 丢弃另一版 | `POST /v1/candidates/:bid/discard` | 立即作废 |
| 我的作品(跨任务) | `GET /v1/accounts/me/candidates` | 7 天内的全部候选 |

**保留期 7 天**(`pipelineCandidateTTL`,平台常量,**与会员等级无关**)。
到期 `CandidateExpiryWorker` 连 R2 对象一起删 —— **主文件与 sidecar 一并删除**。

> ⚠️ **`save` 会让作品变成永久保留**:资产的 `expires_at` 默认为空,
> 目前只有「订阅到期」事件才会给它设过期。若产品的保留期就是 7 天,
> **不要调 `save`** —— 候选层本身就是「7 天有效的我的作品」。

#### 词级时间轴

```jsonc
"output_metadata": { "refs": {
  "audio_sha256": "…",                    // 时间轴与音频的绑定锚 —— 换了音频这个值就变
  "duration_ms": 150000,
  "word_timings": 149,                    // 词级时间戳条数
  "alignment_precision": "word",          // word | line | none —— **绝不上调**
  "lyric_timeline_key": "…",              // 时间轴 JSON 的存储 key(候选 sidecar 同一份)
  "lyric_timeline_schema": "lyric_timeline_v1"
}}
```

时间轴文件本身:

```jsonc
{
  "schema": "lyric_timeline_v1",          // ← 写歌**自己的** schema
  "source_schema": "transcript_v1",       // 内容当前由回听产物派生,如实记录来源
  "alignment_precision": "word",
  "duration_ms": 150000,
  "audio_sha256": "…",
  "word_timings": 149,
  "lines": [ { "idx":0, "t0":1200, "t1":5800, "text":"…",
               "words":[{"t0":1200,"t1":1650,"w":"今"}] } ]
}
```

> `lyric_timeline_v1` 与听语的 `transcript_v1` 是**两个 schema**,各自演进。
> 客户端请判 `schema` 字段,不要假设它等同于转写格式。

`alignment_precision` 如实声明精度:`word` 才能做逐字高亮,`line` 只能行级,
`none` 只能静态展示。**平台绝不按总时长平均分配来伪造时间轴。**

### 两段试听的名字

平台**不提供**方向词表 —— 平台没有按「温暖/明亮」这类词去引导生成,
凭空起个名字就是编(PRD §13.2 同类禁令)。两条路,产品选一条:

| 做法 | 客户端要做的 |
|---|---|
| **不给标签**(默认) | 按 `candidate_index` 升序显示「版本 A / 版本 B」 |
| **自带标签** | 提交时给 `variant_a_label` / `variant_b_label`(≤64 字节,自由文本);平台原样带回 `candidates[].metadata.variant_label` |

标签是**客户端自己的词**,所以永远不会出现「客户端不认识的取值」——
契约里那句「标识是开放集合、客户端不许写死」由此不再适用。

### 进度

见 §SSE 的「管线任务的阶段进度」——
预览 `0% composing → 50% composing → completed`;成品 `0% composing → completed`。

## 音乐 → MV 管线(songlet_lyric_video_v1 / songlet_chorus_mv_v1 / songlet_full_mv_v1)

> 来源:ADR-043 · 处理器 `internal/creation/infra/postprocess/{ffmpeg_audio_slice,image_keyframes,provider_video_segments,ffmpeg_mv_assemble}_processor.go` ·
> 校验器 `app/command/mv_submit_validator.go` · seed `20260928c` / `20260928d`。复用 `POST /v1/tasks`(`pipeline_code`),零新端点。

### 提交(复用 `POST /v1/tasks`)

| 参数 | 类型 | 说明 |
|---|---|---|
| `song_candidate_bid` | string | **必填**。歌曲候选 bid,必须已 Save(`status=selected`),否则 `40876`(D-5:MV 只建在已保存的歌上,候选会过期)。跨账号 / 不存在 `45400` |
| `photo_asset_bids` | string[] | 可选 ≤10。只作**风格参考**(色调 / 场景),不做真人驱动;须 uploaded 的 image,过期 `40877` |
| `aspect_ratio` | string | `9:16`(缺省)/ `16:9` / `1:1` |
| `quality` | string | `standard`(缺省,720p 档)/ `high`(1080p 档;模型侧按能力表挑 1080p / 2K) |
| `chorus_start_ms` / `chorus_end_ms` | int | 可选,同进同退;副歌管线的窗(4–60 s),缺席 = 服务端取歌曲中段 30 s |
| `subtitles` | bool | 可选;烧录歌词字幕(缺省 true;无回听时间轴的歌没有字幕) |
| `lyrics` / `title` / `style` / `region` | string | 可选;分镜提示词变量。`lyrics` 缺省取歌曲候选自带的模型歌词;`region` 只作文化偏好,不路由不阻断 |

服务端注入(客户端携带即删):`_mv_song` / `_mv_timeline_url` / `_mv_photo_urls` / `duration`(per_second 计价量纲 = 歌曲秒数向上取整)。
歌曲 > 190 s → `40878`。

### 三条模板

| 模板 | 形态 | 价 | 预计 |
|---|---|---|---|
| `songlet_lyric_video_v1` | 一张 AI 背景图(Ken Burns)+ 歌词字幕 + AI 角标 | 0 / 次 | ~2 分钟 |
| `songlet_chorus_mv_v1` | 30 s 副歌窗 → 3 段 AI 视频(锚 11 s / 锚 11 s / 桥 8 s)+ 字幕 + 角标 | 2169 / 次 | ~10 分钟 |
| `songlet_full_mv_v1` | 整曲 15 s 一段(锚锚桥,≤12 段)+ 字幕 + 角标 | 69 / 秒,min 4140 | ~30 分钟(180 s 歌) |

### 产物(`GET /v1/tasks/:bid` 终态)

单候选(`content_type=video`,mp4 H.264 + AAC),`candidates[].metadata`:`kind=mv` · `mode=segments|still` · `width/height/fps` · `segments` ·
`window_start_ms/window_end_ms` · `ai_badge=true` · `badge_text` · `subtitles` · `song_asset_bid` · `song_sha256`。
AI 角标烧进像素(右下安全区,进程内生成不依赖字体),容器元数据另写 `comment=AI-generated`;**不可关闭**。

### 进度 / 取消 / 失败

- 进度:SSE `progress` 按阶段 `slicing → storyboarding → keyframing → rendering(每段一帧)→ assembling`;轮询走 `pipeline` 块(ADR-038,同源同值)。
- 取消:processing 中 `POST /v1/tasks/:bid/cancel` → `data.outcome=cancel_requested`,worker 在段间 / 步间空隙终结为 `cancelled`,已完成付费步按权重分摊(ADR-037)。已渲的段留在 R2 断点里,同一任务重试不重复付费。
- 失败码(`failure.code`):`mv_storyboard_invalid` / `mv_keyframe_failed` / `mv_segment_render_failed`(平台侧,可重试)· `mv_no_capable_model`(等待)·
  `mv_assemble_failed` / `mv_plan_uncoverable`(联系客服);上游规范码(`content_filtered` / `rate_limited` …)经 ADR-033 上卷原样带出。

## 分片直传(multipart 四段式 — 听语 P-5′)

弱网大文件断点续传(与 `/v1/uploads/sign` 单 PUT 互补)。S3 约束:除末片外每片 ≥5MiB。

| 步骤 | 端点 | 说明 |
|---|---|---|
| 1 | `POST /v1/uploads/multipart/init` | 入参同 sign(+`part_size` 可选,clamp 5–64MiB 默认 8MiB);hash 命中短路 `dedup_hit`;响应 `{bid, key, upload_id, part_size, part_count}` |
| 2 | `POST /v1/uploads/multipart/sign-part` | `{bid, part_number}` → `{url, expires_at}`(1h);客户端 PUT 分片并记录响应头 `ETag`;可乱序/重试 |
| 3 | `POST /v1/uploads/multipart/complete` | `{bid, parts:[{part_number, etag}]}` → S3 合并 → 委派 finalize(HEAD size 校验 / pending→uploaded / 去重 fallback),响应同 finalize |
| 4 | `POST /v1/uploads/multipart/abort` | 显式取消(清理已传分片 + pending 软删);静默弃传由 PendingUploadCleanup 定期 Abort 收口 |

## 迭代谱系(Derivation Lineage — Plan-Lineage v1)

> 设计: 主表内嵌 + root 反规范化 (D1), 谱系即 `gen_generation_tasks` 行列 — 与任务创建同事务原子。
> 命名红线: `parent_task_id` 已被 N-Generation fanout 占用 (任务内部拆分), 谱系一律 `derived_from_*` /
> `derivation_*` 前缀; fanout 子任务不携带谱系字段, 天然不入树。迁移: `docs/migrations/p_task_derivation_lineage_20260612.sql`。
> 上限 (D9, 写侧硬卡 40871): 深度 ≤ **32**, 单树 ≤ **500** 节点 — 读侧永远完整返回, 不截断。
> 存量任务零回填 (D8): 谱系从启用日生长, 历史任务 lineage 返单节点树。

### 派生类型 × 源类型合法性矩阵(D2,DerivationTypeRegistry 守卫)

| type | derived_from (task) | source_candidate | source_asset | 附加校验 | 源存活要求 | 版本 |
|---|---|---|---|---|---|---|
| `rerun` | 必填 | 可选 (信息性) | ✗ 拒 40873 | — | 父任务行存在即可 (含 failed) | v1 |
| `param_adjust` | 必填 | 可选 (信息性) | ✗ 拒 40873 | — | 同上 | v1 |
| `model_switch` | 必填 | 可选 (信息性) | ✗ 拒 40873 | 新模型版本 ≠ 父任务 (40873); 管线任务无模型身份 → 40873 | 同上 | v1 |
| `shot_regen` | 必填 | 可选 (信息性) | ✗ 拒 40873 | 父任务必须携带 `workflow_context` 锚点 (40873) | 同上 | v1 |
| `asset_edit` | **服务端回填** (显式携带 → 40004) | ✗ 拒 40873 | **必填** | 源资产同账号同租户 (40872 同码隐匿); `derived_from` 由源资产 `source_task_id` 自动解析, 上传资产自成谱系根 (depth=0); 原子编辑管线携带顶层 `params.source_asset_bid` 时**自动装配**本声明 (显式声明优先) | 源资产存在且非 `pending` 上传态 (40874) | ADR-019 |
| `extend` / `upscale` | — | — | — | **W1 预留** — registry 注册即生效 (源=产物, 必须存活) | — | W1 |

通用行 (全类型): 父任务同账号同租户 (40872, **不存在与跨户同码同文案** — 不泄漏存在性);
候选源须属父任务 (`task_id`/`source_task_id` 对位) 且非 `discarded` (40874; `expired` 放行作信息性引用 — D7 墓碑);
candidate ⊕ asset 互斥 (40873); fanout 子任务不可作谱系父 (40873); 深度/树规模 (40871)。

### GET /v1/tasks/:bid/lineage

谱系树查询 (G2) — 给定任意节点返回**整棵树**的扁平节点表 (邻接表, 客户端按 `derived_from_task_bid` 建树)。
单查询走 `idx_tasks_lineage_root` partial 索引一把捞; ≤500 节点一次返回, 无分页。
跨账号/不存在同码 **40420**。fanout 子任务 bid 深链自动上爬到父任务。

```json
{
  "root_task_bid": "01975f2e-...",
  "nodes": [
    { "bid": "01975f2e-...", "derivation_type": "", "status": "completed", "model_code": "gemini-3.1-flash-image",
      "depth": 0, "created_at": 1765500000,
      "thumb": { "candidate_bid": "...", "url": "https://r2.../k.png", "state": "asset" },
      "anchor": { "run_bid": "0197...-run", "node_id": "gen_images" }, "is_current": false },
    { "bid": "01976a01-...", "derived_from_task_bid": "01975f2e-...", "derivation_type": "param_adjust",
      "status": "processing", "model_code": "gemini-3.1-flash-image", "depth": 1, "created_at": 1765586400,
      "thumb": { "candidate_bid": "...", "state": "expired" }, "is_current": true }
  ],
  "total": 2, "is_capped": false
}
```

字段语义:
- `thumb.state`: `live` (ready 候选, url=1h 签名) / `asset` (已固化, url 有效 — asset 复用候选 R2 key) /
  `expired` / `discarded` (**墓碑** — D7: url 空, 血缘与参数仍可查; 谱系引用**不**构成候选 TTL 续期 R6); 无非 pending 候选 → `thumb` 缺省
- `anchor`: 任务 `workflow_context` 透出的 Run 定位 (G4/D5, task 侧单一真相); 非 workflow 任务缺省
- `is_current`: 入口节点高亮 (版本条 UI)
- `is_capped`: 防御性字段 — 写侧硬卡后恒 false

### GET /v1/tasks/:bid/compare?with=\<bid\>

版本对比 (G3) — `params` 结构化 diff (读时计算零存储) + 产物并排引用。
双侧各自确权, 任一不属请求者 → **40420 同码**; 自比 → 40033; **不要求同树** (`same_tree` 告知)。

> 路由形态: Plan 草案为 `GET /v1/tasks/compare?a=&b=`; Hertz 同方法下静态段 `/tasks/compare`
> 与参数段 `/tasks/:bid` 注册冲突 (panic), 落地为 `/:bid/compare?with=` — 语义等价, 校验完全对称。

```json
{
  "a": { "bid": "...", "status": "completed", "model_code": "...", "depth": 0, "created_at": 1765500000,
         "candidates": [ { "candidate_bid": "...", "url": "https://r2.../1.png", "state": "live" } ] },
  "b": { "bid": "...", "status": "completed", "model_code": "...", "depth": 1, "created_at": 1765586400,
         "candidates": [ { "candidate_bid": "...", "state": "expired" } ] },
  "same_tree": true,
  "params_diff": [
    { "path": "prompt", "kind": "changed", "a": "霓虹雨夜...", "b": "暴雨夜..." },
    { "path": "style.motion", "kind": "added", "b": "zoom_in" }
  ]
}
```

diff 语义: 深层递归 (深度 ≤8, 超深子树整值比较); 数组整值比较; media 类字段按字符串比较
(URL 不同即不同 — v1 不做内容指纹); 服务端私有键 (`_` 前缀, 如 `_compose_media`) 不参与;
输出按 `path` 字典序确定性排列。`kind ∈ {added, removed, changed}`。

### 客户端「重做」升级(D8,渐进增强零强制)

旧客户端 (纯 `input_params` 回填 POST) 零破坏 — 产生无血缘根任务, 与历史一致。
新客户端重做面板提交时附 `derivation`: 表单未改 → `rerun`; 改参 → `param_adjust`;
换模型 → `model_switch`; 长按候选发起时带 `source_candidate_bid`。
版本条数据 = lineage 端点 `nodes[]` (同辈 = `derived_from_task_bid` 相同, `is_current` 高亮)。

### 运营度量(D10,离线 SQL)

收敛轮次分布 / 派生类型分布 / 第几轮 Save / showcase 复刻归因 — 单表 SQL 可算,
见 [docs/ops/lineage-metrics.md](../ops/lineage-metrics.md)。不建实时看板 (1G 单机, API-Only 定位)。

## 任务级提示词预设(`gen_prompt_templates`)

**Phase 3 GAP-P3-002 落地** — 与 Prompt BC `pt_prompt_templates`(Agent Builder 层)分层共存。分层规约见 [audit-prompt-template-overlap.md](../architecture/audit/audit-prompt-template-overlap.md);完整方案见 [docs/plan/gen-prompt-templates-implementation-plan.md](../plan/gen-prompt-templates-implementation-plan.md)。

数据模型:
- 表:`gen_prompt_templates`(`docs/migrations/creation_pipeline_migration.sql:7-29`)
- 隔离:`tenant_id` + `template_code` 二维 UNIQUE;`is_system=true + tenant_id=0` 跨租户系统内置可读,普通预设按租户隔离
- 字段:`content_template`(text/template 语法,经 Prompt BC Renderer 渲染)· `task_type` · `model_code` · `parameter_schema`(JSON Schema 声明)· `is_active`(软下线)· `sort_order`
- Seed:`docs/migrations/p9_01_gen_prompt_templates_seed.sql`(5 个内置:code_generator / image_describer / markdown_polish / email_draft / sql_explainer)

### GET /v1/prompt-templates

> 来源:`internal/creation/port/http/gen_prompt_template_handler.go::List`

列出当前租户 + system 内置的所有 active 模板,按 `sort_order ASC, id ASC`。可选 `?task_type=` 过滤。

```
GET /v1/prompt-templates
GET /v1/prompt-templates?task_type=chat
```

响应:

```json
{
  "code": 0,
  "data": {
    "items": [
      {
        "bid": "...",
        "template_code": "code_generator",
        "template_name": "代码生成 / Code Generator",
        "content_template": "You are an expert {{ .language }} engineer. ...",
        "task_type": "chat",
        "model_code": "",
        "parameter_schema": {
          "language":    {"type": "string", "required": true, "description": "目标编程语言"},
          "requirement": {"type": "string", "required": true, "description": "代码需求描述"}
        },
        "is_system": true,
        "is_active": true,
        "sort_order": 10,
        "version": 1,
        "created_at": "..."
      }
    ],
    "total": 5
  }
}
```

### GET /v1/prompt-templates/:code

> 来源:`internal/creation/port/http/gen_prompt_template_handler.go::GetByCode`

按 `template_code` 单查,双轨语义:优先匹配租户级,次选 system 内置。

错误:
- `404 NotFound` — `ErrGenPromptTemplateNotFound`(`creationRepo.ErrGenPromptTemplateNotFound` sentinel)

```
GET /v1/prompt-templates/code_generator
```

### 三级 cache(实施细节)

服务端 Resolver 走 **L1 in-process TTL(60s 正 / 30s 负,sync.Map + atomic.Int64 + lazy eviction)→ L2 Redis(`AIGC:gen_pt:{tenant_id}:{template_code}` 5min 正 / 60s 负)→ L3 DB**。Redis op 失败容错降级直读 DB,负缓存防穿透。详见 [`internal/creation/app/service/gen_prompt_resolver.go`](../../internal/creation/app/service/gen_prompt_resolver.go)。

### 守卫红线

Creation BC 严禁直接 import `text/template` — 由 [`tests/archtest/creation_no_text_template_test.go::TestCreationDoesNotImportTextTemplate`](../../tests/archtest/creation_no_text_template_test.go) 阻断回归。任何模板渲染必须经 `creationPort.GenPromptRenderPort`,在 `internal/bootstrap/bridges.go::creationGenPromptRenderPortBridge` 委派到 `prompt.PromptAPI.RenderInline`(复用 Prompt BC 唯一渲染沙箱:100ms 超时 / 64KB 上限 / `missingkey=error` / 白名单 FuncMap)。

## 提示词辅助(`POST /v1/prompt-assist`,p9_05)

**移动端「增强提示词」/「扩写提示词」按钮通用入口**。这是 Creation BC 暴露的薄层 HTTP 端点,内部经 `capability.CapabilityAPI.Invoke(SurfaceInternal)` 走 Capability 14-step middleware chain — 自动获得 Wallet 计费 / Safety 审查 / Cache 1h 命中 / Quota / 背压 / 审计。完整方案见 [docs/plan/提示词辅助_完整实施方案_v2.md](../plan/提示词辅助_完整实施方案_v2.md)。

### 数据模型

- 模板:`pt_prompt_templates` + `pt_prompt_versions`(Prompt BC,**非 `gen_prompt_templates`** — 后者是 AIGC 任务层预设)
- Seed:`docs/migrations/p9_04_prompt_assist_templates.sql`
  - `prompt_assist_enhance`(润色优化)· `prompt_assist_expand`(补充扩写)
  - `tenant_id=0` + `workspace_id=0` + `is_shared=true` 跨租户共享
  - `template_type='system_prompt'`(给 LLM 的角色指令)
- Capability:`prompt_assist` v1.0.0 published(`docs/migrations/p9_05_prompt_assist_capability.sql`)
  - `cap_invocation_surfaces.surface_kind='internal'`(仅 internal surface,不暴露 admin direct_api)
  - `cache_policy={idempotent:true, ttl_seconds:3600}`(同 input 1h 内 cache 命中 ~10ms 不计费)
- 定价:`wal_credit_pricing_rules`(`entity_type='capability'`, `entity_code='prompt_assist'`)
  - default / member / enterprise = 1 credit/次
  - free = 2 credit/次

### POST /v1/prompt-assist

> 来源:`internal/creation/port/http/prompt_assist_handler.go::Assist`

请求体:

```json
{
  "mode":             "enhance" | "expand",     // 必填
  "text":             "用户原始提示词",          // 必填, 1..2000
  "language":         "zh-Hans",                // 可选, 默认 zh-Hans (跟随 app locale)
  "scene_hint":       "store_screenshot",       // 可选, 业务场景标签 ..100
  "model_hint":       "model_version_bid",      // 可选, 覆盖 config 默认模型
  "idempotency_key":  "<client-uuid>"           // 可选, 命中 cache 复用结果
}
```

⚠️ **严禁在 body 传 `account_id` / `app_id` / `tenant_id`** — Handler 从 JWT + HMAC middleware 注入的 ctx 读取,body 字段会被忽略(防越权计费)。

响应:

```json
{
  "code": 0,
  "data": {
    "result_text":  "优化 / 扩写后的提示词文本",
    "mode":         "enhance",
    "language":     "zh-Hans",
    "model_used":   "<model_version_bid>",
    "cost_credits": 1,        // cache 命中 = 0
    "cache_hit":    false     // true 时 ~10ms 返回, 不计费
  }
}
```

### 错误码映射

`capability` 14-step chain 返回的 `ExecutionResult.ErrorCode` → HTTP envelope `code` 字段:

| ErrorCode | code | 客户端处理建议 |
|---|---:|---|
| `invalid_input` / bind fail | `40030` | 修正参数后重试 |
| (无 ctx account_id) | `40103` | 重新登录拉新 JWT |
| `permission_denied` | `40300` | 权限不足 |
| `insufficient_credits` | `40200` | 引导充值(WalletNotifier) |
| `wallet_unavailable` / `pricing_*` | `50230` | 钱包停用或服务端定价未配 —— **不要**引导充值,提示联系支持 |
| `safety_blocked` | `40330` | "内容含敏感词,请修改" |
| `prompt_render_failed` | `45013` | 服务端模板异常,提示重试 |
| `quota_exceeded` / `queue_full` / `backpressure` | `50385` | 指数退避重试 |
| `timeout` | `50410` | "服务繁忙,请稍后重试" |
| `canceled` | `49900` | 用户取消 |
| 其他(provider_error / no_model / executor_error / unknown) | `50000` | 内部错误,降级 |

> **`insufficient_credits` 自 2026-08-17 起是 `40200`(此前误用 `40301`)**:`40301` 在全仓语义是
> 「权限拒绝 / 账号锁定」(tenancy·catalog·runtime·tool 的 permission_denied、identity 的
> account locked、iap 的 not authorized 都用它),余额不足混用会让客户端走"没权限"分支而非
> "去充值"。现与 capability / creation `GetErrorCode` / runtime 四家统一到 402 Payment 段。
>
> 响应 `message` 一律是固定英文常量,**不含**上游 capability 文案与任何内部 ID
> —— 排障看服务端日志(见 [error-codes.md](error-codes.md) 响应内容红线)。

### 移动端集成要点(Flutter)

完整代码示例见方案 §10。关键 UX:

1. **按钮 loading 态** — LLM ~1-2s,按钮 loading 期间禁重复点击
2. **enhance 替换 / expand 可选** — `enhance` 默认替换原文,`expand` 提示用户「替换」或「另存」
3. **撤销** — 替换后本地暂存原文,提供一次撤销(不调后端)
4. **空文本禁用** — `text` 空时按钮 disabled(对齐 schema `minLength: 1`)
5. **积分预校验** — 调用前余额低于单次成本,先弹充值

### 红线(方案 §13 全量)

- 模板归 `pt_*`(双表版本化),**不**用 `gen_prompt_templates`
- `template_type='system_prompt'`(给 LLM 的角色,非用户消息模板)
- 移动端**不**直接调 `/v1/capabilities/prompt_assist/invoke`(admin gated 返 40300)
- `SurfaceKind` 硬编码 `internal`,客户端无法覆盖
- `mode → slug` 走白名单 map(防模板注入),Executor + Schema + Handler 三道防御
- Executor 不依赖 Creation BC(由 `tests/archtest/prompt_assist_boundary_test.go::TestPromptAssistExecutorNoCreationDep` 守卫)

## 内部回调

### POST /v1/internal/tasks/:bid/complete
**内部端点**(无 JWT,内网调用)。供应商 webhook 或内部 worker 通知任务完成。

```json
{
  "outputs": [{ "type": "video", "url": "https://provider-cdn/...", "metadata": {...} }],
  "usage": { "amount": 8, "unit": "second", "cost": 800 },
  "error": ""                       // 非空表示失败
}
```

行为:
- 转存 R2 + 资产落库(`gen_assets`)
- Wallet `ConfirmFreeze(actual_cost)` 或 `RefundFreeze`(失败)
- 改 `gen_generation_tasks.status` 终态
- 触发 SSE 通知前端(若有连接)

> 现状订正(2026-08-15,P6 核查期发现本段为陈旧断言):Creation 域 Outbox **已实装** ——
> `TaskOutboxPublisher.FinalizeCompleted/FinalizeFailed`(`app/command/outbox_publisher.go`)
> 在 UpdateStatus 同事务内 outbox.Save + 标 `events_published`;管线 task-primary 路径
> 经 `PipelineOutboxPublisher`(T6)同构接入;步骤级账务事件 `creation.pipeline_step_settled`
> 于台账写入点同事务发出(P3 R2)。`idx_tasks_unpublished` 服务于未发布行的补投查询。

## 通用文件直传(presigned PUT)

### POST /v1/uploads/sign

> 来源:`internal/creation/port/http/upload_handler.go::SignUpload`
> 业务:`internal/creation/app/command/request_upload_url_handler.go`
> 校验:`internal/creation/domain/service/upload_policy.go`

**用途**:为前端 ParamSchemaForm **文件参数字段**(以及任何 BC 共享的文件输入场景)生成 R2 presigned PUT URL,客户端拿到后直传到 R2,完成后把 `public_url` 回填到任务参数里。

**鉴权**:JWT(标准 `RegisterAuthenticatedRoutes`)+ 全局 App 签名(全局生效,本端点不在 SkipPaths)。

#### 请求

```http
POST /v1/uploads/sign
Authorization: Bearer <jwt>
Content-Type: application/json

{
  "mime_type": "image/png",
  "size":      102400,
  "filename":  "logo.png",
  "file_hash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
}
```

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `mime_type` | string | ✓ | 文件 MIME(白名单,见下) |
| `size` | int64 | ✓ | 字节数,> 0,默认上限 50 MiB |
| `filename` | string | ✓ | 原始文件名(用于决定扩展名,**不**作为对象 key 一部分,长度 ≤ 255) |
| `file_hash` | string | ✓ | **必填(2026-06-20 起)**;文件内容 SHA-256,**64 字符 lowercase hex**;上传去重必需(presigned 通道服务端看不到字节,只能客户端算 hash)。缺/空 → `40001`,格式错 → `40001`/`40037`。详见下文「双段式 Step 1」的 file_hash 去重说明。 |

#### 响应

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "put_url":    "https://genaistudio.<account>.r2.cloudflarestorage.com/uploads/0/0193b9a0-7c8d-7e3f-9a01-abcdef012345/2026/05/26/01988f30-1234-7e3f-9a01-bbbbbbbbbbbb.png?X-Amz-Algorithm=...&X-Amz-Signature=...",
    "public_url": "https://r2.showsapp.org/uploads/0/0193b9a0-7c8d-7e3f-9a01-abcdef012345/2026/05/26/01988f30-1234-7e3f-9a01-bbbbbbbbbbbb.png",
    "expires_at": 1714555800,
    "key":        "uploads/0/0193b9a0-7c8d-7e3f-9a01-abcdef012345/2026/05/26/01988f30-1234-7e3f-9a01-bbbbbbbbbbbb.png"
  }
}
```

| 字段 | 类型 | 说明 |
|---|---|---|
| `put_url` | string | R2 直传 URL(含签名);TTL 5 分钟,过期即失效 |
| `public_url` | string | 上传成功后的公网 URL(CDN 域名);**回填到参数字段的就是这个** |
| `expires_at` | int64 | `put_url` 过期 Unix 秒(= 现在 + 300s) |
| `key` | string | 对象桶内路径(调试用,业务无需保存)|

#### 客户端 PUT 步骤

```http
PUT <put_url>
Content-Type: image/png    # 必须与 sign 请求的 mime_type 一致
Content-Length: 102400

<bytes>
```

R2 200 OK 即表示上传成功。**Content-Type 不一致会被 R2 直接拒绝(签名验失败)**。

#### MIME 白名单(默认策略)

| 类别 | 允许的 MIME |
|---|---|
| 图像 | `image/png` `image/jpeg` `image/webp` `image/gif` `image/heic` `image/heif` |
| 视频 | `video/mp4` `video/quicktime` `video/webm` |
| 音频 | `audio/mpeg` `audio/wav` `audio/x-wav` `audio/mp4` |
| 文档 | `application/pdf` `text/plain` `text/markdown` |

不在白名单的 MIME(如 `application/vnd.ms-excel`、`application/x-msdownload`)直接 40034 拒绝。如有新场景需求,在 `domain/service/upload_policy.go::DefaultUploadPolicy` 扩展。

#### 错误码

| HTTP 状态 + code | 含义 | 触发 |
|---|---|---|
| 400 / 40001 | 参数校验失败(字段级,带 `details`) | **`file_hash` 缺失/空/格式错**(64 字符 lowercase hex),或 mime/size/filename 字段级非法 |
| 200 / 40034 | 不支持的文件类型 | mime 不在白名单 |
| 200 / 40035 | 文件大小超过限制 | size > MaxBytes(默认 50 MiB) |
| 200 / 40037 | file_hash 格式非法(P6-04 域层) | `file_hash` 非 64 字符 lowercase hex(域层二次把关) |
| 50100 | 当前存储后端不支持直传 | `storage.provider=local`(开发模式)|
| 401xx | 未授权 | JWT 缺失或失效 |
| 40110-40114 | 签名错误 | App 签名 header 缺失或不匹配 |

#### 在 ParamSchemaForm 中的使用

ParamSchema 的文件参数(`type=string` + `format=uri` + `x-input-type=file`)由前端识别后:
1. 文件选择 → `POST /v1/uploads/sign` 拿 `put_url + public_url`
2. 浏览器 PUT → R2
3. 表单 onSubmit 时 `params: { reference_image: <public_url> }` 传给 `POST /v1/tasks`

后端 SubmitTaskHandler 把 `public_url` 直接透传给 Provider Adapter — 上游 SDK(Gemini / Runway / DashScope)接受公网可达的 URL 作为输入。

> 注:本端点**不**创建 `gen_assets` 行(参数文件是瞬态输入,Asset 仅落 AI 生成产物)。瞬态文件由 R2 lifecycle policy 定期清理(默认保留 30 天)。

## Candidate(候选层 — P7 Phase 5 引入)

> 来源:`internal/creation/port/http/candidate_handler.go` · 业务:`internal/creation/app/{command,query}/candidate_*_handler.go`
>
> 候选层物理独立于 `gen_assets`,存储在 `gen_task_candidates` 表。AI 任务的所有产出**先落候选**,用户**主动 Save** 后才创建 `gen_assets` 资产。未在 TTL(默认 7 天)内 Save 或 Discard 的候选,由后台 `CandidateExpiryWorker` 清理(R2 对象 + DB 行)。

### 状态机

```
       ┌────────────────────────────────┐
       │                                ▼
   pending ─→ ready ─→ selected (终态)
       │       │
       │       ├─→ discarded (终态)
       │       │
       └───────┴─→ expired (终态)
```

- `pending`:R2 上传中 / 失败,Worker 5min 内重试。客户端可显示但不能 Save。
- `ready`:可见可操作。
- `selected`:用户 Save 后,关联 `asset_bid`。
- `discarded`:用户主动丢弃。
- `expired`:TTL 到期,R2 已清理。

终态不可逆。同一候选 BID 重复 Save 返 `45902 already_selected`;重复 Discard 幂等成功(无副作用)。

### 错误码段(45xxx,候选层专用)

| Code | 含义 |
|---|---|
| `45401` | 批量数量超过上限(50) |
| `45400` | 候选不存在 / 越权 |
| `45901` | 候选未就绪(R2 上传中) |
| `45902` | 候选已保存(重复 Save) |
| `45903` | 候选已过期 |
| `45904` | 候选已丢弃 |
| `45905` | 候选审核中(P8 Safety BC 启用后) |
| `45906` | 候选未通过审核(P8) |
| `45920` | 候选状态转移非法 |

详见 `internal/creation/domain/errors.go::GetErrorCode`(`ErrCandidate*` 段)。

---

### GET /v1/candidates/:bid

查单个候选详情。

#### 响应

```json
{
  "code": 0,
  "data": {
    "bid":              "0193b9a1-aaaa-...",
    "task_bid":         "0193b9a0-...e3",
    "index":            0,
    "status":           "ready",
    "moderation_status":"skipped",
    "content_type":     "image",
    "primary_url":      "https://r2.example.com/gen/0/0193b9a0-7c8d-7e3f-9a01-abcdef012345/2026/05/26/01988f30-1234-7e3f-9a01-aaaaaaaaaaaa.png?sig=...",
    "files": [...],
    "asset_bid":        "",
    "expires_at":       1716364800,
    "created_at":       1715760010
  }
}
```

字段语义同 `GET /v1/tasks/:bid` 响应的 `candidates[]` 元素。越权 / 不存在统一返 `45400`(不暴露 BID 属于谁)。

---

### POST /v1/candidates/:bid/save

把候选提升为正式资产(`gen_assets`)。

#### 请求

```json
{
  "access_level": "private",
  "group_name":   "summer_campaign",
  "tags":         ["banner", "v1"]
}
```

| 字段 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `access_level` | string | `"private"` | `private` / `unlisted` / `public` — 写入 `gen_assets.access_level`,决定后续 URL 模式 |
| `group_name` | string | `""` | 业务分组(资产库筛选用,写 `gen_assets.metadata.group_name`) |
| `tags` | string[] | `[]` | 标签(写 `gen_assets.metadata.tags`) |

#### 响应

```json
{
  "code": 0,
  "data": {
    "candidate_bid": "0193b9a1-aaaa-...",
    "asset_bid":     "0193b9a2-bbbb-...",
    "task_bid":      "0193b9a0-...e3"
  }
}
```

候选 status → `selected`,新建 `gen_assets` 行 lifecycle=`kept`,R2 对象**不复制**(asset 复用候选 R2 key)。

#### 错误码

| HTTP | code | 触发条件 |
|---|---|---|
| 404 | 45400 | 候选 BID 不存在 / 不属于当前账户 |
| 409 | 45901 | 候选 status=`pending`(R2 上传未完成,客户端应等 1-5min 重试) |
| 409 | 45902 | 候选 status=`selected`(已 Save 过,客户端可幂等忽略) |
| 409 | 45903 | 候选 status=`expired`(TTL 到期) |
| 409 | 45904 | 候选 status=`discarded` |
| 409 | 45905 | moderation_status=`pending`(P8 启用 Safety 后) |
| 409 | 45906 | moderation_status=`rejected` |

#### 客户端建议

- **乐观 UI**:点 Save 立即把候选标"已保存",失败再回滚;`45902` 视为成功(已是终态)
- **重试策略**:`45901` 是临时状态,前端可显示"加载中"按钮变灰,3-5s 后自动重试
- **错误展示**:`45906` 显示"该图含敏感内容,无法保存";其他 4xx 统一"操作失败,请稍后重试"

---

### POST /v1/candidates/:bid/discard

丢弃候选(R2 对象由 TTL Worker 异步清理)。

#### 请求

```json
{
  "reason": "user_initiated"
}
```

`reason` 可选,默认 `"user_initiated"`,写入 `gen_task_candidates.discarded_reason`(64 字符上限)。

#### 响应

```json
{
  "code": 0,
  "data": { "status": "discarded" }
}
```

#### 幂等语义

- 候选 status=`discarded` → 直接返成功(用户视角已删,不重复改 DB)
- 候选 status=`selected` → 返 `45902`(已 Save 不能反悔丢弃 — 客户端应改用 DELETE asset 端点)
- 候选 status=`expired` → 返 `45903`

---

### POST /v1/candidates/batch_save

批量保存候选(AIP-136 partial success — 单项失败不影响其他)。

#### 请求

```json
{
  "candidate_bids": ["bid1", "bid2", "bid3"],
  "access_level":   "private",
  "group_name":     "summer",
  "tags":           ["v1"]
}
```

| 字段 | 类型 | 必填 | 约束 |
|---|---|---|---|
| `candidate_bids` | string[] | ✓ | 1-50 元素;重复 BID 自动去重 |
| `access_level` / `group_name` / `tags` | — | — | 对所有成功项统一应用 |

#### 响应

```json
{
  "code": 0,
  "data": {
    "results": [
      { "candidate_bid": "bid1", "asset_bid": "asset1", "status": "saved" },
      { "candidate_bid": "bid2", "asset_bid": "",      "status": "already_selected", "error_code": 45902, "error_message": "..." },
      { "candidate_bid": "bid3", "asset_bid": "asset3", "status": "saved" }
    ],
    "saved":  2,
    "failed": 1
  }
}
```

| `results[].status` | 含义 |
|---|---|
| `saved` | 成功(`asset_bid` 已填) |
| `already_selected` | 45902 已 Save |
| `expired` | 45903 |
| `discarded` | 45904 |
| `not_ready` | 45901 R2 未完成 |
| `not_found` | 45400 |
| `moderation_pending` / `moderation_rejected` | 45905 / 45906 |
| `error` | 50000 服务端异常 |

整体请求 HTTP 仍是 200(partial success);`code=0` 表示请求处理完成,客户端按 `results[].status` 各自处理。

#### 错误码(整体请求级)

| HTTP | code | 触发条件 |
|---|---|---|
| 400 | 40033 | `candidate_bids` 空 |
| 400 | 45401 | `candidate_bids` 超过 50 |

---

### POST /v1/candidates/batch_discard

批量丢弃。请求 / 响应结构与 `batch_save` 镜像(只是字段 `discarded` 替代 `saved`),错误码同上。

```json
{
  "candidate_bids": ["bid1", "bid2"],
  "reason":         "batch_operation"
}
```

```json
{
  "code": 0,
  "data": {
    "results": [
      { "candidate_bid": "bid1", "status": "discarded" },
      { "candidate_bid": "bid2", "status": "already_selected", "error_code": 45902 }
    ],
    "discarded": 1,
    "failed":    1
  }
}
```

---

### GET /v1/accounts/me/candidates

我的草稿(跨任务候选池视图)。前端"草稿池 / 待保存"页用。

#### Query 参数

| 参数 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `status` | string | `"ready,pending"` | 逗号分隔状态过滤;空 = 默认只返用户能操作的(ready+pending) |
| `limit` | int | 50 | 上限 200 |
| `offset` | int | 0 | 分页偏移 |

#### 响应

```json
{
  "code": 0,
  "data": {
    "candidates": [
      { "bid": "...", "task_bid": "...", "index": 0, "status": "ready", "primary_url": "...", ... }
    ],
    "total":  50,
    "limit":  50,
    "offset": 0
  }
}
```

`total` 是当前页大小(P5 不返全表 count;P8+ 加 CountByAccount)。客户端用 `len(candidates) == limit` 判断是否有下一页(经典 keyset 思路)。

---

### 候选层客户端集成建议

| 场景 | 端点 / 字段 | 建议 |
|---|---|---|
| 任务详情页"挑选" | `GET /v1/tasks/:bid` 的 `candidates[]` | 9 张图按 `index` 排,显示 status 角标(ready=可点,pending=加载中) |
| 单图 Save | `POST /v1/candidates/:bid/save` | 乐观 UI:点击即变"已保存",失败回滚 |
| 单图 Discard | `POST /v1/candidates/:bid/discard` | 二次确认弹窗(防误删);删后立即移出列表 |
| 全选保存 | `POST /v1/candidates/batch_save` | 单次 API 调用,UX 流畅;前端按 `results[].status` 显示每张结果 |
| 全选丢弃 | `POST /v1/candidates/batch_discard` | 同上 |
| 草稿池 | `GET /v1/accounts/me/candidates` | 用户离开任务页后再次回访仍能看到自己未操作的候选 |
| 渐进式 UI | `GET /v1/tasks/:bid` polling | 终态前 1-2s polling;`candidate_summary` 驱动进度条 |
| 过期处理 | `candidates[].expires_at` | 客户端在到期前 1 天提示用户"还有 1 天未保存" |

### 候选 ↔ 资产对照

| 维度 | Candidate (gen_task_candidates) | Asset (gen_assets) |
|---|---|---|
| 创建时机 | 任务完成时(Provider 返产物后) | 用户主动 Save 时 |
| TTL | 7 天(过期后 R2 + DB 清理) | 无 TTL(永久) |
| R2 prefix | `gen/` (R2 Key 统一重构 2026-05-26) | 共用候选的 R2 key(**不 CopyObject**) |
| 索引 | `gen_task_candidates.asset_id`(指向 selected 后的 asset) | `gen_assets.source_task_id`(反查任务) |
| 用户可见 | `GET /v1/tasks/:bid` 内嵌 + `GET /v1/accounts/me/candidates` | `GET /v1/assets` 资产库列表 |
| 计费 | 候选生成时已扣分(均摊 N) | Save 时不再扣分(候选已分摊) |

## Asset(生成资产)

### POST /v1/uploads/sign — 直传签名(双段式 Step 1)

> 来源: `internal/creation/port/http/upload_handler.go::SignUpload` · `internal/creation/app/command/request_upload_url_handler.go` · `internal/creation/domain/service/upload_policy.go`

**用途**: 为客户端生成 R2 presigned PUT URL,**同时预创建 pending Asset 行**(`upload_state='pending'`)。客户端 PUT 完成后调 `/v1/uploads/finalize` 把状态推到 `uploaded`。

适用场景(**瞬态参数输入**为主,需要持久素材库的请走 `/v1/assets/upload`):
- ParamSchemaForm 文件参数(image-to-image source / 视频参考图)
- 临时一次性 RAG 文档
- 大文件(BFF 带宽敏感场景)

**鉴权**: JWT + 全局 App 签名。

#### 请求

```http
POST /v1/uploads/sign
Authorization: Bearer <jwt>
Content-Type: application/json

{
  "mime_type":    "image/png",
  "size":         102400,
  "filename":     "logo.png",
  "content_type": "image",      // 可选; 推荐传, 让 finalize 后能被 ListAssets type filter 过滤
  "access_level": "private",    // 可选; 默认 private
  "file_hash":    "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"  // 必填 (2026-06-20 起); SHA-256 内容 hex, 64 字符 lowercase; 上传去重必需
}
```

**P6-04 账户级去重**(`file_hash` **必填** — 2026-06-20 起):
- **`file_hash` 是必填字段**:客户端选定文件后 **必须先在本地算内容 SHA-256 hex**(`crypto.subtle.digest('SHA-256', file)` / Node `crypto.createHash` / Flutter `sha256.convert(bytes).toString()`),把 **64 字符 lowercase hex** 作为 `file_hash` 一并提交。
  - 为什么必填:presigned-PUT 通道客户端**直传 R2、服务端全程看不到文件字节**,无法服务端算 hash → 去重只能靠客户端提供内容 hash。留空会绕过去重、每次新建 R2 对象浪费存储(P6-04 修复根因)。
- server 用 `(account_id, file_hash)` 在 `gen_assets` UNIQUE INDEX `uq_gen_assets_account_file_hash` 上点查:
  - **命中** → 响应 `dedup_hit=true` + `bid` 指向已有 uploaded asset + `put_url=""`,客户端 **跳过 PUT**,直接保存 `bid` 后续引用。
  - **未命中** → 走完整流程(`dedup_hit=false`)。
- **缺字段 / 空值** → `40001 parameter validation failed`,`details.file_hash = "file_hash 必填 (SHA-256 内容 hex, 64 字符 lowercase) — 上传去重必需"`。
- **格式错**(非 64 字符 lowercase hex,含大写)→ `40001`(DTO 形态校验)/ `40037 ErrInvalidFileHash`(域层二次把关)。

#### 响应

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "bid":        "uuid",
    "put_url":    "https://genaistudio.<acc>.r2.cloudflarestorage.com/uploads/0/0193b9a0-7c8d-7e3f-9a01-abcdef012345/2026/05/26/01988f30-1234-7e3f-9a01-cccccccccccc.png?X-Amz-Signature=...",
    "public_url": "https://r2.showsapp.org/uploads/0/0193b9a0-7c8d-7e3f-9a01-abcdef012345/2026/05/26/01988f30-1234-7e3f-9a01-cccccccccccc.png",
    "expires_at": 1735689600,
    "key":        "uploads/0/0193b9a0-7c8d-7e3f-9a01-abcdef012345/2026/05/26/01988f30-1234-7e3f-9a01-cccccccccccc.png",
    "dedup_hit":  false                                                // P6-04: 命中已有素材时为 true, 客户端跳过 PUT
  }
}
```

| 字段 | 说明 |
|---|---|
| `bid` | pending Asset 的 BID,**必须存下** — finalize 时引用。`dedup_hit=true` 时已是 uploaded 终态,**不要再调 finalize** |
| `put_url` | R2 直传 URL(含签名);TTL 5 分钟;**只能 PUT 一次**。`dedup_hit=true` 时为空字符串 |
| `public_url` | finalize 成功后的公网 URL;sign 阶段返回但未生效。`dedup_hit=true` 时直接是已有素材的访问 URL(private 走预签名,public 走公网) |
| `expires_at` | `put_url` 过期 Unix 秒。`dedup_hit=true` 时是 `public_url` 的过期时间(0 表无 TTL) |
| `key` | 桶内路径,业务无需保存 |
| `dedup_hit` | P6-04 命中标记,见上方 file_hash 说明 |

#### 客户端 PUT 步骤

```http
PUT <put_url>
Content-Type: image/png    # 必须与 sign 时一致, 否则 R2 403
Content-Length: 102400

<bytes>
```

PUT 成功后**立即调 finalize**(下文)。

---

### POST /v1/uploads/finalize — 直传确认(双段式 Step 2)

> 来源: `internal/creation/port/http/upload_handler.go::FinalizeUpload` · `internal/creation/app/command/finalize_upload_handler.go`

把 pending Asset 推进到 `uploaded` 终态。服务端会 **HEAD R2** 确认对象真的 PUT 完成,**并校验 R2 实际字节数 == sign 时声明的 `size`**(A2 服务端权威校验:presigned PUT 不强制 `Content-Length`,客户端可声明小 `size` 过 sign 的大小闸、却 PUT 大文件;此处用服务端 HEAD 的真实 size 堵死)。实际 size 与声明不符 → **`40038 ErrUploadSizeMismatch`**(不更状态,客户端可重新 PUT 正确文件后再 finalize)。

#### 请求

```http
POST /v1/uploads/finalize
Authorization: Bearer <jwt>
Content-Type: application/json

{ "bid": "<sign 返回的 bid>" }
```

#### 响应

与 `POST /v1/assets/upload` 同一 schema(前端可复用同一 UI 组件):

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "bid":              "uuid",
    "url":              "https://r2.showsapp.org/uploads/...",
    "thumbnail_url":    "",
    "file_name":        "logo.png",
    "file_size":        102400,
    "mime_type":        "image/png",
    "content_type":     "image",
    "storage_provider": "r2",
    "width":            0,
    "height":           0,
    "duration_seconds": 0,
    "access_level":     "private",
    "tags":             [],
    "group_name":       "",
    "created_at":       1735689600,
    "dedup_hit":        false                                          // P6-04: 并发 race 兜底命中已有素材时为 true
  }
}
```

#### 错误码

| `code` | 含义 | 触发 |
|---|---|---|
| `40420` | 找不到 bid 对应的 Asset(或不属于当前账号) | FindByBIDAndAccount 失败 |
| `40430` | R2 对象不存在(客户端没真 PUT?) | `storage.Exists` 返 false |
| `40038` | 上传对象实际 size ≠ sign 时声明的 `size`(A2 服务端权威校验) | HEAD R2 真实字节数与声明不符 —— 不更状态,**可重新 PUT 正确文件后再 finalize** |
| `40922` | 已 finalize 或处于异常状态 | 重复 finalize / 并发竞争(非 dedup race) |
| `50324` | 分发声明了上传留存期,但此刻读不到(配置库故障)或配置值非法 | ADR-025 fail-close:**不更状态**(仍 pending),**稍后重试 finalize** 即可 |

#### 分发级上传留存(ADR-025,2026-09-25)

分发的远程配置(acfg `config.retention.upload_hours`,整数小时,1–720)声明了留存期时,
finalize 在把资产推到 `uploaded` 的**同一次写入**里设置过期时间 `now + upload_hours`,
到期后由资产清理 worker 删除对象与记录(收藏 / 被主体引用的资产照旧跳过)。

- 未声明的分发:行为与此前完全相同(上传资产不过期)。
- 这个过期时间**不会被订阅续期清除**(订阅机制只撤销它自己设下的过期)。
- multipart 上传的 `complete` 走同一条 finalize 路径,同样生效;`POST /v1/assets/upload`
  直传与外链摄取**不在**本机制范围内。
- 响应里的 `expires_at`(若有)仍是**访问 URL** 的过期时间,不是资产的留存期 —— 字段语义不变。

#### 失败语义

- 客户端 PUT 失败 → 不调 finalize,pending 行由后台清理 worker 兜底(P5 起跳点)
- 客户端调 finalize 但没 PUT → 返 40430,**可重 PUT 后再 finalize**(状态机仍 pending)
- 客户端声明小 `size` 过 sign 大小闸、却 PUT 大文件 → finalize HEAD R2 真实 size 不符 → 返 **40038**,不更状态,**可重 PUT 正确文件后再 finalize**(A2 防绕过大小限制)
- 重复 finalize 同一 bid → 返 40922(乐观条件 `WHERE upload_state='pending'` 不命中)

#### P6-04 dedup race 兜底

并发场景:同账户两端同时调 sign + 各自上传 + 各自 finalize 同一文件。

- 第一次 finalize: 正常 `pending → uploaded`,`(account_id, file_hash)` 进 UNIQUE 索引。
- 第二次 finalize: `pending → uploaded` UPDATE 触发 PG `23505` UNIQUE 冲突。
- handler 自动切到复用路径:
  1. 回查 `(account_id, file_hash)` 命中已 uploaded 的 winning asset
  2. 软删本次 pending 行(避免列表污染)
  3. R2 best-effort delete 本次 PUT 上的对象(避免孤儿)
  4. 返回 winner 的 `bid` + `dedup_hit=true`
- 客户端无感:得到 `200 + dedup_hit=true`,可正常使用 `bid` 引用素材。**不会**收到 `40922`。

---

### POST /v1/uploads/resolve-urls — 批量 key→访问 URL 解析

> 来源: `internal/creation/port/http/upload_handler.go::ResolveURLs` · `internal/creation/app/query/resolve_upload_urls_handler.go` · `internal/creation/domain/service/object_key_builder.go::UploadKeyOwnedBy`

**用途**: 把路径 A(`uploads/`)对象 key 批量解析为可展示访问 URL。首要消费方是**下游产品服务**(genaistudio-products,衣橱 `image_url` 内联)——产品服务转发终端用户 JWT + 以分发密钥重签请求体代调本端点(D6 JWT 同源 + D6-a 分发密钥双供给,零新增 s2s 鉴权面);App 客户端亦可直调。

**鉴权**: JWT + 全局 App 签名(普通认证端点,无特殊处理)。

**归属确权**: 逐 key 按 JWT `account_bid` 匹配 key 第 3 段(`UploadKeyOwnedBy`,纯语法判定零查库)。不归属 / `gen/` 前缀 / 畸形 key → 该条 `url` 空串(fail-quiet),请求整体不报错。

#### 请求

```http
POST /v1/uploads/resolve-urls
Authorization: Bearer <jwt>
Content-Type: application/json

{ "keys": ["uploads/0/<account_bid>/2026/07/11/<uuidv7>.jpg"] }
```

| 字段 | 类型 | 约束 |
|---|---|---|
| `keys` | string[] | 必填,1-200 条,单条 ≤512 字符;仅 `uploads/` 层 key 有效 |

#### 响应

```json
{
  "code": 0,
  "data": {
    "urls": [
      { "key": "uploads/0/…/x.jpg", "url": "https://r2.showsapp.org/uploads/0/…/x.jpg", "expires_at": 0 }
    ]
  }
}
```

| 字段 | 说明 |
|---|---|
| `urls[]` | 与 `keys` **一一对应保序**,`key` 原样回显 |
| `urls[].url` | 访问 URL。公开桶 = CDN URL;私有桶 = presigned GET(按 `private` 级签名,TTL 1h,与 `candidates[].url` 同口径)。**空串** = 不归属/畸形/签名失败 |
| `urls[].expires_at` | Unix 秒;`0` = 永不过期(公开桶)或 url 为空 |

**注意**: 本端点**不做对象存在性检查**(200 条批量逐 key HEAD 成本不可接受)——key 语法合法但对象缺失时 `url` 非空、拉取 404,客户端按图片加载失败回落占位。错误码仅请求级:字段校验失败走 ValidationFailed(HTTP 400),无业务级新码。

---

### POST /v1/assets/upload — 服务端 multipart 直传

> 来源: `internal/creation/port/http/asset_handler.go::UploadAsset` · `internal/creation/app/command/upload_asset_handler.go` · `internal/creation/domain/service/upload_policy.go`

**用途**: 用户主动上传素材到自己的资产库(头像 / 文档 / 上传素材)。文件流经 BFF + 落 `gen_assets` 行(`source='upload'`,`upload_state='uploaded'` 直接终态)。

**与 sign+finalize 互补**:

| 端点 | 文件路径 | 是否落 `gen_assets` | upload_state 终态 | 适用场景 |
|---|---|---|---|---|
| `POST /v1/uploads/sign` + `/finalize` | 客户端 → R2(绕过 BFF) | ✅ 落(预 pending) | finalize 后 `uploaded` | 瞬态参数输入 / 大文件 |
| `POST /v1/assets/upload`(本端点) | 客户端 → BFF → R2 | ✅ 落(直接 uploaded) | `uploaded`(同步) | 用户素材库 / 头像 / 文档持久化 |

**鉴权**: JWT + 全局 App 签名。

#### 请求

```http
POST /v1/assets/upload
Authorization: Bearer <jwt>
Content-Type: multipart/form-data; boundary=...

------...
Content-Disposition: form-data; name="content_type"

image
------...
Content-Disposition: form-data; name="access_level"

private
------...
Content-Disposition: form-data; name="group_name"

avatar
------...
Content-Disposition: form-data; name="tags"

["profile","avatar"]
------...
Content-Disposition: form-data; name="file"; filename="logo.png"
Content-Type: image/png

<bytes>
------...--
```

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `file` | binary | ✓ | 文件 bytes,默认上限 100 MiB(`storage.upload.max_file_size_mb`) |
| `content_type` | string | ✓ | `image` / `video` / `audio` / `text` / `file`(对应 `gen_assets.content_type`) |
| `access_level` | string | ✗ | `private`(默认) / `public` / `unlisted` |
| `group_name` | string | ✗ | 逻辑分组,≤ 128 字符,落 `metadata.group_name` |
| `tags` | string | ✗ | JSON 字符串数组(如 `["profile","avatar"]`),落 `metadata.tags` |

#### 响应

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "bid": "uuid",
    "url": "https://r2.showsapp.org/uploads/<tenant_id>/<account_bid>/2026/05/01/<uuid>.png",
    "expires_at": 0,
    "thumbnail_url": "",
    "file_name": "logo.png",
    "file_size": 102400,
    "mime_type": "image/png",
    "content_type": "image",
    "storage_provider": "r2",
    "width": 0,
    "height": 0,
    "duration_seconds": 0,
    "access_level": "private",
    "tags": ["profile", "avatar"],
    "group_name": "avatar",
    "created_at": 1735689600,
    "dedup_hit": false                                                  // P6-04: 命中已有同 hash 素材时为 true
  },
  "request_id": "uuid",
  "timestamp": 1735689600
}
```

#### P6-04 账户级去重

服务端在 R2 PUT **之前** 计算 SHA-256,然后查 `(account_id, file_hash)`:

- **命中已有 uploaded asset**:**不传 R2 / 不落新行**,直接返已有 `bid` + `dedup_hit=true`。`url` / 媒体属性来自已有 asset;`tags` 取本次请求(允许同一文件挂不同标签),`group_name` 保持已有 asset 的值(不覆盖聚合根)。
- **未命中**:走完整流程(R2 PUT + DB INSERT)。INSERT 阶段如果撞 UNIQUE(并发请求 race),自动:删刚 PUT 上的 R2 对象 + 回查 + 返已有 BID + `dedup_hit=true`。客户端无感。

去重维度是**账户级**(`account_id`):同账户跨设备 / 多次上传同一文件自动收敛;不同账户互不串扰(避免 private 资产被他人探测 hash)。

#### URL 语义

`data.url` **始终是用户立即可用的访问 URL**,前端拿到即可直接 `<img src>` / `<video src>` / `fetch()`,无需再调 `GET /v1/assets/:bid` 续签。

**R2 key 结构** (R2 Key 统一重构 2026-05-26,**唯一权威格式**):

| 路径 | 格式 |
|---|---|
| A · 用户上传素材 | `uploads/<tenant_id>/<account_bid>/<yyyy>/<mm>/<dd>/<uuidv7>.<ext>` |
| B · AI 生成作品(候选与资产**共用**)| `gen/<tenant_id>/<account_bid>/<yyyy>/<mm>/<dd>/<uuidv7>.<ext>` |

| 段 | 类型 | 来源 | 用途 |
|---|---|---|---|
| `<tenant_id>` | int64 | JWT `account_tenant_id` | 顶级前缀 — 删整个租户时 `s3 rm s3://bucket/uploads/<tenant_id>/ --recursive` 一次性清理。`0` = 个人账户 / 未归属租户 |
| `<account_bid>` | UUID | JWT `account_bid` | 用 UUID 而非内部 int64 `account_id` — 防顺序枚举 / 平台规模泄漏(`account_id` 是 int64 易推算用户量级)|
| `<yyyy>/<mm>/<dd>` | UTC | server clock | 时间分区,便于按日期归档 / lifecycle 配置 |
| `<uuidv7>` | UUID **v7** | `uuid.NewV7()` | 时间有序 UUID(v7) — R2 底层按 key 字典序分区,有序写入避免热点;与数据库 `bid uuid DEFAULT uuidv7()` 保持一致 |
| `<ext>` | string | `KeyBuilder.safeExt(filename)` | 严格 `[a-z0-9]{2,8}`,无法识别回落 `.bin`(防路径注入 `../` 穿透)|

> ⭐ 唯一权威实现位于 [`internal/creation/domain/service/object_key_builder.go`](../../internal/creation/domain/service/object_key_builder.go) `ObjectKeyBuilder`(放 `domain/service` 层 — 纯逻辑无 infra 依赖,符合 arch 守卫)。
> **任何直接字符串拼接 R2 key 的代码均为违规**,须替换为 `KeyBuilder.UploadKey` / `KeyBuilder.GenKey`。

URL 形态由 `storage.r2.public_bucket` 决定:

| 配置 | URL 形态 | `expires_at` |
|---|---|---|
| `public_bucket: true`(当前部署 r2.showsapp.org)| `{r2.public_url}/<account_bid>/<date>/<uuid>.<ext>` | `0`(无 TTL,直接 CDN) |
| `public_bucket: false` + `access_level=public` | 永久 PublicURL | `0` |
| `public_bucket: false` + `access_level=private/unlisted` | R2 预签名 GET URL(1h TTL,走 cloudflarestorage.com 内部域)| Unix 秒,客户端 `now > expires_at - 60s` 调 `GET /v1/assets/:bid` 续签 |

**`storage_provider`**:取自实际后端(`r2` / `local`),不再硬编码;`local` 模式下 `url` 是相对路径 `/storage/{key}`,需挂静态路由(开发期)。

> 说明:`width` / `height` / `duration_seconds` 当前**始终为 0**(handler 不引 ffprobe / image decoder),前端如需要尺寸可在浏览器侧从 File 对象读取后通过另接口补写,或后续走 PostProcess 流水线。

#### content_type ↔ MIME 校验表

服务端 `UploadPolicy` 强制一致性(`mimeMatchesContentType`),跨类被拒(40034):

| `content_type` | 允许的 MIME |
|---|---|
| `image` | `image/*` |
| `video` | `video/*` |
| `audio` | `audio/*` |
| `text` | `text/*`、`application/json`、`application/xml` |
| `file` | `application/pdf`、`application/msword`、`application/zip`、`application/octet-stream`、`application/vnd.openxmlformats-*` (docx/xlsx/pptx 等) |

> Office 宏文档 (`application/vnd.ms-excel`)、可执行文件 (`application/x-msdownload`) 等不在白名单。

#### 错误码

| HTTP `code` | 含义 | 触发 |
|---|---|---|
| `40001` | content_type / file 字段缺失或非法 | ValidationFailed |
| `40033` | filename 缺失 / content_type 非允许集合 | UploadPolicy 拒绝 |
| `40034` | MIME 与 content_type 不匹配 / MIME 不在白名单 | UploadPolicy 拒绝 |
| `40035` | 文件超过 `storage.upload.max_file_size_mb`(默认 100 MiB) | UploadPolicy 拒绝 |
| `50000` | 读取上传文件失败 / R2 写入失败(已记日志) | 系统错误 |
| `40010+` | JWT 错误 | 鉴权失败 |
| `40110+` | App 签名错误 | 签名失败 |

#### 持久化字段映射

| 请求字段 | `gen_assets` 列 | 备注 |
|---|---|---|
| `file` (bytes) | `file_path` (R2 key) + `file_size` + `file_hash` (SHA-256) | hash 服务端去重用 |
| header `Content-Type` | `mime_type` | |
| `content_type` | `content_type` | 业务类型枚举 |
| `access_level` | `access_level` | |
| `group_name`、`tags` | `metadata` (JSON) | schema 无原生列,落 metadata.{group_name,tags} |
| (后端动态填) | `storage_provider` | `ObjectStorage.ProviderName()` 返:`r2` / `local` (避免硬编码导致 contract 错配) |
| (固定值 `upload`) | `source` | 区分 generation/upload/system/import |
| (生成 bid) | `bid` (UUID) | 对外标识 |

#### 客户端示例 (curl)

```bash
curl -X POST https://api.example.com/v1/assets/upload \
  -H "Authorization: Bearer $JWT" \
  -F "content_type=image" \
  -F "access_level=private" \
  -F "group_name=avatar" \
  -F 'tags=["profile"]' \
  -F "file=@./logo.png"
```

#### 浏览器示例 (FormData)

```typescript
async function uploadAsset(file: File) {
  const fd = new FormData();
  fd.append('file', file);
  fd.append('content_type', detectContentType(file.type));
  fd.append('access_level', 'private');
  fd.append('tags', JSON.stringify(['profile']));

  const resp = await request('/v1/assets/upload', {
    method: 'POST',
    data: fd,
    requestType: 'form',  // umi: 不要 JSON.stringify, 让浏览器设 boundary
  });
  return resp.data; // { bid, url, ... }
}
```

> ⚠️ 如果只是 ParamSchemaForm 文件参数(瞬态输入),用 [POST /v1/uploads/sign](#post-v1uploadssign) 更高效(避免文件经 BFF 中转)。本端点专给"用户长期持有的素材库"场景。

---

### GET /v1/assets/:bid
取资产详情。

返:
```json
{
  "bid": "...",
  "task_id": "<task_bid>",
  "type": "image",                  // text / image / video / audio
  "url": "https://...r2.../asset.png",
  "size_bytes": 102400,
  "duration_sec": 0,
  "metadata": { "width": 1024, "height": 1024 },
  "created_at": "..."
}
```

### GET /v1/assets
列资产(同账号 + 同 app)。Query:`type` / `task_id` / `limit` / `cursor`。

## 任务状态机

```
draft (内存态, 不落库) → processing → completed
                                   → failed
                                   → cancelled
```

`processing` 是创建后落库的初始态(无 `pending`)。

## Sync vs Async 路由判定

由 `prov_model_versions.execution_mode` 字段决定:

| Mode | 行为 | 典型 Provider |
|---|---|---|
| `sync` | HTTP 一次返结果 | Gemini text/image, Imagen, Seedream, Nano Banana |
| `async` | 入 Redis Stream + worker 消费 + 内部 poll 至终态 | Veo / Runway / Seedance |

**Async 内部架构**:
- 72 streams = 6 providers × 4 media × 3 priorities
- `TaskConsumer` 拉 stream → `Execute`(在 service 层内部 `pollUntilTerminal` 循环)→ `CompleteTask`
- `TaskMessage` 携带 `freeze_id`(不落盘,Stream 里恢复)
- `TimeoutWorker`(30s 扫描)兜底悬挂任务

详见 [pipeline-api.md](../architecture/creation/pipeline-api.md)。

## 数据模型

| 表 | 主键 | 说明 |
|---|---|---|
| `gen_generation_tasks` | id, bid UNIQUE | 聚合根; 5 mixin |
| `gen_task_steps` | id | 步骤详情(异步 polling 步骤) |
| `gen_task_candidates` | **(expires_at, id) PK** + bid UNIQUE | **P7 Phase 5 新增**:AI 候选(7d TTL,用户 Save 后才落 asset) |
| `gen_task_candidate_files` | id | **P7 Phase 5 新增**:候选子文件 — AIGC 域实际只产 `role='original'`,ent enum 含 `thumbnail/preview/sidecar` 是历史兼容占位 |
| `gen_assets` | id, bid UNIQUE | 用户**已 Save** 的资产(永久) |
| `gen_conversations` | id | 对话上下文(多轮生成) |
| `gen_content_reviews` | id | 安全审核记录 |
| `gen_generation_feedback` | id | 用户反馈 |

`task_type` 枚举(归一化):`text_gen` / `image_gen` / `video_gen` / `audio_gen`。

**P7 Phase 5 schema 变更**:`gen_generation_tasks` 删除 `output_asset_ids` / `input_asset_ids` / `raw_asset_ids` / `final_asset_ids`(全部 dead column);`gen_assets` 删除 `selected_from_task_id`(应用层零引用),`lifecycle_state` 默认改 `kept`(候选不再写入 gen_assets)。详见 `docs/migrations/p7_phase5_candidate_layer.sql`。

> **注**:`prov_models.task_type`(原值,如 `txt2video`)≠ `gen_generation_tasks.task_type`(归一化)。`ResolveModel` 返 `ModelInfo.TaskType`(归一化)+ `ProviderTaskType`(原值,用于 pricing_rules 查询)。

## 计费链路

```
SubmitTask:
  Freeze(estimated_credits) → freeze_id
  task.freeze_id = freeze_id (内存)
  Async: TaskMessage{ freeze_id } → Stream

CompleteTask (success):
  ConfirmFreeze(freeze_id, actual_credits)
  task.status = completed

CompleteTask (failure / Cancel):
  RefundFreeze(freeze_id)
  task.status = failed/cancelled

PartialConfirm (实际 < estimated):
  PartialConfirmFreeze(freeze_id, actual_credits)
    → 扣实际 + 退差额, 双条 ledger
```

ledger 行均带 `ref_task_id`(支持任务级账单聚合)。

## 错误码段

### Task 任务层(40xxx)

| Code | 含义 |
|---|---|
| `40003` | params 缺必填字段 |
| `40033` | provider param schema 校验失败 |
| `40036` | quantity 越界(>9 hardcap) |
| `40404` | task / asset / model_version 不存在 |
| `40410` | provider 不可用(channel 全 disabled / 熔断打开) |
| `40901` | task 状态机违规(已完成的不能再 cancel) |
| `42910` | provider rate limit |
| `50040` | Wallet Freeze 失败(余额不足) |
| `50410` | upstream provider timeout |

### Candidate 候选层(45xxx,P7 Phase 5)

| Code | 含义 |
|---|---|
| `45401` | 候选批量数量超过上限(50) |
| `45400` | 候选不存在 / 跨账户越权 |
| `45901` | 候选未就绪(R2 上传未完成) |
| `45902` | 候选已保存(重复 Save / 客户端可视为成功) |
| `45903` | 候选已过期(TTL 到期) |
| `45904` | 候选已丢弃 |
| `45905` | 候选审核中(P8 Safety BC 启用后) |
| `45906` | 候选未通过审核 |
| `45920` | 候选状态转移非法(域守卫) |

### Subject 主体层(40850-40869,Plan-Subject T4,2026-06-11)

| Code | 含义 |
|---|---|
| `40850` | 主体参考集超上限(单任务 character_bids > 14 / Admin replace 参考图 > 14) |
| `40851` | 主体注入与已传参数互斥(预留 strict 模式;v1 互斥默认跳过注入 + `_subject_skipped_reason`) |
| `40852` | 资产被未删主体锚定,丢弃/归档被拦截(先解绑;清扫 worker 对应路径为 skip+warn 保活) |
| `40853` | 主体参考图未通过内容审核(D7 挂载点;Safety Noop 现状放行) |
| `40854` | 锚定资产未就绪(`upload_state≠uploaded` 或为 TTL 候选 — 候选须先 Save) |

详见 `internal/creation/domain/errors.go`。

## Subject 主体库(Plan-Subject,2026-06-11)

产品语 **Subject ≡ 域内 Character**(`subject_bid ≡ character_bid`)。完整端点见
`endpoint-inventory.md` Creation 段;设计依据 `docs/architecture/creation/adr-subject-01-role-injection.md`。

### 任务提交主体注入

`POST /v1/tasks` 新增可选 `character_bids: []string`(≤14,须属当前账号):

```json
{
  "model_version_bid": "…",
  "params": { "prompt": "两人在公园散步" },
  "character_bids": ["<subject-bid-1>", "<subject-bid-2>"]
}
```

提交链路 `SubjectRefInjector` 把主体锚定参考图注入模型 `role=reference_material`
目标字段(形态/容量/互斥按 param_schema 自适配;`view_role` 优先级 front>side>back>custom
裁剪;prompt 自动拼接 `prompt_anchor` 与序数段)。注入不可行时任务照常提交,
`task.params._subject_skipped_reason` 可查原因(`exclusive:first_frame_image` /
`capacity_exhausted:…` / `no_reference_target` 等)。

### 三视图闭环(D3)

1. `POST /v1/characters`(单图建主体,初始锚定须 `upload_state=uploaded`;`workspace_bid` **可选**,2026-07-22 起——缺省懒创建/复用账号个人空间默认 workspace,与建会话 FT-PRE-0 同语义,B2C/游客路径零前置;`GET /v1/characters` scope=mine 缺省同口径 = 个人空间视角)
2. `POST /v1/characters/:bid/three-view` body `{"model_version_bid": "…"}`(**可选**,2026-07-21 起——缺省走 `prov_capability_defaults('subject_three_view')` 平台默认解析,客户端不必关心模型;显式传 = 高级覆盖;默认行缺失/失效 → 50035 fail-close)
   → 202 返 `task_bid/poll_url`;prompt 由 Prompt BC 模板 `subject_three_view_generator`
   渲染(name + prompt_anchor),`params._subject_gen={character_bid, views:[front,side,back]}`
   供客户端挑选器渲染视角指派
3. 候选 ready → `POST /v1/candidates/:bid/save`(候选固化为 kept 资产)
4. `POST /v1/characters/:bid/assets` body `{"asset_bid": "…", "view_role": "front"}` 回填

### 平台公共角色包(FT-5)

`account_id=0` 的 `gen_characters` 行 = 平台公共角色(`tenant_id=0/workspace_id=0`,
seed `p_platform_characters_seed_20260612.sql` / 独立 admin 后台维护)。语义:

- **全员只读可引用**:任务 `character_bids` 注入放行(`SubjectRefInjector` 对
  `IsPlatform()` 跳过 account 确权;跨账号私有角色仍 40330 拒)、
  `GET /v1/characters/:bid` 详情可见
- **发现**:`GET /v1/characters?scope=platform`(全局维度,不需要 `workspace_bid`;
  `scope` 缺省/`mine` = 本人角色,行为不变)
- **不可改**:用户侧 PATCH/DELETE/three-view 的 owner 确权天然拒绝(0 ≠ 真实账号);
  内容维护走 `AdminReplaceCharacter`
- 锚点先行:seed 仅含 `prompt_anchor/negative_anchor/tags/voice_ref`(绑
  qwen3-tts-flash 音色);三视图参考资产由运维经三视图闭环生成后锚定,
  锚定后注入自动升级为「锚点+参考图」双通道

### 管理端(facade,API-only)

运营管理走 `creation.CreationAPI` facade(独立 Admin 后台 RPC 接入,本仓库零 `/admin/*` 端点):

- `AdminReplaceCharacter` — 表单类:元数据/档案 + 参考图集**全量 replace**(单事务,
  全删后批插;`Assets` nil=不动 / 空切片=清空;资产仍过 R3 闸)
- `AdminDeleteCharacter` — 生命周期类:软删(轻量,零子资源 CUD)

## Outbox 事件

### Task 任务事件(KTD)

**未实装**。`CreationEventConsumer` 当前只**消费**入站 IAP 事件(`iap.purchase_completed` 等),不**发布** task lifecycle 事件。

期望(P5):
- `creation.task_submitted` / `creation.task_completed` / `creation.task_failed` / `creation.task_cancelled`

E2E `assertions_test.go` 对此降级为 WARN,不阻断 CI。

### Candidate 候选事件(P7 Phase 5)

事件定义在 `internal/shared/outbox/events.go`。当前**已发布**:

| 事件类型 | 触发点 | aggregate_id | 主要消费者 |
|---|---|---|---|
| `creation.candidate_selected` | `SaveCandidateHandler` Save 成功 | `candidate_bid` | (预留,P8 接入 project stats) |
| `creation.candidate_discarded` | `DiscardCandidateHandler` Discard 成功 | `candidate_bid` | (预留) |
| `creation.candidate_expired` | `CandidateExpiryWorker` 单批一次性 | 首个 `candidate_bid`(批量字段含 `candidate_bids[]`) | (预留,运维 dashboard) |

**预留未发**:`creation.candidate_generated`(任务完成时一批候选落库)— 定义已存在,但 CandidatePersister 暂未写 outbox(候选层 happy path 不依赖此事件;P8 接入 project_stats_consumer 时启用)。

## Module API(跨 BC)

`creation.CreationAPI` 自 Plan-Subject T6 起承载主体管理端方法(此前为 marker interface):
`AdminReplaceCharacter`(表单 replace)/ `AdminDeleteCharacter`(生命周期软删),
供独立 Admin 后台经 RPC 接入(见上文 Subject 管理端小节)。未来若 Agent 多模态需要
触发图像/视频生成,可继续在此扩 `SubmitTask`。

## 起跳点

- Outbox 发布(KTD)
- `prov_models.capability_tags / supported_features / display_tags` 字段 schema 不一致(KTD,长期需 Ent SchemaType="text[]")
- Sync 路径下 Submit 返 err 但非 sentinel 时绕过 failTask 的边界(KTD)


## OpenAPI 3.1 Specification

> 基于代码事实生成,4 个 sub-agent 独立扫描 + 交叉校验。来源:
> - `internal/creation/port/http/{routes,task_handler,asset_handler}.go`
> - `internal/creation/app/dto/task.go`
> - `internal/creation/app/command/{submit,estimate,complete,cancel}_*.go`
> - `internal/creation/app/query/{get_task,list_tasks,asset_query}_handler.go`
> - `internal/creation/domain/errors.go::GetErrorCode`
>
> 公共契约(BaseURL / Headers / 鉴权 / 签名 / Envelope / 错误码)见 [overview.md](overview.md)。

```yaml
openapi: 3.1.0
info:
  title: AIGC Platform — Creation Domain API
  description: |
    创作任务全生命周期 (8 endpoints):
      - submit / estimate / list / get / cancel + 内部回调
      - 资产列表 / 详情 (含 1h presigned 下载 URL)

    **统一异步模型** (P6-02 起): POST /v1/tasks 永远返 202 + poll_url, 无论
    model_version.execution_mode = sync 或 async. 提交体验统一 ~50ms.
      - 任务在 worker 端执行 (同步 model 几秒, 异步 model 经内部 polling 或 asynq pipeline)
      - 客户端轮询 GET /v1/tasks/:bid 拿终态
      - 异步 model 上游回调走内部端点 /v1/internal/tasks/:bid/complete
  version: "1.0.0"

servers:
  - url: https://api.aigc.example.com/v1
    description: Production
  - url: http://localhost:9999/v1
    description: Local dev

# 默认所有 path 走 JWT + 签名 (5 项)
security:
  - BearerAuth: []
    DistributionCode: []
    Timestamp: []
    Nonce: []
    AppSignature: []

components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: |
        Identity BC 颁发 HS256 JWT.
        Claims: { abid (string), role (string), sid (string), iat (int64), exp (int64) }
    DistributionCode:
      type: apiKey
      in: header
      name: X-Distribution-Code
    Timestamp:
      type: apiKey
      in: header
      name: X-Timestamp
      description: Unix 秒级时间戳, 服务端窗口 ±5 分钟
    Nonce:
      type: apiKey
      in: header
      name: X-Nonce
      description: UUID v4, 防重放窗口 10 分钟
    AppSignature:
      type: apiKey
      in: header
      name: X-App-Signature
      description: |
        canonical = timestamp + nonce + sortedJSON(body)  (无分隔符)
        signature = hex(HMAC-SHA256(secret, canonical))   (lowercase, 64 字符)

  parameters:
    TaskBID:
      name: bid
      in: path
      required: true
      schema:
        type: string
        format: uuid
      description: task BID (UUID v7)
    AssetBID:
      name: bid
      in: path
      required: true
      schema:
        type: string
        format: uuid

  schemas:
    StandardResponse:
      type: object
      required: [code, message, request_id, timestamp]
      properties:
        code:
          type: integer
          example: 0
          description: 0 = 成功; 非 0 见错误码表 (overview.md §7)
        message:
          type: string
          example: success
        data:
          description: 业务载荷, 各端点不同
        request_id:
          type: string
          format: uuid
        timestamp:
          type: integer
          format: int64
          description: Unix 秒

    ErrorResponse:
      type: object
      required: [code, message, request_id, timestamp]
      properties:
        code:
          type: integer
        message:
          type: string
        details:
          type: object
          additionalProperties:
            type: string
          description: 仅 ValidationFailed (40001) 返字段级 map
        request_id:
          type: string
        timestamp:
          type: integer
          format: int64

    # ── POST /v1/tasks ── (来源 dto/task.go)

    SubmitTaskRequest:
      type: object
      required: [model_version_bid]
      properties:
        model_version_bid:
          type: string
          format: uuid
          description: prov_model_versions.bid
        params:
          type: object
          additionalProperties: true
          description: |
            动态参数. 由 Provider BC 的 ValidateAndMergeParams 校验, 合并 preset_code 的 base.
            params 与 preset_code 至少一个非空 (Validate 强制).
        preset_code:
          type: string
          description: 预设编码 (prov_model_presets.preset_code), 与 params 二选一或配合
        idempotency_key:
          type: string
          description: 客户端 UUID, 防重复提交; 命中已有任务直接返历史结果

    OutputItem:
      type: object
      required: [type]
      properties:
        type:
          type: string
          enum: [text, image, video, audio]
        url:
          type: string
          format: uri
          description: R2 持久化 URL (异步终态后)
        content:
          type: string
          description: 文本类输出 (text 模型)
        metadata:
          type: object
          additionalProperties: true

    UsageDTO:
      type: object
      required: [amount, unit]
      properties:
        amount:
          type: number
          format: double
        unit:
          type: string
          example: second
        cost:
          type: number
          format: double
          description: 消耗积分 (浮点)

    TaskResultDTO:
      type: object
      properties:
        outputs:
          type: array
          items:
            $ref: '#/components/schemas/OutputItem'
        usage:
          $ref: '#/components/schemas/UsageDTO'

    SubmitTaskResponse:
      type: object
      required: [task_id, status, poll_url, estimate_ms]
      description: |
        P6-02 起永远 202 + poll_url. SubmitTask 与 GetTask 共用此响应类型
        (dto/task.go::SubmitTaskResponse), 但 SubmitTask 不再 inline result.
        客户端始终通过 GET /v1/tasks/:bid 取终态.
        estimate_ms = p95_latency_ms (model.platform_params)
                      + queue_wait_ms (depth × p95 / worker_concurrency).
      properties:
        task_id:
          type: string
          format: uuid
          description: task BID
        status:
          type: string
          enum: [processing, completed, failed]
          description: SubmitTask 永远 processing; GetTask 据真实状态填
        poll_url:
          type: string
          description: /v1/tasks/<bid>
        estimate_ms:
          type: integer
          description: 预估完成时间 (毫秒, 含队列等待)

    # ── POST /v1/tasks/estimate ── (来源 command/estimate_cost_handler.go:11-28)

    EstimateCostRequest:
      type: object
      required: [model_version_bid]
      properties:
        model_version_bid:
          type: string
          format: uuid
        params:
          type: object
          additionalProperties: true
        preset_code:
          type: string

    EstimateCostResponse:
      type: object
      required: [credits, unit_cost, unit, quantity, breakdown, applied_tier]
      properties:
        credits:
          type: integer
          format: int64
          example: 800
        unit_cost:
          type: integer
          format: int64
          example: 100
        unit:
          type: string
          enum: [per_request, per_second, per_1k_tokens, per_megapixel]
        quantity:
          type: integer
          example: 8
        breakdown:
          type: string
          example: "8s × 100 credits/s = 800 credits"
        applied_tier:
          type: string
          description: 实际匹配的定价分层 (前端可显示"会员价")
          example: premium

    # ── GET /v1/tasks/:bid ── (来源 query/get_task_handler.go::TaskResponse)

    PollStrategy:
      type: object
      required: [next_poll_after_ms, should_continue, elapsed_ms, estimate_total_ms]
      description: |
        非终态 (processing/pending) 时由后端计算并返回, 指导客户端下次轮询.
        text/image/video 各自策略不同, processing 状态间隔递增 (2s → 5s → 10s → 30s → 60s),
        超过 max timeout 后 should_continue=false.
      properties:
        next_poll_after_ms:
          type: integer
        should_continue:
          type: boolean
        elapsed_ms:
          type: integer
        estimate_total_ms:
          type: integer

    BillingResource:
      type: object
      properties:
        asset_bid:
          type: string
          format: uuid
        file_path:
          type: string
        content_type:
          type: string
        credit_cost:
          type: integer
          format: int64
        provider_usage:
          type: object
          additionalProperties: true

    TaskBilling:
      type: object
      description: 仅终态任务返回, 含资源级计费明细 (支持 N-Generation Fan-out)
      properties:
        quota_consumed:
          type: integer
          format: int64
        quantity_requested:
          type: integer
        quantity_completed:
          type: integer
        quantity_failed:
          type: integer
        resources:
          type: array
          items:
            $ref: '#/components/schemas/BillingResource'
        funding_revoked:
          type: boolean
          description: |
            ADR-024:资助本任务的订单中有资金已撤回的(退款 / revoke)。缺席 = false;
            撤销退款(REFUND_REVERSED)后重算回 false。交付物本身不删、已下载的不追回 ——
            据此锁「下载 / 商用许可」一类权益是产品层的规则。读取标记失败时整个请求失败(不省略字段)。

    TaskResponse:
      type: object
      required: [task_bid, status, model_code, task_type, created_at]
      description: |
        ★ 与 SubmitTaskResponse 字段不同! GetTask 返此专属类型.
        - 字段名: task_bid (不是 task_id)
        - 无 result/poll_url 字段; 改为 output_content + output_metadata
        - 终态填 billing struct; 非终态填 poll struct
      properties:
        task_bid:
          type: string
          format: uuid
        status:
          type: string
          enum: [pending, processing, completed, failed, cancelled, timeout, partial]
        model_code:
          type: string
        task_type:
          type: string
          description: text_gen / image_gen / video_gen / audio_gen
        output_content:
          type: string
          nullable: true
          description: 文本生成内容或资产 URL
        output_metadata:
          type: object
          additionalProperties: true
        error_code:
          type: string
        error_message:
          type: string
        created_at:
          type: integer
          format: int64
          description: Unix 秒
        started_at:
          type: integer
          format: int64
          nullable: true
        completed_at:
          type: integer
          format: int64
          nullable: true
        billing:
          $ref: '#/components/schemas/TaskBilling'
          description: 仅终态任务有
        poll:
          $ref: '#/components/schemas/PollStrategy'
          description: 仅非终态任务有

    # ── GET /v1/tasks ── (来源 query/list_tasks_handler.go::TaskListItem)

    TaskOutput:
      type: object
      required: [asset_bid, url, content_type]
      description: |
        单个产出资源 (一个 task 可有多个; N-Generation 父任务自动聚合子任务产物).
        URL 已拼接 R2 / CDN 完整域名, 客户端可直接 GET, 无需再处理 key → URL 映射.
      properties:
        asset_bid:
          type: string
          format: uuid
          description: 资产 BID (gen_assets.bid); 用于后续收藏 / 分享 / 删除等操作
        url:
          type: string
          format: uri
          description: |
            完整可访问 URL.
            - access_level=public:  CDN 长效链 (expires_at=0)
            - access_level=private/unlisted: 预签名短效链 (expires_at>0)
        content_type:
          type: string
          description: image / video / audio / text / file
        mime_type:
          type: string
          example: image/png
        width:
          type: integer
          description: 图像 / 视频宽度 px; 0 表示不适用或未识别
        height:
          type: integer
        duration_seconds:
          type: integer
          description: 视频 / 音频时长秒; 0 表示不适用
        expires_at:
          type: integer
          format: int64
          description: |
            URL 过期 Unix 秒.
            - 0     = 长效 (public bucket 或 CDN 直链)
            - > 0   = 预签名过期时间, 客户端应在到期前重拉列表刷新

    TaskListItem:
      type: object
      required: [task_bid, status, model_code, task_type, created_at]
      properties:
        task_bid:
          type: string
          format: uuid
        status:
          type: string
          enum: [pending, processing, completed, failed, cancelled, timeout, partial]
        model_code:
          type: string
        task_type:
          type: string
        scene:
          type: string
        thumbnail_url:
          type: string
          format: uri
          description: |
            缩略图 URL (完整 R2/CDN 链接).
            优先取 outputs[0].url; 无 asset 时 fallback 取 OutputContent.
            失败任务为空串.
        error_code:
          type: string
        error_message:
          type: string
        created_at:
          type: integer
          format: int64
        completed_at:
          type: integer
          format: int64
          nullable: true
        input_params:
          type: object
          additionalProperties: true
          description: |
            ★ 用户提交任务时的原始 params (透传 gen_generation_tasks.input_params).
            客户端"再生成 / 重试 / 一键复用"直接拿这个字段填回表单, 无需重新解析 ParamSchema.
        outputs:
          type: array
          description: |
            产物列表 (status=completed/partial 通常非空; failed/timeout 一般为空数组).
            N-Generation 父任务: 自动聚合所有子任务的资产 (子任务不会单独出现在 tasks 列表里).
          items:
            $ref: '#/components/schemas/TaskOutput'
        output_metadata:
          type: object
          additionalProperties: true
          description: |
            扩展元数据 (post_process_status / final_urls / urls 等).
            优先使用 outputs 字段, output_metadata 视作 provider/pipeline 特定 payload.

    ListTasksResponse:
      type: object
      required: [tasks, total]
      properties:
        tasks:
          type: array
          items:
            $ref: '#/components/schemas/TaskListItem'
        total:
          type: integer
          description: |
            该 account 下满足 status 过滤的全表任务数 (顶层任务, 不含 fan-out 子任务).
            用于客户端分页计算 total pages.

    # ── POST /v1/internal/tasks/:bid/complete ── (来源 task_handler.go:171-178 内联 struct)

    CompleteTaskRequest:
      type: object
      required: [success]
      properties:
        success:
          type: boolean
        result_url:
          type: string
          format: uri
          description: 产物 URL (成功时)
        result_data:
          type: object
          additionalProperties: true
        cost_amount:
          type: number
          format: double
          description: 实际成本 (浮点)
        error_code:
          type: string
        error_msg:
          type: string

    # ── /v1/assets ── (来源 asset_handler.go, dynamic map 实际填充字段)

    AssetItem:
      type: object
      required: [asset_bid, content_type, file_size, created_at]
      description: ListAssets 返回的资产摘要 (动态 map, 非 struct)
      properties:
        asset_bid:
          type: string
          format: uuid
        file_name:
          type: string
        content_type:
          type: string
          description: "image / video / audio / text (注: 不是 mime_type)"
        mime_type:
          type: string
          example: image/png
        file_size:
          type: integer
          format: int64
        storage_provider:
          type: string
          example: r2
        width:
          type: integer
        height:
          type: integer
        duration_seconds:
          type: number
          format: double
        source:
          type: string
        thumbnail_url:
          type: string
          format: uri
          description: 仅当 ThumbnailPath 非空时返回
        created_at:
          type: integer
          format: int64

    AssetDetail:
      allOf:
        - $ref: '#/components/schemas/AssetItem'
        - type: object
          properties:
            file_path:
              type: string
            file_hash:
              type: string
              example: "sha256:..."
            access_level:
              type: string
            download_url:
              type: string
              format: uri
              description: 1 小时 presigned URL (失败时为 "")
            metadata:
              type: object
              additionalProperties: true

paths:
  /tasks:
    get:
      summary: 列任务历史
      operationId: listTasks
      tags: [Task]
      parameters:
        - name: status
          in: query
          schema:
            type: string
            enum: [pending, processing, completed, failed, cancelled, timeout, partial]
        - name: page
          in: query
          schema:
            type: integer
            minimum: 1
            default: 1
          description: page < 1 → 1
        - name: size
          in: query
          schema:
            type: integer
            minimum: 1
            maximum: 50
            default: 20
          description: size <= 0 或 > 50 → 20
      responses:
        '200':
          description: 任务列表 (total = 当前页 len, 非全表 count)
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data:
                        $ref: '#/components/schemas/ListTasksResponse'
        '401':
          description: 未认证 / 签名失败 (Unauthorized HTTP 401)

    post:
      summary: 提交创作任务 (sync→200, async→202)
      operationId: submitTask
      tags: [Task]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/SubmitTaskRequest'
      responses:
        '200':
          description: 同步任务完成 (model.execution_mode=sync)
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data:
                        $ref: '#/components/schemas/SubmitTaskResponse'
        '202':
          description: 异步任务已入队 (返 poll_url)
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data:
                        $ref: '#/components/schemas/SubmitTaskResponse'
        '400':
          description: |
            参数校验失败. 注: 多数业务错误 HTTP 200 + 业务码 (overview.md §6).
            HTTP 400 仅在 BadRequest / ValidationFailed (code=40001) 时返.
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'

  /tasks/estimate:
    post:
      summary: 积分预估 (不冻结、不扣费)
      operationId: estimateCost
      tags: [Task]
      description: |
        Auth 可选: JWT 存在时注入 accountID 解析定价分层; 缺 JWT 走 default tier.
        ★ App 签名仍必须 (overview.md §5).
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/EstimateCostRequest'
      responses:
        '200':
          description: 预估成功
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data:
                        $ref: '#/components/schemas/EstimateCostResponse'
        '400':
          description: model_version_bid 空

  /tasks/{bid}:
    get:
      summary: 查询任务状态 (轮询用; 非终态返 poll struct)
      operationId: getTask
      tags: [Task]
      parameters:
        - $ref: '#/components/parameters/TaskBID'
      responses:
        '200':
          description: |
            任务详情. ★ 此响应是 TaskResponse (与 SubmitTaskResponse 不同字段).
            非终态填 poll, 终态填 billing.
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data:
                        $ref: '#/components/schemas/TaskResponse'

  /tasks/{bid}/cancel:
    post:
      summary: 取消任务
      operationId: cancelTask
      tags: [Task]
      description: |
        仅 pending / processing 状态可取消. 已 completed / failed / timeout / cancelled
        返 40920 状态机冲突.
      parameters:
        - $ref: '#/components/parameters/TaskBID'
      responses:
        '200':
          description: "取消成功 (data: null), 已退冻结积分"
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/StandardResponse'

  /internal/tasks/{bid}/complete:
    post:
      summary: 内部回调 — 异步任务完成通知
      operationId: completeTask
      tags: [Internal]
      description: |
        ★ **公开端点** (无 JWT). **跳过 App 签名** (/v1/internal/ 在 SkipPaths).
        仅内网信任 / IP 白名单调用. 供应商 webhook 或 worker 完成后调用.
      security: []
      parameters:
        - $ref: '#/components/parameters/TaskBID'
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CompleteTaskRequest'
      responses:
        '200':
          description: "完成处理成功 (data: null)"
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/StandardResponse'

  /assets:
    get:
      summary: 用户资产列表
      operationId: listAssets
      tags: [Asset]
      parameters:
        - name: type
          in: query
          schema:
            type: string
            description: image / video / audio / text
        - name: page
          in: query
          schema:
            type: integer
            minimum: 1
            default: 1
        - name: size
          in: query
          schema:
            type: integer
            minimum: 1
            maximum: 50
            default: 20
      responses:
        '200':
          description: 资产列表 (total = 当前页 len)
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data:
                        type: object
                        required: [assets, total]
                        properties:
                          assets:
                            type: array
                            items:
                              $ref: '#/components/schemas/AssetItem'
                          total:
                            type: integer

  /assets/{bid}:
    get:
      summary: 资产详情 (含 1h presigned 下载 URL)
      operationId: getAsset
      tags: [Asset]
      parameters:
        - $ref: '#/components/parameters/AssetBID'
      responses:
        '200':
          description: 资产详情
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data:
                        $ref: '#/components/schemas/AssetDetail'
        '404':
          description: 资产不存在 / 跨账号访问 (故意混淆, 不暴露存在性)

# ─────────────────────────────────────────────────────────────────────────
# 错误码段 (来源 internal/creation/domain/errors.go::GetErrorCode)
# ─────────────────────────────────────────────────────────────────────────
# 注: 多数业务错误 HTTP 状态码为 200, 业务码在 response.code (见 overview.md §6).
# 仅 ValidationFailed (40001) 走 HTTP 400.
#
# 40033  ErrInvalidParam              参数校验失败
# 40200  ErrInsufficientCredits       余额不足
# 40420  ErrTaskNotFound              任务不存在 / 跨账号访问
# 40920  ErrInvalidStatusTransition   任务状态冲突 (cancel 已终态任务等)
# 40921  ErrDuplicateIdempotencyKey   重复提交 (idempotency_key 命中)
# 45100  ErrPromptRejected            内容审核未通过
# 50210  ErrProviderUnavailable       供应商服务不可用
# 50000  (default)                    服务内部错误
```

---

## 竞品素材拆解 (material_analysis_v1, M1)

> **完整接口文档**(请求/响应示例 + 报告字段表 + 生命周期 + 端到端示例)见 [material-analysis.md](material-analysis.md)。本节为 BC 内速查。

多模态拆解竞品买量视频 → 结构化拆解报告 (四维) + 六维评分, 并按需 derive (反推提示词 / 复刻方案)。
报告持久于非分区表 `gen_analysis_reports` (生命周期独立于执行用管线任务, 红线 R2)。

**实现要点**:复用 Pipeline Engine — 一条系统预置流水线 `material_analysis_v1`
(probe→抽帧→ASR→多模态拆解→组装), 经 `gen_post_process_templates` 定义, PostProcessWorker
经 Orchestrator 逐步执行; **零新状态机 / 零新 Run 模型**。报告状态 (processing/completed/failed)
镜像管线终态, 非状态机 (无转移守卫)。

### 端点 (均挂 JWT + 签名)

| 方法 | 路径 | 说明 |
|---|---|---|
| POST | `/v1/analysis-reports` | 提交拆解 → 202; body `{"material_bid": "<uuid>"}`; 返 `{report_bid, task_bid, status}` |
| GET | `/v1/analysis-reports` | 账号维度列表 (分页 `page`/`page_size`≤100); 返 `{items[], total}` (摘要含 scores) |
| GET | `/v1/analysis-reports/:bid` | 报告详情 (Schema 驱动渲染; `report`/`scores`/`transcript`/`frames_summary`/`derived`) |
| POST | `/v1/analysis-reports/:bid/derive` | 触发 derive; body `{"kind": "reverse_prompt"\|"replication_plan"}`; 幂等命中返缓存 |

> `frames_summary` 仅暴露 `count`/`strategy` — 关键帧 R2 key 是内部中间产物, 不外泄
> (帧由 FrameCleanupWorker 在 `frame_ttl_days` (默认 7d) 后回收, 报告本体永存, D3)。

### 幂等

提交幂等键 = `UNIQUE(tenant_id, material_bid, pipeline_version, file_hash)` (partial WHERE deleted_at IS NULL):
同素材同版本同内容复提 → 命中既有报告 (零重复扣费); `pipeline_version` 升级即新报告 (历史可见, D6)。
derive 幂等 = `derived[kind]` 已存在直接返缓存。

### 计费 (缺价硬拒, 非 fail-open)

- 主链拆解: 走 `pipeline:material_analysis_v1` 管线级冻结 (per_second); 缺价 → `ErrPipelinePricingMissing (50830)`。
- derive: 走 capability internal Invoke 独立计费单元 (per_request, `entity_type='capability'`);
  缺价 → `pricing_missing` → `40201`。每步均须命中显式定价规则 (显式免费用 `credit_cost=0` 规则行)。

### 合规红线 R7 — 竞品素材禁入生成/分发

竞品导入素材标记 `asset_source='competitor_import'`。**可被拆解 (analysis), 但禁入生成输入 / 分发链路**:
compose / asr submit validator 提交期检测 `IsCompetitorSource` → `ErrCompetitorAssetRestricted (40336)` 硬拒。

### 报告 Schema

报告 JSON Schema v1 契约 + 前端渲染锚点见 `docs/api/analysis_report_schema_v1.json`
(枚举与 `internal/creation/domain/postprocess/analysis_report_v1.go` 由 `analysis_report_v1_guard_test.go` 锁死一致)。
step4 多模态 LLM 输出经 `StrictParseAnalysisOutput` (additionalProperties:false 等价) + `ValidateAnalysisOutput`
(Σcomposition.percent∈[95,105] / 分镜 index 连续且时间窗不重叠≤时长+1.5s 容差 / 评分 stars∈[1,5]) 强校验,
失败返 `ErrStepFailed` → Orchestrator 按 RetryPolicy 重跑 step4 (回注校验失败重试, R13/D5)。

### 错误码 (M1 新增)

```
# 40470  ErrAnalysisReportNotFound    拆解报告不存在 / 跨账号越权 (同码不泄漏)
# 40471  ErrAnalysisMaterialInvalid   素材不可拆解 (不存在/未完成上传/非视频); GET 详情非 completed 复用
# 40472  ErrAnalysisDeriveKindInvalid derive 类型非法 (仅 reverse_prompt / replication_plan)
# 40336  ErrCompetitorAssetRestricted 竞品导入素材禁入分发/生成输入 (R7)
# 50830  ErrPipelinePricingMissing    拆解管线定价缺失
# 40201  (capability pricing_missing) derive 定价缺失
```

### 可观测

- 通用管线步骤指标 (`ppStepExecCounter{processor_type,status}` 等) 覆盖逐步执行/失败/重试/时延。
- 拆解专属 (`internal/platform/telemetry/analysis_metrics.go`):
  `analysis.report_terminal_total{status}` / `analysis.frames_extract_total{strategy}` +
  `analysis.frames_count_total{strategy}` (scene-vs-interval 兜底率) /
  `analysis.derive_total{kind,outcome}` / `analysis.frames_purged_total{dim}`。
