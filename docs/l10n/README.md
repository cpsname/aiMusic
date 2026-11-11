# Songlet 本地化维护

源语言为英语。`lib/l10n/arb/` 中只维护 13 份完整资源：en、zh_Hans、zh_Hant、ja、ko、de、fr、es、pt_BR、hi、id、vi、tr。文件名及 `@@locale` 使用下划线；对外 BCP-47 标签使用 `zh-Hans`、`zh-Hant`、`pt-BR`。

`supportedUiLocales` 是产品支持语言清单。Settings → Language → App language 提供“跟随系统”和 13 种语言，各语言用母语名称显示。`uiLocaleProvider` 优先使用 `uiLanguagePreferenceProvider`，未选择时使用 `systemUiLocaleProvider`；不支持的系统语言回退英语，中文按 Hans/Hant 解析。请求的 `X-Language` 使用相同结果。

选择保存在 SharedPreferences 的 `songlet.ui_locale`，值为规范 BCP-47 标签；跟随系统删除该键，未知或损坏值按跟随系统处理。启动时等待偏好加载才显示业务页面。保存操作串行执行，持久化成功后才更新界面；失败保留原选择并在弹层显示重试提示。语言切换保留导航、创作草稿、播放和后台任务。

默认歌词语言是独立设置，只影响新歌曲；自动选择始终参考系统语言及地区规则，不随 App language 改变。新增创作入口应传入 `systemUiLocaleProvider` 的语言和脚本，不能把当前 UI locale 当作歌词偏好。

远程配置切换语言时立即刷新；请求未结束则排队刷新最后选择的语言，并丢弃旧语言响应。维护／禁用标志保留，维护及促销正文只显示当前语言已有内容，缺失时使用本地化维护兜底或隐藏促销。`app_init` 和商品缓存按语言标签分区；旧的无语言缓存不用于新请求，同语言离线缓存仍可复用。StoreKit 价格仍原样使用 `displayPrice`，界面语言不改变商店地区。通知绑定随 UI locale 更新，后续创建的通知使用新语言；已经提交给系统的通知保留调度时文案。

## 新增或修改文案

1. 先在 `app_en.arb` 添加完整句子或独立标签，使用小驼峰和页面前缀，例如 `paywallStartTrial`、`mvChipMakingWithProgress`、`createGenreIndiePop`。已发布的旧键保持兼容，新键遵循此前缀规则。
2. 为每条文案添加 `@key.description`，说明页面、控件、使用条件；每个参数注明类型和具体含义。参数只使用 `int`、`String`、`DateTime`。日期传入已转换为本地时间的 `DateTime`，使用 `yMMMd` 等 intl 格式；整数使用 `decimalPattern`。
3. 句子里的数量使用 ICU plural，并包含 `other`。使用 `one` 等语言类别时插入实际数量，不把数字 1 固定写入：法语、印地语的 `one` 可能也匹配 0。分支或性别使用 ICU select，参数类型为 String，并包含 `other`。协议枚举值不能翻译。
4. 在其余 12 个 ARB 中添加同名键，并同步参数名、类型、格式及说明。短句、自然表达优先；翻译完整句子，避免在 Dart 中拼接语法片段。
5. 页面通过 `AppLocalizations.of(context)` 读取资源。用户内容和未知生成内容保持原样；固定曲风请求值通过 `genreName` 映射为本地化显示名。歌词编辑器用 `sectionTagLabels` 显示本地化标签，`sectionTags` 始终保留英文插入 token。
6. 执行 `make l10n`，然后 `flutter analyze`、`flutter test`。布局或文案改变时更新受影响的 golden，逐张检查后再运行不带更新参数的测试。

示例：

```json
{
  "mvPhotosCount": "{count, plural, one{{count} photo} other{{count} photos}}",
  "@mvPhotosCount": {
    "description": "Selected reference-photo count on the video configuration screen.",
    "placeholders": {
      "count": {
        "type": "int",
        "format": "decimalPattern",
        "description": "Number of selected video reference photos."
      }
    }
  }
}
```

## 生成器与构建

当前 Flutter gen-l10n 强制要求脚本／地区变体拥有基础语言 ARB。`tool/l10n/prepare.dart` 将 13 份资源复制到 `.dart_tool/songlet_l10n/arb/`，临时补齐 zh、pt 回退：分别复用 zh_Hans、pt_BR 的完整内容。该目录和 `lib/l10n/generated/` 都是构建产物，不能手工修改或提交。

`l10n.yaml` 指向临时目录。首次检出或清理后用 `make get` 安装依赖：Flutter 的 pub get 也会自动生成本地化，所以必须先准备 ARB。CI 使用相同入口。`make l10n` 按顺序准备资源并运行 `flutter gen-l10n`。Makefile 的测试、分析、运行和构建入口先执行本地化准备；直接调用 Flutter 构建前，也先执行 `make l10n`。准备后可单独运行 `flutter gen-l10n`。

