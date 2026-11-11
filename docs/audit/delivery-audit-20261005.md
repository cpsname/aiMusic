# Songlet 交付自审 · 首页作曲栏三态重构（2026-10-05）

- **范围**：首页作曲栏（P01 / P03）重构，已确认方案的 A–F 六步，分支 `feat/composer-three-states`（7 个提交，见文末）。只审本次改动及其对既有部分的影响；既有结论见 `delivery-audit-20260930.md`。
- **方法**：结论以源码与实跑结果为准，每条给出证据路径或命令；写了但没跑通的按没跑通算。
- **判定档**：A 可交付 · B 有条件可交付 · C 需返工 · D 不可交付。

## 总判定：A · 可交付（附一项未实跑：XCUITest 验收）

完成标准 9 条全部满足。唯一没有实跑的是 XCUITest 验收（`make acceptance`）：它把 mock 管理端写死在 `:8787`，而本机 `:8787` 上的 mock 属于另一个会话的演练（`--profile demo`），重置它会破坏那边的工作。Swift 改动已做语法检查，但未跑（见 L6）。

执行中发现并修复了 4 个真实缺陷，都是既有问题被这次的流程暴露出来的，详见 L3。

## 完成标准逐条核对

| # | 标准 | 判定 | 证据 |
| --- | --- | --- | --- |
| 1 | `flutter analyze` 零告警 | ✅ | `flutter analyze` → No issues found（app + 全部包 + integration_test）；`dart run arch_guard` → 0 违规 |
| 2 | `flutter test` 与 `integration_test` 通过 | ✅ | app 1105 · ui_kit 125 · songlet_kit 410 · commerce_kit 122 · infra_core 107 · media_kit 27 · app_config 18 · mock_server 86，全绿；`integration_test/first_session_test.dart` 在 iPhone 17e 模拟器（iOS 27.0）上运行，对接独立 mock（`:8788`）与独立 worktree：`00:48 +1: All tests passed!` |
| 3 | integration 证明「选模板 → 填名字 → 点按钮」三步内发起生成，且请求体正确 | ✅ | 测试对交互计数并断言为 3；读取 mock `/__admin/state` 中 mock 实际收到的请求：`model=lyria-3-clip-preview`、`occasion=birthday`、`template(=inspiration)=birthday_wish`，`prompt` 首行为 `inspiration: birthday_wish`，含 `recipient: Alex`，无 `description:`，`vocals` / `lyric_language` 各一行，无歌词、无图片。报告：`open_to_first_listen_ms 7107` |
| 4 | 作曲栏默认 ≤ 35%、展开 ≤ 55% 屏高，网格至少露出一行（设备矩阵 golden 验证） | ✅ | `test/pages/composer_layout_test.dart` 48 例 = 6 台设备 × 4 种状态（A、B、A 上的 C、B 上的 C）× 键盘收起/弹出，逐例量测：卡片高度、网格视口内至少一张完整瓦片、键盘上沿、主按钮可点、模板头可见、iPad 不重叠、展开时选择器可见；矩阵审阅 golden 新增 `P01-options`、`P01-picked`、`P01-keyboard`、`P03-options`、`P03-keyboard`，共 68 张，逐张看过 |
| 5 | 首页不再有 Music 芯片、Preview/Full 分段、发送箭头 | ✅ | `create_home_test.dart`「removed: …」：作曲栏内找不到 `SegmentedToggle<SongModel>`、"Music"、"Full"、`Icons.arrow_upward_rounded`，只有一个 `ObsButton`；ui_kit 中 `SourceChip`、`ComposerActions` 已删除（`SegmentedToggle` 仍被 MV hub 使用，保留） |
| 6 | 13 个 ARB 键集合一致 | ✅ | `test/l10n/arb_completeness_test.dart` 全绿：13 个文件各 734 键（新增 14、删除 10、`lengthFull` 改值），占位符、描述、德语 ≤ 1.4× 规则均通过；de / hi 的本地化 golden 已更新 |
| 7 | 仓库 grep 不到待办 / 修复 / 权宜标记 | ✅ | `git grep -nE "T[O]DO\|F[I]XME\|H[A]CK" -- ':!*.png' ':!*.jpg'` → 本次改动 0 命中（其余命中仅为审计文档中引用该检查本身的文字） |
| 8 | 更新 docs/ui 的 P01、P03 页面说明 | ✅ | `docs/ui/inventory.md`：P01（三态、空间规则）、P02a、P03（B 态与深链）、P03a、P18、P28 段落，以及表格备注 |
| 9 | 更新 PRD 4.1 的作曲栏描述 | ✅ | `docs/design/songlet-prd.md` 新增 §4.1「首页作曲栏」（原 PRD 无 4.1，按 D7 新增） |

