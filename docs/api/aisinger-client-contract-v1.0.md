# AI 写歌 · 客户端对接契约 v1.0

> **谁读这份**:实现 iOS 客户端的人。从冷启动到出歌到付费,一份读完能做完。
> **写于** 2026-09-08,平台侧数据已 apply 到生产。
>
> **权威边界**:本文只讲写歌这条链路。通用机制(BaseURL、Envelope、错误段、
> 签名算法细节)在 [`overview.md`](overview.md);创作面全量端点在
> [`creation.md`](creation.md);钱包/内购在 [`wallet.md`](wallet.md) / [`iap.md`](iap.md)。
> 三者与本文冲突时**以代码为准**,并请回来改本文。

---

## 0. 一句话的产品形态

用户描述一首歌 → **先花 100 积分出两段 30 秒试听**,选一个方向 → **再花 115 积分出完整歌**,
带词级时间轴可做逐字高亮。作品保留 **7 天**。

**一首歌 = 215 积分。**

---

## 1. 接入身份(四个常量)

| 项 | 值 |
|---|---|
| `distribution_code` | `aisinger-ios` |
| `app_code` | `GenAI` |
| `bundle_id` | `com.frameink.song` |
| HMAC 签名密钥 | 平台生成,走带外交付,放 `.env`,**不进代码库** |

### 1.1 每个请求都要带的四个头

| Header | 值 |
|---|---|
| `X-Distribution-Code` | `aisinger-ios` |
| `X-Timestamp` | Unix **秒**;服务端窗口 **±5 分钟** |
| `X-Nonce` | UUID v4;同 nonce **10 分钟**内不可重放 |
| `X-App-Signature` | `hex(HMAC_SHA256(secret, X-Timestamp + X-Nonce + sorted(body)))`,小写 64 字符 |

`sorted(body)` 的规范化规则见 [`overview.md` §5.2](overview.md)。

⚠️ **时钟**:`POST /v1/app/init` 返回 `server_time`(Unix 毫秒),客户端据此算 offset 并持续校正。
本地时钟偏差超 5 分钟 → 全部请求 401。**冷启动第一件事就是校时。**

### 1.2 登录后再带

| Header | 值 |
|---|---|
| `Authorization` | `Bearer <access_token>` |

---

## 2. 冷启动三步

### 2.1 `POST /v1/app/init`(公开,不需要 JWT)

```jsonc
// 请求
{ "distribution_code": "aisinger-ios", "client_version": "1.0.0" }

// 响应 data
{
  "server_time": 1757308800000,        // ← 校时基准
  "update": { "required": false, "forced": false },
  "products": [ /* 见 §7.2 */ ],
  "payment_channels": [],              // 纯 App Store 内购 ⇒ 空数组
  "legal": { "privacy_url": "", "terms_url": "", "subscription_terms_url": "" }
}
```

⚠️ `legal` 三个链接**当前为空**。App Store 审核要它们 —— 页面上线后平台侧一条 UPDATE 填上,
客户端**必须按空串降级**(不渲染入口),不要假设非空。

### 2.2 `POST /v1/auth/guest-register`(公开)

```jsonc
// 请求
{ "app": {
    "distribution_code": "aisinger-ios",
    "app_code": "GenAI",
    "bundle_id": "com.frameink.song",
    "channel": "appstore"          // 分包渠道, 必填
}}

// 响应 data
{
  "user_id": "<account uuid>", "guest_id": "guest_xxxx", "is_new_user": true,
  "access_token": "...", "refresh_token": "...", "expires_in": 7200, "token_type": "Bearer"
}
```

设备信息走 Header,**不放 body**。其中 **`X-Device-ID` 必填** —— 它是游客注册的幂等键,
缺了直接 `40001`;同一 device_id 重复调返回同一个账号(`is_new_user=false`)。
另有 `X-Device-Model` / `X-App-Version` 等可选头,清单见 [`overview.md` §3.2](overview.md)。
⚠️ 该端点有**设备维度限流**(10 次 / 分钟)。

