# Live 语音会话 · 客户端契约 v1.0

> **状态**:**服务端已实装**(2026-08-20)。端点 `GET /v1/live/sessions/{conversation_bid}/stream`
> 已在 runtime BC 落地,本文件描述的全部上下行消息、`ready.params` 全量参数、
> `ended.reason` 封闭集均按此实现并有测试守卫。
> **开闸仍需运维动作**:总开关 `runtime.live_audio.enabled` 默认 `false`,
> 且单价须先在 `wal_credit_pricing_rules` seed `live_audio` 行(缺行则建连 fail-close)—— 前置清单见
> [`live-audio-duplex.md`](live-audio-duplex.md) §9。
> **执行方**:`xing_yuan` 仓自行实施。本仓只出契约,不改客户端代码。
> **成文**:2026-08-17 · 依据同上设计文档阶段一~三

---

## 0 · 一句话说清变了什么

**拓扑从「客户端直连 Google」改为「客户端连后端,后端连 Google」。**

| | 旧(已否决) | 新(本契约) |
|---|---|---|
| 音频路径 | 客户端 ↔ Google | 客户端 ↔ **后端** ↔ Google |
| 客户端拿什么 | 临时令牌 `auth_tokens/...` | **只有一条 WS 地址 + JWT** |
| 谁看得见用量 | 只有 Google | **后端**(这是改拓扑的唯一理由:后端拿不到 `usageMetadata` 就无法可信计费) |
| resumption / GoAway | 客户端处理 | **后端处理,客户端完全不感知** |
| 计费 | 按令牌 TTL 预扣 + 客户端上报用时结算 | 后端据实计量(具体形态待定,见 §7) |

### 已废弃的契约

> ℹ️ 平台内(BC 间)对接文档见 [`live-audio-duplex.md`](live-audio-duplex.md) —— 本契约只覆盖客户端 ↔ 后端一段。

`docs/api/live-session.md` 描述的 **`POST /v1/live-sessions` + `POST /v1/live-sessions/:bid/settle`** 两个端点及其令牌模型,在本契约下**不再是客户端的接入路径**。

⚠️ 该文档**尚未下线**(端点仍在服务中,见 `docs/api/endpoint-inventory.md`)。下线时机由平台侧统一裁决(设计文档任务 G-1/G-2/G-3)。**在收到明确下线通知之前,`xing_yuan` 保留旧实现可运行,不要删除。**

---

## 1 · 客户端**不需要改**的部分(先说这个,因为它是大头)

以下经平台侧逐行核对(2026-08-17),**在新拓扑下全部可原样保留**:

| 面 | 文件 | 为什么不用改 |
|---|---|---|
| **传输层抽象** | `lib/features/live/data/live_transport.dart:47-77` | `LiveTransport` 的 5 个方法(`connect` / `sendAudio` / `sendText` / `events` / `close`)与传输实现无关。换后端 = **换一个实现类** |
| **会话状态机** | `lib/features/live/providers/live_session_provider.dart` | `live_transport.dart:45-46` 注释已声明:*"实现本接口后在 `liveTransportProvider` 处注入。会话状态机、计费、结算、UI 全部不需要改。"* 该声明在新拓扑下成立 |
| **音频采集** | `lib/features/live/data/record_soloud_audio_engine.dart:113-138` | 上行格式不变:PCM16 / 16kHz / 单声道 / `echoCancel+noiseSuppress+autoGain` / Android `voiceCommunication`+`modeInCommunication` |
| **音频播放** | 同上 `:100-108` | 下行格式不变:PCM16 / 24kHz / `BufferType.s16le` |
| **打断清空** | 同上 `:180` `SoLoud.resetBufferStream(source)` | 打断语义不变(仍是下行事件驱动),清空动作完全一样 |
| **AEC 真机探针** | `lib/dev/aec_probe/` | 与拓扑无关 |
| **返回键拦截** | `lib/features/live/ui/live_call_page.dart:39-59` | 交互不变 |

**⇒ 新拓扑对客户端的核心改动 = 写一个新的 `LiveTransport` 实现(§3)+ 按 §4 补 UI。**

---

