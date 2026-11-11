# 竞品素材拆解 API（material_analysis_v1 · M1）

> 给定一个视频 → 自动拆解出结构化报告（含 **N 个分镜步骤**）→ 按需反推「创作提示词」/「复刻方案」。
>
> 通用机制（BaseURL / 鉴权 / 签名 / 响应 Envelope）见 [overview.md](overview.md)；本文件只讲本功能的接口契约与实现原理。BC 内的速查版见 [creation.md §竞品素材拆解](creation.md)，报告 JSON Schema 见 [analysis_report_schema_v1.json](analysis_report_schema_v1.json)。

---

## 0. 这个功能在做什么（业务逻辑）

**输入**:一个**已上传完成的视频素材**(`gen_assets`,`content_type=video`,`upload_state=uploaded`,且属于当前账号)。

**输出**:一份**结构化拆解报告**,两大块 + 按需衍生:

| 块 | 内容 | 「N 步骤」在哪 |
|---|---|---|
| **四维拆解** `report` | `theme` 题材内核 · `composition` 成分构成 · **`shots` 分镜序列** · `highlights` 亮点 · `risks` 风险 | **`shots[]` 就是「N 步骤」**——按时间顺序的分镜,每镜含画面/台词/字幕/功能定位 + 起止时间 |
| **六维评分** `scores` | `hook` · `info_density` · `visual_impact` · `pacing` · `conversion` · `compliance`,每维 1–5 星 + 理由 | — |
| **衍生产物** `derived`（按需 derive,不自动产出) | `reverse_prompt` / `replication_plan` | **`replication_plan` = 按分镜的 N 步复刻方案** |

**两种「prompt」衍生**(`POST /:bid/derive`,显式触发、独立计费):

- **`reverse_prompt` 反推提示词** —— 把整条视频反推成**一条可直接喂给 AI 生成同类素材的创作提示词**(单段文本,覆盖题材内核/画面风格/分镜节奏/钩子/转化点)。
- **`replication_plan` 复刻方案** —— **按分镜顺序给出 N 步复刻步骤**(每步:画面内容、文案/旁白、时长建议、制作要点)+ 末尾整体注意事项与合规风险。

**典型用途**:竞品买量视频分析 → 看懂它怎么拍的(分镜 + 评分)→ 反推创作思路(reverse_prompt)→ 落地复刻生产(replication_plan)。

---

## 1. 背后怎么跑的(实现原理)

整条链路**复用既有 Pipeline Engine,零新状态机、零新 Run 模型**。提交是同步的(确权 + 冻结 + 入队),拆解是异步的(后台 worker 逐步执行),报告状态**镜像**管线终态。

```
POST /v1/analysis-reports  { material_bid }
      │  ① 确权素材(属己 / uploaded / video)  ② 幂等去重  ③ 钱包冻结(缺价硬拒)  ④ 入队
      ▼  202  { report_bid, task_bid, status:"processing" }      ← 报告行此刻落库 (processing)
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│  cmd/genaistudio-worker · PostProcessWorker · Orchestrator 逐步执行 material_analysis_v1 │
│                                                                                          │
│   1 probe      ffprobe 读容器头        → duration_ms / 宽高 / has_audio                  │
│   2 frames     ffmpeg 抽关键帧          → ≤32 帧 (scene 变化,稀疏则 interval 兜底)       │
│   3 asr        语音转写 (best-effort)   → transcript { text, srt }                       │
│   4 analysis   多模态 LLM (帧 + 转写)   → { report, scores }  强 Schema 校验 + 失败重试  │
│   5 assemble   CAS processing→completed,落库五通道 (report/scores/transcript/frames/…)   │
└──────────────────────────────────────────────────────────────────────────────────────────┘
      │  成功 → status=completed   (assemble 步骤写)
      │  失败 → status=failed      (task_failed 事件消费者写 error_code)
      ▼
GET /v1/analysis-reports/:bid     客户端轮询,直到 completed / failed
      │  completed
      ▼
POST /v1/analysis-reports/:bid/derive  { kind }   ← 走 capability 链,独立计费、幂等缓存
      ├─ reverse_prompt    → 一条创作提示词
      └─ replication_plan  → 按分镜的 N 步复刻方案
```

**七个关键设计点**:

