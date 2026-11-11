# Songlet 交付自审 · MV 模块阶段二（2026-09-30）

- **范围**：音乐 → MV 模块阶段二（已确认方案的 A–G 七步），以工作区当前状态为准（未提交）。阶段 0–7 的既有结论见 `delivery-audit-20260924.md`，本文只审本次改动及其对既有部分的影响。
- **方法**：结论以源码与实跑结果为准；每条给出证据路径或命令。写了但没跑通的，按没跑通算。
- **结构**：沿用上一份审计的七层定义与四档判定（A 可交付 · B 有条件可交付 · C 需返工 · D 不可交付）。

## 总判定：B · 有条件可交付

七层中 4 层 A、3 层 B，无 C/D。条件全部属于**验证环境或外部依赖**：
1. 模拟器实跑（`make integration`、`make acceptance`）在本机控制台锁屏后无法渲染，新增的集成步骤与 XCUITest `test09` 已编写并编译通过，但未跑完（见 L6）；
2. 真机 + App Store Connect 沙盒的 MV 包购买（手工清单第 5 项）；
3. 平台仓对契约缺口 G1–G9 的评审（`docs/songlet/backend-contract.md` §7.1），客户端均已按"可选、缺席即关闭"实现；
4. P19–P30 无原型，按 PRD 第 15 章推导（ADR-0027），原型到位后补还原度打分。

没有已知需要返工的缺陷。执行中发现并修复了 1 个真实缺陷（L3 第一条）。

## 完成标准逐条核对

| # | 标准 | 判定 | 证据 |
| --- | --- | --- | --- |
| 1 | `flutter analyze` 零告警 | ✅ | `flutter analyze` → No issues found；`dart analyze tool mock_server` → No issues found |
| 2 | `flutter test` 与 `integration_test` 全部通过 | ⚠️ | 单元/组件/golden 全绿：app 729 · 包 773 · mock 84；`dart run arch_guard` 0 违规。集成测试已扩展到"歌词视频 → 副歌 MV（额度不足 → 服务端授予 → 继续）→ 播放 → 分享"，本次会话内实跑到歌词视频阶段并借此发现了 L3 的缺陷；修复后在锁屏环境下无法再跑完（`CGSSessionScreenIsLocked = Yes`，模拟器不出帧，`delayForFrameTimings` 挂起） |
| 3 | `xcodebuild` release 成功 | ✅ | `flutter build ios --release --no-codesign` → `Runner.app`（24.6 MB）；用临时 `config/prod.json`（dev 值 + `ENV=prod`）满足构建期校验，结束后删除并把 `Generated.xcconfig` 恢复为 mock |
| 4 | mock 模拟器流程：完整歌 → L2 → L3 发起 → 进度 → 播放 → 分享 | ⚠️ | 同第 2 条：流程由 widget 测试逐页覆盖（`test/pages/mv_test.dart` 45 例，含"歌词视频 → 再做一个 → 副歌档可发起"整链）与 mock 契约测试覆盖；模拟器端到端待解锁后重跑 |
| 5 | 创作开关自动 L2 + 升级入口 | ✅ | `AutoVideoCoordinator`（`packages/songlet_kit/lib/src/mv/application/auto_video_coordinator.dart`）；`test/mv/auto_video_coordinator_test.dart` 7 例（一次且仅一次、重启续做 L2、Premier 倒计时、取消、重启丢弃副歌、拒绝、与手动副歌并发）；P23 横幅与升级入口 `mv_test.dart` P23 组 |
| 6 | 沙盒 `QUOTA_EXHAUSTED` → 自动购买 → 自动重试，不双扣 | ⚠️ | 逻辑 ✅：`mv_controller_test.dart`（同 `client_ref` 重试、0/2/5 s 有界重试、60 min 换 ref、启动续做、业务拒绝清意图/传输失败保留）；P22 页面测试以脚本化 `IapPurchaseOrchestrator` 验证购买完成即重发同一请求；mock 契约测试"差额 → 购包 → 同 `client_ref` 受理，只扣一次"。真实 StoreKit 沙盒为手工清单第 5 项（模拟器拒绝为 XCUITest 启动的 App 提供 StoreKit Testing，既有已知限制） |
| 7 | 分段拦截 UI 与退额正确 | ✅（按 D-2 定义） | P25：拒绝照片 → 退回积分 + 照片数 + "调整照片后重新发起"（新 `client_ref`）；mock `fail_next IMAGE_REJECTED` 在首个渲染段失败并全额退回（`contract_extensions_test.dart`）。逐段重试/跳过为契约缺口 G4 |
| 8 | 后台 → 前台恢复 | ✅（模拟器路径）/ ⚠️ 真机 | 启动与回前台恢复 pending 视频（`StartupGate`）、ETA 本地通知与点按路由（`MvNotificationBinding`，`mv_test.dart` notifications 组）、进度页按 id 订阅（ADR-0021）；真机后台行为未测 |
| 9 | 12 语言 ARB 完整 | ✅ | 13 个 ARB，新增 42 键、删除 4 个不再使用的键；`test/l10n` 13 例全绿 |
| 10 | P19–P30 golden | ✅ | `test/goldens/pages/P19–P30.png` 逐张目检；原 P19/P20/P21 改名为 P20/P24/P26；P02a 因新增两行按预期更新 |
| 11 | 设备矩阵通过 | ✅ | 34 页 × 6 设备 × {默认, AX5} = 408 例无溢出；P09 的三张 iPad 审阅 golden 因视频入口卡进入视口按预期更新 |
| 12 | 仓库 grep 干净 | ✅ | `grep -rnE "T[O]DO\|F[I]XME\|H[A]CK\|X[X]X\|UnimplementedError"` 覆盖 lib、packages、mock_server、ios、测试、tool、ADR：0 命中 |

