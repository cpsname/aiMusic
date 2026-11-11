# 基础设施完成度审计(infra-audit)

- **审计日期**:2026-08-27
- **视角**:「新产品首日接入者」——复制本仓开新产品,哪些开箱即用、哪些要自己写、哪些阻塞上线。
- **方法**:全部结论以源码为准(文档说有、代码没有的按没有算);关键链路逐文件精读;外围维度全仓符号级扫描;质量门禁实跑验证。
- **实跑验证结果**(本机 Flutter 3.44.2 / Dart 3.12.2):
  - `dart run arch_guard` → 0 违规(6 source roots);
  - 6 个包测试全绿(`infra_core` 96 / `commerce_kit` 117,其余包亦全过);
  - 根 app `flutter analyze` 0 issues、48 测试全过 —— **但需先 `flutter gen-l10n`**(见缺口 G15:当前工作树删除了 `lib/l10n/generated/`,直接跑门禁是红的);
  - `flutter build ios --config-only --dart-define-from-file=config/dev.json` 通过。

**一句话结论**:商业化基座(网络/签名/错误/存储/IAP/钱包/治理)是真实的企业级完成度,复制即用;但「能跑通购买」≠「能上架」——订阅合规文案(~~G1,2026-08-27 已收口~~ ✅)、账号删除、Android 发布通道是每个新产品都会踩的上架阻塞;增长侧(崩溃上报 vendor、推送、评分)与 AIGC 任务层是成体系的缺失。

状态取值:✅ 开箱即用 / ⚠️ 有骨架需补全 / ❌ 缺失。

---

## 一、完成度总表

