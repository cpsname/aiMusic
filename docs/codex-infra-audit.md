# 基础设施完成度体验审计

审计日期：2026-08-27  
审计基线：当前工作区源码（不是 README 所描述的目标状态）  
审计视角：复制仓库后的新产品首日接入者

本文只把可执行实现算作能力：入口、Provider 绑定、仓储实现、状态流转、原生工程配置和测试代码均已核对；README、注释和 API 文档只用于定位，不作为“已经实现”的证据。`make analyze`、`make arch`、`make test` 均通过，但它们只说明现有门禁可运行，不替代下面的业务链审计。

状态口径固定为：

- ✅ 开箱即用：该维度列出的基础能力已经形成可调用闭环，新产品不需要再编写同类基础设施。
- ⚠️ 有骨架需补全：已有可复用主链，但仍缺上线必需的公共能力，或主链存在需要修复的确定性缺陷。
- ❌ 缺失：仓内没有可调用实现，只有相邻能力、错误码或文档。

结论先行：这个仓库已经是一个有商业化客户端内核的 Flutter 起点，但还不是“复制后只写 PRD 核心业务即可上线”的产品模板。当前可直接复用的是工程分层、Riverpod 组合根、签名网络、游客鉴权、基础商品/下单/验单/恢复链、远程治理、上传和 UI 原语；仍需补齐的是付费最终一致性、多 Offer/换档、账号与权益切换、路由和启动扩展、生产观测、合规发布链、CI/CD，以及全部 AI 接入层。

文中标注“推断”的结论，均同时写明了源码依据；没有把仓外服务或平台行为当作已实现事实。

## 1. 完成度总表

