# 深度基建盲点规格（高杠杆 · 最易漏）

> 这 7 项是支付/AIGC 类 App **每个项目都会踩、却最易在模板期被跳过**的基建。逐项实现级，标注落点与是否需要后端配合。
> 凡标【后端依赖】的，对应要求汇总在 `BACKEND_COORDINATION.md`。本规格遵守与主 prompt 相同的红线：不简化、不绕架构、不降扩展性、不表面修复。

---

## 1. 时钟偏移打穿 HMAC 签名链  〔infra_core/crypto + config + network〕【后端依赖】

**症状/为何最易漏**：签名是 `timestamp + nonce + canonical_json`。设备时钟偏移几分钟 → 每个签名请求 401/签名错，且**开发机时钟准、线下无法复现**，上线才爆。

**实现要点**
- `/app/init` 返回服务器权威时间（ms）→ 计算 `offset = serverTime - deviceTime`，用 RTT/2 粗补偿网络往返 → 存进程内 `ClockOffsetService`。
- `SigningService` 生成 `timestamp` 一律用 `correctedNow = deviceNow + offset`，**不直接用 `DateTime.now()`**。
- 持续校正：若每个响应带 `X-Server-Time` 头，滑动更新 offset。
- **冷启动排序坑**：guest-register 与 `/app/init` 并行发出时，首个签名请求可能在拿到 offset 之前。处理：首启允许用本地时间签发 guest-register；若因签名时间窗被服务端拒（特定签名错误码）→ 用此时已获得的 offset **重签并重试一次**（不无限重试）。
- offset 不持久化（重启重算），避免存了过期 offset。

**验收/测试**：注入偏移的 fake clock，断言签名时间被校正；offset 未就绪时的"失败→重签重试"路径有 unit 覆盖。

---

## 2. 生产可观测性为空  〔infra_core/observability(新增) + bootstrap + network + error〕【后端依赖】

**症状/为何最易漏**：`LoggingInterceptor` 只在 dev/staging。线上 IAP 出问题**完全无数据可查**。

**实现要点**
- `bootstrap` 用 `runZonedGuarded` 包裹 + 挂 `FlutterError.onError` 与 `PlatformDispatcher.onError` → 统一汇入既有 `Failure` 体系。
- 新增**厂商无关** `TelemetrySink` 接口（`logEvent / recordError / breadcrumb / setUser`）+ `NoopTelemetrySink` 默认实现 + 一个示例 adapter（仅接口形态，不绑死任何厂商）。
- **PII 脱敏**：token/secret/email/手机号在落库前正则脱敏；只放行白名单字段。
- 标签：app version、build、匿名 userId、`request_id`（与 envelope 联动，便于和后端日志对账）。
- **IAP 漏斗埋点**（贯穿 orchestrator 各分支）：`paywall_view → purchase_start → native_cancel / verify_retry / purchase_success / purchase_fail(stage)`。
- `LoggingInterceptor` 在**所有环境**记录脱敏后的 `request_id + 状态码 + 耗时`（不止 dev/staging）。

**验收/测试**：人为抛异常被 zone 捕获并送 sink；脱敏断言（token 不出现在输出）；orchestrator 每条分支发出对应漏斗事件。

---

## 3. 用 lint 机器强制架构边界  〔仓库层：custom_lint + analysis_options + CI〕

**症状/为何最易漏**："不准绕架构/降扩展性"现在只靠文字 + 人审；**一旦复制成新项目就开始漂移**，模板初衷被慢慢蚀空。

**实现要点**（把价值观变成门禁，复制即继承）
- 用 `custom_lint`/import 规则集强制：
  - `features/*` / `commerce_kit` 不得 import `ui/*` 或 `ui_kit`；
  - 包 → app 反向依赖禁止（`infra_core/commerce_kit/ui_kit` 不得 import `studio_app`）；
  - `domain` 不得 import `data` / `application` / `package:flutter/material.dart`；
  - `application` 经 `domain` 接口依赖 `data`，不得 import `data` 具体实现类；
  - 禁止在 `features/` 下出现 `presentation/`；
  - UI 层禁止硬编码 left/right padding（配合 §5 RTL）。
- CI：`melos exec -- custom_lint` 任一越界即 fail；规则集随模板分发。

**验收/测试**：故意写一条越界 import，CI 必须红；规则集本身有最小测试夹具。

---

## 4. Apple 隐私清单 + Required-Reason API  〔apps/studio_app/ios + 文档〕【后端依赖（仅账号删除）】

