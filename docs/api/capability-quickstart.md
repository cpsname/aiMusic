# Capability Platform 快速对接指南

> 给**第一次对接** capability platform 的客户端开发者 / 运维 / 集成方。
>
> **完整契约**:[`capability.md`](capability.md);**全量端点索引**:[`endpoint-inventory.md`](endpoint-inventory.md);**通用机制**(BaseURL / 鉴权 / App 签名):[`overview.md`](overview.md)。

---

## 5 分钟看懂

Capability Platform 是把"能力调用"统一收敛到一个入口的平台,客户端只需要 `POST /v1/capabilities/:code/invoke`,平台自动:

1. **解析**:`code` + `version_constraint` → 选具体 cap_versions row
2. **权限**:IAM 检查调用权
3. **配额**:扣 daily / monthly quota(原子 CTE,并发安全)
4. **缓存**:idempotent capability + 同输入 → 命中 cache 直接返(<10ms)
5. **钱包冻结**:按 pricing rule 估算 + 冻结积分
6. **输入校验**:JSON Schema(input_schema)+ SafetyPre(brand 拦截)
7. **调度**:按 resource_profile 检 backpressure(超阈值返 503)
8. **执行**:调真实 executor(builtin / PostProcess / LLM)
9. **输出校验**:JSON Schema(output_schema)+ SafetyPost(凭证 redact)
10. **钱包确认**:成功 confirm 真扣 / 失败 refund
11. **流水**:写 `cap_executions`,可后续查 `GET /executions/:bid`

整条链路单次调用 ~5-15ms 框架开销 + capability 自身耗时。失败任何一步都返结构化 ErrorCode,客户端无需理解内部细节。

---

## 步骤 1:拿到访问凭证

Capability Platform 端点要求:
1. **App 签名**(全局 `/v1/*`)— 见 [`overview.md` §5 App 签名](overview.md#5-app-签名机制)
2. **JWT**(`Authorization: Bearer <token>`)— 见 [`overview.md` §4 JWT](overview.md#4-jwt-鉴权机制)
3. **admin 角色**(JWT claims 中 `account_role` ∈ `{admin, super_admin}`)

**为什么要 admin?**
- Capability 调用直接消费积分 + 触发外部 IO(LLM / R2 / shell exec)
- 流水含 input/output 内容,可能是商业机密
- 普通用户应该走 surface adapter(LLM tool / Workflow node 内部直调 `capability.Invoke`),不应通过 HTTP

如果你是后端服务集成,建议申请 **super_admin** 服务账号 + 长期 JWT(运维出 token,不轮换)。

---

## 步骤 2:第一次调用(Calculator)

最简单的 capability 是 `calculator`(纯算术,免费,light profile,~5ms)。

### Request
```bash
POST https://api.example.com/v1/capabilities/calculator/invoke
Authorization: Bearer eyJhbGc...
X-Distribution-Code: web
X-App-Signature: <hmac-sha256>
X-Timestamp: 1730000000
X-Nonce: 0192e5fc-1234-5678-9abc-def012345678
Content-Type: application/json

{
  "input": {
    "expression": "(1+2) * (3+4)"
  }
}
```

### Response(成功,200)
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "execution_bid": "0192e5fc-1234-5678-9abc-def012345678",
    "status": "succeeded",
    "output": {
      "result": 21,
      "expression": "(1+2) * (3+4)"
    },
    "cache_hit": false,
    "duration_ms": 3,
    "cost_credits": 0,
    "error_code": "",
    "error_message": "",
    "correlation_id": "..."
  },
  "request_id": "...",
  "timestamp": 1730000000
}
```

**记下 `execution_bid`** — 后续可通过 `GET /v1/capabilities/calculator/executions/:bid` 查任何历史调用。

---

## 步骤 3:典型业务路径

### 3.1 App Store 五图工作流(组合 5 个 capability)

一个完整的 App Store 截图发布流程,串 5 次 invoke:

```
用户上传主图
    ↓
[1] spec_validate    校验主图是否符合 ios screenshot 规格
    ↓ passed=true
[2] prompt_enhance   原始描述 → 工程化 image-gen prompt
    ↓ enhanced_prompt
[3] image_generate   生成 1320×2868 png(iPhone 6.9 portrait)
    ↓ image_url
[4] brand_safety     检查图片有无 Apple logo / 真人脸 / 商标
    ↓ passed=true