| 维度 | 状态 | 判定与证据路径 |
| --- | --- | --- |
| 工程骨架 | ✅ 开箱即用 | 根 `pubspec.yaml` 声明 app + 6 个 workspace package；`packages/infra_core`、`commerce_kit`、`app_config`、`media_kit` 均采用 domain/data/application 或明确的基础设施边界；`packages/infra_core/lib/src/providers.dart`、`packages/commerce_kit/lib/src/iap/application/iap_providers.dart`、`packages/app_config/lib/src/application/app_config_providers.dart`、`packages/media_kit/lib/src/application/upload_providers.dart` 是 Riverpod 组合根；`packages/infra_core/lib/src/config/env_config.dart::EnvConfig.fromEnvironment` 支持 dev/staging/prod；`packages/arch_guard/lib/arch_guard.dart::scanDirectories/analyzeSource` 执行反向依赖、领域纯度和 RTL 规则。新产品需要填配置和改产品身份，但不需要重写分层、DI 或环境机制。 |
| 应用外壳 | ⚠️ 有骨架需补全 | `lib/main.dart::main` 完成 bootstrap + ProviderScope；`lib/ui/app.dart::StudioApp.build` 提供 MaterialApp、主题、多语言、启动/强更/维护门；`packages/ui_kit/lib/src/theme.dart::AuraTheme` 同时有 light/dark；`lib/l10n/arb/app_en.arb`、`app_zh.arb` 有双语资源。缺口是 `StudioApp` 只有 `home`，`lib/ui/shell/studio_shell.dart::_StudioShellState` 用本地 `_index + IndexedStack` 硬编码两个页面，仓内没有路由表、深链、导航恢复、Locale/ThemeMode 持久化；`StartupController` 也没有新产品启动任务扩展点。 |
| 数据层 | ⚠️ 有骨架需补全 | `packages/infra_core/lib/src/network/dio_factory.dart::DioFactory` 组装设备头、Bearer、HMAC、时钟校准、重试、Envelope、防泄漏 breadcrumb；各业务包有 DTO→Domain 防腐层，例如 `commerce_kit/.../account_dtos.dart`、`iap_dtos.dart`、`media_kit/.../upload_dtos.dart`；`KeyValueStore`、`SecureTokenStore`、`StorageMigrator`、`AppInitCache`、`ProductCache` 和 `ErrorHandler` 均有实现。不能判 ✅：`RetryInterceptor._isRetryable` 不区分 HTTP 方法，会自动重放下单、登录、上传 finalize 等 POST；缓存只有业务特例，没有通用版本化缓存/离线队列，且 `/app/init` 新鲜度存在确定性问题。 |
| IAP | ⚠️ 有骨架需补全 | `iap_providers.dart::storeCatalogQueryProvider` 完成后端目录与商店详情合并；`IapPurchaseOrchestrator.purchase/restorePurchases`、`IapVerifier.verify`、`IapBackgroundReconciler` 构成创建订单→原生购买→服务端验单→finish→权益刷新及恢复/补单主链；`SubscriptionEntitlement` 有 active/trial/grace/billing-retry/expired/revoked 映射；`lib/ui/paywall/paywall_page.dart::PaywallPage` 是可用 Paywall。不能判 ✅：验单失败时后台仍可能 finish 并删除订阅/非消耗型 pending；商店错误和购买启动 `false` 被吞；pending 只按 productId 关联；多 Offer、优惠签名、资格判断、升级/降级没有购买实现，且 UI 会展示无法确定买到的 Offer。 |
| 用户体系 | ⚠️ 有骨架需补全 | `DeviceInfoService.load` 生成并安全存储设备 UUID；`AuthController.ensureAuthenticated/login/refresh/logout`、`AuthInterceptor`、`currentAccountProvider` 提供游客、密码登录、刷新及 `/auth/me`；`walletSnapshotProvider`、`hasFeatureProvider` 打通服务端钱包/权益到 UI。不能判 ✅：logout 最终停在 `AuthIdle` 且不会立即重建游客会话；钱包没有按账号身份失效；登录请求不携带游客会话，仓内无游客资产合并；权益到期没有前台定时失效；注册、找回密码、账号删除均缺失。 |
| 增长与运营 | ⚠️ 有骨架需补全 | `AppConfigController.refresh` + `AppConfig` 实现维护、kill switch、远程参数和前台刷新；`MaintenanceGate` 和 Paywall 的 `iap_purchase`/`promo_text` 已实际消费；IAP/维护有 `TelemetrySink.logEvent` 埋点。不能判 ✅：`lib/main.dart` 在 release 绑定 `NoopTelemetrySink`，事件不会上报；没有实验分流/曝光模型、评分引导、APNs/FCM 推送或 token 注册链。 |
| 稳定性 | ⚠️ 有骨架需补全 | `packages/infra_core/lib/src/observability/bootstrap.dart::bootstrap` 捕获 Zone、Flutter、PlatformDispatcher 错误；`ErrorHandler` 有统一 Failure；`LoggingInterceptor` 产出请求 breadcrumb；`TelemetrySink` 提供厂商无关边界。不能判 ✅：生产 sink 是 Noop；`RedactingTelemetrySink.recordError` 仍转发原始 error/stack；开发日志输出登录/刷新请求体；IAP stream 没有 onError，后台 `unawaited(_reconcile)` 的异常无收口；没有性能指标、告警或持久化日志。 |
| 合规 | ⚠️ 有骨架需补全 | `ios/Runner/PrivacyInfo.xcprivacy` 已声明 Required Reason API；Paywall 有恢复购买及后端下发的 Terms/Privacy/Subscription Terms 链接；`external_links.dart::manageSubscriptionsUrl` 能打开系统订阅管理。不能判 ✅：隐私清单声明“不收集数据”，但 `DeviceHeadersInterceptor` 实际向后端发送稳定设备 ID、机型、系统与语言，账号/IAP 还发送账号及交易数据；没有 ATT/权限协调层；法律链接可为空并直接隐藏；缺少稳定可见的订阅管理、自动续订/取消说明和应用内账号删除。 |
| 工程效率 | ⚠️ 有骨架需补全 | `Makefile`、`melos.yaml`、`scripts/check_config.sh`、`scripts/verify_xcode_config.sh` 提供 analyze/arch/test/config/build 门禁；测试覆盖网络、鉴权、IAP、配置、上传、Widget、golden 和 RTL。不能判 ✅：版本库没有 CI workflow、自动签名/发版/版本策略或覆盖率阈值；`android/app/build.gradle.kts` 的 release 使用 debug key；release 主 Manifest 没有 INTERNET 权限；iOS team 为空且 bundle ID 硬编码；三个产品身份来源彼此不一致。 |
| AI 能力接入层 | ❌ 缺失 | 根 `pubspec.yaml::workspace/dependencies` 和所有 `packages/*/pubspec.yaml` 没有模型 SDK或 `ai_kit`；仓内没有 ModelRouter、Provider Adapter、TokenUsage、fallback/circuit-breaker 等领域接口。`packages/media_kit/lib/media_kit.dart` 只解决文件上传，`infra_core` 的内容过滤错误类型也只是错误映射，不能算模型接入层。 |

聚合结果：1 项 ✅、8 项 ⚠️、1 项 ❌。

## 2. 开箱即用清单

这里的“开箱即用”指客户端实现可直接调用；外部前提仍是配置一套与这些接口匹配的共享后端，并在 App Store Connect / Play Console 建好对应商品。若没有该后端，见缺口 G06。

### 2.1 环境、DI 与启动门

填好 `config/<env>.json` 后，现有 `StudioApp` 会依次完成本地配置校验、设备/存储加载、游客或历史会话恢复、`/app/init`、强更、账户/钱包预热以及 IAP reconciler 启动。新业务读取配置不需要自建全局单例：

