# 设计方案 — 网络请求失败重试界面(无网络 / 请求失败场景)

状态:**待人工确认**(本轮仅方案,不含实现代码)。
范围澄清:通用网络请求失败重试,**不涉及** iOS Local Network 权限、ATT、任何系统权限弹窗或跳转「设置」。

---

## 0. 关键纠偏(预读后,先纠正提示词与直觉中的错误前提)

预读得到三条与"凭直觉的方案"相悖的事实,直接决定了设计方向:

1. **"无网络"目前根本无法被区分。** `connectionError`(Dio 对 `SocketException`/不可达的归类)与三类 timeout 被 `ErrorHandler` **折叠进同一个无字段的 `NetworkFailure`**(`error_handler.dart:77-85`)。UI 拿到的 `NetworkFailure` 只有 `message/code/requestId`,**没有任何判别字段**(`failure.dart:71-73`)。所以"为真·无网络单独呈现"在当前类型体系下是做不到的——这是本方案要不要补的第一个决策(决策 A)。
2. **无网络其实已经在自动重试。** 传输层 `RetryInterceptor` 明确把 `connectionError` 当作可重试(`retry_interceptor.dart:47`),与三类 timeout 一起,按有界退避列表(prod 400/900/2000ms,`api_config.dart:25-29`)重试。IAP `IapVerifier` 同样重试 `connectionError`(`iap_verifier.dart:75`)。**所以"网络层自动重试"不是缺口**;UI 层缺的是"自动重试耗尽后,让用户原地手动再试"的呈现。
3. **存在一个真实缺口:`DioExceptionType.unknown`。** Dio 无法归类的 socket 错误落到 `unknown`,既**不被重试**(`retry_interceptor.dart:54-55`),又被 `ErrorHandler` 映射成 **`ServerFailure`** 而非 `NetworkFailure`(`error_handler.dart:95-96`)。即一部分"其实是没网"的失败,会被当成服务端错误展示——这是要顺带修的正确性问题。

---

## 1. 现状分析(基于预读,均附 `file:line`)

### 1.1 错误类型体系:无"网络不可用"细分

- `Failure`(sealed,`failure.dart:7`)十个变体:`Auth/Payment/RateLimit/Validation/ContentFilter/Signature/Server/Network/Store/Cache`(`failure.dart:18,29,33,44,55,63,67,71,77,81`)。
- **`NetworkFailure` 只有继承自基类的 `message/code/requestId` 三个字段,无任何判别字段**(`failure.dart:71-73`)。
- `ErrorHandler.handle`(`error_handler.dart:15-20`)→ `_fromDio`(`error_handler.dart:72-98`)的传输映射:
  - `connectionTimeout/sendTimeout/receiveTimeout/connectionError/badCertificate` → **同一个** `NetworkFailure`,无区分(`error_handler.dart:77-85`)。
  - `badResponse`(4xx/5xx 带 body):先尝试解析 envelope→`ApiError`,否则 `ServerFailure(code: status)`(`error_handler.dart:88-94`)。**5xx → `ServerFailure`,不是 `NetworkFailure`。**
  - `unknown`(常见地包着 `SocketException`)→ **`ServerFailure`**(`error_handler.dart:95-96`),且**未检查 `error.error` 是否为 `SocketException`**。
- 全仓 grep:**无任何 connectivity 包 / 可达性探测 / `SocketException` 处理**;"无连接"只能间接由 Dio 的 enum 推断。
- 上游:`ApiError`(sealed,`api_error.dart:9`,10 个变体)由 `EnvelopeInterceptor` 产出(`envelope_interceptor.dart:36,55` → `api_envelope.dart:53` → `api_error.dart:13-112`);业务错误走 HTTP 200 + 非零 code。

### 1.2 全局错误展示:一次性提示,带"可选"重试回调(但不自重试)

- `GlobalErrorPresenter.show(...)`(`error_presenter.dart:18-26`)—— **已废弃**(`error_presenter.dart:17`)。一次性 SnackBar,仅当传入 `onRetry` 时渲染 `SnackBarAction`(`error_presenter.dart:41-43`),自身不重试。
- 取代它的统一组件 **Message**(commit b3eb86f,`packages/ui_kit/lib/src/message/`):
  - `MessageVariant { loading, success, error, warning, info }`(`message_spec.dart:4`);`MessageSpec` 携带 `actionLabel/onAction/autoDismiss`(`message_spec.dart:18-28`)。
  - `MessageController.error(text, {actionLabel, onAction})`(`message_controller.dart:59`)——重试 action 即由 `onAction` 挂载,控制器**不自重试**。
  - `MessageView` 是 **inline / banner**(`GlassCard` 行内卡 + `TextButton` action,`message_view.dart:11,42-48`);`MessageHost` 默认 `AlignmentDirectional.bottomCenter`、`maxWidth 560`(`message_host.dart:20-21`)——**底部悬浮横幅栈,非全屏**。