生成器内部有 zh、pt 回退，应用仍只开放 `supportedUiLocales` 的 13 个目标 locale。不要直接用生成器支持列表作为产品语言清单。

## 翻译审核清单

- 文案简洁、口语化，适合按钮、表单或当前错误场景；CJK 和越南语优先短句。
- 所有语言的键集合相同，值非空，说明齐全，参数契约与英文相同，ICU 可解析。不要用正则提取 ICU 分支正文作为参数。
- 德语单条不超过英语的 1.4 倍字符数；检查 ICU 的实际显示分支和长参数。空间紧张的国家／语言标签可使用通行缩写，不能缩短法务正文或错误原因。
- 付费法务逐句核对：确认时扣款、相同价格与周期自动续订、至少提前 24 小时取消、试用结束转付费、App Store 管理／取消入口；不得遗漏。
- 恢复购买区分开始、无可恢复项目、成功数量与失败。价格参数必须原样传入 StoreKit `displayPrice`，不能解析、换算、拼币种或重新格式化。
- 试用结束的价格说明使用 `paywallTrialDisclosure(pricePerPeriod)`：参数由当前商品的 `planPerMonth`／`planPerYear` 生成，价格部分仍是原始 `displayPrice`。优先采用 StoreKit 周期，仅在缺失时采用目录周期；不能把所有试用写成年付。当前目录只售单月／单年订阅，增加其他周期时须同步扩展价格与试用单位文案，不能用 30／365 天代替日历月／年。
- 错误文案保留 PRD 6.5 的原因与下一步。`REGION_UNAVAILABLE` 按既有 ADR-0005 显示可重试的超时文案，修改此行为需同时更新该决定和测试。
- 百分比使用 `progressPercent`：输入为 0–1，输出已包含符号和 locale 空格。不要再在 ARB 里追加百分号。媒体时长使用 `mediaDuration`，不能用一天中的时间格式造成分钟回绕。
- 主按钮和参数值允许换行，避免省略操作含义。用 de、hi 的关键页 golden，以及 de、hi、vi 小屏／最大字体测试检查溢出、遮挡和高字形；印地语 golden 注册系统天城文字体。
- 远程促销、权益名称、更新说明及错误正文由服务端按 X-Language 本地化。缺失权益名称显示本地化通用说明，不直接暴露权益码。

## 验证命令

```sh
make l10n
flutter analyze
flutter test
flutter test test/l10n/localized_pages_test.dart
```

需要更新关键页基线时：

```sh
flutter test test/l10n/localized_pages_test.dart --update-goldens
```

`arb_completeness_test.dart` 检查资源集合、非空值、ICU、说明、参数类型及格式（含 `optionalParameters`）、德语长度，加载全部目标 locale 并覆盖 0、1、2、21、1000 等数量、日期、StoreKit 价格和通知。`localized_pages_test.dart` 覆盖创作首页／表单、付费、MV 配置及歌曲／MV 进度，也包含 `P01-inspirations` 底部的 de／hi golden。灵感网格逐段滚动，检查延迟构建的全部卡片；de／hi／vi 同时检查小屏和最大字体，主操作和卡片标题不能省略或超出卡片边界。`trial_disclosure_test.dart` 检查月付／年付试用、商店与界面语言不同的价格，以及商店周期优先级。

## 不翻译与扫描例外

固定名称由 `SongletBrand` 管理：Songlet、Pro、Premier。Lyria 3、Lyria 3.5、Google Lyria 3、SynthID、Gemini API、平台及文件格式名称保持原样，周围的自然语言必须翻译。

以下不属于待翻译产品文案：产品 ID、错误码、路由、测试 ID、遥测键、远程配置键、URL、MIME、文件扩展名、正则、协议曲风和段落 token、用户名称／歌词／描述、未知服务端生成内容、缺失值横线及纯排版分隔符。`failure_copy.dart` 中只在 debug 展示的构建诊断允许保留英文。

灵感内容遵循 [ADR-0029](../adr/0029-inspirations.md)：英语与简中显示服务端 `name/style`；其余语言通过协议英文值匹配 `inspirationName*`／`inspirationStyle*`，未知值回退英文。英文匹配表与预测量名称表不是待迁移文案。独立灵感将 `style.en` 填入可编辑提示词是现有模型输入契约；变更显示语言时须同时设计显示值与提交值，不能只翻译提交内容。新增已知灵感需更新映射、13 份资源及布局验证。

检查 `lib/` 时排除 `lib/l10n/generated/`，并区分字符串参与协议匹配还是直接显示。禁止新增直接显示的固定正文；提交前清除未完成的占位标记。

`ui_language_test.dart` 覆盖全部语言的真实点击、跟随系统、持久化／重新加载、保存失败、连续选择、草稿隔离，以及真实应用根组件的冷启动与通知重绑定。`settings_language_layout_test.dart` 覆盖 de／hi 设置与弹层 golden，以及 de／hi／vi 小屏和最大字体下滚动到末项；新增语言时须同步扩展这些验证。
