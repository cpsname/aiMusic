# Claude Code 开发指令 —— `iap_template` 企业级 IAP + AIGC 基础设施模板

> 把本文件作为权威开发契约。整个开发过程以**正确性、架构完整性、可复用性**优先于交付速度。
>
> **配套规格**（与本文件同目录，Claude Code 须读取标「权威输入」的两份）：
> - `STOREKIT2_PURCHASE_SPEC.md`〔权威输入〕— IAP 模块实现级规格；本文件 §3.2-iap 与 §4 指向它。
> - `DEEP_FOUNDATIONS_SPEC.md`〔权威输入〕— 7 项横切深度基建；本文件 §3.5 与 Phase 4 指向它。
> - `BACKEND_COORDINATION.md`〔参考/交后端〕— 需后端配合的契约（服务器时间、ASSN V2、订单语义等）；客户端按其约定的字段对接，不在本次开发范围内实现后端。
> - `NEW_PROJECT_CHECKLIST.md`〔参考〕— 将来复制本模板开新项目的操作手册，非开发期输入。

---

## 0. 角色与总目标

你是负责 `iap_template` 的资深 Flutter 架构工程师。目标：把它建成**可复用的企业级基础设施模板（monorepo）**，使任何新项目复制后**无需重复接入**以下能力即可直接开展业务开发：

App 初始化（/app/init） · 游客注册（HMAC 签名链） · 订单创建 · 订单服务端校验 · StoreKit 2 订阅购买（含 App Store Connect 下发的多语言商品列表） · 钱包与功能门控 · 多语言 i18n · 网络拦截与日志 · 统一错误体系。

并交付一个可端到端跑通的业务示例：**登录用户信息（Profile）页 + 内购产品列表付费墙（点击购买走完整流程）**。

---

## ⛔ 硬性元规则（贯穿全程，违反即返工，不可协商）

1. **禁止任何形式的简化交付**：不得留待办标记 / 占位 / 空实现 / `throw UnimplementedError()` / `// mock` / 注释掉的逻辑 在交付物中。每个声明的能力必须真实实现并被测试覆盖。
2. **禁止绕过架构约束**：不得在 `features/` 下新建 `presentation/`；不得跨 `domain/data/application` 层混合职责；不得制造反向依赖；不得新增与现有职责重复的 Riverpod provider。
3. **禁止降低可扩展性**：复用现有接口与 provider；动态数据一律走 provider，**严禁硬编码**产品名/价格/折扣/周期/文案；保持 sealed 错误体系与分层契约的开放性。
4. **禁止表面修复**：bug 与边界要在**正确的层**根因解决（如 SK2 取消在 data + orchestrator 层处理，而非 patch stream / 注入伪事件）；不得通过删测试、放宽 analyze、`// ignore` 掩盖、关闭 SPM 等手段制造"通过"假象。
5. **遇到"必须破坏上述规则才能完成"的情况：停下，写明阻塞点与备选方案，等待指示，不得擅自简化。**

---

## 1. Phase 0 — 现状勘察（先做，禁止写业务代码）

1. 读取并理解：`CLAUDE.md`、`README.md`、`pubspec.yaml`、`analysis_options.yaml`、`docs/api/*`、现有 `lib/` 与 `test/`，以及两份权威规格 `STOREKIT2_PURCHASE_SPEC.md`、`DEEP_FOUNDATIONS_SPEC.md`。
2. 判定仓库当前形态，三选一并据此选择路径：
   - **(a) 空/骨架项目** → 按第 2、3 节从零实现整套架构。
   - **(b) 已是 `iap_flow_kit` 单体形态** → 先按第 2.1 节 monorepo 化（如已有 `tool/extract.sh` 与 `MIGRATION.md` 则据其执行并完成人工收口），再补齐能力。
   - **(c) 已部分实现** → 逐项核对第 3 节能力清单，仅补齐缺口，不重写已合规的部分。
