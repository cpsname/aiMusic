# 实时语音会话 API 参考(客户端对接)

> ⚠️ **本文档描述的「客户端直连 + 临时令牌」拓扑已被否决**(后端拿不到 usageMetadata, 计费不可信)。现行方案为服务端代理, 平台内对接见 [`live-audio-duplex.md`](live-audio-duplex.md), 客户端契约见 [`live-audio-client-contract-v1.0.md`](live-audio-client-contract-v1.0.md)。本文端点仍在服务中, 下线时机待裁决 —— 在收到明确通知前客户端保留旧实现。

> 设计:`internal/capability/app/builtins/live_session_token/` + `internal/capability/port/http/live_session_handler.go`
> 上游:Gemini Live API(客户端**直连**,音视频不经过本平台)

所有路径前缀 `/v1`。两个端点都在**鉴权组**:必须同时带 **App 签名 header** 与 **JWT**(与 `/v1/tasks` 等用户态端点同一套中间件链)。

---

## 一、这条链路和别的接口不一样在哪

普通生成类接口是「客户端发请求 → 平台调上游 → 平台返结果」。

实时语音是「**平台发一张短命令牌 → 客户端拿着它自己连 Google → 通话结束后回来结账**」。音频流全程不经过本平台。

因此对接分三步,**第三步不能省**:

```
① POST /v1/live-sessions                    拿令牌(此刻按授予时长预扣积分)
② 客户端用令牌直连 Gemini Live API           通话(平台看不到)
③ POST /v1/live-sessions/{bid}/settle       上报真实用时(多扣的退回)
```

**不做第 3 步的后果**:约 30 分钟后平台按「授予时长」全额扣费。用户只聊了 2 分钟也会被扣满 15 分钟的钱 —— 这是用户投诉的直接来源,请务必实现。

---

## 二、POST /v1/live-sessions — 开始会话

### 请求

```json
{
  "requested_minutes": 15
}
```

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `requested_minutes` | int | 否 | 期望通话时长(分钟)。省略 = 取平台上限。会被钳制到 `[1, 15]`,并**按钳制后的值预扣积分** |

空 body(`{}`)合法。