- 应用侧桥接:`failureMessage(l10n, failure, {onRetry})`(`messages.dart:21`)已把 `NetworkFailure → l10n.commonNetworkError`(`messages.dart:30`),并在有 `onRetry` 时挂 `actionLabel: l10n.commonRetry`(`messages.dart:24,37-38`)。**这是现成的"失败+重试"行内通道。**

### 1.3 启动失败重试界面:存在,但为 bespoke 内联实现

- `StartupGate`(`startup_gate.dart`):首帧触发 `start()`(`startup_gate.dart:26-28`);`StartupReady→child`(`:36`);`StartupFailed(failure)→_StartupErrorView(message: messageForFailure(...), onRetry: _restart)`(`:42`);**重试 `_restart()` = 再次调用 `StartupController.start()`**(`:31`),非 invalidate。
- `_StartupErrorView` 为**私有内联**(`startup_gate.dart:125-149`):`GlassCard` → 标题 `l10n.startupErrorTitle` → 正文 → `ObsButton(label: l10n.commonRetry, onPressed: onRetry)`(`:144`)。
- `StartupController.start()`(`startup_controller.dart:42-86`):整体 `try/catch`,**任何**失败(含 `/app/init` 无网)→ `StartupFailed(errorHandler.handle(error))`(`:83-85`)。所以启动期网络失败**已**是可重试态。

### 1.4 现有重试覆盖:已含"无网络"(自动,有界)

- `RetryInterceptor._isRetryable`(`retry_interceptor.dart:42-57`):重试 `connectionTimeout/sendTimeout/receiveTimeout/connectionError`(`:44-48`)+ 可重试状态码 408/429/500/502/503/504(`api_config.dart:18`);**`unknown` 不重试**(`:54-55`)。退避 `retryBackoff[attempt]`(`:30`),prod 400/900/2000ms(`api_config.dart:25-29`)。
- `IapVerifier`:重试码集 `{40010,40016,40912,50000,50301,50302}`(`iap_verifier.dart:21-28`),`40011`=幂等成功(`:48-54`);transient 网络含 `connectionError`(`iap_verifier.dart:71-78`);退避 1/2/4s(`iap_providers.dart:43-45`)。
- 其它:`AuthInterceptor` 仅 token 刷新-重放(`40102`),不管网络重试(`auth_interceptor.dart`)。
- **结论:无网络的"自动有界重试"已存在;本需求是其耗尽后的"用户原地手动重试 UI",而非新增重试策略。**

### 1.5 UI 复用基线:有原子件,无"错误+重试"复用件

- ui_kit 原子件:`GlassCard`(`glass_card.dart:9`)、**`ObsButton`(主按钮,含 loading,`obs_button.dart:7-17`)**、`AuraSkeleton`(`skeleton.dart:11`)、`AuroraBackground`、`GradientText`、`Typewriter`、`MotionPolicy`。
- **不存在**可复用的 EmptyState / StatusView / 全屏状态 / "错误+重试"组件。
- **四处 bespoke 错误+重试卡几乎同构**(`GlassCard → Text → ObsButton(commonRetry)`),仅标题/消息接法与 `expand` 不同:
  1. `startup_gate.dart:125-149` `_StartupErrorView`(retry → `start()`)
  2. `profile_page.dart:274-299` `_ProfileError`(retry → `ref.invalidate(currentAccountProvider)`,接于 `:25`)
  3. `paywall_page.dart:398-422` `_ProductsError`(retry → `ref.invalidate(appInitProvider)`,接于 `:49`)
  4. `maintenance_gate.dart:65-111` `_MaintenancePage`(retry → `appConfigProvider.notifier.refresh(force:true)`,`:97-102`)
- 非重试失败面:profile 钱包余额错误渲染 `'—'`(`profile_page.dart:138`)、paywall `_FeatureUnavailable`(`:424-451`)、`_BillingRetryBanner`(`:356-375`)、购买失败走 message 栈(`:72-76`)。
- 业务页统一三态 `AsyncValue.when(skeleton/data/error+retry)`:profile `:21-28`、paywall `:46-52`。