1. **复用 Pipeline,不发明轮子** —— `material_analysis_v1` 是 `gen_post_process_templates` 里的一条系统预置流水线(5 步),提交直接复用 `SubmitTaskHandler` 的计费 / 冻结 / 入队;PostProcessWorker 经 Orchestrator 执行。**缺 worker → 报告永远 processing**。
2. **报告独立持久(红线 R2)** —— 报告落非分区表 `gen_analysis_reports`,生命周期**独立于**执行用的 `gen_generation_tasks`(分区表会随时间老化归档);task 行被清理后,报告仍可全量读。
3. **强 Schema 校验 + 校验失败重试(R13/D5)** —— step4 多模态 LLM 用 provider 原生 `response_mime_type=application/json` 保证可解析,再经 `StrictParseAnalysisOutput`(`additionalProperties:false` 等价)+ `ValidateAnalysisOutput`(语义约束)强校验;**失败不静默降级**,而是按 RetryPolicy(`max_attempts=2`)重跑 step4(重新调 LLM)。重试耗尽 → step 失败 → 整条管线失败 → 退款。
4. **ASR 是 best-effort,多模态是硬依赖** —— 无音轨 / 转写失败 → 空 transcript,**不阻断**(画面 OCR 经 `shots[].on_screen_text` 兜底);多模态失败 → 整份报告 `failed`。
5. **关键帧是中间产物,TTL 回收** —— 抽出的帧上传 R2(私有),仅供 step4 消费;`FrameCleanupWorker` 在 `frame_ttl_days`(默认 7 天)后删 R2 对象并置 `frames_purged_at`,**报告本体永存**。帧的 R2 key **不对客户端暴露**(详情仅给 `frames_summary` 的 count/strategy)。
6. **derive 走 capability 链,独立计费** —— 主链拆解 step3/4 在管线级冻结下直调 provider(不双计费);derive 是用户显式触发的独立动作,经 `capability.Invoke(SurfaceInternal)` 走 14 步链,自带 freeze/confirm + cache 幂等 + safety。
7. **计费缺价硬拒,零 fail-open** —— 主链缺价 `50830`、derive 缺价 `40201`,绝不免费执行;显式免费须配 `credit_cost=0` 规则行。

---

## 2. 鉴权与通用约定

- **BaseURL**:开发 `http://localhost:9999/v1` · 生产 `https://api.aigc.example.com/v1`。
- **全部端点需 JWT + App 签名**(挂在认证路由组):请求头须带 `Authorization: Bearer <jwt>` 及签名四件套 `X-App-Id` / `X-Timestamp` / `X-Nonce` / `X-App-Signature`(详见 [overview.md §3/§5](overview.md))。
- **禁止**在 body 里传 `app_id` / `tenant_id` / `account_id` —— 一律由中间件从 JWT / 签名注入,客户端伪造无效。
- **响应 Envelope**:`{ "code": 0, "message": "...", "data": {...}, "request_id": "<uuid>", "timestamp": <unix> }`,`code=0` 即成功;失败时 `code` 为业务错误码(见 §9),HTTP 状态码同步语义化(202/400/401/403/404/409/500…)。下文示例只展开 `data`。

---

## 3. 端点

| 方法 | 路径 | 作用 | 同步/异步 |
|---|---|---|---|
| `POST` | `/v1/analysis-reports` | 提交拆解 | 同步返 202,拆解异步 |
| `GET` | `/v1/analysis-reports/:bid` | 报告详情(轮询) | 同步 |
| `GET` | `/v1/analysis-reports` | 报告列表(分页) | 同步 |
| `POST` | `/v1/analysis-reports/:bid/derive` | 反推提示词 / 复刻方案 | 同步(内部调 LLM) |

### 3.1 提交拆解 —— `POST /v1/analysis-reports`

**Request body**

```json
{ "material_bid": "0d4c1a2e-...-uuid" }
```

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `material_bid` | string(uuid) | ✓ | 待拆解视频素材的 `gen_assets.bid`。须**属当前账号 + 已上传完成 + `content_type=video`**,否则 `40471`。 |

**Response —— `202 Accepted`**

```json
{
  "report_bid": "9f2b...-uuid",
  "task_bid":   "7a13...-uuid",
  "status":     "processing"
}
```