3. 输出一份**现状报告 + 分阶段实施计划**（含每阶段验收门禁），再开始动手。计划与本文件冲突时以本文件为准；信息不足处先勘察/提问，不臆测。

---

## 2. 目标架构（权威契约）

### 2.1 Monorepo（pub workspace + melos）

```
<repo>/
├── pubspec.yaml                  # workspace 根：workspace: 成员清单 + melos dev_dep
├── melos.yaml                    # 跨包脚本（analyze / test / version）
├── packages/
│   ├── infra_core/   # 纯基建：network / crypto / error / config / storage / device / utils。零业务、零 UI、无 iOS 原生代码
│   ├── commerce_kit/ # 商业化核心：auth + iap + wallet 的 domain/data/application。→ infra_core
│   └── ui_kit/       # Aura 视觉原语：AuroraBackground / GlassCard / ObsButton / GradientText / Typewriter / Tokens / Typography
└── apps/studio_app/  # 脚手架样板：ui 屏幕 + provider/creation 示例 + settings + l10n + testing + 平台目录。→ 三个包
```

- 各成员 `resolution: workspace`，`environment: sdk: ^3.11.0`；成员间依赖在 workspace 内走 `path`，对外新项目改为 `git: {url, ref}` tag。
- 依赖方向（单向，禁止反向）：
  `ui → app/providers → commerce_kit(application → domain ← data) → infra_core`；`ui → ui_kit`；`* → infra_core`。
- 三个包均为纯 Dart/Flutter 包，**不含 `ios/` 插件代码、不需要 `Package.swift`**；叶子插件的原生依赖由 Flutter 在 app 层沿依赖树聚合。

### 2.2 分层与状态管理约定

- DDD 三层：`domain`（纯 Dart：模型 / 仓库接口 / 领域服务，不依赖 Flutter/Dio）→ `data`（DTO fromJson/toJson/toDomain、数据源、仓库实现）→ `application`（Riverpod Provider + Notifier/AsyncNotifier/FutureProvider）。
- **手写 Riverpod，禁止代码生成**（与现有约定一致）。
- UI 只在 `apps/studio_app/lib/ui/`，复用 `ui_kit` 视觉原语，**不引入第二套主题系统**。

### 2.3 SPM 强制（硬约束）

- 目标工具链 Flutter ≥ 3.44（SwiftPM 默认开启）。**禁止**写 `config: enable-swift-package-manager: false` 或任何关闭 SPM 的绕法。
- iOS 部署目标 ≥ 15.0，macOS ≥ 10.14。
- `flutter_secure_storage ^10`（内置 SwiftPM）等插件直连 SPM；如个别插件缺 `Package.swift`，记录并在交付报告中列出，不得以关闭 SPM 规避。
- `device_info_plus` 维持 `>=11.0.0 <12.4.0`（iOS 26 API 需 Xcode 17），确认工具链后再放开。

---

## 3. 能力清单（按依赖序实现，逐包验收）

### 3.1 `infra_core`

- **Network（5 段拦截器，顺序固定）**：
  1. `DeviceHeadersInterceptor` — 注入 `X-Device-ID`(持久 UUID)/`X-Platform`/`X-App-Version`/`X-Os-Version`/`X-Device-Model`/`X-App-Build`/`X-Language`
  2. `AuthInterceptor`(`QueuedInterceptor`) — Bearer 注入；**40102 静默刷新+重放**（用独立 `retryDio` 切断递归）；**40106 强制登出**（不重试、清本地）
  3. `RetryInterceptor` — 408/429/500/502/503/504 可配置重试
  4. `EnvelopeInterceptor` — 解包 `{code,message,data,request_id,timestamp}`；`code!=0` → 类型化 `ApiError`（`handler.reject(err, true)`）
  5. `LoggingInterceptor` — 仅 dev/staging