### 1.6 文案管理

- `l10n.yaml`:`arb-dir: lib/l10n/arb`,模板 `app_en.arb`,生成到 `lib/l10n/generated/`(`AppLocalizations`,提交入库)。
- 双 ARB:`app_en.arb` + `app_zh.arb`;加 key→改两个 ARB→`flutter gen-l10n`;访问 `AppLocalizations.of(context)`(`startup_gate.dart:133`),非 widget 处以参数传入(`messages.dart:21-22`)。
- 现有相关 key:`commonRetry`(en `:4`)、`startupErrorTitle`(`:7`)、`commonError`(`:49`)、`commonNetworkError`="Network error — check your connection and try again."(`:50`,zh `:44`)、`paywallProductsErrorTitle`(`:52`)。**无 offline / connection 专用 key**(仅 `commonNetworkError`)。
- ui_kit **不依赖 l10n**(Message 组件只收已本地化字符串,`message_spec.dart:6-7`)——新 ui_kit 组件也必须只收字符串。

---

## 2. 范围分类表

| # | 候选改动 | 结论 | 理由 |
|---|---|---|---|
| 1 | "无网络"细分错误 | **现在做(复用类型加字段,不新增子类)** | 在 `NetworkFailure` 加 `NetworkFailureKind { offline, timeout, unknown }`(可空,默认 unknown),由 `ErrorHandler` 据 `DioExceptionType` 派生。不新增 sealed 子类,避免冲击全仓 `switch (failure)` 穷尽分支与 arch_guard。同时修 §0.3 缺口:`unknown`+`SocketException` → `NetworkFailure(offline)`。 |
| 2 | 可复用"网络重试" UI 组件 | **现在做** | ui_kit 新增 `StatusView`(全屏/页面级,纯字符串入参)+ 应用侧 `ErrorRetryView`(接 `Failure`→本地化→`StatusView`)。**全屏形态**=启动/整页无内容;**局部形态**=页面级数据加载失败。行内提示形态复用现有 Message 通道(见决策 B)。 |
| 3 | 启动失败重试界面改造 | **现在做(改为复用)** | `_StartupErrorView` 替换为 `ErrorRetryView(fullScreen:true)`;retry 仍 `start()`。消灭四处同构副本。 |
| 4 | 启动后业务场景失败呈现 | **现在做(分层)** | 主数据加载失败(AsyncValue.error,页面本无内容)→ `ErrorRetryView` 页面级;用户主动操作失败(已有页面内容,如购买)→ 现有 Message inline banner + 重试 action,**不打断页面**。见决策 B。 |
| 5 | 自动重试(指数退避) | **不在范围内(网络层已有)** | 传输层(`retry_interceptor`)+ IapVerifier 已对无网络/超时做有界退避自动重试(§1.4)。UI 再自动重试会叠加放大、真无网时空转耗电,违反红线 5(重试收敛在网络层)。UI 仅"手动原地重试"。 |
| 6 | 主动探测网络连通性 | **不在范围内(被动驱动)** | 引入 connectivity 依赖会扩大权限面与复杂度,且与现有 fail-passive 架构相悖。被动依赖请求失败回调。 |
| 7 | 多语言文案 | **现在做** | 新增 en+zh key(网络/离线标题与提示),走 `gen-l10n`。 |
| 8 | "网络恢复后自动重试" | **预留接口** | `StatusView` 暴露 `onAction`;若将来加 connectivity provider,可在恢复事件里复用同一 `onAction`,无需改组件。本轮不接线。 |
| 9 | maintenance 卡复用 StatusView | **预留(可选重构)** | `_MaintenancePage` 同构但语义非"错误"(带倒计时)。可后续复用 `StatusView` 布局;本轮不强制,避免牵动 governance 测试。 |

---

## 3. 设计决策表

### 决策 A — 失败判定边界