| # | 维度 · 子项 | 状态 | 证据(文件 · 关键类/方法) |
|---|---|---|---|
| 1.1 | 工程骨架 · 目录分层与模块边界 | ✅ | `pubspec.yaml`(workspace)+ `melos.yaml`;`packages/{infra_core,commerce_kit,ui_kit,app_config,media_kit,arch_guard}` DDD 三层;`packages/arch_guard/bin/arch_guard.dart` 实跑 0 违规 |
| 1.2 | 工程骨架 · 依赖注入 | ✅ | 手写 Riverpod 组合根:`packages/infra_core/lib/src/providers.dart`、`.../iap/application/iap_providers.dart`;`lib/main.dart` `commerceKitOverrides()` 绑定 `AuthGateway` |
| 1.3 | 工程骨架 · 环境区分(dev/prod) | ✅ | `packages/infra_core/lib/src/config/env_config.dart`(`String.fromEnvironment` 全量,零硬编码);`Makefile` `check_config.sh` 守卫;Xcode「Verify Build Config」构建阶段(`ios|macos/Runner.xcodeproj/project.pbxproj` 各 1 处);运行时兜底 `StartupController.start()` → `ConfigFailure` |
| 2.1 | 应用外壳 · 启动流程 | ✅ | `packages/commerce_kit/lib/src/iap/application/startup_controller.dart`(配置检查→迁移→并行 `/app/init`+认证→强更门→预取→对账器);`lib/ui/startup/startup_gate.dart` |
| 2.2 | 应用外壳 · 状态管理 | ✅ | Riverpod 3.x 全手写;`lib/main.dart` `ProviderScope(retry: (_, _) => null)`(错误终态化) |
| 2.3 | 应用外壳 · 主题 | ⚠️ | `packages/ui_kit/lib/src/theme.dart` `AuraTheme.dark/.light` 双套齐备,但 `lib/ui/app.dart:21` 只挂 `theme: AuraTheme.dark`,无 `darkTheme:`/`themeMode:`,浅色已建未用 |
| 2.4 | 应用外壳 · 多语言 | ✅ | `l10n.yaml` + `lib/l10n/arb/{app_en,app_zh}.arb`(71 键);RTL 结构安全由 arch_guard `no_hardcoded_directional` 规则机器强制 + `test/goldens/*_rtl.png` 快照;后端文案走 `X-Language` |
| 2.5 | 应用外壳 · 路由 | ❌ | 全仓唯一 `Navigator` 调用是 `lib/ui/me/login_sheet.dart:50` 的 `pop()`;无路由表/`onGenerateRoute`/go_router,页面切换靠 `lib/ui/shell/studio_shell.dart` `IndexedStack`;深链无挂载面 |
| 3.1 | 数据层 · 网络层与防腐层 | ✅ | `packages/infra_core/lib/src/network/dio_factory.dart` 双 Dio 七段拦截器链(device→auth→signature→clock-sync→retry→envelope→logging);签名 `crypto/signing_service.dart`(openssl 字节级对拍测试);DTO→domain 防腐层各包 `data/` 齐备 |
| 3.2 | 数据层 · 本地存储 | ✅ | `key_value_store.dart`(损坏容错)、`secure_token_store.dart`(Keychain,`clearTokens()` 保设备 id)、`storage_migrator.dart`(有序迁移、可续跑、永不阻塞启动) |
| 3.3 | 数据层 · 缓存 | ✅ | `app_init_cache.dart`(boot-session 级,重启/升级失效)、`product_cache.dart`(24h TTL + 币种失配检测 + 查询失败回落陈旧缓存) |
| 3.4 | 数据层 · 错误模型 | ✅ | sealed `ApiError`/`Failure`(`packages/infra_core/lib/src/error/`);`ErrorHandler.handle` 全映射(含 `unknown`+`SocketException`→offline);呈现层单一事实源 `lib/ui/common/failure_copy.dart` + `ErrorRetryView`/Message 双面 |
| 4.1 | IAP · 商品配置 | ✅ | 后端目录(`/app/init`)∩ 商店实价合并:`product_merge_service.dart`、`product_detail_extractor.dart`;不可购商品剔除(`unavailableProductIdsProvider`) |
| 4.2 | IAP · 购买 | ✅ | `iap_purchase_orchestrator.dart` 完整状态机(创建订单→过期检查→native→校验→完成;pending 先持久化;SK2 静默取消探测窗) |
| 4.3 | IAP · 恢复 | ✅ | `restorePurchases()`:仅用户触发;restore 窗口收集→逐笔串行 create-order→verify(`transaction_id` 绑定,`40011` 幂等成功);`_restoreOne` 永不抛 |
| 4.4 | IAP · 票据校验 | ✅ | 服务端校验 `iap_verifier.dart`(1s→2s→4s 退避,`40010/40016/40912/50000/50301/50302`+超时重试;verify-成功才 finish) |
| 4.5 | IAP · 订阅状态机 | ✅ | 权益服务端真值 `subscription_entitlement.dart`(宽限期放行、billing-retry 提示);`iap_background_reconciler.dart`(续订/补投/撤销对账、类型化 finish 策略、前台刷新) |
| 4.6 | IAP · 试用与优惠 | ✅ | `product_detail_extractor.dart` 读 SK1/SK2/Play 的 intro/promo/free-trial;`lib/ui/paywall/paywall_page.dart` `_offerLabels` 渲染 |
| 4.7 | IAP · Paywall 组件 | ✅ | `lib/ui/paywall/paywall_page.dart`:动态商品、骨架屏、错误重试、restore、法务链接、kill-switch、promo 横幅(合规文案缺口见 8.4) |
| 5.1 | 用户体系 · 设备标识 | ✅ | `device_info_service.dart` UUID 一次生成 + Keychain 持久(`SecureTokenStore`,重装存活,锚定 guest 幂等) |
| 5.2 | 用户体系 · 账号 | ⚠️ | 三防线齐备(`auth_controller.dart` `ensureAuthenticated()`:本地复用→refresh→幂等 guest 注册);但登录仅用户名/密码(`login_sheet.dart`),无 Sign in with Apple/Google,无账号删除(见 8.5) |
| 5.3 | 用户体系 · 订阅态与权益下发 | ✅ | `/auth/me` + `/wallet` → `currentAccountProvider`/`walletSnapshotProvider`/`hasFeatureProvider`;刷新链路(启动/verify 成功/前台恢复)在 `IapBackgroundReconciler.refreshEntitlement()` |
| 6.1 | 增长运营 · 埋点 | ⚠️ | 框架完整:`TelemetrySink` 抽象 + IAP 漏斗全事件(`paywall_view→purchase_start→…`)+ `RedactingTelemetrySink` 脱敏;但具体 sink 只有 Noop/Console(`telemetry_sink.dart:29,54`),`lib/main.dart:15` release 即 Noop——**线上零上报** |
| 6.2 | 增长运营 · 远程配置 / Feature Flag | ✅ | `packages/app_config/`:`GET /app/config` fail-open;`isFeatureKilledProvider`(kill-switch)、`configValue<T>`(远程配置)、`MaintenanceGate`(`lib/ui/governance/maintenance_gate.dart`) |
| 6.3 | 增长运营 · 评分引导 | ❌ | 全仓无 `in_app_review`/`SKStoreReviewController`/相关 ARB 键(符号级扫描零命中) |
| 6.4 | 增长运营 · 推送 | ❌ | 无 firebase_messaging/APNs 注册;`ios/` 无任何 `.entitlements` 文件(无 `aps-environment`);`commerce_kit` 中的 `push_token` 实为 IAP `appAccountToken` 复用,非推送 |
| 7.1 | 稳定性 · 崩溃与错误上报 | ⚠️ | 捕获链完整:`bootstrap.dart`(zone + `FlutterError.onError` + `PlatformDispatcher.onError` 全接管);但无 vendor SDK(全仓无 sentry/crashlytics),release 落进 Noop——**线上崩溃黑盒** |
| 7.2 | 稳定性 · 日志与脱敏 | ✅ | `logging_interceptor.dart` 全环境掩码面包屑(`method·path·status·latency·request_id`);`pii_redactor.dart`(JWT/邮箱/hex 密钥/E.164 清洗,`request_id` 存活可关联);`envelope_interceptor.dart` 透传 `request_id` |
| 8.1 | 合规 · ATT | ✅ | 当前姿态正确:零追踪 SDK,`ios/Runner/PrivacyInfo.xcprivacy` 声明 `NSPrivacyTracking=false`,故无需 ATT;**引入任何归因/广告 SDK 时需自补**(见 G9) |
| 8.2 | 合规 · 隐私清单 | ✅ | `ios/Runner/PrivacyInfo.xcprivacy` 四类 Required-Reason API + 理由码,已挂入 Runner Resources 阶段(`project.pbxproj:235`),`test/governance/build_config_gate_test.dart` 守护 |
| 8.3 | 合规 · 权限申请 | ✅ | 当前插件集不需要任何运行时权限:`ios/Runner/Info.plist` 0 个 `NS*UsageDescription`、Android main manifest 0 个 `uses-permission` 均为正确状态(新产品加相机/相册等时自补) |
| 8.4 | 合规 · 订阅必备文案与入口 | ✅ | **G1 于 2026-08-27 收口**:自动续订披露 `paywallAutoRenewNotice`(订阅商品在列即渲染);法务链接兜底链 `effectiveLegalInfo`(服务端 → `TERMS_URL`/`PRIVACY_URL` → Apple 标准 EULA,`lib/ui/common/external_links.dart`)+ store 构建守卫 `SHIP_KEYS`(Makefile);Profile 订阅卡常驻「管理订阅」入口(`profile_page.dart` `_subscriptionCard`) |
| 8.5 | 合规 · 账号删除(5.1.1(v)) | ⚠️ | **游客生命周期已交付(2026-08-27)**:`AuthController.deleteAccount()` 销毁 Keychain `device_id`(注册按 id 幂等 → 旧游客永久不可达)+ 即时重注册新游客;Profile 游客可见删除入口(确认弹窗含「不取消 App Store 订阅」披露)。**剩余**:正式账号删除端点 + 孤儿游客服务端清退(`BACKEND_COORDINATION.md` §8) |
| 8.6 | 合规 · 商店上架配置 | ✅ | **2026-08-27 收口**:`ITSAppUsesNonExemptEncryption=false` 已声明于双端 Info.plist(仅豁免加密/HTTPS);显示名/包名按当日决策属**产品发布期配置**,已固化为 `docs/RELEASE_CHECKLIST.md` §1 |
| 9.1 | 工程效率 · 本地质量门禁 | ✅ | `Makefile` `gates` = analyze→arch→test→ios→verify-xcode-config→shellcheck;`scripts/` 五件套(config 校验/xcconfig 对拍/dev.sh/logcat.sh);Xcode 构建阶段强制防错配 |
| 9.2 | 工程效率 · 测试覆盖 | ✅ | 59 个测试文件跨 7 个 source root,本次实跑全绿;含 openssl 对拍、SK2 静默取消、三防线、LTR/RTL golden ×6;无 coverage 统计工具(小疵) |
| 9.3 | 工程效率 · CI/CD | ✅ | **2026-08-27 交付**:`.github/workflows/gates.yml`——macOS runner 跑与本地同款的 `make gates`(golden 依赖渲染器 + iOS config-only 需 macOS),CI 用合成 dev.json(dummy secret,不含真实密钥) |
| 9.4 | 工程效率 · 打包签名 | ✅ | 模板范围内完整:`make ipa/aab/apk` 注入链 + GUARD_SHIP 守卫。签名/证书/keystore 按 2026-08-27 决策属**产品发布期配置**(逐产品各异),已固化为 `docs/RELEASE_CHECKLIST.md` §3(含「Android release 仍为 debug 桩,发包前必换」的显式检查项) |
| 9.5 | 工程效率 · 版本管理 | ❌ | `pubspec.yaml` `1.0.0+1` 手改;无 bump 脚本、无 CHANGELOG、git 0 个 tag |
| 10.1 | AI 接入层 · 文件上传 | ✅ | `packages/media_kit/` 完整两段式预签名直传(hash→policy→sign→dedup 短路→PUT R2→finalize,含取消/进度/去重);**参照消费方已接线(2026-08-27,G13)**:`lib/ui/upload/upload_demo_page.dart`(第三个 tab,image_picker 相册零权限,进度/取消/秒传徽标/标准失败面) |
| 10.2 | AI 接入层 · Token/积分计量 | ✅ | 读侧完备:`/wallet` 余额/冻结/累计 + `InsufficientCreditsApiError`→`PaymentFailure`(计费扣减在服务端逐次任务发生,客户端只需读模型) |
| 10.3 | AI 接入层 · 模型路由 / 任务创建 / 轮询 / 失败降级 | ❌ | 客户端 HTTP 面仅 9 条路径(auth×5 + app/init + iap×2 + app/config + wallet + uploads×2),`/creations`、`/v1/models/*`、`/materials` 等零客户端代码;无任务模型、无轮询器;`docs/api/{creation,provider,material-analysis,…}.md` 契约齐但全无对应实现 |

