# StoreShot 应用商店截图管线 — API 对接文档

> **范围**:App Store / Google Play 宣传图 AI 生成工具(StoreShot)的客户端对接契约。
> StoreShot 以 **task-as-primary 管线**(P8-07)形态实装于 Creation BC,复用既有 `POST /v1/tasks` 任务通道。
>
> **备注 — 能力归属**:StoreShot 为 **StoreShot 应用工具单独拥有**的产品能力。`storeshot_v1` 管线模板及本文档所述全部对接契约**专属于 StoreShot 这一应用**,非平台通用 API,平台上其他应用不具备、也不共享此能力。(`POST /v1/tasks` 任务通道本身为平台通用,StoreShot 仅是其上的一个应用专属管线模板。)
>
> **事实驱动**:本文每条契约均标注源代码 `文件:行号`,严禁推测。最后核对时间 2026-06-10。
> 公共机制(BaseURL、签名、Envelope、JWT)见 [overview.md](overview.md);通用任务端点见 [creation.md](creation.md)。
> 历史种子 `docs/migrations/p8_07_storeshot_pipeline.sql` 已随迁移套件退役删除(commit `78d8333`,
> docker.postgres 为唯一基准);现行管线模板种子 = `docs/migrations/20260815a_storeshot_v1_baseline_seed.sql`(幂等,自校验)。

---

## 🆕 v1.2 更新(2026-08-06):端到端出图 + 打包

管线从 2 步扩到 **4 步**,新增两步把"生成的展示图"直接做成 **Transporter 能吃的 `.itmsp` ZIP**:

```
gen_copy(llm_copy) → stylize_image(image_stylize) → resize(magick_resize) → itmsp(itmsp_pack)
```

- **resize**:把风格化图精确对齐到 App Store Connect 机型像素规格(App Store 权威尺寸,已按 Apple 官方纠正)。
- **itmsp**:按 `<locale> × <display_target> × position` 组织,生成 `metadata.xml`(每图带 md5/size),打包为 `<app>.itmsp/` 并 zip 上传。

**新增 `params` 字段(全部可选,向后兼容)**:

| 字段 | 类型 | 默认 | 作用 |
|---|---|---|---|
| `target_devices` | string[] | `["iphone_69"]` | resize 目标机型(多机型);机型码见 §7.3。仅 `iphone_69` 时苹果自动向下适配其它 iPhone;iPad 按需加 `ipad_13` 等 |
| `apple_id` | string | 占位 `REPLACE_WITH_APPLE_ID` | 你 App 在 ASC 的 Apple ID(纯数字)。给了 → `.itmsp` 可直接上传;缺省 → 包内附 README 提示替换一处 |
| `version_string` | string | `1.0` | 写入 metadata.xml 的版本号 |
| `app_platform` | string | `ios` | metadata.xml 的 app_platform |

**新增产物**:任务终态 `output_metadata.final_urls` 除展示图外,还含 **`.itmsp` ZIP 的下载 URL**(itmsp 步产出);itmsp 步 `Data` 另含 `manifest`(每图的 locale/device/position/md5)。

> 未传 `target_devices` / `apple_id` 时行为与 v1.1 一致(单机型 iphone_69 + 占位 apple_id),旧客户端无需改动。

---

## 0. 真实实现状态(对接前必读)

| 项 | 状态 | 证据 |
|---|---|---|
| `gen_task_type` 枚举含 `pipeline` | ✅ 已生效(dev DB 已验证) | dev DB `pg_enum` 实查含 `pipeline`(原 p8_07 SQL 已退役删除) |
| 管线模板 `storeshot_v1` 已入库 | ✅ `status=active` `category=app_assets`(dev DB 已验证) | `docs/migrations/20260815a_storeshot_v1_baseline_seed.sql`(原 p8_07 被 78d83332 删除后重建,终态全量+动态 bid 解析);dev DB id=85 |
| 定价规则 4 档已入库 | ✅ dev 4 档实查;⚠ prod 曾零行(2026-08-15 recon 实证,提交被 40033/pricing-missing 硬拒)— `20260815b` 随下次发布补齐 | `docs/migrations/20260815b_storeshot_v1_pricing.sql` |
| HTTP 端点已挂载 | ✅ `POST /v1/tasks`(管线分支)+ `GET /v1/pipelines[/:code]` | `routes.go:50-54,127-129` |
| Worker 执行路径已实装 | ✅ `PostProcessWorker.executeTaskPrimary` | `infra/postprocess/worker.go:330-395` |
| Prompt+Provider 桥接已实装(非 stub) | ✅ `StepLLMPort` / `StepImagePort` 真实装 | `internal/bootstrap/bridges.go:1944-2089` |
| 管线步骤的模型版本 bid | ✅ **已填真实值(2026-06-10,dev DB 已验证无占位符)** | `gen_copy` → `gemini-3.1-flash-lite`;`stylize_image` → `gemini-3-pro-image-preview`(Nano Banana);种子文件同值 |
| 参考图实际送达图像模型 | ✅ **双键发射修复(2026-06-10)**:桥接同时发 `image_url` + `reference_images`([]{url,role:object}) | `bridges.go:2059-2069` + `creation_step_image_bridge_test.go`;历史只发 `image_url` 时 Gemini 系适配器静默丢图(只认 `reference_images`,`gemini_image_inputs.go:206`) |