**症状/为何最易漏**：用了 `shared_preferences`/`secure_storage`/`device_info_plus` 等会触发 Required-Reason API；自 2024 春起，缺合规的隐私清单**直接拒审**（ITMS-91xxx）。

**实现要点**
- app 级 `PrivacyInfo.xcprivacy` 模板，**聚合整个应用**（含所有库）的：
  - `NSPrivacyAccessedAPITypes`：按实际用到声明理由——UserDefaults(`CA92.1`)、FileTimestamp(`C617.1`/`3B52.1`)、DiskSpace(`E174.1`/`85F4.1`)、SystemBootTime(`35F9.1`) 等；
  - `NSPrivacyCollectedDataTypes`：即便不收集也常需显式声明 `None`/空数组，**省略键反而可能被拒**。
- 校验插件是否已自带 `.xcprivacy`（多数一方插件已带）；用 **Apple 规范的 SDK 标识符**而非友好名；确认清单落在 `Payload/Runner.app/PrivacyInfo.xcprivacy` 根部，未被多层嵌套埋没。
- 若接分析/广告 → ATT 流程（`NSUserTrackingUsageDescription` + 请求时机）。
- **账号删除**：若有账号体系，App Store 要求 App 内可删除账号 → 需后端删除端点（见后端文档）。

**验收/测试**：Xcode Organizer 上传无隐私警告；TestFlight 处理通过；`flutter clean && pub get` 后重打包复核。

---

## 5. RTL / 阿拉伯语正确性  〔ui_kit + studio_app〕

**症状/为何最易漏**：`ar` 已是发布 locale，但渐变 + 动画的 Aura UI 几乎必然有 RTL bug（方向性 padding、图标镜像、文本对齐、`AuroraBackground` 朝向）。

**实现要点**
- 全量改用 `EdgeInsetsDirectional` / `AlignmentDirectional` / `start-end`，**禁绝硬编码 left/right**（§3 lint 兜底）。
- 方向性图标镜像（`matchTextDirection` 或 `Transform`），文本对齐随 `Directionality`。
- `AuroraBackground` 做成方向无关或方向感知。
- 关键页（Profile / Paywall / Shell）做 **ltr + rtl 双向 golden 快照**。

**验收/测试**：rtl golden 与 ltr golden 同时存在并通过；阿拉伯语下关键交互无错位。

---

## 6. 减弱动态效果 + 功耗  〔ui_kit + 生命周期服务〕

**症状/为何最易漏**：`AuroraBackground` 是无限 `repeat()`（测试都得用 `pump()` 而非 `pumpAndSettle()`）。无障碍"减弱动态效果"、低电量、后台续跑都会带来耗电与审核风险。

**实现要点**
- 读 `MediaQuery.disableAnimations`（reduce-motion）→ 降级为静态渐变。
- 监听 `AppLifecycleState.paused/inactive` → 暂停所有 `AnimationController`；恢复前台再启。
- 可选低电量降级（`battery_plus`）。
- 封装成 `MotionPolicy` + 让 `AuroraBackground`/`Typewriter` 等统一遵循。

**验收/测试**：reduce-motion 下断言不启动 ticker（单帧 `pump` 后无动画）；后台切换暂停/恢复有 widget 测试。

---

## 7. 持久化数据版本迁移  〔infra_core/storage〕

**症状/为何最易漏**：prefs/secure storage 的数据形状会随模板演进与 App 升级变化；升级后旧数据导致崩溃/脏态，且**只在存量用户升级时发生**。

**实现要点**
- 存 `schemaVersion` key；`StorageMigrator` 注册有序迁移步 `[from → to]`，启动按序执行。
- 覆盖 `PendingOrderStore` / 商品缓存 / settings 等所有持久结构。
- 损坏/不可解析数据的降级策略：**隔离或重置该键，不得让整个启动崩溃**。

**验收/测试**：构造旧 schema 数据 → 迁移到当前版本断言；注入损坏数据 → 走降级不崩。

---

## 实施优先级（按 ROI）

| 序 | 项 | 理由 |
|---|---|---|
| 1 | §3 架构 lint 强制 | 守护模板初衷，写一次全项目继承 |
| 2 | §2 生产可观测性 | 支付 App 的生产硬底线 |
| 3 | §1 时钟偏移 | 低成本、防一类线下不可复现的致命故障 |
| 4 | §4 隐私清单 | 不做直接拒审，硬门槛 |
| 5 | §7 数据迁移 | 防存量升级崩溃，越早植入越省事 |
| 6 | §5 RTL / §6 减弱动态 | 已发布 ar + 重动画 UI 的必修，可并入 ui_kit 阶段 |