token 过期用 `POST /v1/auth/refresh`(公开,RTR:旧 refresh token 立即失效)。

### 2.3 `GET /v1/app/config`(公开签名组)

```jsonc
{
  "maintenance": { "active": false, "message": "", "resume_at": null },
  "kill_switches": [],
  "config": {
    "song": {
      "duration_options_ms": [90000, 120000, 150000, 180000],
      "default_duration_ms": 150000,
      "preview_duration_ms": 30000,
      "output_format": "mp3"
    },
    "retention": { "works_days": 7, "membership_differentiated": false },
    "upload_limits": { "max_file_bytes": { "default": 20971520 }, "max_inflight_uploads": 3 }
  }
}
```

**时长选项必须从这里读,不要写死。** 平台会随实测调整这个闭集。

`kill_switches` 里出现下列码时,对应入口需**灰掉并给文案**:

| 码 | 关掉的东西 |
|---|---|
| `submit:pipeline:ai_song_preview_v1` | 只关预览 |
| `submit:pipeline:ai_song_full_v1` | 只关成品 |
| `submit:pipeline` | 关全部管线 |
| `submit:lyria-3-pro-preview` | 关模型直连 |

`maintenance.active=true` → 全站维护页,`message` 直接展示。

---

## 3. 一首歌的完整时序

```
① 用户输入一句话
      ↓ (可选) POST /v1/prompt-assist   mode=enhance|expand   —— 帮用户把描述写好
② POST /v1/tasks/estimate  pipeline_code=ai_song_preview_v1   —— 报价 100,不冻结
③ POST /v1/tasks           pipeline_code=ai_song_preview_v1   —— 冻结 100
      ↓ GET /v1/tasks/:bid/stream  (SSE)
④ completed → GET /v1/tasks/:bid 拿 candidates[]  —— 两段 30 秒,按 index 升序 = A、B
⑤ 用户试听选一个方向
⑥ POST /v1/tasks           pipeline_code=ai_song_full_v1      —— 冻结 115
      ↓ SSE 同上
⑦ completed → candidates[0] 是完整歌;files[role=sidecar] 是词级时间轴
⑧ 作品列表 GET /v1/accounts/me/candidates   —— 7 天内全部
```

**积分不够**:`③`/`⑥` 返 `40201`(余额不足)→ 引导到 §7 内购。

---

## 4. 提交

### 4.1 估价 `POST /v1/tasks/estimate`

**与提交同参**,不冻结。返:

```jsonc
{ "credits": 100, "unit_cost": 100, "unit": "per_request", "quantity": 1,
  "breakdown": "…", "applied_tier": "default", "confirmation": { … } }
```

⚠️ 估价与提交**同源同码**。估价过了提交就不会因参数被拒 —— 反过来,估价被拒就别提交。

### 4.2 提交 `POST /v1/tasks`

```jsonc
{
  "pipeline_code": "ai_song_full_v1",     // 或 "ai_song_preview_v1"
  "idempotency_key": "<= 64 字节>",
  "params": {
    "prompt": "…",                        // 必填。风格/乐器/BPM/情绪/曲式;歌词写进来;
                                          //   纯伴奏写 "Instrumental only, no vocals";
                                          //   时长也在这里说(如 "create a 2-minute song")
    "lyrics": "今天是你的生日…",            // 可选。用户确认的那份词,**仅用于回听比对**
    "vocal_mode": "vocal",                // 可选 vocal | instrumental,默认 vocal
    "target_duration_ms": 150000,         // 可选。**仅用于时长判据**
    "language_hints": ["zh"],             // 可选 ≤4 项
    "reference_image_bids": ["<asset bid>"],  // 可选 ≤10 张,**资产 BID 不是 URL**
    "variant_a_label": "温暖",             // 仅预览管线,可选 ≤64 字节
    "variant_b_label": "明亮"
  }
}
```