- **Crypto**：`SigningService` HMAC-SHA256 over `timestamp + nonce + canonical_json(body)`（递归键排序）；guest-register 以 canonical JSON 原文为 body 保证字节一致。
- **Error 双层 sealed**：`ApiError`（Auth/Signature/Validation/InsufficientCredits/RateLimit/Conflict/ContentFilter/Server/NotFound/Permission）→ `ErrorHandler.handle()` → `Failure`（Auth(requiresForceLogout)/Payment/RateLimit(retryAfterSeconds)/Validation(details)/ContentFilter/Signature/Server/Network/Store/Cache）→ `GlobalErrorPresenter.show(context, failure)`。
- **Config**：`EnvConfig`(dev/staging/prod) 含 `distributionCode/distributionSecret/appCode/bundleId/iapChannel/baseUrl`，**密钥零硬编码**，仅经 `String.fromEnvironment` 读取（app 用 `--dart-define-from-file` 注入，密钥文件入 `.gitignore`）；`ApiConfig` 分环境超时/重试。
- **Storage**：`flutter_secure_storage`(Token) + `shared_preferences`(设置/待处理订单/商品缓存) 封装。
- **Device**：持久化 UUID 设备 ID + OS/机型信息缓存。
- **i18n 脚手架**：gen-l10n 配置随 app（见 3.4），公共与项目文案分治；若基建类需文案，经参数/错误码注入，**禁止基建包 import app 的 `AppLocalizations`（反向依赖）**。

### 3.2 `commerce_kit`

- **auth**：guest-register（HMAC 签名链）、login、refresh、logout、logout/all、`/me`。
  - 状态机 `AuthPhase: Idle → Registering → Authenticated(userId,isGuest,token) | Error(failure)`；`ensureAuthenticated()`(有效用/过期refresh/无则guest-register)、`login/logout/refreshAccessToken`。
  - `currentAccountProvider`(FutureProvider<MeResponse>)：7 段优雅降级（基础信息/订阅?/钱包?/features[]/会话?/guidance{needsProfileComplete,hasActiveSubscription,hasCredits}）。
- **iap**：`/app/init`、`/iap/orders`、`/iap/orders/{no}/verify` + StoreKit 2 / Play Billing。
  - **实现以 `STOREKIT2_PURCHASE_SPEC.md` 为权威规格**：分层职责、购买/恢复状态机、用户会话 vs 应用级后台对账、SK2 取消的数据层契约、验证退避与幂等、商品目录动态化、订阅专属增强项（续订/撤销/退款/Ask-to-Buy/宽限期门控/已订阅路由）均在其中。本节不再重述，须严格按该文件实现。
  - 启动编排：`StartupNotifier.start()` 并行 `/app/init`(noAuth) 与 guest-register → 强更检查 → ready → fire-and-forget 预取 /me+/wallet → 扫描 `PendingOrderStore` 恢复未完成购买；同时建立应用级常驻事务对账（见 SPEC §5）。
- **wallet**：`/wallet`。`walletBalanceProvider`(int) / `hasFeatureProvider(String)`(bool, 激活且未过期) / `activeWalletFeaturesProvider`(List<WalletFeature>)。刷新触发：启动、IAP verify 成功、任务终态、前台恢复。

### 3.3 `ui_kit`

- 迁移/实现 Aura 视觉原语与设计 token：`AuroraBackground`、`GlassCard`、`ObsButton`、`GradientText`、`Typewriter`、`StudioTokens`、`StudioTypography`、`AuraTheme.light`。明暗双模式可扩展。
- 不含业务、不含 provider；纯展示原语，供 app 复用。

### 3.4 `studio_app`（含业务示例 UI）

- 入口：`MaterialApp(home: StartupGate(child: StudioShell()))`，无路由表。`StartupGate`(splash/强更/错误重试)、`StudioShell`(adaptive 外壳)。
- **i18n**：`lib/.../l10n/arb/`（en / zh / ja / ar），`flutter gen-l10n`。
- **Profile 页**（`lib/ui/me/`）：
  - 消费 `currentAccountProvider`(MeResponse) + `walletBalanceProvider` + `activeWalletFeaturesProvider`。
  - `AsyncValue` 三态：loading 骨架 / data 展示 / error → `GlobalErrorPresenter` 或就地重试。
  - 游客态给登录入口（走 auth 流程）。
