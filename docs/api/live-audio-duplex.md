# Live 音频双工会话 · 平台内对接文档 v1.0

> **读者**:平台内 BC 开发者(未来的会话编排层 / capability / runtime)。
> **状态**:已合入 `main` 并随 `20260818-142826-a60f3ae8` 上线。**当前无任何调用方、无 HTTP 端点**——线上行为零变化,这是有意的:激活前置条件见 §9。
> **成文**:2026-08-18 · 依据 `docs/design/live-audio-implementation-plan-v1.0.md`(四阶段方案 + 实施留痕)

## 0 · 三份 Live 文档的分工(先读这个,别走错门)

| 文档 | 拓扑 | 读者 | 状态 |
|---|---|---|---|
| **本文档** | 服务端代理:**平台持上游连接**,音频经平台中转 | 平台内 BC 开发者 | ✅ 现行方案,已交付 |
| [`live-audio-client-contract-v1.0.md`](live-audio-client-contract-v1.0.md) | 同上,客户端 ↔ **后端** 的 WS 契约 | `xing_yuan` 客户端 | **已实装**(2026-08-20),端点 `GET /v1/live/sessions/:conversation_bid/stream` |
| [`live-session.md`](live-session.md) | 客户端直连:平台只签临时令牌 | 客户端 | ⚠️ **已否决拓扑**,端点仍在服务中,下线时机待裁决(任务 G-1/G-2) |

两种拓扑**互斥**。选服务端代理的唯一理由:客户端直连时后端拿不到 `usageMetadata`,计费不可信。

---

## 1 · 接入面:一个方法

**唯一入口**是 provider BC 的 facade(BC 间通信红线:只走 `XxxAPI` 接口):

```go
// internal/provider/api.go
OpenDuplexSession(ctx context.Context, req *provider.DuplexSessionRequest) (provider.DuplexSession, error)
```

```go
type DuplexSessionRequest struct {
    ModelVersionBID string                // 必须是 task_type='realtime' 的模型版本(§9)
    Spec            *DuplexSpec           // 会话参数,必填
    Resilience      *DuplexResilienceSpec // nil = 裸会话(断即结束);非 nil = 韧性会话(§5)
    ConnectTimeout  time.Duration         // <=0 → adapter 默认 20s
    TraceID         string                // 空则服务层合成
}
```

全部类型是 `internal/provider/app/port` 的**别名**(同一类型,零转换)——消费方只 import `internal/provider` 一个包。

### 与其余 facade 方法的本质差异:返回后资源仍在持有

`DuplexSession` 背后是一条活的上游 WSS + **每连接 3 个常驻 goroutine**(writeLoop/readLoop/watchdog;韧性会话再 +1)。**调用方必须 `Close()`(幂等)**。忘了 Close = 泄漏 goroutine、TCP,以及**上游侧一个仍在计费的会话**。

### 内部链路(供排障定位)

```
provider.ProviderAPI.OpenDuplexSession        api_local.go(纯委派)
  → ProviderCallService.OpenDuplexSession     provider_duplex_session.go
      realtime 门禁 → 能力选道 → 熔断准入 → 凭证解密 → 建连(经闭包,重连同路)→ 调用日志
    → AIGateway.OpenDuplexSession             ai_gateway.go(可选扩展接口分派 + trace 埋点)
      → GeminiAdapter.OpenDuplexSession       gemini_live_duplex.go(SDK 安全封装)
```

**每次建连(含韧性会话的每次重连)各落一条 `prov_provider_call_logs`**——"建了多少条连接"必须可查,每条都对应一段上游计费。日志记的是建连这一次调用,不是会话时长。

---

## 2 · DuplexSpec:会话参数

| 字段 | 类型 | 说明 |
|---|---|---|
| `InputAudio` / `OutputAudio` | `DuplexAudioFormat` | **必填,且不同**:输入 16kHz / 输出 24kHz 是上游设计。仅支持 `pcm_s16le` 单声道;`Validate` 拒立体声(会让全部字节↔时长换算错位) |
| `SystemInstruction` | string | 纯文本系统指令 |
| `Voice` | string | 厂商音色名(如 `"Puck"`),空=上游默认,中立层不校验 |
| `InputTranscription` / `OutputTranscription` | bool | 请求上下行转写 |
| `TranscriptionLanguages` | []string | BCP-47 提示,空=自动检测 |
| `TurnCoverage` | enum | **计费口径开关**:`activity_only`(排除静音)/ `all_input` / 空=上游默认。⚠️ 上游默认随模型版本变化且文档与 SDK 枚举不一致——**计费敏感场景必须显式指定** |
| `ActivityDetection` | *struct | VAD。`Disabled=true` 后必须自己 `SignalActivity`——全自动/全手动二选一,无中间态 |
| `ContextCompression` | *struct | 上下文压缩。`TargetTokens` 必须 < `TriggerTokens`(否则每轮都压缩)。代价:被压掉的早期对话**模型真的忘了** |
| `Resumption` | *struct | 会话恢复,见 §6 |
| `Extra` | map | provider-specific 透传,中立层不解释。Gemini 认 `api_version` / `base_url`(连接层参数) |