## 2 · 必须先修的两处**注释漂移**(与拓扑无关,是既有事实错误)

| # | 位置 | 注释声称 | 事实 | 处置 |
|---|---|---|---|---|
| **D-1** | `live_transport.dart:29-36`「客户端还缺的依赖」表 | *"录音 / PCM 播放:pubspec 无音频依赖"* | **已证伪**:`pubspec.yaml:57` `record: ^7.1.1`、`:58` `flutter_soloud: ^4.1.6` 均已在;`record_soloud_audio_engine.dart` 已实装 | 删除该表,或改写为"已实装,见 `record_soloud_audio_engine.dart`" |
| **D-2** | `live_transport.dart:24` | *"单连接时长 ~10 分钟(上游主动断,断前发 GoAway)"*,标注出处 `docs/api/live-session.md §3` | 该表述的**唯一来源**是本仓 `docs/api/live-session.md:201`,**不是 Google 官方文档**。Google 主文档(`ai.google.dev/gemini-api/docs/live-session`)只写会话 15 分钟,**无 10 分钟连接**表述;仅 Firebase AI Logic 文档提到 *"Connection length: about 10 minutes"*。两者不一致,平台侧正在实测(设计文档 U-2 / M-2) | 改标注为「来源=本仓 live-session.md,与 Google 主文档不一致,实测中」。**新拓扑下该约束由后端承担,客户端可整条删除** |

**为什么现在修**:这两处注释会误导后续维护者(第一条会让人重复引入音频依赖;第二条会让人以为 10 分钟是官方保证)。修改本身零风险 —— 只动注释。

---

## 3 · 新传输契约:客户端 ↔ 后端 WebSocket

### 3.1 建连

```
GET  wss://<host>/v1/live/sessions/{conversation_bid}/stream
Headers:
  Authorization: Bearer <JWT>
  <App 签名 header 组>      # 与现有 App 签名中间件一致,不新增规则
```

- `conversation_bid` 由客户端先调用现有会话创建接口取得(与文字对话共用同一套会话身份)
- **不再有令牌签发这一步**。建连即开始;鉴权失败在握手阶段以 HTTP 状态码返回
- 握手 HTTP 错误码沿用现有语义:`401` 未认证 · `403` 无权访问该会话 · `404` 会话不存在 · `429` 并发超限 · **`402` 余额不足一分钟(2026-08-23 计费恢复批新增)** · `503` 上游不可用
- **判因首选直读握手响应**(2026-08-24 勘误:xing_yuan 实测其握手栈能拿到 `status=402` 与响应体 `{"code":40200}`,此前「Flutter 读不到状态码」的平台侧断言对该实现**不成立**)。处置与全仓其他计费路径**同一套**:`402`/`40200` → 走既有的余额不足处置(`paywallLauncherProvider.handleIfInsufficient` 弹订阅/购买),且 **402 必须归入不可重试**——余额不会因为再点一次就变多。业务码要从响应体 `code` 字段结构化取出并随异常携带,不要埋进给人看的 diagnostic 字符串。仅当握手实现确实取不到状态码时,才以 §3.1.1 预检作判因兜底

### 3.1.1 拨号前预检 `GET /v1/live/quote`(2026-08-24 新增)

**主用途**:详情页 T0 展示(§4.1)的数据源 —— 单价与可通话分钟在拨号前**唯一**可查的面(`budget` 事件连上之后才有,单价别无来源),并支持拨号前就把通话按钮切「去充值」态。**判因只是兜底**:握手栈取不到状态码的实现才需要它判因;xing_yuan 已实测可直读握手 402(§3.1),判因不必经此。纯读零副作用,可放心在页面进入与失败重试间反复调用。

```
GET /v1/live/quote
Headers: Authorization: Bearer <JWT> + <App 签名 header 组>
→ 200 标准信封,data:
{
  "available": false,                  // 现在拨号能否通过余额/开关判定
  "reason": "insufficient_credits",   // 仅 available=false 下发: insufficient_credits | unavailable
  "credit_per_minute": 12,            // ┐
  "balance_credits": 0,               // ├ 计费模式恒下发(含零值); 免费模式三字段缺席,
  "callable_minutes": 0,              // ┘ 客户端据缺席隐藏全部费用 UI(与 §6/ready 同语义)
  "max_duration_seconds": 2700        // 单通硬顶
}
```