响应:

```jsonc
{ "task_id": "<uuid>", "status": "processing", "poll_url": "/v1/tasks/<bid>", "estimate_ms": 60000 }
```

### 4.3 🔴 六条硬约束(违反的后果都写在后面)

| # | 约束 | 违反会怎样 |
|---|---|---|
| **C1** | `prompt` / `lyrics` 上限按**字节**算(各 8000),不是字符 | 3000 个汉字 = 9000 字节 → `40001`,而前端「字数」显示是没超的 |
| **C2** | `reference_image_bids` 只收**资产 BID**,不收 URL | 传 URL → `40001`。平台不替客户端去取任意地址 |
| **C3** | `lyrics` / `vocal_mode` / `target_duration_ms` 只喂**验收判据**,不进上游 —— 真正决定产物的是 `prompt` | 三者与 `prompt` 说的不一致时,一首**正确**的歌会被判不合格并重做,而积分照扣 |
| **C4** | 缺省即跳过:不给 `lyrics` → 不判歌词保真;不给 `target_duration_ms` → 不判时长 | 你以为验了,其实没验 |
| **C5** | 成品时长只许从 `song.duration_options_ms` 里选(当前 90/120/150/180 秒)。**30 秒只存在于预览** | 成品用的模型有约 60 秒下限(实测要 45 秒给 59–74 秒,18/18 全超)。给下限附近或以下的档 = 每次必然判不合格并重做,积分照扣 |
| **C6** | 只出 MP3,没有高音质档 | 上游不支持 WAV(实测 20/20 拒) |

### 4.4 幂等

`idempotency_key` 相同 → **70 分钟内**返回原任务,且仅当那个任务**还有东西可保护**时:

| 原任务状态 | 行为 |
|---|---|
| 在途(`pending`/`processing`)、已出片(`completed`/`partial`) | 返回原任务,不重复扣费 |
| 已失败 / 超时 / 取消 | **不返回** → 按新任务受理并正常扣费(那次的积分已退) |
| 超过 70 分钟 | **不返回** → 同上 |

⇒ **不要把幂等键当"这组输入只会扣一次费"的长期凭证。** 它是一个**短窗**的重复提交保护,
防的是网络重试与用户连点(秒级),不是"同样的入参永远只出一份成品"。

✅ **原「跨月重放同一个 key 会重新扣费」的缺陷已于 2026-09-15 修复**
(`docs/adr/ADR-023`)。根因是两处叠加:任务表按 `created_at` 分区,
唯一索引必须含分区键 ⇒ 同键多行合法;而查找用了 `Only()` 撞上多行即报错,
该错又被压成「不存在」⇒ 每次重提都新建任务并扣费。现已改为按 `created_at` 倒序取最新一行,
且查找故障 fail-close。**key 不再需要含月份。**

⚠️ 但注意口径变了:现在超过 **70 分钟**重放同一个 key 就会新建任务并扣费 ——
这不是缺陷而是有意的边界(见上表),比原来的"跨月"更早。

---

## 5. 进度

### 5.1 SSE `GET /v1/tasks/:bid/stream`

| event | 说明 |
|---|---|
| `snapshot` | 首帧:任务当前完整状态(同 `GET /v1/tasks/:bid`) |
| `progress` | 步骤边界推送,带 `data.payload.stage` + 真实百分比 |
| `candidate_ready` | 单个候选落库,`data.candidate_index` |
| `completed` / `failed` | 终态,推完服务端关流 |
| `done` | 会话结束,`data.reason` |
| `: hb` | 心跳注释行,无新事件时每 15s |

断线重连带标准 `Last-Event-ID`,服务端从该 ID 之后续推。单会话 10 分钟须重连。

### 5.2 阶段进度

```
预览:  0% composing → 50% composing → completed 100%
成品:  0% composing → completed 100%
```

**阶段闭集只有 `composing` 一个值。** 遇到闭集外取值按「正在生成」兜底。