校验三层执行(service/gateway/adapter,纵深防御),非法 spec → `ErrDuplexInvalidSpec`,**绝不重试**。

---

## 3 · DuplexSession:会话句柄与并发契约

```go
type DuplexSession interface {
    SendAudio(data []byte) error        // 须符合 Spec.InputAudio;内部有防御性拷贝,缓冲区可复用
    SendText(text string) error         // 用户改用键盘时
    SendToolResults(results []DuplexToolResult) error
    SignalActivity(signal DuplexActivitySignal) error  // 仅 VAD Disabled 时 start/end;自动 VAD 时仅 stream_end
    Events() streaming.Reader[*DuplexEvent]            // 单消费者!整个会话期间同一个 Reader
    Close() error                                      // 幂等;唯一的资源释放路径
}
```

**并发契约(调用方可依赖)**:

- 全部 `Send*` 与 `Close` 可被任意 goroutine 并发调用(内部串行化到单写者)。
- `Events()` 的 Reader 是**单消费者**——只允许一个 goroutine 调 `Recv`。
- 会话正常结束 → `Recv` 返 `io.EOF`;异常断开 → 返具体错误;主动 `Close` 后 → EOF(不伪装成故障)。

**背压**:上行缓冲有界(32 帧 ≈ 1-3 秒音频)。满时 `SendAudio` 返 `ErrDuplexBackpressure` 且**本帧未被接受**——中立层不替你丢帧,丢不丢是产品决策(丢 = 用户说的话没被听到)。

**弃读止血(2026-08-18 整改)**:消费者只关 Reader 不调 Close 时,会话**自我终结**上游连接(与全仓泵约定 W2 对齐)——但这是兜底不是契约,**正路仍是 defer Close**。

---

## 4 · 下行事件:16 种 Kind

`DuplexEvent` 是 Kind 判别式的胖结构(加 Kind 不破坏消费方——**未知 Kind 必须忽略而非报错**,这是前向兼容的全部要求)。

| Kind | 载荷字段 | 语义与陷阱 |
|---|---|---|
| `session_ready` | `SessionID` / `ResumeConfirmed` | 必然是第一个事件。⚠️ **`ResumeConfirmed` 恒 false**:Gemini 握手不提供恢复成功与否的信号,恢复成功与开新会话在协议层**不可区分**。不得据此判定"上下文是否还在" |
| `audio_output` | `Audio []byte` | 24kHz PCM16LE |
| `text_output` | `Text` | 仅请求文本模态时 |
| `input_transcript` / `output_transcript` | `Transcript{Text, Final, LanguageCode, SpeakerLabel, AudioOffset}` | ⚠️ **转写与音频无顺序保证**(上游明文)。落库锚点只能是 `Final` + `AudioOffset`,不能是到达顺序。interim 输入转写恒 `Final=false` |
| `turn_complete` | — | 模型本轮结束 |
| `generation_complete` | — | 生成完毕(可能早于 turn_complete);**被打断的轮次没有本事件** |
| `interrupted` | — | 用户抢话,上游已取消本轮。**收到即停止向下游转发在途音频**——打断三级清空的第一级。保证先于同帧的 `turn_complete` 送达 |
| `tool_call` | `ToolCalls[]{ID, Name, Args}` | ⚠️ **每个 ID 都必须回一条 `SendToolResults`**,未命中的工具也要回固定语义的失败结果——少回一条上游永久等待,表现为"它突然不说话了"且零错误信号 |
| `tool_call_cancelled` | `CancelledToolCallIDs` | 仅客户端打断服务端轮次时;有副作用的工具需据此撤销 |
| `usage` | `Usage`(分模态明细) | ⚠️ 下发时机与**累计/增量语义上游未定义**(风险 U-1,待 M-1 实测)。中立层逐帧如实转达,**不合并不推算**——语义未定时的合并等于编造账单。分模态明细是计费必要输入(音频/文本单价差数倍) |
| `resumption_update` | `Resumption{Handle, Resumable, LastConsumedClientMessageIndex, HasIndex}` | ⚠️ `Resumable=false` = 「**此刻**不可恢复」,**不是**「旧句柄失效」——不得覆盖已存句柄 |
| `going_away` | `GoAwayIn` | 上游即将断开,**主动重连的唯一提前信号**。韧性会话已内部消化 |
| `reconnecting` / `reconnected` | `ReconnectAttempt` / `ReplayedUplinkBytes` | 仅韧性会话下发,见 §5。重连**机制上透明、事实上可见**——上游侧每次重连都是一条新会话,计费归集方必须知道 |
| `error` | `Err` | 上游在数据帧里回了错误对象(连接仍在)。原始报文**已被剥离**只进 slog(含上游内部标识,红线) |

