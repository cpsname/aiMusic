# Agent 能力接口文档 — 测算族 · 生成管线族 · 治理可见面

> 覆盖 2026-07-11 三批交付的全部 10 个 published Agent 的对外接口:
> **B 族(测算,6 个,会话式)** + **A 族(生成管线,4 个,workflow 式)** + 治理层对调用方可见的语义。
> 通用前置(BaseURL / App 签名 / JWT / 信封 / 通用错误段)见 `docs/api/overview.md`,本文不重复;
> 文中所有 bid 均为 **dev 环境真实值,仅作示例**——bid 跨环境不稳定,生产接入以运营下发 / 发现接口为准。

---

## 0. 快速索引

| Agent code | bid(dev 示例) | 形态 | 一句话能力 |
|---|---|---|---|
| `tarot_master` | `019f2768-ef7d-788c-84ac-1dbf441896a0` | react 会话 | 塔罗抽牌解读(服务端确定性抽牌,LLM 只解读) |
| `dice_oracle` | `019f2768-ef82-7a7f-bf8a-a47dcf54d7f1` | react 会话 | 掷骰吉凶(掷骰 + 规则表定档,LLM 只叙事) |
| `astro_master` | `019f2768-ef82-7e63-858a-ce70f9aa4b79` | react 会话 | 本命盘解读(自研星历引擎,行星黄经 ≤0.01° 对齐 JPL) |
| `synastry_master` | `019f2768-ef83-7165-91c6-7f6e420fa90a` | react 会话 | 双人合盘(双盘 + 相位 + 五维契合分) |
| `dream_palm_master` | `019f2768-ef83-758f-8e9b-1ba94d70c497` | direct 会话 | 梦境/手相解析(纯 LLM) |
| `theme_master` | `019f2768-ef83-79c5-a77a-b18b41ab9e36` | direct 会话 | 主题运势(纯 LLM,可用评分档位表) |
| `short-drama-v1` | `019eb9cd-3b75-725a-96c6-9cae91f8f3ef` | workflow | 一句话创意 → 短剧成片(剧本→分镜图→旁白→合成) |
| `novel-comic-v1` | `019eb9cd-3b84-7f91-afc3-7664f9630d8b` | workflow | 小说文本 → 漫剧成片(改编→角色卡→分镜→合成) |
| `music-mv-v1` | `019eb9cd-3b88-749a-afc5-94de9cea8c92` | workflow | 音乐资产 → MV 成片(分镜→图→按节奏合成) |
| `shot-reshoot-v1` | `019f4f72-a108-753a-b8fc-bcb4d1709fc0` | workflow | 失败/不满意镜头重拍并回填合成(partial 补拍) |

**入口目录发现(接入起点)**:agent 入口清单不硬编码、不走 `app/init` —— 从
**`GET /v1/app/config`** 的 `data.config.agents` 读取(与 kill-switch/维护态同源,
按分发数据行下发;运营改行即灰度/熔断,`enabled=false` 或条目缺席 = 入口隐藏):

```json
{ "config": { "agents": [
    { "code": "short-drama-v1", "bid": "019eb9cd-…", "enabled": true }, …
] } }
```

所有请求走统一中间件链:**App HMAC 签名头**(`X-Distribution-Code / X-Timestamp / X-Nonce / X-App-Signature`,算法 `pkg/aigcsign`)+ **JWT**(`Authorization: Bearer`)。响应统一信封:

```json
{ "code": 0, "message": "success", "data": { ... }, "request_id": "uuid", "timestamp": 1760000000 }
```

---

## 1. B 族(测算)— 会话式接入

### 1.1 通用链路

```
POST /v1/conversations                      创建会话(绑定 agent)
POST /v1/conversations/:conv_bid/messages   发一条用户消息 → 创建 run
GET  /v1/conversations/:bid/messages        轮询消息(或走 1.3 SSE)
GET  /v1/conversations/:bid/events          会话级统一 SSE(推荐)
```

**① 创建会话**

```http
POST /v1/conversations
{ "agent_bid": "019f2768-ef7d-788c-84ac-1dbf441896a0", "title": "感情牌阵" }
```

响应 `data` 为会话 DTO,取 `bid`(下称 `conv_bid`)。