| 状态 | 客户端处置 |
|---|---|
| `available=true` | 通话按钮常态;计费模式按 §4.1 T0 渲染 `{credit_per_minute} 星币/分钟 · 余额约可通话 {callable_minutes} 分钟` |
| `reason="insufficient_credits"` | 通话按钮切「去充值」态 / 拨号失败后弹**订阅或购买积分**半屏 sheet;`credit_per_minute`、`balance_credits` 照常下发,购买页直接渲染 |
| `reason="unavailable"` | 语音入口隐藏或置灰(面未开启/配置不完整,确定性,重试无用) |
| 信封 `code=50323` | 基础设施故障,可重试 —— **不要**据此弹购买 |

- `callable_minutes = floor(balance/price)`,是**余额口径**,不受单通上限截断;单通上限看 `max_duration_seconds`
- 预检不是承诺:预检说可拨、拨号时余额已被花掉,握手仍会 402 —— Admit 是唯一权威门,失败后回来再查一次即可

### 3.2 帧格式(双向)

| 帧类型 | 方向 | 内容 |
|---|---|---|
| **Binary** | 客户端 → 后端 | 裸 PCM16LE / **16000 Hz** / 单声道。**零封装** |
| **Binary** | 后端 → 客户端 | 裸 PCM16LE / **24000 Hz** / 单声道。**零封装** |
| **Text** | 双向 | 一条 JSON,形如 `{"t":"<type>", ...}` |

**音频为什么用裸 Binary 而不是 JSON+base64**:上行 32ms 一帧 ⇒ 每秒 31 帧。base64 膨胀 33% 且每帧一次 JSON 编解码 —— 在移动端是持续的 CPU 与电量开销,在后端是每连接每秒 31 次 map 分配。裸二进制帧零解析。

**分片时长**:上行 **32ms**(= 512 samples = 1024 字节)。该值由后端在 `ready` 事件下发(`frame_ms`),客户端**按下发值走**,不硬编码。

### 3.3 客户端 → 后端 · 控制消息

| `t` | 载荷 | 语义 |
|---|---|---|
| `text` | `{"t":"text","text":"..."}` | 用户改用键盘输入 |
| `mute` | `{"t":"mute","on":true}` | 静音开/关。`on=true` 后客户端**停止发送 Binary 上行帧** |
| `bye` | `{"t":"bye"}` | 用户主动挂断。**发完再关 WS** —— 让后端有机会做正常结算并回一条 `ended` |

**没有 `interrupt` 上行消息。** 打断由上游 VAD 识别后以下行 `interrupted` 事件通知(`live_transport.dart:65-70` 的既有结论在新拓扑下继续成立)。

### 3.4 后端 → 客户端 · 事件

| `t` | 载荷 | 映射到现有 `LiveEvent` | 客户端动作 |
|---|---|---|---|
| `ready` | 见 §3.5 | `LiveSetupComplete` | 开始采集并发送上行 |
| `interrupted` | `{"t":"interrupted"}` | `LiveInterrupted` | **立即** `resetBufferStream` + 动效切聆听态 |
| `turn_end` | `{"t":"turn_end"}` | `LiveTurnComplete` | 动效切聆听态 |
| `transcript` | `{"t":"transcript","who":"user"\|"agent","text":"...","final":bool,"lang":"zh-CN"}` | `LiveTranscript` | **默认丢弃**(见 §4.4);无障碍开关打开时才渲染 |
| **`link`** | `{"t":"link","state":"up"\|"reconnecting"\|"degraded"}` | **新增事件类** | 见 §4.2 |
| **`budget`** | `{"t":"budget","remaining_seconds":2940,"level":"ok"\|"warn"\|"critical"\|"grace","grace_seconds":60}` | **新增事件类** | 见 §4.1 |
| **`notice`** | `{"t":"notice","code":"session_ending_soon"\|"weak_network"\|"mic_busy","text":"..."}` | **新增事件类** | 顶部/底部非模态条显示 `text` |
| `ended` | `{"t":"ended","reason":"...","cost_credits":13,"balance_after":1227,"duration_seconds":754}` | `LiveClosed` | 结算卡 |