## L1 产品与合规 — A

- ✅ PRD 第 15 章流程完整：入口（P19）→ 三档估价（估价即锁歌）→ 额度不足直购并自动重试 → 真实进度与取消两种结果 → 成片、分享、相册、文件 → 失败文案与重试。
- ✅ AI 标注：角标由服务端烧录，播放页再次显式标注；分享文案不变。
- ✅ 照片只作风格参考（文案 "faces aren't used"），客户端无人脸审核代码；供应商拒绝走 `IMAGE_REJECTED` 并退回。
- ✅ 付费墙：MV 包独立成组、为视频打开时置顶并预选；Premier 权益只说明"额度也可做视频"（不上调发放量，PRD X-56）；不在付费墙写积分数。
- ✅ 地区只影响文化偏好，未新增任何客户端地区拦截。

## L2 表现层 — B

- ✅ 新组件 `MvLevelCard`、`InlineProgressBanner`（ui_kit，浅/深/RTL golden，AX 尺寸堆叠，减弱动效下不播放不定进度条）；其余全部复用既有组件与令牌。
- ✅ 播放器 P26/P27：深色、全屏（路由挂在根导航之上，盖住标签栏）、横屏/iPad 侧栏布局。
- ✅ `PackRow` 补上辅助功能字号的堆叠布局（AX5 下在额度弹层中溢出 47 pt，付费墙同样受益）。
- ⚠️ P19–P30 没有原型（ADR-0027）：`make diff-report` 第 4 节列出这些页并把截图放进 `docs/ui/diff/`，原型到位后自动纳入打分。既有 5 项还原度偏差与上一份审计相同，无新增。

## L3 应用层 — A

- ✅ **执行中发现并修复的缺陷**：视频提交后 `MvWaiting` 被视为"忙"，渲染期间中心页既不能估价也不能发起其他档，从播放页"再做一个"回到中心页时按钮永远不可用（集成测试实跑暴露，widget 测试复现）。修复：只有估价与准备阶段算忙；提交后的视频交给 runner，会话只在仍"跟随"该视频时写入状态；取消改为按视频（ADR-0021）。回归测试：`mv_test.dart`"歌词视频 → 再做一个 → 副歌档可发起"、`mv_controller_test.dart`"渲染中可再估价并发起另一支"。
- ✅ 路由：`MvRoute(workId, level?, from?)`、`MvGenerateRoute(workId, videoId)`；旧版无 id 的进度链接落到中心页；深链与通知共用同一解析。
- ✅ 额度弹层打开付费墙期间忽略购买事件，避免重复关闭。
- ✅ 自动视频协调器的状态变更延后到微任务，避免在页面构建期间修改 provider。

## L4 领域与数据 — A

- ✅ 作品库 v4 迁移（ADR-0028）：`music_videos` 六列、`works.auto_video`；迁移只补缺列，v2→v4 与 v3→v4 均有测试。
- ✅ `MvIntent` 持久化（`KeyValueStore`，损坏记录读作缺席）；`MvSource` 本地记录，线上发送由 `MvRequest.sendsSource` 统一开关（缺口 G6）。
- ✅ `SongletEntitlement.creditsAvailable` 可选解析（缺口 G5）；MV 包分档积分（T1/T2/T3，PRD §15.4）仅作提示，账本以服务端为准。
- ✅ 删除作品级联删除其视频记录与文件，并放弃仍在轮询的运行。
- 📌 方案中的 `credits_refunded` 列未实现：终态 `balances` 只有歌曲/片段数，无法不做客户端算账地得出退额；P25 只陈述平台已退回的数额（ADR-0028）。
- **外部依赖**：`backend-contract.md` §7.1 的 G1–G9 待平台仓评审。

## L5 平台与原生 — B

- ✅ 新侧信道 `songlet/notifications`（+ `/events`），`NotificationService.swift`，无推送、无新权限说明、无 Required-Reason API；Pigeon 接口未改动。
- ✅ 模拟器 debug 构建、`build-for-testing`、release 构建全部通过。
- ⚠️ 本地通知的真机行为（授权弹窗时机、锁屏点按冷启动路由）未在真机验证。

## L6 验证 — B

