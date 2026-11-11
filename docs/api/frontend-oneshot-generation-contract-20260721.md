# 「一句话生成」端到端契约(客户端对接版,2026-07-21)

> 适用:一句话短剧 / 小说漫画 / 音乐 MV 等模板管线的单次生成流。
> 服务端执行模型是**会话锚定**的:一次生成 = 会话里一条消息触发一个 workflow run,
> 进度与结果走会话级 SSE。客户端 UI 不必暴露「会话」概念——每次生成静默新建即可,
> 「历史记录 / 继续改 / 重拍」天然复用同一会话。
>
> 通用约定:所有请求带 App 签名 + JWT;信封 `{code, message, data, request_id, timestamp}`,
> `code=0` 成功。字段均 snake_case。

## 0. 时序总览

```
(可选) POST /v1/skills/match            技能发现 → skill_version_bid
(推荐) POST /v1/plan-previews           计划卡: 槽位表单 + 变量缺口 + 预算 (零副作用)
        POST /v1/conversations           建会话 (执行容器)
        POST /v1/conversations/:bid/messages   确认提交 → {message, run}
        GET  /v1/conversations/:bid/events     SSE: 进度/槽位/终态 (断线续传)
(收尾)  GET  /v1/runs/:bid  ·  GET /v1/conversations/:bid/messages
        POST /v1/candidates/:bid/save          用户点选留存候选
```

## 1. 计划卡预览(推荐接入,当前客户端缺失)

`POST /v1/plan-previews` — 零副作用只读。**首次调用可不传 variables**:
返回的 `slots` 就是渲染表单的数据源,`variable_gaps` 全量列出缺口
(2026-07-21 起;之前版本缺变量直接 40043,已修)。

```jsonc
// 请求 (agent 路径; 技能路径改传 skill_version_bid, 见工作台契约文档 §3.1)
{ "agent_bid": "...", "variables": { "idea": "..." } }   // variables 可省略/可部分
```

```jsonc
// data
{
  "workflow_version_ref": "...",
  "est_total": 120, "run_level_hold": 80, "envelope_cap": 200,   // 积分预算信封
  "steps":  [ { "node_id": "...", "kind": "llm|capability|tool|creation", "est_credits": 10 } ],
  "slots":  [ { "name": "idea", "type": "string", "required": true, "has_default": false } ],
  "variables_valid": false,          // false → 禁用「开拍」按钮
  "variable_gaps": [                 // 全量缺口, 一次回全部
    { "name": "idea", "reason": "missing_required", "detail": "..." }
  ]
}
```

`reason` 词表:`missing_required` / `undeclared` / `invalid_value`(类型不符或 null)
/ `too_large` / `not_serializable`(后两者 `name` 为空)。
**`variable_gaps` 为空 ⇒ 提交必过**(与提交同一套校验规则,服务端等价性测试守卫)。

## 2. 建会话

`POST /v1/conversations`

```jsonc
// 请求
{ "agent_bid": "019eb9cd-...", "title": "一句话短剧" }
// data
{ "bid": "...", "workspace_bid": "...", "agent_bid": "...", "owner_account_bid": "...",
  "title": "...", "status": "active", "total_messages": 0, "created_at": "...", "updated_at": "..." }
```

## 3. 确认提交(触发 run)

`POST /v1/conversations/:conv_bid/messages`

```jsonc
{
  "content": "开拍",                        // 用户话语, 入会话历史
  "idempotency_key": "uuid",               // 必传: 防重复提交双扣
  "variables": {                           // 结构化槽位入参 (预览 §1 校验过的那套)
    "idea": "...", "hero_bid": "...", "hero_name": "林晚",
    "style": "国漫", "voice": "Kore", "shots_count": 4
  },
  "execution_mode": "workflow",            // 可选 (agent 定义已默认 workflow 可省)
  "skill_version_bid": "...",              // 可选: 技能路径 (非空强制 workflow, agent_bid 不参与)
  "estimated_credits": 0                   // 可选: 客户端预期价 (预览 est_total), 服务端核对
}
```

```jsonc
// data
{
  "message": { "bid": "...", "conversation_bid": "...", "role": "user", "content": "开拍", "created_at": "..." },
  "run":     { "bid": "...", "state": "created", "execution_mode": "workflow",
               "timeout_seconds": 300, "total_credits_charged": 0, ... }
}
```

拿到 `run.bid` 后立刻转 §4 订阅 SSE。

**提交错误码**:`40043` 变量校验失败(预览 §1 做对了就不会遇到)· `40041` 执行模式冲突
· `40422/40937/40304` 技能不存在越权/不可执行/工具缺失(技能路径)
· `40203` 项目池积分不足 / `40332` 池不可用(池计费 workspace)· 钱包不足见钱包错误段
· `40934` 会话已结束 · `40930/40931` run 状态类。