⚠️ **百分比不随时间自增**,它是「已完成步数」。等待动画请用 `estimate_ms` 驱动,
**不要拿 `progress` 当秒表** —— 上游不给内部进度,按本地计时补中间态就是伪造进度。

### 5.3 任务状态

`pending` → `processing` → `completed` / `failed` / `timeout` / `cancelled` / `partial`

⚠️ **`partial` 是成功的一种**(预览两段只成了一段)。`completed` 事件里要读
`data.task_status` 区分,别把 `partial` 当全成。积分按完成比例部分退。

取消:`POST /v1/tasks/:bid/cancel`。**服务端确认取消后才释放冻结**。

---

## 6. 产物

### 6.1 产物在候选层,不是资产

`GET /v1/tasks/:bid` 的 `candidates[]`,按 `index` 升序 = A、B。

```jsonc
{
  "bid": "…", "task_bid": "…", "index": 0,
  "status": "ready",                    // ready | selected | discarded | expired | pending
  "moderation_status": "skipped",
  "content_type": "audio",
  "url": "https://…",                   // 播放 URL,presigned,**TTL 1 小时**
  "primary_url": "https://…",           // 与 url 同值(历史兼容字段)
  "duration_ms": 30000,
  "metadata": {                         // 产出步骤自述,平台不解释
    "variant_label": "温暖",             // ← 你提交时给的标签,原样带回
    "verified": true,
    "alignment_precision": "word",
    "audio_sha256": "…"
  },
  "files": [
    { "role": "original", "url": "…", "mime_type": "audio/mpeg",
      "file_size": 708000, "duration_ms": 30000 },
    { "role": "sidecar",  "url": "…", "mime_type": "application/json",
      "file_size": 4096 }               // ← 词级时间轴
  ],
  "expires_at": 1757913600,             // Unix 秒,7 天后
  "created_at": 1757308800
}
```

⚠️ **播放 URL TTL 只有 1 小时**。长播放列表要**播放前重新拉一次**任务详情,不要缓存 URL。

### 6.2 两段试听怎么显示名字

| 你的做法 | 客户端要做的 |
|---|---|
| **不给标签**(默认) | 按 `index` 升序显示「版本 A / 版本 B」 |
| **提交时给了 `variant_a_label` / `variant_b_label`** | 读 `candidates[].metadata.variant_label` |

平台**不提供**方向词表 —— 平台没有拿「温暖/明亮」这类词去引导生成,凭空起名就是编。
标签是**你自己的词**,所以永远不会出现你不认识的取值。

### 6.3 词级时间轴

`files[role=sidecar].url` 下载得到:

```jsonc
{
  "schema": "lyric_timeline_v1",        // ← 先判这个字段再解析
  "source_schema": "transcript_v1",     // 内容派生来源,如实记录
  "alignment_precision": "word",        // word | line | none
  "duration_ms": 150000,
  "audio_sha256": "…",                  // 与音频的绑定锚
  "word_timings": 149,
  "lines": [
    { "idx": 0, "t0": 1200, "t1": 5800, "text": "今天是你的生日",
      "words": [ { "t0": 1200, "t1": 1650, "w": "今" } ] }
  ]
}
```

`alignment_precision` **如实声明精度,绝不上调**:

| 值 | 你能做什么 |
|---|---|
| `word` | 逐字高亮 |
| `line` | 只能行级高亮 |
| `none` | 只能静态展示歌词 |

⚠️ **平台绝不按总时长平均分配来伪造时间轴。** 拿到 `none` 就老实静态展示。

⚠️ `lyric_timeline_v1` 与转写产品的 `transcript_v1` 是**两个 schema**,各自演进。
请判 `schema` 字段,不要假设它等同于转写格式。

### 6.4 选版与作品列表