#### `ended.reason` 封闭集

`user_hangup` · `session_max_duration` · `balance_exhausted` · `mute_timeout` · `link_lost` · `no_response` · `upstream_error` · `server_shutdown`

客户端按 reason 决定结算卡文案与是否显示「重新拨打」/「充值」。**未知 reason 一律按 `upstream_error` 处理**(前向兼容:后端新增 reason 不需要客户端同步发版)。

### 3.5 `ready` 事件:**全部运行参数由服务端下发,客户端零硬编码**

```json
{
  "t": "ready",
  "params": {
    "frame_ms": 32,
    "upstream_rate_in": 16000,
    "upstream_rate_out": 24000,
    "replay_window_ms": 2000,

    "credit_per_minute": 20,
    "balance_credits": 1240,

    "max_duration_seconds": 2700,
    "warn_before_end_seconds": 300,
    "mute_auto_end_seconds": 180,

    "link_degraded_after_ms": 8000,
    "link_fatal_after_ms": 30000,
    "no_response_after_ms": 6000,

    "weak_playout_buffer_ms": 300,
    "normal_playout_buffer_ms": 100,
    "weak_frame_ms": 64
  },

  "greeting": "我是掷天机,报上你的问题,三枚骰子替你断个吉凶。"
}
```

**这是本契约最重要的一条设计约束。**

| 理由 | 说明 |
|---|---|
| **调参零发版** | 45 分钟上限、8 秒/30 秒判定、`P` 星币/分钟 —— 全部是产品参数,上线后必然要调。硬编码在客户端 = 每次调参一个 App 发版周期 |
| **契约可以现在签** | 平台侧尚有 8 项待裁决(`P` 定值、45 分钟上限、静音口径…)。参数化后,**这些决策不阻塞客户端开工** |
| **多产品复用** | 同一套客户端代码,按**定价档位**(default / member / enterprise)下发不同 `credit_per_minute` —— 档位由账户权益解析,单价来自服务端定价表。⚠️ 分发级配置**不能**覆盖价格(2026-08-20 整改:定价唯一事实源是 `wal_credit_pricing_rules`),客户端无感知 |

**客户端必须做到**:任何阈值都从 `params` 读;**代码里不得出现 45/300/180/8000/30000/6000 这些字面量**。缺字段时用一份保底默认表(见 §6),并记一条 warning 日志。

#### `greeting` — 开场白(2026-08-21 新增)

与 `params` **并列而不在其中**:`params` 里全是客户端行为阈值(数值),
`greeting` 是内容。混在一起会破坏"任何阈值都从 params 读"这条规律。

| 项 | 约定 |
|---|---|
| 类型 | 字符串,已按当前请求的语言/地区渲染完成 |
| **缺字段 / 空** | **不播报**。这是正常情况(该咨询师没配开场白),不是错误,**不要记 warning** |
| 谁来播 | **客户端**。服务端不让模型生成第一句 |
| 何时播 | 收到 `ready` 后、开始采集之前 |

**为什么不让模型说第一句**:逐字可控(不会被模型改写)· 零上游 token ·
零首答延迟。让模型生成开场白还会计入 usage,给"这通电话花了多少"
多加一个与用户行为无关的变量。

⚠️ 服务端保证下发的 `greeting` 是**成品文本** —— 若模板渲染失败,
服务端会**省略该字段**而不是下发半渲染的原文。客户端因此**不需要**
对内容做任何清洗或占位符替换;拿到什么就播什么。

---

## 4 · 客户端必须新增的行为

### 4.1 余额与时长呈现(依赖 `budget` 事件)