## L1 产品与合规 — A

- ✅ 首个会话 3 个决定（瓦片 → 名字 → 主按钮），由 widget 测试与集成测试共同证明。
- ✅ 主按钮的 "free" 只在账本显示有免费额度时出现（ADR-0035）。账本为 0 或未知时不显示任何花费，不做虚假的免费承诺（ADR-0031）。没有额度时照常提交，由服务端返回 `QUOTA_EXHAUSTED`，再按 `offer` 打开付费墙。
- ✅ 选卡后从 Preview 开始（ADR-0036，对应 PRD §3.1 / §8.2）。
- ✅ 契约不变：仍是契约 02 v2.1 的八个字段，场景以 slug 发送（mock 侧断言）。

## L2 表现层 — A

- ✅ 三态共用一份草稿。A / B 由草稿推出，C 用路由参数 `?options=1`，可深链，弹层关闭后回到 C。
- ✅ 复用组件：`ObsButton`、`ParamChip(value:)`、`LyricsEditor`、`KeywordChipInput`、`ComposerTag`、`MetaLine.join`、`showAnchoredPanel`。只新增一个组件 `ComposerSummary`（库中无同类）；`CoverFallback` 从 `TemplateTile` 中抽出，供模板头复用。
- ✅ 令牌：新增 `SongletMotion.state = 200 ms`（D3），曲线用 `emphasizedCurve`，减弱动态效果时无动画；页面里没有字面量。
- ✅ 键盘：已读 Flutter SDK `scaffold.dart`（`contentBottom`、`removeBottomInset`），确认 shell 会把页面整体抬到键盘之上。页面在 `LayoutBuilder` 内读取视图的 inset，因为这里会随 resize 重建。
- ✅ AX5：设备矩阵扫描 40 个页面状态 × 6 台设备，无溢出；修复了一处潜在问题：锚点在低处时，`AnchoredPanelBody` 的页脚现在随内容滚动。

## L3 应用层 — A（发现并修复 4 个缺陷）

1. **付费墙外到账后卡住**（`main` 上已存在，集成测试第 9 步因此一直失败）：ADR-0031 去掉客户端闸门后，只有在付费墙内完成购买才会重试；服务端授予、稍后批准这类到账方式会让被拒的歌停在失败页。修复：付费墙关闭后重读账本，额度足够就继续生成（`generating_page.dart`，ADR-0035）。`generating_test.dart` 覆盖两个分支和一次真实链路。
2. **过早的额度拒绝不弹付费墙**：拒绝如果在生成页挂载前到达，页面只监听状态"变化"，因此会错过。修复：挂载后检查一次当前状态。
3. **构建期间 setState**（从预览页生成完整歌时触发）：生成控制器使 library / 钱包失效后，第一个读到它们的 widget 在 build 中触发重建，其它监听者因此在帧中途刷新。修复：由控制器在自己的异步流程里立即重建（`refreshLibrary`、`_refreshLedger`）。iCloud 同步保持惰性，否则会与 library 的构建形成循环（已验证并回退）。`create_pick_test` 断言整个流程中无异常。
4. **AX5 下锚定面板溢出**：见 L2。

## L4 领域与数据 — A

- ✅ `CreationDraft.forSubmit()` 是"只发送显示内容"的唯一入口，规则逐条有测试（`prompt_block_test.dart` forSubmit 组）。
- ✅ `pickInputRequired` 的写法与 `pickRequiresRecipient` 一致；`draftFromWork` 在补做完整歌、"再来一版"时重放卡片的 Your words（`draft_codec_test.dart`）。
- ✅ `Preflight.screen(text)` 把艺人名问题对到具体字段，`check()` 复用它，结果不变。
- ✅ 纯模型 `CreateAction`、`summaryParts`、`ComposerBudget`、`IdeaGridLayout`（UI 层纯 Dart，不新增 Provider），单元测试 40 余例。
- ℹ️ 旧作品若是"选卡 + 照片"组合（ADR-0032 起一天内可能产生），重放时不再带照片；照片 bid 本身也只有 24 小时有效期，已写在 `draft_codec.dart` 文档注释。