```dart
final env = ref.read(envConfigProvider);
final isProduction = env.isProd;
```

证据：`lib/main.dart::main`、`lib/ui/startup/startup_gate.dart::StartupGate`、`packages/commerce_kit/lib/src/iap/application/startup_controller.dart::start`、`packages/infra_core/lib/src/providers.dart`。

### 2.2 带鉴权、签名和 Envelope 解包的网络调用

启动完成后，业务只需要发请求；设备头、Bearer 刷新、HMAC、时钟偏差、成功 Envelope 解包和错误类型化由拦截器完成。当前建议只把自动重试链直接用于 GET/幂等请求，POST 安全性见 G12。

```dart
final dio = ref.read(apiDioProvider);
final response = await dio.get<dynamic>('/my-feature');
final data = response.data; // 已是 envelope.data
```

证据：`packages/infra_core/lib/src/network/dio_factory.dart::createApiDio`、`interceptors/auth_interceptor.dart`、`signature_interceptor.dart`、`envelope_interceptor.dart`。

### 2.3 游客会话、密码登录和当前账户

冷启动会自动走“有效 token → refresh → guest-register”。业务可直接读取当前账户；密码登录也有可调用 Controller 和现成登录 Sheet。

```dart
await ref.read(authControllerProvider.notifier).ensureAuthenticated();
final account = await ref.read(currentAccountProvider.future);
```

证据：`packages/commerce_kit/lib/src/auth/application/auth_controller.dart::ensureAuthenticated/login`、`auth_providers.dart::currentAccountProvider`、`lib/ui/me/login_sheet.dart::_submit`。

### 2.4 服务端权益门

新产品可以直接用钱包 feature code 控制功能，不必从本地交易推导订阅态：

```dart
final canExportHD = ref.watch(hasFeatureProvider('export_hd'));
if (!canExportHD) return const PaywallPage();
```

证据：`packages/commerce_kit/lib/src/wallet/application/wallet_providers.dart::hasFeatureProvider`、`packages/commerce_kit/lib/src/iap/application/iap_providers.dart::subscriptionEntitlementProvider`。

### 2.5 基础 IAP 与 Paywall

在“单个默认 Offer、暂不做订阅换档”的范围内，动态商品、下单、商店购买、服务端 verify、finish、恢复购买和 UI 反馈可直接使用：

```dart
final products = await ref.read(storeProductsProvider.future);
await ref
    .read(iapPurchaseOrchestratorProvider.notifier)
    .purchase(products.first);

await ref
    .read(iapPurchaseOrchestratorProvider.notifier)
    .restorePurchases();
```

也可以直接把 `const PaywallPage()` 放进产品导航。证据：`packages/commerce_kit/lib/src/iap/application/iap_purchase_orchestrator.dart`、`iap_verifier.dart`、`iap_background_reconciler.dart`、`lib/ui/paywall/paywall_page.dart`。

### 2.6 维护、Kill Switch 与远程参数

远程治理已经被真实 UI 消费，不是空接口：

```dart
final disabled = ref.watch(isFeatureKilledProvider('image_generation'));
final promo = ref
    .watch(appConfigProvider)
    .configValue<String>('promo_text', '');
```

证据：`packages/app_config/lib/src/application/app_config_controller.dart::refresh`、`app_config_providers.dart`、`lib/ui/governance/maintenance_gate.dart`、`lib/ui/paywall/paywall_page.dart::_PaywallList`。

### 2.7 文件直传

上传服务已封装 SHA-256、策略预检、签名、R2 PUT、去重、finalize、进度和取消：

```dart
final asset = await ref.read(uploadServiceProvider).upload(
  UploadInput(
    bytes: bytes,
    filename: 'input.png',
    mimeType: 'image/png',
    contentKind: UploadContentKind.image,
  ),
);
```

证据：`packages/media_kit/lib/src/application/upload_service.dart::upload`、`upload_providers.dart`、`data/upload_repository_impl.dart`。

### 2.8 错误与 UI 原语

业务异常可以统一转成 Failure；主题、按钮、骨架、状态页和全局消息栈也可直接复用：

```dart
try {
  await useCase();
} catch (error, stack) {
  final failure = ref.read(errorHandlerProvider).handle(error, stack);
  ref.read(messageControllerProvider).show(failureMessage(l10n, failure));
}
```

证据：`packages/infra_core/lib/src/error/error_handler.dart::handle`、`lib/ui/common/messages.dart`、`packages/ui_kit/lib/ui_kit.dart`。

## 3. 缺口清单

估时按一名熟悉 Flutter/IAP 的工程师计算，包含实现和针对性测试，不含商店审核等待时间；“客户端 + 服务端”分别计人日。每行的交付定义可直接建开发任务。