- ✅ 单元/组件/golden：app 729 · 包 773 · mock 84，全部通过；新增测试覆盖意图存储、v4 迁移、runner 快照总线与放弃、估价并发、有界重试、启动续做、按视频取消、通知、自动视频、并发两路径、全部新页面各状态、泄漏（MV 流程 0 未释放对象）。
- ✅ mock 契约：新增"差额购包后同 `client_ref` 受理且只扣一次""照片在首个渲染段被拒、全额退回"。
- ⚠️ 集成测试与 XCUITest `test09_mvQuotaPurchaseRetry`：已编写、编译通过；因控制台锁屏未能跑完。解锁后执行：`make mock` 然后 `make integration SIM=<udid>`、`make acceptance SIM=<udid>`。
- ⚠️ 性能：MV 播放器帧时间与首帧需真机 `make perf`（既有条件）。

## L7 交付与可维护 — A

- ✅ ADR 0021–0028 与索引；ADR-0020 追加修订节。
- ✅ `docs/ui/inventory.md` 增加 P19–P30；`backend-contract.md` §6 mock 控制与 §7.1 缺口表；`acceptance.md`（test09、手工清单第 5 项、本次未跑说明）；`performance.md`；`mock_server/README.md`；`CLAUDE.md`（MV 架构、侧信道、页面与 ADR 范围）。
- ✅ 分层：`arch_guard` 0 违规；UI 未新建 provider；无代码生成。

## 与已确认方案的差异（均为执行中的必要调整，已记入 ADR）

| 项 | 方案 | 实际 | 理由 |
| --- | --- | --- | --- |
| 通知端口命名 | `NotificationScheduler`（`native_gateways.dart`） | `LocalNotifications`（`platform/domain/local_notifications.dart`） | 仅命名与文件位置（ADR-0025） |
| `credits_refunded` 列 | 新增 | 未加 | 无法从服务端数据得出（ADR-0028） |
| 删除作品时的视频 | 级联删除 | 级联删除 + 放弃本地轮询，不向平台发取消 | 删除不等于取消请求（ADR-0021） |
| `MvWaiting` 忙碌语义 | 未涉及 | 提交后不再算忙 | 修复中心页被锁的缺陷（ADR-0021） |
| 播放器路由 | 页面内 | 根导航之上 | "竖版全屏"，标签栏会挤压面板（ADR-0027） |
| Premier 自动副歌的 `source` | 未涉及 | `library` | 任务只给三个取值（ADR-0022） |
| 额度页"继续" | 显示弹层 | 先向平台问一次，仍不足才弹 | 购买可能在别处完成 |
| diff 报告 | 标"无原型" | 新增第 4 节列出并存截图 | ADR-0027 |
| mock `fail_next` | 分段失败 | `IMAGE_REJECTED`/`SAFETY_BLOCKED` 落在首个渲染段 | 让 P25 可在 mock 上重现 |

## 需要知会的事项

- 解锁本机后重跑模拟器验收与集成测试（命令见 L6），结果补记到本文件。
- 把 `backend-contract.md` §7.1（G1–G9）交平台仓评审。
- 原型 `docs/ui/P19–P30.png` 到位后运行 `make diff-report` 补打分。

## 补记（2026-10-01）· 契约 02 v1.2 / v1.3

- **v1.2 `inspirations[]`（新功能，已交付）**：创作首页「灵感」区（ADR-0029）。一次 `/templates` 请求同时供模板示例与灵感使用（`RemoteTemplateCatalog`）；缺字段或请求失败即不显示；条目缺必填字段或试听 URL 非绝对 http(s) 时剔除；试听按其绝对 URL 下载播放（从不拼 `BASE_URL`），缓存以 URL 的 UUID v5 为键，平台换自有存储（ADR-S12）后自动取新音频；点按有 `linked_template_id` 进模板，否则以 `style.en` 预填提示词；英文/简体取服务端，繁体及其余 10 种语言以英文文案为键查本地表（ARB 键按 slug 命名），未知条目回退英文。新组件 `InspirationCard`（浅/深/RTL golden），新页面 golden `P01-inspirations`，设备矩阵覆盖；mock 内置产品仓 24 条种子与 `inspirations_enabled` 开关。
- **v1.3 `credits_available`**：无需改动（缺口 G5 在 `backend-contract.md` §7.1 标为已解决）。平台所引两条宽松解析单测位于 `entitlement_remote_impl_test.dart` 第 53 行（`null`）与第 55 行（字符串 `"66"`），与平台所述一致，本次未移动。
- **环境**：`config/dev.json` 的 `BASE_URL` 仍指向平台域名，应改为产品 BFF `https://genaistudio-products.showsapp.org/v1`（`dev.example.json` 已正确；该文件含密钥，未代改）。
- **验证**：`flutter analyze` 零告警；`arch_guard` 0 违规；app 840 · 包 783 · mock 85 全绿；ARB 13 种语言完整性、描述与德语长度预算通过。模拟器端到端与 XCUITest 仍待解锁后重跑（见上文 L6）。