### 响应

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "execution_bid": "0198f3a2-...-8c41",
    "token": "auth_tokens/xxxxxxxxxxxxx",
    "expires_at": "2026-08-04T12:15:00Z",
    "new_session_expires_at": "2026-08-04T12:01:00Z",
    "model": "gemini-3.1-flash-live-preview",
    "granted_minutes": 15
  },
  "request_id": "...",
  "timestamp": 1785000000
}
```

| 字段 | 说明 |
|---|---|
| `execution_bid` | **务必保存** —— 第 3 步结算要用它 |
| `token` | 临时令牌,直接用于连接 Gemini Live API |
| `expires_at` | 令牌失效时刻(= 签发时刻 + `granted_minutes`) |
| `new_session_expires_at` | **必须在此之前发起连接**(默认签发后 60 秒),之后再连会被拒 |
| `model` | 已锁定的上游模型,连接时原样使用 |
| `granted_minutes` | 实际授予 = **实际预扣**的分钟数(可能小于你请求的值) |

### 三个容易踩的点

1. **`new_session_expires_at` 只有 60 秒**。拿到令牌要立刻连,不要先做 UI 动画再连。用户点了「开始通话」才请求令牌,别提前预取。
2. **`granted_minutes` 可能小于 `requested_minutes`**。平台上限或运营配置会收窄它。UI 上显示的剩余时长请以此字段为准。
3. **令牌锁定了模型与部分会话配置** —— 但这**不等于 setup 帧不发这些字段**。
   `setup.model` 是协议必填项,必须回填本响应返回的 `model` 值(见 §3.3)。
   「锁定」的含义是:**值不能改成别的**,而不是「不能出现」。本平台当前锁定的字段
   只有 `responseModalities`(见 §3.4 的完整清单),其余会话配置客户端可自行声明。

---

## 三、连接上游(客户端直连 Gemini Live API)

> 本节的连接参数取自 **Go GenAI SDK v1.62.0 的实际实现**(`live.go:100-120`),不是从文档推测的。
> 官方文档没有给出临时令牌的 URL,SDK 源码是目前最硬的事实来源。
> **仍建议以首次真机连接的结果为准** —— 见 §3.5 的已知不确定项。

### 3.1 端点 URL

临时令牌走的是 **`BidiGenerateContentConstrained`**,与用 API Key 的 `BidiGenerateContent` 是**不同的方法**:

```
wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContentConstrained
```

SDK 的构造逻辑(`live.go:101-116`):检测到 key 以 `auth_tokens/` 开头 → method 取
`BidiGenerateContentConstrained`;否则取 `BidiGenerateContent`。

### 3.2 鉴权:用 Header,不用 query 参数

```
Authorization: Token <token>
```

SDK 走的是这一条(`live.go:106`),**注意 auth-scheme 是 `Token` 而不是 `Bearer`**。
官方文档提到的 `?access_token=` query 参数形式 SDK 未使用 —— **推荐照 SDK 走 Header**,
理由:令牌出现在 URL 里会被代理日志、崩溃日志记录下来,而它在有效期内是可直接使用的凭证。

### 3.3 API 版本:`v1alpha` 与 `v1beta` **实测都可用**

2026-08-05 真机实测(`cmd/liveprobe`),两个版本都握手 101 并收到 `setupComplete`。

SDK 内部有硬性检查只放行 `v1alpha`(`live.go:103-105`),但那是 **SDK 自己的限制**,
不是上游的。直连时两个都行。

**推荐 `v1alpha`** —— 与 SDK 走同一条路,将来若改用 SDK 实现不用换。

### 3.4 首帧 setup:字段嵌套是关键(实测踩坑点)

**必须发 setup 帧**。字段结构如下 —— ⚠️ **`responseModalities` 要嵌在 `generationConfig` 里,
不是 setup 的直接子字段**:

```json
{
  "setup": {
    "model": "gemini-3.1-flash-live-preview",
    "generationConfig": {
      "responseModalities": ["AUDIO"]
    },
    "inputAudioTranscription": {},
    "outputAudioTranscription": {},
    "sessionResumption": {}
  }
}
```

拍平写成 `setup.responseModalities` 会被上游直接关闭连接(2026-08-05 实测):

```
close 1007 (invalid payload data):
Invalid JSON payload received. Unknown name "responseModalities" at 'setup': Cannot find field.
```

嵌套规则(SDK `live_converters.go:205/245/270/413` 佐证):

| 字段 | 位置 |
|---|---|
| `responseModalities` · `temperature` 等生成参数 | `setup.generationConfig.*` |
| `systemInstruction` · `sessionResumption` · `inputAudioTranscription` · `outputAudioTranscription` · `tools` | `setup.*`(直接子字段) |

完整真机帧序列见 [`samples/live_session_frames.json`](samples/live_session_frames.json)。

**本平台当前锁定的字段只有一项**:

| 字段 | 是否锁定 | 客户端能否自行声明 |
|---|---|---|
| `model` | 锁定 | 必须发,值 = 响应里的 `model` |
| `responseModalities` | **锁定为 `["AUDIO"]`** | 不要改成别的值 |
| `sessionResumption` | 未锁 | ✅ 可自行开启 |
| `inputAudioTranscription` / `outputAudioTranscription` | 未锁 | ✅ 可自行开启(做字幕) |
| `systemInstruction` / `speechConfig` / `tools` 等 | 未锁 | ✅ 可自行声明 |

锁定清单由服务端 `cap_capabilities.metadata.live_locked_config` 决定,改动会在此文档同步。

### 3.5 真机实测结论(2026-08-05,`cmd/liveprobe` 六组对照)

| 实验 | 结果 | 对客户端的含义 |
|---|---|---|
| `v1alpha` | ✅ 101 + setupComplete | 推荐用这个 |
| `v1beta` | ✅ 101 + setupComplete | 也能用,SDK 的版本限制是它自己的 |
| setup 回填 model + AUDIO | ✅ | **标准做法** |
| setup 发 `TEXT`(锁定是 AUDIO) | ✅ **未报错** | 上游**静默用锁定值覆盖**;不要依赖自己发的值生效 |
| setup 完全为空 `{}` | ✅ | 能连,但不推荐(拿不到转写等可选能力) |
| 省略 `model` | ✅ | 令牌已锁定,可省;**仍建议回填**以便日志自证 |
| 开 `inputAudioTranscription` / `outputAudioTranscription` | ✅ | **字幕可以做** |
| 开 `sessionResumption` | ✅ | 客户端自行声明即可 |

**最重要的两条**:

1. 锁定字段发错值**不会报错**,上游静默覆盖 —— 所以客户端**不能**用"发了没报错"来验证自己
   的配置生效了。以服务端下发的 `model` 为准。
2. 转写和 session resumption 都**未锁定**,客户端可自行开启。

仍未覆盖(需真实通话才能触发,首次联调时请抓取回传):
`goAway` 帧 · session resumption 重连帧 · 音频 `serverContent` / `turnComplete` 帧

### 音频格式(必须严格匹配)

| 方向 | 格式 |
|---|---|
| 上行(麦克风) | 原始 PCM,**16-bit 小端,16 kHz**,MIME `audio/pcm;rate=16000` |
| 下行(播放) | 原始 PCM,**16-bit 小端,24 kHz** |

上下行采样率不同,别用同一个 AudioContext 配置。

### 会话时长的硬约束(来自上游,平台无法放宽)

| 项 | 值 |
|---|---|
| 单条 WebSocket 连接 | ~10 分钟(上游会主动断,断前发 `GoAway` 带剩余时间) |
| 纯音频单次会话 | **15 分钟上限** |
| 音频+视频会话 | 2 分钟上限 |

**这意味着「聊 30 分钟」不是一张令牌能做到的**。用户需要长时间通话时:

```
令牌 A 到期 →（客户端感知 expires_at 临近）
  → 先调 ③ settle 结算令牌 A
  → 再调 ① 拿令牌 B，重新连接