| 位置 | 内容 | 条件 |
|---|---|---|
| **拨号前**(咨询师详情页,通话按钮下方常驻一行) | `语音通话 · {credit_per_minute} 星币/分钟 · 余额约可通话 {callable_minutes} 分钟` —— 数据源 `GET /v1/live/quote`(§3.1.1),服务端权威计算,客户端不自己除 | 常驻 |
| **通话中**(`mm:ss` 计时下方) | `剩余约 {floor(remaining_seconds/60)} 分钟` | **仅当 `remaining_seconds ≤ 1800`**。> 30 分钟该行不渲染 |
| 刷新节奏 | 收到 `budget` 事件即刷新 | 后端按 **30 秒**节奏下发;客户端**不做本地插值跳秒** |
| **挂断后**结算卡 | `本次通话 {mm:ss} · 消耗 {cost_credits} 星币 · 余额 {balance_after}` | 现状 `本次消耗 N 星币`(`live_call_page.dart:203`)扩为三段 |

#### `budget.level` 四级降级(非模态条,**全程无提示音**)

| `level` | 条内容 | 视觉 | 附加 |
|---|---|---|---|
| `ok` | 条隐藏 | — | — |
| `warn` | `余额约剩 5 分钟` | 常规色 | 右侧「充值」按钮 |
| `critical` | `余额约剩 2 分钟,充值可继续` | warning 色 | 同上 |
| `grace` | `余额已用完,{grace_seconds} 秒后自动结束` | danger 色 + 倒计时 | 同上 |

- **非模态条**(高 44pt,不遮挡咨询师形象),**不是弹窗** —— 弹窗抢焦点而语音仍在继续,用户听得到却看不到状态
- **无声音提示**:语音通话里插提示音 = 打断对话
- 充值走**半屏 sheet**,**通话不中断**

> ⚠️ **待客户端验证并回报平台**:iOS StoreKit 支付面板弹出时是否会抢占/中断 `AVAudioSession`。若会,通话中充值必须先静音再拉起、支付完成后恢复。**平台侧无法验证此项,请 `xing_yuan` 实测后回报结论。**

### 4.2 链路状态(依赖 `link` 事件)—— 本契约最关键的新增

**为什么后端必须告诉你**:在代理拓扑下,**后端↔Google 断连时,客户端↔后端的 WS 仍然是通的**。客户端只看到"没声音",无法区分三种情形:咨询师在思考 / 后端在重连 / 后端挂了。所以链路状态**只能由后端下发**。

| `state` | 客户端表现 |
|---|---|
| `up` | 隐藏所有链路提示。恢复正常 |
| `reconnecting` | **界面完全不变**。计时继续走,咨询师形象保持聆听态,**不出声、不提示**。麦克风**继续采集并继续发送**(后端持有重放窗口) |
| `degraded` | 非模态条 `网络不稳定,正在恢复…` |

**时序由后端控制**:后端在断连 < `link_degraded_after_ms` 内发 `reconnecting`;超过则发 `degraded`;超过 `link_fatal_after_ms` 直接发 `ended{reason:"link_lost"}`。**客户端不自己计时判定**。

**重连成功后**:后端可能注入一句咨询师的话(`刚才信号断了一下,你刚说的我没听清,再说一遍好吗?`)。客户端**什么都不用做** —— 它就是一段正常的下行音频。

> **明确不做**:不显示"正在重连"、不播提示音、不弹"上下文已丢失"。真人通话断线后没人说"我的记忆已重置" —— 用产品语言接住技术故障,这是本条的全部要点。

### 4.3 静音(依赖 `mute` 上行 + `notice`)

| 项 | 行为 |
|---|---|
| 控件 | 通话界面常驻「静音」按钮(麦克风图标),与「挂断」并列 |
| 点击 | 发 `{"t":"mute","on":true}`;**停止发送 Binary 上行帧**;**不断开 WS** |
| 视觉 | 麦克风图标划斜线 + 顶部条 `已静音 · 仍在计费` |
| 计时 | **继续走** |
| 自动结束 | 后端在静音达 `mute_auto_end_seconds` 时发 `ended{reason:"mute_timeout"}`。**客户端不自己计时** |

**「仍在计费」这四个字必须出现在条上** —— 这是产品诚实,不是可选文案。

### 4.4 转写可见性

