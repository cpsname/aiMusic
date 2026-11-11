# ASO 素材体系故障知识库

更新：2026-10-13。以可复核的代码、测试、日志为依据；远端状态不由本地日志推断。
业务模型与流程以 [主手册](asset-library-playbook.zh-CN.md) 为准。

| 编号 / 证据 | 触发条件与现象 | 根因及修复层 | 防复发与状态 |
| --- | --- | --- | --- |
| R01 / `reuse_regression_test.dart` | 同时有 `zh`、`zh_Hans` 或 `nb`、`no` ARB；生成重复 storefront，或挪威语映射错误 | `new_app.dart` 原来逐 ARB 映射；改为按 ASC locale 去重，优先具体语种，补正 nb/no、da、ms 的模拟器 locale | 测试验证唯一 storefront 与保留原 ARB。已修复；本次旧实现可复现，不冒充历史报错 |
| R02 / 同上 | 最后一个 ARB 损坏，前面 ARB/配置却已被写入 | 初始化边读边写；`FilePlan` 先完成全部解析与规划，再暂存应用，写失败回滚 | `new-app`、`new-creatives` 的晚期错误不留下半份配置；重复初始化拒绝覆盖。已修复 |
| R03 / `integration_test.dart` | 已有 App 无 workspace、开发依赖或 Makefile 目标，需多处人工接线 | 新增现有 CLI 子命令 `integrate`，复用 YAML 编辑器和 `FilePlan`，不建立第二条工具链 | 计划 / `--write` / `--check`，重复无变化；SDK 不满足、依赖/目标冲突整体失败。已修复 |
| R04 / `vendor_protection_test.dart` | 同目录 vendor、嵌套目录、源文件缺失、目标副本已改动或后续目录无法写入 | 原复制/替换缺少完整前置保护；模板内预检、摘要校验、分组替换与异常回滚 | 源文件不删除，业务文件不变，不覆盖未回灌修复。已修复；没有证据表明 ai_studio 曾遇到全部这些失败 |
| R05 / `reuse_regression_test.dart` | 多个 Bundle ID 时选错首项；引用另一 bundle listing；YAML 路径含 `: ` | 原初始化默认取第一个 ID，缺少 listing 归属检查，字符串未转义 | 多 ID 必须显式选择；核对 listing 目录及 base.yaml；路径用 JSON 字符串表示 YAML 标量。已修复 |
| R06 / ai_studio 原清单与 `cpp-production/local-artifact-drift.json` | 新录制覆盖 67 个已有素材；原上传清单与本地文件不符 | 固定输出目录直接覆盖，旧清单虽保留但旧字节未完整归档 | 隔离渲染、旧交付归档、哈希漂移阻断；`creative_release_test.dart` 验证。机制已修复；历史原件未恢复，验收仍失败 |
| R07 / `creative_release_test.dart`、`creative_render_test.dart` | 定义未变但重录、改文案或 EDL 后，旧 `real_ui` 仍可能被沿用 | 旧复核摘要只覆盖定义，未绑定最终文件 | 人工记录绑定各语言素材 / EDL / 海报哈希；旧格式可读但不能证明新文件。已修复；未将任何真实素材自动标记为 true |
| R08 / `creative_render_test.dart` | 合法 schema 的清单来自另一 App、少了定义中的条目，或伪造 `real_ui` | 仅 schema 和单文件校验不能证明整套业务契约一致 | 校验 App/Bundle、完整 ID 集、路径、locale、placement intents、当前人工记录。已修复 |
| R09 / `recording_test.dart` | 两个 App 使用同名默认模拟器；后录制会清空先录制的设备 | 默认设备名仅含机型 | 名称加入 Bundle ID 和 App 配置 ID，显式设备覆盖兼容。已修复；本次代码审计发现，未声称发生过业务数据丢失 |
| R10 / 独立冷启动 Xcode 日志、`simulator_preflight_test.dart` | Flutter 新工程最低 iOS 13，而选中 SDK 支持 15–27；录制准备后才构建失败 | SDK 部署范围与应用配置不兼容，缺少早期检查 | 读取 SDKSettings.json 和 Xcode resolved Debug settings，在清空设备前失败；同样核对实际 Bundle ID。公共前置检查已修复；样例自行选 iOS 15，业务 App 不改 |
| R11 / 提交前 Git 文件快照、`vendor_protection_test.dart` | 本机 `vendor --check` 通过，但仅恢复 Git 中的文件后失败 | 旧 vendor 将被 Git 忽略的 `.flutter-plugins` / `.flutter-plugins-dependencies` 纳入复制与摘要，生成文件缺失或变化导致误报 | 从复制和摘要中排除 Flutter 插件生成元数据；仅旧摘要完整匹配时兼容迁移，源码漂移仍拒绝。已修复；新增生成、干净检出、旧 stamp 迁移与源码保护测试 |
| H01 / ai_studio `ascpub-cpp-complete-fix.patch` | CPP 创建内联新版本关系返回 409；草稿可见性处理不当 | ascpub CPP API 编排层，历史修复已在 ASOShip | 已验证该层已有实现；本次不改 ASOShip，不复制进 store-preview |
| H02 / `add-for-review-*` 回执和补丁 | 250 件素材不能一次全加入审核；已有 draft 被错误重用 | ascpub 审核草稿编排；历史实际分为 200 / 50 件 | 修复已有代码和测试；200 是本次历史观察，不作为永久 Apple 限额写死在模板 |
| H03 / `cpp-production/application-review.json` | CPP 宣传文本仅是素材短标题；素材已上传但展示位尚未应用 | 文案字段含义混淆，上传与绑定/送审混淆 | ARB 短标题、CPP promotional_text、版本 promotional_text/whats_new 分开审阅；listing 管业务，工具不凭长度伪造营销质量。已验证已有业务修复，本次不重写 |
| H04 / 历史审核占用提示 | Header/Search 素材在独立审核中，App 版本 Add for Review 被阻止 | 同一素材被另一 submission 占用 | 选择随版本审核或独立提前审核；等待获批或经授权调整另一提交。本地校验不解除远端占用；当前远端状态本次未查询 |