> ✅ **占位符问题已解决**(原 §0 ⚠️):dev DB 两步 `model_version_bid` 已替换为真实
> `prov_model_versions.bid` 并通过自校验(bid 可解析、无 `REPLACE_WITH_*` 残留)。
> **新环境(含 prod)前置**:分域迁移按台账全量 apply 即可 —— provider 目录=`20260812d`、
> 定价=`20260815b`、管线模板=`20260815a`(终态 seed,依赖模型 seed 先行,fail-close 自检);
> 旧"主 seed 文件"(genai-prod-seed.sql)已不存在,勿再引用。
> 漏 apply `20260815a` 则 `GET /v1/pipelines` 为空、提交管线任务返 40001;
> 该迁移幂等可重跑(已存在即 no-op NOTICE),模型缺失 fail-close 整体回滚。

---

## 1. 工作原理

StoreShot 不是独立的 BC,而是 Creation BC 的一种**管线任务**(`task_type="pipeline"`):

```
POST /v1/tasks {pipeline_code:"storeshot_v1", params:{...}}
   │
   ├─ SubmitTaskHandler.Handle 检测 pipeline_code 非空 → handlePipelineSubmit 分支
   │     (submit_task_handler.go:366-367)
   │
   ├─ 解析模板 → 算价 → 冻结积分 → 建 gen_generation_tasks 行(task_type=pipeline)
   │     → 入队 PostProcessRequest(OwnerMode=task_primary)         (submit_task_handler.go:658-767)
   │
   └─ 同步返回 202 + task_id  ← 客户端在此拿到 task_id
         │
         ▼ (异步,cmd/genaistudio-worker 进程)
   PostProcessWorker.executeTaskPrimary                            (worker.go:330-395)
         │
         ├─ Orchestrator 按拓扑序跑 2 步管线:                       (app/postprocess/orchestrator.go:65-142)
         │     gen_copy(llm_copy)   → 调 LLM 生成多语言文案 JSON
         │     stylize_image(image_stylize) → (截图 × 语言) 矩阵并发调图像模型
         │
         └─ 回写 task 主状态(completed/partial/failed)+ 结算积分 + 候选矩阵落库
                                                                   (worker.go:397-466,560-580)
         │
         ▼
GET /v1/tasks/:bid  ← 客户端轮询拿终态 + candidates[](生成的展示图)
```

管线定义(终态 4 步)源:`docs/migrations/20260815a_storeshot_v1_baseline_seed.sql`(`storeshot_v1` 终态 seed;历史演进 20260806b/c 为 UPDATE 追加,空环境由 20260815a 一次落终态)。

| 步骤 `step_key` | 处理器 `processor_type` | 模型(已填真实 bid) | 超时 | 重试 | 作用 |
|---|---|---|---|---|---|
| `gen_copy` | `llm_copy` | `gemini-3.1-flash-lite` | 60s | 2 次 / 退避 1000ms | LLM 生成多语言营销文案 |
| `stylize_image` | `image_stylize` | `gemini-3-pro-image-preview`(Nano Banana) | 180s | 2 次 / 退避 2000ms | 截图 × 语言矩阵风格化出展示图 |

依赖:`stylize_image` `depends_on` `gen_copy`(种子文件 `storeshot_v1` 的 pipeline JSON)。

---

## 2. 公共契约

| 项 | 值 | 来源 |
|---|---|---|
| BaseURL(dev) | `http://localhost:9999/v1` | `router/router.go:48` |
| 鉴权 | JWT(`Authorization: Bearer <jwt>`) | `router/router.go:54-55` |
| App 签名 | `X-Distribution-Code`/`X-Timestamp`/`X-Nonce`/`X-App-Signature` 全 `/v1/*` 必带 | overview.md §3.1 / §5 |
| 响应 Envelope | `{code,message,data,request_id,timestamp}`;`code=0` 成功 | `response/response.go:20-26` |

> 所有 StoreShot 端点均在 `authenticated` 组下(JWT)+ `/v1` 全局链(含 AppSignature)。
> Handler 从 ctx 注入获取 `account_id`/`app_id`(`task_handler.go:81-84`),**严禁**在请求体放
> `app_id`/`tenant_id`/`distribution_code`。

### 2.1 HTTP 状态码 vs 业务码

| 响应辅助 | HTTP 状态 | Envelope `code` | 来源 |
|---|---|---|---|
| `Success` | 200 | 0 | `response.go:58-66` |
| `Accepted` | 202 | 0(`message:"accepted"`) | `response.go:80-88` |
| `Error(code,msg)` | **200** | 业务码(非 0) | `response.go:101-108` |
| `BadRequest` | 400 | 400 | `response.go:122-129` |
| `Unauthorized` | 401 | 401 | `response.go:132-139` |
| `NotFound` | 404 | 404 | `response.go:152-159` |
| `ValidationFailed` | 400 | 40001 + `details{}` | `response.go:237-246`、`errors.go:18` |

⚠️ 业务错误(余额不足、内部错误等)走 `Error` → **HTTP 200**,客户端**必须读 Envelope `code` 判定成败**,不能只看 HTTP 状态。

---

## 3. 端点清单

| 方法 | 路径 | 用途 | 鉴权 | 来源 |
|---|---|---|---|---|
| GET | `/v1/pipelines` | 列出可用管线目录 | JWT | `routes.go:128` |
| GET | `/v1/pipelines/:code` | 单个管线详情 | JWT | `routes.go:129` |
| POST | `/v1/tasks` | 提交管线任务(`pipeline_code` 非空) | JWT | `routes.go:50` |
| GET | `/v1/tasks/:bid` | 轮询任务状态 + 取产物 | JWT | `routes.go:52` |
| POST | `/v1/tasks/:bid/cancel` | 取消任务 | JWT | `routes.go:54` |
| GET | `/v1/tasks/:bid/stream` | SSE 实时进度(替代轮询) | JWT | `routes.go:53` |