## L5 平台与原生 — A

- 无原生改动。XCUITest 选择器已同步：去掉点 Preview 的步骤，Genre 先展开摘要行再点，照片歌曲先取消已选卡片。

## L6 验证 — A（XCUITest 未实跑）

- **Golden 基线**：本机（macOS 27.0.1）上，`main` 的全部 golden 都因字形栅格化存在 < 2% 的差异（app 100 张、ui_kit 41 张），行为测试则全部通过。为此先用 `main` 的原始代码单独做了一个重录提交 `a3983df`（只含 golden），本分支建立在它之上，所以本分支的 golden 变化只反映本次改动。CI runner 字体若不同，需要另行确认基线。
- **集成测试**：在独立 worktree、独立 mock（`:8788`）和一台空闲模拟器上运行，没有动你的 `config/mock.json`、另一个会话的 mock，以及其它会话已启动的模拟器。为保证稳定性对测试本身做了这些调整：
  - 断言与界面语言无关（模拟器默认中文）；
  - 引擎不上报帧耗时时（无头模拟器可能如此），仍执行滑动，并在报告里写明，而不是无限等待；
  - 滑动超过 30 秒预览、预览结束自动弹出付费墙时先关闭它；
  - 分享按钮在小屏上位于首屏之下，先滚动到它；
  - 额度弹层的购买按钮依赖 StoreKit 能解析商品（裸模拟器解析不到），改为等待弹层本身，购买仍由服务端授予。
- **未跑**：`make acceptance`（理由见总判定）。合并前请在 `:8787` 空闲时运行 `make mock` 与 `make acceptance SIM=<udid>`。
- **还原度报告**：`make diff-report` 的结果与 `main` 一致，仍是那 5 项既有偏差（`accentSoft`、P02 / P10 / P11），本次没有新增。P03 新增一条豁免（gutter，理由写入 ADR-0033）。

## L7 交付与可维护 — A

- ✅ 每步一个提交，便于单独回滚。差异：A、B 两步提交时 app 的 widget 测试 / golden 尚未更新，它们要到 C 才能写；那两个提交的门槛是包级 analyze / test 与 arch_guard，从 C 开始全量门槛全绿。
- ✅ 文档：ADR-0033–0036 与索引（ADR-0015 标为被 0033 取代）、`CLAUDE.md` Create home 段落与测试清单、`docs/ui/inventory.md`、PRD §4.1、`docs/perf/performance.md`、`docs/songlet/acceptance.md`、`tool/diff_report/config.json`。

## 与已确认方案的差异（均为执行中的必要调整，已记入 ADR 或本文）

| 方案 | 实际 | 原因 |
| --- | --- | --- |
| 主按钮文案用 `{action} · {cost}` 拼接 | 三个 ICU `select` 键保存整句 | 德语 ≤ 1.4× 规则（"free" → "gratis" 超长），且整句能适配各语言语序 |
| 主按钮可用条件里歌词只算选卡态 | 自由输入时自写歌词也算"可生成" | 选项区在 A 态也有歌词，服务端规则允许 |
| 删除语音的关键词 / 歌词动作，保留领域 API | 一并删除 `TranscriptUse` 与 `keywordsFromTranscript` | 已不可达，留下即死代码 |
| — | 新增 `composerPromptHintWide` | iPad 网格在侧边，不能说"above" |
| — | 新增 `composerPhotosAttached` | 去掉来源芯片后，"已添加照片"需要有可见、可读的提示 |
| — | 修复 L3 的 1–3 | 集成测试暴露的既有缺陷，不修无法达成完成标准 2、3 |
| — | Golden 重录提交 | 本机 `main` 的全部 golden 已漂移（与本次改动无关） |

## 需要知会的事项

1. **XCUITest 待跑**：`:8787` 空闲时执行 `make acceptance SIM=<udid>`。
2. **CI golden**：基线已在 macOS 27.0.1 上重录；CI runner 的系统字体如果不同，需要在 CI 上重录或固定 runner 镜像。
3. **ADR-0036** 让 `default_model` 不再决定 Length；产品端如果希望某些卡默认完整歌，需要另立决策。

提交：`a3983df`（golden 基线）· `1019808` A · `949962d` B · `aab3c2f` C · `a6adebc` D · `2df12f2` E · `5f36042` F（测试与缺陷修复）· 文档与本审计（本提交）。