**② 发消息(创建 run)**

```http
POST /v1/conversations/{conv_bid}/messages
{
  "content": "我和暗恋的人最近有进展吗?帮我抽三张牌看看过去、现在和未来。",
  "idempotency_key": "xy-tarot-20260712-0001"
}
```

响应 `data`:

```json
{
  "message": { "bid": "…", "role": "user", "content": "…", "created_at": "…" },
  "run":     { "bid": "…", "state": "queued", "execution_mode": "react", "timeout_seconds": 300, "created_at": "…" }
}
```

- `idempotency_key` 强烈建议携带:**平台保证**同会话同 key 幂等 —— 重试返回既有 run(不重复冻结、不重复创建;查重 + `rt_run_idempotency` 唯一约束双层兜底)。
- 流式变体:`POST /v1/conversations/:conv_bid/messages/stream`(SSE 逐 token,配置门 `runtime.streaming.enabled`)。

**③ 取结果** — 轮询 `GET /v1/conversations/{conv_bid}/messages?limit=50`,直到出现新的 `role=assistant` 消息;消息 DTO:

```json
{
  "bid": "…", "run_bid": "…", "role": "assistant",
  "content": "亲爱的,让我们看看牌面。……本内容仅供娱乐参考,不构成医疗、法律或投资建议。\n\n```json\n{…}\n```",
  "tool_calls": [ … ], "tokens_used": 812, "created_at": "…"
}
```

中间还会出现 `role=tool` 消息(服务端工具的原始输出,客户端可用于校验/展示动画,见各 agent 小节)。

### 1.2 输出协议(六 agent 统一)

助手最终消息 = **正文(口语化解读,含固定免责短语)+ 末尾一个 ```json fence**:

```
…正文若干段…

本内容仅供娱乐参考,不构成医疗、法律或投资建议。

```json
{ "result": { …各 agent 专属 schema… }, "suggested_questions": ["…","…"] }
```
```

客户端解析约定(与 xing_yuan `_parseAnswer` 同语义):取**首个** ```json fence 解析;无 fence / 解析失败 → 整段按纯文本兜底展示。`suggested_questions` 用于追问引导气泡。

**平台保证**(守卫级,非尽力而为):
- 免责短语 `本内容仅供娱乐参考` 逐字出现在正文(模板协议段与 CI rubric 双向钉死);
- 计算结果字段(牌面/点数/星位/档位)**逐字段照抄服务端工具输出**——LLM 无权改写;客户端可拿 `role=tool` 消息做一致性校验;
- 不输出医疗诊断 / 投资承诺 / 婚姻裁决类结论(对抗 case 进 golden 评测)。

### 1.3 会话级 SSE(推荐替代轮询)

```http
GET /v1/conversations/{conv_bid}/events
Last-Event-ID: 0        ← 断线续传游标(=conv_seq;0 或缺省 = 全量回放后接实时流)
```

事件类型:`run.status`(run 状态翻转)、`task.slot`(A 族创作任务槽位进度)、`approval.requested`(人工确认请求)。单连接上限 5 分钟(到点重连,带 Last-Event-ID 无缝续传);每会话并发流有配额,超限返回 `42921`。

**流的存活保证(2026-08-23 起,客户端接入必读)**:

- 建流**立即**收到注释帧 `: connected`;PG 补传完(空会话 = 紧接着)收到 `: ready seq=<n>`(n = 当前游标,与 Last-Event-ID 同坐标系)—— 首字节零延迟,客户端的首包看门狗**不要**因为几秒没有事件就判流死亡;
- 静默期每 **5 秒**一条心跳注释 `: ka` —— 客户端的空闲超时必须 **> 5 秒**(建议 ≥15s);
- **事件时效**:事件经 outbox → worker → 投影落库,run 状态翻转到事件可见存在秒级延迟(实测 ~2-4s);**短平快 run 可能只有终态一条 `run.status` 事件**(queued/running 过渡态不投影)—— 进度条类 UI 不要假设逐态都有事件,以 `: ready` 后收到的终态为准;
- 客户端实现要点:必须以**流式**方式消费(`Accept: text/event-stream`,禁止按整包 JSON 读取);主动关闭(如 run 已完成)不要记为"流不可用";重连恒带 `Last-Event-ID`。