> `POST /v1/tasks/estimate`(算价预估)**不支持管线** —— `EstimateCostRequest` 仅有 `model_version_bid`
> 字段且 HTTP 边界强校验非空,管线无单一模型(`estimate_cost_handler.go:13`、`task_handler.go:296-300`)。
> 管线价格只能在提交时由服务端计算。

---

## 4. GET /v1/pipelines — 管线目录

列出系统级(`tenant=0`)`active` 状态的全部管线模板。客户端据此发现可提交的 `pipeline_code`。

**请求**:无参数。
**Handler**:`pipeline_handler.go:53-65` → `ListPipelinesHandler.List`(`pipeline_query_handler.go:20-22`,`templateRepo.ListActive(ctx, 0)`)。

**响应** `200`:

```json
{
  "code": 0,
  "message": "success",
  "data": [
    {
      "code": "storeshot_v1",
      "display_name": "StoreShot 应用商店截图管线 (v1)",
      "category": "app_assets",
      "description": "上传应用截图 + 应用信息, 一键生成带营销文案的 App Store 展示图。...",
      "expected_duration_sec": 150,
      "resource_profile": "light",
      "step_count": 2
    }
  ],
  "request_id": "uuid",
  "timestamp": 1747800000
}
```

**`data[]` 字段**(`PipelineDTO`,`pipeline_handler.go:26-50`):

| 字段 | 类型 | 说明 | 来源 |
|---|---|---|---|
| `code` | string | 管线代码,提交时作 `pipeline_code` | `Template.TemplateCode` |
| `display_name` | string | 展示名 | `Template.DisplayName` |
| `category` | string | 业务分类,枚举见下 | `Template.Category` |
| `description` | string | 描述 | `Template.Description` |
| `expected_duration_sec` | int | 预估耗时(秒),`storeshot_v1`=150 | `Template.ExpectedDurSec` |
| `resource_profile` | string | 资源画像,`storeshot_v1`=`light` | `Template.ResourceProfile` |
| `step_count` | int | 管线步骤数,`storeshot_v1`=2 | `len(Pipeline.Steps)` |

`category` 枚举(`domain/postprocess/template.go:28-33`):`app_assets` / `ecommerce` / `social_media` / `creative`。
`resource_profile` 枚举(`template.go:18-23`):`light` / `cpu_intensive` / `gpu_required` / `memory_heavy`。

> ⚠️ 目录**不暴露价格、不暴露步骤实现细节**(`params`/`processor_type`)。`PipelineDTO` 结构体无任何 cost 字段
> (`pipeline_handler.go:26-34`)。价格仅在提交后由服务端结算 —— 见 §8。

---

## 5. GET /v1/pipelines/:code — 管线详情

**路径参数**:`code` —— 管线代码(如 `storeshot_v1`)。
**Handler**:`pipeline_handler.go:68-85` → `ListPipelinesHandler.GetByCode`(`templateRepo.FindActiveByCode(ctx, 0, code)`)。

**响应** `200`:`data` 为单个 `PipelineDTO`(字段同 §4)。

**错误**:

| 场景 | HTTP | Envelope `code` | message | 来源 |
|---|---|---|---|---|
| `code` 路径段为空 | 400 | 400 | `管线 code 不能为空` | `pipeline_handler.go:70-73` |
| 管线不存在 / 非 active | 404 | 404 | `管线不存在` | `pipeline_handler.go:76-79`(`ErrTemplateNotFound`) |
| 其他错误 | 200 | 50000 | `服务内部错误` | `pipeline_handler.go:80-82` → `GetErrorCode` default |

---

## 6. POST /v1/tasks — 提交管线任务

与普通生成任务**同一端点**。`pipeline_code` 非空即进入管线分支(`submit_task_handler.go:160-162`)。

### 6.1 请求体

`SubmitTaskRequest`(`dto/task.go:8-16`):

```json
{
  "pipeline_code": "storeshot_v1",
  "params": {
    "app_name": "FocusFlow",
    "app_description": "极简专注计时器,帮你进入心流状态",
    "languages": "en",
    "tone": "专业、现代",
    "screenshots": [
      "https://your-cdn/shot1.png",
      "https://your-cdn/shot2.png"
    ]
  },
  "idempotency_key": "client-uuid-optional"
}
```

| 字段 | 类型 | 必填 | 说明 | 来源 |
|---|---|---|---|---|
| `pipeline_code` | string | **是**(管线模式) | 管线代码,来自 §4 目录;与 `model_version_bid` 互斥 | `dto/task.go:13-15` |
| `params` | object | **是** | 管线输入参数,见 §7;管线模式下仅校验非空 | `dto/task.go:21-25` |
| `idempotency_key` | string | 否 | 幂等键;命中已有任务则直接返回该任务 | `submit_task_handler.go:353-361` |
| `model_version_bid` | string | —— | **管线模式留空**;非空走普通任务分支 | `dto/task.go:9` |
| `preset_code` | string | —— | 管线模式不使用 | `dto/task.go:11` |

> **校验规则**(`SubmitTaskRequest.Validate`,`dto/task.go:19-38`):管线模式(`pipeline_code` 非空)下,
> **只校验 `params` 非空**,不校验 `params` 内具体字段。`params` 内字段缺失的后果在 Worker 执行期暴露(见 §7、§9)。

### 6.2 成功响应 `202`

`SubmitTaskResponse`(`dto/task.go:44-49`,构造于 `submit_task_handler.go:761-766`):