| 时机 | 行为 |
|---|---|
| **通话中** | 屏幕**零文字**:只有咨询师形象 + `mm:ss` + 三个按钮(静音 / 免提 / 挂断)。收到的 `transcript` 事件**直接丢弃** |
| **挂断后** | 结算卡下方「查看对话记录」入口 → 走**现有 REST 历史消息接口**(与文字对话共用),**不从 WS 事件拼装** |
| 回看渲染 | 用户侧右对齐、咨询师侧左对齐(与现有 IM 一致);`final=false` 的条目**灰色 + 结尾省略号**(= 被打断的话) |
| **无障碍例外** | 设置 → 无障碍 → 「显示实时字幕」,**默认关**。打开后才渲染 `transcript` 事件 |

**为什么通话中不显示字幕**(这是产品决策,不是技术限制):
1. 情感咨询的用户在说难以启齿的事。**看着自己的话被逐字打成文本,会让人闭嘴。**
2. 语音通话的心智是"说完就过去了"。实时字幕把它变成"被记录的",改变了关系性质。
3. ASR 会出错。用户看到"我离婚了"被转成"我离开了",注意力从对话转移到纠错。

无障碍开关成立是因为听障用户是**主动**打开它的,不存在上述心理负担。

### 4.5 首次使用引导(五步,严格排序)

| 步 | 时机 | 界面 | 文案 |
|---|---|---|---|
| **T0** | 咨询师详情页(**点击之前**) | 通话按钮下方常驻一行 | `语音通话 · {P} 星币/分钟 · 余额约可通话 {N} 分钟` |
| **T1** | 点击后、**请求麦克风权限之前**(仅首次) | 半屏 sheet | 标题 `开始语音通话`<br>正文 `需要使用麦克风。建议在安静环境、使用 Wi-Fi 或 4G/5G。单次通话最长 {max_duration_seconds/60} 分钟。`<br>主按钮 `允许并开始` |
| **T2** | T1 主按钮触发 | 系统原生权限弹窗 | — |
| **T3** | 权限通过 | 全屏:咨询师形象 + `正在接通…` | — |
| **T4** | 首次接通 | 咨询师说第一句话(自我介绍 + 说明可随时打断) | 由后端注入,客户端无需处理 |

- **T1 必须在 T2 之前**:iOS 系统权限弹窗只能弹一次。无前置说明 ⇒ 用户不知道为什么要麦克风就点了拒绝
- **权限被拒**:不重复弹系统弹窗(iOS 不允许)。改为一屏说明 + 「去设置」深链
- **不做前置网络检测**:检测结果("你现在是 3G")对用户无用,他改变不了,只会被劝退

### 4.6 弱网模式(依赖 `notice{code:"weak_network"}`)

| 项 | 值 |
|---|---|
| 触发 | 后端下发 `notice{code:"weak_network"}` |
| 动作 A | 播放缓冲 `normal_playout_buffer_ms` → `weak_playout_buffer_ms`(现值 `record_soloud_audio_engine.dart:103` `bufferingTimeNeeds: 0.1` = 100ms → 300ms) |
| 动作 B | 上行分片 `frame_ms` → `weak_frame_ms`(32ms → 64ms,减少小包数量) |
| 视觉 | 顶部条 `当前网络较慢,通话质量可能下降` |
| 恢复 | 后端下发 `link{state:"up"}` 时还原两项 |

**这是显式取舍**:牺牲延迟换连续性。断续的语音比慢半拍的语音难听懂得多。

### 4.7 失败面(客户端自己能观测的部分)

| 失败 | 表现 | 阈值来源 |
|---|---|---|
| **麦克风被其他 App 占用** | 通话**不断**。顶部条 `麦克风被其他应用占用`;同时发 `{"t":"mute","on":true}` 让咨询师进等待态。占用解除自动发 `mute:off` 恢复 | 客户端观测;超时由后端 `mute_auto_end_seconds` 兜底 |
| **麦克风权限被撤销** | 立即发 `bye` 并结束 → 结算卡 `麦克风权限已关闭` + 「去设置」 | 即时 |
| **网络抖动**(WS 仍连着) | **不提示**。用户听到短暂卡顿 —— 所有语音通话的常态,提示只会放大焦虑 | — |
| **模型无响应** | 用户说完后 `no_response_after_ms`(6000)无任何下行 Binary 帧 → 播**本地预置音频**:`不好意思,我刚走神了,你再说一遍?` | `params.no_response_after_ms` |