| ID | 可直接建单的缺口与完成标准 | 当前替代做法 | 成本估计 | 证据路径 |
| --- | --- | --- | --- | --- |
| G01 | **收紧 IAP 最终一致性。** 将服务端 `isSuccessful` 或新增的“可安全 acknowledge”结果设为 finish/remove 的唯一门槛；验单 timeout、`grant_failed`、原生 finish、pending save/remove 任一失败都必须进入可观测失败态并保留可重试记录；purchase stream 增加 `onError`，每个后台 reconcile future 都捕获并上报；补齐失败矩阵测试。 | 目前依赖 S2S/RTDN、商店 restore 和下一次前台刷新兜底。**推断依据：**仓内没有 S2S/RTDN 服务实现，客户端无法证明 webhook 已授予权益。 | 客户端 4–7 人日；若需新增交易查询接口，服务端 3–5 人日 | `IapBackgroundReconciler._reconcileLocked` 在 `granted || _mayFinishWithoutGrant` 时 finish/remove，且无本地订单的事件直接 finish；`IapPurchaseOrchestrator._verifyAndComplete` 的 complete/remove 在 try 外；`IapBackgroundReconciler.start/_onEvents` 无 onError/异步错误收口；`test/iap/reconciler_test.dart` 明确固化了“verify throws 仍 finish subscription”。 |
| G02 | **补全商店可用性和错误语义。** 商品查询前调用 `isAvailable`；`ProductDetailsResponse.error` 转成 `StoreUnavailableException` 并触发缓存 fallback；原生 `buy*` 返回 `false` 时立即失败而不是按静默取消处理；Paywall 区分“商店不可用、商品未配置、真正空目录”；增加三类测试。 | 用户看到空商品或“已取消”，再手工重试；旧 ProductCache 只在抛异常时才会命中。 | 1–2 人日 | `domain/store_client.dart::isAvailable` 只有声明；`store_client_impl.dart::queryProducts` 只 debugPrint `response.error`；`buy` await 后丢弃 bool；`iap_providers.dart::storeCatalogQueryProvider` 只在 catch 中读缓存。 |
| G03 | **建立交易级关联并禁止重复 pending。** PendingOrder 增加 transactionId/状态；同一 storeProductId 有未决订单时先恢复或明确取消，不再创建第二单；claim/reconcile 以 transactionId 为主键；校验 create-order 返回的 productCode/storeProductId 与用户选择完全一致；为“静默取消后立刻重试、旧事件迟到、同批同商品交易”写测试。 | UI 只防止一个正在进行的调用；静默取消后允许再次购买，遗留订单靠 24 小时清理。 | 3–5 人日 | `IapPurchaseOrchestrator.purchase` 静默取消保留 pending，而终态不再阻止下一次 purchase；`IapBackgroundReconciler._claims/_reconciling` 以 productId 为键；`PendingOrderStore.findByStoreProductId` 返回第一条；create-order 后没有 ID 一致性检查。**推断：**上述组合允许同商品多 pending 和迟到事件错配。 |
| G04 | **完成 Offer、试用资格和订阅换档。** 新增 `PurchaseOfferSelection`；Play 保存 basePlan/offerToken 对应的原始 ProductDetails 并显式传 `GooglePlayPurchaseParam`，iOS 接入 promotional-offer 签名并传 AppStore 参数；只展示确认可购买且用户有资格的 Offer；价格周期取商店 `subscriptionPeriod`；支持 upgrade/downgrade/replacement mode；修正 Android nonRecurring 一律被当 free trial 的映射。完成前设置目录闸门：只允许一个默认订阅计划并隐藏 promo/后端 trial。 | 安全替代是只售一个默认 base plan，不配置/不展示促销、不允许订阅换档。 | 客户端 8–13 人日；优惠签名/资格接口服务端 3–5 人日 | `StoreClient.buy` 没有 offer 参数；`store_client_impl.dart::_productCache` 以 product id 覆盖；`ProductMergeService.merge` 也按 id 收敛；`ProductDetailExtractor._mapAndroidPhase` 把 nonRecurring 映射为 freeTrial；`PaywallPage._offerLabels` 展示所有 promo，而 `_ProductTile` 购买时不传选择；周期来自 `product.billingCycle`；`purchase` 对任意已有订阅直接 `IapAlreadySubscribed`。`commerce_kit/pubspec.yaml` 固定的 Play 插件会为同一订阅返回逐 Offer 的 ProductDetails，故“最后一个 id 覆盖”是可复现推断。 |
| G05 | **让 `/app/init` 可刷新。** 给 AppInitCache 增加 TTL + stale-while-revalidate；提供 `forceRefresh` 真正绕过缓存；强更使用短 TTL；商品/法律信息刷新成功后更新缓存；接入 ProductCache 的 currency mismatch 清理；Paywall retry 同时重查 app-init 和 store。 | 发布新版本、等待设备重启；紧急停售只能依赖独立 `app_config` 的 IAP kill switch。 | 2–3 人日 | `AppInitCache.read` 只按 boot instant + appVersion 判命中，没有 TTL；`appInitProvider` 命中后不请求网络；Paywall retry 仅 invalidate provider，仍会再次读同一缓存；`ProductCache.isCurrencyMismatch` 没有生产调用点。 |
| G06 | **建立可执行的共享后端接入合同。** CI 中启动或连接测试环境，依次验证 app/config、app/init、guest-register、refresh、me、wallet、create-order、verify、恢复交易及 Apple S2S/Play RTDN 的授权结果；生成隔离的测试 distribution/product；把合同测试作为模板发布门。若组织没有现成共享服务，需要交付对应 auth/catalog/order/receipt/webhook/wallet 服务。 | 手工填写 BASE_URL/secret 并相信外部服务与客户端 DTO 一致；复制仓库本身无法独立工作。 | 接入既有服务 2–4 人日；从零实现服务端 25–40 人日 | 仓内只有客户端仓储：`AuthRepositoryImpl`、`AccountRepositoryImpl`、`WalletRepositoryImpl`、`IapRepositoryImpl`、`AppConfigRepositoryImpl`、`UploadRepositoryImpl`；版本库没有服务端入口或 webhook/receipt validator。 |
| G07 | **修复账号切换的状态隔离。** logout/logoutAll 清 token 后立即 guest-register，或导航到明确的未登录门；`currentAccountProvider` 只在 AuthAuthenticated 后请求；`walletSnapshotProvider` watch 当前 userId 并在 login/logout/refresh identity change 时失效；同步 `TelemetrySink.setUser`；增加 guest→login→logout 的账户、余额、feature、IAP token 测试。 | 注销后要求重启 App；登录后由页面手工 invalidate 钱包。现代码没有执行这个手工步骤。 | 2–3 人日 | `AuthController.forceLogout` 最终为 `AuthIdle`；只有 `StartupController.start` 调用 `ensureAuthenticated`；`currentAccountProvider` watch auth 后无条件请求 `/me`；`walletSnapshotProvider` 不 watch auth；生产代码没有 `setUser` 调用。 |
| G08 | **补齐游客升级和账号生命周期。** 登录/注册明确携带当前 guest credential，服务端原子合并余额、feature、IAP 归属并返回迁移结果；增加注册、找回密码、应用内删除账号（确认、服务端删除/匿名化、清本地、回到新 guest）流程；删除和迁移写端到端测试。 | 维持纯游客产品，或让客服在仓外处理账号创建、资产迁移和删除。已有登录只是会话替换。 | 客户端 5–8 人日；服务端 6–12 人日 | `AuthRepositoryImpl.login` body 只有 username/password 且使用 no-auth Dio；`AuthController.login` 直接覆盖 session；`AuthRepository` 只有 guest/login/refresh/logout/logoutAll；`ProfilePage` 只有登录/退出入口，没有注册、找回、删除。 |
| G09 | **统一并定时失效权益快照。** 建立按 userId 缓存的 `EntitlementSnapshot`，合并 `/me` subscription 与 `/wallet` features；在最早 expiresAt/currentPeriodEnd 安排 Timer 失效并后台刷新；前台恢复、账号切换、IAP 成功均走同一刷新入口；grace 状态在 Profile 与 feature gate 语义一致。 | 依赖 App resume、IAP 成功或下一次网络业务请求刷新；关键服务端接口继续自行鉴权。 | 2–4 人日 | `activeWalletFeaturesProvider` 只在 provider build 时调用一次 `DateTime.now`，没有 timer；`SubscriptionEntitlement.isEntitled` 包含 grace，但 `Subscription.isActive` 只包含 active/trialing，Profile 使用后者；`/me` 和 `/wallet` 各有一套 wallet/features 数据。 |
| G10 | **提供可扩展路由和启动任务注册表。** 使用 `MaterialApp.router` 建基础 RouteGraph，含 startup/maintenance/auth redirect、shell、profile、paywall、深链和状态恢复；暴露 `productRoutesProvider`；把 StartupController 的固定流程拆成 `StartupTask` 列表，支持 critical/non-critical、超时、失败展示和产品任务注入。 | 每个新产品直接改 `StudioShell`、`StudioApp.home` 和 `StartupController.start`。 | 4–7 人日 | `StudioApp` 只有 `home`；仓内无 `routes/onGenerateRoute/RouterConfig`；`StudioShell` 硬编码两个页面；`StartupController.start` 直接写死 device/storage/app-init/auth/account/wallet/IAP。 |
| G11 | **补齐 Locale/ThemeMode 控制器。** 增加持久化 provider，MaterialApp 绑定 locale/themeMode/darkTheme；系统跟随、中文、英文、浅色、深色均可切换；`languageTagProvider` 必须与选中 locale 同源；添加重启恢复测试。 | 固定 Aura dark，语言跟随平台首选 locale。 | 1–2 人日 | `StudioApp` 只设置 `theme: AuraTheme.dark`，没有 themeMode/darkTheme/locale；`languageTagProvider` 默认直接读 PlatformDispatcher；`AuraTheme.light` 存在但没有生产调用点。 |
| G12 | **让重试具备幂等语义。** 默认只重试 GET/HEAD/OPTIONS；写请求必须显式 `replaySafe=true` 且携带稳定 Idempotency-Key；create-order、upload sign/finalize 与登录策略逐一声明；刷新 replay 不重复消费 body；增加 POST 503/timeout 测试，证明无 key 不重放、有 key 最多产生一个业务结果。 | 依赖服务端碰巧幂等，并接受网络超时后重复创建订单/资产的风险。 | 客户端 2–4 人日；服务端补幂等键 2–4 人日 | `RetryInterceptor._isRetryable` 只看异常类型/状态码，不检查 method 或 extra；它安装在 authDio/apiDio 上；`IapRepositoryImpl.createOrder`、`AuthRepositoryImpl.login/guestRegister`、`UploadRepositoryImpl.sign/finalize` 均是 POST 且无 Idempotency-Key。 |
| G13 | **替换可提取的移动端共享 HMAC。** 明确 `DISTRIBUTION_SECRET` 只作低可信渠道标记；接入 App Attest/DeviceCheck 和 Play Integrity，服务端验证 attestation 并签发短期安装凭证；高价值接口再使用安装级密钥/nonce；加入伪造客户端和重放测试。 | 继续使用包内 HMAC，配合后端限流、风控和商店收据校验；不能把它当客户端身份安全边界。 | 客户端 4–6 人日；服务端 4–7 人日 | `EnvConfig.fromEnvironment` 把 DISTRIBUTION_SECRET 编译进二进制；`SignatureInterceptor` 每次用同一 secret 做 HMAC。源码实现无法保证 secret 对终端用户保密。 |
| G14 | **落地生产可观测性并修复脱敏。** 实现一个生产 TelemetrySink adapter（建议先交付 Sentry 适配），按 env 配 DSN/release；auth 切换调用 setUser；`recordError` 对 error message/stack 做发送前脱敏；HTTP verbose logger 对 password、refresh_token、文件 URL 等字段递归遮罩；IAP stage/order requestId 做结构化 tag；添加 release-mode 冒烟和脱敏测试。 | debug/staging 看 console；release 只能靠用户反馈和服务端日志。 | 3–5 人日 | `lib/main.dart` release 绑定 `NoopTelemetrySink`；`RedactingTelemetrySink.recordError` 原样传 error/stack，只处理 context；`LoggingInterceptor._body` 输出完整请求体，header 仅遮 Authorization；登录/刷新 body 位于 `AuthRepositoryImpl`。 |
| G15 | **建立类型化埋点与实验层。** 定义事件/属性 schema、版本、页面与购买漏斗；新增稳定设备/账号实验分桶、variant provider、曝光去重和 consent gate；把现有字符串 `logEvent` 迁移并在 CI 校验未知事件/属性。 | 使用 `AppConfig.config` 任意 key/value 和散落字符串事件；release 当前实际不上报。 | 3–5 人日 | `TelemetrySink.logEvent(String, Map)` 无 schema；`AppConfig.configValue` 是任意 Map；已消费的类型化 feature code 只有 `AppFeatureCodes.iapPurchase`。 |
| G16 | **补评分引导与推送公共包。** 评分服务按成功次数、冷却期、版本和“无进行中交易”触发 `in_app_review`；通知服务完成 APNs/FCM 权限、token 刷新/注销、账号绑定、前后台消息、深链路由和埋点；服务端增加 token/发送接口。 | 评分靠商店自然入口；运营触达只能站外进行。 | 评分 1–2 人日；推送客户端 5–8 人日、服务端 3–5 人日 | 根及各 package pubspec 没有 review、Firebase Messaging/APNs 依赖；仓内无 notification permission/token/provider；IAP 字段 `push_token` 实际传的是账号 BID，不是通知 token。 |
| G17 | **修正隐私清单并建立权限/ATT 协调层。** 按实际数据流声明 Device ID、产品交互、购买、账号/contact info 等用途与关联性；维护 iOS PrivacyInfo、Info.plist purpose strings 和 Android Data Safety 映射；新增 PrivacyConsentCoordinator，任何 tracking adapter 在 ATT/同意前不得启用；相机/相册/麦克风/通知采用场景内申请；CI 校验依赖变化后清单未更新则失败。 | 当前没有广告/跟踪 SDK，可保持“不请求 ATT”，但只能人工在每次新增 SDK/权限时审查。现有空 collected-data 声明不能继续沿用。 | 客户端 3–5 人日 + 法务/运营确认 | `PrivacyInfo.xcprivacy` 的 `NSPrivacyCollectedDataTypes` 为空；`DeviceHeadersInterceptor.onRequest` 发送稳定设备 ID/机型/系统等；`AuthRepositoryImpl`、`IapRepositoryImpl` 处理账号和交易；Info.plist 无 ATT/媒体 purpose string；pubspec 无权限协调依赖。 |
| G18 | **把 Paywall 合规项设为 fail-closed。** subscription 商品出现前必须校验 Terms + Privacy URL 非空可解析；展示商店真实名称、价格、周期、试用后价格、自动续订及取消说明；Restore 和 Manage Subscription 始终可见，billing-retry banner 提供管理动作；Profile 增加管理与删除账号入口；缺法律配置时隐藏订阅并上报配置错误。 | 人工保证 `/app/init` 永远下发三条链接；用户需先尝试重复购买才会看到 Manage。 | 3–5 人日；账号删除服务端计入 G08 | `PaywallPage._LegalLinks` 对 null/空链接直接隐藏；`_cycleLabel` 使用后端 billingCycle；Manage 只在 `IapAlreadySubscribed` 消息 action 中；billing banner 无 action；ARB 无自动续订/取消正文；Profile 无 manage/delete。 |
| G19 | **交付可发布的原生产品身份和签名。** 先把 INTERNET 移到 Android main Manifest；release signing 从 CI secret/keystore.properties 注入且禁止 debug key；用一个 `product.yaml` 生成 Android namespace/applicationId/label、iOS bundle/display name/team 配置和三个 env 样例；构建门比较 `EnvConfig.bundleId` 与真实 native ID；提供 App Store/Play 两条签名产物 smoke test。 | 手工改 Gradle/Xcode/Info.plist/config 并本地签名。Android 当前只有 debug/profile 有网络权限，release 没有可用替代。 | 3–5 人日（其中 INTERNET 修复与测试约 0.5 人日） | `android/app/src/main/AndroidManifest.xml` 无 INTERNET，而 debug/profile Manifest 有；`android/app/build.gradle.kts` release 指向 debug signing，ID 为 `com.example.iap_template`；iOS project 的 team 为空、ID 为 `org.vizgo.ai`；`config/dev.example.json` 又是 `com.example.studio`；代码未比较这些值。 |
| G20 | **补 CI/CD、版本和覆盖率发布门。** 新增 GitHub Actions：pub get→analyze→arch→test/golden→coverage threshold→Android release manifest/signing dry-run→iOS config/archive dry-run；用 tag 生成 pubspec version/build number/changelog；Fastlane 上传 TestFlight/Internal Testing；核心包设置行/分支阈值；增加 StoreKit config、Play license tester 的端到端购买/恢复/中断补单测试。 | 开发者本机执行 `make gates`，手改 `1.0.0+1`，手工上传商店；IAP 只跑 fake 单测。 | 5–8 人日，商店凭证准备另计 | 版本库无 `.github/workflows`、`.gitlab-ci.yml`、`codemagic.yaml` 或 fastlane；`pubspec.yaml` 版本固定；Makefile 无 coverage/release/upload；RunnerTests 只有空示例；现有 IAP 测试使用 `FakeStoreClient`。 |
| G21 | **提供通用版本化缓存与离线策略。** 抽出 `JsonCache<T>`（schema version、TTL、SWR、按账号 namespace、corruption telemetry、clear-on-logout），再提供 connectivity 状态；只给显式幂等业务提供离线队列。迁移 AppInit/ProductCache/PendingOrder 的共性逻辑并写升级测试。 | 新产品继续在 SharedPreferences 上为每个功能手写 JSON、TTL 和迁移；完全在线使用。 | 3–5 人日 | `KeyValueStore` 只提供基础 get/set；`AppInitCache`、`ProductCache`、`PendingOrderStore` 各自实现序列化/失效；没有 connectivity/offline queue package。 |
| G22 | **新增 `ai_kit`。** 定义 ModelCapability/ModelRoute/ProviderAdapter、流式与非流式统一结果、TokenUsage（input/output/cached/estimated）、额度预检与结算、超时/取消、重试边界、provider fallback/circuit breaker、内容安全错误和 telemetry；默认通过自有后端路由，不在客户端保存供应商密钥；用 fake adapter 覆盖主备切换、半开恢复、usage 缺失和超额。 | 每个 AI 产品直接在业务层调用自己的模型后端并自行计量/降级；仓内没有可复用实现。 | 客户端 10–15 人日；若服务端也缺模型网关与计量，再加 12–20 人日 | 根 workspace 只有 infra/commerce/ui/arch/config/media；所有 pubspec 无模型 SDK；仓内只有 `ContentFilterFailure` 错误映射和 `media_kit` 上传，不存在路由/usage/fallback 实现。 |