```json
{
  "code": 0,
  "message": "accepted",
  "data": {
    "task_id": "<task_bid uuid>",
    "status": "processing",
    "poll_url": "/v1/tasks/<task_bid>",
    "estimate_ms": 150000
  },
  "request_id": "uuid",
  "timestamp": 1747800000
}
```

| 字段 | 类型 | 说明 | 来源 |
|---|---|---|---|
| `task_id` | string | 任务 BID(UUID);后续轮询用 | `submit_task_handler.go:762` |
| `status` | string | 恒为 `processing`(幂等命中已终态任务时为该任务实际状态) | `submit_task_handler.go:763`、`buildResponseFromTask:930-938` |
| `poll_url` | string | 轮询路径 = `/v1/tasks/<task_id>` | `submit_task_handler.go:764` |
| `estimate_ms` | int | 预估耗时(毫秒)= 模板 `expected_duration_sec × 1000`,`storeshot_v1`=150000 | `submit_task_handler.go:765` |

### 6.3 提交期错误

`handlePipelineSubmit` 的错误处理(`submit_task_handler.go:658-767`)+ HTTP 边界映射(`task_handler.go:110-125`):

| 场景 | HTTP | Envelope `code` | 响应形态 | 来源 |
|---|---|---|---|---|
| 请求体非法 JSON | 400 | 400 | `BadRequest` | `task_handler.go:65-70` |
| `params` 为空 | 400 | 40001 | `ValidationFailed` `details:{params:"参数不能为空"}` | `dto/task.go:22-24`、`task_handler.go:72-75` |
| 无 JWT 认证信息 | 401 | 401 | `Unauthorized` | `task_handler.go:77-80` |
| 后处理子系统未装配 | 400 | 40001 | `ValidationFailed`(`ErrInvalidParam` 经 `errors.Is` 命中) | `submit_task_handler.go:659-661`、`task_handler.go:116-119` |
| `pipeline_code` 对应模板不存在 / 非 active | 400 | 40001 | `ValidationFailed` `details:{params:"...pipeline \"xxx\" not found..."}` | `submit_task_handler.go:664-667` |
| 余额不足(冻结失败,真实不足) | **200** | 40200 | `Error` `message:"余额不足"` | `submit_task_handler.go:691-700` → `mapFreezeError:42-60`、`errors.go:143-144` |
| 钱包数据漂移(冻结失败,balance 虚高于口袋,**非用户问题**) | **200** | 50231 | `Error`(需对账修复,见 `docs/ops/wallet-update-balance-chain.sql`) | `mapFreezeError`、`errors.go:14-17,145-146` |
| 钱包不可用(冻结失败,钱包不存在/停用/系统错误) | **200** | 50230 | `Error` | `mapFreezeError`、`errors.go:11-13` |
| 建任务 / 入队失败 | **200** | 50000 | `Error` `message:"服务内部错误"`(入队失败已自动退款) | `submit_task_handler.go:741-752`、`errors.go` default |

> 冻结失败**不再一律 40200**:2026-06 起经 `mapFreezeError` 按成因分流(历史上钱包数据漂移被误报
> "余额不足",误导有充足余额的用户)。客户端对 50230/50231 应提示"系统繁忙/请联系客服",而非引导充值。

> 后处理子系统未装配 = `cmd/genaistudio-server` 的 modules 配置未启用 creation 后处理。生产 `cmd/genaistudio-worker` 形态下正常装配。

---

## 7. params 字段规格(storeshot_v1)

`params` 整体作为 `gen_generation_tasks.input_params` 落库(`submit_task_handler.go:711-718`),
Worker 执行时作为管线的 `RootParams` 只读快照传入(`worker.go:378-381`、`orchestrator.go:56-58`)。
各步骤处理器从 `RootParams` 取所需字段。

> Prompt 正文证据源:`storeshot_copy_generator` / `storeshot_image_stylizer` 的 live 版本存
> `pt_prompt_versions`(dev DB 实查两 slug live=true)。步骤参数证据源:
> `docs/migrations/20260815a_storeshot_v1_baseline_seed.sql` 的 `storeshot_v1` pipeline JSON(与 dev/prod 现行行对齐)。

| 字段 | 类型 | 必填 | 消费方 | 缺失后果 | 来源 |
|---|---|---|---|---|---|
| `app_name` | string | 强烈建议 | `gen_copy` + `stylize_image` 的 Prompt 变量 | Prompt 渲染缺变量,文案/排版降级 | `storeshot_copy_generator` 正文引用 `{{ .app_name }}` |
| `app_description` | string | 强烈建议 | `gen_copy` Prompt 变量 | 同上 | 同上模板正文 + variables_schema |
| `languages` | string | 强烈建议 | `gen_copy` Prompt 变量 | LLM 无目标语言指引,输出语言不可控 | 同上模板正文 + variables_schema |
| `tone` | string | 可选 | `gen_copy` Prompt 变量 | schema 标注 default `专业、现代`;建议显式传 | 同上模板 variables_schema |
| `screenshots` | string[] | **必填(硬要求)** | `stylize_image` 处理器**直接读取** `RootParams["screenshots"]` | **整步硬失败 → 任务 `failed` + 退款** | `image_stylize_processor.go:82,87-90`;键名见种子 `screenshots_var` |

**两类字段语义不同 —— 对接时务必区分**:

1. **Prompt 变量类**(`app_name`/`app_description`/`languages`/`tone`):由 `gen_copy` 步骤渲染
   `storeshot_copy_generator` Prompt 模板时消费(`llm_copy_processor.go:66-69`),`stylize_image` 渲染
   `storeshot_image_stylizer` 时也注入 `RootParams`(`image_stylize_processor.go:170-173`)。
   缺失 = **软降级**(渲染出空变量,文案质量下降),不一定报错。