---

## 二、开箱即用清单(复制仓库后可直接调用)

以下能力**零改造**可用,接入代码即最小示例(均已在样例 app 有真实调用点可对照)。

**1. 全链路网络请求**(签名/JWT/时钟纠偏/重试/信封解包/脱敏日志全免费):

```dart
final res = await ref.read(apiDioProvider).get<dynamic>('/my/endpoint');
// 业务错误已由 EnvelopeInterceptor 抛成 sealed ApiError;40102 自动刷新重放
```

**2. 统一错误 → UI**(与 Profile/Paywall 完全同款的呈现):

```dart
// 页面级(无内容可展示时)
ErrorRetryView(failure: ref.read(errorHandlerProvider).handle(e, st),
    onRetry: () => ref.invalidate(myProvider));
// 操作级(不覆盖页面状态)
ref.read(messageControllerProvider)
    .show(failureMessage(l10n, failure, fallback: l10n.myFallback));
```

**3. 认证(三防线,永不误注册新 guest)**:

```dart
await ref.read(authControllerProvider.notifier).ensureAuthenticated();
// 之后 apiDio 自动携带 Bearer;40102 单飞刷新、40106 强登出全自动
```

**4. 订阅购买 / 恢复 / 权益门**(整套状态机现成):

```dart
ref.read(iapPurchaseOrchestratorProvider.notifier).purchase(product);   // 购买
ref.read(iapPurchaseOrchestratorProvider.notifier).restorePurchases();  // 恢复
if (ref.watch(subscriptionEntitlementProvider).isEntitled) { ... }      // 订阅门
if (ref.watch(hasFeatureProvider('feature_code'))) { ... }              // 权益门
```