## 4. 补齐路线

排序严格按“阻塞新产品上线”＞“重复劳动最多”＞“体验优化”。路线中的编号引用上一节任务，可直接拆成迭代。

### P0：阻塞上线

1. **先修 IAP 最终一致性（G01）。** 这是当前最该动手的一项：现实现能在 subscription/non-consumable 验单超时或 `grant_failed` 后 finish 原生交易并删除 pending，而仓内没有可证明授权已完成的 webhook 实现。它会产生“用户已付费、客户端却没有可证明权益”的资金与信任事故；这比路由、埋点和 CI 缺失更难补救，也直接违背模板最核心的 IAP 价值。完成标准是所有 finish 都有可审计的服务端授权/安全 acknowledge 结论，任何失败都保留可重试记录且不会成为未处理异步异常。
2. **让原生 release 真正可发布（G19）。** 先修 Android main INTERNET 权限，再完成 release signing、产品身份单一来源和 native/config 一致性门；否则 Android release 要么无法联网，要么不能作为正式包上架。
3. **建立共享后端合同与真实商店 E2E（G06、G20 的 IAP 部分）。** 用隔离商品证明下单、验单、S2S/RTDN、恢复和权益刷新闭环；没有这个证据，客户端 fake 测试不能证明票据校验能力。
4. **关闭商店错误、关联与幂等缺口（G02、G03、G12）。** 先保证商店不可用/启动失败可解释，再保证一个交易只对应一个订单、写请求不会被透明重放。
5. **保证 Paywall 所见即所得（G04、G18）。** 在完整 Offer 购买和资格判断上线前，强制只售一个默认计划并隐藏所有 promo/后端 trial；随后补优惠签名、Play offerToken、换档和商店真实周期。同步把法律链接、续订说明、Restore/Manage 设为 fail-closed。
6. **修正隐私与账号合规（G17、G08 的删除账号）。** 按真实数据流更新隐私清单，接入权限/ATT gate，并提供应用内账号删除；将三者加入发布 checklist/CI。
7. **修复账号—钱包—权益一致性（G07、G08、G09）。** 交付 logout 后可用会话、游客资产迁移、按账号隔离的钱包，以及到期定时失效，防止跨账号显示或使用旧权益。