2. **管线机制类**(`screenshots`):由 `image_stylize` 处理器**代码直接取值**,不经 Prompt 模板。
   `screenshots_var` 默认键名 `"screenshots"`(`image_stylize_processor.go:82`、种子 `storeshot_v1` step params)。
   取值为空 → `image_stylize 源截图缺失` 错误 → **管线硬失败**(`image_stylize_processor.go:88-90`)。
   截图经 `StepImageRequest.SourceImageURL` 进入桥接后**双键发射**:`image_url`(存量契约)+
   `reference_images=[{url, role:"object"}]`(Gemini/Volcengine 适配器唯一认的键,`bridges.go:2059-2069`)
   —— 即截图作为参考图真实送达 `gemini-3-pro-image-preview`,风格化是 image-to-image 而非纯文生图。

**`screenshots` 取值兼容**(`stringSliceValue`,`image_stylize_processor.go:246-264`):`[]string` / `[]any`(取字符串元素)/ 单 `string` 均可;推荐传字符串数组。

### 7.1 输出矩阵规模

`stylize_image` 构建 **(截图 × 语言) 矩阵**(`image_stylize_processor.go:97-103`):
- 截图维 = `screenshots` 数组每个元素;
- 语言维 = `gen_copy` 步骤 LLM 输出 `copy_map` 的键集合(`sortedMapKeys`,升序)。

> **产出图数量 = `len(screenshots) × len(copy_map 语言数)`**。`languages` 传单语言时即 `N 张截图 → N 张展示图`。
> `copy_map` 的语言键由 LLM 依 `storeshot_copy_generator` Prompt + `languages` 变量决定
> —— Prompt 要求输出顶层 key 为语言代码的 JSON(模板正文,`pt_prompt_versions` live 版)。

### 7.2 部分成功阈值

矩阵每个 cell 并发独立生成,单 cell 失败不中断(`image_stylize_processor.go:105-122`)。
- 并发上限 `max_concurrency`=5(种子 `storeshot_v1` step params);
- 成功率 `< min_success_ratio`(0.5,种子同处)→ 整步失败 → 任务 `failed`(`image_stylize_processor.go:143-147`);
- 成功率 `≥ 0.5` 但有失败 cell → 整步成功,任务进入**部分成功**结算(见 §8、§9)。

### 7.3 `target_devices` 机型码(v1.2 resize/itmsp)

resize 步的目标机型。**缺省 = `["iphone_69"]`**(苹果唯一强制机型,自动向下适配其它 iPhone);
支持带/不带下划线两种写法(`iphone69` 与 `iphone_69` 等价)。

| 机型码 | 机型 | 尺寸(portrait) |
|---|---|---|
| `iphone_69` | iPhone 6.9″(默认) | 1320×2868 |
| `iphone_67` | iPhone 6.7″ | 1290×2796 |
| `iphone_65` | iPhone 6.5″ | 1284×2778 |
| `iphone_55` | iPhone 5.5″ | 1242×2208 |
| `ipad_129` | iPad Pro 12.9″ | 2048×2732 |
| `ipad_13` | iPad Pro 13″ | 2064×2752 |
| `ipad_11` | iPad Pro 11″ | 1668×2420 |

- 尺寸唯一权威 = DB 表 `gen_store_specs`(与 `spec_validate` 同源);上表值随该表,勿硬编码。
- **提交期校验(fail-fast)**:`target_devices` 含未知机型码 / 该机型在 `gen_store_specs` 无 active 规格
  → 提交即 **400 `40001`**(`ErrInvalidParam`),不进入昂贵的文案/出图步骤。归一后的
  `target_devices`(canonical + 去重)随任务落库。
- **产出规模**:`itmsp` 打包按 `<ASC locale> × <display_target> × position` 组织,每 (locale, 机型)
  至多 10 张(Apple 上限,超出丢弃并告警)。ASC locale 由 `languages` 的语言码映射
  (`en`→`en-US`、`zh`→`zh-Hans`,显式 `en-GB` 透传)。

---

## 8. 计费

管线作为一个可定价单元,复用 `wal_credit_pricing_rules`(`submit_task_handler.go:669-684`):
查规则键 = `model_code="pipeline:storeshot_v1"` + `task_type="pipeline"` + 用户 `pricing_tier`。

**定价入库状态**(2026-08-15 订正):dev 4 档实查;prod 曾零行(recon 实证,提交被硬拒)— `docs/migrations/20260815b_storeshot_v1_pricing.sql` 固化四档并随下次发布补齐 prod。
2026-05-31 起经 RepriceJob 倒置定价全表重算生效,**取代本档早期版本记录的 240/290/190/150**):

| `pricing_tier` | `credit_cost` | `min_cost` |
|---|---|---|
| `default` | 17 | 11 |
| `free` | 21 | 11 |
| `member` | 14 | 11 |
| `enterprise` | 11 | 11 |

> `pricing_tier` 由服务端按 `(account, app)` 解析(`featureQuery.ResolvePricingTier`,`submit_task_handler.go:673-676`),
> 客户端不传、不可指定。**无匹配规则 → 硬拒绝 50830**(2026-06-10 strict 化,取代历史 fail-open 免费放行;
> `ErrPipelinePricingMissing`,显式免费须用 `credit_cost=0` 规则行表达)。

**结算时机**:提交时**冻结**(`FreezeCredits`,`submit_task_handler.go:686-702`);Worker 终态时结算
(`completePipelineTask` 内调 `decidePipelineSettlement` 纯函数,`worker.go:427-448,468-482`):

