# 前端契约对接 — 云工作台批(2026-07-21,对应服务端 e968115 之后增量)

> 面向 genaistudio-web 前端仓的**新增/变更 HTTP 契约汇总**。
> 通用约定不重复(BaseURL / App 签名 / JWT / 信封 `{code,message,data,request_id,timestamp}` /
> 错误段见 `docs/api/overview.md`)。所有新端点均在既有 auth 中间件链下(App 签名 + JWT)。
> 本批服务端已可部署;**前端未接线前这些面零流量**,可按本档排期接入。

---

## 1. 项目池:任务提交按 workspace 计费(ADR-016 D3)

`POST /v1/tasks` 提交体新增可选字段:

```jsonc
{
  // ...既有字段不变...
  "workspace_bid": "..."   // 非空 = 本次任务计费目标为该 workspace 项目池
}
```

- 语义:服务端硬校验发起人是该 workspace 的活跃成员;池钱包缺失/未授权/积分不足
  **显式报错,绝不回落个人钱包**(防"以为花池的钱实际扣了个人")。
- 空/缺省 = 现行个人钱包路径,行为不变。
- 新错误码:

| code | 含义 | 前端处理建议 |
|---|---|---|
| `40203` | 项目池积分不足 | 引导走 §2 追加申请(自助通道) |
| `40332` | 项目池不可用或无权访问 | 提示联系管理员开通/加入 workspace |

## 2. 项目池:超额预授权申请(ADR-016 D4,用户面)

审批**处置**(批准/驳回/额度配置)在独立 console,App 端只有「申请 + 自查」。

### 2.1 发起申请

`POST /v1/wallet/pool-approvals`

```jsonc
// 请求 (app_id 由签名头解析, 不收 body)
{ "workspace_bid": "...", "requested_total": 500, "reason": "冲刺周需要加渲染量" }
```

```jsonc
// data
{
  "bid": "...",
  "status": "pending",          // pending | approved | rejected | expired
  "amount": 0,                  // approved 后 = 实际发放积分
  "requested_total": 500,
  "reason": "...",
  "resolve_note": "",           // 处置备注 (approved/rejected 后)
  "expires_at": 1753142400,     // Unix 秒; 过期未处置自动 expired
  "resolved_at": null,          // Unix 秒, 终态后非空
  "created_at": 1753056000
}
```

| code | 含义 |
|---|---|
| `40205` | 申请额超出该池的审批余量上限(headroom) |
| `40332` | 池不可用 / 非该 workspace 活跃成员 |

### 2.2 自查列表

`GET /v1/wallet/pool-approvals?limit=20` → `data: { "approvals": [<同上对象>] }`

| code | 含义 |
|---|---|
| `40421` | 申请不存在 |
| `40922` | 申请已终态/已过期(重复处置类冲突) |

前端建议:`pending` 项在钱包页挂待办角标;`approved` 后余额刷新(发放走幂等入账)。

---

## 3. 技能路径(蓝图 §5.6):发现 → 计划卡预览 → 确认提交 → 执行卡

### 3.0 技能发现(话语 → 推荐技能)

`POST /v1/skills/match`(2026-07-21 新开;这是前端拿 `skill_version_bid` 的正式来源)

```jsonc
// 请求
{
  "utterance": "帮我写本周行业周报",  // 必填
  "workspace_bid": "...",            // 空 = 仅平台内置技能; 非空 = 该 workspace 自有 ∪ 内置
                                      // (服务端校验请求者活跃成员身份, 非成员 40301)
  "limit": 5                          // 可选, ≤0 不截断
}
```

```jsonc
// data
{
  "matches": [                        // 按匹配分降序; 空数组 = 未命中 → 走自由对话, 不硬凑
    {
      "skill_bid": "...",
      "name": "行业周报",
      "slug": "weekly-report",
      "version_bid": "...",           // ← 传给 §3.1 预览 / §3.2 提交的 skill_version_bid
      "score": 0.83,                  // (0, 1]
      "matched_keywords": ["周报"],   // 命中依据 (确认卡展示「因为你提到…」)
      "required_tools": ["web_search"],
      "tools": [ { "code": "web_search", "available": true } ],  // 同 §3.1 词表
      "usable": true                  // false = 有缺失工具, 列表可展示但引导受限
    }
  ]
}
```