```

建议在 `expires_at` 前 30 秒就开始续签流程,避免用户感知到中断。**不要等断开了才处理** —— 那时用户已经在「喂?喂?」了。

单条连接 10 分钟的限制在会话内部,可用上游的 session resumption 机制在同一张令牌的有效期内重连,不需要向平台重新申请令牌。

---

## 四、POST /v1/live-sessions/{execution_bid}/settle — 结束并结算

### 请求

路径参数 `execution_bid` = 第 1 步返回的值。

```json
{
  "used_minutes": 4
}
```

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `used_minutes` | int | 否 | 真实通话分钟数。会被钳制到 `[0, granted_minutes]`。省略或 0 = 按 0 结算(全额退回) |

**取整建议**:向上取整(聊了 3 分 10 秒报 4)。平台按分钟计价,报 3 会让你少收用户的钱。

### 响应

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "settled": true,
    "cost_credits": 20,
    "server_time": "2026-08-04T12:04:30Z"
  }
}
```

| 字段 | 说明 |
|---|---|
| `settled` | `true` = 本次结算生效;`false` = 此前已结算过(重复上报 / 已被超时回收),**不是错误** |
| `cost_credits` | 实际扣除的积分。预扣的差额已自动退回用户钱包 |

### 幂等与重试

**这个接口可以放心重试**。网络失败、App 崩溃后重启补报都可以再调 —— 已结算的会返回 `settled: false` 且不会二次扣费。

建议实现:通话结束立即上报;失败则本地持久化 `execution_bid` + `used_minutes`,下次启动重试。

---

## 五、计费模型

```
① 开始会话   冻结 = 每分钟单价 × granted_minutes
② 通话中     冻结保持挂起,不扣不退
③ 上报结算   实扣 = 冻结额 × used_minutes / granted_minutes(向下取整)
             差额自动退回钱包
④ 未上报     约 30 分钟后按冻结额全额扣除
```

要点:

- **预扣发生在第 1 步**。用户余额不足时第 1 步就会失败,不会出现「聊到一半没钱了」。
- **余数归用户**。按比例结算的除法向下取整。
- **绝不超扣**。上报值超过授予时长会被钳制,最坏情况就是按授予时长全额扣。
- 用户在通话前应能看到自己的余额够聊多久 —— 建议用钱包接口的余额 ÷ 单价预估并展示。
- **本能力没有免费额度**。实时会话每一分钟都产生真实上游成本,所有档位一律计费
  (会员/企业档只是单价更低)。余额为 0 时第 1 步直接返回 `40200`,请引导充值而不是重试。

---

## 六、错误码

| code | 场景 | 客户端应该怎么做 |
|---|---|---|
| `40200` | 余额不足 | 引导充值。**不要重试** |
| `40033` | `requested_minutes` 非法(非正整数等) | 修正入参 |
| `40110` | 缺 JWT 或缺 App 签名上下文 | 检查签名 header 与登录态 |
| `40300` | 结算的会话不属于当前账号 | 检查 `execution_bid` 是否用错 |
| `40402` | 会话记录不存在 | 检查 `execution_bid` |
| `42930` | 配额超限 —— **日频**或**并发会话数** | 见下方说明,区分处理 |
| `50084` | 实时会话能力不可用(服务端未配置模型 / 渠道不支持) | **不要重试**,提示用户功能暂不可用并上报 |
| `50080` | 其他执行失败 | 可重试一次 |

签发失败时**不会扣费**(冻结当场退还),客户端无需做任何补偿动作。

### 关于 42930(并发会话数)

平台按账号限制**同时进行中的会话数**(不同档位 1–5 路)。一次会话在你调用 settle 之前
都算「进行中」,因此:

- 上一通电话没有 settle 就直接开下一通 → 很可能撞 42930
- **这是 settle 必须及时调用的第二个理由**(第一个是计费)
- 撞到时的提示应该是「你已有通话进行中」,而不是「服务繁忙」

异常断开后请立刻用已通话时长 settle,否则该名额会一直占用到超时回收(约 30 分钟)。

### 令牌的留存

平台**不保存**签发出去的令牌明文 —— 执行流水里该字段是脱敏的。这意味着:

- 令牌只在这一次响应里出现,客户端拿不到第二次
- 丢了只能重新签发(会再次预扣),所以**别丢**
- 平台侧也无法帮你找回某次会话的令牌

---

## 七、推荐的客户端状态机

```
idle
 └─(用户点开始通话)→ requesting_token
      ├─ 失败(40200)→ 引导充值 → idle
      ├─ 失败(50084)→ 提示不可用 → idle
      └─ 成功 → connecting（必须在 new_session_expires_at 前完成）
           └─ 成功 → in_call
                ├─(expires_at 前 30s)→ settle(A) + requesting_token(B) → 无缝续接
                ├─(用户挂断)→ settling
                └─(异常断开)→ settling（用已通话时长上报）
                     └─ settling
                          ├─ 成功 → idle
                          └─ 失败 → 本地持久化待补报 → idle
```

**必须持久化的两个字段**:`execution_bid`、本地累计的 `used_minutes`。App 被杀死后重启要能补报。

---

## 八、联调自检清单

- [ ] 请求带了 App 签名 header(缺了会 40110,不是 401)
- [ ] 保存了 `execution_bid`
- [ ] 60 秒内发起了连接
- [ ] 上行 16kHz / 下行 24kHz,没搞混
- [ ] 没有自己指定 model 或 `responseModalities`(令牌已锁定)
- [ ] 通话结束调了 settle
- [ ] settle 失败有本地重试
- [ ] App 被杀死后重启会补报
- [ ] 处理了 `granted_minutes < requested_minutes` 的情况
- [ ] 处理了 15 分钟到期的续签

---

## 九、服务端上线前置(非客户端职责,但会影响联调)

联调前请与后端确认这两项已完成,否则第 1 步会稳定返回 `50084`:

1. `cap_capabilities.metadata.live_model_version_bid` 已指向真实实时模型版本
2. 该模型版本所属渠道是 **Gemini Developer API**(Vertex AI 后端无法签发临时令牌)

迁移:`docs/migrations/20260804_cap_deferred_settlement_columns.sql` → `20260804b_live_session_token_capability.sql`(顺序敏感)。