## 诊断顺序

1. 先保存原清单、文件哈希、命令退出码和错误日志，再判断问题属于哪一层。
2. `vendor --check` 失败：对比 `VENDOR.json` 与模板，不直接覆盖副本；回灌通用修复后重新 vendor。
   旧 stamp 若包含 Flutter 插件生成文件，必须保留旧副本并验证旧摘要后迁移；缺文件或摘要已变不能凭猜测放行。新 stamp 不再依赖这些机器生成文件。
3. `integrate --check` 失败：查看 `integrate` 的计划。自定义 Makefile 或依赖冲突由应用负责人合并；工具不会猜测替换。
4. 配置失败：核对 App/Bundle、脚本、授权 manifest、ARB、CPP/PPO locales 和已声明的 shelf。
5. 录制失败：看该 take 的 `test.log`、`rec.log`。SDK 不兼容选择适用 Xcode 或评估应用部署策略，不借验收改业务最低版本。
6. 哈希漂移：从 `.releases/<hash>/receipt.json` 或独立备份验证原件，再恢复原字节。没有原件就是阻塞，不能运行 `manifest` 掩盖。
7. 规格或文案不通过：回到定义、原素材、ARB 修正设计并重新生产；校验器只报错，不裁图、拉伸、缩字或静默跳过。
8. ASC 审核冲突：保留完整原始状态与 submission 归属，由 ascpub 或人工处理。没有远端授权时停在本地验收。

## 归档和恢复边界

`.releases` 是同机恢复来源，不替代异地备份。`receipt.json` 逐个绑定旧清单、素材、海报、EDL。
已有归档被修改、缺文件或与当前证据冲突时停止，保留现场。恢复应整套匹配，不从不同代际拼接。
进程内异常会回滚文件替换；当前实现不承诺断电时跨多个文件的原子事务。断电后应先验证原目录及归档再继续。
源录像仍由 take registry 管理；仅恢复图片/视频并不能重新录制缺失的来源。

## 修复应落在哪一层

- 模板 `packages/store_preview`：配置、录制/渲染、证据、初始化、vendor、离线契约。
- 应用：真实交互步骤、素材授权、文案、受众、已实现的深链、购买披露和客户端最低版本策略。
- ASOShip：ASC API、凭据、上传/审核/展示位应用、截图集合顺序及远端读回。本次只作为契约与本地校验边界。

深链必须同时有客户端入口、路由行为和注册证明。内部 `/home` 不是可对外投放的 URL；没有已验证入口就留空，不能发明 scheme。