| 方案 | 说明 | 取舍 |
|---|---|---|
| **A1(选定)** 把"传输层不可达"整类统一呈现,文案中性化,但**补 `kind` 字段**供文案细分 | `connectionError`+三类 timeout+`unknown(SocketException)` 都归 `NetworkFailure`,默认文案"网络连接失败,请检查网络后重试";`kind=offline` 时可用更贴切的"似乎已离线"copy。 | 无主动探测时,offline 与 server-unreachable **本就无法可靠区分**(决策 6 已排除探测);对用户而言动作都是"查网→重试",中性文案不会误导;`kind` 让"想细分时能细分"而不强行断言。复杂度低,且修复了 `unknown→ServerFailure` 的错判。 |
| A2(拒绝)严格只对"真·无网络"展示专属界面,其余网络失败走通用错误 | 需要精确判定 offline。 | **拒绝**:当前类型体系无法精确判定(§0.1);要精确就得引入主动探测(已被决策 6 排除),且仍有竞态。会把"误报没网"的风险转嫁给用户感知,得不偿失。 |
| A3(拒绝)所有网络类失败(含 5xx)都纳入"无网络重试界面" | 把 `ServerFailure(5xx)` 也并入。 | **拒绝**:5xx 是服务端错误,文案"检查你的网络"会误导用户;且 5xx 走 `ServerFailure`(`error_handler.dart:91-94`),并入会破坏现有分类语义与红线 2。5xx 仍走通用错误+重试(同一 `ErrorRetryView`,只是标题文案不同)。 |

**选定 A1。** 用户感知:文案准确(不谎称"没网")。实现复杂度:仅加一个枚举字段 + 修一处错判,零新依赖。

### 决策 B — UI 呈现层级

| 方案 | 说明 | 对"进行中操作/页面状态"的影响 |
|---|---|---|
| **B1(选定)** 按场景分层:整页无内容→页面级/全屏 `ErrorRetryView`;已有页面内容的主动操作失败→复用 Message inline banner + 重试 action | 启动=全屏;profile/paywall 主数据 `AsyncValue.error`=页面级卡(页面本就空);购买等操作失败=底部横幅,不覆盖页面。 | **最优**:有内容的页面绝不被全屏覆盖,正在进行中的操作上下文得以保留;空白页给明确的整页重试入口。 |
| B2(拒绝)统一全屏覆盖所有网络失败 | 任何网络失败弹全屏。 | **拒绝**:会摧毁用户当前页面状态(如已填表单、滚动位置、进行中的购买回执),体验割裂,违背"原地重试"目标。 |
| B3(拒绝)全部复用现有 Message banner(不加任何全屏/页面级) | 一律底部横幅。 | **拒绝**:对"页面无任何内容可显示"的加载失败(启动、首屏列表),用户只见空白+底部小横幅,失焦;且启动期 `MessageHost` 尚未必就绪。 |

**选定 B1。** 复用 §1.2 的 Message 通道(零新机制)承接"操作类失败";新增 `ErrorRetryView` 承接"整页/页面级数据失败"。

### 决策 C — 状态管理

| 方案 | 说明 | 对现有范式侵入度 |
|---|---|---|
| **C1(选定)** 保持**无状态**:各调用方沿用现有 `AsyncValue.when` / sealed `StartupState` 捕获失败并条件渲染,不引入全局"无网络态" | `ErrorRetryView` 是纯展示;重试动作仍是各页已有的 `ref.invalidate(...)` / `start()`。 | **最低**:完全沿用手写 Riverpod 三态范式(`profile_page.dart:21`、`paywall_page.dart:46`、`StartupState`),零新 provider、零新框架,符合红线 4。 |
| C2(拒绝)新增全局 `NetworkStatusNotifier` 跟踪"当前是否无网络重试态" | 一个 `Notifier<bool/enum>`。 | **拒绝**:要让它有意义就得**主动探测**网络才能驱动"恢复"(否则无人置位/复位),与决策 6、红线 6 冲突;且与现有 invalidate-driven、fail-passive 模式重复,侵入大。 |
| C3(拒绝)每个调用方各自再写一份 offline 判定/渲染分支 | 分散实现。 | **拒绝**:正是现状四处 bespoke 的病根;违背红线(重试/呈现应收敛复用)。本方案要消除它。 |

**选定 C1。** 预留:若将来要全局离线横幅,新增一个独立 connectivity provider 即可,不改 `ErrorRetryView`(决策 8)。

---

## 4. 最终方案 — 受影响文件清单

> 约定:ui_kit 纯展示、只收字符串;Failure→文案映射在应用层;新增字段不新增 sealed 子类。

### 新增

