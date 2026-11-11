# Web -- Provider Domain API

> **Base URL**: `{server}/v1`
> **Content-Type**: `application/json`
> **Last updated**: 2026-05-22

---

## Table of Contents

1. [GET /v1/models -- Model Catalog](#1-get-v1models)
2. [Response Schema Reference](#2-response-schema-reference)
3. [ParamSchema Deep Dive](#3-paramschema-deep-dive)
   - 3.0 [i18n 约定(param_schema 全量双语)](#30-i18n-约定param_schema-全量双语)
   - 3.4 [Condition (Field Dependency) System](#34-condition-field-dependency-system)
   - 3.5 [Asset URL 拼接(R2 / CDN base 注入)](#35-asset-url-拼接r2--cdn-base-注入)
   - 3.10 [Thinking Level(Nano Banana 图片模型专项)](#310-thinking-levelnano-banana-图片模型专项thinking_level)
   - 3.11 [音乐生成(`task_type=txt2audio`)](#311-音乐生成task_typetxt2audio2026-08-26)
   - 3.12 [语音转写(`task_type=stt`)](#312-语音转写task_typestt2026-08-27)
4. [Complete param_schema Example](#4-complete-param_schema-example)
   - 4.1 [qwen-image-2.0-pro (Alibaba DashScope)](#qwen-image-20-pro-alibaba-dashscope)
   - 4.2 [wanx-style-repaint-v1 (image_selector + x-enum-previews)](#42-wanx-style-repaint-v1image_selector--x-enum-previews-实例)
   - 4.3 [seedance-2.0 / -fast (输入决定形态)](#43-seedance-20--seedance-20-fastvolcengine--输入决定形态p5-28)
   - 4.4 [token 计费模型的 credit_cost 与 pricing](#44-token-计费模型的-credit_cost-与-pricing以-gemini-31-flash-lite-为例)
5. [Ant Design Pro Dynamic Form Rendering](#5-ant-design-pro-dynamic-form-rendering)
   - 5.5 [File Upload Integration (presigned PUT)](#55-file-upload-integration-presigned-put) — ParamSchemaForm 文件参数接入 `/v1/uploads/sign`

---

## 1. GET /v1/models

**Model Catalog** -- Returns all available AI models with their versions, parameter schemas, presets, and pricing information. The response is designed to be consumed directly by a dynamic form renderer.

| Property | Value |
|----------|-------|
| Auth | JWT Required |
| Cache | HTTP-layer cacheable (CQRS query side, pure read-only) |
| Query Pattern | 3-batch query (models + versions + presets), no N+1 |

### Query Parameters

| Param | Type | Required | Default | Values | Description |
|-------|------|----------|---------|--------|-------------|
| `media_type` | string | No | (all) | `image`, `video`, `audio`, `text`, `multimodal`, `code` | Filter by media type |
| `task_type` | string | No | (all) | `txt2img`, `img2img`, `txt2video`, `img2video`, `chat`, etc. | Filter by task type |
| `status` | string | No | `online` | `online`, `offline`, `deprecated` | Filter by model status |

### Request Example

```
GET /v1/models?media_type=image&task_type=txt2img
Authorization: Bearer eyJ...
```

### Response -- `data` payload

> ⚠ 下例为**应用层全量 DTO**。公开 HTTP 响应经 `port/http/model_dto.go` 白名单裁剪
> (26817473):`provider_code` 与 `versions[].pricing` **不下发客户端**(上游供应商
> 映射/成本结构,内部与独立管理后台专用)。真实公开响应抓包见
> `docs/api/samples/get_v1_models_{image,video}_20260824.json`(本地 dev 实抓)。

```jsonc
{
  "models": [
    {
      "model_bid": "uuid",
      "provider_code": "dashscope",   // ⚠ 内部字段, 公开响应已裁剪
      "model_code": "qwen-image-2.0-pro",
      "model_name": { "en": "Qwen-Image 2.0 Pro", "zh": "通义千问图像 2.0 Pro" },
      "logo_url": "",
      "showcase_url": "",
      "description": { "en": "[Qwen-Image 2.0 Pro · ...]\n▸ What it does: ...", "zh": "【Qwen-Image 2.0 Pro · 基础主力款图像生成】\n▸ 能做什么: ..." },
      "media_type": "image",
      "task_type": "txt2img",
      "capability_tags": ["高清", "多图"],
      "supported_features": [],
      "display_tags": ["hot"],   // 运营标签, 词表 hot/new/best_value/limited; 空数组时字段省略
      "sort_order": 10,
      "versions": [
        {
          "version_bid": "uuid  <-- THIS IS WHAT YOU PASS TO POST /v1/tasks",
          "version_code": "v1",
          "version_name": "Qwen Image 2.0 Pro v1",
          "capability_label": "",
          "release_note": "...",
          "param_schema": { /* JSON Schema draft-07 + x-extensions -- see Section 3 */ },
          "output_schema": null,
          "is_async": false,
          "estimate_ms": 8000,
          "async_strategy": null,
          "credit_cost": {
            "amount": 60,
            "unit": "per_request"
          },
          "pricing": {              // ⚠ 内部字段, 公开响应已裁剪
            "schema_version": 2,
            "currency": "CNY",
            "source": "https://help.aliyun.com/zh/model-studio/model-pricing 2026-05-29",
            "metering": { "unit": "image" },
            "rate_kind": "scalar",
            "dimensions": [],
            "rates": [ { "at": {}, "amount": 0.50 } ],
            "free_quota": { "unit": "image", "scope": "new_user_cn", "amount": 100, "validity_days": 90 }
          },
          "presets": [
            {
              "preset_bid": "uuid",
              "preset_code": "cinematic",
              "preset_name": "Cinematic",
              "preset_name_zh": "电影感",
              "description": "",
              "preview_url": "https://cdn.example.com/presets/cinematic.jpg",
              "param_values": { "size": "1664*928", "negative_prompt": "blurry, low quality" },
              "is_default": false
            }
          ],
          "status": "published"
        }
      ]
    }
  ],
  "total": 15
}
```

---

## 2. Response Schema Reference

### ModelDTO

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `model_bid` | string (UUID) | No | Model external identifier |
| `provider_code` | string | No | Provider identifier: `dashscope`, `google`, `runway`, `volcengine`。**内部字段** — 公开 HTTP 响应已裁剪(26817473),仅内部/管理后台 DTO 可见 |
| `model_code` | string | No | Model code: `qwen-image-2.0-pro`, `gemini-3-flash-preview`, `veo-3.1-generate-001`, etc. |
| `model_name` | object `{en,zh}` | No | i18n 名称对象,例 `{"en":"Gen-4 Turbo","zh":"Gen-4 Turbo 快速视频"}`(原 `model_name` + `model_name_zh` 双列已合并)|
| `logo_url` | string | Yes | Model logo URL |
| `showcase_url` | string | Yes | Showcase/demo URL |
| `description` | object `{en,zh}` | Yes | i18n 描述对象;为营销文案,**不含具体供应商价格** |
| `media_type` | string | No | `image`, `video`, `audio`, `text`, `multimodal`, `code` |
| `task_type` | string | No | `txt2img`, `img2img`, `txt2video`, `img2video`, `chat`, etc. |
| `capability_tags` | string[] | Yes | Capability tags, e.g. `["高清", "有声"]` |
| `supported_features` | string[] | Yes | Supported feature flags |
| `display_tags` | string[] | Yes | 运营标签,词表固定 4 值(`prov_models.display_tags` 列注释即权威):`hot`(品类内近 30 天用量断层第一)· `new`(新接入批次)· `best_value`(品类内 default 档积分单价最低)· `limited`(限时/限量运营活动,暂未启用)。**空数组时整个字段省略**(omitempty),客户端按缺失=无标签渲染。判据与回填依据(用量/单价实测)见 `docs/migrations/20260824a_prov_models_display_tags_backfill.sql` |
| `sort_order` | int | No | 排序权重(`prov_models.sort_order`,Repository 按 `sort_order ASC, id ASC` 排序,2026-08-24 起同值行由 id 二级键钉死不再漂移;数值越小越靠前,默认 0) |
| `versions` | VersionDTO[] | No | Published model versions,**按 `published_at DESC, id DESC` 排序**(2026-07-10 审计 C5 定契约):`versions[0]` 即客户端默认版本,最新发布优先 |

### VersionDTO

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `version_bid` | string (UUID) | No | **The ID you pass to `POST /v1/tasks`** |
| `version_code` | string | No | Version code, e.g. `v1` |
| `version_name` | string | No | Version display name |
| `capability_label` | string | Yes | Capability entry label, e.g. "文生视频" / "图生视频" |
| `release_note` | string | Yes | Release notes |
| `param_schema` | object | No | JSON Schema (draft-07) + x-extensions for dynamic form rendering |
| `output_schema` | object | Yes | 产物形态描述(自由结构,多数模型为 `null`)。音乐模型自 2026-08-26 起有值,见 §3.11 |
| `is_async` | bool | No | `true` if this version uses async generation (polling) |
| `estimate_ms` | int | No | Estimated end-to-end p95 latency (idle queue), in ms. **Always > 0 for any published version** — async models use `async_strategy.max_wait_ms / 2`, sync models use `platform_params.p95_latency_ms`, with `media_type` fallback (text=3000, image=8000, video=60000, audio=10000, default=5000). 客户端可用此值预估等待文案 / 乐观进度条目标 / client-side timeout 上限;真实轮询节奏请用 `POST /v1/tasks` 响应里同名字段(含实时 queue depth 更精准)。P6-02 决策:消除 sync/async 差异,平台侧不让 client 感知模型上游执行类型。|
| `async_strategy` | AsyncStrategyDTO | Yes | Polling configuration (null for sync models) |
| `credit_cost` | CreditCostDTO | Yes | 平台积分计费(来源 `wal_credit_pricing_rules`,**非 pricing**;免费时 null)|
| `pricing` | PricingInfo (schema v2) | Yes | 上游供应商计费,强类型正交结构(见下文 §Upstream Pricing Schema v2)。**内部字段** — 公开 HTTP 响应已裁剪(26817473),严禁下发移动端 |
| `presets` | PresetDTO[] | No | Parameter presets |
| `status` | string | No | `published` |

### AsyncStrategyDTO

| Field | Type | Description |
|-------|------|-------------|
| `mode` | string | `"polling"`, `"webhook"`, or `"sse"` |
| `interval_ms` | int | Recommended polling interval in milliseconds |
| `max_wait_ms` | int | Maximum wait time in milliseconds |

### Upstream Pricing Schema v2(`VersionDTO.pricing` 强类型结构)

`VersionDTO.pricing` 来自 DB `prov_model_versions.pricing`,是**上游供应商真实计费信息**(USD/CNY,与平台积分计费完全独立)。

**schema v2 = 正交分解**(取代旧的 9 个扁平 variant 笛卡尔积;设计与审计:`docs/architecture/provider/pricing-schema-v2.md`,Go 强类型:`internal/provider/domain/pricing.go::PricingInfo`)。四条正交轴:

| 轴 | 字段 | 含义 |
|---|---|---|
| **计费什么** | `metering.unit` | `image` / `video_second` / `token_1m` / `request` / `megapixel` |
| **价格叶子形态** | `rate_kind` | `scalar`(单一 `amount`)或 `token`(按模态 `input/output/cache_read`)|
| **是否/如何分档** | `dimensions[]` | 有序维度数组(如 `image_size` / `video_resolution` / `service_tier` / `input_mode`);扁平模型为空 `[]` |
| **正交修饰** | `free_quota` / `grounding` / `routing` / `verification` / `metering.scope` | 与上面三轴正交,按需出现 |

价格本体在 `rates[]`:每个 cell 的 `at` 是各维度坐标(扁平时 `{}`),叶子按 `rate_kind` 填 `amount`(scalar)或 `input/output/cache_read/cache_storage_per_1m_token_hour`(token)。

**顶层公共字段**:`schema_version`(恒 `2`)· `currency`(`USD`/`CNY`)· `source`(`"<url> YYYY-MM-DD"` 查证戳)。

#### 形态 1 — scalar 扁平(无分档)

```jsonc
{
  "schema_version": 2,
  "currency": "USD",
  "source": "https://ai.google.dev/gemini-api/docs/pricing 2026-05-29",
  "metering": { "unit": "image" },
  "rate_kind": "scalar",
  "dimensions": [],
  "rates": [ { "at": {}, "amount": 0.040 } ]
}
```
适用:`imagen-4.0-*` / `seedream-4.5/5.0` / `gen4_image_turbo` / `gen4_turbo`。

#### 形态 2 — scalar 分档(1+ 维)

```jsonc
{
  "schema_version": 2, "currency": "USD",
  "source": "https://ai.google.dev/gemini-api/docs/pricing 2026-05-29",
  "metering": { "unit": "image" },
  "rate_kind": "scalar",
  "dimensions": [ { "name": "image_size", "default": "1K" } ],
  "rates": [
    { "at": { "image_size": "0.5K" }, "amount": 0.045 },
    { "at": { "image_size": "1K"   }, "amount": 0.067 },
    { "at": { "image_size": "2K"   }, "amount": 0.101 },
    { "at": { "image_size": "4K"   }, "amount": 0.151 }
  ],
  "grounding": { "google_search": { "billing_unit": "search_query", "free_queries_per_month": 5000, "overage_per_1000_queries": 14.00 } }
}
```
适用:`gemini-3.1-flash-image-preview` / `gemini-3-pro-image-preview` / `veo-3.1-{generate,fast,lite}-*` / `wan2.7-{video,i2v,r2v}`(后者带 `routing` + `metering.scope`)。**多维示例** `seedance-2.0`:`dimensions=[resolution, input_mode]`,6 个 cell 各带二维 `at`,`metering.unit=token_1m`(单价即每百万 token,仍是 `scalar`)+ `metering.quantity_formula`。

#### 形态 3 — token(按模态拆分)

```jsonc
{
  "schema_version": 2, "currency": "USD",
  "source": "https://ai.google.dev/gemini-api/docs/pricing 2026-05-29",
  "metering": { "unit": "token_1m", "audio_token_density": "25 tokens/sec" },  // density 仅 TTS
  "rate_kind": "token",
  "dimensions": [ { "name": "service_tier", "default": "standard" } ],
  "rates": [
    { "at": { "service_tier": "standard" },
      "input":  { "text": 0.250, "audio": 0.500, "image": 0.250, "video": 0.250 },
      "output": { "text": 1.500 },                       // 纯文本输出也统一为模态 map
      "cache_read": { "text": 0.02500, "audio": 0.05000 },
      "cache_storage_per_1m_token_hour": 1.00 }
  ]
}
```
适用:`gemini-3.1-flash-lite`(4 服务档 + `google_search`/`google_maps` grounding)· `gemini-3.1-flash-tts-preview`(`input.text` + `output.audio`)。

#### 修饰字段

| 字段 | 形态 | 说明 |
|---|---|---|
| `verification` | `{verified:bool, note?}` | `verified:false` = 估算价(官方无公开 SKU,如 `veo-3.1-upscale`);`note` 也用于承载 SKU 映射等审计说明 |
| `free_quota` | `{unit, scope, amount, validity_days?}` | 新用户/渠道免费额度(DashScope 系) |
| `routing` | `{role?, group?, entry_model_code?}` | 多版本路由族(wan2.7 家族:`role=t2v/i2v/r2v`,同 `group` 同价,`entry_model_code` 为用户入口) |
| `metering.scope` | string | 计费口径,如 `output_video_seconds` / `input_and_output_video_seconds` |

#### 前端解析约定(单一真相,无兼容路径)

1. 先读 `metering.unit` + `rate_kind` → 知道 cell 叶子是 `amount` 还是 `input/output` 模态 map。
2. **默认展示价** = 取「各维度 `default` 组成的坐标」命中的 cell:scalar → `amount`;token → 代表性 `input.text`(无则任一 `input` 模态)。等价于 Go `PricingInfo.DefaultDisplayPrice()`。
3. 用户切换某维度参数(如 `image_size`/`video_resolution`/`service_tier`)→ 用「该维度选值 + 其余维度 default」组成坐标,在 `rates[]` 里找 `at` 全等的 cell。未命中(如上游不支持的档)→ 禁用该选项。
4. **不要**自己解析 token 多模态求和;成本计算是后端 `SupplierCostCalculator` 职责,前端只做展示价。

> **红线**:`pricing` 内**不含任何平台积分字段**(旧 `credit_usd_rate` / `credit_cost_per_*` 已彻底移除)。平台积分计费(用户实际扣的 credits)唯一权威 = `wal_credit_pricing_rules`,经 `VersionDTO.credit_cost`(下文)单独表达。二者正交:`pricing` = 上游成本基线(对账/毛利),`credit_cost` = 对客定价。

### CreditCostDTO

`credit_cost` 字段是**平台积分计费**(用户实际看到 / 扣的 credits 数),与上游 `pricing` 价格完全分离。**来源**:`list_models_handler` 经 provider 的 `PricingRuleRepository.FindRule(model_code, task_type, "default")`(桥接 `WalletAPI.FindPricingRule`,4 级回退 exact→tier=default→task_type='*'→无)查 `wal_credit_pricing_rules` 得到;`amount<=0` 时 `credit_cost` 返回 null。

| Field | Type | Description |
|-------|------|-------------|
| `amount` | int64 | Credits consumed per unit |
| `unit` | string | `"per_request"`, `"per_1k_tokens"`, `"per_second"`, `"per_megapixel"` |
| `example_breakdown` | string | (Optional / 预留) 计费示例文案。当前 `FindRule` 仅返回 amount+unit,**暂不自动产出**(为空);未来由积分定价规则携带示例文本时填充。字段缺失时前端仅显示 amount + unit pill。|

### PresetDTO

| Field | Type | Description |
|-------|------|-------------|
| `preset_bid` | string (UUID) | Preset identifier |
| `preset_code` | string | Preset code, e.g. `cinematic` |
| `preset_name` | string | English name |
| `preset_name_zh` | string | Chinese name (may be empty) |
| `description` | string | Preset description |
| `preview_url` | string | Preview image URL |
| `param_values` | object | Parameter values to apply when preset is selected |
| `is_default` | bool | Whether this preset is applied by default |

---

## 3. ParamSchema Deep Dive

The `param_schema` field in each version is returned as **JSON Schema draft-07** with custom `x-` extensions for rich UI rendering. The server converts the internal `ParamSchema` format to JSON Schema via `ToJSONSchema()`.

### 3.0 i18n 约定(param_schema 全量双语)

本平台面向全球用户。**`param_schema` 内所有面向用户的文本节点一律为 `{en, zh}` 双语对象,两种语言均保证非空** —— 该不变量由 migration `provider_i18n_3_param_schema_backfill.sql` 全量回填历史数据建立,新模型注册时 seed 必须同样双语。

| 文本节点 | 内部格式(DB JSONB)| API 输出(JSON Schema) |
|---|---|---|
| 参数标签 | `parameters[].label` | `properties.{key}.title`(取 `en`)+ `x-label`(完整 `{en,zh}`)|
| 参数描述 | `parameters[].description` | `properties.{key}.description`(取 `en`)+ `x-description`(完整 `{en,zh}`)|
| 占位符 | `parameters[].placeholder` | `x-placeholder`(完整 `{en,zh}`)|
| 辅助文字 | `parameters[].hint` | `x-hint`(完整 `{en,zh}`)|
| 枚举项标签 | `parameters[].options[].label` | `x-enum-labels`(`{value: {en,zh}}`)|
| 分组标签 / 说明 | `groups[].label` / `groups[].description` | `x-groups[].label` / `.description`(完整 `{en,zh}`)|

- **标准 JSON Schema 字段**(`title` / `description`)只承载 `en` 字符串(draft-07 无 i18n 概念,遵循国际惯例);
- **`x-` 扩展字段**承载完整 `{en, zh}` map —— 前端按 `当前 locale → en → zh` 顺序 fallback 取值;
- 回填后 `en`/`zh` 双非空是平台不变量,前端无需写"某语言缺失"兜底分支。

> §3 / §4 / §6 下方个别示例为排版简洁可能仅示 `zh`,**实际响应必为 `{en, zh}` 双语**;§3.1(内部结构)、§4.1(完整输出)已按 docker.pg18 真实数据补全为双语基准。

### 3.1 Internal ParamSchema Structure (source of truth)

The server stores parameters in this structure (JSONB in `prov_model_versions.param_schema`):

```jsonc
{
  "version": "1.0",
  "groups": [
    { "key": "basic",    "label": {"en": "Basic",    "zh": "基础设置"}, "sort": 1, "description": {"en": "Common parameters used by all users", "zh": "面向所有用户的常用参数"} },
    { "key": "advanced", "label": {"en": "Advanced", "zh": "高级设置"}, "sort": 2 }
  ],
  "parameters": [
    {
      "key": "prompt",
      "type": "string",           // string | integer | float | enum | boolean | file | media_array | file_array | array
      "required": true,
      "label": {"en": "Prompt", "zh": "提示词"},
      "placeholder": {"en": "Describe the image you want to generate...", "zh": "描述你想生成的画面..."},
      "description": {"en": "Supports English and Chinese", "zh": "支持中英文"},
      "hint": {"en": "50–200 characters recommended", "zh": "建议 50-200 字"},   // 字段下方的灰色辅助文字
      "ui_component": "textarea", // textarea | select | radio_group | switch | number_input | slider | image_upload | multi_image_upload | image_selector | media_array | speakers_editor
      "default": null,
      "options": [],              // for enum type only
      "min": null,                // for integer/float
      "max": null,
      "step": null,
      "max_length": 2000,         // for string
      "max_items": null,          // for array/media_array/file_array  ← snake_case (历史 camelCase maxItems 后端兼容)
      "min_items": null,
      "item_schema": null,        // for array: 元素 sub-schema (如 speakers 编辑器每行结构)
      "options_ref": "",          // 跨字段引用同 schema 的 enum 列表 (B5 voice_name 复用)
      "items": null,              // 通用 JSON Schema items 透传 (file_array / 嵌套对象)
      "accept": [],               // for file/file_array: MIME types ["image/jpeg", "image/png"]
      "max_size_mb": null,        // for file: max upload size
      "api_field_name": "",       // 上游真实字段名 (与 request_mapping 联动, 历史)
      "group": "basic",
      "sort_order": 1,
      "conditions": [             // field dependency/visibility rules (AND 语义, 多条件全部满足)
        { "when": "mode", "eq": "img2img", "action": "show" },
        { "when": "ref_image", "is_empty": false, "action": "show" }
      ],
      "visible_when": null        // 简写: {key: val} → 后端转换层翻为 x-conditions show
    }
  ],
  "constraints": [                // (2026-08-25) 跨字段**提交期**约束 — 可选, 未声明即无约束
    {
      "key": "reference_to_video_resolution_cap",
      "label": {"en": "Reference-to-video is capped at 720p on this model.", "zh": "本模型的参考图生视频最高 720p。"},
      "when": [                   // AND 语义: 全部子句成立才触发
        { "field": "media", "has_role": "reference_image" }
      ],
      "then": { "field": "resolution", "allow_values": ["480p", "720p"] }
    }
  ]
}
```

**`constraints[]` 与 `conditions[]` 的分工(别混用)**:

| | `parameters[].conditions` / `visible_when` | `constraints[]` |
|---|---|---|
| 层级 | 字段级 | schema 级(跨字段) |
| 语义 | **渲染**(show / hide / require / disable) | **提交期强制** |
| 执行方 | 客户端。服务端只编译成 `x-conditions` 透传,**从不据此校验** | 服务端 `ValidateParams` 硬拒(40033),客户端另据 `x-constraints` 提前置灰 |
| 违反后果 | 无(纯 UI) | 请求在**冻结积分之前**被拒 |

`when` 子句三算子**互斥**,每条恰好声明一个:

| 算子 | 含义 |
|---|---|
| `has_role` | `field`(必须是 `media_array`)中存在至少一个 `role` == 该值的元素。**裸 URL 字符串元素不计** —— 它们没有 role,adapter 也不会把它们当作对应角色的素材发出 |
| `eq` | `field` 的值等于该字面量(数字跨 int/float 表示归一) |
| `is_empty` | `field` 是否为空(缺席 / null / 空串 / 空数组 / 空对象) |

`then` 目前只支持 enum 值域收窄(`allow_values` 白名单)。**没有 `deny_values`** —— 黑名单在上游新增枚举值时静默放行,白名单则挡住新值由运营发现,fail-close。

后端启动期校验(`ValidateShape` 不变量 16)强制:`key` 唯一 + `{en,zh}` 双语 label + `when`/`then` 引用的字段均已声明 + `has_role` ∈ 该字段 `roles[]` 词表 + `then.field` 是 enum 且 `required` 或带 `default` + `allow_values` 是 `options` 的**真子集**。任一不满足 → 服务启动即拒(坏声明的表现是"永远不触发的假保护",宁可启动失败也不能让它静默存在)。

**为什么需要这层**:xAI `grok-imagine-video-1.5` 的官方约束是「参考图生视频最高 720p」。该限制此前只写在 `resolution` 字段的 `hint` 里 —— 那是给人看的文案,不是机器约束,于是 1080p + 参考图的请求会一路通过创建/冻结/提交,直到上游同步 400 才失败(生产任务 `e5fa5203`,同账号 50 分钟连撞 7 次)。

**Key 命名约定**:DB seed 写入时**统一用 snake_case**(`max_length` / `max_items` / `min_items`)。后端 `ParamDef.UnmarshalJSON` 同时容忍历史 camelCase 写法(`maxLength` / `maxItems` / `minItems`)避免静默丢字段,但**新数据必须用 snake_case**。

### 3.2 JSON Schema Output (what the API returns)

The API response transforms the above into standard JSON Schema with `x-` extensions:

| JSON Schema Field | Source |
|-------------------|--------|
| `type` | `ParamDef.Type` mapped: string→string, integer→integer, float→number, enum→string+enum[], boolean→boolean, file→string+format:binary, **media_array / file_array / array → array** |
| `required` (array) | Collected from all `ParamDef.Required == true` |
| `properties.{key}.title` | `ParamDef.Label["en"]` (fallback `Label["zh"]`) |
| `properties.{key}.description` | `ParamDef.Description["en"]` (fallback `Description["zh"]`) |
| `properties.{key}.default` | `ParamDef.Default` |
| `properties.{key}.enum` | Collected from `ParamDef.Options[].Value` |
| `properties.{key}.minimum/maximum` | `ParamDef.Min/Max` |
| `properties.{key}.multipleOf` | `ParamDef.Step` |
| `properties.{key}.maxLength` | `ParamDef.MaxLength` |
| `properties.{key}.maxItems` | `ParamDef.MaxItems` (for array/media_array/file_array) |
| `properties.{key}.minItems` | `ParamDef.MinItems` |
| `properties.{key}.items` | `ParamDef.Items` (raw JSON Schema items) **OR** auto-built from `ParamDef.ItemSchema` for array editors |

**Custom x-extensions:**

| Extension | Type | Description |
|-----------|------|-------------|
| `x-ui-component` | string | Widget hint,**受控词表 19 值冻结**(CRC v2 role_kind 切片,`ui_component.go` + ValidateShape 不变量 15 启动期强制): `textarea`, `text_input`, `select`, `radio_group`, `switch`, `number_input`, `slider`, `mode_selector`(P5-30, 见 §3.6), `image_selector`, `image_upload`, `video_upload`, `audio_upload`, `multi_image_upload`, `multi_video_upload`, `multi_audio_upload`, `media_array`, `voice_selector`, `speakers_editor`, `asset_picker`。**冻结令:禁止新增 `multi_*_upload` 变体** — 多值媒体新需求一律 `media_array` + `x-roles`;新增词表项须过契约评审 |
| `x-group` | string | Group key (信息架构语义, 自由命名: `basic` / `input` / `output` / `i2v` / `v2v` / ...) — 后台编辑器 / 调试用; 前端**勿**用作渲染分区 |
| `x-section` (P5-35) | string enum (`basic`\|`advanced`) | **渲染分区** — 由所属 `x-groups[].section` 派生; 前端**唯一**渲染分区契约 (PromptArea/Toolbar 区 vs AdvancedSheet 抽屉) |
| `x-sort-order` | int | Sort order within group |
| `x-label` | `{en, zh}` | i18n 标签 map,`en`/`zh` 均非空(见 §3.0)|
| `x-placeholder` | `{en, zh}` | i18n 占位符,`en`/`zh` 均非空 |
| `x-description` | `{en, zh}` | i18n 描述 map,`en`/`zh` 均非空(见 §3.0)|
| `x-hint` | `{en, zh}` | i18n 字段下方辅助文字(B2 wan2.7 media[] 等),`en`/`zh` 均非空 |
| `x-enum-labels` | `{value: {en, zh}}` | enum 选项的 i18n 标签,每项 `en`/`zh` 均非空 |
| `x-enum-previews` | `{value: string}` | Preview image **绝对 URL** for enum options(后端在响应时已用 `cfg.storage.r2.public_url` 拼接相对路径,前端拿到的就是可直接 `<img>` 用的绝对 URL;详见 §3.5)|
| `x-conditions` | `[{when, eq?, is_empty?, action}]` | Field visibility/requirement conditions(多条件 AND;`is_empty` 算子见 §3.4) |
| `x-options-ref` | string | 跨字段引用同 schema 的某字段 enum 列表(如 `speakers[].voice_name` 复用顶层 `voice_name` 字段的 options) |
| `x-api-field-name` | string | 上游真实字段名(P5-39 升级:用于"数量字段归一化"调试参考)。**前端按 `properties.quantity` 字段名提交即可**,中台 `injectPlatformN` 自动按此字段映射到上游(详见 §3.8 + `docs/spec/n-param-spec.md` §2)|
| `x-accept` | string[] | MIME whitelist for file type (e.g. `["image/jpeg", "image/png"]`) |
| `x-max-size-mb` | int | Max file size in MB |
| `x-role` | string | (P5-32) 字段级语义角色,受控词表 `prompt` \| `negative_prompt` \| `reference_material`;前端按 role 识别字段语义、不靠键名(见 §3.7) |
| `x-roles` | `[{key, kind, label, max_items, accept?, default, mode?}]` | (CRC v2) `media_array` 多角色机读目录。`kind ∈ {tag, slot}`(role_kind 切片,守卫强制):`tag`=可互换注记 → 统一上传区+角标;`slot`=位置/功能槽位 → 独立入口。`default` 恒输出 bool,恰好一个 true;`max_items` 恒存在。渲染规则见 §3.7 |
| `x-role-modes` | `[{key, label}]` | (CRC v2.1) `media_array` 角色模式目录(仅多模式字段输出,如 wan2.7-video);角色的 `mode` ∈ 该目录 |
| `x-role-mode-exclusive` | bool | 恒 `true`(与 x-role-modes 同现):模式互斥,前端渲染模式切换器,跨模式清空对方角色 |
| `x-value-kind` | string | (CRC v2.1 切片4) 值语义受控词表(aspect_ratio / resolution_tier / duration_seconds / seed / count 等 8 值);客户端据此格式化/分组,不解析值猜测 |
| `x-client-only` | bool | (CRC v2.1 S2-e) UI-only 驱动字段(如 `_ui_mode`);客户端**排除出提交 payload** |
| `x-groups` (root level) | `[{key, section, label, sort, description?}]` | Group definitions with i18n labels and sort order;`section ∈ {basic, advanced}` 强 enum 由后端校验(P5-35);可选 `description` 用于 group caption tooltip(B11) |
| `x-constraints` (root level) | `[{key, label, when: [{field, has_role?\|eq?\|is_empty?}], then: {field, allow_values}}]` | (2026-08-25) 跨字段**提交期**约束(声明形态见 §3.1)。`when` 全部成立时,`then.field` 的取值必须 ∈ `then.allow_values`。**前端应据此实时置灰被排除的选项并用 `label` 解释**(如挂上参考图后置灰 1080p);不置灰只会让用户提交后吃 40033。服务端 `ValidateParams` 无条件强制,置灰是体验不是防线 |

### 3.3 Parameter Types

| Type | JSON Schema | UI Components | Description |
|------|-------------|---------------|-------------|
| `string` | `"type": "string"` | `textarea` | Free text input. May have `maxLength` |
| `integer` | `"type": "integer"` | `number_input`, `slider` | Integer with optional `min/max/step` |
| `float` | `"type": "number"` | `number_input`, `slider` | Decimal with optional `min/max` |
| `enum` | `"type": "string", "enum": [...]` | `select`, `radio_group`, `image_selector` | Pick from predefined options |
| `boolean` | `"type": "boolean"` | `switch` | Toggle |
| `file` | `"type": "string", "format": "uri"` (`"format": "binary"` 历史) | `image_upload`, `multi_image_upload` | **直传后存 public_url 字符串** (单图) / `string[]` (多图)。前端通过 `POST /v1/uploads/sign` 拿 presigned PUT URL 后客户端直传 R2,完成后把返回的 `public_url` 回填到字段。`x-accept` (mime 白名单) 和 `x-max-size-mb` (大小上限) 仅作前端预检,后端 `domain.UploadPolicy` 二次校验。详见 [creation.md POST /v1/uploads/sign](creation.md#post-v1uploadssign) |
| `media_array` | `"type": "array"` + `maxItems` + 派生标准 `items`(`{url, role, ...}`) | `media_array` | **多角色媒体数组**(CRC v2) — 元素是 `{role: string, url: string, ...}` 对象,`role ∈ items.properties.role.enum`(= `x-roles[].key`)。角色目录**机读自 `x-roles`**(key/kind/label/max_items/accept/default/mode),**禁止硬编码角色表或按 model 文档人工枚举**。呈现形态由 `x-roles[].kind` 数据驱动(tag=统一上传区+角标 / slot=独立槽位入口,见 §3.7);多模式字段另有 `x-role-modes` 互斥切换。family-router 场景(wan2.7)后端按元素 role 自动路由 t2v/i2v/r2v upstream,详见 §6.2 |
| `file_array` | `"type": "array"` + `items.format=binary` + `maxItems` | `multi_image_upload` | 多文件直传,元素均为 R2 public_url。`x-accept` 适用于所有元素 |
| `array` | `"type": "array"` + `items` | `speakers_editor` 等定制行编辑器 | 通用结构化数组,通常配合 `item_schema` 字段定义每行结构(如 TTS speakers 的 `{speaker, voice_name}`)。前端可基于 `items.properties` 渲染行编辑器或回落到 JSON 文本框 |

### 3.3.1 `frame_urls` — 多模态图片输入(平台唯一入口)

需要"看图"的调用一律经 **`params.frame_urls`** 传图。它是**平台唯一的多模态输入入口**,
两族适配器各自按自己的协议投影,调用方无需知道对端是谁:

| 适配器族 | 投影方式 | 实现 |
|---|---|---|
| Gemini 原生 | 逐帧**下载后内联字节**(走 SSRF SafeTransport) | `gemini_multimodal_inputs.go` |
| OpenAI 兼容(经 `request_mapping` 模板) | 派生成 `content: [{type:text},{type:image_url},…]`,**URL 直传**由上游自取 | `template_renderer.go::buildChatMessages`(内置变量 `{{_chat_messages}}`) |

**字段契约**

| 属性 | 值 |
|---|---|
| `type` | `array`(元素为 https URL 字符串) |
| `required` | `false` —— 不传即退化为纯文本调用 |
| `max_items` | `32`(与 `gemini_multimodal_inputs.go` 的 `geminiMaxFrames` 对齐) |
| `ui_component` | `multi_image_upload` |

**哪些模型支持**:以 `GET /v1/models` 返回的 `param_schema` 里**有没有 `frame_urls` 声明**为准,
不要按模型名或 provider 猜。2026-09-09 起下列版本已声明(逐个真机验证过,
存档 `docs/design/text-model-probe-20260909/`):`gpt-5.6-sol` · `gpt-5.6-luna` ·
`gpt-5.6-terra` · `gpt-5.5` · `gemini-3.1-pro-preview` · `gemini-3.1-flash-lite`。

> ⚠️ **为什么强调"以声明为准"**:2026-09-09 之前 `frame_urls` 是一条
> **没声明、没守卫、没文档**的内部约定 —— param_schema 校验器只遍历已声明字段,
> 所以未声明的键既不被拒也不被丢,原样透传到适配器,能用纯属侥幸。
> 后果是客户端无从知道某能力接不接图,而平台换模型时也没有任何东西提醒"这里有人在用图",
> 图会静默消失而任务照样 `succeeded`。现已升格为声明契约。

**capability 侧**:executor 若以 OpenAI 风格 `messages` 数组表达入参
(`content: [{type:text},{type:image_url}]`),由 capability→Provider 桥在折叠时
把 text 段并入 `prompt`、image_url 段并入 `frame_urls`,executor 不必自己拼
(`capability_cross_bc_bridge.go::normalizeCapabilityLLMParams`)。

### 3.3.2 `response_mime_type` — 结构化输出(平台唯一键)

要求模型输出可严格解析的 JSON,一律经 **`params.response_mime_type = "application/json"`**。

| 适配器族 | 投影方式 | 实现 |
|---|---|---|
| Gemini 原生 | `GenerateContentConfig.ResponseMIMEType` | `gemini_adapter.go` |
| OpenAI 兼容 | 派生成 `response_format: {"type":"json_object"}` | `template_renderer.go::buildResponseFormat`(内置变量 `{{_response_format}}`) |

> ⚠️ **2026-09-09 之前这里有两个键**:`response_mime_type`(只有 Gemini 读)与
> `response_format`(OpenAI 形状,平台无人投影)。同一个意图两个键、各自只被一族认识,
> 于是换个模型结构化输出就静默失效 —— 模型返散文,下游 strict-parse 在离根因很远的地方炸。
> 现已收敛为单键 + 各族自行投影。**新增适配器族按自己的协议再投影一次,不要新造平台键。**

已声明该参数的版本(逐个真机验证过 strict-parse):`gpt-5.6-sol` · `gpt-5.6-luna` ·
`gpt-5.6-terra` · `gpt-5.5` · `gemini-3.1-pro-preview` · `gemini-3.1-flash-lite`。

### 3.4 Condition (Field Dependency) System

Conditions control field visibility and requirement dynamically. **多条件视为 AND** — 所有条件全部满足才触发 action。

> ⚠️ `x-conditions` 是**纯渲染**契约,服务端不据它校验任何东西。需要"某组合必须被拒绝"的场景请用 §3.1 的 `constraints[]` / `x-constraints`(提交期硬强制),两者不可互相替代。

```json
{
  "x-conditions": [
    { "when": "mode",      "eq": "img2img",   "action": "show" },
    { "when": "ref_image", "is_empty": false, "action": "show" }
  ]
}
```

#### Action 语义

| Action | Behavior |
|--------|----------|
| `show` | Field is visible only when condition is met |
| `hide` | Field is hidden when condition is met |
| `require` | Field becomes required when condition is met |
| `disable` | Field is disabled (grayed out) when condition is met |

#### Operator 语义

| Operator | Behavior | 典型用例 |
|---|---|---|
| `eq` | 等于某值时触发(单值 / 数组任一匹配)| 模式选择(`mode == "img2img"` 才显示参考图字段)|
| `is_empty: true` | 依赖字段值为空数组 / 空字符串 / null 时触发 | wan2.7 `audio_url` 仅在 `media[]` 空时显示 |
| `is_empty: false` | 依赖字段已填值时触发 | Veo `last_frame_image` 仅在 `first_frame_image` 已填时显示 |

#### Visible_when 简写

DB seed 写 `visible_when: {key: val}` 形态时,后端转换层会自动翻译为等价的 `x-conditions: [{when: key, eq: val, action: "show"}]`,前端无感知。

### 3.5 Asset URL 拼接(R2 / CDN base 注入)

`param_schema` 中的静态资源(目前主要是 `EnumOption.preview_url` → 输出到 `x-enum-previews`)在 DB 中**仅存相对路径**,后端 `ListModelsHandler` 在响应时用 `cfg.storage.r2.public_url` 实时拼接绝对 URL。

| 阶段 | 数据形态 | 示例 |
|---|---|---|
| DB(`prov_model_versions.param_schema.parameters[*].options[*].preview_url`)| 相对路径 | `"preset-thumbnails/wanx-style-repaint/style_0_retro_comic.jpg"` |
| Handler 响应(`/v1/models` → `properties.style_index["x-enum-previews"]`)| 绝对 URL | `"https://r2.showsapp.org/preset-thumbnails/wanx-style-repaint/style_0_retro_comic.jpg"` |

**设计动机**:
- DB 不持有基础设施 URL — 多环境(dev/staging/prod)各自走自己的 base
- CDN 域名变更只改 `config.{env}.yaml::storage.r2.public_url`,**不需要迁移 DB**
- 已是绝对 URL 的数据(legacy / 第三方资源) handler 原样保留,向前兼容

**前端约束**:**永远使用响应里的 URL,不要根据 model_code 自行拼路径** —— 后端可能切换 R2 / CDN 路径,只有 handler 知道当前环境的 base。

### 3.6 Virtual Mode Selector(`x-ui-component=mode_selector`,P5-30)

某些模型(如 Seedance 2.0)有"形态分组"语义 — 字段集合互斥,需要前端显式提供 Mode Selector 让用户选择当前形态。后端通过**虚拟字段** `_ui_mode` + `visible_when` 联动表达这种分组,**无需前端识别新机制**(已有 `x-conditions` 引擎自动处理)。

#### 设计原则

> **后端 schema = 引擎能力契约** — 5 个 Seedance 文件字段(reference_images/videos/audios + first_frame/last_frame)保持独立(火山 API 拆 image_url/video_url/audio_url 三种 content type 必需)
> **前端 UI = 用户心智模型** — 把"5 字段 + 隐性互斥"折叠为"一个 Mode Selector + 联动显示对应字段组"
> **元数据桥接** — `_ui_mode` 虚拟字段 + `visible_when:{_ui_mode: <key>}`,前端零新代码

#### 字段约定

```json
// 虚拟字段定义 (用户 UI 控件,不传给上游)
{
  "key": "_ui_mode",                // ← 下划线前缀: 前端 UI state, 不进入 API 请求体
  "type": "enum",
  "required": false,                // 不选 = 默认形态(Seedance: 文生视频)
  "ui_component": "mode_selector",  // ← 前端识别此值, 渲染顶部 Tab/Radio
  "label": { "zh": "生成模式", "en": "Generation Mode" },
  "options": [
    { "value": "frames",     "label": { "zh": "首尾帧" },   "icon": "frames" },
    { "value": "references", "label": { "zh": "全能参考" }, "icon": "references" }
  ]
}

// 联动字段 (visible_when 简写, 后端转 x-conditions show)
{
  "key": "first_frame",
  "type": "file",
  "visible_when": { "_ui_mode": "frames" }
  // → x-conditions: [{ "when": "_ui_mode", "eq": "frames", "action": "show" }]
}
```

#### 前端实现要点

**Step 1**:遇到 `x-ui-component=mode_selector` 字段 → 渲染顶部 Tab/Radio(`options` + `icon` + `label`)

**Step 2**:其他字段照常用 `x-conditions` 引擎判定显隐(已实装,与 B4 Veo 案例同机制)

**Step 3**:提交时**剔除 `_` 前缀字段**,不进入 `params` 请求体:

```typescript
const { _ui_mode, ...payload } = params;
api.post('/v1/tasks', { model_version_bid, params: payload });
```

**Step 4(可选 polish)**:用户切换 mode 时,前端 onChange 应清空对方组字段(避免互斥提交触发 40033):

```typescript
onChange={(mode) => {
  params._ui_mode = mode;
  if (mode !== 'frames')     { params.first_frame = ''; params.last_frame = ''; }
  if (mode !== 'references') { params.reference_images = []; params.reference_videos = []; params.reference_audios = []; }
}}
```

#### 后端兜底

即使前端误传 `_ui_mode` 到 API,**后端 adapter 透传白名单不含 `_` 前缀字段**,自动不会泄漏到上游(Seedance 例:adapter 仅透传 `["ratio","duration","resolution","watermark","generate_audio","seed","return_last_frame"]`)。

如果客户端绕过 Mode Selector UI(例如直接调 API),adapter 仍会做**业务级互斥校验**(P5-29):同传 reference_* + first_frame → 直接返 `40033 ErrInvalidParam` 不调上游。

#### 同模式可复用

未来其他模型若也有形态分组语义(例:Veo i2v vs v2v 已用 `mode` 字段实现互斥,可迁移到 `_ui_mode` 模式让 UX 统一),**只需 schema migration 加字段定义**,无需任何后端代码或前端机制改动。

详细 UX 设计 + 互斥校验协作:[`docs/web-paramschema-seedance-ux-design.md`](../web-paramschema-seedance-ux-design.md)

---

### 3.7 Field Semantic Role(`x-role=reference_material`,P5-32)

参考素材类字段(参考图 / 首尾帧 / 源视频 / 风格 ref 等)在前端通常聚合为一个"参考素材区"渲染,但每个模型的字段构造差异很大 — wan2.7-video 是单字段多用途、Seedance 是 5 字段独立、Seedream 是单字段多张数组。后端通过**字段级语义角色** `x-role` 给前端单一信号识别参考素材集合,**前端按字段数自决渲染形态**。

#### 设计原则

> **schema 声明事实,不规定 UX 策略** — 后端只说"这些字段是参考素材",**不**告诉前端 segmented 还是 unified;
> **字段级精准** — 不在 group 上加 role(group 是功能分组 e.g. `input/advanced`,可能含非参考字段如 prompt);
> **零信息重叠** — `x-role` 不重复 `key/label/accept/max_items/required` 任一已有字段。

#### 字段约定

```json
// 同 group 下的多个参考素材字段(Seedance segmented 形态)
{
  "key": "first_frame",
  "type": "file",
  "role": "reference_material",          // ← P5-32: 字段语义角色
  "ui_component": "image_upload",
  "group": "input"
}
// → JSON Schema 输出: prop["x-role"] = "reference_material"
```

```json
// 单字段多用途(wan2.7-video unified 形态 / Seedream 多张数组)
{
  "key": "media",
  "type": "media_array",
  "role": "reference_material",
  "max_items": 5,
  "ui_component": "media_array"
}
```

#### 前端识别逻辑

**Step 1** — 扫 `properties[*]` 找出 `x-role == "reference_material"` 的字段集合 `refFields[]`。

**Step 2** — 按 `refFields.length` 推断渲染形态:

| 字段数 | 形态 | 渲染策略 |
|---|---|---|
| `0` | 模型无参考素材输入 | 不渲染参考素材区 |
| `1` | **unified** 单上传入口 | 单 widget(`media_array` 多用途 / `multi_image_upload` 多张图 / `image_upload` 单张) |
| `≥ 2` | **segmented** 多行入口 | 每个字段独立渲染一行,共享标题"参考素材" |

**Step 3** — 能力标签 / 行 label 直接用每个字段的 `x-label.zh / x-label.en`,不引入新字段。

**Step 4** — 模式切换(配合 `_ui_mode` Mode Selector,如 Seedance)时,前端 onChange 清空对方组字段;`x-conditions` 引擎自动处理显隐,与 §3.6 同链路。

#### 字段内多角色渲染契约(`x-roles[].kind`,CRC v2 role_kind 切片)

Step 2 解决的是**字段间**形态(几个 reference_material 字段几个入口);`media_array` 单字段**内部**的多角色形态由 `x-roles[].kind` 数据驱动 —— 同一 x-roles 机制实际承载两类语义完全不同的角色,客户端**禁止**用启发式或硬编码 role-key 白名单区分(migration `20260710_crc_v2_role_kind.sql` 前 ai_studio 曾被迫硬编码 `_collapsibleRoleKeySets`,正是本契约要消灭的形态):

| 输入形态 | 渲染 | 现网实例 |
|---|---|---|
| 无 `x-roles`(`multi_*_upload` / role-less array) | 扁平网格上传 | Seedream/GPT/Qwen `reference_images` |
| 全部 role 为 `kind=tag`(可互换注记) | **单一上传区 + 角标切换**:默认角色 = `default:true`,每 role 显示配额 `n/max_items`,总量 `maxItems`;角标可点按改 role | gemini `object`/`character`、veo `subject`/`style` |
| 含 `kind=slot`(位置/功能槽位) | **每 slot 独立入口行**(各自 `accept`/`max_items`);同字段的 tag roles 池化为一个附加上传区(混装) | wan2.7-i2v 全 slot;wan2.7-video slot×4 + tag×2 混装 |
| 有 `x-role-modes` | 模式 chip 先行,激活模式的 role 子集内套用上两行规则 | wan2.7-video |
| `kind` 缺失(旧缓存) | 按 `slot` 保守处理,**不引入启发式** | — |

**提交契约**:`media_array` 值 = `[{role, url, ...item_extra_props}]`,`role ∈ x-roles[].key`(缺省视为 default 角色);`multi_*_upload` 值 = `["url", ...]`。role 数据必须端到端保留 — veo 的 subject/style 映射上游真实字段(referenceType ASSET/STYLE),gemini 的 object/character 用于平台配额校验(object/character 各自 max_items,总 maxItems)。

> **服务端归一兜底(2026-08-06)**:元素 `role` 为空或不在该字段 `x-roles[].key` 词表内时,
> 服务端在提交前统一改写为该字段的 default 角色(provider app service
> `normalizeMediaElementRoles`,schema 驱动、按模型各归各的 default)。
> 起因:客户端曾把**字段级** `x-role` 值 `reference_material` 误填进**元素级** role 槽,
> 上游 DashScope 直接拒绝(生产 BID `a49ede1c`)。归一让这类漏值不再打穿到上游,
> 但客户端**仍应**按本节契约发 `x-roles[].key` 内的值——归一是兜底不是许可,
> 显式槽位选择(如 last_frame)拼错会被静默归到 default 槽位,语义即偏离用户意图。

> **服务端 role 级强制(2026-08-09,线上双向验收通过)**:`x-roles` 目录不再只供渲染 —
> 创建期(积分冻结前)服务端按 schema 强制执行,违例整单拒绝,**不建任务、不冻结积分**
> (provider domain `validateMediaArrayRoles`,经 `ValidateAndMergeParams` 在归一之后执行)。
> 错误码按端点分两种呈现:
> - `POST /v1/tasks`(提交,端点特化):**HTTP 400 / code 40001** `parameter validation failed`,
>   逐项违例明细在 **`details.params`**(如 `invalid parameter: map[media:media: role "first_frame"
>   allows at most 1 item(s), got 3]`);
> - 其余经通用 `GetErrorCode` 映射的面(如 `POST /v1/tasks/estimate`):**40033**,message 通用无字段明细。
>
> 校验项:
> 1. **每角色数量 ≤ `x-roles[].max_items`** — 如 wan2.7 `first_frame` 上限 1,发 3 张报
>    `media: role "first_frame" allows at most 1 item(s), got 3`。注意归一兜底会把词表外
>    role 收敛到 default 角色,多张词表外图会被计入 default 槽位一并触发本限制
>    (起因:生产任务 `ca3dd776` 客户端 3 张图全标 `first_frame`,上游 DashScope 提交后
>    2 秒终态拒绝 "Multiple first_frame items are not allowed",积分已冻结)。
> 2. **role ∈ `x-roles[].key` 词表**(归一后仍词表外 → 拒)。
> 3. **URL 与角色 `accept` MIME 白名单匹配**(按扩展名/data URI 推断,无法推断时放行)。
>
> 不强制模式互斥(`x-role-mode-exclusive` 是渲染约束;`first_frame` 与 `reference_image`
> 混发在 wan2.7 上游合法,后端 family-router 照常路由 r2v)。角色组合规则(如
> `driving_audio` 依赖关系)仍归上游终态诊断。

#### 当前覆盖范围(2026-05-06,migration `p5_32` 已落地)

37 个字段、18 个 model 一次性标完:

| 模型 | role 字段数 | 形态 |
|---|---|---|
| Seedance 2.0 / 2.0-fast | 5(first/last_frame + reference_images/videos/audios) | segmented + `_ui_mode` 联动 |
| Veo 3.1 generate/fast | 4(first/last_frame_image + source_video + reference_images) | segmented(i2v / v2v group 区分)|
| Veo 3.1 lite | 3(**无 reference_images** — lite 不支持参考图,2026-08-06 迁移摘除;误传会被 adapter 硬闸拒 `unsupported_by_model`) | segmented |
| wan2.2-animate-mix | 2(image_url + video_url) | segmented |
| wanx-style-repaint-v1 | 2(image_url + style_ref_url) | segmented |
| wan2.7-video | 1(media[] 多用途) | unified |
| Gemini 3-pro-image / 3.1-flash-image preview | 1(reference_images,max=14) | unified |
| Seedream 4.5 / 5.0 | 1(ref_images,max=14) | unified |
| qwen-image-2.0-pro / wan2.7-image-pro | 1(ref_images) | unified |
| Veo upscale / Veo3.1 / gen4_image_turbo / gen4_turbo | 1 | unified |

#### 与 `_ui_mode`(§3.6)的协作

`x-role` 和 `_ui_mode` 解决正交问题、互不冲突:
- `_ui_mode` = **形态选择**(用户当前在哪个 mode,e.g. 首尾帧 vs 全能参考)
- `x-role` = **字段语义**(这个字段是哪类资源,e.g. 参考素材 vs prompt)

Seedance 同时使用两者:`_ui_mode` 决定字段可见性(visible_when),`x-role` 让前端识别可见的字段集中哪些属于参考素材区。

#### 后端纪律

`x-role` **不**驱动 adapter 行为。Adapter 互斥校验(P5-29 Seedance / P5-31 Seedream)仍按字段名硬编码;migration p5_32 改了 schema 但**不**改 adapter,可独立回滚(单 SQL 清空 role 字段,前端按 ui_component 启发兜底自动接管)。

> **纪律松动记录(ADR-Subject-01, 2026-06-10)**: 原表述"纯 UI 元数据"已松动 ——
> creation BC 的 `SubjectRefInjector`(主体参考注入,提交期)将 `role=reference_material`
> 作为注入目标识别依据。边界:仅限 creation 提交期;adapter 仍禁止读 role;回滚 = 清空
> role 后注入自动降级为跳过(`_subject_skipped_reason`),提交链路零破坏。
> 详见 `docs/architecture/creation/adr-subject-01-role-injection.md`。

新模型注册时,所有"参考素材类"字段必须显式标 `role: "reference_material"`;DB verify block 是 SQL 合规闸,新加目标模型时同步更新 `expected_models` 数组(防漏标)。**该标记自 ADR-Subject-01 起兼具主体注入目标语义 —— 漏标 = 该模型主体注入静默不可用**。

---

### 3.8 Quantity Field Normalization(P5-39)

历史上同一语义的"生成数量"字段,跨 model 用 3 种 key 命名(`n` / `quantity` / `number_of_videos`),前端无法用统一字段路径渲染数量 stepper。**P5-39 全平台归一化为 `quantity`**(migration `p5_39_normalize_quantity_field.sql`)。

#### 设计原则

> **DB 是动态参数归一化层** — `param_schema.parameters[i].key` 是描述性元数据,改名零业务影响;
> **adapter 与 schema 字段名解耦** — 全平台读 `params["_platform_n"]`,与前端字段名完全独立;
> **上游真实字段名锚定 `platform_params.n.provider_key`** — 这才是写上游 API 的字段名,P5-39 一字未动。

#### 字段约定

```json
// 用户从 GET /v1/models 看到的统一格式 (举例: veo-3.1-generate-001)
{
  "properties": {
    "quantity": {
      "type": "integer",
      "title": "Variants",
      "default": 1, "minimum": 1, "maximum": 4,
      "x-ui-component": "number_input",
      "x-group": "basic",
      "x-sort-order": 6,
      "x-label": { "en": "Variants", "zh": "生成数量" },
      "x-api-field-name": "number_of_videos"   // ★ P5-39: 上游真实字段名 (调试参考)
    }
  }
}
```

#### 前端规范

**Step 1** — 渲染数量 stepper:统一读 `properties.quantity`(跨全 12 model 命中)。

**Step 2** — 提交请求体:统一传 `params: { quantity: 3 }`,**不需要按 `x-api-field-name` 改名**。

```typescript
// 前端无需关心 x-api-field-name, 提交统一用 quantity
api.post('/v1/tasks', {
  model_version_bid,
  params: { quantity: 3, ...其他参数 }
});
```

**Step 3** — `x-api-field-name` 仅作调试参考(在开发者面板展示"上游使用的真实字段名",方便排查)。

#### 后端字段路径(自动接管)

```
前端 quantity=3
       ↓
中台 injectPlatformN (provider_call_service.go:613):
  优先 _platform_n → 兜底 [n, quantity, providerKey] → clamp [min,max] → 同时写:
    params["_platform_n"] = 3      (平台统一名, adapter 读这个)
    params[provider_key]  = 3      (e.g. n / number_of_videos / quantity, 由 platform_params.n.provider_key 决定)
       ↓
Adapter ExecuteSync: 读 params["_platform_n"], 按 provider_key 字段名写上游 API 体
       ↓
上游 API: { "n": 3 } 或 { "number_of_videos": 3 } 或 { "quantity": 3 }
```

#### 全 12 模型实测对照

| model | properties 字段名 | x-api-field-name | upstream API 字段名 |
|---|---|---|---|
| imagen-4.0-fast/generate-001 | `quantity` | (空)| `quantity` |
| imagen-4.0-ultra-generate-001 | `quantity` | (空)| (空)|
| qwen-image-2.0-pro | `quantity` | `n` | `n` |
| seedance-2.0 / 2.0-fast | `quantity` | `n` | `n` |
| seedream-4.5 / 5.0 | `quantity` | `n` | `n` |
| veo-3.1-fast/generate/lite-001 | `quantity` | `number_of_videos` | `number_of_videos` |
| wan2.7-image-pro | `quantity` | `n` | `n` |

#### 兼容性

- ✅ **前端继续传 `n` / `number_of_videos`** 也能 work — `injectPlatformN` 兜底链已含三套字段名(向后兼容旧前端,无强制升级压力)
- ✅ **adapter 0 改动** — 读 `_platform_n`,与前端字段名解耦
- ✅ **上游 API 行为完全不变** — `provider_key` 一字未动,上游字段名映射通过此锚点决定

详见 `docs/spec/n-param-spec.md` §2 + migration `p5_39_normalize_quantity_field.sql`。

---

### 3.9 Universal Field Name Normalization(P5-40)

P5-39 数量字段归一化是**单字段** + 中台 `injectPlatformN` 兜底链。P5-40 把这套思路**通用化** — 引入 `transformAliasToProviderField` 中台函数,基于 `api_field_name` 元数据做**双向双写**,使 schema 字段名与 adapter 字面量解耦。

#### 三层分层架构

| 层 | 字段名语义 | 责任 | 例(Runway gen4_image_turbo)|
|---|---|---|---|
| **UI 层**(`param_schema.parameters[i].key`)| canonical 前端友好名 | schema 元数据 | `prompt` / `aspect_ratio` |
| **中台层**(`transformAliasToProviderField`)| 双向双写 | UI ↔ adapter 翻译 | 读 `api_field_name` 做映射 |
| **Adapter 层**(`Params["xxx"]` 字面量)| 上游 API 字段名 | 与上游协议对齐 | `promptText` / `ratio` |

#### 7 类归一化映射(P5-40 已落地)

| label.zh | UI canonical key | 上游字段(api_field_name)| 受影响 model |
|---|---|---|---|
| 提示词 | `prompt` | `promptText` | gen4_turbo / gen4_image_turbo / veo3.1 |
| 画面比例 | `aspect_ratio` | `ratio`(部分,gen4/seedance/veo3.1/wan2.7-video) | 6 model |
| 参考图片 | `reference_images` | `ref_images`(qwen / seedream / wan2.7-image)| 4 model |
| 分辨率 | `resolution` | `size`(仅 wan2.7-image-pro)| 1 model |
| 生成音频 | `generate_audio` | `audio`(仅 Runway veo3.1)| 1 model |
| 首帧 | `first_frame_image` | `first_frame`(seedance ×2)| 2 model |
| 尾帧 | `last_frame_image` | `last_frame`(seedance ×2)| 2 model |

#### 前端规范

**Step 1 — schema 渲染**:统一读 `properties.<canonical_key>`(prompt / aspect_ratio / reference_images 等),按 `x-ui-component` 渲染对应组件。

**Step 2 — 提交请求**:统一传 `params: { canonical_key: value }`,**不需要按 `x-api-field-name` 改名**。

```typescript
// 前端无需关心 api_field_name, 提交统一用 canonical
api.post('/v1/tasks', {
  model_version_bid,
  params: {
    prompt: "hi",                 // 即使 Runway 上游用 promptText
    aspect_ratio: "16:9",         // 即使 Runway 上游用 ratio
    reference_images: [...]       // 即使旧 schema 用 ref_images
  }
});
```

**Step 3 — `x-api-field-name` 仅作调试参考**(开发者面板看"上游真实字段名")。

#### 后端字段路径(自动接管)

```
前端 prompt + aspect_ratio
       ↓
中台 injectPlatformN (P5-39, 数量字段专用)
       ↓
中台 transformAliasToProviderField (P5-40, 通用):
  schema.parameters 中 api_field_name 配置 →
  双写: params["prompt"] + params["promptText"] (alias)
        params["aspect_ratio"] + params["ratio"] (alias)
       ↓
Adapter ExecuteSync: 读老字段名 (params["promptText"] / params["ratio"]) → 调上游
       ↓
上游 API: { "promptText": "hi", "ratio": "16:9" }
```

#### 双向兼容(向后)

旧前端继续传老字段名(`promptText` / `ratio`)也能 work — `transformAliasToProviderField` 反向双写到 canonical。

#### 关键设计原则

1. **schema 字段名与 adapter 字面量解耦** — 符合分层架构,各层独立演进
2. **零 adapter 字面量改动** — 改 DB 不需要改 5 个 adapter,单一来源 `api_field_name` 配置
3. **可扩展** — 新候选字段只需 DB schema + `api_field_name` 配置,中台自动接管,不需要再写新 if-else
4. **functional purity** — `transformAliasToProviderField` 不修改入参,返回新 map

详见 `docs/spec/n-param-spec.md` §2.1 + migration `p5_40_normalize_field_names.sql` + `provider_call_service.go::transformAliasToProviderField`。

---

### 3.10 Thinking Level(Nano Banana 图片模型专项,`thinking_level`)

**能力矩阵(事实源 = 各模型 `param_schema`,DB 驱动)**

| 模型 | 是否支持 `thinking_level` | 可选值 |
|---|---|---|
| `gemini-3.1-flash-image` | ✅ 支持 | `minimal`(极速) / `high`(更强指令遵循与文字保真,延迟更高) |
| `gemini-3-pro-image` | ❌ **不支持** | — |
| 其它/未来图片模型 | ❌ 默认不支持 | — |

#### 设计原则

- **数据驱动为根**:某图片模型是否支持思考,**只由其 `param_schema` 是否声明 `thinking_level` 字段决定**。支持 → 该字段进 `param_schema.parameters[]`(`type=enum`,`group=advanced`),前端据此渲染「思考深度」控件并下发;不支持 → 不声明,前端不显示、不下发。**新增支持思考的模型零代码**:在其 `param_schema` 声明 `thinking_level` 即可。
- **后端兜底防御(belt-and-suspenders)**:适配器 `buildNanoBananaConfig` 另有一道 `modelSupportsThinking` 白名单闸(仅 `gemini-3.1-flash-image` 前缀放行)。作用是**防持旧/脏 `param_schema` 的客户端硬传** `thinking_level` 给不支持的模型 → 否则上游返 `400 INVALID_ARGUMENT: thinking_level ... is not supported by this model`。不支持的模型即便收到该参数也**静默丢弃**(不阻断出图)。此闸是防脏输入的第二道线,**不是**能力事实源。

#### 客户端契约

- 客户端**只应**对 `param_schema` 声明了 `thinking_level` 的模型下发该参数(即对着表单渲染,不臆造)。
- 对 `gemini-3-pro-image` 下发 `thinking_level` 会被后端丢弃(不报错、正常出图);但仍应以 `param_schema` 为准,不要硬传。
- ⚠️ **缓存**:模型列表(含 `param_schema` → JSON Schema)服务端 Redis 缓存 TTL ~5min。`param_schema` 变更后,客户端应在缓存过期后重新拉取 `GET /v1/models` 以获得最新能力矩阵。

> 历史事故(task `7ca263af`):`gemini-3-pro-image` 的 `param_schema` 曾错误声明 `thinking_level` → 前端下发 → 上游 400。已由迁移 `20260723_prov_gemini_image_thinking_fix.sql` 从其 `param_schema` 移除,并把 `gemini-3.1-flash-image` 的 enum 收敛为 `minimal/high`。

---

### 3.11 音乐生成(`task_type=txt2audio`,2026-08-26)

**在架模型**(`media_type=audio` · `task_type=txt2audio`,creation 侧归一为 `audio_gen`):

| `model_code` | 产物 | 时长 | `output_format` |
|---|---|---|---|
| `lyria-3-pro-preview` | MP3 / WAV,44.1 kHz 立体声 | 数分钟(由提示词决定) | ✅ `mp3`(默认) / `wav` |
| `lyria-3-clip-preview` | MP3,44.1 kHz 立体声 | **恒 30 秒** | ❌ 不暴露(上游仅 MP3) |

#### 为什么只有一个 `prompt` 字段(没有 lyrics / instrumental / duration)

上游**没有**这三个字段 —— 官方把它们全部表述为**提示词内容**:

- 曲式:`[Verse]` / `[Chorus]` / `[Bridge]` 段落标签
- 时间轴:`[0:00 - 0:10] Intro: soft lo-fi beat with vinyl crackle`
- 纯音乐:在提示词里写 `Instrumental only, no vocals`
- 时长(仅 Pro):在提示词里写 `create a 2-minute song`
- 歌词:直接把歌词整段写进提示词
- 语言:**歌词语言跟随提示词语言**(用法语写提示词就出法语歌)

平台不把它们拆成表单字段再在后端拼回一段文本 —— 那会把一份提示词模板焊死在
适配器里,用户反而写不出上面这些更精细的表达。渲染提示请读该字段的
`x-hint` / `placeholder`(双语,DB 驱动)。

#### 参考图(`reference_images`)

单角色 `media_array`(`x-roles[0].key = "inspiration"`,`kind=tag`),**最多 10 张**。
模型按画面的情绪与色彩谱曲。上游的图片只有"灵感来源"一种语义,故**不做**
object/character 式的角色分类。

#### `output_schema`(音乐模型有值)

```jsonc
// lyria-3-clip-preview
{ "formats": ["mp3"], "sample_rate_hz": 44100, "channels": 2, "duration_seconds": 30, "watermark": "synthid" }
// lyria-3-pro-preview
{ "formats": ["mp3", "wav"], "sample_rate_hz": 44100, "channels": 2, "watermark": "synthid" }
```

#### 客户端需要知道的三件事

1. **产物候选的 `duration_ms` 可能为 0** —— 上游不返回时长。资产级时长由服务端
   ffprobe 异步回填 `gen_assets.duration_seconds`,不要依赖候选阶段的该字段做排版。
2. **`output_metadata.lyrics`** 携带模型生成的歌词与曲式结构(纯文本,可直接展示)。
   它**不是** `output_metadata.text` —— 后者在平台内是"文本产物"的判据,音乐任务不设该键。
3. **单轮生成**:不支持基于已生成片段做多轮迭代编辑;每次都是一次全新生成,
   同一提示词两次结果也会不同。产物含 SynthID 音频水印(人耳不可闻)。

### 3.12 语音转写(`task_type=stt`,2026-08-27)

**在架模型**(`media_type=audio` · `task_type=stt`,均为 `per_minute` 对客计价):

| `model_code` | 输入上限 | 时间戳 | 说话人分离 | 词表 |
|---|---|---|---|---|
| `fun-asr` | 8 小时(平台闸) | 句级原生(+可选词级) | ✅ `speaker_count` 提示 1..12 | 预建词表 `vocabulary_id` |
| `gemini-3.5-transcribe` | **30 分钟**(上游硬限) | 词级(句由服务端重建) | ✅ 至多 8 人,无数量提示 | 内联热词 `custom_vocabulary` |

两模型 `param_schema` 完全同形(单参数 `audio_asset_bid`,`asset_picker`),客户端
渲染层切换零适配;差异全部在**直发的供应商参数**与能力边界上。

#### 供应商参数(白名单直发,不在 param_schema 里)

提交时随任务参数携带,服务端白名单校验(形状非法 40001 显式拒绝):

| 键 | 形状 | `fun-asr` | `gemini-3.5-transcribe` |
|---|---|---|---|
| `language_hints` | string[] ≤4 项 | ✅ | ✅(BCP-47,如 `cmn-Hans-CN`;缺省=85+ 语言自动检测含混说) |
| `diarization_enabled` | bool | ✅ | ✅ |
| `speaker_count` | int 1..12(须配合 diarization) | ✅ | ⚪ 忽略(上游无此参数,提示类降级无害) |
| `vocabulary_id` | string ≤64 | ✅ | ❌ **确定性拒绝**(dashscope 侧资源引用,换用 `custom_vocabulary`) |
| `custom_vocabulary` | string[] 1..100 项,每项 ≤64 字符 | ❌ **确定性拒绝**(fun-asr 只认预建词表) | ✅(代价见下) |

`custom_vocabulary` 两条互斥(均提交期 40001):
- 与 `vocabulary_id` 互斥(不同供应商的同一能力,同时携带说明没想清楚走哪家);
- 与 `diarization_enabled=true` 互斥 —— **上游硬约束**(2026-08-27 真机 400
  `custom_vocabulary is incompatible with diarization`;官方文档的三者组合示例已被上游拒绝,以实测为准)。

⚠️ **热词换走时间轴**:`custom_vocabulary` 与词级时间戳同样互斥(真机 400),
携带热词时服务端自动切到纯文本模式 —— 产物**只有全文 `text`,无
`transcript.json` 句级时间戳、无 `transcript.srt`**(管线降级为单句全区间)。
需要字幕/逐句定位的场景不要带热词,或改走 `fun-asr` 的预建词表(两者兼得)。

#### 产物(两模型同口径)

`transcript.json`(D2 冻结 `schema=transcript_v1`:句级 `idx/t0/t1/text` +
可选 `speaker` / `words`)+ `transcript.srt`。gemini 上游只返词级标注,句由
服务端确定性重建(说话人切换 / 句末标点 / ≥2s 停顿 / 80 词硬切);说话人标签
归一为与 fun-asr 同形的 `"1"` / `"2"`(剥上游 `spk_` 前缀)。

#### 选型指引

- **> 30 分钟的素材必须走 `fun-asr`** —— gemini 开词级时间戳时上游硬限 30 分钟,
  超限确定性失败(不静默降级)。
- 多语种混说、内联热词、无预建词表流程 → `gemini-3.5-transcribe`。
- `gemini-3.5-transcribe-live`(实时流式)**不在本表**:那是 Live API 域,归实时
  语音会话面(`docs/api/live-audio-client-contract-v1.0.md`),不可当普通 stt 提交。

---

## 4. Complete param_schema Example

### qwen-image-2.0-pro (Alibaba DashScope)

This is the **full JSON Schema output** as returned by `GET /v1/models` for the qwen-image-2.0-pro model version. It demonstrates all field types, conditions, groups, i18n labels, and file upload constraints.

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["mode", "prompt"],
  "properties": {
    "mode": {
      "type": "string",
      "enum": ["txt2img", "img2img"],
      "default": "txt2img",
      "title": "Mode",
      "x-ui-component": "radio_group",
      "x-group": "basic",
      "x-sort-order": 1,
      "x-label": {"en": "Mode", "zh": "创作模式"},
      "x-description": {"en": "Choose a creation mode: generate an image from text only, or upload a reference image to edit", "zh": "选择创作模式: 纯文本生成图片, 或上传参考图进行编辑"},
      "x-enum-labels": {
        "txt2img": {"en": "Text-to-Image", "zh": "文生图"},
        "img2img": {"en": "Image Edit", "zh": "图生图 / 编辑"}
      }
    },
    "prompt": {
      "type": "string",
      "maxLength": 2000,
      "title": "Prompt",
      "x-ui-component": "textarea",
      "x-group": "basic",
      "x-sort-order": 2,
      "x-label": {"en": "Prompt", "zh": "提示词"},
      "x-description": {"en": "Supports Chinese and English — describe the scene / add text / give editing instructions (e.g. 'change the background to a beach')", "zh": "支持中英文, 可描述画面 / 添加文字 / 编辑指令 (如 '把背景换成海滩')"}
    },
    "ref_images": {
      "type": "string",
      "format": "binary",
      "title": "Reference Images",
      "x-ui-component": "multi_image_upload",
      "x-group": "basic",
      "x-sort-order": 3,
      "x-label": {"en": "Reference Images", "zh": "参考图片"},
      "x-description": {"en": "Up to 3 images, each ≤ 10MB, resolution 384–3072px. For multi-image blending or multi-image sequences, pass them in order", "zh": "最多 3 张, 每张 <= 10MB, 分辨率 384-3072px。多图融合 / 多图连续生成时按顺序传入"},
      "x-accept": ["image/jpeg", "image/png", "image/webp", "image/bmp"],
      "x-max-size-mb": 10,
      "x-conditions": [
        {"when": "mode", "eq": "img2img", "action": "show"}
      ]
    },
    "size": {
      "type": "string",
      "enum": ["1024*1024", "1664*928", "928*1664", "1472*1140", "1140*1472", "2048*2048"],
      "default": "1024*1024",
      "title": "Image Size",
      "x-ui-component": "select",
      "x-group": "basic",
      "x-sort-order": 4,
      "x-label": {"en": "Image Size", "zh": "图片尺寸"},
      "x-enum-labels": {
        "1024*1024": {"en": "1:1 (1024×1024)", "zh": "1:1 (1024×1024)"},
        "1664*928":  {"en": "16:9 (1664×928)", "zh": "16:9 (1664×928)"},
        "928*1664":  {"en": "9:16 (928×1664)", "zh": "9:16 (928×1664)"},
        "1472*1140": {"en": "4:3 (1472×1140)", "zh": "4:3 (1472×1140)"},
        "1140*1472": {"en": "3:4 (1140×1472)", "zh": "3:4 (1140×1472)"},
        "2048*2048": {"en": "2K Large", "zh": "2K 大图"}
      }
    },
    "n": {
      "type": "integer",
      "minimum": 1,
      "maximum": 6,
      "default": 1,
      "title": "Number of Images",
      "x-ui-component": "number_input",
      "x-group": "basic",
      "x-sort-order": 5,
      "x-label": {"en": "Number of Images", "zh": "生成数量"},
      "x-description": {"en": "Number of images generated per request (billed per image)", "zh": "一次请求生成的图像数量 (按张收费)"}
    },
    "negative_prompt": {
      "type": "string",
      "maxLength": 500,
      "title": "Negative Prompt",
      "x-ui-component": "textarea",
      "x-group": "advanced",
      "x-sort-order": 1,
      "x-label": {"en": "Negative Prompt", "zh": "负向提示词"},
      "x-description": {"en": "Describe content you do not want to appear", "zh": "描述不希望出现的内容"}
    },
    "prompt_extend": {
      "type": "boolean",
      "default": true,
      "title": "Prompt Rewrite",
      "x-ui-component": "switch",
      "x-group": "advanced",
      "x-sort-order": 2,
      "x-label": {"en": "Prompt Rewrite", "zh": "智能改写提示词"},
      "x-description": {"en": "When enabled, the model automatically refines the prompt to improve results", "zh": "开启后模型会自动优化提示词以提升效果"}
    },
    "seed": {
      "type": "integer",
      "minimum": 0,
      "maximum": 2147483647,
      "title": "Seed",
      "x-ui-component": "number_input",
      "x-group": "advanced",
      "x-sort-order": 3,
      "x-label": {"en": "Seed", "zh": "随机种子"},
      "x-description": {"en": "A fixed seed makes results reproducible", "zh": "固定种子可复现结果"}
    },
    "watermark": {
      "type": "boolean",
      "default": false,
      "title": "Watermark",
      "x-ui-component": "switch",
      "x-group": "advanced",
      "x-sort-order": 4,
      "x-label": {"en": "Watermark", "zh": "水印"}
    }
  },
  "x-groups": [
    {"key": "basic",    "section": "basic",    "label": {"en": "Basic",    "zh": "基础设置"}, "sort": 1},
    {"key": "advanced", "section": "advanced", "label": {"en": "Advanced", "zh": "高级设置"}, "sort": 2}
  ]
  // 注: 各 properties 字段同时也输出 "x-section" (basic|advanced),
  // 由所属 group 的 section 派生; 前端读 x-section 决定渲染抽屉.
}
```

### 4.2 wanx-style-repaint-v1(image_selector + x-enum-previews 实例)

展示 `image_selector` widget 的完整 `x-enum-previews` 输出形态(P5-14 落地后,前端零改动可直接渲染卡片网格):

```jsonc
{
  "style_index": {
    "type": "string",
    "default": "0",
    "enum": ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "-1"],
    "x-ui-component": "image_selector",
    "x-group": "basic",
    "x-sort-order": 2,
    "x-label": { "en": "Style", "zh": "风格" },
    "x-enum-labels": {
      "0":  { "zh": "复古漫画" },
      "1":  { "zh": "3D 童话" },
      "...": "...",
      "-1": { "zh": "自定义风格" }
    },
    // 11 个绝对 URL — 后端已用 cfg.storage.r2.public_url 拼好
    // (DB 仅存 'preset-thumbnails/wanx-style-repaint/style_N_xxx.jpg' 相对路径)
    "x-enum-previews": {
      "0":  "https://r2.showsapp.org/preset-thumbnails/wanx-style-repaint/style_0_retro_comic.jpg",
      "1":  "https://r2.showsapp.org/preset-thumbnails/wanx-style-repaint/style_1_3d_fairytale.jpg",
      "...": "...",
      "-1": "https://r2.showsapp.org/preset-thumbnails/wanx-style-repaint/style_-1_custom_upload.jpg"
    }
  }
}
```

**前端渲染**:`BareImageSelector` 检测 `x-enum-previews` 非空 → 渲染 11 张缩略图卡片网格;空时自动降级 `BareEnumPicker` 纯文字。

### 4.3 seedance-2.0 / seedance-2.0-fast(Volcengine — 输入决定形态,P5-28)

展示 **「不让用户先选 mode,看到啥上传啥」** 的产品 UX 设计:schema 不含 mode 选择器,reference_* / first_frame / last_frame 永远可见,**形态由 adapter 按字段非空推断**。

#### 形态推断(adapter 按字段非空 + 优先级决定)

| 用户输入 | 上游 mode | 备注 |
|---|---|---|
| `reference_images / reference_videos / reference_audios` 任一非空 | `multimodal_reference` | 多模态参考(优先级最高);官方约束不可纯音频 — 须 ≥1 image OR ≥1 video,Volcengine 端拒绝 |
| `first_frame` 非空 + `last_frame` 非空 | `image_to_video_first_last` | 首尾帧定义视频 |
| `first_frame` 非空(`last_frame` 空) | `image_to_video_first` | 首帧驱动视频 |
| 啥都不传 | `text_to_video` | 隐式默认;**仅此时** `enable_web_search=true` 注入顶层 `tools: [{type:"web_search"}]` |

> `edit_video` / `extend_video` 不暴露(产品决策)— 待后续如需开放,可加显式 `mode` 参数走分支即可。
>
> 同时填了 reference 和 first_frame:**reference 优先**(reference 是更复杂的输入意图)。前端表单建议用 `disabled` 视觉提示一组上传时另一组被忽略。

#### Schema 形态摘要(v2.1)

```jsonc
{
  // 注意:无 mode 字段
  "reference_images": {
    "type": "array", "maxItems": 9,
    "items": {"type": "string", "format": "binary"},
    "x-ui-component": "multi_image_upload",
    "x-group": "input",
    "x-description": { "zh": "提示词中用「图片1」「图片2」按顺序引用" }
    // 无 visible_when - 永远可见
  },
  "reference_videos": {
    "type": "array", "maxItems": 3,
    "x-description": { "zh": "参考视频 (0-3 个) — 提示词中用「视频n」按顺序引用" }
  },
  "reference_audios": {
    "type": "array", "maxItems": 3,
    "x-description": { "zh": "可参考音色 / 音乐旋律. 注意: 不能仅传音频 (须配合至少 1 张图或 1 个视频)" }
  },
  "first_frame": {
    "type": "string", "format": "uri",
    "x-ui-component": "image_upload",
    "x-group": "input"
    // 无 visible_when
  },
  "last_frame": {
    "type": "string", "format": "uri"
    // 无 visible_when
  },
  "enable_web_search": {
    "type": "boolean", "default": false,
    "x-description": { "zh": "模型自主判断是否搜索互联网内容. 仅文生视频(无任何上传素材)时生效" },
    "x-group": "advanced"
    // 无 visible_when - 始终可勾选, adapter 仅在隐式文生形态下注入 tools
  },
  "return_last_frame": { "type": "boolean", "default": false, "x-group": "advanced" },
  "resolution": {
    "type": "string",
    // seedance-2.0:      ["480p", "720p", "1080p"]
    // seedance-2.0-fast: ["480p", "720p"]            ← fast 不支持 1080p
    "default": "720p"
  },
  "ratio":          { "enum": ["21:9","16:9","4:3","1:1","3:4","9:16"], "default": "16:9" },
  "duration":       { "type": "integer", "min": 4, "max": 15, "default": 5 },
  "generate_audio": { "type": "boolean", "default": true }
}
```

#### 设计要点

1. **schema 不含 mode** — 用户感知的是上传字段,看到啥上传啥;不需要在表单顶部先做"我要哪种生成"的认知决策。
2. **adapter 按字段非空推断** — `volcengine_adapter.go::buildSeedanceRequestBody` 不再读 `params.mode`;reference 优先级 > first_frame > 隐式文生。**前端不需要也不应该**自行推断或拼 mode 字段。
3. **fast 变体单一真相** — DB seed 时 fast schema 由 2.0 schema 克隆 + patch `resolution.options=["480p","720p"]`(去 1080p),其余字段语义 100% 等价。
4. **enable_web_search 永远可见** — schema 上无 `visible_when`,前端永远渲染开关;adapter 仅在「隐式文生形态(无任何上传)」下注入 `tools: [{type:"web_search"}]`,其他形态忽略 — 这避免了"用户勾了开关却被前端隐藏掉"的反直觉。
5. **`return_last_frame`** — 文生 / 首帧驱动场景实用(取末帧用于续写),adapter 透传到顶层。
6. **官方 `edit_video` / `extend_video` 不暴露** — Volcengine 还有 2 个能力(视频编辑 / 视频续写)未开放给用户;后续如需,在 schema 加 `mode` 显式 enum + 对应字段 + adapter 加分支即可,不破坏现有形态。

#### 与 wan2.7-video.media[] 的对比

| 维度 | wan2.7-video(family router) | seedance-2.0(本方案) |
|---|---|---|
| 形态决策位置 | family router(adapter 上游)按 `media[]` 元素 type 改写真实 upstream | adapter 内部按字段非空推断上游 mode |
| 角色字段 | 复合数组 `media[{type, url}]` + 自定义 `media_array` widget | 平铺多 file_array,字段名即角色 + 标准 `multi_image_upload` |
| 用户感知 | 一个"媒体素材"区,选 type 后上传 | 多个独立的上传区(参考图 / 参考视频 / 参考音频 / 首帧 / 尾帧) |
| 何时选哪种 | 厂商把多产品线拆成不同 upstream | 厂商单 upstream 接受多种引用媒体角色 |

### 4.3a minimax-h3 / minimax-h3-max(MiniMax 视频生成 V2 — 规范键 + 形态互斥进数据,2026-09-28)

seed `docs/migrations/20260928a_minimax_h3_video_models.sql`;adapter `adapters/minimax/minimax_video.go`(与音乐分支同包,按 `endpoint_path=/v2/video_generation` 分流)。
官方原文:create / query / delete 端点、限制、错误信封与定价见 seed 文件头(2026-09-28 抓取)。

**规范键**(与 veo / seedance 同词汇,creation 的视频桥只说这套键;厂商线名 `ratio` / `first_frame` / `last_frame` 经 `api_field_name` 双写):

| key | type | 说明 |
|---|---|---|
| `prompt` | string(≤7000 字符) | 所有形态必填 |
| `duration` | enum(H3 `4..15`,H3-Max `5..15`) | 计费秒数 |
| `resolution` | enum(H3 `768P|2K`,H3-Max `480P|768P`) | 主分量分档 |
| `aspect_ratio` | enum(`adaptive` + 6 档) | t2v 必填且 ≠ adaptive(约束 `text_to_video_ratio_required`);i2v 不发(上游恒 adaptive) |
| `first_frame_image` / `last_frame_image` | file | 图生视频;末帧须配首帧 |
| `reference_images` | file_array ≤9 | 参考生视频 |
| `reference_videos` | file_array ≤3,每段 2–15 s,`max_total_duration_seconds=15` | 参考生视频 |
| `reference_audios` | file_array ≤3,每段 2–15 s,合计 ≤15 s,免费 | 参考生视频 |
| `prompt_expansion_mode` | enum `disabled|balanced|quality` | 仅 H3-Max,adapter 装进 `extra` |

**形态互斥**用 `constraints[].then.must_be_empty`(ADR-040)表达:任一 `reference_*` 非空 ⇒ `first_frame_image` 必须为空;`first_frame_image` 为空 ⇒ `last_frame_image` 必须为空。客户端按 `x-constraints` 置灰,服务端 `ValidateParams` 在冻结前拒绝,adapter 本地校验是最后防线(不发请求)。

**pricing v2 + `components[]`**(ADR-039):主分量 `video_second` 按 `resolution` 分档;`input_image`(H3 前 5 张免费超出 $0.04/张;H3-Max 前 2 张免费超出 $0.074/张)、`input_video`(按输入秒 × 输出分辩率价)、`input_audio`(显式 0 价)三个分量按 adapter 上报的 `input_image_count` / `input_seconds` / `input_audio_seconds` 求和。

**异步**:`async_strategy.mode=polling`,interval 10 s(官方推荐),max_wait 30 min;`callback_path=/v1/webhook/minimax/video` 只是声明 —— 是否向上游发 `callback_url` 由渠道 `auth_extensions.callback_base_url` 决定,回调只用于提前轮询(ADR-041),终态与产物一律以查询端点为准。`resilience.max_retries=0`(按秒计费,渠道级重发即双扣;U-4)。

**能力投影**:`ProviderAPI.ResolveVideoCapability(bid)` 从上述 schema + pricing + 渠道行读出形态 / 参考音频上限 / 时长档 / 分辩率 / 每秒单价 / 可用性(ADR-042),无代码能力表。

### 4.4 token 计费模型的 `credit_cost` 与 `pricing`(以 gemini-3.1-flash-lite 为例)

token 类模型同时返回**对客积分计费** `credit_cost`(来源 `wal_credit_pricing_rules`)与**上游成本基线** `pricing`(schema v2,`rate_kind=token`,见 §Upstream Pricing Schema v2 形态 3)。二者正交,前端展示 `credit_cost`,`pricing` 仅供内部对账:

```jsonc
{
  "credit_cost": {
    "amount": 7,
    "unit": "per_1k_tokens"
    // example_breakdown 字段当前为空 —— FindRule 仅返回 amount+unit,见 §CreditCostDTO
  }
}
```

- `credit_cost` 由 `list_models_handler` 经 `FindRule` 查 `wal_credit_pricing_rules` 得到(每 model 一次,非按 version N+1)。
- `example_breakdown` 为预留字段,当前不自动产出;非直观单位(`per_1k_tokens` / `per_megapixel`)的用户引导文案,后续随积分定价规则补充。

---

## 5. Ant Design Pro Dynamic Form Rendering

### 5.1 UI Component Mapping Table

| `x-ui-component` | Ant Design Component | Props |
|-------------------|---------------------|-------|
| `textarea` | `ProFormTextArea` | `fieldProps={{ maxLength, showCount: true }}` |
| `select` | `ProFormSelect` | `options` built from `enum` + `x-enum-labels` |
| `radio_group` | `ProFormRadio.Group` | `options` built from `enum` + `x-enum-labels` |
| `switch` | `ProFormSwitch` | Default from `default` |
| `number_input` | `ProFormDigit` | `min`, `max`, `fieldProps={{ step }}` |
| `slider` | `ProFormSlider` | `min`, `max`, `step` |
| `image_upload` | `ProFormUploadButton` | `accept` from `x-accept`, `max` from `x-max-size-mb` |
| `multi_image_upload` | `ProFormUploadDragger` | `accept`, `maxCount=maxItems`, `maxFileSize`(历史 Veo 系列曾用别名 `image_multi_upload`,DB 数据已统一为 `multi_image_upload`,前端可移除别名映射)|
| `image_selector` | Custom `ImageSelector` | Card grid with preview images from `x-enum-previews` (历史名 `style_grid` 已统一为 `image_selector`) |
| `media_array` | Custom `MediaReferenceField` | 多角色媒体组件,**角色目录机读自 `x-roles`(含 kind/label/max_items/accept/default),严禁按 model 文档人工枚举**(CRC v2 role_kind 切片治本)。渲染形态由 `x-roles[].kind` 数据驱动:全 tag → 统一上传区+角标;含 slot → 每槽独立入口(tag 池化);有 `x-role-modes` → 模式切换器。`url` 走 `/v1/uploads/sign` 直传 R2,提交 `[{role, url}]`;`maxItems` 限制总数,每角色上限 `x-roles[].max_items`。规则矩阵见 §3.7 |
| `speakers_editor` | Custom `SpeakersEditor` | 行编辑器:基于 `items.properties` 渲染 `{speaker: text, voice_name: select}`;`voice_name.options` 通过 `x-options-ref` 复用顶层 `voice_name` 字段的 enum。`maxItems` 限制行数;前端可回落到 JSON 文本框作为兜底 |
| `file_upload` | `ProFormUploadButton` | 通用文件直传(非图片专用),`accept` 来自 `x-accept`(如 `["video/mp4"]` / `["audio/mp3"]`)|

### 5.2 Complete Dynamic Form Component

```tsx
// src/components/ParamSchemaForm/index.tsx
import React, { useMemo, useState } from 'react';
import {
  ProForm,
  ProFormText,
  ProFormTextArea,
  ProFormSelect,
  ProFormRadio,
  ProFormSwitch,
  ProFormDigit,
  ProFormSlider,
  ProFormUploadButton,
  ProFormGroup,
} from '@ant-design/pro-components';
import { Tabs, Card } from 'antd';

interface ParamSchemaFormProps {
  schema: Record<string, any>;
  presets?: Array<{
    preset_bid: string;
    preset_name: string;
    preset_name_zh?: string;
    preview_url?: string;
    param_values: Record<string, any>;
    is_default: boolean;
  }>;
  locale?: 'en' | 'zh';
  onFinish: (values: Record<string, any>) => void;
}

export default function ParamSchemaForm({
  schema,
  presets,
  locale = 'zh',
  onFinish,
}: ParamSchemaFormProps) {
  const [formRef] = ProForm.useForm();
  const [formValues, setFormValues] = useState<Record<string, any>>({});

  // Parse groups from x-groups extension
  const groups = useMemo(() => {
    const xGroups = schema['x-groups'] as Array<{
      key: string;
      label: Record<string, string>;
      sort: number;
    }> | undefined;

    if (!xGroups) return [{ key: '_default', label: 'Parameters', sort: 0 }];
    return xGroups
      .map((g) => ({ key: g.key, label: g.label[locale] || g.label['en'] || g.key, sort: g.sort }))
      .sort((a, b) => a.sort - b.sort);
  }, [schema, locale]);

  // Parse properties and sort by x-sort-order
  const fieldsByGroup = useMemo(() => {
    const properties = schema.properties || {};
    const required = new Set(schema.required || []);
    const result: Record<string, Array<any>> = {};

    Object.entries(properties).forEach(([key, prop]: [string, any]) => {
      const group = prop['x-group'] || '_default';
      if (!result[group]) result[group] = [];
      result[group].push({
        key,
        ...prop,
        isRequired: required.has(key),
        sortOrder: prop['x-sort-order'] ?? 999,
      });
    });

    // Sort each group's fields
    Object.values(result).forEach((fields) => fields.sort((a, b) => a.sortOrder - b.sortOrder));
    return result;
  }, [schema]);

  // Check if a field should be visible based on x-conditions
  const isFieldVisible = (field: any): boolean => {
    const conditions = field['x-conditions'] as Array<{
      when: string; eq: any; action: string;
    }> | undefined;

    if (!conditions || conditions.length === 0) return true;

    for (const cond of conditions) {
      const currentValue = formValues[cond.when];
      const matches = Array.isArray(cond.eq)
        ? cond.eq.includes(currentValue)
        : currentValue === cond.eq;

      if (cond.action === 'show' && !matches) return false;
      if (cond.action === 'hide' && matches) return false;
    }
    return true;
  };

  // Get label in current locale
  const getLabel = (field: any): string => {
    const xLabel = field['x-label'];
    if (xLabel) return xLabel[locale] || xLabel['en'] || field.title || field.key;
    return field.title || field.key;
  };

  // Get placeholder in current locale
  const getPlaceholder = (field: any): string | undefined => {
    const xPlaceholder = field['x-placeholder'];
    if (xPlaceholder) return xPlaceholder[locale] || xPlaceholder['en'];
    return undefined;
  };

  // Build enum options with i18n labels
  const buildEnumOptions = (field: any) => {
    const enumValues = field.enum || [];
    const labels = field['x-enum-labels'] || {};
    return enumValues.map((value: string) => ({
      value,
      label: labels[value]?.[locale] || labels[value]?.['en'] || value,
    }));
  };

  // Render a single field based on x-ui-component
  const renderField = (field: any) => {
    if (!isFieldVisible(field)) return null;

    const commonProps = {
      name: field.key,
      label: getLabel(field),
      tooltip: field['x-description']?.[locale] || field.description,
      placeholder: getPlaceholder(field),
      required: field.isRequired,
      initialValue: field.default,
    };

    const component = field['x-ui-component'];

    switch (component) {
      case 'textarea':
        return (
          <ProFormTextArea
            key={field.key}
            {...commonProps}
            fieldProps={{
              maxLength: field.maxLength,
              showCount: true,
              autoSize: { minRows: 3, maxRows: 8 },
            }}
          />
        );

      case 'select':
        return (
          <ProFormSelect
            key={field.key}
            {...commonProps}
            options={buildEnumOptions(field)}
          />
        );

      case 'radio_group':
        return (
          <ProFormRadio.Group
            key={field.key}
            {...commonProps}
            options={buildEnumOptions(field)}
          />
        );

      case 'switch':
        return (
          <ProFormSwitch
            key={field.key}
            {...commonProps}
          />
        );

      case 'number_input':
        return (
          <ProFormDigit
            key={field.key}
            {...commonProps}
            min={field.minimum}
            max={field.maximum}
            fieldProps={{ step: field.multipleOf || 1 }}
          />
        );

      case 'slider':
        return (
          <ProFormSlider
            key={field.key}
            {...commonProps}
            min={field.minimum}
            max={field.maximum}
            step={field.multipleOf || 1}
          />
        );

      case 'image_upload':
      case 'multi_image_upload':
        // 走平台通用直传 (presigned PUT 双段式):
        //   1. POST /v1/uploads/sign → put_url + public_url
        //   2. PUT put_url with file bytes (Content-Type 必须与 sign 时一致)
        //   3. 表单值存 public_url 字符串 (单图) / string[] (多图)
        // 详见 docs/api/overview.md §11 + docs/api/creation.md POST /v1/uploads/sign
        return (
          <ProFormUploadButton
            key={field.key}
            {...commonProps}
            max={component === 'multi_image_upload' ? 4 : 1}
            fieldProps={{
              accept: (field['x-accept'] || []).join(','),
              maxCount: component === 'multi_image_upload' ? 4 : 1,
              listType: 'picture-card',
              // 关键: customRequest 接管上传, 不走默认 multipart POST
              customRequest: async ({ file, onSuccess, onError, onProgress }) => {
                try {
                  // 大小预检 (后端 UploadPolicy 也会校验, 这里提早反馈)
                  const maxSizeMB = field['x-max-size-mb'] || 50;
                  if ((file as File).size / 1024 / 1024 > maxSizeMB) {
                    throw new Error(`文件超过 ${maxSizeMB} MB`);
                  }
                  // 1. 调签名端点
                  const signResp = await request('/v1/uploads/sign', {
                    method: 'POST',
                    data: {
                      mime_type: (file as File).type,
                      size: (file as File).size,
                      filename: (file as File).name,
                    },
                  });
                  if (signResp.code !== 0) throw new Error(signResp.message);
                  const { put_url, public_url } = signResp.data;

                  // 2. 直传 R2 (Content-Type 必须与 sign 时一致, 否则 403)
                  await fetch(put_url, {
                    method: 'PUT',
                    headers: { 'Content-Type': (file as File).type },
                    body: file as File,
                  }).then((r) => {
                    if (!r.ok) throw new Error(`R2 PUT failed: ${r.status}`);
                  });

                  // 3. 回填: 表单字段值 = public_url
                  //    Ant Design Upload 通过 onSuccess 回调把 url 字段写入 fileList
                  onSuccess?.({ url: public_url }, file as any);
                  onProgress?.({ percent: 100 } as any);
                } catch (err: any) {
                  onError?.(err);
                  message.error(err?.message ?? '上传失败');
                }
              },
              // 提交时把 fileList 转成 public_url 字符串数组传给后端
              transform: (fileList: any[]) => {
                const urls = (fileList || []).map((f) => f.url || f.response?.url).filter(Boolean);
                return component === 'multi_image_upload' ? urls : urls[0] || '';
              },
            }}
            title={locale === 'zh' ? '上传图片' : 'Upload'}
          />
        );

      default:
        // Fallback: plain text input
        return (
          <ProFormText
            key={field.key}
            {...commonProps}
          />
        );
    }
  };

  // Apply a preset's param_values to the form
  const applyPreset = (paramValues: Record<string, any>) => {
    formRef.setFieldsValue(paramValues);
    setFormValues((prev) => ({ ...prev, ...paramValues }));
  };

  return (
    <Card>
      {/* Preset selector */}
      {presets && presets.length > 0 && (
        <div style={{ marginBottom: 16, display: 'flex', gap: 8 }}>
          {presets.map((preset) => (
            <Card.Grid
              key={preset.preset_bid}
              style={{ width: 120, cursor: 'pointer', textAlign: 'center', padding: 8 }}
              onClick={() => applyPreset(preset.param_values)}
            >
              {preset.preview_url && (
                <img src={preset.preview_url} alt={preset.preset_name} style={{ width: '100%', borderRadius: 4 }} />
              )}
              <div style={{ fontSize: 12, marginTop: 4 }}>
                {preset.preset_name_zh || preset.preset_name}
              </div>
            </Card.Grid>
          ))}
        </div>
      )}

      <ProForm
        form={formRef}
        onValuesChange={(_, allValues) => setFormValues(allValues)}
        onFinish={onFinish}
      >
        {groups.length > 1 ? (
          <Tabs items={groups.map((group) => ({
            key: group.key,
            label: group.label,
            children: (
              <ProFormGroup>
                {(fieldsByGroup[group.key] || []).map(renderField)}
              </ProFormGroup>
            ),
          }))} />
        ) : (
          <ProFormGroup>
            {Object.values(fieldsByGroup).flat().map(renderField)}
          </ProFormGroup>
        )}
      </ProForm>
    </Card>
  );
}
```

### 5.3 Usage in a Page

```tsx
// src/pages/Create/index.tsx
import { useRequest } from '@umijs/max';
import { message, Select } from 'antd';
import ParamSchemaForm from '@/components/ParamSchemaForm';

export default function CreatePage() {
  const { data: modelsResponse } = useRequest(() =>
    request('/v1/models?media_type=image')
  );

  const [selectedVersion, setSelectedVersion] = useState<any>(null);

  const models = modelsResponse?.data?.models || [];

  // Flatten versions for selection
  const versionOptions = models.flatMap((model: any) =>
    model.versions.map((v: any) => ({
      label: `${model.model_name?.zh || model.model_name?.en} - ${v.version_name}`,
      value: v.version_bid,
      version: v,
    }))
  );

  return (
    <div>
      <Select
        style={{ width: 400, marginBottom: 16 }}
        placeholder="选择模型版本"
        options={versionOptions}
        onChange={(bid) => {
          const opt = versionOptions.find((v: any) => v.value === bid);
          setSelectedVersion(opt?.version);
        }}
      />

      {selectedVersion && (
        <>
          {/* Credit cost display */}
          {selectedVersion.credit_cost && (
            <div style={{ marginBottom: 16 }}>
              消耗: {selectedVersion.credit_cost.amount} 积分 / {selectedVersion.credit_cost.unit}
              {/* estimate_ms 永远存在 (P6-02 起 sync/async 都有) — 直接显示 */}
              {selectedVersion.estimate_ms > 0 && ` (预计 ${Math.round(selectedVersion.estimate_ms / 1000)}s)`}
            </div>
          )}

          <ParamSchemaForm
            schema={selectedVersion.param_schema}
            presets={selectedVersion.presets}
            onFinish={async (values) => {
              const res = await request('/v1/tasks', {
                method: 'POST',
                data: {
                  version_bid: selectedVersion.version_bid,
                  params: values,
                },
              });
              if (res.code === 0) {
                message.success('任务已提交');
              }
            }}
          />
        </>
      )}
    </div>
  );
}
```

### 5.4 BetaSchemaForm Alternative

For simpler cases, you can convert the param_schema to Ant Design's `BetaSchemaForm` column format:

```typescript
// src/utils/schemaToColumns.ts
import type { ProFormColumnsType } from '@ant-design/pro-components';

const componentMap: Record<string, string> = {
  textarea: 'textarea',
  select: 'select',
  radio_group: 'radio',
  switch: 'switch',
  number_input: 'digit',
  slider: 'slider',
  image_upload: 'upload',
  multi_image_upload: 'upload',
};

export function schemaToColumns(
  schema: Record<string, any>,
  locale: string = 'zh',
): ProFormColumnsType[] {
  const properties = schema.properties || {};
  const required = new Set(schema.required || []);

  return Object.entries(properties)
    .map(([key, prop]: [string, any]) => {
      const xLabel = prop['x-label'];
      const label = xLabel?.[locale] || xLabel?.['en'] || prop.title || key;

      const column: ProFormColumnsType = {
        dataIndex: key,
        title: label,
        tooltip: prop['x-description']?.[locale] || prop.description,
        valueType: componentMap[prop['x-ui-component']] || 'text',
        initialValue: prop.default,
        formItemProps: {
          rules: required.has(key) ? [{ required: true }] : undefined,
        },
      };

      // Enum options
      if (prop.enum) {
        const labels = prop['x-enum-labels'] || {};
        column.valueEnum = Object.fromEntries(
          prop.enum.map((v: string) => [
            v,
            { text: labels[v]?.[locale] || labels[v]?.['en'] || v },
          ])
        );
      }

      // Number constraints
      if (prop.minimum !== undefined) {
        column.fieldProps = { ...column.fieldProps, min: prop.minimum };
      }
      if (prop.maximum !== undefined) {
        column.fieldProps = { ...column.fieldProps, max: prop.maximum };
      }

      return {
        ...column,
        order: prop['x-sort-order'] ?? 999,
        group: prop['x-group'],
      };
    })
    .sort((a: any, b: any) => (a.order ?? 999) - (b.order ?? 999));
}
```

Usage:

```tsx
import { BetaSchemaForm } from '@ant-design/pro-components';
import { schemaToColumns } from '@/utils/schemaToColumns';

<BetaSchemaForm
  columns={schemaToColumns(versionDTO.param_schema)}
  onFinish={handleSubmit}
/>
```

### 5.5 File Upload Integration (presigned PUT)

> 来源: `internal/creation/port/http/upload_handler.go::SignUpload` · `internal/creation/app/command/request_upload_url_handler.go` · `internal/creation/domain/service/upload_policy.go`. 端点契约见 [creation.md POST /v1/uploads/sign](creation.md#post-v1uploadssign)。

ParamSchemaForm 文件参数(`x-ui-component=image_upload` / `multi_image_upload`)的上传链路是**两段式**(BFF 仅签名 → 客户端直传 R2)。**不要**用 multipart POST 把文件上传到本平台后端。

#### 5.5.1 复用 Hook(推荐)

把签名+直传逻辑抽成 hook,所有需要文件上传的页面共享:

```typescript
// src/hooks/useUploadFile.ts
import { request } from '@umijs/max';
import { message } from 'antd';

export interface UploadResult {
  publicUrl: string;
  key: string;
  expiresAt: number;
}

/**
 * sign+finalize 直传 hook —— 用于"瞬态"文件输入
 * (ParamSchemaForm 文件参数 / 临时 RAG 文档 / 任务参考图等)
 *
 * ⚠️ 用户素材库 (头像 / 文档持久化) 应走 POST /v1/assets/upload
 *    服务端 multipart 通道, 直接落 gen_assets, 不走 sign+finalize 双段式.
 *
 * 流程:
 *   1. POST /v1/uploads/sign     → 拿 bid + put_url + public_url
 *   2. PUT  put_url              → 直传 R2 (Content-Type 必须一致)
 *   3. POST /v1/uploads/finalize → 提交 bid, 把 pending Asset 转 uploaded
 *   4. 返回 publicUrl 给调用方回填到表单 / 任务参数
 */
export async function uploadFile(file: File): Promise<UploadResult> {
  // Step 1: 签名
  const sign = await request<{
    code: number;
    message: string;
    data: { put_url: string; public_url: string; expires_at: number; key: string };
  }>('/v1/uploads/sign', {
    method: 'POST',
    data: {
      mime_type: file.type,
      size: file.size,
      filename: file.name,
    },
  });
  if (sign.code !== 0) {
    // 40034 不支持的文件类型 / 40035 文件大小超过限制 / 50100 storage 后端不支持直传
    throw new Error(sign.message);
  }
  const { put_url, public_url, expires_at, key } = sign.data;

  // Step 2: 直传 R2 (浏览器原生 fetch, 不走 umi request 拦截器避免被注入 Authorization)
  const putResp = await fetch(put_url, {
    method: 'PUT',
    headers: { 'Content-Type': file.type }, // ★ 必须与 sign 时一致, 否则 R2 403
    body: file,
  });
  if (!putResp.ok) {
    throw new Error(`R2 直传失败: ${putResp.status} ${putResp.statusText}`);
  }

  return { publicUrl: public_url, key, expiresAt: expires_at };
}

/**
 * 适配 Ant Design Upload 的 customRequest 形态
 * 用于 ProFormUploadButton / ProFormUploadDragger 接管默认上传行为
 */
export function makeAntdCustomRequest() {
  return async ({ file, onSuccess, onError, onProgress }: any) => {
    try {
      const { publicUrl } = await uploadFile(file as File);
      onProgress?.({ percent: 100 });
      onSuccess?.({ url: publicUrl }, file);
    } catch (err: any) {
      onError?.(err);
      message.error(err?.message ?? '上传失败');
    }
  };
}
```

#### 5.5.2 在 ParamSchemaForm 中使用

`5.2` 的 `image_upload` / `multi_image_upload` case 已用 `customRequest` 接入此流程。如果你的 form 用 `BetaSchemaForm` 或自定义 Form,**自己接 hook**:

```tsx
import { ProFormUploadButton } from '@ant-design/pro-components';
import { makeAntdCustomRequest } from '@/hooks/useUploadFile';

<ProFormUploadButton
  name="reference_image"
  label="参考图"
  fieldProps={{
    accept: 'image/jpeg,image/png,image/webp',
    customRequest: makeAntdCustomRequest(),
    maxCount: 1,
  }}
  // 提交时只取 public_url 字符串
  transform={(fileList: any[]) => fileList?.[0]?.url ?? fileList?.[0]?.response?.url ?? ''}
/>
```

#### 5.5.3 后端如何使用 public_url

`public_url` 是 R2 公网可达的 CDN URL。前端把它作为参数字段值传给 `POST /v1/tasks`:

```json
POST /v1/tasks
{
  "model_version_bid": "uuid",
  "params": {
    "prompt": "make this image cinematic",
    "reference_image": "https://r2.showsapp.org/uploads/0/0193b9a0-7c8d-7e3f-9a01-abcdef012345/2026/05/26/01988f30-1234-7e3f-9a01-bbbbbbbbbbbb.png"
  }
}
```

后端 `SubmitTaskHandler` 把 `params` 透传给 Provider Adapter,上游 SDK(Gemini / Runway / DashScope)接受公网可达 URL 作为输入,**无需平台再做一次中转下载/上传**。

#### 5.5.4 常见错误码

| HTTP `code` | 含义 | 前端处理建议 |
|---|---|---|
| `40033` | 参数缺失 (mime_type / size / filename 任一空值) | 检查 File 对象 |
| `40034` | 不支持的文件类型 | 提示用户改格式;`x-accept` 应在前端预检 |
| `40035` | 文件大小超过限制(默认 50 MiB) | 提示用户压缩;`x-max-size-mb` 应预检 |
| `50100` | 当前存储后端不支持直传(`storage.provider=local`) | 联系后端切到 `r2` 模式,或本地开发自行处理 |
| R2 `403` | PUT 时 Content-Type 不一致或签名过期 | 检查 `Content-Type` header,5min TTL 内完成 PUT |
| R2 `0`/CORS | 桶 CORS 未配置 | 联系运维补 `PUT` allowed methods + `Content-Type` allowed headers |

#### 5.5.5 注意事项

- ✅ **public_url 长期有效**(R2 桶公开读,默认保留 30 天后由 lifecycle policy 清理)
- ✅ **多文件**: `multi_image_upload` 时表单值是 `string[]`,逐个调 `uploadFile` 并收集结果
- ❌ **不要存 put_url 到表单**: 它含签名,5 min 后失效
- ❌ **不要复用 put_url**: 一个签名只能 PUT 一次,需要换文件请重新调 `/v1/uploads/sign`
- ❌ **不要把 R2 直传请求经过 umi `request` 拦截器**: 否则会被加 `Authorization` header,导致 R2 签名校验失败。**必须用浏览器原生 `fetch`**

---

## 6. Family Router(模型家族路由)

> 来源:`internal/provider/infra/gateway/family_routers/` · `internal/provider/infra/gateway/family_router_decorator.go`

某些厂商把一个用户视角的逻辑模型(如 "Wan 2.7 视频生成")拆成多个真实上游模型(`wan2.7-t2v` / `-i2v` / `-r2v`),分别对应不同输入模式。Family Router 让前端**只看到 1 个 model_version_bid**,后端按用户提交的 params 自动决定真实 upstream。

### 6.1 工作机制

```
ProviderCallService.Execute
  → port.AIGateway (接口)
      ↓ Fx fx.Decorate
  → FamilyRouterDecorator                    (横切: 哨兵改写)
      ↓ inner
  → AIGatewayImpl                             (路由到具体 ProviderAdapter)
      ↓
  → ResilientAdapter(DashScopeAdapter)        (横切: retry + circuit breaker)
      ↓
  → DashScope API
```

`FamilyRouterDecorator.applyRouting`:
```go
router, ok := family_routers.Lookup(req.UpstreamModelID)
if !ok { return }  // 99% 模型走这里, 零开销直传
realID, realPath := router.Resolve(req.Params)
req.UpstreamModelID = realID
req.EndpointPath    = realPath
```

### 6.2 当前已注册家族

| 哨兵 `upstream_model_id` | 路由依据 | 真实 upstream | Router 实现 |
|---|---|---|---|
| `wan2.7-video` | `params.media[]` 元素 type | `wan2.7-t2v` / `-i2v` / `-r2v` | `family_routers/wan27_video/router.go` |

#### Wan 2.7 视频路由判定

| `params.media[]` 内容 | 真实 upstream |
|---|---|
| 缺失 / 空数组 / 全部非 map 元素 | `wan2.7-t2v`(文生视频) |
| 含任一 `{type: reference_image}` 或 `{type: reference_video}` | `wan2.7-r2v`(参考生视频)— **优先级最高** |
| 其他(`first_frame` / `last_frame` / `first_clip` / `driving_audio` / 未知 type) | `wan2.7-i2v`(图生视频) |

> 优先级原则:**reference > image > text**。即 `media[]` 同时含 `first_frame` 与 `reference_image` → 走 r2v(reference 是 r2v 的特征字段;first_frame 在 r2v 也合法)。

#### wan2.7-video `media[]` 前端渲染契约

调 `GET /v1/models?media_type=video` 在 `wan2.7-video` 的 `param_schema.properties.media` 字段拿到:

```jsonc
{
  "media": {
    "type": "array",
    "maxItems": 5,
    "x-ui-component": "media_array",
    "x-label":       { "en": "Media (optional)", "zh": "媒体素材 (可选)" },
    "x-hint":        { "zh": "留空=文生视频; 含 first_frame/last_frame/first_clip/driving_audio=图生视频; 含 reference_image/reference_video=参考生视频" },
    "x-group":       "basic"
  }
}
```

前端 `MediaArrayEditor` 渲染要点:
- **行数上限**:取 `maxItems`(当前 5);
- **每行结构**:`{ type: enum, url: string }`(`url` 走 `/v1/uploads/sign` 直传 R2 后回填 public_url);
- **type enum 列表**:由前端按本节路由表硬编码(`first_frame` / `last_frame` / `first_clip` / `driving_audio` / `reference_image` / `reference_video`),无需后端下发(family router 文档已说明语义)。
- **Hint 文案**:直接渲染 `x-hint.zh` 即可,产品已写明 t2v / i2v / r2v 触发条件。
- **零行**:不阻塞提交 — 后端会路由到 t2v(纯文生视频)。

### 6.3 添加新家族

厂商再来一个产品线分裂(如未来 veo4 拆 t2v/i2v):

1. `family_routers/veo4_video/router.go` 实现 `Router` 接口
2. 在 `init()` 调 `family_routers.Register(router{})`
3. `internal/provider/fx_module.go` 加 blank import:`_ "genaistudio/internal/provider/infra/gateway/family_routers/veo4_video"`
4. DB 把 `prov_model_versions.upstream_model_id` 设为家族哨兵(如 `veo4-video`)
5. 合并 `param_schema`,标可选字段 + `x-conditions` 控制可见

**adapter 层零改动**。

### 6.4 设计权衡

| 备选方案 | 拒绝原因 |
|---|---|
| `platform_params.input_mode_routing` JSONB 配置 | 抽象泄漏(通用字段承载厂商语义)+ 类型不安全(JSONB 无校验)+ 调试两处对照 |
| 哨兵 `upstream_model_id` + adapter 内 const | 单一职责违反(adapter 学了产品线知识)+ 多家族扩展时 adapter 膨胀 |
| 域 service `model_family` 字段 | 单家族过度设计(加 column 成本不对等) |
| Decorator(本方案) | ✅ 与项目 `ResilientAdapter` 同构 + adapter 纯净 + 注册表水平扩展 |

---

## OpenAPI 3.1 Specification

> 基于代码事实生成,sub-agent 独立扫描 + 交叉校验。来源:
> - `internal/provider/port/http/{routes,model_handler,admin_router_handler,admin_cache_handler}.go`
> - `internal/provider/app/dto/model.go` (ModelDTO / VersionDTO / PresetDTO 等)
> - `internal/provider/app/query/list_models_handler.go` (param_schema 转换 + credit_cost FindRule + pricing v2 ParsePricing)
> - `internal/provider/domain/pricing.go` (PricingInfo schema v2 强类型 + Validate)
> - `internal/provider/app/command/router_rule_handlers.go` (Cmd struct)
> - `internal/provider/domain/router/{rule,types}.go` (RuleStatus / RuleConditions / RetryPolicy)
> - `internal/provider/domain/errors.go::GetErrorCode`
>
> 公共契约(BaseURL / Headers / 鉴权 / 签名 / Envelope / 错误码)见 [overview.md](overview.md)。

```yaml
openapi: 3.1.0
info:
  title: AIGC Platform — Provider Domain API
  description: |
    Provider BC 暴露 (8 endpoints):
      - 模型目录: GET /v1/models (param_schema + 预设 + 计费 + 异步策略)
      - Router rule admin: 6 endpoints (CRUD + reload, P1-03 Phase A)
      - SemanticCache: DELETE /v1/admin/provider/cache/:tenant_id (P1-03 Phase C)

    模型动态参数 param_schema 是 JSON Schema draft-07 子集 + x-extensions,
    校验内核是手写 ParamValidator (无三方依赖).
  version: "1.0.0"

servers:
  - url: https://api.aigc.example.com/v1
    description: Production
  - url: http://localhost:9999/v1
    description: Local dev

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
    DistributionCode:
      type: apiKey
      in: header
      name: X-Distribution-Code
    Timestamp:
      type: apiKey
      in: header
      name: X-Timestamp
    Nonce:
      type: apiKey
      in: header
      name: X-Nonce
    AppSignature:
      type: apiKey
      in: header
      name: X-App-Signature

  schemas:
    StandardResponse:
      type: object
      required: [code, message, request_id, timestamp]
      properties:
        code:
          type: integer
          example: 0
        message:
          type: string
          example: success
        data:
          description: 业务载荷
        request_id:
          type: string
          format: uuid
        timestamp:
          type: integer
          format: int64

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
        request_id:
          type: string
        timestamp:
          type: integer
          format: int64

    # ── /v1/models DTO ── (来源 app/dto/model.go)

    AsyncStrategyDTO:
      type: object
      properties:
        mode:
          type: string
          enum: [polling, webhook, sse]
        interval_ms:
          type: integer
          description: 建议轮询间隔(毫秒)
        max_wait_ms:
          type: integer
          description: 最大等待时间(毫秒)

    CreditCostDTO:
      type: object
      required: [amount, unit]
      description: |
        平台积分计费, 来源 wal_credit_pricing_rules (经 PricingRuleRepository.FindRule, 非 pricing).
        amount <= 0 时返回 null (免费/未配规则); 客户端不再从 pricing 解析积分 (pricing 仅上游成本基线).
      properties:
        amount:
          type: integer
          format: int64
        unit:
          type: string
          enum: [per_request, per_1k_tokens, per_second, per_megapixel]

    PresetDTO:
      type: object
      required: [preset_bid, preset_code, preset_name, param_values, is_default]
      properties:
        preset_bid:
          type: string
          format: uuid
        preset_code:
          type: string
        preset_name:
          type: string
        preset_name_zh:
          type: string
        description:
          type: string
        preview_url:
          type: string
          format: uri
        param_values:
          type: object
          additionalProperties: true
        is_default:
          type: boolean

    VersionDTO:
      type: object
      required: [version_bid, version_code, version_name, param_schema, is_async, status]
      properties:
        version_bid:
          type: string
          format: uuid
        version_code:
          type: string
        version_name:
          type: string
        capability_label:
          type: string
          description: 能力入口标签 (如 "文生视频" / "图生视频")
        release_note:
          type: string
        param_schema:
          type: object
          additionalProperties: true
          description: |
            JSON Schema draft-07 + x-extensions (freeform).
            从 prov_model_versions.param_schema (自定义格式) 经 ToJSONSchema() 转换得到.
            ★ 始终非空 (即使为 {} 也会返回, 不会是 null).
            ★ 面向用户的文本节点 (label/description/placeholder/hint/enum-labels) 均为
              {en,zh} 双语对象 (见 x- 扩展字段); 标准 title/description 取 en. 详见 §3.0.
        output_schema:
          type: object
          additionalProperties: true
          nullable: true
          description: ⚠️ 当前总是 null (代码事实, Phase B 留作扩展位)
        is_async:
          type: boolean
          description: 从 async_strategy 是否非空判断
        estimate_ms:
          type: integer
          description: 从 async_strategy.max_wait_ms / 2 计算
        async_strategy:
          $ref: '#/components/schemas/AsyncStrategyDTO'
          nullable: true
        credit_cost:
          $ref: '#/components/schemas/CreditCostDTO'
          nullable: true
        pricing:
          type: object
          additionalProperties: true
          description: |
            上游供应商计费, schema v2 强类型正交结构 (见 §Upstream Pricing Schema v2).
            顶层: schema_version=2 / currency / source / metering{unit,...} / rate_kind / dimensions[] / rates[] + 修饰字段.
            不含任何平台积分字段 (credit_usd_rate / credit_cost_* 已彻底移除).
        presets:
          type: array
          items:
            $ref: '#/components/schemas/PresetDTO'
        status:
          type: string
          enum: [published, canary, deprecated, offline]
          description: |
            ★ 修正自代码事实 (domain/repository.ModelVersion.Status).
            之前 OpenAPI 写的 active/deprecated/draft 不准确.

    ModelDTO:
      type: object
      required: [model_bid, model_code, model_name, media_type, task_type, versions]
      properties:
        model_bid:
          type: string
          format: uuid
        provider_code:
          type: string
        model_code:
          type: string
        model_name:
          type: object
          description: i18n 名称对象 {en, zh}(原 model_name + model_name_zh 已合并)
          properties:
            en: { type: string }
            zh: { type: string }
        logo_url:
          type: string
          format: uri
        showcase_url:
          type: string
          format: uri
        description:
          type: object
          description: i18n 描述对象 {en, zh};营销文案,不含具体供应商价格
          properties:
            en: { type: string }
            zh: { type: string }
        media_type:
          type: string
          enum: [image, video, audio, text, multimodal, code]
        task_type:
          type: string
          description: |
            归一化值 (text_gen / image_gen / video_gen / audio_gen ...).
            ⚠️ 注: 这是 Provider 内部归一化值 (ModelInfo.TaskType),
            与 Creation 的 gen_generation_tasks.task_type 同一枚举体系,
            但与 prov_models.task_type 原值 (txt2video 等) 不同.
        capability_tags:
          type: array
          items:
            type: string
        supported_features:
          type: array
          items:
            type: string
        display_tags:
          type: array
          items:
            type: string
            enum: [hot, new, best_value, limited]
          description: |
            运营标签, 词表固定 4 值 (prov_models.display_tags 列注释即权威):
            hot=品类内近30天用量断层第一 / new=新接入批次 /
            best_value=品类内 default 档积分单价最低 / limited=限时限量(暂未启用).
            空数组时字段整体省略 (omitempty). 回填判据见迁移 20260824a.
        sort_order:
          type: integer
          default: 0
          description: |
            排序权重 (prov_models.sort_order). Repository 按 sort_order ASC, id ASC 排序
            (2026-08-24 起 id 二级键钉死同值行次序, 不再随 PG 物理顺序漂移);
            数值越小越靠前, 默认 0.
        versions:
          type: array
          items:
            $ref: '#/components/schemas/VersionDTO'

    ListModelsResponse:
      type: object
      required: [models, total]
      properties:
        models:
          type: array
          items:
            $ref: '#/components/schemas/ModelDTO'
        total:
          type: integer

    # ── Router Rule DTO ── (来源 domain/router/{rule,types}.go + admin_router_handler.go)

    RuleConditions:
      type: object
      description: |
        路由规则匹配条件 (AND 语义).
        来源 domain/router/types.go::RuleConditions (9 字段).
        所有字段都是可选; 命中需要 RouteRequest 满足所有非零字段.
      properties:
        semantic_tag:
          type: string
          description: 精确匹配 RouteRequest.SemanticTag (code / chat / reasoning / extraction / creative)
        max_context_tokens:
          type: integer
          description: ContextTokens 上限 (含)
        min_context_tokens:
          type: integer
          description: ContextTokens 下限 (含)
        latency_sla:
          type: string
          enum: [fast, standard, batch]
        budget_max_cents:
          type: integer
          format: int64
          description: 请求预算上限 (cents)
        requires_tools:
          type: boolean
          description: 要求 tool calling 能力
        requires_json:
          type: boolean
          description: 要求 JSON 输出能力
        tenant_id_in:
          type: array
          items:
            type: integer
            format: int64
          description: 允许的租户列表 (空 = 全部租户都命中)
        not_semantic_tag_in:
          type: array
          items:
            type: string
          description: 排除的标签列表 (黑名单)

    RetryPolicy:
      type: object
      description: 来源 domain/router/types.go::RetryPolicy
      properties:
        max_retries:
          type: integer
        backoff_ms:
          type: integer
          description: 指数退避基数(毫秒)
        timeout_ms:
          type: integer
          description: 单次请求超时(毫秒)

    CreateRouterRuleRequest:
      type: object
      required: [tenant_id, name, primary_model_version_bid]
      properties:
        tenant_id:
          type: integer
          format: int64
          description: 0 = 平台全局规则; >0 = 租户级
        name:
          type: string
        description:
          type: string
        priority:
          type: integer
          description: 数值大优先级高(冲突时); 默认 100
        conditions:
          $ref: '#/components/schemas/RuleConditions'
        primary_model_version_bid:
          type: string
          format: uuid
        fallback_chain:
          type: array
          items:
            type: string
            format: uuid
        retry_policy:
          $ref: '#/components/schemas/RetryPolicy'

    UpdateRouterRuleRequest:
      type: object
      description: |
        全部字段可选, 不传不修改.
        ⚠️ Nullable 策略不对称 (代码事实, 见 admin_router_handler.go:69-78):
          - 标量 (name/description/priority/status/primary_model_version_bid): 指针 *T
          - 集合 (fallback_chain): *[]string (可表达"清空")
          - 对象 (conditions/retry_policy): map (检 len > 0 判修改意图)
      properties:
        name:
          type: string
        description:
          type: string
        priority:
          type: integer
        status:
          type: string
          enum: [enabled, disabled, archived]
          description: ★ 含 archived (代码事实, domain/router/rule.go:16 RuleStatus 三值枚举)
        conditions:
          $ref: '#/components/schemas/RuleConditions'
        primary_model_version_bid:
          type: string
          format: uuid
        fallback_chain:
          type: array
          items:
            type: string
            format: uuid
        retry_policy:
          $ref: '#/components/schemas/RetryPolicy'

    RouterRuleDTO:
      type: object
      required: [bid, tenant_id, name, priority, status, primary_model_version_bid, version]
      properties:
        bid:
          type: string
          format: uuid
        tenant_id:
          type: integer
          format: int64
        name:
          type: string
        description:
          type: string
        priority:
          type: integer
        status:
          type: string
          enum: [enabled, disabled, archived]
        conditions:
          $ref: '#/components/schemas/RuleConditions'
          nullable: true
          description: 仅 r.Conditions != nil 时序列化
        primary_model_version_bid:
          type: string
          format: uuid
        fallback_chain:
          type: array
          items:
            type: string
            format: uuid
        retry_policy:
          $ref: '#/components/schemas/RetryPolicy'
          nullable: true
          description: 仅非零值时序列化 (zeroPolicy 检查)
        version:
          type: integer
          description: 乐观锁版本号

paths:
  /models:
    get:
      summary: 查询可用模型能力 (暴露 param_schema 给前端表单)
      operationId: listModels
      tags: [Catalog]
      parameters:
        - name: media_type
          in: query
          schema:
            type: string
            enum: [image, video, audio, text, multimodal, code]
        - name: task_type
          in: query
          schema:
            type: string
        - name: status
          in: query
          schema:
            type: string
            description: 模型 status 过滤 (online / offline / deprecated 等)
      responses:
        '200':
          description: 模型列表 (每个 version 含完整 param_schema)
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data:
                        $ref: '#/components/schemas/ListModelsResponse'
        '400':
          description: media_type 非法 (40030)

  /admin/provider/router-rules:
    post:
      summary: 创建路由规则 (P1-03 Phase A)
      operationId: createRouterRule
      tags: [Admin/Router]
      description: |
        创建后:
          1. Insert 到 prov_router_rules
          2. 发 Outbox 事件 (catalog.router_rule_created)
          3. 热加载到内存索引引擎
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateRouterRuleRequest'
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
                      data:
                        $ref: '#/components/schemas/RouterRuleDTO'
        '400':
          description: 参数无效 (40030)
        '500':
          description: 业务逻辑错误 (40010, 名称冲突 / 版本冲突等)

    get:
      summary: 列路由规则
      operationId: listRouterRules
      tags: [Admin/Router]
      parameters:
        - name: tenant_id
          in: query
          schema:
            type: integer
            format: int64
        - name: include_global
          in: query
          schema:
            type: boolean
            default: false
          description: |
            true 时 tenant_id=N 查询同时包含 tenant_id=0 的全局规则.
            false 时仅返指定 tenant 自己的规则.
        - name: status
          in: query
          schema:
            type: string
            enum: [enabled, disabled, archived]
        - name: limit
          in: query
          schema:
            type: integer
            minimum: 1
            maximum: 200
            default: 50
        - name: offset
          in: query
          schema:
            type: integer
            minimum: 0
            default: 0
      responses:
        '200':
          description: 规则列表
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data:
                        type: object
                        required: [items, total]
                        properties:
                          items:
                            type: array
                            items:
                              $ref: '#/components/schemas/RouterRuleDTO'
                          total:
                            type: integer
                            description: ⚠️ 当前页 len(items), 非全表 count

  /admin/provider/router-rules/{bid}:
    parameters:
      - name: bid
        in: path
        required: true
        schema:
          type: string
          format: uuid
    get:
      summary: 查路由规则详情
      operationId: getRouterRule
      tags: [Admin/Router]
      description: 走 FindActiveByBID, 软删过滤 (deleted_at IS NULL)
      responses:
        '200':
          description: 规则详情
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/StandardResponse'
                  - type: object
                    properties:
                      data:
                        $ref: '#/components/schemas/RouterRuleDTO'
        '404':
          description: 规则不存在或已删除 (40404)

    patch:
      summary: 更新路由规则 (乐观锁)
      operationId: updateRouterRule
      tags: [Admin/Router]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/UpdateRouterRuleRequest'
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
                        $ref: '#/components/schemas/RouterRuleDTO'
        '400':
          description: 参数无效 (40030)
        '500':
          description: 业务逻辑错误 (40010, 含乐观锁冲突)

    delete:
      summary: 软删路由规则
      operationId: deleteRouterRule
      tags: [Admin/Router]
      description: |
        SoftDelete (deleted_at = NOW()) + 发 Outbox 事件 (action=delete) + 热加载.
        返 data: null (SuccessWithoutData).
      responses:
        '200':
          description: "删除成功 (data: null)"
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/StandardResponse'
        '404':
          description: 规则不存在或已删除 (40404)

  /admin/provider/router-rules/_reload:
    post:
      summary: 热重载路由规则 (从 DB → 内存索引)
      operationId: reloadRouterRules
      tags: [Admin/Router]
      description: |
        当 DB 中规则被旁路修改 (非走 HTTP CRUD) 或运维补救手段时调用.
        Phase A: HTTP CRUD 已自动通过 Outbox 触发热加载, 此端点是补救机制.
      responses:
        '200':
          description: "重载完成 (data: null)"
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/StandardResponse'
        '500':
          description: 重载失败 (50010)

  /admin/provider/cache/{tenant_id}:
    delete:
      summary: 清 SemanticCache (P1-03 Phase C 运维清理)
      operationId: invalidateProviderCache
      tags: [Admin/Cache]
      description: |
        失效维度:
          - 整租户:        {TenantID=N, ModelVersionBID=""}
          - 单 model 维度: {TenantID=N, ModelVersionBID="UUID"}

        路径参数用 tenant_id (int) 而非 tenant_bid, 因 Provider BC 不持
        Tenancy 的 BID 反查能力 (caller 应预先解析 BID → ID).

        ⚠️ 已知缺陷: model_version_bid query 无 UUID 格式校验 (代码事实).
      parameters:
        - name: tenant_id
          in: path
          required: true
          schema:
            type: integer
            format: int64
            minimum: 1
        - name: model_version_bid
          in: query
          required: false
          schema:
            type: string
            format: uuid
          description: 仅失效该 model_version 的缓存 (空 = 整租户)
      responses:
        '200':
          description: "失效成功 (data: null)"
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/StandardResponse'
        '400':
          description: tenant_id 非法 (40030)
        '500':
          description: 缓存清理失败 (50010)

# ─────────────────────────────────────────────────────────────────────────
# 错误码段 (来源 internal/provider/domain/errors.go::GetErrorCode)
# ─────────────────────────────────────────────────────────────────────────
# 多数业务错误 HTTP 状态码为 200, 业务码在 response.code (见 overview.md §6).
#
# 40010  ErrInvalidParam              参数校验失败 (Provider 段)
# 40030  (admin handler 直接返)        参数格式错或 status 非法
# 40310  ErrProviderDisabled / ChannelDisabled / ModelOffline   资源不可用
# 40311  ErrProviderMaintenance       供应商维护中
# 40312  ErrChannelExpired            通道凭证已过期
# 40313  ErrNoAvailableChannel        无可用通道
# 40314  ErrVersionDeprecated         模型版本已弃用
# 40404  规则 / 模型版本不存在 (handler 直接返)
# 40410  ErrProviderNotFound / ModelNotFound / VersionNotFound / ChannelNotFound
# 42910  ErrQuotaExhausted            配额耗尽
# 45110  ErrContentFiltered           内容被供应商过滤
# 50010  (admin handler 直接返)        仓储查询失败 / 重载失败 / 缓存清理失败
# 50020  ErrCredentialDecrypt         凭证解密失败
# 50210  ErrUpstreamFailed            上游调用失败
# 50410  ErrUpstreamTimeout           上游服务超时
```