### 工具结果的外泄红线

`DuplexToolResult.Result` 会被模型读取并**念成语音**。**绝不放入错误原文、内部 ID、堆栈**——那是一条不留结构化痕迹的外泄通道。失败用固定语义串,原文只进日志。(与 CLAUDE.md「内部 int64 不进对外文案」同族;反面样板见设计文档 T-1/T-2。)

---

## 5 · 韧性会话:`Resilience != nil`

对上层表现为**一条不因单条连接断开而结束的会话**:重连、恢复句柄、上行重放全部内部完成。

```go
type DuplexResilienceSpec struct {
    ReplayWindow      time.Duration // 上行重放窗口时长。<=0 = 不重放。P8 裁决初值 2s(16kHz 下 ≈62.5KiB/连接)
    MaxReconnects     int           // = 断开事件数。<=0 = 不重连(等价裸会话)
    ReconnectBackoff  time.Duration // 单次重连内建连重试的起步退避(指数,走 shared/retry)。<=0 → 200ms
    ReconnectDeadline time.Duration // 单次重连从断开到放弃的总时长。<=0 → 30s
    GoAwayLeadTime    time.Duration // 收到 GoAway 后提前多久主动切换。<=0 → 2s。须 ≥ 建连 p99
}
```

**语义要点**:

- **MaxReconnects 数的是断开事件**;单次重连内部的建连重试由 Backoff×Deadline 双闸约束(30s + 200ms 起步 ≈ 最多 7 回)。两闸独立:一防慢速失败拖用户,一防快速失败刷上游。
- **break-then-make**:先断再建,不做 make-before-break——重叠期两条上游会话**同时计费**,对按分钟计价不成立。空窗由重放窗口补偿。
- **重连必回同一条渠道**:resumption handle 按凭证签发,换道句柄必失效,"续接"静默退化成新会话(模型突然不记得前文,系统毫无察觉)。
- **重放窗口只含上行音频**:窗口内重连后重发(`reconnected.ReplayedUplinkBytes` 量化补了多少);**窗口外明确接受丢失**(P8 裁决)。重放段可能被模型重复消费,轻微内容重叠可接受。
- **重连期间的上行**:音频**继续被接受**(进窗口);`SendText` / `SendToolResults` 返 `ErrDuplexBackpressure`(文本乱序注入会错位上下文;工具结果绑定旧连接的 id,补发无效)——由持有产品语境的上层决定重试或放弃。
- **首次建连失败不经过韧性层**:配置错/余额/能力边界由调用方直接看到,不会被包装成"重连耗尽"。

---

## 6 · 会话恢复(Resumption)

```go
Resumption: &provider.DuplexResumptionSpec{
    Enabled:     true,   // 请求上游下发恢复句柄(false 则收不到 resumption_update)
    Handle:      "...",  // 上次会话的句柄;空 = 新会话
    Transparent: false,  // 仅 Vertex 后端支持!
}
```

- 韧性会话自动追踪最新可用句柄并带入每次重连——上层无需手工管理。
- **`Transparent=true` 在 Developer API 后端被三层硬拒**(`ErrDuplexInvalidSpec`),且能力选道会因此**只选 Vertex 渠道**、无 Vertex 渠道时 fail-close 返 `ErrNoAvailableChannel`。静默忽略会让上层以为在做无损重连、实际每次都在丢音频——而丢音频没有任何错误信号。
- 恢复成功与否**判定不出来**(见 §4 `ResumeConfirmed`)。产品层的接法:把恢复当 best-effort,失败表现(模型不记得前文)用话术接住(设计文档阶段三 Q4)。
- 上游句柄有效期:上游文档称最后一次会话终止后 2 小时。

---

## 7 · 错误语义(sentinel 全部从 `internal/provider` 取)