| 终态 | 结算动作 | 说明 |
|---|---|---|
| 全部 cell 成功(`completed`) | `ConfirmFreeze` 全额确认 | `worker.go:432-437` |
| 部分成功(`partial`) | `PartialConfirmFreeze` 按比例 = `冻结额 × 成功数 / 总数` | `worker.go:438-442,479-481` |
| 部分成功但比例额向下取整为 0 | `RefundFreeze` 全额退款 | `worker.go:443-447,475-478` |
| 失败(`failed`) | `RefundFreeze` 全额退款 | `worker.go:574-578` |

---

## 9. GET /v1/tasks/:bid — 轮询任务 / 取产物

管线任务是普通 `gen_generation_tasks` 行,用通用任务查询端点轮询(`get_task_handler.go:104-156`)。

**路径参数**:`bid` = `task_id`。
**鉴权**:JWT + 任务归属校验(非本账号任务统一返 `40420`,不暴露归属,`get_task_handler.go:110-112`)。

### 9.1 任务状态机

`task_type="pipeline"` 任务的 `status`(`task_status.go:16-24`):

| `status` | 含义 | 终态 |
|---|---|---|
| `pending` | 已入队,Worker 未开始 | 否 |
| `processing` | 管线执行中 | 否 |
| `completed` | 全部矩阵 cell 成功 | 是 |
| `partial` | 部分 cell 成功(成功率 ≥ 0.5) | 是 |
| `failed` | 管线失败(见 §9.4 错误码) | 是 |
| `timeout` | 超时 | 是 |
| `cancelled` | 用户取消 | 是 |