- **付费墙页**（`lib/ui/paywall/`）：
  - 商品列表**动态**来自 `storeProductsProvider`/`iapCatalogProvider`，无任何硬编码名/价/折扣。
  - 加载中显示骨架（shimmer，色取 token；`AnimationController` 随 dispose 销毁、测试用 `tester.pump()` 单帧）；加载失败降级纯文本 + 重试，不阻塞。
  - 购买按钮触发 `IapPurchaseOrchestrator`；watch 编排器状态驱动：进行中 loading、**取消（非错误，不弹错误框，恢复按钮）**、失败弹错误、成功 → `ref.invalidate(walletProvider)` 刷新余额。
  - 含"恢复购买"入口。
  - **不新增 provider**，复用 commerce_kit application 层；UI 仅在 `lib/ui/`，复用 `ui_kit` 原语。

### 3.5 横切深度基建（实现以 `DEEP_FOUNDATIONS_SPEC.md` 为权威规格）

支付/AIGC 类 App 必备、但最易在模板期被跳过的 7 项横切基建。各项落点与验收见该文件，本节仅给落点索引（不在此重述实现）：

| 项 | 落点 | 后端依赖 |
|---|---|---|
| ① 时钟偏移抗签名失败 | infra_core/crypto+config+network | 是（`server_time`）|
| ② 生产可观测性（runZonedGuarded + 厂商无关 TelemetrySink + IAP 漏斗 + PII 脱敏）| infra_core/observability + bootstrap | 是（`request_id` 关联）|
| ③ 架构边界 lint 强制（custom_lint + CI 红线）| 仓库层 + analysis_options | 否 |
| ④ Apple 隐私清单 + Required-Reason API | apps/studio_app/ios | 仅账号删除端点 |
| ⑤ RTL / 阿拉伯语正确性（双向 golden）| ui_kit + studio_app | 否 |
| ⑥ 减弱动态效果 + 功耗（reduce-motion / 后台暂停动画）| ui_kit + 生命周期服务 | 否 |
| ⑦ 持久化数据版本迁移（schemaVersion + Migrator）| infra_core/storage | 否 |

> ③ 架构 lint 须在 Phase 1 即引入（使后续各阶段受门禁保护）；① ② ⑦ 在 Phase 2（infra_core）接入；⑤ ⑥ 在 Phase 3（ui_kit）接入；④ 与全部收口在 Phase 4 完成。

---

## 4. IAP 安全不变量与 StoreKit 2 订阅逻辑 → 见 `STOREKIT2_PURCHASE_SPEC.md`

本节全部内容（状态机、`PendingOrderStore` 时序、verify-then-finish、退避重试码、`purchaseStream` 超时、`expires_at` 解析、`40011`/`40912` 等特例、SK2 取消的数据层契约、应用级后台对账、订阅专属增强与不变量）以 **`STOREKIT2_PURCHASE_SPEC.md`** 为权威规格，须严格按其实现，**不得简化或绕过**。该文件中标注的【纠偏】点（用户取消产生的孤儿 pending 单处理）需先与服务端订单生命周期对齐再定稿。

---

## 5. 验收门禁（每阶段末必须全部通过，否则先修复不进下阶段）