### 1.4 tarot_master(塔罗)

- **服务端工具**:`seeded_draw`(确定性抽牌)。LLM 发起 `tool_call` → 平台执行 → 结果进对话。
- **`role=tool` 消息 content**(真实输出形状):

```json
{
  "items": [
    { "id": "0",  "name": "愚者", "is_reversed": false, "position": "过去" },
    { "id": "8",  "name": "力量", "is_reversed": true,  "position": "现在" },
    { "id": "17", "name": "星星", "is_reversed": false, "position": "未来" }
  ],
  "seed": "e3b0c44298fc1c149afbf4c8996fb924",
  "seed_material": "run:10021|call:1",
  "dataset_size": 78
}
```

  确定性语义:同一 run 内重试**逐字节复现**(seed = HMAC(密钥, run|call));换一次提问(新 run)= 重新抽。"一直问到好为止" 是产品语义上允许的重抽,对抗 case 已覆盖话术引导。

- **最终 result 契约**:

```json
{
  "result": {
    "tarot_cards": [ { "id": "0", "name": "愚者", "is_reversed": false, "position": "过去" }, … ],
    "keywords": ["转变", "希望"]
  },
  "suggested_questions": ["我该主动吗?", "时机在何时?"]
}
```

  `tarot_cards[]` 的 `name/is_reversed/position` 与工具输出逐字段相等(golden 断言 `resultItemsSubset`)。

### 1.5 dice_oracle(掷骰)

- **工具链**:`seeded_draw`(掷 3×d6)+ `rule_table_eval`(总和 → 吉凶档)。
- **rule_table_eval 输出**(表 `dice_fortune_3d6`,服务端硬编码,LLM 无权改档):

```json
{ "table": "dice_fortune_3d6", "value": 14, "fortune": "中吉", "fortune_level": 4 }
```

  档位映射:3-6 凶 / 7-9 平 / 10-12 小吉 / 13-15 中吉 / 16-18 大吉。
- **result 契约**:`result.values`(骰面数组,照抄)+ `fortune/fortune_level`(照抄)+ 叙事字段。

### 1.6 astro_master(本命盘)

- **工具**:`ephemeris_chart` — **自研手写星历引擎**(VSOP87B + Meeus 章动/黄赤交角/ΔT + Moon Ch.47 + Pluto Ch.37),行星视黄经与 JPL Horizons 对齐 ≤0.01°(60 样本实证)。不依赖任何外部 API,离线可复现。
- **工具输入**(LLM 从用户话语中抽取后调用;客户端无需直接调):

```json
{ "person": { "date": "1995-08-17", "time": "06:30", "tz_offset_hours": 8, "lat": 30.25, "lon": 120.17 } }
```

  校验域:date 1900–2099 / tz ∈ [-12,14] / lat ∈ [-90,90] / lon ∈ [-180,180];`time` 可缺省(无时辰模式,不给上升/宫位,正文会说明局限)。
- **工具输出形状**:

```json
{
  "chart": {
    "planets": {
      "sun":  { "lon": 144.12, "sign": "狮子座", "sign_en": "Leo",   "deg_in_sign": 24.12 },
      "moon": { "lon": 267.9,  "sign": "射手座", "sign_en": "Sagittarius", "deg_in_sign": 27.9 },
      "…":    "mercury/venus/mars/jupiter/saturn/uranus/neptune/pluto 同构"
    },
    "ascendant": { "lon": 172.4, "sign": "处女座", "sign_en": "Virgo", "deg_in_sign": 22.4 },
    "houses":  [ … ],
    "aspects": [ { "body1": "sun", "body2": "moon", "name": "拱", "name_en": "trine", "angle": 120, "orb": 1.2 }, … ]
  }
}
```

### 1.7 synastry_master(合盘)

- 同 `ephemeris_chart`,输入多一个 `partner`(同 person 结构);输出额外含:

```json
{
  "partner_chart": { …同 chart 结构… },
  "synastry_aspects": [ { "body1": "sun", "body2": "moon", "name": "合", "name_en": "conjunction", "angle": 0, "orb": 0.8 }, … ],
  "compatibility_scores": { "overall": 78, "emotional": 82, "communication": 71, "values": 80, "stability": 74 }
}
```

  五维分值由服务端相位规则计算,LLM 照抄叙事,**不得**输出"必须离婚/分手"类裁决(rubric 禁用模式)。

### 1.8 dream_palm_master / theme_master(纯 LLM)

无工具调用(theme 可选用 `rule_table_eval` 的 `score_band_5` 表:0-100 → 低迷/平稳/向好/顺遂/极佳)。输出协议同 §1.2。手相场景当前为文字描述解析;图片理解能力上线后接口不变(消息带资产引用)。

### 1.9 计费(B 族)

测算三工具 `pricing_cents_per_call = 0`(零冻结路径);计费主体为 LLM run(按 token → 积分,run 结束结算,`run.total_credits_charged` 可查)。余额不足在发消息时即被拒(钱包错误段)。

---

## 2. A 族(生成管线)— workflow 式接入

### 2.1 通用链路(与 B 族同端点,多两步)

```
POST /v1/plan-previews                       ① 计划卡预览(零副作用,强烈建议先调)
POST /v1/conversations                       ② 创建会话(绑定管线 agent)
POST /v1/conversations/:conv_bid/messages    ③ 携 variables 发起 → workflow run
GET  /v1/conversations/:bid/events           ④ SSE 跟进(task.slot 槽位进度)
GET  /v1/runs/:bid                           ⑤ run 详情(节点级观测)
POST /v1/runs/:bid/cancel                    ⑥ 取消(级联在途创作任务)
POST /v1/runs/:bid/approvals                 ⑦ 人工确认(预算加注等挂起时)
```

### 2.2 计划卡预览(真实案例:短剧)

**请求**:

```http
POST /v1/plan-previews
{
  "agent_bid": "019eb9cd-3b75-725a-96c6-9cae91f8f3ef",
  "variables": {
    "idea": "外卖骑手捡到一枚会说话的戒指",
    "hero_bid": "0e2b8a3c-…(角色包 character_bid)",
    "hero_name": "阿豪"
  }
}
```

**响应 `data`**(`WorkflowPlanCardDTO`):

```json
{
  "agent_bid": "019eb9cd-3b75-725a-96c6-9cae91f8f3ef",
  "workflow_version_ref": "019f5…(已 pin 的 workflow 版本 bid)",
  "est_total": 320,
  "run_level_hold": 20,
  "envelope_cap": 352,
  "steps": [
    { "node_id": "script",     "kind": "llm",      "est_credits": 20 },
    { "node_id": "gen_images", "kind": "creation", "est_credits": 100, "self_frozen": true },
    { "node_id": "gen_voice",  "kind": "creation", "est_credits": 100, "self_frozen": true },
    { "node_id": "assemble",   "kind": "creation", "est_credits": 100, "self_frozen": true }
  ],
  "slots": [
    { "name": "hero_bid",    "type": "string",  "required": true },
    { "name": "hero_name",   "type": "string",  "required": true },
    { "name": "idea",        "type": "string",  "required": true },
    { "name": "shots_count", "type": "integer", "required": false, "has_default": true, "default": 6 },
    { "name": "style",       "type": "string",  "required": false, "has_default": true, "default": "国漫" },
    { "name": "voice",       "type": "string",  "required": false, "has_default": true, "default": "Kore" }
  ]
}
```

关键契约:
- **预览通过 ⇒ 提交必过**:预览与提交路径用同一槽位校验器。缺必填 / 类型不符 → `40043`,message 指名字段(如 `workflow variables invalid: required variable "idea" missing`)。
- 预算信封:`run_level_hold` 是 run 级预冻结;`self_frozen: true` 的 creation 节点由创作域**自冻结自结算**(不重复冻结);`envelope_cap` = 超支硬顶(超出即挂起或失败,依 topup 配置)。
- `est_*` 为预估;实扣以 run 结束的 `total_credits_charged` 与节点 `cost_credits` 为准。

### 2.3 发起 workflow run