**`packages/ui_kit/lib/src/status_view.dart`** — 可复用全屏/页面级状态组件(纯展示)
职责:统一"图标 + 标题 + 说明 + 主操作按钮"的状态面板,替换四处 bespoke 卡的视觉。用 `GlassCard`+`ObsButton`+`StudioTokens`,方向安全(`EdgeInsetsDirectional`/`AlignmentDirectional`),尊重 reduce-motion。
关键签名(仅签名,不含实现体):
```dart
class StatusView extends StatelessWidget {
  const StatusView({
    super.key,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.icon,
    this.accentColor,           // 默认 StudioTokens.errorColor;info 态可传 infoColor
    this.loading = false,       // 重试进行中:ObsButton(loading:true)
    this.expand = true,         // true=全屏居中;false=页面级内嵌
    this.padding,
  });
  final String title;
  final String? message;
  final String? actionLabel;    // 为空则不渲染按钮
  final VoidCallback? onAction;
  final IconData? icon;
  final Color? accentColor;
  final bool loading;
  final bool expand;
  final EdgeInsetsGeometry? padding;
}
```

**`packages/ui_kit/lib/ui_kit.dart`**(改导出,见下)— 追加 `export 'src/status_view.dart';`

**`lib/ui/common/error_retry_view.dart`** — 应用侧适配器(接 `Failure`→本地化→`StatusView`)
职责:把 sealed `Failure` 映射成本地化标题/说明(区分 `NetworkFailure(kind)` 与其它),供三个业务/启动面统一调用。复用现有 `messageForFailure`(`error_text.dart:8`)。
关键签名:
```dart
class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({
    super.key,
    required this.failure,
    required this.onRetry,
    this.fullScreen = true,     // → StatusView.expand
    this.retrying = false,
  });
  final Failure failure;
  final VoidCallback onRetry;
  final bool fullScreen;
  final bool retrying;
}

// 纯函数:Failure → (title, message, icon)。Network(offline) 用离线文案,
// Network(timeout/unknown) 用通用网络文案,其它沿用 messageForFailure。
({String title, String message, IconData icon}) describeFailure(
  AppLocalizations l10n, Failure failure);
```

### 修改

**`packages/infra_core/lib/src/error/failure.dart`**
- 新增 `enum NetworkFailureKind { offline, timeout, unknown }`。
- `NetworkFailure` 增可空字段 `final NetworkFailureKind? kind;`(向后兼容,默认 `null`/unknown)。不动其它变体,保持 sealed 穷尽不破。

**`packages/infra_core/lib/src/error/error_handler.dart`**
- `_fromDio`(`:77-96`):`connectionError` → `NetworkFailure(kind: offline)`;三类 timeout → `NetworkFailure(kind: timeout)`;`badCertificate` 维持 NetworkFailure(kind: unknown)。
- **修缺口**:`DioExceptionType.unknown` 分支(`:95-96`)先检查 `error.error is SocketException` → `NetworkFailure(kind: offline)`,否则维持 `ServerFailure`。`badResponse`/5xx 维持 `ServerFailure` 不变(决策 A3)。

**`lib/ui/startup/startup_gate.dart`**
- 删除私有 `_StartupErrorView`(`:125-149`);`StartupFailed` 分支(`:42`)改用 `ErrorRetryView(failure: failure, onRetry: _restart, fullScreen: true)`。`_restart`/`start()` 不变。

**`lib/ui/me/profile_page.dart`**
- 删除 `_ProfileError`(`:274-299`);`account.when` error 分支(`:23-26`)改用 `ErrorRetryView(failure: handle(error), onRetry: () => ref.invalidate(currentAccountProvider), fullScreen: false)`。钱包 `'—'` 兜底(`:138`)不动。

**`lib/ui/paywall/paywall_page.dart`**
- 删除 `_ProductsError`(`:398-422`);`products.when` error 分支(`:48-50`)改用 `ErrorRetryView(failure: handle(error), onRetry: () => ref.invalidate(appInitProvider), fullScreen: false)`。`_FeatureUnavailable`/`_BillingRetryBanner`/购买失败 message 通道不动。

**`lib/ui/common/messages.dart`**(可选增强,低风险)
- `failureMessage`(`:21`):`NetworkFailure` 分支按 `kind` 细化——`offline → l10n.commonOfflineError`,否则 `commonNetworkError`。重试 action 接法不变。

**`lib/l10n/arb/app_en.arb` + `app_zh.arb`** → 新增 key,随后 `flutter gen-l10n`:
- `networkErrorTitle`(en: "Connection problem" / zh: "网络连接异常")
- `commonOfflineError`(en: "You appear to be offline. Check your connection and try again." / zh: "似乎已离线,请检查网络后重试。")
- (复用现有 `commonRetry`、`commonNetworkError`、`startupErrorTitle`、`paywallProductsErrorTitle`;后两者作为对应面的标题继续使用。)

