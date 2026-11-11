# 下一款 IAP 应用的 ASO 素材接入与验收

本流程只做本地生产与验收。上传、送审、实际展示变更另行授权。
主契约见 [主手册](asset-library-playbook.zh-CN.md)，故障依据见 [知识库](asset-library-troubleshooting.zh-CN.md)。

## 1. 接入公共工具

先设置 `TEMPLATE_ROOT`、`APP_ROOT`、`ASCPUB_ROOT` 为各自检出目录，`APP_ID` 为录制配置名称，
`BUNDLE_ID` 为 iOS 工程真实标识。变量使用项目自己的路径，不提交本机绝对路径或凭据。

```sh
cd "$TEMPLATE_ROOT"
dart run store_preview vendor --from . --root "$APP_ROOT"
dart run store_preview integrate --root "$APP_ROOT"
dart run store_preview integrate --root "$APP_ROOT" --write
cd "$APP_ROOT"
flutter pub get
dart run store_preview vendor --check
dart run store_preview integrate --check
dart run store_preview new-app "$APP_ID" --bundle-id "$BUNDLE_ID"
```

已有 `store_preview/<app>` 则跳过 `new-app`。不要删除已经确认的配置后重复初始化。
`integrate` 可重复运行，无变化时不写文件；初始化必须先全部解析成功再应用。
workspace 本身要求根 SDK 下限不低于 3.6，实际工具 SDK/Flutter 要求以两个公共包 pubspec 为准。

## 2. 补齐应用自身的事实

在 `app.yaml` 填品牌、设备、storefront、真实 `driver.ready`；在脚本中写应用已支持的操作。
所有上屏语言来自 ARB。提供授权背景图片；`media/manifest.json` 每个 storefront 有相应条目及真实许可依据。
录制用本地数据或经应用允许的测试数据，不接入商店凭据。

先录一份验证场景、设备和语言：

```sh
dart run store_preview captions --app "$APP_ID"
dart run store_preview validate --app "$APP_ID" --config-only
dart run store_preview record --app "$APP_ID" --scripts A --locales en-US
```

默认模拟器按 Bundle/App/设备独立。前置检查核对 Xcode 实际 Debug Bundle 和 SDK 支持范围。
SDK 冲突由应用评估选择兼容 Xcode 或调整最低系统版本，工具不替应用做该决定。
IAP 披露必须符合实际业务，不能为测试关闭真实应用的购买说明。

## 3. 明确货架与客群，再初始化

先人工确认默认 Header/Search 卖点、CPP 客群和预期入口、PPO 唯一变量、假设与衡量指标。
以下用一个已确认的 `creators` 客群和 `header-proof:Proof` treatment 演示命令；实际应用换为自己的名称。

```sh
dart run store_preview new-creatives --app "$APP_ID" --ascpub "$ASCPUB_ROOT" \
  --cpp creators --ppo header-proof:Proof
node "$ASCPUB_ROOT/dist/cli.js" assets init -b "$BUNDLE_ID" --cpp creators --ppo header-proof
```

编辑 CPP/PPO listing 的名字、客群推广文本、locales、已有合法关键词、深链和实验信息。
CPP 深链只能用客户端已实现并注册的入口；没有入口就留空。初始 `visible: false` 保留为草稿。
素材短标题与 CPP 宣传文本用途不同，不能相互截断替代。`What's New` 属 App 版本的发行说明。
PPO 只变更声明的变量；若同时改变多项，显式声明 bundle 并解释混杂因素。

## 4. 写回、生成、验证

编辑 ARB 的 `storeCreative*` 和每个定义的 `shelf:` 后运行：

```sh
dart run store_preview captions --app "$APP_ID"
dart run store_preview listing --app "$APP_ID" --write
dart run store_preview listing --app "$APP_ID"
dart run store_preview validate --app "$APP_ID" --config-only
dart run store_preview render --app "$APP_ID"
# 录制已齐全时可用：dart run store_preview creatives --app "$APP_ID"
dart run store_preview review --app "$APP_ID"
make asset-library APP="$APP_ID"
```

查看全部联系表和视频开场。只有人实际查看对应文件后，才能用 `review --asset ... --reviewer ...`
记录 true/false，再执行 `manifest` 和最终 gate。未复核素材保持 false；截图集合是否满足 real_ui 比例由校验器决定。
不能通过补一条假的人工记录满足比例。

`listing --write` 只写已声明的货架和 manifest 路径；手工文案、深链、未声明媒体组应保持不变。
重复运行后对比 listing 字节与素材条目，确认没有覆盖人工内容。
已有交付会先验证旧哈希并归档，隔离渲染全部通过后才替换。局部首轮没有完整清单时不算交付。
截图只缺人工复核时可查看新工作文件，但当前目录不保留交付清单、命令返回失败；旧交付在归档中。
复核后再运行 `manifest` 和最终 gate，不能将待复核工作文件称为已交付。

```sh
LISTING_DIR="$(dart run store_preview listing --app "$APP_ID" --dir)"
node "$ASCPUB_ROOT/dist/cli.js" assets validate -l "$(dirname "$LISTING_DIR")" -b "$BUNDLE_ID"
node "$ASCPUB_ROOT/dist/cli.js" cpp validate -l "$(dirname "$LISTING_DIR")" -b "$BUNDLE_ID"
node "$ASCPUB_ROOT/dist/cli.js" ppo validate -l "$(dirname "$LISTING_DIR")" -b "$BUNDLE_ID"
```