**本地预置音频为什么必须本地**:上游正是失联的那一方,不能指望它生成这句话。这条设计把一个技术故障转成一个**人格化的自然反应**。

---

## 5 · `LiveEvent` 新增三类(sealed class 扩展)

现有 8 类(`live_transport.dart:80-160`)在新拓扑下的处置:

| 现有类 | 处置 |
|---|---|
| `LiveSetupComplete` | ✅ 保留,载荷扩为 `params`(§3.5) |
| `LiveAudioChunk` | ✅ 保留 |
| `LiveInterrupted` | ✅ 保留 |
| `LiveTranscript` | ✅ 保留,补 `lang` 字段 |
| `LiveTurnComplete` | ✅ 保留 |
| `LiveClosed` | ✅ 保留,载荷扩为 `cost_credits` / `balance_after` / `duration_seconds` |
| **`LiveResumptionHandle`** | ❌ **删除** —— resumption 在新拓扑下完全由后端处理,客户端不感知 |
| **`LiveGoAway`** | ❌ **删除** —— 同上。上游 GoAway 由后端消化为一次对客户端透明的重连 |

新增三类:

```dart
/// 链路状态(代理拓扑特有:客户端↔后端通,不代表后端↔上游通)
class LiveLinkState extends LiveEvent {
  final String state; // up | reconnecting | degraded
  const LiveLinkState(this.state);
}

/// 余额/时长预算
class LiveBudget extends LiveEvent {
  final int remainingSeconds;
  final String level;       // ok | warn | critical | grace
  final int? graceSeconds;
  const LiveBudget({required this.remainingSeconds, required this.level, this.graceSeconds});
}

/// 系统通知(会话将结束 / 弱网 / 麦克风占用…)
class LiveNotice extends LiveEvent {
  final String code;
  final String text;        // 服务端下发的展示文案,客户端直出
  const LiveNotice({required this.code, required this.text});
}
```

**`LiveNotice.text` 由服务端下发而非客户端拼**:文案要能随运营调整,且要随 `Accept-Language` 出对应语言(平台侧 i18n 纪律:后端存 `{en,zh}` jsonb 并透传,locale 解析在客户端 —— 本字段由后端按请求 locale 选好直出)。

---

## 6 · 保底默认表(`params` 缺字段时用,并记 warning)

> ⚠️ 本表**只覆盖 `params` 内的阈值**。`greeting` 不在其列 ——
> 它缺失是正常情况(不播报即可),没有保底值可言,也不该记 warning。


| 字段 | 保底值 | 说明 |
|---|---|---|
| `frame_ms` | 32 | |
| `upstream_rate_in` / `out` | 16000 / 24000 | 上游协议硬约束,不会变 |
| `replay_window_ms` | 2000 | 客户端不使用该值(重放在后端),仅供诊断展示 |
| `max_duration_seconds` | 2700 | 45 分钟 |
| `warn_before_end_seconds` | 300 | |
| `mute_auto_end_seconds` | 180 | |
| `link_degraded_after_ms` | 8000 | |
| `link_fatal_after_ms` | 30000 | |
| `no_response_after_ms` | 6000 | |
| `normal_playout_buffer_ms` | 100 | 与现值一致 |
| `weak_playout_buffer_ms` | 300 | |
| `weak_frame_ms` | 64 | |
| `credit_per_minute` | **无保底** | 缺失 ⇒ **不显示任何费用文案**,不猜 |
| `balance_credits` | **无保底** | 同上 |

**`credit_per_minute` / `balance_credits` 刻意不给保底值**:猜错的后果是给用户展示错误的价格。缺失时隐藏费用相关 UI,比显示一个编造的数字好。

---

## 7 · 明确**尚未定稿**、不要提前实现的部分