错误:`40030` utterance 缺失 · `40301` 声明 workspace 非活跃成员 · `40421` workspace 不存在
· `50031` 工具可用性预检通道故障(fail-close,前端按服务端异常处理)。

### 3.1 计划卡预览(技能骨架)

`POST /v1/plan-previews`(零副作用只读;既有 agent 路径不变,新增技能路径)

```jsonc
// 请求二选一: agent_bid (既有) 或 skill_version_bid (新)
{
  "skill_version_bid": "...",   // 技能路径: 骨架 = 该技能版本 pin 的 workflow, agent_bid 不参与
  "workspace_bid": "...",       // 可选; 组织 workspace 技能必传 (越权校验+工具可用性作用域);
                                 // 空 = 仅平台内置技能视角
  "variables": { "topic": "AI" } // 槽位入参, 可省略 — 首次预览拿卡渲染表单, 缺口在卡上 (见 variable_gaps)
}
```

```jsonc
// data (WorkflowPlanCardDTO; 既有字段不变, 新增 skill 段 + 变量缺口段)
{
  "workflow_version_ref": "...",
  "est_total": 120, "run_level_hold": 80, "envelope_cap": 200,
  "steps": [ { "node_id": "...", "kind": "llm|capability|tool|creation", "est_credits": 10 } ],
  "slots": [ { "name": "topic", "type": "string", "required": true, "has_default": false } ],

  "variables_valid": false,             // false → UI 禁用确认 (2026-07-21 起; 之前版本缺变量直接 40043)
  "variable_gaps": [                    // 全量缺口 (一次回全部, 非首错即返); 空/缺省 = 变量齐备
    { "name": "topic", "reason": "missing_required", "detail": "required variable \"topic\" not provided" }
  ],

  "subjects": [                         // 主体锚定就绪度 (骨架用到的角色, 按已填变量解析; 缺省 = 无主体)
    { "character_bid": "...", "name": "林晚", "ready": false,
      "reason": "no_reference_images", "has_prompt_anchor": true }
  ],

  "skill": {                            // 仅技能路径预览返回
    "skill_bid": "...",
    "skill_version_bid": "...",
    "name": "行业周报",
    "slug": "weekly-report",
    "required_tools": ["web_search", "doc_export"],
    "tools": [                          // 与 required_tools 同序, 逐工具可用性
      { "code": "web_search", "available": true },
      { "code": "doc_export", "available": false, "reason": "not_installed" }
    ],
    "usable": false,                    // ⚠ false = 有缺失工具
    "quality_checklist": [ { "key": "has_summary", "label": "...", "rule": {} } ]
  }
}
```

**前端硬规则**:`skill.usable=false` **或** `variables_valid=false` 时**禁用确认按钮**
并醒目展示缺口(服务端提交路径分别硬拒 40304 / 40043,预览宽/提交严是刻意设计 —
成本前置,冻结前拒绝)。`variable_gaps` 为空 ⇒ 提交侧变量校验必过(同一规则,服务端等价性测试守卫)。
`quality_checklist` 用于计划卡预告「完成后将核验哪些项」。

工具不可用 `reason` 词表:`not_found` / `not_installed` / `disabled` / `version_not_approved`。
变量缺口 `reason` 词表:`missing_required` / `undeclared` / `invalid_value`(类型不符/null)
/ `too_large` / `not_serializable`(后两者 `name` 为空,整体性缺口)。

**主体「未定妆」预警**(`subjects`,2026-07-21 新增):`ready=false` 表示该角色**无参考图**,
镜间人像一致性没有图像锚(`reason`:`no_reference_images` 未定妆 / `not_found` 角色不存在或越权)。
这是**画质降级预警不是失败——不要禁用确认按钮**(与 variable_gaps 语义不同);建议 UI 提示
「角色未定妆,建议先生成角色定妆照再开拍」并给跳转;`has_prompt_anchor=true` 时可弱化文案
(有文本锚兜底,发色服装等可锚,人脸仍会漂)。填了角色变量再次预览才会出现此段。