**5. 动态商品列表**(商店实价 + ASC 优惠 + 离线陈旧缓存回落):

```dart
final products = ref.watch(storeProductsProvider); // AsyncValue<List<StoreProduct>>
```

**6. 运行时治理**(维护页/kill-switch/远程配置,fail-open 永不堵启动):

```dart
if (ref.watch(isFeatureKilledProvider('my_feature'))) return const Unavailable();
final banner = ref.watch(appConfigProvider).configValue<String>('promo_text', '');
```

**7. 埋点与错误上报**(换 vendor 只改 `main.dart` 一处):

```dart
ref.read(telemetrySinkProvider).logEvent('my_event', properties: {'k': 'v'});
// 生产接入:main.dart 里把 NoopTelemetrySink 换成你的 vendor adapter,
// RedactingTelemetrySink 包裹保证 PII 不出端
```

**8. 文件直传 R2**(含进度/取消/秒传去重):

```dart
final result = await ref.read(uploadServiceProvider).upload(
  UploadInput(bytes: bytes, mimeType: 'image/png', filename: 'a.png',
      contentKind: UploadContentKind.image),
  onProgress: (p) => debugPrint('${p.phase} ${p.sentBytes}/${p.totalBytes}'),
);
```

**9. 持久化与 schema 演进**:

```dart
// 任何持久化形状变更:migrations 加一步 + 版本常量 +1,启动自动迁移
final storageMigrationsProvider = Provider<List<StorageMigration>>((ref) => [
  StorageMigration(version: 2, description: 'xxx', migrate: (store) async {...}),
]);
```

**10. 启动/强更/维护外壳**:`lib/ui/app.dart` 的 `StartupGate(child: MaintenanceGate(child: …))` 三层门直接换 `StudioShell` 为你的首页即可;配置注入 `make run ENV=dev`。

---

## 三、缺口清单

每项含:缺什么 / 当前替代做法 / 自行实现成本(人日,含测试)。均可直接立任务。

| ID | 缺口 | 缺什么(验收口径) | 当前替代做法 | 成本 |
|---|---|---|---|---|
| G1 | ~~订阅合规文案与入口(8.4)~~ **✅ 已完成(2026-08-27)** | 落地为:披露文案 `paywallAutoRenewNotice`(订阅商品在列时渲染);`effectiveLegalInfo`(`lib/ui/common/external_links.dart`,服务端 → `TERMS_URL`/`PRIVACY_URL` 编译期兜底 → Apple 标准 EULA);Profile 订阅卡常驻管理入口(权益/billing-retry 时);store 构建守卫 `SHIP_KEYS` 强制两 URL 非空;golden ×6 更新 | — | 已交付 |
| G2 | 账号删除(8.5)**〔游客路径已交付 2026-08-27〕** | 已落地:`deleteAccount()`(销毁 Keychain 锚 + 重注册)、Profile 游客删除入口 + 确认弹窗、`SecureTokenStore.deleteDeviceId` / `DeviceInfoService.reset`。**剩余(后端依赖)**:正式账号删除端点 + 孤儿游客数据清退,端点落地后调用加在 `deleteAccount()` 顶部 | 游客产品已合规;正式账号仍缺 | 后端端点 + 客户端 0.5d |
| G3 | ~~Android release 无网络权限~~ **✅ 已完成(2026-08-27)** | main manifest 已声明 INTERNET(`android/app/src/main/AndroidManifest.xml`),并新增治理测试 `test/governance/release_manifest_test.dart` 防回退 | — | 已交付 |
| G4 | ~~Android 发布签名~~ **改判(2026-08-27)**:产品发布期配置,非模板缺口 | 已固化为 `docs/RELEASE_CHECKLIST.md` §3(keystore/key.properties/signingConfig/R8 逐项检查) | checklist 约束 | — |
| G5 | ~~上架元数据基线~~ **部分交付 + 改判(2026-08-27)** | 模板侧已做:`ITSAppUsesNonExemptEncryption=false`(双端 Info.plist);显示名/包名统一 = 产品项 → `RELEASE_CHECKLIST.md` §1 | checklist 约束 | — |
| G6 | 崩溃/埋点 vendor adapter **〔按 2026-08-27 决策暂缓〕** | 维持 Noop(release)/Console(dev)现状;将来接入时:实现 `TelemetrySink` 的 vendor adapter + `main.dart` 绑定 + PII 复核 + 隐私清单/营养标签同步申报 | Noop/Console | 1–2d(暂缓) |
| G7 | ~~CI/CD~~ **✅ 已完成(2026-08-27)** | `.github/workflows/gates.yml`:macOS runner + 合成 config 跑 `make gates`(与本地完全同款入口) | — | 已交付 |
| G8 | 路由骨架 | go_router(或 Navigator 2 封装)+ 三层门迁为 redirect/外层包裹;预留 deep-link 挂载面(`CFBundleURLTypes`/App Links) | `IndexedStack` 双 tab,新页面无处可推 | 1–2d |
| G9 | Sign in with Apple / 第三方登录 | SIWA 按钮 + `sign_in_with_apple` + entitlements(需先建 `ios/Runner/*.entitlements`)+ 后端 `/auth/apple` 协调;注:一旦提供任何第三方登录,SIWA 即为 4.8 强制项 | 用户名/密码 + guest | 2–3d + 后端 |
| G10 | 推送 | APNs/FCM 注册、token 上报端点、`aps-environment` entitlements、Android 13+ `POST_NOTIFICATIONS` 权限流 | 无 | 2–3d + 后端 |
| G11 | 评分引导 | `in_app_review` + 触发策略(建议挂 `purchase_success`/任务成功漏斗,频控持久化于 `KeyValueStore`) | 无 | 0.5d |
| G12 | AIGC 任务层客户端 | 新包 `aigc_kit`(同 DDD 分层):任务创建/查询/轮询(或 SSE)、`/v1/models/*` 模型列表与路由、`45100 promptRejected` 等错误落地、失败降级策略;契约齐备:`docs/api/{creation,provider,material-analysis}.md` | 每个新产品从零手写(唯一有后端契约却零实现的大块) | 5–10d |
| G13 | ~~media_kit 接线示例~~ **✅ 已完成(2026-08-27)** | `upload_demo_page.dart`(第三 tab):image_picker 相册直选(PHPicker 零权限)→ `uploadServiceProvider` 全流程,进度分相/取消/秒传徽标/policy 失败即时提示;3 个 widget 测试 + ltr/rtl golden;macOS 补 user-selected-read 权益 | — | 已交付 |
| G14 | 浅色主题挂载 | `MaterialApp` 补 `darkTheme:`+`themeMode:`;`AuraTheme.light` 已存在仅未接 | 强制深色 | 0.5d |
| G15 | ~~l10n 生成物状态收口~~ **✅ 已完成(2026-08-27)** | 定案为「生成物不入库」(与工作树未提交删除的意图一致):`.gitignore` 加 `lib/l10n/generated/`、已 `git rm --cached`;`make analyze`/`make test` 前置 `l10n`,鲜克隆与 CI 自愈 | — | 已交付 |
| G16 | 版本管理 | bump 脚本(pubspec version + git tag)+ CHANGELOG 约定 | 手改 pubspec | 0.5d |
| G17 | 杂项小疵 | ① `melos.yaml` 含 `"."` 致 `make test` 根测试跑两遍;② `activeWalletFeaturesProvider` 用裸 `DateTime.now()` 而非 DF① 纠偏时钟(与 `MaintenanceGate` 不一致,时钟漂移设备权益误判);③ shellcheck 未装时软放行 | — | 0.5d 合计 |