| 动作 | 端点 |
|---|---|
| 丢弃另一版 | `POST /v1/candidates/:bid/discard` |
| 我的作品(跨任务,7 天内) | `GET /v1/accounts/me/candidates` |
| 单个候选详情 | `GET /v1/candidates/:bid` |

### 6.5 🔴 不要调 `save`

`POST /v1/candidates/:bid/save` 会把作品变成**永久保留**的资产。

产品定的保留期是 **7 天**,而候选层本身就是「7 天有效的我的作品」——
到期平台自动删,连存储上的文件一起删,音频和时间轴一起删。
**调了 save 就跳出这个机制**,而平台目前没有给免费用户的作品设过期的路径。

---

## 7. 钱包与内购

### 7.1 余额 `GET /v1/wallet`

```jsonc
{ "balance": 897,          // ← **可用**积分(已扣掉冻结),UI 显示这个
  "frozen": 115,           // 进行中任务的预扣
  "total_credited": 897, "total_debited": 0,
  "features": [] }
```

流水 `GET /v1/wallet/ledger?cursor=&limit=`(keyset 分页)。

### 7.2 三档商品

`/v1/app/init` 的 `products[]`。当前三档:

| `store_product_id` | 形态 | 价格 | 积分 | 约合首数 |
|---|---|---|---|---|
| `aisinger.sub.weekly` | 周订阅 7 天,订阅组 `aisinger_main` | ¥38 | 897 | 4.1 首/周 |
| `aisinger.credits.small` | 消耗型 | ¥68 | 1606 | 7.4 首 |
| `aisinger.credits.large` | 消耗型 | ¥198 | 4675 | 21.7 首 |

`store_platform` 全为 `apple` → 客户端用 `store_product_id` 调 StoreKit。

⚠️ **三档都不带任何权益标**(`features` 为空)。付费页**不要**写「高清输出 / 去水印 /
优先队列 / 高级模型」—— 这四个标准权益码对写歌全部无效,平台不兑现。

⚠️ **不要写「会员作品保留更久」**。保留期是 7 天,**与会员等级无关**,
平台的清理程序里根本没有订阅判断,做不到差异化。

### 7.3 购买链路

```
POST /v1/iap/orders                    → 创建订单,拿 order_no
      ↓ StoreKit purchase(store_product_id)
POST /v1/iap/orders/:order_no/verify   → 提交收据,校验通过即发积分
POST /v1/iap/restore                   → 恢复购买(有专项限流)
```

`restore` **只幂等延长订阅权益,不重发积分** —— 消耗型积分是一次性的,重发即膨胀。

### 7.4 ⚠️ 积分有效期:首购与续期不一致

这是平台**既有行为**,不是本产品引入的:

| | 有效期 |
|---|---|
| 消耗型(小包/大包) | **永不过期** |
| 周卡**第一周** | **永不过期** |
| 周卡**第二周起**每次续期 | **本计费周期结束即过期** |

**文案两句都不能写**:「积分永久有效」错一半,「每周清零」也错一半。
建议只说「周卡每周发放 897 积分」,不提有效期。

---

## 8. 失败与话术

### 8.1 写歌专有失败码(读 `error_code`)

| `error_code` | 含义 | 建议话术与动作 |
|---|---|---|
| `lyrics_mismatch` | 唱出来的词与你提交的词差太多 | 「歌词没唱准,换个说法试试」→ 引导改歌词重试 |
| `vocal_detected` | 要纯伴奏却唱出了人声 | 「这次混进了人声」→ **直接重试**按钮 |
| `duration_out_of_range` | 时长不在容差内 | 「时长没控住」→ 引导改时长档 |
| `content_filter_unspecified` | 上游安全过滤器**非确定性**拦截(实测 6.7%) | 「网络开小差」→ **直接重试**,同样的输入多半就过了 |

⚠️ `content_filter_unspecified` 与真正的内容违规是**两回事**,处置相反:
前者直接重试,后者要引导用户改内容。别归纳成同一句话。

### 8.2 回听不可用时会怎样