### P1：减少新产品重复劳动

8. **抽出路由与启动注册表（G10）。** 新产品只注册 route 和 startup task，不再复制/修改 app shell 与 commerce 启动源码。
9. **修复动态目录新鲜度并抽通用缓存（G05、G21）。** 一次解决商品/法律/强更陈旧，以及每个产品重复写 TTL、迁移和账号隔离的问题。
10. **接通生产观测、事件 schema 和实验层（G14、G15）。** 让所有后续产品自动获得 crash、IAP 漏斗、requestId 关联、脱敏和实验曝光，而不是到上线前再选 SDK、重埋事件。
11. **自动化质量与发版（G20 的 CI/CD/版本部分）。** 把本地 Makefile 门禁迁入 CI，加入覆盖率、签名 dry-run、版本生成和商店上传，消除每个产品重复搭流水线。
12. **升级移动端请求身份（G13）。** 在更多付费产品接入前，把可提取 HMAC 降级为渠道信号，统一接入 App Attest/Play Integrity，避免每个产品重新做一套反滥用。
13. **建设 AI 产品公共接入层（G22）。** 对计划中的 AI 产品线，在首个模型业务页面之前完成；否则模型路由、Token 计量和降级会立刻散落进各产品业务代码，之后最难回收。

### P2：体验与运营优化

14. **补 Locale/ThemeMode（G11）。** 让产品可切换语言/明暗主题，并保证请求语言与 UI 一致。
15. **补评分引导和推送（G16）。** 先上线低风险评分策略，再接权限受控的推送、账号 token 绑定与深链；两者都复用 P1 的路由、埋点和 consent 层。

完成 P0 后，这个仓库才可被称为“具备可上线 IAP 闭环的模板”；完成 P1 后，才基本达到背景目标所说的“新产品主要编写 PRD 核心业务逻辑”；P2 决定增长效率和最终体验，但不应排在资金、身份、合规和发布正确性之前。
