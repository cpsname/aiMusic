# Capability Platform BC HTTP API

> **Module**: `internal/capability/port/http`  Prefix: `/v1`  JWT + Admin role required (no public routes).
>
> **Sources of truth**:
> - 路由:`internal/capability/port/http/routes.go`
> - 业务契约:`internal/capability/api.go`(`CapabilityAPI` interface + DTO)
> - 错误码映射:`internal/capability/port/http/invoke_handler.go`(`errorCodeMapping`)
>
> Capability Platform 是 P7 全程 + M6 W12 完整交付的"能力平台",收编了 20 个 published capability(5 utility + 9 App Store 工具 + 5 PostProcess via bridge + 1 mobile-first **p9_05** `prompt_assist`),提供统一的 12-step middleware chain(Resolve / Permission / Quota / Cache / WalletFreeze / SchemaInput / SafetyPre / **Scheduler with backpressure 503** / Executor / SchemaOutput / SafetyPost / WalletConfirm / RecordExecution)。
>
> HTTP API 主要给:① 第三方系统集成、② 运维 / 排障、③ 开发本地调试 / Marketplace 后台。**LLM tool 调用 / Workflow node 调用直接走 Go function `capability.Invoke`,不经过 HTTP**(零 HTTP 框架开销)。

---

## 路由总览(6 endpoints)