预览错误:`40422` 技能不存在或越权 · `40937` 技能版本不可执行(含纯提示型无骨架)
· `40301` 声明的 workspace 非活跃成员。**变量问题不再报 40043**(2026-07-21 起改为
`variable_gaps` 上卡;40043 仅在确认提交时出现)。

### 3.2 确认提交(技能驱动 run)

`POST /v1/conversations/:conv_bid/messages` body 新增可选字段:

```jsonc
{
  "content": "写本周行业周报",
  "skill_version_bid": "...",     // 非空 = 技能驱动: 强制 workflow 模式, 骨架 = 技能 pin 版本
  "variables": { "topic": "AI" },
  "idempotency_key": "..."
}
```

- `execution_mode` 留空即可;显式传非 `workflow` 值 + 技能 → `40041` 拒绝。
- 全部技能硬闸在 **Freeze 之前**完成,失败零计费:

| code | 含义 | 前端处理 |
|---|---|---|
| `40422` | 技能版本不存在/越权 | 回到技能列表刷新 |
| `40937` | 技能版本不可执行(已重发布/已弃用/纯提示型) | **计划卡过期**:提示重新预览(重发布后旧卡显式失效,不静默执行旧内容) |
| `40304` | 所需工具在当前 workspace 不可用(message 含 `code:reason` 明细) | 展示缺失清单,引导安装/联系管理员 |
| `40041` | 执行模式冲突 | 前端 bug,不应出现 |

### 3.3 执行卡:run 读面新增字段(质检报告)

`GET /v1/runs/:bid`(及所有返回 run 对象的响应)新增:

```jsonc
{
  "bid": "...",
  "skill_version_bid": "...",      // 空 = 非技能路径
  "skill_check_status": "attention", // "" 无质检 | passed | attention | error
  "skill_quality_report": {          // 终态后异步补充 (见下)
    "skill_version_bid": "...",
    "evaluated_at": "2026-07-21T04:00:00Z",
    "results": [
      { "key": "has_summary", "label": "...", "verdict": "passed" },
      { "key": "cover_image", "label": "...", "verdict": "failed", "detail": "output does not contain ..." },
      { "key": "human_review", "label": "...", "verdict": "manual" }
    ],
    "passed": 1, "failed": 1, "manual": 1
  }
}
```

- `verdict` 词表:`passed` / `failed` / `manual`(不可机判,待人工确认)。
- **时序语义**:报告在 run 终态后由 worker **异步**写入(通常秒级)——执行卡先显示
  run 结果,`skill_check_status` 为空时短轮询该 run 或等下次进入页面刷新;
  `attention` = 有 failed 或 manual 项,**醒目待办展示但不阻塞**结果可见/下载。
- `status=error` = 核验流程自身失败(极少),展示「质检未完成」即可。

---

## 3.5 资产版本树(ADR-018 R2,2026-07-21 新增)

留存候选/完成上传的资产自动建**根版本**;后续「回滚到 vN」是纯指针切换。

`POST /v1/assets/:bid/adopt`

```jsonc
// 请求
{ "version_bid": "..." }
// data
{ "asset_bid": "...", "adopted_version_bid": "..." }
```

| code | 含义 |
|---|---|
| `40855` | 版本不属于该资产(越树) |
| `40856` | 资产不存在/越权 |
| `40857` | 版本不存在 |

- 幂等:重复切同一版本零副作用;版本行本身不可变(服务端库层触发器强制)。

`GET /v1/assets/:bid/versions`(R3,2026-07-21 开放)

```jsonc
// data
{
  "asset_bid": "...",
  "adopted_version_bid": "...",   // 空 = pre-tree 平面资产 (无版本行)
  "versions": [                   // version_number 升序
    {
      "bid": "...", "version_number": 1,
      "parent_version_bid": "",   // 空 = 根版本
      "adopted": true,
      "content_sha256": "...", "file_size": 123456,
      "mime_type": "image/png", "width": 1024, "height": 1024,
      "source_task_bid": "...",
      "gen_context": { "prompt": "...", "params": {} }, // 属主可见的生成参数快照
      "url": "https://...",       // 按 access_level 预签名; 生成失败为空可单独重请求
      "url_expires_at": 1753200000,
      "created_at": 1753100000
    }
  ]
}
```