```http
POST /v1/conversations/{conv_bid}/messages
{
  "content": "开拍",
  "idempotency_key": "xy-drama-20260712-0007",
  "variables": {
    "idea": "外卖骑手捡到一枚会说话的戒指",
    "hero_bid": "0e2b8a3c-…", "hero_name": "阿豪",
    "style": "国漫", "shots_count": 6
  }
}
```

`variables` 白名单严格:未声明的键直接 `40043 undeclared variable "xxx"`(各管线槽位表见 §2.6)。

### 2.4 进度与节点级观测

**SSE(§1.3 同端点)**:`task.slot` 事件随每个创作任务槽位翻转推送(排队→生成中→完成/失败);`run.status` 推 run 态;`approval.requested` 推预算加注等确认请求(客户端弹窗 → `POST /v1/runs/:bid/approvals` 回填决定)。

**run 详情** `GET /v1/runs/{run_bid}` → `RunPublicDTO`,workflow run 含节点数组:

```json
{
  "bid": "…", "state": "running", "execution_mode": "workflow",
  "total_credits_charged": 120,
  "workflow_nodes": [
    { "node_id": "script",     "status": "succeeded", "cost_credits": 18, "model_code": "…", "started_at": "…", "finished_at": "…" },
    { "node_id": "gen_images", "status": "running",   "task_bids": ["019f…", "019f…"] },
    { "node_id": "assemble",   "status": "pending" }
  ]
}
```

`workflow_nodes[].task_bids` 即创作任务 bid,可逐个查任务详情/产物(`GET /v1/tasks/:bid`,SSE 进度 `GET /v1/tasks/:bid/stream`,血缘 `GET /v1/tasks/:bid/lineage`);`cost_credits/model_code` 直答"这单烧了多少、用了什么模型"。

### 2.5 取消与部分成功

- **取消 run**:`POST /v1/runs/{bid}/cancel` — 级联取消在途 creation 任务(pending 的即时取消退款;**已被上游模型受理的任务多数供应商不支持中断**,该任务照常结算,后续节点不再执行)。单任务直取消:`POST /v1/tasks/{bid}/cancel`(同样仅 pending 可取消)。
- **部分成功(partial=continue)**:批量镜头节点配置 `on_partial=continue + min_success`——部分镜头失败不整单报废:成功项照常进入合成,失败项退款,run 正常完成并在节点 `reason`/产物清单标记缺口;不足 `min_success` 才整节点失败。

### 2.6 四条管线的槽位契约与真实案例

**short-drama-v1(短剧)** — 必填 `idea / hero_bid / hero_name`;可选 `style`(默认 国漫,可选 写实/水墨/赛博)、`voice`(默认 Kore)、`shots_count`(默认 6,域 4..12)。案例见 §2.2/§2.3。

**novel-comic-v1(小说转漫剧)** — 必填 `hero_bid / hero_name / novel_text`(≤5 万字,长篇按章分批);可选 `style`(国漫)、`voice`(Charon)、`shots_count`(默认 12,域 6..16)、`chapter_hint`(如 `"第三章"`,空=全文/开篇)。

```json
{
  "variables": {
    "hero_bid": "0e2b8a3c-…", "hero_name": "林晚",
    "novel_text": "第一章 夜色如墨。林晚推开老宅斑驳的木门……",
    "chapter_hint": "第一章", "shots_count": 10
  }
}
```

管线内部经 `register_character` 把改编中提炼的配角自动注册为角色资产并与主角 `hero_bid` 一起锚定各镜头(跨镜头角色一致性);提炼出的角色卡在 run 产物中可见。

**music-mv-v1(音乐 MV)** — 必填 `music_asset_bid`(**已上传的音乐资产 bid,用户须确认拥有版权**);可选 `style`(赛博霓虹)、`shots_count`(默认 12,域 8..18)。音频先经节奏分析,镜头切点按节拍对齐。

**shot-reshoot-v1(镜头补拍)** — 8 槽位,全部服务于"对已完成/部分成功的短剧 run 重拍个别镜头并回填合成":