---

## 四、补齐路线

排序依据:**阻塞新产品上线 > 重复劳动最多 > 体验优化**。

### 第 1 项(当前最该动手):G1 订阅合规收口包 —— ✅ 已于 2026-08-27 完成

**为什么是它**:本模板的核心卖点就是订阅变现,而当前复制出去的**每一个**新产品都会在 App Review 3.1.2 上踩同一颗雷——法务链接完全依赖后端下发且无兜底(新产品后端漏配一个 URL,paywall 法务块整体静默消失),且全仓没有一条自动续订披露文案。它同时满足三个「第一」:上架阻塞里唯一**纯客户端、无外部依赖**就能闭环的;修一次所有未来产品受益(模板杠杆最大);成本最低(1–2 天)风险最高(必拒项)。G2(账号删除)同为阻塞但卡后端端点,正确动作是**今天同时发起后端协调**,客户端实现排第 2 并行推进。

### P0 — 阻塞新产品上线

1. **G1 订阅合规收口包**(披露文案 + 法务链接兜底 + 常驻管理订阅入口)— 1–2d
2. **G2 账号删除** —— ✅ 游客生命周期已于 2026-08-27 交付(`deleteAccount()` 销毁 Keychain 锚 + 重注册);剩余为后端项:正式账号删除端点 + 孤儿游客清退(§8 已更新协调说明)
3. **G3 Android INTERNET 权限** —— ✅ 2026-08-27 已交付;**G4 签名** —— 改判为产品发布期配置(`RELEASE_CHECKLIST.md` §3)
4. **G5 上架元数据基线** —— ✅/改判 2026-08-27:出口合规声明已入模板,身份项固化为 `RELEASE_CHECKLIST.md` §1