- 存量资产(版本树上线前创建)`versions` 为空数组、`adopted_version_bid` 为空
  —— 前端按「无版本入口」渲染即可,不是错误。
- 前端版本面板建议:采用稿高亮 + 「回滚到此版本」调 adopt;`gen_context`
  可做「查看生成参数」折叠面板。

### 3.5.1 编辑任务留存 = 源资产长新版本(ADR-019,2026-07-21 新增)

原子编辑管线(裁剪/擦除/扩图等 atomic-edit pipeline)的接入契约:

- **提交**:顶层 `params.source_asset_bid` 携带被编辑资产 bid 即可,**无需**手写
  `derivation` 声明 —— 服务端识别到该键自动装配 `type=asset_edit` 谱系
  (显式传了 `derivation` 则以显式为准;给 `asset_edit` 显式携带
  `derived_from_task_bid` 会被拒 40004,谱系父任务由服务端从源资产回填)。
  上传资产直接可编辑(自成谱系根);他人资产 / `pending` 上传态分别拒
  40872 / 40874。
- **留存**(`POST /v1/candidates/:bid/save`):编辑任务的候选留存**不再创建新资产**,
  而是在**源资产**上长一个新版本。响应字段:

```jsonc
{
  "CandidateBID": "...",
  "TaskBID": "...",
  "AssetBID": "...",     // 编辑任务 = 源资产 bid (非新资产!); 普通任务 = 新建资产 bid
  "VersionBID": "..."    // 本次留存产生(或内容重复时复用)的版本 bid; 普通任务留存也回带根版本
}
```

  - **采用稿指针不自动跳**:留存新版本后 `adopted_version_bid` 保持不变,
    用户在版本面板显式点「采用」才切(即 §3.5 的 adopt 端点)。前端留存成功后
    建议弹「已存为版本 vN,是否采用?」引导。
  - 同一资产上留存**内容完全相同**的编辑结果(SHA-256 相同)幂等复用既有版本,
    `VersionBID` 回带已存在的版本 bid,不报错。
  - 源资产是版本树上线前的存量平面资产时,服务端在留存时自动补建根版本
    (`gen_context.source = "backfill_on_edit"`)再挂编辑版本;若存量资产
    缺内容哈希(极老数据)则拒 40858 `not versionable (missing content hash)`。

---

## 4. RAG 引用行为变化(既有接线的前端需知)

- run 的 `citations` 数组结构**不变**,但服务端新增预算截断:默认最多 **8 条**、
  单条 snippet 最长 800 字符(超长以 `…` 截断),编号 `index` 与回答文本中的
  `[n]` 保持严格一致 —— 前端脚注渲染逻辑无需改,但不要再假设 citations 数量无上限。
- 模型提示词中参考资料块增加了「非指令」声明与 `[参考资料结束]` 闭合标记,
  属服务端提示词内部变化,对 API 不可见。

---

## 5. 尚未暴露(排期依赖,勿按猜测接)

| 能力 | 状态 |
|---|---|
| **技能发现** | ✅ 已开(2026-07-21):见 §3.0,前端按此接入 |
| 技能创作/送审/发布 | 管理面,归独立 console(App 端无) |
| 池审批处置(批准/驳回) | console 面(App 端只有 §2 申请+自查) |
| 运行时参数覆盖 `runtime_options` | 灰度门 `runtime.call_options_enabled` 默认关,传了也被忽略 |

## 6. 联调注意

- 新端点/字段全部走既有双中间件链(App 签名 + JWT);`app_id`/`workspace` 授权
  一律服务端裁决,**body 不收 `app_id`**。
- 幂等:消息提交沿用 `idempotency_key`;池申请无幂等键(重复点击会产生多条 pending,
  前端应做提交中禁点)。
- 时间字段:池审批为 Unix 秒;质检报告 `evaluated_at` 为 RFC3339 字符串(跟随各自
  BC 既有惯例)。
