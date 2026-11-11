# ai_studio ASO 工程复盘与跨项目复用验收

审计日期：2026-10-13。本次范围是公共工具、初始化、契约、失败保护及独立样例；不重新设计 ai_studio 营销业务。

## 证据与边界

- 完整阅读 `asset-library-playbook.zh-CN.md`，核对模板代码、历史提交、应用配置、忽略目录内现存回执和本地输出。
- 初始模板 HEAD 为 `4ff6de46b40a916083c571b48552f0ba6e32a882`；应用 HEAD 为 `4d575b6`。
  应用已有未提交的业务审计修改，本次不归因、不覆盖、不提交。
- 初始公共工具逐文件比对一致：没有发现只存在于 ai_studio vendored 副本中的通用修复。
  原戳记录 `569ab608…` 且 `template_dirty: true`；单看提交号不足以判断漂移，必须比较文件摘要。
- ASOShip 作为本地契约及 validator 使用，其已有未提交审核占用修复保留；本次不修改其代码。
- 全程未执行 ASC 查询、上传、提交审核、发布或实际展示变更。没有把邮件或旧回执当作当前审核状态。

模板历史证据包括：`e6bd64d`（CPP 有序设备截图）、`111d235`（货架本地化过滤和初始化输入检查）、
`96b9883`（原生工具并发构建）、`5cedf3c`（shelf 声明）。这些已有能力不重复实现。

## 实际交付经过的可还原部分

应用本地证据目录为 `listings/com.gemini.ai/.ascpub/delivery/3.0.4/`（忽略目录，不向公共模板复制账户回执）。
主要证据索引：

| 记录 | 可以证明的事实 | 不能据此推断 |
| --- | --- | --- |
| `delivery-summary.json`、`asset-library-after-fix.log` | 历史交付 250 项创意素材，曾通过本地校验 | 当前文件仍是原件、当前远端已展示 |
| `ascpub-cpp-complete-fix.patch`、`cpp-fix-validation.json` | CPP 内联关系及可见性问题的实际补丁和当时测试 | 需要在 store-preview 再写一套 API 实现 |
| `add-for-review-apple-errors.json`、`add-for-review-summary.json`、`add-for-review-tool-validation.json` | 当时审核添加失败及 200/50 两组实际处理记录 | Apple 永久固定批量上限、Add for Review 等于最终提交 |
| `cpp-production/application-review.json`、apply/readback 记录 | 客群文案和 listing 应用曾独立修复、读回核对 | 每次素材重录都已获用户认可 |
| `cpp-production/local-artifact-drift.json`、`asset-library-current.log` | 67 个当前文件已偏离原交付清单 | 重算哈希即可恢复原交付 |
| `version-text/whats-new-local-validation.json` | 版本文本曾做本地校验 | 当前版本已经发布 |

250 项为 225 图片 / 25 视频，覆盖默认页、3 个 CPP 及 PPO 候选，共 25 个语言。
后续扩展截图录制曾被停止，额外录制目录被归档；本地原输出已有部分覆盖。
原始视频 take 目录目前缺失。全部真实业务 `real_ui` 为 false，没有可借用的人工复核记录。

## 公共整改

逐项触发条件、现象、根因、修复层、影响范围和回归测试统一见
[故障知识库 R01–R11 / H01–H04](asset-library-troubleshooting.zh-CN.md)。

| 状态 | 内容 |
| --- | --- |
| 已修复 | locale 去重与映射；歧义 Bundle 必须选择；listing 归属与路径转义；初始化全部预检后写入 |
| 已修复 | `integrate` 接入 workspace / 开发依赖 / Makefile；既有字段保留、冲突报错、重复无变化 |
| 已修复 | vendor 源/目标隔离、完整性、漂移与符号链接保护；暂存、摘要校验、失败回滚 |
| 已修复 | vendor 摘要排除 Flutter 插件生成文件；旧 stamp 完整验证后迁移，干净 Git 检出可复验 |
| 已修复 | 旧交付归档、隔离渲染、既有漂移阻断；待人工复核截图不会继承旧清单 |
| 已修复 | `real_ui` 绑定实际文件 / EDL / 海报；manifest 核对应用身份、完整 ID、locale、用途和人工依据 |
| 已修复 | 默认录制设备按 Bundle/App 隔离；清空设备前核对 Xcode SDK / resolved Debug 配置 |
| 已验证无需重复修复 | 模板与应用副本初始一致；原生工具原子构建、take registry、离线媒体服务、有序 CPP 截图等已有实现和测试保留 |
| 已有历史修复，本次不改对应层 | ASOShip CPP/API/审核批次编排；应用营销文案修复；未为本地审计重演远端错误 |
| 未解决 | 67 件原交付素材的原字节缺失；本次比对暂停归档中 67 个同名候选，匹配原 SHA 数为 0 |
| 未重现远端、不能标记完成 | 当前 Apple 审核/展示状态、审核占用是否已解除、实际转化提升；本次没有远端授权与观测 |