验收依赖一次 ASR 回听。回听服务故障时,平台**按未验收交付**,不重做 ——
重做对「ASR 挂了」毫无帮助,只是让用户多等一轮多花一次钱。

此时产物照常返回,`metadata.verified = false`。客户端**不必特殊处理**,
但如果做了「已校验」角标,记得读这个字段。

### 8.3 通用错误段

| 码 | 含义 |
|---|---|
| `40001` | 参数错(六条硬约束的违反都落这) |
| `40201` | 积分不足 → 引导内购 |
| `40113` / `40115` | 签名/时钟问题 → 重新校时后重试 |
| `50830` | 管线定价缺失(不该出现;出现即平台配置事故) |

完整码表见 [`error-codes.md`](error-codes.md)。

---

## 9. 平台**不做**的事(边界,不是待办)

这些是当前平台能力的真实边界。客户端要么规避,要么自己承担。

| # | 平台不做 | 后果 / 客户端怎么办 |
|---|---|---|
| **B1** | **没有 Apple 登录,没有账号绑定** —— 认证面只有游客注册 | **换机 / 重装 = 账号与余额丢失,不可找回**。这条会直接影响付费用户投诉率,产品侧须评估是否可接受再上架 |
| **B2** | 没有免费额度 | 拉新请走 App Store 首购优惠 |
| **B3** | `prompt-assist` 只有 `enhance` / `expand` 两个 mode | **没有押韵(rhyme)模式**,也没有歌词专用提示词模板。歌词辅助只能用通用增强/扩写 |
| **B4** | 没有音频转码 / 多码率 | 只有一份 MP3 |
| **B5** | 不做输出内容审核 | 提示词入口有审核,**音频产物没有** |
| **B6** | 不做产品级埋点 | 事件采集客户端自理 |
| **B7** | 作品保留期固定 7 天,不可按用户分档 | 见 §7.2 的文案禁令 |

---

## 10. 上线前自检

对着这份逐条打勾,全绿才提审:

- [ ] 冷启动先调 `/v1/app/init` 并用 `server_time` 校时,再发任何签名请求
- [ ] 时长选项从 `/v1/app/config` 的 `song.duration_options_ms` 读,**没有写死**
- [ ] `prompt` / `lyrics` 长度校验按**字节**,不是字符
- [ ] 参考图传的是**资产 BID**,不是 URL
- [ ] `lyrics` / `vocal_mode` / `target_duration_ms` 与 `prompt` 里说的**一致**
- [ ] 播放 URL **播放前重新拉**,没有长期缓存(TTL 1 小时)
- [ ] `completed` 事件读了 `data.task_status`,`partial` 有单独处理
- [ ] 按 `alignment_precision` 三态分别渲染,拿到 `none` 老实静态展示
- [ ] 时间轴先判 `schema == "lyric_timeline_v1"` 再解析
- [ ] **没有调** `POST /v1/candidates/:bid/save`
- [ ] `kill_switches` 四个码都有对应的入口灰掉逻辑
- [ ] `maintenance.active` 有维护页
- [ ] `legal` 三个链接为空时**降级不渲染**
- [ ] 付费页**没有**写四个权益标,**没有**写「会员作品保留更久」
- [ ] 积分有效期文案**既没写**「永久有效」**也没写**「每周清零」
- [ ] 四个写歌失败码各有话术,`content_filter_unspecified` 是**直接重试**不是「内容违规」
- [ ] 幂等 key 含月份(或保证 24h 内不跨月重放)
- [ ] B1 的后果(换机丢账号)已在产品侧被明确接受

---

## 11. 改动会通知你

以下任一变化平台会主动回传,不要靠自己发现:

- `song.duration_options_ms` 闭集变化(实测数据更新后可能放宽)
- 阶段闭集从 `composing` 扩展
- 新增写歌失败码
- 三档商品的积分数或价格变化
- B1 / B3 边界解除(Apple 登录、押韵模式)