| 字段 | 说明 |
|---|---|
| `report_bid` | 报告 bid —— **后续用它轮询详情 / derive**。 |
| `task_bid` | 执行用管线任务 bid(审计参考;task 老化后可悬空,报告不依赖)。 |
| `status` | 恒为 `processing`(命中幂等既有报告时,可能直接是 `completed`/`failed`)。 |

**幂等**:同 `(tenant_id, material_bid, pipeline_version, file_hash)` 重复提交 → **直接返既有报告,零重复扣费**(并发双提交也只冻结一次)。素材内容变(file_hash 变)或 `pipeline_version` 升级 = 新报告行(历史可见)。

**计费**:提交即按管线 `pipeline:material_analysis_v1` 冻结(`per_second`,详见 §7);缺价 → `50830` 硬拒,**此时报告尚未创建,干净返回**。

**主要错误**:`40471` 素材不可拆解 · `40336` 竞品素材受限(R7,见 §8)· `40200` 余额不足 · `50830` 管线缺价 · `40000` body 格式错 · `40300` `material_bid` 缺失。

---

### 3.2 报告详情 —— `GET /v1/analysis-reports/:bid`

账号作用域查询;**跨账号 / 不存在同返 `40470`**(不泄漏存在性)。前端按 `report_schema_version` 做 Schema 驱动渲染。

**Response data**(字段随 `status` 出现/省略;`omitempty`)

```json
{
  "bid": "9f2b...-uuid",
  "material_bid": "0d4c...-uuid",
  "pipeline_version": "material_analysis_v1",
  "report_schema_version": "v1",
  "status": "completed",
  "report":  { "theme": {...}, "composition": [...], "shots": [...], "highlights": [...], "risks": [...] },
  "scores":  { "hook": {...}, "info_density": {...}, "...": {} },
  "transcript": { "text": "...", "srt": "1\n00:00:00,000 --> ..." },
  "frames_summary": { "count": 18, "strategy": "scene" },
  "derived": { "reverse_prompt": { "output": {...}, "execution_bid": "...", "kind": "reverse_prompt" } },
  "created_at": 1749900000,
  "updated_at": 1749900180
}
```

| 字段 | 出现时机 | 说明 |
|---|---|---|
| `status` | 总是 | `processing` / `completed` / `failed`。 |
| `error_code` | `failed` 时 | 失败码(如 `schema_validation_failed` / `pipeline_failed`),用于排障/提示。 |
| `failed_step` | `failed` 时 | 失败步骤 step_key(可能为空)。 |
| `report` | `completed` 时 | 四维拆解,结构见 §4。 |
| `scores` | `completed` 时 | 六维评分,见 §4。 |
| `transcript` | `completed` 且有音轨时 | `{ text, srt? }`;无音轨/失败时为空文本(best-effort)。 |
| `frames_summary` | `completed` 时 | **仅 `count` + `strategy`**(`scene`/`interval`);**帧 R2 key 不外暴露**。 |
| `derived` | derive 过后 | 按 kind 收口:`{ reverse_prompt?, replication_plan? }`,见 §3.4。 |
| `created_at` / `updated_at` | 总是 | Unix 秒。 |

> **轮询建议**:提交后用 `report_bid` 轮询本端点,见 `status` 由 `processing` → `completed`/`failed` 即停。整条管线 `expected_duration_sec=300`(抽帧 + ASR 较重);建议**首轮 5s、随后 5–10s 间隔退避**,设客户端超时上限(如 10 min)。**异步拆解的失败不走 HTTP 错误**,而是体现在 `status=failed` + `error_code`。

---

### 3.3 报告列表 —— `GET /v1/analysis-reports`

租户 + 账号维度分页,按 `created_at` 倒序。

**Query**:`page`(默认 1)· `page_size`(默认 20,**上限 100**)。

**Response data**

```json
{
  "items": [
    { "bid": "9f2b...", "material_bid": "0d4c...", "pipeline_version": "material_analysis_v1",
      "status": "completed", "scores": { "...": {} }, "created_at": 1749900000 }
  ],
  "total": 42
}
```

列表项为**摘要**(不含 `report`/`transcript`/`frames` 等大字段,仅带 `scores` 供卡片展示)。

---

### 3.4 触发 derive —— `POST /v1/analysis-reports/:bid/derive`