**(预留,本轮不改)** `lib/ui/governance/maintenance_gate.dart` `_MaintenancePage`:后续可复用 `StatusView(expand:true, accentColor: infoColor)` 承载倒计时布局(决策 9)。

---

## 5. 红线自查表

| # | 红线 | 合规说明 |
|---|---|---|
| 1 | 不新增第二套主题/视觉 | ✅ `StatusView` 仅用 `GlassCard`/`ObsButton`/`StudioTokens`(errorColor/infoColor/spacing/radii),无新视觉系统。 |
| 2 | 不绕过统一错误链路另起分支 | ✅ 仍 `throwable → ErrorHandler.handle → Failure`;只在 `NetworkFailure` 加可空字段、修一处 `unknown` 错判,**未新增并行错误分支**;5xx 仍 `ServerFailure`。 |
| 3 | 文案走 l10n,禁硬编码 | ✅ 新 key 入双 ARB→`gen-l10n`;ui_kit `StatusView` 只收字符串(不引 l10n),本地化在应用层 `ErrorRetryView`/`messages.dart` 完成。 |
| 4 | 遵循现有状态管理范式 | ✅ 保持 `AsyncValue.when` / sealed `StartupState`(决策 C1),零新 provider、零新框架。 |
| 5 | 重试策略收敛在网络层 | ✅ 不在业务层加自动重试;自动有界退避仍只在 `RetryInterceptor`/`IapVerifier`;UI 仅手动 `invalidate`/`start()`。 |
| 6 | 排除系统权限请求 | ✅ 无 connectivity 主动探测、无权限弹窗、无跳转「设置」;全程被动依赖请求失败回调。 |
| 附 | arch_guard / 分层 | ✅ ui_kit 无 providers/l10n;无反向依赖;`no_hardcoded_directional`(`StatusView` 用 `*Directional`)。 |

---

## 6. 测试计划

**infra_core 单测**(`packages/infra_core/test/error/error_handler_test.dart` 扩展):
- `connectionError → NetworkFailure(kind: offline)`;三类 timeout → `NetworkFailure(kind: timeout)`;`badCertificate → NetworkFailure(kind: unknown)`。
- **缺口回归**:`DioException(type: unknown, error: SocketException) → NetworkFailure(kind: offline)`;`unknown` 无 SocketException → `ServerFailure`(不变)。
- `badResponse` 5xx → `ServerFailure(code: status)`(不变,锁住决策 A3)。
- `RetryInterceptor`/`IapVerifier` 既有测试**不应改动**(未触网络层重试)。

**ui_kit widget 测**(新增 `packages/ui_kit/test/status_view_test.dart`):
- 渲染 title/message/icon;`actionLabel` 为空→无按钮;点击触发 `onAction`;`loading:true`→`ObsButton` spinner、按钮禁用;`expand:false` 内嵌布局。

**应用 widget 测**(`pumpApp()`,单帧 `pump`,`Override` from `package:riverpod/misc.dart`):
- 启动:`StartupFailed(NetworkFailure)` → 显示 `ErrorRetryView`;点重试 → 再次调用 `start()`(用 spy/fake notifier 断言)。
- profile:`currentAccountProvider` 抛错 → `ErrorRetryView`;点重试 → `currentAccountProvider` 被 invalidate(重新进入 loading)。
- paywall:`appInitProvider`/`storeProductsProvider` 抛错 → `ErrorRetryView`;点重试 → `appInitProvider` 被 invalidate。
- 操作类失败不打断:购买失败仍走 message banner(回归 `paywall_page.dart:72-76` 路径,页面内容保留)。

**Golden(DF⑤/⑥,reduce-motion)**:为网络错误态新增 `StatusView` 的 **ltr + rtl** 快照(`test/goldens/`,`pumpApp(textDirection:)` 强制 rtl),保证方向安全与视觉回归。

**门禁**:`flutter analyze`(Gate1)、`flutter test`(2a)、`melos exec flutter test`(2b)、`dart run arch_guard`(Gate6,验证 ui_kit 无 l10n/provider、无反向依赖)。

---

## 7. 复核约定(实现后)

实现完成后独立复核,按 P0(功能/正确性,如缺口修复未生效、重试不触发)、P1(复用未落地/仍有 bespoke 残留、文案硬编码)、P2(视觉/文案细节)分级记录;**跳过项不得记为通过**,逐条对照本文件 §4 文件清单与 §5/§6 核验。