## 4. SSE 事件流(**当前客户端主要缺陷在此,见 §7**)

`GET /v1/conversations/:conv_bid/events`
Header:`Accept: text/event-stream` · `Last-Event-ID: <上次收到的最大 id>`(首连传 `0`)

**协议行为(服务端实现约定,客户端必须按此实现):**

| 行为 | 值 | 客户端要求 |
|---|---|---|
| 事件 id | 会话内单调 `conv_seq` | 持久化最后 id,重连回传 `Last-Event-ID` |
| 补传 | 连接先从 DB 全量补 `> Last-Event-ID` 的事件,再转实时 | 无需另拉历史接口 |
| 心跳 | 每 **15s** 一条注释帧 `:ka` | **禁用 receive/idle 超时**,或设 >30s |
| 会话轮转 | 连接最长 **5 分钟**,服务端发 `event: done` `{"reason":"session timeout"}` 后关闭 | 收到 `done` 或断线 → **立即带 Last-Event-ID 重连**(事件零丢失) |
| 去重 | at-least-once 投递 | 按 id 幂等跳过 `<= 已收 id` 的帧 |
| 并发上限 | 同会话并发流超限返 `42921` | 同会话只开一条流 |

**事件类型词表(封闭集;进度类瞬时信息刻意不持久化不补传):**

```jsonc
// event: run.status — run 终态 (成功才计费)
{ "run_bid": "...", "state": "succeeded", "credits_charged": 120 }
{ "run_bid": "...", "state": "failed", "error_code": 50021 }
{ "run_bid": "...", "state": "cancelled" }

// event: task.slot — 单个镜头/槽位完成, 候选就绪 (边生成边渲染的关键)
{ "run_bid": "...", "task_bid": "...", "node_id": "shot_gen",
  "status": "completed", "batch_index": 2, "batch_total": 4,
  "candidates": [ { "bid": "...", "asset_bid": "...", "url": "https://..." } ] }

// event: approval.requested — 人工确认/预算增补挂起 (恢复走 POST /v1/runs/:run_bid/approvals)
{ "run_bid": "...", "prompt": "..." }

// event: system.notice — 降级横幅/系统通知
// event: done — 本条 SSE 连接轮转 (非业务终态!), 重连即可
```

UI 建议:`task.slot` 按 `batch_index/batch_total` 渐进点亮镜头格子;`run.status`
终态后收尾(§5);`failed` 用 `error_code` 对错误码表展示可读文案。

## 5. 收尾读取

- `GET /v1/runs/:bid` — run 终态、token/积分实耗(对账「本次花了多少」)。
- `GET /v1/conversations/:bid/messages` — assistant 消息(文案类产物)。
- 候选留存:`POST /v1/candidates/:bid/save` → `{ "candidate_bid", "asset_bid", "task_bid", "version_bid" }`
  (2026-07-21 起 snake_case + `version_bid`;编辑类任务留存语义见工作台契约 §3.5.1)。
- 中断:`POST /v1/runs/:bid/cancel`。

## 6. 迭代(重拍/继续改)

同一 `conversation_bid` 再 POST 一条 message 即可——上下文与记忆自动携带。
重拍单镜头用 shot-reshoot 技能(`skills/match` 发现),变量引用原 run 的镜头产物。

## 7. 当前客户端待改进清单(按 2026-07-21 抓包日志)

1. **[必改] SSE 被 20s 超时掐断**:日志显示 events 连接 20057ms 后按普通请求「完成」
   ——是客户端 dio receiveTimeout 干的。服务端心跳 15s、连接最长 5min 轮转,
   照 §4 表实现:SSE 请求单独禁用 receiveTimeout + `done`/断线自动重连带 Last-Event-ID
   + 按 id 去重。**不修这个,超过 20 秒的生成(短剧必然超)前端会误判失败。**
2. **[推荐] 接入 §1 计划卡预览**:当前客户端本地拼好全部变量直接提交,缺预算展示
   (est_total 用户见价确认)且变量错误要到提交才发现(40043)。预览的 `slots` 渲染表单、
   `variable_gaps` 标字段错、`variables_valid=false` 禁用按钮。
3. **[推荐] 短剧入口切技能路径**:传 `skill_version_bid`(来源 `POST /v1/skills/match`)
   替代硬编码 `agent_bid`,吃技能治理红利(pin 版本/质检清单/健康度),服务端两路径长期并存。
4. **[小] `Last-Event-ID: 0` 首连正确**;重连时务必换成实际收到的最大 id,否则全量重放。