### 9.2 响应字段(`TaskResponse`,`get_task_handler.go:13-38`)

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "task_bid": "<task_bid>",
    "status": "completed",
    "model_code": "pipeline:storeshot_v1",
    "task_type": "pipeline",
    "output_metadata": {
      "final_urls": ["https://provider/.../img1.png", "https://provider/.../img2.png"],
      "candidate_bids": ["<cand_bid_1>", "<cand_bid_2>"]
    },
    "created_at": 1747800000,
    "started_at": 1747800002,
    "completed_at": 1747800140,
    "billing": { "quota_consumed": 240, "quantity_requested": 1, "quantity_completed": 0, "quantity_failed": 0 },
    "candidates": [
      {
        "bid": "<cand_bid_1>", "task_bid": "<task_bid>", "index": 0,
        "status": "ready", "moderation_status": "skipped", "content_type": "image",
        "url": "https://r2.../signed...", "primary_url": "https://r2.../signed...",
        "width": 1242, "height": 2688,
        "expires_at": 1748404800, "created_at": 1747800140
      }
    ],
    "candidate_summary": { "total": 2, "ready": 2, "pending": 0, "selected": 0, "discarded": 0, "expired": 0 }
  },
  "request_id": "uuid",
  "timestamp": 1747800141
}
```

| 字段 | 类型 | 说明 | 来源 |
|---|---|---|---|
| `task_bid` | string | 任务 BID | `get_task_handler.go:115` |
| `status` | string | 见 §9.1 | `get_task_handler.go:117` |
| `model_code` | string | 管线任务恒为 `pipeline:<pipeline_code>` | `submit_task_handler.go:712-714`、`get_task_handler.go:118` |
| `task_type` | string | 恒为 `pipeline` | `submit_task_handler.go:461` |
| `output_metadata` | object | **仅 `completed`/`partial` 填充**;字段见 §9.3 | `get_task_handler.go:132-134` |
| `output_content` | string\|null | 管线任务**不填**(管线无文本主输出) | `get_task_handler.go:133` |
| `error_code` / `error_message` | string | **仅 `failed`/`timeout` 填充**;见 §9.4 | `get_task_handler.go:135-137` |
| `created_at`/`started_at`/`completed_at` | int / int\|null | Unix 秒 | `get_task_handler.go:119-129` |
| `billing` | object\|null | 终态填充;`resources[]` 对管线任务通常为空(资产以候选形态存在,非 `gen_assets`) | `get_task_handler.go:141-143,218-266` |
| `candidates` | array | 生成的展示图候选;终态 + processing 均返(渐进式) | `get_task_handler.go:146-148,167-214` |
| `candidate_summary` | object | 各状态计数 | `get_task_handler.go:40-48` |
| `poll` | object\|null | 非终态返轮询策略,终态为 `null` | `get_task_handler.go:151-153` |

### 9.3 output_metadata 字段

| 键 | 出现条件 | 类型 | 说明 | 来源 |
|---|---|---|---|---|
| `final_urls` | 恒有(`completed`/`partial`) | string[] | **末端步骤产出图 URL** —— Provider 已上传的永久地址,可立即下载 | `worker.go:404`;`step_image_port.go:12` |
| `candidate_bids` | 有候选时 | string[] | 候选 BID 列表,与 `candidates[].bid` 对应 | `worker.go:407-408` |
| `matrix_total` | 仅 `partial` | int | 矩阵 cell 总数 | `worker.go:413` |
| `matrix_succeeded` | 仅 `partial` | int | 成功 cell 数 | `worker.go:414` |

> **取产物的两条路径**:
> 1. **`output_metadata.final_urls`** —— 任务终态即可用,是图像模型直出的 Provider 永久 URL。**最快路径**。
> 2. **`candidates[].url`** —— 平台托管路径。候选初始为 `pending` 态,由 `PendingPromotionWorker`
>    异步转存 R2 后才填 `url`(见 §9.5)。带完整生命周期(可保存进资产库)。

### 9.4 失败任务的 error_code

`status="failed"` 时 `error_code` 取值(`gen_generation_tasks.error_code`,经 `TaskResponse.ErrorCode` 暴露):

| `error_code` | 触发场景 | 来源 |
|---|---|---|
| `pipeline_failed` | 管线某步骤执行失败(LLM 调用失败 / 图像生成失败 / 成功率 < 0.5 / `screenshots` 缺失 / Provider 解析模型失败) | `worker.go:385`(`runErr` 来自 Orchestrator) |
| `template_not_found` | 模板快照加载失败 | `worker.go:364` |
| `pipeline_interrupted` | 进程崩溃后消息重投递,为防重复扣费保守失败(需重新提交) | `worker.go:355` |
| `enqueue_failed` | 提交期入队失败(提交时即置 `failed`) | `submit_task_handler.go:751`、`failTask:769-781` |

> `error_message` 统一截断至 500 字符(`worker.go:567`)。历史 §0 占位符未替换场景
> (`pipeline_failed` + `REPLACE_WITH_*` 解析失败)已于 2026-06-10 解决,仅当新环境漏跑
> 旧占位符形态 seed(p8_07,已删)且模板被手工灌入占位符版本时才会复现;现行 20260815a 动态解析 + fail-close,占位符形态已不可能入库。

### 9.5 candidates[] 字段(`CandidateResponse`)

每个成功矩阵 cell → 一个候选(`worker.go:484-537`)。字段(`get_candidate_handler.go:16-46`):

| 字段 | 类型 | 说明 |
|---|---|---|
| `bid` | string | 候选 BID |
| `task_bid` | string | 所属任务 BID |
| `index` | int | 候选序号(0-based,跳过空 URL 后连续) |
| `status` | string | `pending`(待转存)→ `ready`(可下载)→ `selected`(已存资产库)/ `discarded` / `expired` |
| `moderation_status` | string | 管线候选恒为 `skipped`(`candidate.go:159`) |
| `content_type` | string | 恒为 `image` |
| `url` / `primary_url` | string | 主文件 URL;**`pending` 阶段为空串**,转存 R2 后填签名 URL(二者同值) |
| `width` / `height` | int | 像素尺寸(`omitempty`) |
| `files` | array | 文件列表(`omitempty`) |
| `asset_bid` | string | 该候选已"保存到资产库"后的资产 BID(`omitempty`) |
| `expires_at` / `created_at` | int | Unix 秒;管线候选 TTL = 7 天(`worker.go:323`) |

> **关键对接点**:管线任务到达 `completed`/`partial` 时,候选**仍可能是 `pending` 态**,
> `candidates[].url` 为空串(`NewPendingCandidate` 置 `PrimaryFileKey=""`,`candidate.go:155`;
> `MapCandidateToDTO` 在 `PrimaryFileKey==""` 时跳过 URL 构建,`get_candidate_handler.go:158`)。
> 客户端若需平台托管 URL,**应继续轮询直至 `candidate_summary.ready` 达预期且 `candidates[].url` 非空**;
> 若只需尽快展示,**直接用 `output_metadata.final_urls`**(任务终态即可用)。
>
> 候选状态枚举与完整生命周期(选取 / 丢弃 / 存资产库)语义与普通任务候选一致,见 [creation.md](creation.md) 候选层章节。

### 9.6 轮询策略

`task_type="pipeline"` 不匹配 text/image/video/audio 关键字,`computePollStrategy` 走默认档
(`get_task_handler.go:277-315,422-436`):预估总耗时 `30s`、最大轮询超时 `600s`(`get_task_handler.go:400,418`)、
间隔 3s→5s→10s→30s→60s 递增(`get_task_handler.go:374-385`)。
非终态响应带 `poll.next_poll_after_ms` 指示下次轮询间隔;终态 `poll=null`。

> StoreShot 实际预估 150s(模板 `expected_duration_sec`),与默认轮询档的 30s 预估不一致 —— 客户端
> 以提交响应的 `estimate_ms`(150000)为耗时基准,以 `poll.next_poll_after_ms` 为轮询节奏。
> 也可改用 `GET /v1/tasks/:bid/stream`(SSE)免轮询。

---

## 10. 错误码总表(均含代码来源)

业务码经 `domain.GetErrorCode`(`errors.go:115-215`)映射;经 `Error` 辅助返回时 **HTTP 200 + Envelope `code`**。

| Envelope `code` | message | HTTP | 含义 / 场景 | 代码来源 |
|---|---|---|---|---|
| `0` | success / accepted | 200 / 202 | 成功 | `response.go:60,83` |
| `400` | (动态) | 400 | 请求体非法 / 路径参数空 | `response.go:122-129` |
| `401` | (动态) | 401 | 无 / 无效 JWT | `response.go:132-139` |
| `404` | 管线不存在 | 404 | `GET /v1/pipelines/:code` 未找到 | `pipeline_handler.go:76-78`、`response.go:152-159` |
| `40001` | 参数校验失败 | 400 | `params` 空 / 后处理子系统未装配 / `pipeline_code` 模板不存在(带 `details`) | `errors.go:18`、`response.go:237-246`、`task_handler.go:104-109` |
| `40200` | 余额不足 | 200 | 冻结积分失败 | `errors.go:126-127`(`ErrInsufficientCredits`) |
| `40420` | 任务不存在 | 200 | `GET /v1/tasks/:bid` 任务不存在 / 非本账号 | `errors.go:120-121`(`ErrTaskNotFound`) |
| `40920` | 任务状态冲突 | 200 | 非法状态转移 | `errors.go:122-123`(`ErrInvalidStatusTransition`) |
| `45100` | 内容审核未通过 | 200 | Prompt 命中安全过滤(管线提交路径不走此审核;列此为通用任务码) | `errors.go:132-133` |
| `50000` | 服务内部错误 | 200 | 建任务 / 入队失败等未分类错误 | `errors.go:212-213` |

> 任务**执行期失败**不走上述 HTTP 错误码 —— 而是任务终态 `status="failed"` + `error_code`(见 §9.4)。
> HTTP 错误码只覆盖**提交期 / 查询期**。

---

## 11. 完整对接时序

```
① 发现           GET /v1/pipelines                    → 取 code="storeshot_v1"
                  (可选 GET /v1/pipelines/:code 取详情)