| Sentinel | 含义 | 处置 |
|---|---|---|
| `provider.ErrDuplexNotSupported` | 模型非 realtime / adapter 不支持 | **能力边界非故障**:不重试、不计熔断 |
| `provider.ErrDuplexInvalidSpec` | 会话参数非法 | **编程错误**:不重试、不放宽后重连 |
| `provider.ErrDuplexClosed` | Close 后仍 Send | 停止发送,走会话结束流程 |
| `provider.ErrDuplexBackpressure` | 上行缓冲满 / 韧性会话重连中 | 本帧未被接受;产品层决定丢或等 |
| `provider.ErrNoAvailableChannel` | 无可承载渠道 | 配置问题。服务端日志分记 `skipped_for_capability` / `skipped_for_circuit` / `total_bindings` 三个成因 |
| (upstream failed 类) | 建连/传输故障 | 不换道重试(会掩盖故障且每次建连都可能在上游留下计费会话) |

⚠️ 面向终端用户的 HTTP 面 5xx 分支**不得回吐 `err.Error()`**——链上错误含内部 int64(`version %d` 等),按 CLAUDE.md 红线在桥/mapper 层翻译成固定文案。
**已落实**:runtime 侧的哨兵翻译在 `internal/bootstrap/bridges.go::translateLiveDuplexError`(provider 哨兵 → `runtimePort.ErrLive*`),端点映射在 `internal/runtime/port/http/live_handler.go::mapLiveAdmitError`(哨兵 → 固定英文文案,零 `err.Error()` 拼接)。

---

## 8 · 最小接入示例(编排层形态)

```go
sess, err := providerAPI.OpenDuplexSession(ctx, &provider.DuplexSessionRequest{
    ModelVersionBID: modelVerBID,
    Spec: &provider.DuplexSpec{
        InputAudio:  provider.DuplexAudioFormat{Encoding: provider.DuplexAudioEncodingPCM16LE, SampleRate: 16000, Channels: 1},
        OutputAudio: provider.DuplexAudioFormat{Encoding: provider.DuplexAudioEncodingPCM16LE, SampleRate: 24000, Channels: 1},
        SystemInstruction:   persona,
        InputTranscription:  true,
        OutputTranscription: true,
        TurnCoverage:        provider.DuplexTurnCoverageActivityOnly, // 计费口径:显式,别依赖默认
        ContextCompression:  &provider.DuplexContextCompression{TriggerTokens: 100_000},
        Resumption:          &provider.DuplexResumptionSpec{Enabled: true},
    },
    Resilience: &provider.DuplexResilienceSpec{ReplayWindow: 2 * time.Second, MaxReconnects: 4},
    TraceID:    traceID,
})
if err != nil { /* 按 §7 分流;ErrDuplexNotSupported/InvalidSpec 勿重试 */ }
defer sess.Close() // 必须。背后是计费中的上游连接

go func() { // 上行:客户端 WS → 上游
    for frame := range clientAudio {
        if err := sess.SendAudio(frame); errors.Is(err, provider.ErrDuplexBackpressure) {
            // 产品决策点:丢帧(实时性优先)或缓一拍
        }
    }
}()

for { // 下行:唯一消费者
    ev, err := sess.Events().Recv()
    if err != nil { break } // io.EOF=正常结束; 其余=异常断开
    switch ev.Kind {
    case provider.DuplexEventAudioOutput:       // → 客户端播放
    case provider.DuplexEventInterrupted:       // → 立即清空下行转发队列 + 通知客户端清播放缓冲
    case provider.DuplexEventUsage:             // → 逐帧留痕(语义待 M-1, 勿自行累加当账单)
    case provider.DuplexEventToolCall:          // → 每个 ID 必回;结果绝不含错误原文
    case provider.DuplexEventReconnecting, provider.DuplexEventReconnected:
        // 计费/时长归集需要知道;要不要告诉用户是产品决策(阶段三 Q4: 零感知)
    default: // 未知 Kind 忽略 —— 前向兼容
    }
}
```

---

## 9 · 激活前置条件

**客户端面已实装**(2026-08-20):`GET /v1/live/sessions/:conversation_bid/stream`
(runtime BC,WebSocket)。会话编排、租约、优雅停机、计费与崩溃回收全部落地。
线上仍**零行为变化** —— 总开关 `runtime.live_audio.enabled` 默认 `false`。