从**已 completed** 的报告反推衍生产物。报告未完成 → `40471`。经 capability 链,**独立计费**(`per_request`)。

**Request body**

```json
{ "kind": "reverse_prompt" }
```

| `kind` | 产出 |
|---|---|
| `reverse_prompt` | 一条可直接用于 AI 生成同类素材的**创作提示词**(单段文本)。 |
| `replication_plan` | 按分镜顺序的 **N 步复刻方案** + 合规注意。 |

其它值 → `40472`。

**Response data**

```json
{
  "kind": "reverse_prompt",
  "payload": {
    "output": { "kind": "reverse_prompt", "result_text": "<衍生文本正文>" },
    "execution_bid": "c1d2...-uuid",
    "kind": "reverse_prompt"
  },
  "execution_bid": "c1d2...-uuid",
  "cached": false
}
```

| 字段 | 说明 |
|---|---|
| **`payload.output.result_text`** | **真正的衍生文本**(提示词正文 / 复刻方案正文)—— 取这个字段用。 |
| `payload.output.kind` | 回显 kind。 |
| `execution_bid` | capability 执行 bid(M2 谱系锚点;命中报告级缓存时可能为空)。 |
| `cached` | capability 层缓存命中标记。 |

**幂等**:同一报告同一 `kind` **已 derive 过 → 直接返存量、零重复扣费**(产物落 `gen_analysis_reports.derived[kind]`)。需重算请理解这是设计上的「一次产出长期复用」。

**主要错误**:`40470` 报告不存在/越权 · `40471` 报告未 completed · `40472` kind 非法 · `40200` 余额不足 · `40201` derive 定价缺失。

---

## 4. 报告数据结构(Schema v1)

`report` + `scores` 由 step4 多模态 LLM 同次产出,经强校验后落库;前端按本结构 Schema 驱动渲染。权威契约见 [analysis_report_schema_v1.json](analysis_report_schema_v1.json)(枚举与后端 `analysis_report_v1.go` 由 guard test 锁死一致)。

### 4.1 `report` —— 四维拆解

**`theme`**(题材内核,全必填):`genre` 题材 · `core_appeal` 内核卖点一句话 · `summary` 整体概述(≤500 字)。

**`composition[]`**(成分构成,≥1 项):

| 字段 | 类型 | 说明 |
|---|---|---|
| `kind` | enum | `gameplay` / `ui_capture` / `live_action` / `cg_animation` / `text_card` / `talking_head` / `mixed_edit` / `other` |
| `percent` | number | 0–100;**所有 `percent` 之和 ≈ 100(容差 [95,105])** |
| `note` | string? | 备注 |

**`shots[]`**(分镜序列 = **「N 步骤」**,≥1 项):

| 字段 | 类型 | 说明 |
|---|---|---|
| `index` | int | **从 1 连续递增** |
| `start_ms` / `end_ms` | int | 起止毫秒;`end_ms > start_ms`,**按时序不重叠**,`end_ms ≤ 素材时长 + 1500ms`(容差) |
| `visual` | string | 画面描述(必填) |
| `audio_line` | string? | 台词/旁白 |
| `on_screen_text` | string? | 屏幕字幕(无音轨时的兜底信号) |
| `function` | enum | `hook` / `pain_point` / `showcase` / `social_proof` / `benefit` / `cta` / `transition` / `other` |
| `frame_refs` | array? | 模型自填前向引用,**装饰性,平台不校验/不消费**(元素类型随模型而异) |

**`highlights[]`**(亮点,≥1 项):`point` 亮点描述(必填)· `evidence_shot` 对应分镜 index(`0`=未指定,否则须 ∈ [1, 分镜数])。

**`risks[]`**(风险,可空):`point` 描述 · `severity` ∈ `info`/`warn`/`high` · `evidence_shot` 同上。

### 4.2 `scores` —— 六维评分

六维固定:`hook` · `info_density` · `visual_impact` · `pacing` · `conversion` · `compliance`,每维一个 `{ stars: 1–5, reason: "<理由>" }`。

### 4.3 旁路字段