所有通用代码先在模板的隔离 worktree 修改并测试，再回到公共检出；业务仓只通过 vendor 接收。
新增架构决策为 ADR-0016，补强 ADR-0011 的人工复核证据约束，不引入第二条生产工具链。

## 自动化验证证据

原模板 147 项既有测试通过；首轮公共工具 174 项通过，新增 27 项并扩展已有渲染/录制断言。
两公共包静态分析 0 问题。将 4 个故障用例放回原 HEAD 后，4 项全部失败；新实现中全部通过，
分别证明 locale 重复、歧义 Bundle、两种初始化的晚期 ARB 部分写入确实存在。

提交前补充检查发现 R11：125 个 vendor 文件中包含一个未被 Git 跟踪的 Flutter 生成文件，
只恢复暂存区文件后，旧 `vendor --check` 可复现失败。新增 3 项回归后，全量 177 项通过，
静态分析仍为 0 问题；累计新增 30 项。旧实现上的新用例失败记录与提交复核结果另存为
`vendor-metadata-baseline-red.log`、`template-commit-tests.log` 和 `commit-readiness.json`。
首轮验收快照 `summary.json` 保留当时的测试数量和 stamp，最终来源以应用的 `VENDOR.json` 为准。

模板仓 `docs/store/verification/2026-10-13-reuse/` 保存脱敏命令日志、逐文件漂移表、证据索引及最终验收摘要。
历史回执只列出处，不复制认证信息。日志中的本机用户名和检出路径已替换为占位符。

## 冷启动验证

独立应用 `reuse_notes` / `org.example.reuseNotes` 使用自己的笔记 UI、两种语言、清单和置顶操作。
从 `flutter create` 开始，实际执行 vendor → integrate → pub get → new-app → new-creatives → ARB →
shelf → listing → 真正的 iOS 模拟器录制 → render → make asset-library。目录包含空格。
没有使用 ai_studio 的业务配置、录像、深链或素材。可重复的输入和命令见
[复用手册 §5](asset-library-reuse.zh-CN.md)。

实际结果：2 份 15 秒预览、10 件 Header/Search/CPP/PPO 素材通过技术校验；
`make asset-library APP=reuse_notes` 成功，ascpub assets/cpp/ppo 本地校验 0 个错误。
`real_ui` 全部保持 false。保留规格快照及实验干扰提示，未把警告删除来换取“零错误”。
重复运行 integrate/listing/creatives：listing 文件及 manifest entries 均不变；上一交付归档 21 个文件哈希全部匹配。
独立进程持有渲染锁时，`manifest` 返回 1 并提示占用；释放锁后返回 0。

冷启动还真实暴露两项准备问题：

1. Flutter 新建项目 iOS 13 与本机 SDK 最低 iOS 15 不兼容。公共前置检查现在在录制前报错；
   样例自行选 iOS 15，未修改 ai_studio 部署策略。
2. 样例初次补入 l10n.yaml 后漏开 Flutter generate。修正样例 pubspec、flutter_localizations/intl 和 ARB UI；
   这是测试应用准备错误，不宣称为 ai_studio 曾发生的故障，也不让 ASO 工具偷偷改业务本地化配置。

## ai_studio 验收限制

原清单 SHA-256：`f17d9a5a4601825d25f6d7d4453c330bcc24d53fd3554c75c946f9f357189e03`。
例如 `cpp.product-marketers.header.en-US`：

- 原清单：`29176708f818ee8bb3d3daca3061cc1121108969010baa47706088b8b8318862`
- 当前文件：`2a40f9b480f3501a2c930eb815a254cc35924a4c36219268cc716476f4e4b45e`

该问题在本次改动前已存在。没有运行新的业务素材录制/渲染，没有改写原清单或重新登记上传状态。
本次 ascpub assets 校验为 134 个错误（67 个 SHA-256 + 67 个大小不符）；CPP 和 PPO 本地校验 0 错误。
三个任务仓的 1612 个候选媒体文件中，没有任何文件大小匹配这 67 个原件，暂停归档同名文件也不匹配。
因此不能把 ai_studio 的素材 gate 或 ascpub 全量校验标记为通过；公共修复阻止继续扩大损失，不能凭空恢复原件。
后续必须提供匹配原 SHA 的本地备份，或单独决定重新生产并重新验收一版明确不同的新交付。

业务静态分析通过。现有 Flutter 测试为 178 通过、4 个 GenerateBar golden 失败；失败分别是
member dark/light/ru 与 non-member dark，保留原 golden，没有更新基准掩盖差异。
本次的完成口径是公共能力与独立复用验证结果、加上明确列出的既有阻塞，**不是 ai_studio 全部交付门槛已经通过**。

## 下一项目减少的重复工作

六处人工接线变为一个可预览、幂等的 `integrate`；locale/Bundle 排错变为前置约束；
初始化清理、vendor 丢失局部补丁、重录覆盖原件等问题由回归测试守护。
手工复核、产品文案、授权与深链判断仍保留在人和应用层。
详细命令、证据映射和限制见 [可执行操作流程](asset-library-reuse.zh-CN.md)。