1. `melos exec -- flutter analyze` **零 warning / 零 error**（不得用放宽 lint、`// ignore`、删规则等方式凑过）。
2. `melos exec -- flutter test` 全绿；**新增能力须有对应测试**：orchestrator 每条状态分支（成功/取消/失败/断点续传）有 unit 测试；Profile / Paywall 有 widget 测试（用 `pumpApp()`；含 `AuroraBackground` 的用 `tester.pump()` 单帧，**禁止 `pumpAndSettle()`** 否则无限动画会 hang）；`Override` 从 `package:riverpod/misc.dart` 导入。
3. `cd apps/studio_app && flutter build ios --config-only` 通过；SPM 插件齐全（缺 `Package.swift` 的插件列入报告）。
4. 全仓 `grep -rn "T[O]DO\|UnimplementedError\|F[I]XME\|占位\|mock实现"` 在交付物中**无残留**（测试 fixtures/fakes 除外）。
5. 端到端可跑：游客启动 → 注册 → Profile 展示 /me 与余额 → 唤起内购 → 成功/取消/失败/断点续传四条路径状态正确、余额随成功刷新。
6. **架构边界 lint** `melos exec -- custom_lint` 零越界（`features`/包→`ui`、包→app 反向依赖、跨层 import 等规则，见 `DEEP_FOUNDATIONS_SPEC.md` §3）；CI 红线。
7. **iOS 隐私清单完备**：`PrivacyInfo.xcprivacy` 聚合全应用 API/数据使用，Xcode Organizer / TestFlight 上传无隐私警告（ITMS-91xxx）。
8. **深度基建验收**：`DEEP_FOUNDATIONS_SPEC.md` 各项验收通过——时钟偏移（偏移时钟下签名被校正）/ 可观测性（异常入 sink + 脱敏 + 漏斗事件）/ RTL（ltr+rtl 双向 golden）/ 减弱动态（reduce-motion 不启动 ticker、后台暂停）/ 存储迁移（旧 schema 迁移 + 损坏数据降级不崩）。

---

## 6. 工作方法与阶段

- **Phase 0**：勘察 + 计划（第 1 节）。
- **Phase 1**：monorepo 化与边界落地（第 2.1 节）+ **引入架构 lint 规则集**（§3.5③，使后续各阶段受门禁保护）；过门禁 1、6。
- **Phase 2**：`infra_core` → `commerce_kit` 能力实现/补齐（第 3.1–3.2 节 + `STOREKIT2_PURCHASE_SPEC.md`）+ **接入 §3.5①②⑦**（时钟偏移 / 可观测性 / 存储迁移）+ 测试；过门禁 1、2、4、6。
- **Phase 3**：`ui_kit` + `studio_app`（Profile + Paywall，第 3.3–3.4 节）+ i18n + **§3.5⑤⑥**（RTL / 减弱动态）+ 测试；过门禁 1、2、4、5、6。
- **Phase 4 — 深度基建收口与加固**：完成 `DEEP_FOUNDATIONS_SPEC.md` §4 隐私清单（及账号删除端点对接）+ 复核全部 7 项验收 + 补齐 ① 的 offset 未就绪重签路径、② 的全分支漏斗埋点、⑤ 的双向 golden；过门禁**全部 1–8**。
- 每阶段结束输出简报：完成项、门禁结果、未决项与原因。
- 全程保持 `CLAUDE.md` 与实际架构同步更新（它是后续协作的权威指引）。
- 任一时刻若发现需破坏元规则才能推进 → 停止并上报（见元规则 5）。

---

## 7. 一句话蒸馏

> 把 `iap_template` 建成 pub-workspace monorepo（infra_core / commerce_kit / ui_kit / studio_app，全程强制 SPM），完整实现初始化·游客注册·订单创建与校验·StoreKit2 订阅与动态多语言商品列表·钱包门控·i18n·五段网络拦截与统一错误体系，叠加横切深度基建（时钟偏移抗签名·生产可观测性·架构边界 lint 强制·隐私清单·RTL·减弱动态·存储迁移），并交付端到端可跑的 Profile + 动态付费墙示例；严守 DDD 分层与 IAP 安全不变量，零待办/占位、零硬编码、analyze 与测试全绿、架构 lint 零越界、iOS SPM 构建与隐私清单通过——任何需要简化或绕过约束的地方一律停下上报而非自行降级。