- **`transcript`**:`{ text, srt? }` —— ASR 转写稿;`srt` 为带时间戳字幕(dashscope fun-asr 提供,gemini 兜底为空)。无音轨/失败时 `text` 为空(best-effort,不阻断拆解)。
- **`frames_summary`**:`{ count, strategy }` —— 关键帧数量与抽帧策略(`scene` 场景变化 / `interval` 固定间隔兜底)。**不含帧 R2 key**。

---

## 5. 状态与生命周期

报告状态**镜像管线终态,非状态机**(无转移守卫):

| status | 含义 | 谁写的 |
|---|---|---|
| `processing` | 提交时落库,管线执行中 | 提交 handler |
| `completed` | 拆解成功,`report`/`scores`/… 就绪 | `assemble` 步骤(CAS `processing→completed`) |
| `failed` | 管线失败 | `creation.task_failed` 事件消费者(CAS `processing→failed`,置 `error_code`) |

- 单写者:`completed` 与 `failed` 由互斥的 `status='processing'` CAS 保证(已 completed 不会被 failed 覆盖)。
- **失败可重提**:同素材重新 `POST` 会命中幂等键返回那条 failed 报告;需重跑请改素材或等 `pipeline_version` 升级(升级即新报告行)。
- 异步完成信号另发 outbox 事件 `creation.analysis_completed` / `creation.analysis_failed`(M1 暂无消费者,为 M2 谱系 / M3 工作台预留;**客户端请用轮询,不依赖事件**)。

---

## 6. 幂等小结

| 动作 | 幂等键 | 命中行为 |
|---|---|---|
| 提交拆解 | `(tenant_id, material_bid, pipeline_version, file_hash)` partial-unique | 返既有报告,零重复扣费 |
| derive | `gen_analysis_reports.derived[kind]` 已存在 | 返存量产物,零重复扣费 |

---

## 7. 计费

| 动作 | 计价口径 | 计费实体 | 缺价 |
|---|---|---|---|
| 提交拆解(主链) | `per_second`,管线级**整体冻结**(非逐步) | `entity_code='pipeline:material_analysis_v1'` | `50830` 硬拒 |
| derive(每次) | `per_request`,每次固定 | `entity_type='capability'`,`entity_code` = `reverse_prompt`/`replication_plan` | `40201` 硬拒 |

> 当前 seed 价(**以线上定价规则为准,seed 值为运维标定前的占位**):主链约 2 credits/秒(free 档 3)+ 最小封底(default/free ≈ 30s 当量);derive 每次 2 credits。计费缺价**绝不 fail-open**,显式免费须配 `credit_cost=0` 规则行。

---

## 8. 合规红线 R7 —— 竞品素材禁入生成/分发

竞品导入素材标记 `asset_source='competitor_import'`。**可被本功能拆解(analysis),但禁止进入生成输入 / 分发链路**:compose / asr 等提交校验器在提交期检测 `IsCompetitorSource` → `40336 ErrCompetitorAssetRestricted` 硬拒。即「能拆解、能学,不能直接拿去生成或分发」。

---

## 9. 错误码