② 准备截图        客户端自有 CDN / 经 POST /v1/uploads/sign 双段直传
                  → 得到 screenshots[] 的可访问 URL

③ 提交           POST /v1/tasks
                  { pipeline_code:"storeshot_v1",
                    params:{ app_name, app_description, languages, tone, screenshots:[...] },
                    idempotency_key:<uuid> }
                  → 202 { task_id, poll_url, estimate_ms:150000 }

④ 等待           轮询 GET /v1/tasks/:bid,按 data.poll.next_poll_after_ms 节奏
                  (或 GET /v1/tasks/:bid/stream SSE)
                  → status: pending → processing → completed / partial / failed

⑤ 取产物         status ∈ {completed, partial}:
                    快路径 → output_metadata.final_urls[]   (Provider 永久 URL,立即可用)
                    托管路径 → 继续轮询至 candidates[].url 非空 (R2 托管,带生命周期)
                  status == failed:
                    读 error_code / error_message,据 §9.4 处理

⑥ (可选) 入库   候选可经 POST /v1/candidates/:bid/save 保存进资产库 —— 见 creation.md
```

幂等:同一 `account_id` + `idempotency_key` 重复提交直接返回首次任务(`submit_task_handler.go:353-361`),
不重复扣费 —— 网络抖动重试安全。

---

## 12. 已知限制与上线前置

| 项 | 说明 | 证据 |
|---|---|---|
| **新环境上线前置** | 主 seed 不含 `gen_post_process_templates` → 必须额外跑 `docs/migrations/20260815a_storeshot_v1_baseline_seed.sql`(幂等 + 自校验),否则目录空 / 提交 40001 | `scripts/db/export-seed-data.sh:33-48`(表清单无 gen_*) |
| 算价端点不支持管线 | `POST /v1/tasks/estimate` 仅认 `model_version_bid`,管线无法预估价 | `estimate_cost_handler.go:13`、`task_handler.go:296-300` |
| 目录不暴露价格 | `GET /v1/pipelines` 的 `PipelineDTO` 无 cost 字段,客户端无法对接前展示单价 | `pipeline_handler.go:26-34` |
| `params` 字段无提交期校验 | 仅校验 `params` 非空;字段错误延后到执行期暴露(`screenshots` 缺失=硬失败) | `dto/task.go:21-25`、`image_stylize_processor.go:88-90` |
| 候选 URL 非即时 | 任务 `completed` 时候选可能仍 `pending`,`candidates[].url` 为空,需续轮询或改用 `final_urls` | `candidate.go:155`、`get_candidate_handler.go:158` |
| 崩溃重投保守失败 | Worker 进程在终态回写前崩溃,重投递时管线**不重跑**,直接 `failed`+退款,需重新提交 | `worker.go:346-359` |
| 多语言为 LLM 行为 | 输出语言数 = LLM 依 `languages` 返回的 `copy_map` 键数;Prompt 种子注明"Phase 1 单语言" | `storeshot_copy_generator` 模板正文、`image_stylize_processor.go:97-103` |
| 候选无服务端维度过滤 | 候选 `metadata{screenshot_index, lang}` 已落库,但查询层无 metadata 过滤(仅 status);客户端需拉全量后自行按截图/语言分组 | `worker.go:518-522`、`ent_candidate_repository.go::ListByAccount`(仅 StatusIn) |

---

## 附:源文件索引

| 关注点 | 文件 |
|---|---|
| HTTP 提交 / 查询 | `internal/creation/port/http/task_handler.go`、`pipeline_handler.go`、`routes.go` |
| 提交命令 + 管线分支 | `internal/creation/app/command/submit_task_handler.go` |
| 请求 / 响应 DTO | `internal/creation/app/dto/task.go`、`internal/creation/app/query/get_task_handler.go`、`get_candidate_handler.go` |
| 管线目录查询 | `internal/creation/app/query/pipeline_query_handler.go` |
| 管线 / 模板领域模型 | `internal/creation/domain/postprocess/{pipeline,template,status,errors}.go` |
| 编排执行 | `internal/creation/app/postprocess/orchestrator.go` |
| Worker(task-as-primary) | `internal/creation/infra/postprocess/worker.go` |
| 步骤处理器 | `internal/creation/infra/postprocess/{llm_copy,image_stylize}_processor.go` |
| Prompt+Provider 桥接 | `internal/bootstrap/bridges.go:1944-2138`(LLM 1944 / Image 2021 / appendReferenceImage 2121)+ `creation_step_image_bridge_test.go` |
| 业务错误码 | `internal/creation/domain/errors.go`、`internal/shared/errors/errors.go` |
| 种子数据(管线模板) | `docs/migrations/20260815a_storeshot_v1_baseline_seed.sql`(幂等,自校验;原 p8_07 已退役删除) |
| 种子数据(Prompt / 定价 / Provider 目录) | 分域迁移:provider 目录 `20260812d` · 定价 `20260815b` · Prompt 模板 pt seed 迁移族(旧单文件主 seed 已废弃) |