| Method | Path | Operation | 鉴权 | 错误段 |
|---|---|---|---|---|
| `POST` | `/v1/capabilities/:code/invoke` | 调用 capability(同步执行 12-step chain) | JWT + admin | 40030/40110/40402/42930/40330/50083/50384/**50385** |
| `POST` | `/v1/capabilities/:code/invoke/stream` | 流式调用 capability(SSE,token 级推送) | JWT + admin | 40030/40110/40402/50000 |
| `GET` | `/v1/capabilities` | List 全部 capability(支持 category/status/page) | JWT + admin | 40030/50000 |
| `GET` | `/v1/capabilities/:code` | 单 capability + 全部版本 | JWT + admin | 40402/40031 |
| `GET` | `/v1/capabilities/:code/executions` | 列流水(status/since/until/分页) | JWT + admin | 40030/40031/50000 |
| `GET` | `/v1/capabilities/:code/executions/:bid` | 单条 execution 详情 | JWT + admin | 40402/40030 |

> **统一签名 + JWT**:5 个端点全部走全局 `/v1/*` 中间件链(App 签名 HMAC + JWTAuthMiddleware),再叠加 `requireAdmin = GetRoleMiddleware("admin","super_admin")` 局部 gate。详见 [overview.md §4 JWT](overview.md#4-jwt-鉴权机制) + [§5 App 签名](overview.md#5-app-签名机制)。

---

## 通用响应 Envelope

所有端点统一返 `{code, message, data, request_id, timestamp}`(见 [overview.md §6](overview.md#6-统一响应-envelope))。

```json
{
  "code": 0,
  "message": "success",
  "data": { ... },
  "request_id": "req-uuid",
  "timestamp": 1730000000
}
```

业务失败时 `code` ≠ 0,`data` 仍可能含 `execution_bid` / `output` / `error_code` 等部分内容(见各端点 `Returns 业务失败` 说明)。

---

## 1. POST /v1/capabilities/:code/invoke — 调用 capability

调用单个 capability,**同步**经过 12-step middleware chain,返回 execution 结果。

**解析作用域(2026-08-27 起)**:code → 能力行的解析为 `(tenant_id, code)` →
`(0, code)` 两段回落,租户覆写行优先 —— 平台能力全部注册在 `tenant_id=0`,
任何租户上下文(会话/工作区均带真实租户)都必须能解析到它;租户可用同 code
的自有行覆写平台行。未命中 → 业务终态 `capability_not_found`(确定性,重试
无用),与基础设施错误(`internal_error`,可重试)严格分开。

### Path 参数
| 参数 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `code` | string | ✓ | capability 全局唯一标识(如 `calculator` / `spec_validate` / `magick_resize`)|

### Request Body(`InvokeRequestBody`)
```json
{
  "input": {
    "expression": "1+2*3"
  },
  "version_constraint": "",
  "surface_kind": "direct_api",
  "idempotency_key": "client-gen-uuid-or-empty",
  "correlation_id": "",
  "metadata": {},
  "timeout_ms": 0
}
```

| 字段 | 类型 | 必填 | 默认 | 说明 |
|---|---|---|---|---|
| `input` | object | ✓ | — | capability 业务输入,schema 由 capability 各自定义(见各 builtin 文档) |
| `version_constraint` | string | ✗ | `""` | SemVer 约束(如 `^1.2` / `1.2.3`);空 = 当前 published 版本 |
| `surface_kind` | enum | ✗ | `direct_api` | `direct_api` / `internal`(HTTP 端点禁止外部传 `llm_tool` / `workflow_node`)|
| `idempotency_key` | string | ✗ | `""` | 客户端幂等 key;同 key + input 命中 cache 直接返同结果 |
| `correlation_id` | string | ✗ | auto | 跨 capability 关联(同一 user request 多次调用)|
| `metadata` | object | ✗ | `{}` | 透传给 executor,**不影响 cache_key** |
| `timeout_ms` | int | ✗ | version 默认 | 超时覆盖(0 = 用 version 配置)|

### Returns 成功(HTTP 200)
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "execution_bid": "0192c3...",
    "status": "succeeded",
    "output": {"result": 7, "expression": "1+2*3"},
    "cache_hit": false,
    "duration_ms": 5,
    "cost_credits": 0,
    "error_code": "",
    "error_message": "",
    "correlation_id": "..."
  }
}
```

### Returns 业务失败(HTTP 4xx/5xx,但 envelope `code` 含具体错误段)

| envelope code | HTTP | 触发条件 | 来源 |
|---|---|---|---|
| `40030` | 400 | request body 不合法 | `invoke_handler.go::codeInvalidPayload` |
| `40031` | 400 | path param `code` 为空 | `codeCapabilityCodeEmpty` |
| `40110` | 401 | JWT 缺 `account_id`(中间件未注入)| `codeUnauthorized` |
| `40300` | 403 | 非 admin/super_admin 角色 | `requireAdmin` middleware |
| `40402` | 404 | `capability_not_found` / `version_not_found` | Resolve middleware → `errorCodeMapping` |
| `40330` | 403 | `safety_blocked`(SafetyPre / SafetyPost 拦截)| SafetyMiddleware |
| `42930` | 429 | `quota_exceeded`(超出 daily/monthly 配额)| QuotaMiddleware → atomic CTE |
| `50083` | 500 | `executor_error`(executor 内部错)| ExecutorMiddleware |
| `50384` | 503 | `circuit_blocked`(circuit breaker 跳闸)| 自治 middleware(留 P5 真实施)|
| **`50385`** | 503 | **`queue_overloaded`(M6 W11 backpressure 触发)** | **SchedulerMiddleware**:`queue depth ≥ backpressure_threshold` |
| `50410` | 504 | `timeout` | Executor 超时 |
| `50000` | 500 | 其他基础设施错误 | `codeInternalError` |

### Backpressure 503 触发条件(M6 W11)

`SchedulerMiddleware` 按 `cap_versions.resource_profile` 实时查 `cap_resource_profiles.backpressure_threshold`:

| Profile | Queue | Threshold | 触发场景 |
|---|---|---|---|
| `light` | `cap:light` | 2000 | 平台底建过载(罕见)|
| `cpu_intensive` | `cap:cpu` | 500 | ImageMagick / FFmpeg 工具堆积 |
| `memory_heavy` | `cap:mem` | 200 | 大文件 / video transcode 堆积 |
| `network_io` | `cap:net` | 1000 | LLM 调用 / 远程 API 堆积 |
| `gpu_required` | `cap:gpu` | 50 | GPU 推理(stable diffusion 等)堆积 |

返回的 `error_message` 含详细信息(便于客户端决定降级 / 等待):
```
queue cap:cpu depth 600 ≥ threshold 500 (resource_profile=cpu_intensive) — retry later or use lighter capability
```

### 调用示例

#### Calculator(纯算术,light profile)
```bash
POST /v1/capabilities/calculator/invoke
Authorization: Bearer <admin_jwt>
X-Distribution-Code: ...
X-App-Signature: ...
X-Timestamp: 1730000000
X-Nonce: <uuid>

{
  "input": {"expression": "(1+2) * (3+4)"}
}
```
返:
```json
{"code": 0, "data": {"execution_bid": "...", "status": "succeeded", "output": {"result": 21, "expression": "(1+2) * (3+4)"}, "cache_hit": false, "duration_ms": 3}}
```

#### spec_validate(App Store 规格校验,light profile)
```json
{
  "input": {
    "store_code": "ios",
    "asset_kind": "screenshot",
    "device_code": "iphone_69",
    "width_px": 1320,
    "height_px": 2868,
    "format": "png",
    "orientation": "portrait"
  }
}
```
返:
```json
{
  "code": 0,
  "data": {
    "status": "succeeded",
    "output": {
      "passed": true,
      "violations": [],
      "matched_spec_id": 12,
      "matched_spec": {"width": 1320, "height": 2868, "orientation": "portrait", "max_file_kb": 8192, "allowed_formats": ["png", "jpg"], "required": true}
    }
  }
}
```

#### text_translate(LLM 翻译,network_io profile)
```json
{
  "input": {
    "text": "你好,世界",
    "target_lang": "en",
    "source_lang": "zh",
    "model_hint": "<gemini-2.5-flash model_version_bid>"
  }
}
```

### 流式调用 — POST /v1/capabilities/:code/invoke/stream

`text/event-stream` 流式版本(P8-02 D2),经**同一条 14-step 链**;仅 `SupportsStreaming` 的 capability 适用(当前:`text_translate`),其余返末帧 `streaming_not_supported`。

请求体、鉴权同 `POST .../invoke`。响应为 SSE:

| event | 说明 |
|---|---|
| `chunk` | 增量帧;`data` = `StreamChunk`(`is_final=false`,`delta` 含 token 增量)|
| `done` | 终帧;`data` = `StreamChunk`(`is_final=true`,`delta`=最终 output,`error` 非空则失败)|
| `: hb` | 心跳注释行(无新 chunk 时每 15s)|

`StreamChunk`:`{execution_bid, sequence, is_final, delta, error}`。

- 起流前的服务级错误(参数 / capability 未实装)走标准 JSON 错误,不进 SSE。
- 客户端断连 → 服务端 ctx 取消 → 上游 LLM 调用中止(不再消耗 token)。
- 计费与同步一致:WalletFreeze 前置、WalletConfirm 后置(按估算额,与 `invoke` 同口径)。

---

## 2. GET /v1/capabilities — List capabilities

列出全部 published capability(平台级 + 当前租户),支持过滤 + 分页。Marketplace 后台用。

### Query 参数
| 参数 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `category` | string | `""` | 过滤分类(`compliance` / `image_processing` / `llm` / `productivity` / `utility` / `creative` / `data`)|
| `status` | string | `""` | 过滤状态(`published` / `draft` / `deprecated`)|
| `page` | int | `1` | 页码(>=1)|
| `page_size` | int | `20` | 每页(1-100,clamp)|

### Returns
```json
{
  "code": 0,
  "data": {
    "items": [
      {
        "bid": "0192...",
        "code": "calculator",
        "name": "Calculator",
        "slug": "calculator",
        "category": "productivity",
        "description": "...",
        "icon_url": "",
        "author_type": "system",
        "status": "published",
        "install_count": 0,
        "pricing_hint": {...},
        "metadata": {...},
        "latest_version": {...},
        "published_version": {...},
        "tenant_id": 0,
        "created_at": "..."
      },
      ...
    ],
    "page": 1,
    "page_size": 20,
    "total": 19
  }
}
```

### 调用示例
```bash
GET /v1/capabilities?category=image_processing&status=published&page=1&page_size=10
```

---

## 3. GET /v1/capabilities/:code — 单 capability 详情

返回 capability 元数据 + 全部版本(含 deprecated / retired)。

### Path 参数
| 参数 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `code` | string | ✓ | capability code |

### Returns
```json
{
  "code": 0,
  "data": {
    "bid": "0192...",
    "code": "spec_validate",
    "name": "App Store Spec Validator",
    "category": "compliance",
    "description": "...",
    "status": "published",
    "metadata": {...},
    "versions": [
      {
        "bid": "...",
        "semver": "1.0.0",
        "runtime_type": "builtin",
        "input_schema": {...},
        "output_schema": {...},
        "capability_flags": ["idempotent","fast","platform_builtin"],
        "invocation_modes": ["sync"],
        "resource_profile": "light",
        "timeout_seconds": 5,
        "status": "published",
        "review_status": "approved",
        "canary_percent": 100,
        "release_notes": "...",
        "published_at": "...",
        "created_at": "..."
      }
    ],
    "tenant_id": 0,
    "created_at": "..."
  }
}
```

### 错误
| code | 触发 |
|---|---|
| `40402` | capability code 不存在 |
| `40031` | path 参数为空 |

---

## 4. GET /v1/capabilities/:code/executions — List execution 流水

列出某 capability 的执行流水,支持 status / 时间范围 / 分页过滤。

### Path 参数
| 参数 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `code` | string | ✓ | capability code |

### Query 参数
| 参数 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `status` | string | `""` | 过滤状态(`pending` / `running` / `succeeded` / `failed` / `timed_out` / `circuit_blocked` / `canceled`)|
| `since` | RFC3339 / `YYYY-MM-DD` / `YYYY-MM-DDTHH:MM:SS` | — | 起始时间(包含)|
| `until` | 同上 | — | 截止时间(包含)|
| `page` | int | `1` | 页码 |
| `page_size` | int | `20` | 每页(1-100)|

> 时间字段空 / 非法格式 → 视为"不限",不报错(降级容错)。

### Returns
```json
{
  "code": 0,
  "data": {
    "items": [
      {
        "bid": "0192...",
        "capability_code": "calculator",
        "semver": "1.0.0",
        "surface_kind": "direct_api",
        "status": "succeeded",
        "input": {"expression": "1+2"},
        "output": {"result": 3, "expression": "1+2"},
        "cache_hit": false,
        "duration_ms": 5,
        "cost_credits": 0,
        "error_code": "",
        "error_message": "",
        "started_at": "...",
        "finished_at": "...",
        "created_at": "..."
      },
      ...
    ],
    "page": 1,
    "page_size": 20,
    "total": 142
  }
}
```

> **注**:`duration_ms` / `cost_credits` 字段当前在响应 DTO 中保留位但 `entity.Execution → DTO` mapper 暂未投影，仍需后端补齐；对应实现位置为 `internal/capability/api_local.go::executionToDTO`。流水核心字段(input/output/status/error)已可用。

### 调用示例
```bash
# 列 calculator 最近的失败流水
GET /v1/capabilities/calculator/executions?status=failed&page_size=50

# 列某时间范围内的所有流水
GET /v1/capabilities/spec_validate/executions?since=2026-05-01&until=2026-05-31
```

---

## 5. GET /v1/capabilities/:code/executions/:bid — 单条 execution 详情

按 execution_bid 查单条流水。`:code` 仅做 URL 一致性,实际查询用 `:bid`(全局唯一 UUID)。

### Path 参数
| 参数 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `code` | string | ✓ | capability code(URL 一致性) |
| `bid` | UUID | ✓ | execution_bid(`POST invoke` 返回的)|

### Returns
同 [§4 List 单条 item](#4-get-v1capabilitiescodeexecutions--list-execution-流水) 结构。

### 错误
| code | 触发 |
|---|---|
| `40030` | bid 不是合法 UUID |
| `40402` | execution 不存在 |

### 调用示例
```bash
GET /v1/capabilities/spec_validate/executions/0192e5fc-1234-5678-9abc-def012345678
```

---

## 5b. POST /v1/capabilities/:execution_bid/settle — 延迟结算用量上报

凭证型能力(签发后客户端侧执行)的用量回报口:按实际用量结算挂起冻结,差额
自动退回;不上报由 DeferredSettlementReconciler 兜底按预扣全额结算(反向开关
`deferred_settlement` 默认启用)。幂等:同 execution 重复上报返首次结算结果。

**终态语义(R1, 2026-08-29)**:客户端实报结算收敛 `succeeded`;兜底(无证据)结算收敛显式终态 **`outcome_unknown`** —— 审计上与证据结算严格区分。`outcome_unknown` **禁盲重试**:该态代表副作用可能已发生,上游重放前必须先查此流水(`GET executions/:bid`)而非直接重发。

**副作用重试红线(R2, 2026-08-29)**:计费型 / 不可逆能力的客户端重试**必须携带 `idempotency_key`** —— 键经 `shared/idem.ExecKey` 归一落 `cap_executions.idempotency_key`(部分唯一索引 claim-once),同键重试不产生第二条流水记录;未携键的重试平台无法为你去重。

## 错误码段(完整)

复用全局规范(见 [overview.md §7](overview.md#7-错误码段)),capability 特有码:

| 段 | 含义 | HTTP | 来源 middleware |
|---|---|---|---|
| `400xx` | 入参 / payload 错 | 400 | InvokeHandler 自校验 |
| `401xx` | JWT / 签名 / 鉴权失败 | 401 | 全局中间件 |
| `403xx` | role gate / safety_blocked | 403 | requireAdmin / SafetyMiddleware |
| `404xx` | capability / version / execution not_found | 404 | Resolve / ExecutionRepo |
| `429xx` | quota_exceeded | 429 | QuotaMiddleware |
| `50000` | 通用基础设施错 | 500 | InvokeHandler |
| `50083` | executor_error | 500 | ExecutorMiddleware |
| `5008x` | executor_not_registered / executor_not_resolved | 500 | ResolveMiddleware |
| `50384` | circuit_blocked | 503 | CircuitBreakerMiddleware(留 P5 真实施)|
| **`50385`** | **queue_overloaded(M6 W11)** | **503** | **SchedulerMiddleware** |
| `50410` | timeout | 504 | Executor / ctx.Deadline |

---

## transcript_derive — 转写衍生(听语 P-3,2026-08-18)

`POST /v1/capabilities/transcript_derive/invoke`(direct_api surface;workflow_node 已启用供 V2 编排)。

**输入**(input_schema 强制,`additionalProperties:false`):

```json
{ "kind": "minutes",                       // 闭集: minutes|polish|chapterize|action_items|keyterms
  "template": "standard",                  // 仅 minutes: standard|decision|interview|lecture (默认 standard)
  "transcript_asset_bid": "...",           // 转写产物资产 (归属校验在 creation 侧, 不符按 not found 隐匿)
  "language": "zh",                        // 可选输出语言
  "text": "...",                           // 仅 kind=keyterms 可用内联文本 (会前议程提词, ≤50k 字符) 替代资产引用
  "model_hint": "..." }                    // 可选模型覆盖 (三级降级: input → capability metadata → config)
```

**输出** `{kind, template, result, sentence_count, model_used}`;`result` 逐 kind 结构化,
其中 minutes/action_items 每条要点**强制** `refs:[{sentence_idx,t0}]` 溯源引用 —— idx 必须
存在且 t0 与转写句完全一致,违约整体 `llm_output_invalid`(防幻觉红线,eval 金标
`transcript_derive_v1` 12 case 门禁守卫)。幂等缓存 1h(同输入同租户直接命中);
超长转写(> `transcript_derive.max_transcript_chars`,默认 20 万字符)显式拒绝不静默截断。

错误码:`invalid_input / source_unavailable / no_model / prompt_render_failed /
provider_error / llm_failed / llm_output_invalid / port_unavailable`。

## 20 个 Published Capability 速查

完整列表(按 category)— 每个 capability 的 input/output schema 见 `cap_versions.input_schema` / `output_schema`(亦可通过 `GET /v1/capabilities/:code` 获取):

| Category | Capability code | Resource profile | Idempotent | 备注 |
|---|---|---|---|---|
| compliance | `spec_validate` | light | ✓ | App Store 规格校验,查 `gen_store_specs` |
| productivity | `calculator` | light | ✓ | 表达式求值 |
| productivity | `datetime` | light | ✗ | 当前时间(每次不同)|
| utility | `http_request` | network_io | ✗ | 出站 HTTP + SSRF 防御 |
| utility | `zip_pack` | network_io | ✓ | N URL → ZIP → R2 |
| llm | `text_translate` | network_io | ✓ | LLM 多语言翻译 |
| llm | `prompt_enhance` | network_io | ✓ | image-gen prompt 增强 |
| llm | `prompt_assist` | network_io | ✓ | ⭐ **p9_05** 移动端「增强 / 扩写」按钮通用入口;**仅 internal surface**(经 Creation BC `POST /v1/prompt-assist` 调用);Prompt BC `pt_*` 模板分层 + 统一模型梯子(收敛批 2026-08-19:input.model_hint > `prov_capability_defaults` 注入)|
| llm | `brand_safety` | network_io | ✓ | 文本/图像 brand-safety 审查(fail-closed)|
| creative | `image_generate` | network_io | ✗ | LLM 图像生成 |
| image_processing | `magick_resize` | cpu_intensive | ✓ | App Store 标准尺寸 resize |
| image_processing | `magick_trim` | cpu_intensive | ✓ | 修剪空白边框 |
| image_processing | `magick_safe_area_compose` | cpu_intensive | ✓ | safe-area padding |
| image_processing | `magick_batch_crop_from_source` | cpu_intensive | ✓ | 1 主图 → N aspect crop |
| image_processing | `magick_mockup_compose` | cpu_intensive | ✓ | device frame 套壳 |
| image_processing | `smart_crop` | cpu_intensive | ✓ | LLM vision bbox + crop |
| image_processing | `ffmpeg_crop` | cpu_intensive | ✓ | 视频/图片精确裁剪 |
| image_processing | `ffmpeg_compose` | cpu_intensive | ✓ | 多 source overlay 合成 |
| image_processing | `ffmpeg_watermark` | cpu_intensive | ✓ | 水印叠加 |
| image_processing | `format_convert` | cpu_intensive | ✓ | PNG/JPG/WebP/AVIF 互转 |

---

## 客户端集成提示

### Idempotency Key 用法
- `idempotency_key` 是**客户端自生**(UUID v4 或客户端业务 key)
- 同 `(capability_code, version_id, idempotency_key, input_hash)` 命中 cache → 返之前结果(`cache_hit: true`)
- TTL 由 `cap_versions.cache_policy.ttl_seconds` 控制(默认 1 小时)
- **未幂等的 capability**(`datetime` / `image_generate` / `http_request`)cache 不命中,即便 idempotency_key 一致

### Backpressure 503 重试策略
- `error_code = queue_overloaded` → 客户端**不应立即重试**
- `error_message` 含 queue depth + threshold,可用于 backoff 决策
- 推荐:exponential backoff(1s → 2s → 5s → 15s),或换调"更轻"的 capability(同业务用 `light` profile)
- M6 W11 之前 backpressure 不存在 — 这是**新引入的限流**,生产 SLA 调优后阈值可放宽

### 关于 `cost_credits`
- 当前 20 个 capability 中 LLM 类(`text_translate` / `image_generate` / `prompt_enhance` / `prompt_assist` / `brand_safety` / `smart_crop`)有计费(由 `WalletFreeze + WalletConfirm` middleware 经 `wal_credit_pricing_rules` 算)
- 平台底建(`spec_validate` / `calculator` / `datetime` 等)**免费**,`cost_credits = 0`
- 计费规则可通过 `cap_versions.metadata.default_pricing_credits` 预览,真实扣费由 wallet BC 计算

### 大 input / 大 output 处理
- `input` / `output` 当前**全 inline 存 jsonb**(`cap_executions.input_inline` / `output_inline`)
- **超过 8 KB 的 input** 由 capability platform 自动转 `input_payload_url` 落 R2(`cap_executions.input_payload_url`),减少 PG 行宽
- 客户端通过 `GET /v1/capabilities/:code/executions/:bid` 查时,大 payload 字段会返 R2 presigned URL(后续在 mapper 实施)

---

## EchoNote 能力四件(2026-08-26 B3/B4/B7;全部经 `POST /v1/capabilities/:code/invoke` 调用)

四能力均已注册 + `direct_api` surface enabled + 显式 0 价行(改价=改 `wal_credit_pricing_rules` 行零代码)。

### media_link_resolve — 链接解析/摄取(B4/D-4)

```jsonc
// op=resolve(默认): URL → 归一元数据, 不落库
{"input": {"op": "resolve", "url": "https://example.com/feed.xml"}}
// → {"kind":"direct","url","content_type","size_bytes"}          音/视频直链
// → {"kind":"rss","title","episodes":[{title,audio_url,mime_type,duration_sec,pub_date}]}  ≤100 集
// → {"kind":"subtitle","format":"srt|vtt","content":"..."}       字幕内联回传 (≤2MB)
// op=ingest: 音/视频 URL → 平台流式转存 R2 + gen_assets (hash 去重短路)
{"input": {"op": "ingest", "url": "https://cdn.example.com/ep.mp3"}}
// → {"kind":"ingested","asset_bid","dedup_hit","content_type","size_bytes"}
```

失败码(确定性,**不重试**):`unsupported_source`(HTML 页面/HLS·DASH 清单 — DRM 合规拒绝 D-PF-7)
`not_media` · `size_exceeded` · `source_unavailable`(SSRF 拒绝/非 2xx/超时)。
摄取后 duration 由 MediaProbeWorker 异步回填,随后按常规提交转写(D-PF-3 计费权威链不变)。

### subtitle_normalize — 字幕归一(B4/D-5)

```jsonc
{"input": {"content": "<srt/vtt 文本 ≤2MB>", "format": "auto", "language": "en"}}
// → {"result": {schema:"transcript_v1", source:"subtitle", duration_ms, sentences:[{idx,t0,t1,text}]}, "sentence_count"}
```

产物与 ASR 转写**同构**(transcript_v1)——消费面零第二契约。条目级噪声容忍(坏 cue 剔除/标签剥离/乱序重排),结构级损坏显式 `invalid_input`。

### asr_vocabulary — ASR 热词表管理(B3/D-2)

```jsonc
{"input": {"op": "create", "words": [{"text": "转写平台", "weight": 4, "lang": "zh"}]}}   // → {"vocabulary_id","target_model"}
{"input": {"op": "list"}}                                                                  // → {"vocabularies":[{vocabulary_id,gmt_create}]}
{"input": {"op": "delete", "vocabulary_id": "vocab-ga12-xxx"}}
```

平台**零词表存储**:`vocabulary_id` 归调用方持有,随转写提交经既有白名单参数回传。
前缀 app 维服务端唯一决定(跨 app 不可见);单 app 上限 10 表,满则 create 拒绝(先删后建)。
词条约束:weight 1..5;非 ASCII ≤15 字符 / 纯 ASCII ≤7 空格分段。前置:`prov_capability_defaults`
(audio_asr, app) 行 enabled(未配置 → `vocabulary_failed`,fail-close)。

### push_notify — 移动推送(B7/D-3,OQ-4 裁归平台)

```jsonc
{"input": {"platform": "apns", "device_token": "<hex>", "title": "转写完成",
           "body": "《周会录音》已就绪", "data": {"task_bid": "..."}, "dedup_key": "<task_bid>:done"}}
// → {"delivered": true, "duplicate": false}
```

设备 token 由调用方(产品仓)持有逐次传入 — 平台零 token 存储;`dedup_key` 台账去重
(通道② 重投/重试不重复推送)。失败码:`channel_not_configured`(运维未灌该 app 凭证)·
`device_token_invalid`(**调用方应清理该 token**,不重试)· `push_rejected`。

## Future endpoints(留 P5+)

| Endpoint | 用途 | 状态 |
|---|---|---|
| `POST /v1/capabilities/:code/invoke/async` | 真异步 enqueue,返 execution_bid 让客户端轮询 | 当前 `InvokeAsync` API stub,HTTP 未挂 |
| `POST /v1/capabilities/:code/invoke/stream` | SSE 流式输出(LLM 类)| 当前 `InvokeStream` API stub |
| `POST /v1/capabilities/:code/invoke/batch` | 批量调用(共享 cache + freeze)| 当前 `InvokeBatch` API stub |
| `POST /v1/capabilities/executions/:bid/cancel` | 取消运行中的 async execution | 当前 `CancelExecution` API stub |
| `POST /v1/capabilities/register` | 第三方注册自定义 capability(动态扩展)| Lifecycle API 已就位,HTTP 未挂(等 marketplace 后台需求触发)|
| `POST /v1/capabilities/:code/versions/:semver/publish` | publish 流转 | 同上 |

---

## 参考

- 设计文档:`docs/architecture/capability-platform-overview.md`(待新增,M6 W12 留)
- 12-step middleware chain:`internal/capability/app/invoke/invoker.go::NewInvoker`
- 5 个 resource profile + backpressure threshold seed:`docs/migrations/p7_01_capability_platform_schema.sql`(Phase 5 INSERT cap_resource_profiles)
- 20 个 builtin seed:`docs/migrations/p7_05` ~ `p7_09` 19 个(按 M5/M6 交付阶段拆分)+ `p9_05_prompt_assist_capability.sql`(p9_05 移动端「增强 / 扩写」按钮,内部 surface 唯一)
- 数据库表:`cap_capabilities` / `cap_versions` / `cap_executions` / `cap_invocation_surfaces` / `cap_quotas` / `cap_cache_entries` / `cap_resource_profiles` / `cap_audit_logs` / `cap_circuit_states` / `cap_dependencies` / `cap_dlq`