**同步(HTTP 直接返,见 §3）**

| code | 名称 | 触发 |
|---|---|---|
| `40470` | `ErrAnalysisReportNotFound` | 报告不存在 / 跨账号越权(同码不泄漏存在性) |
| `40471` | `ErrAnalysisMaterialInvalid` | 素材不可拆解(不存在/不属己/未完成上传/非视频);derive 时报告非 completed 复用此码 |
| `40472` | `ErrAnalysisDeriveKindInvalid` | derive kind 非法(仅 `reverse_prompt` / `replication_plan`) |
| `40336` | `ErrCompetitorAssetRestricted` | 竞品导入素材禁入生成/分发(R7) |
| `40200` | 余额不足 | 钱包冻结失败 |
| `50830` | `ErrPipelinePricingMissing` | 拆解管线定价缺失 |
| `40201` | (capability `pricing_missing`) | derive 定价缺失 |
| `40000`/`40300` | body 格式错 / 校验失败 | `material_bid` 缺失等 |
| `401xx` | 鉴权/签名 | 见 [overview.md §6/§7](overview.md) |

**异步(不走 HTTP,体现在 `GET 详情` 的 `status=failed` + `error_code`)**:`schema_validation_failed`(step4 LLM 输出结构/语义违例,重试耗尽)· `pipeline_failed`(其它步骤失败,兜底码)。内部信号 `ErrAnalysisSchemaInvalid` / `ErrAnalysisSemanticInvalid` 不外漏客户端,仅驱动 step4 重试。

---

## 10. 运维 / 可观测(供后端 & SRE)

- **模型挂载点(均在 DB,可热切,无需重启)** —— 详见 [docs/ops/material-analysis-model-switch.md](../ops/material-analysis-model-switch.md):
  | 角色 | 挂载点 | 默认模型 |
  |---|---|---|
  | ASR | 管线 `asr` 步 `params.model_version_bid` | `fun-asr`(best-effort) |
  | 多模态拆解(核心) | 管线 `analysis` 步 `params.model_version_bid` | `gemini-3.1-flash-lite` |
  | derive | `prov_capability_defaults(capability='reverse_prompt'/'replication_plan')` model-only 行(收敛批 2026-08-19;metadata 兼容读已删除,缺行时调用方须传 model_hint) | `gemini-3.1-flash-lite` |
  > 多模态步的模型**必须已声明 `frame_urls`**(以 `GET /v1/models` 的 param_schema 为准,见 [provider.md §3.3.1](provider.md))。2026-09-09 起 gemini 原生与 OpenAI 兼容(`{{_chat_messages}}`)两族**都**支持,不再限于 gemini 系;但换到未声明该参数的模型仍会丢帧退化为纯文本。模型按 `model_version_bid`(UUID)挂载,跨环境/重 seed 后须按 `model_code` 重解析 bid。
- **关键帧回收**:`AnalysisFrameCleanupWorker`(worker 进程),~30min tick、TTL 7 天,删 R2 帧对象后置 `frames_purged_at`;delete-then-mark 保证删失败下轮重试,不漏删。
- **抽帧参数**(管线 `frames` 步):`scene_threshold=0.30` · `max_frames=24`(硬上限 32)· `min_interval_sec=1.0`(scene 帧 <3 时切 interval 兜底)。
- **专属指标**(`internal/platform/telemetry/analysis_metrics.go`):`analysis.report_terminal_total{status}` · `analysis.frames_extract_total{strategy}` · `analysis.frames_count_total{strategy}`(scene/interval 兜底率)· `analysis.derive_total{kind,outcome}` · `analysis.frames_purged_total{dim}`;逐步执行/重试/时延复用通用管线指标 `ppStepExecCounter{processor_type,status}`。

---

## 11. 端到端示例(伪 curl,省略签名头)

```bash
# 1) 提交拆解(material_bid 来自素材上传完成后的 gen_assets.bid)
curl -X POST $BASE/v1/analysis-reports -H "Authorization: Bearer $JWT" \
     -H 'Content-Type: application/json' -d '{"material_bid":"0d4c...-uuid"}'
# → 202 { "report_bid":"9f2b...", "task_bid":"7a13...", "status":"processing" }

# 2) 轮询详情,直到 status=completed / failed(首轮 5s,之后 5–10s 退避)
curl $BASE/v1/analysis-reports/9f2b...-uuid -H "Authorization: Bearer $JWT"
# → { "status":"completed", "report":{...,"shots":[...N 个分镜...]}, "scores":{...} }

# 3a) 反推创作提示词
curl -X POST $BASE/v1/analysis-reports/9f2b...-uuid/derive -H "Authorization: Bearer $JWT" \
     -H 'Content-Type: application/json' -d '{"kind":"reverse_prompt"}'
# → { "payload":{"output":{"result_text":"<可直接喂 AI 的创作提示词>"}}, "cached":false }

# 3b) 生成 N 步复刻方案
curl -X POST $BASE/v1/analysis-reports/9f2b...-uuid/derive -H "Authorization: Bearer $JWT" \
     -H 'Content-Type: application/json' -d '{"kind":"replication_plan"}'
# → { "payload":{"output":{"result_text":"<按分镜的 N 步复刻方案>"}}, "cached":false }
```

---

**相关文档**:[overview.md](overview.md)(通用机制)· [creation.md §竞品素材拆解](creation.md)(BC 内速查)· [analysis_report_schema_v1.json](analysis_report_schema_v1.json)(报告 Schema)· [error-codes.md](error-codes.md)(全量错误码)· [docs/ops/material-analysis-model-switch.md](../ops/material-analysis-model-switch.md)(模型切换 runbook)。