| # | 项 | 状态 |
|---|---|---|
| 7-1 | **计费的具体形态**(一次冻结/多次分段结算/末次终结) | 平台侧被 `usageMetadata` 语义未定义阻塞,正在真机实测。**客户端不受影响** —— 契约里客户端只消费 `budget` 与 `ended.cost_credits`,不参与计费逻辑 |
| 7-2 | ~~`credit_per_minute`(`P`)的定值~~ | ✅ **已定 12**(2026-08-20 成本审计:上游 $0.0176/min 典型,毛利 69.1% / 最坏 56.4%;硬下限 11)。客户端始终按 `params` 走,该值变化对客户端透明 |
| 7-3 | 45 分钟上限**能否达成** | 取决于上游上下文压缩的实际能力,实测中。客户端按 `params.max_duration_seconds` 走 |
| 7-4 | **旧端点下线时机** | 见 §0。收到通知前保留旧实现 |
| 7-5 | 跨境(大陆)是否在 v1 范围 | 待裁决。§4.6 弱网模式无论如何都值得做(它对海外弱网同样有效) |

---

## 8 · 验收清单(`xing_yuan` 自测项)

| # | 验收项 | 判定标准 |
|---|---|---|
| V-1 | 新 `LiveTransport` 实现注入后,`LiveSessionNotifier` / 计费 / 结算 / UI **零改动**即可跑通 | 若需要改,说明抽象被穿透,回报平台 |
| V-2 | 代码中**不存在** 45/2700/300/180/8000/30000/6000/32/64 等阈值字面量(保底表除外,且保底表集中在一处) | grep 可证 |
| V-3 | 收到 `interrupted` 到播放实际停止 **< 100ms** | 真机测量。超过 100ms 用户会感到"它没听见我" |
| V-4 | `link{state:"reconnecting"}` 期间界面**逐像素不变**,麦克风持续采集并持续上行 | 录屏比对 |
| V-5 | 通话中屏幕**零文字**(无障碍开关关闭时) | 截图 |
| V-6 | 未知 `ended.reason` 按 `upstream_error` 处理,不崩不卡 | 注入未知值测试 |
| V-7 | `params` 全缺时,费用 UI 隐藏、其余按保底值正常工作 | 注入空 `params` 测试 |
| V-8 | 静音时**停止发送 Binary 帧**,WS 保持连接 | 抓包 |
| V-9 | iOS StoreKit 支付面板对 `AVAudioSession` 的影响结论 | **实测后回报平台**(§4.1) |
| V-10 | 两处注释漂移已修(§2) | diff |

---

## 9 · 与平台侧的接口边界

| 归属 | 事项 |
|---|---|
| **平台侧负责** | 上游连接与重连 · resumption handle · GoAway 消化 · 上行重放窗口 · 计费与结算 · 所有阈值判定与下发 · `notice.text` 文案与 i18n · 打断的后端侧缓冲清空 |
| **客户端负责** | 音频采集与播放 · AEC · 打断的本地播放缓冲清空 · UI 与交互 · 麦克风权限与占用处理 · 弱网模式的本地参数切换 · 本地预置音频 |
| **共同** | 打断的端到端延迟(后端停推 + 客户端清空,两侧都做才成立) |

### 9.1 · 会话身份的创建时机(客户端注意项)

`conversation_bid` 由客户端先调现有会话创建接口取得(§3.1)。**每次拨号失败都会
在服务端留下一条零消息的会话行** —— 客户端本地的 `forget()` 只清本地状态,不会
回收服务端的行。

平台侧不做自动清理:一条空会话是**用户数据**,服务端无法区分「拨号失败的残留」
与「用户建了会话还没说话」,自动删除会误删后者。

建议客户端把创建时机推后到**握手成功之后**,或复用同一个 `conversation_bid` 重拨
(该 bid 与文字对话共用会话身份,重拨同一个会话在语义上也更对 —— 用户感知的是
「继续跟这位咨询师聊」而不是「开一段新关系」)。并发闸按会话维度算,重拨前一定要
确保上一通已结束(收到 `ended` 即可)。

有疑问或发现契约与实现冲突,回报平台侧并更新 `docs/design/live-audio-implementation-plan-v1.0.md`。**不要在客户端单方面绕过契约** —— 绕过点会在下一次平台改动时静默失效。