[5] zip_pack         打包 5 张图 → ZIP → 给客户端下载链接
```

每一步:
```bash
POST /v1/capabilities/{code}/invoke
{ "input": {...} }
```

**幂等优化**:同一组输入 + 同 `idempotency_key` 第二次调用直接命中 cache(`cache_hit: true`,duration_ms ~2),节省积分 + 时间。

### 3.2 LLM 调用(prompt_enhance)

```bash
POST /v1/capabilities/prompt_enhance/invoke
{
  "input": {
    "user_prompt": "一张很酷的笔记 App 截图",
    "asset_kind": "screenshot",
    "store_code": "ios",
    "style_hints": "minimalist pastel",
    "language": "zh",
    "model_hint": "<gemini-2.5-flash model_version_bid>"
  },
  "idempotency_key": "ios-shot-001"
}
```

返:
```json
{
  "code": 0,
  "data": {
    "execution_bid": "...",
    "status": "succeeded",
    "output": {
      "enhanced_prompt": "minimalist note-taking app screenshot, soft pastel gradient...",
      "negative_prompt": "no faces, no real people, no copyrighted logos",
      "system_constraints": ["safe_area_16px", "single_focal_point"],
      "language": "zh",
      "model_used": "<gemini-2.5-flash model_version_bid>"
    },
    "cost_credits": 1,
    "duration_ms": 1432
  }
}
```

**注意 `model_hint`**:LLM 类 capability 的 `model_hint = <model_version_bid>`(从 `provider/v1/models` 端点查)是**单次覆写**(A/B 实验/灰度)。运营在 `prov_capability_defaults` 配了该 capability 的默认行后,客户端可省略。

> **收敛批 2026-08-19 起,全部 7 个 LLM capability(prompt_assist / prompt_enhance / intent_classify / transcript_derive / brand_safety / smart_crop / analysis_derive)统一模型解析梯子**:`input.model_hint > prov_capability_defaults((capability, app_id) → (capability, 0) 回落,invoke 链注入)`。运营经独立 Admin 后台(`ProviderAPI.UpsertCapabilityDefault`,写时即校验)或 DML 插行即生效(读侧 30s 缓存),**零发版**;app 覆写行让不同产品各用各的默认模型。cap metadata 的 `default_model_version_bid` 兼容读已删除(残值被完全忽略)。梯子实现单点在 `ExecutionRequest.ResolveModelVersionBID`(`internal/capability/domain/service/executor.go`)。

### 3.3 Backpressure 503(M6 W11)

当 queue 堆积超阈值时返:

```bash
HTTP 503
{
  "code": 50385,
  "message": "queue cap:cpu depth 600 ≥ threshold 500 (resource_profile=cpu_intensive) — retry later or use lighter capability",
  "data": null
}
```

客户端处理:
1. **不要立即重试**(并发风暴会加剧堆积)
2. **指数退避**:1s → 2s → 5s → 15s
3. **降级方案**:换"更轻"的 capability 或本地处理(若可行)
4. **监控告警**:50385 频次升高 = 平台容量告急,运营应增加 worker

---

## 步骤 4:查历史流水

### 列最近的失败流水
```bash
GET /v1/capabilities/spec_validate/executions?status=failed&page_size=50
```

### 单条详情
```bash
GET /v1/capabilities/spec_validate/executions/0192e5fc-1234-5678-9abc-def012345678
```

返 input/output/error_code/error_message 完整流水,**用于客户端排障 + audit**。

---

## 步骤 5:列出全部可用 capability

```bash
GET /v1/capabilities?status=published
```

返完整列表(当前 20 个 published)。客户端可据此在 UI 显示 capability marketplace。**不要把这个端点暴露给终端用户** — 平台 capability 不是面向 C 端的功能列表,只给运维 / 开发者看。

> ⚠️ **`prompt_assist`(p9_05)从此 HTTP 端点不可见**(`cap_invocation_surfaces.surface_kind` 仅 `internal`,不开 `direct_api`)。移动端走 Creation BC `POST /v1/prompt-assist`,经服务端 `capability.Invoke(SurfaceKind=internal)` 绕过 admin gate。

---

## 错误处理速查

| 看到这个 code | 含义 | 客户端如何处理 |
|---|---|---|
| `code: 0` | 成功 | 用 `data` 即可 |
| `40030` | input 不合法 / payload 错 | 修 input,见 `error_message` 的 schema 校验细节 |
| `40110` | JWT 失效 / 缺 | 重新登录 / 刷新 token |
| `40300` | 不是 admin | 检查账号角色,普通用户应走 surface adapter |
| `40402` | capability_code 不存在 / 已 retired | `GET /v1/capabilities` 查可用列表 |
| `40330` | safety_blocked | input 含违规内容,见 `error_message.safety_violations` |
| `42930` | quota_exceeded | 等下个计费周期(daily/monthly)|
| `50083` | executor 内部错 | 客户端无能为力,看 `error_message` 报告平台 |
| **`50385`** | **queue 过载 503** | **指数退避重试**;频繁触发应告警平台扩容 |
| `50410` | timeout | input 太大 / 模型延迟过高,试 `timeout_ms` 调高 |

---

## SDK 友好对接清单

如果你在写 SDK / wrapper 库,推荐封装:

1. **App 签名** + **JWT** 自动注入(每次调用 transparent)
2. **idempotency_key** 自动生成(UUID v4 per call,缓存 result map 客户端复用)
3. **重试策略**:
   - `50385`(queue_overloaded)→ 指数退避(1s/2s/5s/15s,最多 4 次)
   - `50410`(timeout)→ 重试 1 次 + 翻倍 timeout
   - `5xxxx`(其他)→ 不重试,报错给上层
4. **超时保护**:每次 `POST invoke` 客户端侧设 30s 超时(防 socket 泄漏)
5. **batch 优化**(留 P5):单 batch 内多 capability 串调时,共享 `correlation_id`,可在流水查询时一次拉一组

---

## 常见问题

### Q: 为什么 LLM capability 需要客户端传 model_hint?
只有当运营还没在 `prov_capability_defaults` 给该 capability 配默认行时才需要。配行后(model-only 平台行即可;app 覆写行支持按产品定制)客户端可省略 `model_hint`,它退化为单次覆写(A/B/灰度)。

### Q: cache 命中怎么计费?
**不计费**。`cache_hit: true` → wallet 不冻结也不扣。这是 capability platform 的核心激励 — 鼓励客户端用 idempotent_key 重复调用同 input。

### Q: 同一个 capability 的不同版本能并存吗?
能。`cap_versions` 表支持多版本(SemVer)+ `canary_percent` 灰度。客户端通过 `version_constraint: "^1.2"` 锁版本,不传 = 当前 published。详见 `capability.md` § 3 的 `versions` 字段。

### Q: 怎么注册一个新 capability?
当前**只有平台运营**通过 SQL migration(`docs/migrations/p7_*.sql`)注册。客户端动态注册的 HTTP 端点(`POST /v1/capabilities/register`)留 P5+(等 marketplace 后台需求触发)。

### Q: 20 个 capability 是固定的吗?
不是。`gen_store_specs`(P7-04 seed)已落 30 行 ios + google_play 规格;5 个 PostProcessor + 9 个 App Store 工具 + 5 个 utility + 1 mobile-first(`prompt_assist`) 通过 SQL migration seed,全部可扩。新加 capability 只需 ① 实现 `service.CapabilityExecutor` ② 注册到 `fx.Group("capability.executors")` ③ SQL migration seed `cap_capabilities/cap_versions/cap_invocation_surfaces` 三步即可上线。**p9_05 `prompt_assist` 是首个 `surface_kind` 仅 `internal` 的样板** — 移动端 surface 不暴露 admin direct_api,经业务 BC handler 转发(参照 `internal/creation/port/http/prompt_assist_handler.go`)。

### Q: 怎么调用 capability 不通过 HTTP(性能优化)?
内部 BC(LLM tool / Workflow node)直接 `import "genaistudio/internal/capability"` + `capability.CapabilityAPI.Invoke(ctx, &InvokeCommand{...})`,**零 HTTP 框架开销**。HTTP 端点主要给外部集成用。

---

## 参考链接

- 完整 API 契约:[`capability.md`](capability.md)
- 全量端点索引:[`endpoint-inventory.md`](endpoint-inventory.md#capability-platform-bc5-endpointsp7--m6-w12-完整)
- 通用 BaseURL / 鉴权 / 签名:[`overview.md`](overview.md)
- 20 个 capability builtin 速查:[`capability.md` § 20 个 Published Capability 速查](capability.md#20-个-published-capability-速查)