全部退出 0、错误数 0，再保存验收日志、清单 SHA、VENDOR.json、业务文件前后哈希和人工复核依据。
这个结果证明本地素材/货架契约成立，不证明 Apple 审核、实际展示或转化率提升。

## 5. 独立冷启动案例：Reuse Notes

`examples/reuse-notes/` 提供独立的双语笔记 UI、三场景操作、授权测试背景声明，以及一组 CPP/PPO 业务输入。
它不是 ai_studio 的素材副本，不包含任何账号、生成模型或 App Store API。
样例无 IAP，因此 `requires_purchase: false` 仅适用于此测试样例；真实 IAP 应用必须保持真实披露。

在模板目录设置 `ASCPUB_ROOT` 后执行以下命令；创建全新临时目录，不覆盖已有应用：

```sh
TEMPLATE_ROOT="$PWD"
CASE_ROOT="$(mktemp -d /tmp/store-preview-cold-XXXXXX)"
APP_ROOT="$CASE_ROOT/reuse_notes"
EXAMPLE="$TEMPLATE_ROOT/docs/store/examples/reuse-notes"
flutter create --empty --platforms=ios --org org.example --project-name reuse_notes --no-pub "$APP_ROOT"
cp "$EXAMPLE/pubspec.yaml" "$APP_ROOT/pubspec.yaml"
cp "$EXAMPLE/l10n.yaml" "$APP_ROOT/l10n.yaml"
mkdir -p "$APP_ROOT/lib/l10n"
cp "$EXAMPLE/lib/main.dart.txt" "$APP_ROOT/lib/main.dart"
cp "$EXAMPLE/lib/l10n/"*.arb "$APP_ROOT/lib/l10n/"

dart run store_preview vendor --from . --root "$APP_ROOT"
dart run store_preview integrate --root "$APP_ROOT" --write
cd "$APP_ROOT"
flutter pub get --offline
dart run store_preview new-app reuse_notes
# 以下是样例自己的 UI/录制配置输入，不复制任何业务 App 配置。
cp -R "$EXAMPLE/store_preview/." store_preview/
# 此独立样例选择 iOS 15；未来 SDK 不支持时前置检查会停止。
sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 13.0;/IPHONEOS_DEPLOYMENT_TARGET = 15.0;/g' ios/Runner.xcodeproj/project.pbxproj
ffmpeg -nostdin -v error -f lavfi -i 'color=c=0x0d1a18:s=3840x2160' \
  -frames:v 1 -pix_fmt rgb24 store_preview/reuse_notes/media/backdrop.png
dart run store_preview new-creatives --app reuse_notes --ascpub "$ASCPUB_ROOT" \
  --cpp daily-planners --ppo header-proof:Checklist
node "$ASCPUB_ROOT/dist/cli.js" assets init -b org.example.reuseNotes --cpp daily-planners --ppo header-proof
cp -R "$EXAMPLE/listings/." listings/
dart run store_preview captions --app reuse_notes
dart run store_preview listing --app reuse_notes --write
dart run store_preview validate --app reuse_notes --config-only
flutter analyze lib integration_test
dart run store_preview render --app reuse_notes
make asset-library APP=reuse_notes
```

`make` 需要 `ascpub` 已在 PATH；也可用 `ASCPUB` 指向已有可执行 CLI。
离线缓存不齐时 `flutter pub get --offline` 会明确失败；安装所需依赖后重跑，不以跳过依赖验证替代。
默认应得到两份 15 秒预览，以及两种语言的默认 Header/Search、CPP Header/Search 和 PPO Header 共 10 项素材。
全部 `real_ui` 保持 false；此案例验证管线，不伪造人工复核或 ASO 效果结论。

## 6. 比旧流程消除的重复工作

| 原步骤/风险 | 现在的机制 | 可复核证据 |
| --- | --- | --- |
| 手加 2 个 workspace 成员、2 个开发依赖、2 个 Makefile 目标 | 一次 `integrate --write`，重复无变化 | `integration_test.dart` |
| 每 App 手工处理 locale 别名和歧义 Bundle | 通用去重、显式 Bundle 选择、listing 归属检查 | `reuse_regression_test.dart` |
| 初始化报错后清理半份配置 | 全输入规划与失败回滚 | 同上、`FilePlan` 测试 |
| 重新 vendor 可能丢失业务仓局部修复 | 漂移阻断、来源/目标预检与回滚 | `vendor_protection_test.dart` |
| 手工备份只有清单，重录覆盖了旧文件 | 带文件哈希的整套归档、隔离生成 | `creative_release_test.dart` |
| 只看配置摘要沿用旧 real_ui | 复核绑定实际素材/EDL/海报 | `creative_render_test.dart` |
| 录制中才发现 SDK/Bundle 不匹配 | 清空模拟器之前读 SDK 与 resolved settings | `simulator_preflight_test.dart` |

仍需人工完成产品定位、文案、授权核实、路由能力判断和画面复核。这些是业务决策，自动填充不能代替生产验收。