| # | 前置 | 状态 |
|---|---|---|
| 1 | `prov_capability_defaults` 的 `live_audio` 行(DML) | ❌ **待 seed**。模型选型唯一事实源;缺行时 `OpenDuplexSession` fail-close。可用 model-only 哨兵(`provider_id=channel_id=0`)把选道交给 RouteModel |
| 2 | 该模型版本 `prov_models.task_type = 'realtime'` | ❌ 待确认。service 门禁 fail-close,不是 realtime 一律拒 |
| 3 | 定价行 `wal_credit_pricing_rules` 的 `live_audio` 行 | ✅ **2026-08-23 商用恢复 12 积分/分钟**(迁移 `20260823d`, 闭 0 价旧行插新行;成本审计与硬下限 11 留 notes)。计费装置随同批代码恢复(借道 capability 延迟结算, 见 `docs/ops/live-audio-billing-restore-20260823.md`)。形态:`entity_code='live_audio'` / `cost_unit='per_minute'` / `pricing_tier='default'`。⚠️ 单价**不在 config** —— 2026-08-20 整改前它曾被写进 `runtime.live_audio.credit_per_minute`,造出定价第二事实源(丢档位 / RepriceJob 接不上 / 调价要发版),已收归定价表并加 archtest 硬门。缺行时建连 fail-close 503;免费用 `credit_cost=0` 行表达 |
| 4 | 面向客户端的 HTTP/WS 面 | ✅ **已建**(`internal/runtime/port/http/live_handler.go`;平台 WS 帧层 `internal/platform/httpserver/ws`) |
| 5 | 会话编排层(租约 / drain / link 事件 / 打断 / 静音 / 预算) | ✅ **已建**(`internal/runtime/app/service/live_session_*.go`) |
| 6 | ~~数据层 `rt_live_sessions`~~ | 🗑 **已退役且不复活**(2026-08-21, 迁移 `20260821a`;该表的三份建/删迁移文件已于 2026-08-23 从仓内删除, 考古走 git 历史)。2026-08-23 商用恢复批(约束: 不新建表)把资金锚点**借道 capability 延迟结算**(`cap_executions` running 行 + Redis 心跳证据回收链 + 兜底 worker), 会话遥测仍归 obs BC(20260823c seed `live_audio` capability) |
| 7 | nginx WebSocket 升级配置 | ⏳ 仓内已改,**待部署**:`snippets/proxy-ws.conf` + `genaistudio.conf` 的 `location ^~ /v1/live/`。⚠️ 不部署的话握手会死在反代这一跳(http{} 层 `Connection ""` 清空升级头),而客户端看到的是普通 HTTP 响应而非 101 |
| 8 | 转写可见性策略(A-5) | 服务端已按契约把 `transcript` 事件下发;客户端默认丢弃、无障碍开关才渲染。**平台侧无待办** |

**计费不再被 P9 闸**:当前按**墙钟分钟**计费(服务端测量、客户端不可伪造),
不依赖 `usageMetadata` 语义,故 M-1 未闭环不构成阻塞。`usageMetadata` 仍逐帧归集
并随会话遥测落 `obs_trace_spans`(同时记 `sum` 与 `last` 两种口径 +
`semantics_undetermined` 标记),M-1 闭环后可用生产数据直接裁定,无需重跑真机探针。

## 10 · 测试设施(接入方写测试用这两个,禁再手写替身)

| 包 | 假的是什么 | 用途 |
|---|---|---|
| `internal/testutil/duplexfake` | **中立会话** `port.DuplexSession` | 编排层单测。`New()` 即用;`Push/Fail/EndStream` 编排下行时序;`AudioBytes/Texts/ToolResults/CloseCount` 断言上行 |
| `internal/provider/infra/gateway/adapters/liveupstream` | **Gemini 线上协议**(真实 SDK 走假 WS 上游) | adapter 层集成;一般接入方用不到 |

两者不可互相替代;此前 3 份手写副本已收敛为 0,**新消费方直接复用 duplexfake**——provider mock 零共享的教训(27+4 套)不再重演。

## 11 · 已知约束与未决项速查

- **usage 语义未定义**(U-1,最高风险):自算值≠账单,Google 明示 Console 才是计费权威。M-1 闭环前不得基于事件流实装计费。
- **单连接寿命**:两份官方文档口径冲突(15min 会话 vs 10min 连接);按"一次通话内必然重连"设计(裁决 P11),韧性会话已覆盖。
- **上游并发配额无官方数字**(社区实测 Tier1=50):**加实例不增加总容量**,容量维度是上游配额不是机器数。
- **Vertex 上无目标模型**:`gemini-3.1-flash-live-preview` 仅 Developer API(裁决 P7);`Transparent` 恢复因此实际不可用,重连按有界重放窗口设计(裁决 P8)。
- goroutine 预算:每通电话常驻 4(裸会话 3)。