| 槽位 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `hero_bid` | string | ✅ | 与原片相同角色(一致性) |
| `style` | string | 默认 国漫 | 与原片一致 |
| `shots` | array | ✅ | 原 run 的全量分镜列表 |
| `base_images` | array | ✅ | 原 run 成功镜头图 items |
| `base_narrations` | array | ✅ | 原 run 旁白音频 items |
| `reshoot_shots` | array | ✅ | 重拍参数 `[{"prompt": "…"}]` |
| `reshoot_indexes` | array | ✅ | 回填到 base 的下标(与 reshoot_shots 对齐) |
| `output` | object | ✅ | 成片输出规格(与原 run compose output 一致) |

**真实案例**(重拍第 2 镜):

```json
{
  "variables": {
    "hero_bid": "0e2b8a3c-…", "style": "国漫",
    "shots": [ { "index": 1, "prompt": "开场巷口全景" }, { "index": 2, "prompt": "主角在雨中回头" } ],
    "base_images":     [ { "index": 1, "asset_bid": "019f…a001" } ],
    "base_narrations": [ { "index": 1, "asset_bid": "019f…b001" } ],
    "reshoot_shots":   [ { "prompt": "主角在雨中回头, 特写, 雨丝清晰" } ],
    "reshoot_indexes": [ 2 ],
    "output": { "format": "mp4" }
  }
}
```

素材来源:原 run 的 `GET /v1/runs/:bid` → `workflow_nodes[].task_bids` → 任务产物清单(images/narrations 的 asset_bid 与 index)。合成语义:`patch` 按 `reshoot_indexes` 覆盖回 `base` 对应位,其余镜头零重算——只为重拍镜头付费。

---

## 3. 治理层对调用方可见的语义(任务 3)

- **版本 pin 化 = 响应稳定性承诺**:published agent 的提示词/工作流引用在发布瞬间全部定格到确切版本(persona 与 workflow llm 节点均已 pin)。同一 agent 版本的行为不会被后台"改模板"静默变更;任何文案/流程变化都对应一次 republish(`GET /v1/runs/:bid` 的版本可溯源)。
- **run 级版本不可变**:run 创建时定格 agent 版本,执行中途的 republish / 灰度调整不影响在途 run。
- **灰度(canary)对客户端透明**:平台可能按比例把**同一账号稳定地**路由到新版本(sticky,不会同一用户忽新忽旧);接口与协议不变,客户端无需感知。
- **发布门禁 40068**(仅对使用 catalog 发布接口的工作台/运营端有意义):safety 空 / persona 非模板引用 / pin 解析失败 → 拒绝发布,修 definition 后重试。
- **质量基线**:每个 published agent 配 ≥3 条 golden case(含对抗题)入仓,CI 守卫强制;免责短语与"照抄工具输出"是守卫级约束而非提示词软约定。

---

## 4. 错误速查(本文相关段)

| code | 场景 | 客户端处置 |
|---|---|---|
| 40030 | plan-preview 缺 `agent_bid` / 参数非法 | 修参重试 |
| 40043 | workflow variables 校验失败(缺必填/类型/未声明键) | 按 message 指名的字段修表单;预览接口可提前暴露 |
| 40065 | 批量(batch)配置非法 | 服务端配置问题,上报 |
| 40068 | 发布门禁拒绝(发布面) | 修 agent definition 后 republish |
| 42921 | 会话 SSE 并发流超配额 | 复用既有连接;退避重连 |
| 钱包段 | 余额不足/冻结失败 | 引导充值;`plan-preview.est_total` 可做前置余额校验 |

通用约定:`code=0` 即成功;非 0 时 `message` 为英文机读文案,展示层按 code 本地化。

---

## 5. 接入检查清单

1. 所有写操作带 `idempotency_key`(消息发送尤其)。
2. A 族先 `plan-preview`:拿槽位表渲染表单 + 拿 `est_total` 做余额预检;**预览通过则提交不会因 40043 失败**。
3. 进度一律走 `GET /v1/conversations/:bid/events`(SSE),断线用 `Last-Event-ID` 续传;不要高频轮询 messages。
4. B 族解析:首个 ```json fence;无 fence 纯文本兜底;`suggested_questions` 做追问气泡;`role=tool` 消息可做牌面/星盘动画数据源。
5. 取消预期管理:仅未开拍(pending)的镜头可退;已受理的上游任务不可中断。
6. agent bid 按环境配置下发,不要硬编码本文示例值。