### P1 — 重复劳动最多(每个新产品都要做一遍的,沉到模板里)

5. **G6 崩溃/埋点 vendor adapter** —— 按 2026-08-27 决策**暂缓**(维持 Noop/Console;接入时连带隐私申报一起做)
6. **G7 CI + G15 l10n 收口** —— ✅ 均于 2026-08-27 交付(macOS runner 跑 `make gates`;生成物退出 git + make 前置自愈)
7. **G8 路由骨架**(go_router + 深链挂载面,为 G10 推送/营销深链铺路)— 1–2d
8. **G9 Sign in with Apple** —— 按「产品全走游客生命周期」的现状降级:仅当某产品启用登录时才需要 — 2–3d
10. **G12 AIGC 任务层 `aigc_kit`**(作为「IAP + AIGC 模板」,这是唯一契约齐备却零实现的大块;若产品线近期开 AIGC 产品,此项可提前至 P1 之首)— 5–10d
11. **G13 media_kit 接线示例** —— ✅ 已于 2026-08-27 交付(上传演示页 + 3 测试 + ltr/rtl golden)

### P2 — 体验优化

12. **G11 评分引导**(挂 `purchase_success` 漏斗)— 0.5d
13. **G14 浅色主题挂载** — 0.5d
14. **G16 版本管理 + G17 杂项小疵** — 1d 合计
15. **G10 推送**(按产品需要拉起;依赖 G8 深链与 entitlements 基建)— 2–3d

---

### 附:审计过程中对工作树的唯一改动

为使门禁可跑,执行了 `flutter gen-l10n` 重新生成 `lib/l10n/generated/`(该目录在当前工作树处于已删除的未提交状态);未改动任何业务代码。G15 的收口决策(入库 vs 忽略)属于本次未提交变更的一部分,建议随 G7 一并定案。
