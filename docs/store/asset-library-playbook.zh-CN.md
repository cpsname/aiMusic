# Asset Library + store-preview 操作手册与跨项目复用指南

> **适用范围**:基于 iap_template 的任何 iOS App。store-preview(本仓库 `packages/store_preview`)负责生产与校验,
> ascpub(仓库 ASOShip)负责发布到 App Store Connect。
> **依据**:本文命令、参数、输出均取自实际代码,并于 2026-10-11 在本机完整跑通(§13 是逐字记录的案例)。
> 决策见模板 ADR-0009–0015、ascpub ADR-0007 / 0010 / 0011;Apple 规格原文见 [creative-assets-specs.md](creative-assets-specs.md)。
> **给 Claude Code / Codex**:先读 §0,再按任务跳到对应章节;不要重新分析架构,不要改工具代码来适配某个 App。

---

## 目录

0. 阅读指引与硬性约束
1. 业务模型:仓库 · 货架 · 专柜 · 货架 A/B
2. 功能说明:两个工具各做什么
3. 环境依赖
4. 安装与初始化
5. 配置参数参考
6. 素材管理(仓库)
7. Header / 搜索结果配置(货架)
8. CPP 操作(专柜)
9. PPO 操作(货架 A/B)
10. 预览与验证
11. 审核与发布
12. 测试与验收
13. 新项目接入流程与完整操作案例
14. 常见问题
15. 故障排查
16. 架构、模块与扩展方式

---

## 0. 阅读指引与硬性约束

| 我要… | 去 |
| --- | --- |
| 给一个新 App 接入整套能力 | §4 → §13 |
| 改 Header / Search 上展示的素材 | §7 |
| 新建一个 CPP / PPO 实验 | §8 / §9 |
| 判断素材能不能交付 | §10、§12 |
| 上传、送审、上架 | §11 |
| 某条报错 | §15 |
| 扩展工具本身 | §16 |

**硬性约束(违反即为缺陷)**

1. store-preview **只生产与校验**:不调用 App Store Connect、不持有凭据、不创建页面、不写深链与关键词。
2. 一切 App 差异都是**配置**(`store_preview/<app>/`、ARB、ascpub listing);工具代码只在模板改,改完 re-vendor。
3. `real_ui` **只能由人复核**后用 `review` 记录;不得凭文件名或模型判断写复核。
4. 校验失败只报错,**不自动修图**;裁切 / 转码会产生新文件,必须重新渲染、重新复核。
5. 凭据(`.p8`、`ASC_*`)只在运行 ascpub 的目录的 `.env`,永不入库;任何写远端的命令先 `--dry-run`。
6. 契约(清单 schema)归 ascpub:store-preview 从 ascpub 检出读取并用 SHA-256 锁定,**不复制**。
7. 已上线 App 改货架(`shelf:`)会改变商店展示内容,属于产品决策,先问负责人(例如 Songlet 先只上架通用图,2026-10-16 才由负责人决定上架本地化图片)。

---

## 1. 业务模型:仓库 · 货架 · 专柜 · 货架 A/B

Apple 2026-10-05 新增两个创意展示位,**iOS 27 / iPadOS 27 及以上**显示(旧系统仍显示截图与预览视频):

- **产品页 Header**:21:9 图片或静音循环视频,或通用 16:9 图片;
- **搜索结果素材**:3:2 图片或静音循环视频,或通用 16:9 图片。

| 概念 | Apple 侧 | ascpub listing | store-preview |
| --- | --- | --- | --- |
| **仓库** | Asset Library(上传、处理、送审) | `assets push` 上传清单条目 | 所有定义产出的全部素材 → `dist/<app>/assets-manifest.json` |
| **货架** | 默认产品页的 Header / Search Results 展示位 | `assets.yaml` › `store_page` | `creatives/store-page.yaml`,`targets: [app_store_version]` |
| **专柜** | 自定义产品页 CPP,按客群(≤ 70 个) | `cpp/<slug>.yaml` | `creatives/cpp-<slug>.yaml`,`targets: ["custom_product_page:<slug>"]` |
| **货架 A/B** | 产品页优化 PPO(只对默认产品页;≤ 3 个 treatment) | `ppo/<slug>.yaml` › `treatments[]` | `creatives/ppo-<slug>-<treatment>.yaml`,`targets: ["ppo:<slug>:<Treatment>"]` |

三条业务规则:

- **进仓 ≠ 上架**。素材必须被某页面某展示位绑定才会展示。`assets push` 默认只上传被绑定的,`--all` 才上传全部。
- **一个展示位 × 一个本地化,同一时刻只摆一件**(Apple 每组上限 1)。同一槽位的多个候选(本地化图、视频、通用图)
  由 `shelf:` 声明哪件上架,其余留在仓库,可作为 PPO 的 treatment。
- **PPO 是货架的 A/B**:对照组 = 默认产品页货架;treatment 只改一个变量(`header` 或 `search_results`)。
  CPP 之间的比较不是随机实验。

---

## 2. 功能说明:两个工具各做什么

```
 模拟器录像(take)
      │  store-preview render / creatives
      ▼
 dist/<app>/creative/<storefront|universal>/<id>.png|.mp4  (+ .poster.png, .edl.json)
 dist/<app>/creative/sheets/<id>.png, <id>.first2s.png     ← 人工复核用
 dist/<app>/assets-manifest.json                            ← 契约:ascpub 的 JSON Schema(SHA 锁定)
      │  store-preview listing --write(只写声明了 shelf: 的页面的槽位块 + manifest 路径)
      ▼
 listings/<bundle>/assets.yaml · cpp/<slug>.yaml · ppo/<slug>.yaml   ← ascpub listing
      │  ascpub assets push / submit · placements · cpp · ppo · analytics
      ▼
 App Store Connect
```

| 能力 | 工具 | 命令 |
| --- | --- | --- |
| 录屏、合成预览视频与创意素材 | store-preview | `render`、`record`、`compose`、`creatives` |
| 三层校验(规格 · 合规 · 叙事)+ 清单复测 | store-preview | `validate`、`manifest` |
| 人工复核 `real_ui` | store-preview | `review` |
| 货架声明写进 listing / 检查一致 | store-preview | `listing [--write] [--dir]` |
| 一次生成整套素材配置 | store-preview | `new-creatives` |
| 契约状态 | store-preview | `contract` |
| 本地离线验收 | 两者 | `make asset-library APP=<app>` |
| listing 建页、离线校验 | ascpub | `assets init`、`assets/cpp/ppo validate` |
| 上传、送审、展示位、CPP、PPO、报表 | ascpub | §11 |

**谁写什么**

| 内容 | 唯一写入方 |
| --- | --- |
| 素材文件、EDL、联系表、清单 | store-preview(ascpub 只读,并重新探测文件,不一致即拒绝) |
| 清单 schema | ascpub(`docs/contracts/assets-manifest.schema.json`) |
| CPP 名称 / 深链 / 关键词 / 可见性 / 本地化;PPO 名称 / 假设 / 流量 / 变量 / locales / treatment 名 | 人 + `ascpub assets init` |
| 声明了 `shelf:` 的页面的 `header` / `search_results` 块、`assets.yaml` › `manifest` | `store-preview listing --write` |
| 未声明 `shelf:` 的页面的绑定 | 人(手写;store-preview 只校验) |
| `real_ui` | 人(`store-preview review`) |
| 远端 id、上传进度、快照、运行报告 | ascpub(`listings/<bundle>/.ascpub/`,不入库,不要手改或删除) |

---

## 3. 环境依赖

| 依赖 | 要求 | 验证命令(本机 2026-10-11 实测) |
| --- | --- | --- |
| macOS + Xcode | 模拟器、`swiftc`、`xcrun`、`plutil` | `xcodebuild -version` → Xcode 27.0 |
| Flutter / Dart | Flutter ≥ 3.44(仓库约定) | `flutter --version` → 3.44.2 |
| ffmpeg / ffprobe | Homebrew 版,含 `aac_at`(AudioToolbox)与 `libx264` | `ffmpeg -hide_banner -encoders \| grep -E "aac_at\|libx264"` |
| Node.js | ≥ 20(ascpub) | `node --version` → v26.8.1 |
| ascpub 检出 | 本机一份 ASOShip;`npm install && npm run build && npm link` 得到全局 `ascpub` | `ascpub --version` |
| App 本地配置 | `config/dev.json`(从 `config/dev.example.json` 复制;已 gitignore,新克隆里没有) | 录屏用 `driver.dart_defines_file` |
| ASC API Key | 仅远端步骤需要:`.env` 里 `ASC_KEY_ID` / `ASC_ISSUER_ID` / `ASC_KEY_PATH` | `ascpub doctor` |

一条命令自检 store-preview 所需工具与配置摘要:

```sh
dart run store_preview doctor --app <app>
# ✓ tools: ffmpeg (aac_at), ffprobe, swiftc, xcrun, flutter, plutil
#   …
#   creatives  cpp-creators, ppo-header-motion-video, store-page (contract: ascpub cdb606c (schema 1, 7f117bc76322…))
```

录屏使用专用模拟器「Store Preview (<device>)」,首次使用自动创建,**每个 take 都会抹掉它**;
用 `STORE_PREVIEW_SIM_IPHONE=<udid>` 指定别的模拟器。

---

## 4. 安装与初始化

### 4.1 ascpub(每台机器一次)

```sh
cd <ascpub 检出,如 ~/Developer/Tools/ASOShip>
npm install && npm run build && npm link     # 得到全局 ascpub;ascpub 改动后重跑 npm run build
ascpub --version
```

store-preview 通过 `app.yaml` › `creatives.ascpub.root`(相对仓库根)找到它;另一台机器或 CI 用环境变量
`ASCPUB_ROOT=<绝对路径>` 覆盖,不改配置。store-preview 自己的测试同样读 `$ASCPUB_ROOT`,
未设置时默认找 `<工作区>/Tools/ASOShip`(即仓库上两级目录旁的 `Tools/ASOShip`)。

### 4.2 新项目(复制模板)

模板约定「一个仓库 = 一个 App」:复制整个 iap_template 即得到工具、Makefile 目标、验收脚本和本手册。

```sh
cp config/dev.example.json config/dev.json    # 填好本地配置
flutter pub get
dart run store_preview new-app <app>          # 生成 store_preview/<app>/(沿用示例 studio_app 时跳过)
```

模板自带的示例 `studio_app` 与 `listings/org.vizgo.ai/` 是参照实现;新 App 用自己的名字和 bundle id 另起,
确认无用后再删除示例。

### 4.3 已有 App(vendor)

App 仓库不是从当前模板复制的(如 Songlet),从模板检出执行:

```sh
cd <iap_template>
dart run store_preview vendor --from . --root <App 仓库>
```

它复制两个公共包、Apple 规则、素材规范、本手册、故障知识库和验收脚本，并写入 `VENDOR.json`。
工具先核对源目录完整性、源/目标不嵌套、符号链接和目标副本漂移，再暂存、校验、替换；
安装失败会回滚已替换文件。副本有本地修改时先把修复回灌模板，禁止用再次 vendor 丢弃差异。

**首次 workspace 尚不存在时，继续从模板运行初始化命令**（App 内尚不能解析 `dart run store_preview`）：

```sh
dart run store_preview integrate --root "<App 仓库>"          # 查看 pubspec / Makefile 变更计划
dart run store_preview integrate --root "<App 仓库>" --write
cd "<App 仓库>"
flutter pub get
dart run store_preview integrate --check
dart run store_preview vendor --check
dart run store_preview new-app <app>                        # 已有录制配置则跳过
```

`integrate` 只补两个 workspace 成员、`integration_test` / `store_preview_driver` 开发依赖和
`store-preview` / `asset-library` Makefile 目标；保留版本、业务依赖、注释、已有成员和匹配的目标。
重复执行无变化；依赖或自定义目标冲突时整体不写，明确指出需人工整合的字段。
Dart workspace 要求根 SDK 下限至少 3.6；工具不自动提高业务工程的 SDK 要求。

`new-app` 从 iOS 工程、图标和 ARB 读取事实。多个 App Bundle ID 时必须用 `--bundle-id <已声明 ID>` 选择，
不能默认选第一个。映射到同一 ASC locale 的 ARB 只生成一个 storefront（例如 zh / zh_Hans、nb / no）；
全部 ARB 解析通过后才写配置和文案。已有文案、已有录制配置不覆盖。
生成的暂停场景仅是接入骨架，必须补本 App 的真实操作、卖点和文案后录制，不等于生产素材已验收。

vendored 副本**禁止就地修改**；公共修复和回归测试一律在模板完成，再 vendor。
详见 [跨项目接入与验收操作](asset-library-reuse.zh-CN.md) 和
[故障知识库](asset-library-troubleshooting.zh-CN.md)。

### 4.4 素材初始化(每个 App 一次)

前提:预览能录制(`store_preview/<app>/` 已就绪),且 `media/manifest.json` 里有一张**给每个 storefront 都授权**的图片
(素材背景)。然后:

```sh
dart run store_preview new-creatives --app <app> --ascpub <ascpub 检出> \
  [--cpp <slug>,<slug>] [--ppo <slug>:<Treatment>,…] [--listing <listing 目录,默认 listings/<bundle id>>]
```

它生成:`app.yaml` › `creatives`(ascpub 根、契约 SHA、listing、授权映射)、`creatives/store-page.yaml`(货架)、
每个 `--cpp` 一个专柜、每个 `--ppo` 一个 treatment、所有 ARB 中的 `storeCreative*` 文案,并打印逐条后续步骤
(包括需要翻译的文案、画面中需要补授权映射的媒体角色)。
任何输入有误(重复的 slug、同名 treatment、没有授权背景图、已存在素材配置)时**一个文件都不写**。
它只生成图片素材;视频见 §7.4。生成短标题不能代替 CPP 的推广文本、受众说明或 PPO 假设；
这些业务字段必须在 listing 中独立编写并人工确认，`listing --write` 只管理声明的货架字段。

---

## 5. 配置参数参考

### 5.1 `store_preview/<app>/app.yaml` › `creatives`

```yaml
creatives:
  ascpub:
    root: ../../Tools/ASOShip            # 必填。ascpub 检出,相对仓库根;$ASCPUB_ROOT 覆盖
    schema_sha256: 7f117bc7…             # 必填。shasum -a 256 <ascpub>/docs/contracts/assets-manifest.schema.json
    listing: listings/com.example.app    # 有 CPP/PPO 目标或声明了 shelf: 时必填。ascpub listing,相对仓库根
  authorization:                         # 媒体角色 → 清单授权字段(interaction_id / mv_id / generation_id)
    photo: generation_id
    song: interaction_id
  layouts:                               # 可选。只能比 defaults/creative.yaml 更严,否则报错
    "21:9": {safe: {width: 0.66}}        # 可调:safe.width/height、text.size/max_lines、backdrop.brightness
```

`captions` 下与素材相关的可选项:`creative_prefix`(默认 `storeCreative`)、`creative_max_chars`(默认 40)、
`creative_max_chars_cjk`(默认 20)。

### 5.2 素材定义 `store_preview/<app>/creatives/<id>.yaml`

| 字段 | 必填 | 说明 |
| --- | --- | --- |
| `id` | 是 | 必须等于文件名 |
| `title` | 是 | 说明用 |
| `targets` | 是 | `app_store_version` / `"custom_product_page:<slug>"` / `"ppo:<slug>:<Treatment>"`,可多个 |
| `universal_from` | 有通用素材时 | 通用素材(id 不含 `{storefront}`)取哪个 storefront 的画面;默认第一个 storefront |
| `backdrop` | 是(或写在槽位上) | `{role, script, index}`:媒体清单里有授权的图片 |
| `text` | 按 storefront 的素材需要 | ARB 键(前缀 `storeCreative`);槽位上可覆盖 |
| `tags` | 否 | 清单 `experiment_tags`,格式 `name` 或 `name:value` |
| `shelf` | 否 | 上架声明,见 §7.2;省略 = listing 绑定手写 |
| `slots[]` | 是 | 每个槽位:`placements`、`spec`、可选 `text` / `backdrop` / `tags`、`assets[]` |

素材(`assets[]`):

```yaml
# 图片:某场景的一帧(at 为负 = 从场景末尾往回数)
- {id: "header.{storefront}", type: image, frame: {script: A, scene: player, at: 2.0}}
# 视频:循环模板上的若干场景,实时播放
- id: "header.{storefront}.video"
  type: video
  template: banner_loop        # 循环模板,见 §7.4
  rhythm: 12                   # 该模板的节奏(秒)
  poster_at: 3.0               # 海报帧,必须落在 finished 场景内
  scenes:
    - {beat: hero, script: B, scene: lyricVideo, duration: 7.0}
    - {beat: detail, script: A, scene: player, from: -2.0, duration: 5.0}
```

id 含 `{storefront}` = 每个 storefront 一份(带文案,`locale` = storefront);不含 = 通用素材(`locale: null`,无文字)。
storefront id 必须是 App Store Connect 的 50 个 locale 之一(如 `en-US`、`zh-Hans`、`de-DE`、`ja`)。
storefront 的 `serves: [en-GB, …]` 列出同语言、没有自己录屏的其它本地化(ADR-0017):不录、不渲染,清单把该 storefront 的
每件按 storefront 素材以 `header.en-GB` 这样的 id 再列一次(`locale` = 被服务的本地化,文件与哈希同源,`derived_from` = 源条目 id),
ascpub 按内容去重只上传一次。
场景可声明 `shows: [{role, script, index}]`,表示画面里出现的授权媒体;其授权 id 会进入清单与 EDL。

### 5.3 规格 id(`packages/store_preview/defaults/creative.yaml`)

| spec | 展示位 | 图片 | 视频 |
| --- | --- | --- | --- |
| `header_21x9` | product_page_header | 3840×1646,仅 .png | 3840×1646,30/60 fps,10–30 s |
| `search_3x2` | app_store_search_results | 1920×1280–3840×2560 精确 3:2,.png/.jpg/.jpeg(渲染 3840×2560) | 同比例范围,30/60 fps,15–30 s(渲染 2880×1920) |
| `universal_16x9` | 两者 | 5244×2950,.png | — |

通用:无 alpha;≤ 524288000 字节;视频 H.264/HEVC、yuv420p、无音轨、无旋转。

### 5.4 ARB

`lib/l10n/arb/app_<locale>.arb` 中每个 storefront 一句 `storeCreative*`:拉丁文字 ≤ 40、CJK ≤ 20 字符,
按版式不超过 2–3 行;不得含价格、「免费」、日期、网址、©/℗、奖项、Apple 推荐语、其他平台名。改完执行
`dart run store_preview captions --app <app>`(导出到 `captions/`,渲染读取它)。

### 5.5 ascpub listing(`listings/<bundle>/`)

```yaml
# assets.yaml(ascpub assets init 生成)
schema: 1
manifest: ../../dist/<app>/assets-manifest.json   # 声明 shelf: 时由 listing --write 写
store_page:
  header:         {default: "", locales: {}}      # 声明 shelf: 时由 listing --write 写
  search_results: {default: "", locales: {}}
deep_links:
  info_plist: ""                                   # 人填:相对本目录的 Info.plist
  allowed: []                                      # 人填:允许的深链前缀,如 myapp://app/create
```

```yaml
# cpp/<slug>.yaml
schema: 1
name: "Creators"            # 人填:对账键,改名 = 新页面
deep_link: ""               # 人填:可选,须以 deep_links.allowed 之一开头(iOS 18+)
visible: false              # 获批后才有意义
locales:                    # 人填:页面拥有的本地化 —— 货架只绑定这些 locale
  en-US: {promotional_text: "", keywords: []}     # 关键词只能取自最新获批版本
  zh-Hans: {promotional_text: "", keywords: []}
header: …                   # 声明 shelf: 时由 listing --write 写
search_results: …
```

```yaml
# ppo/<slug>.yaml
schema: 1
name: "Header motion"
target: product_page        # 只能是默认产品页
traffic_proportion: 30      # 1–100
hypothesis: "A moving header converts more visitors than the still image"
primary_metric: conversion_rate
variable: header            # header | search_results | bundle(需 bundle_note)
locales: [en-US, zh-Hans]   # 实验覆盖的本地化 —— 货架只绑定这些 locale
treatments:
  - name: "Video"           # 必须与素材定义 targets 里的 <Treatment> 完全一致
    header: …               # 声明 shelf: 时由 listing --write 写
```

空字符串 id 表示「不管理」,两个工具读法一致。

### 5.6 环境变量

| 变量 | 作用 |
| --- | --- |
| `ASCPUB_ROOT` | 覆盖 `creatives.ascpub.root`(也供 store-preview 测试使用) |
| `ASCPUB` | 验收脚本使用的 ascpub 命令,默认 `ascpub` |
| `STORE_PREVIEW_SIM_<SLOT>` | 指定录屏模拟器 udid,如 `STORE_PREVIEW_SIM_IPHONE` |
| `ASC_KEY_ID` / `ASC_ISSUER_ID` / `ASC_KEY_PATH` | 只给 ascpub 远端命令;放运行目录 `.env` |

---

## 6. 素材管理(仓库)

### 6.1 生产

```sh
dart run store_preview render --app <app> [--scripts A,S] [--locales all|en-US,ja]    # 录制 + 预览 + 素材 + 校验 + 清单
dart run store_preview record --app <app> --scripts S --locales all                    # 只补录某脚本
dart run store_preview creatives --app <app> [--creatives store-page,cpp-x] [--locales en-US]  # 只在已有录像上出素材
dart run store_preview manifest --app <app>                                            # 只重写清单
```

- 画面不够时加 **capture 脚本**(`kind: capture`,只录不出片),例如 studio_app 的 `scripts/S.yaml`。
- 初次分批生产可以积累已校验的文件；未齐全时命令失败且没有交付清单，不能用于上传。
- 已有交付清单时，先核对旧素材与清单哈希；漂移会阻止渲染和 `manifest`，不得重写哈希将漂移“验绿”。
- 新素材在隔离目录渲染、校验，完整清单通过后才替换当前交付；技术校验失败保留原交付。退役文件在成功替换时移除。
- 截图技术校验通过但只缺人工复核比例时，会明确输出无交付清单的待复核工作文件，命令仍失败；
  旧交付保存在 `.releases`。查看新画面并记录人工结论后，再运行 `manifest` 与最终 gate；不能沿用旧清单。
- 旧清单、原文件、海报与 EDL 自动归档到 `.releases/<旧清单 SHA-256>/`，附逐文件哈希回执；不自动清理归档。
- 同一 App 的素材渲染使用文件锁；默认录制模拟器按 Bundle ID、App 配置和设备隔离。
  显式 `STORE_PREVIEW_SIM_*` 仍受支持，指定者负责该设备独占且可清空。
- 清空模拟器之前读取当前 Xcode SDK 与 Debug 构建配置，检查 Bundle ID 和最低系统版本是否匹配；
  不兼容时停止，不自动修改部署版本。

### 6.2 产物

| 路径 | 内容 |
| --- | --- |
| `dist/<app>/creative/<storefront>/<id>.png\|.mp4` | 按 storefront 的素材 |
| `dist/<app>/creative/universal/<id>.png` | 通用素材 |
| `…/<id>.poster.png` | 视频海报帧 |
| `…/<id>.edl.json` | 来源哈希、参数、授权 id(清单 `source.evidence`) |
| `dist/<app>/creative/sheets/<id,{storefront}→all>.png` | 联系表:各 storefront 拼在一起 |
| `…/<id,{storefront}→all>.first2s.png` | 视频静音开场 0 / 0.5 / 1 / 1.5 / 2 s,每行一个 storefront |
| `dist/<app>/assets-manifest.json` | 清单:每条素材的实测哈希、尺寸、时长、placement_intents、授权、来源 |
| `dist/<app>/.releases/<清单 SHA>/` | 上次交付的不可变本地归档与 `receipt.json`；是恢复依据，不是上传目录 |

### 6.3 人工复核 `real_ui`

```sh
dart run store_preview review --app <app>                      # 列出每个素材定义的复核状态
dart run store_preview review --app <app> --asset "header.{storefront}" --real-ui true --reviewer <姓名> [--note …]
dart run store_preview manifest --app <app>                    # 把结论写进清单
```

`--asset` 写素材定义里的 id(含 `{storefront}`)。复核记录在 `store_preview/<app>/creative_review.yaml`;
复核必须对应实际渲染文件。记录同时绑定定义摘要及每个 storefront 的素材、EDL、视频海报哈希。
定义或上述任何文件变化、增加尚未复核的语言，`real_ui` 都回到 `false`。
旧版只包含定义摘要的记录仍可读取，但不能证明当前文件已复核；需由人重新查看后记录。
渲染成功、截图来自模拟器或测试中的合成复核记录都不能作为真实业务素材的人工结论。

### 6.4 退役与新增 storefront

- **退役素材**:从定义里删掉 → 渲染时自动清理产物,清单不再含它;远端资产用 `ascpub assets prune` 查看未被引用者,
  `--delete` 才删除(需确认)。
- **新增 storefront**:`app.yaml` › `storefronts` + 该语言 ARB → `captions` → `listing --write`(货架自动多一个 locale)
  → `render --locales <新>` → `review` → `manifest` → 验收。
- **同语言的其它本地化**(如 en-GB 用 en-US 的素材):在那个 storefront 上加 `serves: [en-GB]` → `manifest` → `listing --write`
  → `export`(预览也复制过去)→ 验收。无需录屏、复核或新上传;CPP 还要在其 `locales` 里有这个本地化。
  只在语言相同时用;要自己的措辞就做成 storefront(ARB + 录屏 + 复核)。

---

## 7. Header / 搜索结果配置(货架)

### 7.1 设计一个槽位

| 选项 | 何时用 |
| --- | --- |
| 通用 16:9 图(`universal_16x9`,无文字) | 所有未单独配置的本地化的兜底(`default`) |
| 21:9 / 3:2 本地化图片 | 每个 storefront 有自己的文案(`locales`) |
| 21:9 / 3:2 静音循环视频 | 动态展示;可先作为 PPO treatment 验证 |

### 7.2 `shelf:` 上架声明

```yaml
shelf:
  header:         {default: header.universal, locales: "header.{storefront}"}
  search_results: {locales: "search.{storefront}.video"}
```

规则(违反会在配置校验中报错):

- 槽位只能是 `header` / `search_results`,至少给 `default` 或 `locales` 之一;
- `default` 必须是本定义的**通用**素材,`locales` 必须是本定义**按 storefront** 生成的素材;
- 两者都必须为该槽位的展示位而做(`header` ↔ product_page_header,`search_results` ↔ app_store_search_results);
- 同一页面的同一槽位只能由一个定义声明;
- `locales` 展开为 App 的全部本地化(每个 storefront 及其 `serves`),**再按页面拥有的本地化过滤**:默认产品页 = 全部;CPP = 其 `locales` 的键;
  PPO = 其 `locales` 列表(ascpub 不会把素材放到页面没有的本地化上,却仍会上传它,所以不写)。

写入与检查:

```sh
dart run store_preview listing --app <app>           # 列出每页每槽位的绑定;与 listing 不一致则失败
dart run store_preview listing --app <app> --write   # 写入(只改这两块与 manifest 路径,保留其它字段与注释)
dart run store_preview listing --app <app> --dir     # 打印 listing 目录(供脚本使用)
```

### 7.3 手写绑定(不声明 `shelf:`)

listing 里直接写 id;store-preview 校验每个被绑定的 id 都由定义为该页面、该槽位产出。Songlet 采用此方式。

### 7.4 视频与循环模板

| 模板 | 用于 | 节拍(beat) | 节奏(秒:各节拍时长) |
| --- | --- | --- | --- |
| `banner_loop` | Header | `hero`(finished)、`detail`(可选) | 8:5.5/2.5 · 12:7.0/5.0 · 16:8.5/7.5 |
| `search_card` | Search | `input`、`result`(finished)、`share`(可选) | 8:3/5 · 12:4/6.5/1.5 · 15:5/8/2 |

- 每个节拍允许 ±2.0 s 浮动,场景总长必须等于节奏;节拍按模板顺序出现;
- Header 视频 ≥ 10 s → 用 12 或 16;Search 视频 ≥ 15 s → 用 15;
- 第一个场景 ≥ 2 s,文案从第 0 帧出现(静音可懂);`poster_at` 落在 finished 场景;
- 场景实时播放,录像必须足够长;`from` 为负表示从场景末尾往回取;
- 首尾溶接,接缝 PSNR ≥ 40 dB。

---

## 8. CPP 操作(专柜)

**本地(零凭据)**

```sh
ascpub assets init -b <bundle> --cpp <slug>          # 建页面文件;填 name、locales、keywords、deep_link
# 新建 creatives/cpp-<slug>.yaml(或 new-creatives 生成)+ ARB 文案 storeCreativeCpp<Slug>
dart run store_preview listing --app <app> --write
dart run store_preview creatives --app <app> --creatives cpp-<slug>
dart run store_preview review --app <app> --asset "cpp.<slug>.header.{storefront}" --real-ui true --reviewer <姓名>
dart run store_preview manifest --app <app>
make asset-library APP=<app>
```

**远端(ascpub,需 App 已有上线版本)**

```sh
ascpub cpp validate -b <bundle> --remote                    # 关键词必须来自最新获批版本
ascpub cpp validate -b <bundle> --simulator                 # 可选:在已启动模拟器打开深链
ascpub cpp push -b <bundle> --dry-run                       # 计划;确认后 --yes:建页面、版本、本地化、关键词、展示位(不送审)
ascpub cpp submit -b <bundle> --dry-run                     # 前置检查;确认后 --submit --yes 送审,获批即自动上线
ascpub cpp status -b <bundle>
```

注意:≤ 70 个页面;页面名唯一且是对账键;同一关键词组合建议只对应一个页面;深链需 iOS 18+ 且同样送审。

---

## 9. PPO 操作(货架 A/B)

**本地**

```sh
ascpub assets init -b <bundle> --ppo <slug>          # 填 name、hypothesis、locales、variable;treatment 改名为 <Treatment>
# 每个 treatment 一个 creatives/ppo-<slug>-<treatment>.yaml,targets: ["ppo:<slug>:<Treatment>"],
# shelf 只声明实验变量对应的槽位
dart run store_preview listing --app <app> --write
dart run store_preview creatives --app <app> --creatives ppo-<slug>-<treatment>
make asset-library APP=<app>
```

**远端**

```sh
ascpub ppo validate -b <bundle>
ascpub ppo push -b <bundle> --dry-run                 # 确认后 --yes:实验与 treatment(不送审、不启动)
ascpub ppo submit -b <bundle> --dry-run               # 确认后 --submit --yes
ascpub ppo start -b <bundle> --dry-run                # 获批后,确认再 --yes 启动
ascpub ppo status -b <bundle>
ascpub ppo report -b <bundle> --results results.yaml  # 结果指标无 API:从 ASC Analytics 抄录后回填
```

结果文件格式见 ASOShip `docs/ASSETS.zh-CN.md` §6:未出数写 `null` 而不是 0;有混杂因素、置信度 < 90%
或 Apple 标为 Collecting Data / Likely Inconclusive 时结论为「数据不足」。实验期间不要改货架、发版、大改关键词或调整投放。

---

## 10. 预览与验证

### 10.1 看什么

```sh
open dist/<app>/creative/sheets/                 # <id>.png 与 <id>.first2s.png
dart run store_preview listing --app <app>       # 每页每槽位、每个本地化上架哪件
```

- 联系表:每件素材在各 storefront 的样子(视频取海报帧);
- 前 2 秒拼图:静音下 0–2 s 是否看得懂;
- 签字:看完后由人 `review`(§6.3)。

### 10.2 校验表怎么读

`validate` / `creatives` 末尾的表格:

```
asset  type  resolution  duration  fps  size  contrast  loop  spec  compliance  narrative  result
```

`contrast` 为文案处背景对比度(均值 / 90 分位,门槛 4.5 / 3.0);`loop` 为接缝 PSNR(≥ 40 dB);三层都 `pass` 才是 `PASS`。
最后两行必须是:

```
✓ N creative assets pass the spec, compliance and narrative layers
✓ dist/<app>/assets-manifest.json: N entries match the contract (ascpub <commit> (schema 1, <sha>…)) and their files; real_ui from the review: R of N
```

### 10.3 校验层内容

| 层 | 检查 |
| --- | --- |
| 配置(不需录制) | 契约格式;规格与展示位;ASC locale;画面存在;循环模板 / 节奏 / 时长下限 / 海报 / 静音开场;文案;背景与授权映射;listing 页面存在、绑定 id 有产出、货架与 listing 一致 |
| 规格 | 扩展名 = 真实格式;完整解码;尺寸逐像素 / 比例精确;无 alpha;大小;fps、时长、编码、无音轨、无旋转 |
| 合规 | 通用素材无文字;安全区;画面不放大;违禁词;授权齐全;来源有哈希 |
| 叙事 | 对比度;静音开场;海报在成品画面;循环接缝 |
| 清单 | ascpub schema;哈希与实测值一致;截图集合 `real_ui` 过半 |

---

## 11. 审核与发布(ascpub)

在 listing 所在仓库根执行(`.env` 在此)。每个写命令先 `--dry-run`;非交互环境缺 `--yes` 会失败(退出码 6)。

| 步骤 | 命令 | 前置条件 / 结果 |
| --- | --- | --- |
| 0 自检 | `ascpub doctor --remote` | 资产库可读、规格目录、是否已有获批版本、在途提交 |
| 1 规格漂移 | `ascpub assets refdata --diff` | 随包快照与实时目录比较 |
| 2 上传 | `ascpub assets push -b <bundle> --dry-run`,确认后 `--yes`(`--all` 全部、`--entry <id>` 单条) | → `PREPARE_FOR_SUBMISSION`;不送审、不绑定 |
| 3 状态 | `ascpub assets status -b <bundle>` | 本地记录 × 远端原始状态 |
| 4 送审 | `ascpub assets submit -b <bundle> --dry-run`,确认后 `--submit --yes` | **需已有获批版本**;首发版本的素材随版本一起审 |
| 5 上架 | `ascpub placements plan -b <bundle>` → `placements apply -b <bundle> --dry-run` → `placements apply -b <bundle> --live --locale <一个> --yes` → 读回 | 在审版本一律锁定;live 只用已获批素材 |
| 6 回滚 | `ascpub placements unlink …` / `ascpub placements restore --snapshot <runId>` | 解绑不删资产;按快照恢复 |
| 7 观察 | `ascpub assets observe --surface store_page --locale en-US --device "<机型> / iOS <版本>" --storefront US --result seen` | 人工观察记录 |
| 8 报表 | `ascpub analytics request --yes` → 1–2 天后 `ascpub analytics pull` → `ascpub analytics report [--page <Page Title>]` | Key 需报表权限;缺数不转 0 |

**同一素材的送审占用**：版本随附送审与独立素材送审是两条路径。已经在另一提交中等待审核的
Header/Search 素材，不能同时加入 App 版本审核。ai_studio 的本地回执记录过此冲突；应等待该提交获批，
或由有权限的人明确决定移出另一提交。本地校验通过不会解除远端占用。`Add for Review` 也不等于最终提交。
所有远端查询、上传、绑定和送审均属 ascpub 边界；本地生产工具不处理账户或审核状态。

**状态口径**:上传成功(`PREPARE_FOR_SUBMISSION`)≠ 已送审 ≠ 已获批(`APPROVED`;`ACCEPTED` 不是获批)≠ 已展示。

**ascpub 退出码**:0 成功 / dry-run · 2 本地校验 · 3 鉴权 · 4 前置条件不满足(含在审锁定)· 5 上游失败 ·
6 取消或缺 `--yes` · 7 部分成功 · 8 等待(未到终态)· 9 冲突(漂移、锁、占用)。
**store-preview 退出码**:0 成功 · 1 校验 / 配置 / 工具错误 · 64 未知命令。

---

## 12. 测试与验收

### 12.1 本地验收(交付门槛)

```sh
make asset-library APP=<app>
```

依次执行(`scripts/asset_library_check.sh`):

0. `store-preview vendor --check` / `integrate --check`:公共工具完整、workspace 与 Makefile 接入完整;
1. `store-preview listing`:货架与 listing 一致;
2. `store-preview validate --only creatives`:配置 + 清单先行核对归属/完整性/哈希/人工复核，再做全部素材三层校验;
3. `ascpub assets validate` / `cpp validate` / `ppo validate`(离线,listing 目录由 `listing --dir` 给出)。

成功末行:`✓ <app>: the creative assets, the shelves and ascpub's listing agree — ready for \`ascpub assets push --dry-run\``。
ascpub 固定输出的两条警告(「规格目录使用随包快照」「实验期间请避免…」)不是错误。

### 12.2 自动化测试

| 套件 | 命令 | 覆盖 |
| --- | --- | --- |
| store-preview | `cd packages/store_preview && flutter test`(不要用 `dart test`,FFI transformer 会崩) | 以当次运行日志计数；契约读取与锁定、ascpub 示例与反例、listing、货架推导 / 规则 / 写回 / 漂移 / 本地化过滤 / 空 id、new-creatives 全流程与错误输入、退役清理、原生工具并发构建、真实渲染与三层校验、vendor |
| store_preview_driver | `cd packages/store_preview_driver && flutter test` | 4 条 |
| ascpub | `npm test`(+ `npm run typecheck`、`npm run lint`) | 以该仓当次日志为准，含资产库 bundle 解析、doctor --remote |
| 架构 / 分析 | `make analyze`、`dart run arch_guard`、`make shellcheck` | 全仓 |

store-preview 测试需要 ascpub 检出(`$ASCPUB_ROOT` 或 `<工作区>/Tools/ASOShip`),渲染类测试需要 ffmpeg 与 swiftc。

### 12.3 对已有 App 的回归验证

工具升级后先运行 `vendor --check`、`integrate --check` 和 `make asset-library APP=<app>`。
先保存业务文件哈希及原清单；旧文件漂移时停止，不生成新清单覆盖证据。文件与清单一致时，才可检查确定性：

```sh
cp dist/<app>/assets-manifest.json /tmp/before.json
dart run store_preview manifest --app <app>
python3 -c "import json;a=json.load(open('/tmp/before.json'));b=json.load(open('dist/<app>/assets-manifest.json'));print(a['entries']==b['entries'])"
# True = 交付内容未变(只有 generated_at 与 generator.commit 会变)
```

2026-10-11 对 Songlet(127 条)执行结果为 `True`。

---

## 13. 新项目接入流程与完整操作案例

### 13.1 接入清单(约半天,之后每素材 × storefront 约 1 分钟)

| # | 步骤 | 命令 / 产出 | 预计 |
| --- | --- | --- | --- |
| 1 | 环境与 ascpub | §3、§4.1 | 30 min(首次) |
| 2 | 预览就绪 | `packages/store_preview/README.md` › New app(`new-app`、写场景、录制) | 1–3 h |
| 3 | 授权背景图 | `media/manifest.json` 里每个 storefront 一张图片(含 license id) | 10 min |
| 4 | 生成素材配置 | `new-creatives …` | 1 min |
| 5 | ascpub 建页并填写 | `ascpub assets init …`,填 CPP / PPO 字段 | 15 min |
| 6 | 写入货架 | `listing --write` | 1 min |
| 7 | 翻译文案、导出、配置校验 | 改 ARB → `captions` → `validate --config-only` | 15 min |
| 8 | 需要视频时 | capture 脚本 + 视频素材 + 调 `shelf:` | 30 min |
| 9 | 渲染 | `render` 或 `creatives` | 每素材 × storefront 约 1 min |
| 10 | 人工复核 | 看 sheets → `review` → `manifest` | 每定义 2 min |
| 11 | 本地验收 | `make asset-library APP=<app>` | 1–15 min |
| 12 | 发布 | §11(需凭据,由人执行) | — |

### 13.2 完整操作案例(2026-10-11 本机实录)

场景:模板 App `studio_app`(bundle `org.vizgo.ai`,storefront `en-US`、`zh-Hans`),在一份全新检出里从「只有预览」开始,
建货架 + 专柜 `creators` + 实验 `header-motion`(treatment `Video`)。录像已存在于 `build/store_preview/studio_app/`。

**① 生成素材配置**

```sh
$ dart run store_preview new-creatives --app studio_app --ascpub ~/Developer/Tools/ASOShip --cpp creators --ppo header-motion:Video
✓ creative assets for studio_app: the shelf (store-page), 1 counter(s), 1 treatment(s); backdrop photo from A, footage from A
  + store_preview/studio_app/creatives/store-page.yaml
  + store_preview/studio_app/creatives/cpp-creators.yaml
  + store_preview/studio_app/creatives/ppo-header-motion-video.yaml
  ~ store_preview/studio_app/app.yaml: creatives
  ~ lib/l10n/arb/app_en.arb: 3 key(s)
  ~ lib/l10n/arb/app_zh.arb: 3 key(s)

Next (docs/store/asset-library-playbook.zh-CN.md):
  1. in ascpub's listing (run from this repo): ascpub assets init -b org.vizgo.ai --cpp creators --ppo header-motion
      fill each cpp/<slug>.yaml: name, locales (the localizations the page has; keywords from the approved version), deep link
      fill each ppo/<slug>.yaml: name, hypothesis, locales, and treatments named "Video"
  2. dart run store_preview listing --app studio_app --write
  3. translate the English phrases added to app_zh.arb (storeCreativeCppCreators)
  4. dart run store_preview captions --app studio_app; dart run store_preview validate --app studio_app --config-only
  5. dart run store_preview render --app studio_app (or creatives on recorded takes), then review, manifest
  6. make asset-library APP=studio_app
```

**② ascpub 建页并填写**

```sh
$ ascpub assets init -b org.vizgo.ai --cpp creators --ppo header-motion
✓ 写入 listings/org.vizgo.ai/assets.yaml
✓ 写入 listings/org.vizgo.ai/cpp/creators.yaml
✓ 写入 listings/org.vizgo.ai/ppo/header-motion.yaml
```

填写 `cpp/creators.yaml`:`name: "Creators"`,`locales` 加 `zh-Hans`;`ppo/header-motion.yaml`:
`name: "Header motion"`、`hypothesis`、`locales: [en-US, zh-Hans]`、treatment 改名 `"Video"`(完整字段见 §5.5)。

**③ 写入货架**

```sh
$ dart run store_preview listing --app studio_app --write
  app_store_version                  header          default (none) · 2 localization(s): header.en-US …
  app_store_version                  search_results  default (none) · 2 localization(s): search.en-US …
  custom_product_page:creators       header          default (none) · 2 localization(s): cpp.creators.header.en-US …
  custom_product_page:creators       search_results  default (none) · 2 localization(s): cpp.creators.search.en-US …
  ppo:header-motion:Video            header          default (none) · 2 localization(s): ppo.header-motion.video.header.en-US …
✓ wrote the shelves into listings/org.vizgo.ai/assets.yaml, listings/org.vizgo.ai/cpp/creators.yaml, listings/org.vizgo.ai/ppo/header-motion.yaml
```

**④ 翻译、导出、配置校验**:在 `app_zh.arb` 把 `storeCreativeCppCreators` 译为「为创作者而做」,然后

```sh
$ dart run store_preview captions --app studio_app
✓ captions: 2 storefronts → store_preview/studio_app/captions
$ dart run store_preview validate --app studio_app --config-only
✓ configuration: 2 script(s), 2 storefront(s), manifest complete, texts checked
```

**⑤ 渲染**

```sh
$ dart run store_preview creatives --app studio_app
…
cpp.creators.header.en-US               header_image  3840×1646  …  pass  pass  pass  PASS
…
search.zh-Hans                          search_image  3840×2560  …  pass  pass  pass  PASS
✓ 10 creative assets pass the spec, compliance and narrative layers
✓ dist/studio_app/assets-manifest.json: 10 entries match the contract (ascpub cdb606c (schema 1, 7f117bc76322…)) and their files; real_ui from the review: 0 of 10
```

**⑥ 人工复核**(看 `dist/studio_app/creative/sheets/` 后由人执行)

```sh
dart run store_preview review --app studio_app --asset "header.{storefront}" --real-ui true --reviewer <姓名>
# …每个素材定义一条…
dart run store_preview manifest --app studio_app
```

**⑦ 本地验收**

```sh
$ make asset-library APP=studio_app
▶ store-preview: the shelves in ascpub's listing
✓ listings/org.vizgo.ai holds the shelves
▶ store-preview: the configuration, every creative asset, the assets manifest
✓ 10 creative assets pass the spec, compliance and narrative layers
▶ ascpub (offline): listings/org.vizgo.ai
汇总: 0 个错误, 2 个警告
✓ 没有发现任何问题
汇总: 0 个错误, 1 个警告
✓ studio_app: the creative assets, the shelves and ascpub's listing agree — ready for `ascpub assets push --dry-run`
```

**⑧ 发布**:按 §11,由持有凭据的人执行。

模板仓库中提交的 studio_app 是同一流程的成品,并把 Header 视频作为 PPO treatment(`ppo-header-motion-video.yaml`,12 s `banner_loop`)。

---

### 13.3 从空白 Flutter App 冷启动

独立笔记应用 `reuse_notes` 的源样例、逐条命令及验收方法见
[复用操作手册](asset-library-reuse.zh-CN.md)。它用自己的 UI、场景、许可背景图和
Bundle ID，不复制 ai_studio 素材、路由或配置；历史交付复盘与当前限制见
[ai_studio 工程复盘](ai-studio-engineering-retrospective.zh-CN.md)。

## 14. 常见问题

**Q:素材已上传,为什么商店里看不到?**
上传 ≠ 送审 ≠ 获批 ≠ 上架。还需要 `assets submit`(需已有获批版本)、获批后 `placements apply`,并且只在 iOS 27+ 显示。

**Q:为什么 `assets push` 只传了几条?**
默认只上传被 listing 绑定的条目;`--all` 上传清单全部。

**Q:CPP 只做两个市场,其他 storefront 的素材怎么办?**
CPP 的 `locales` 只写这两个市场,货架只会绑定这两个;其余素材留在仓库,不会被上传(除非 `--all`)。

**Q:想把通用图换成本地化图 / 视频?**
改 `shelf:` → `listing --write` → 验收 → 上传、送审、`placements apply`。已上线 App 属于产品决策。

**Q:能在 CPP 上做 PPO 吗?** 不能(Apple 不支持),ascpub 会拒绝。

**Q:换了一台电脑,契约读不到?** 设 `ASCPUB_ROOT=<ascpub 检出>`。

**Q:ascpub 升级了契约?** store-preview 会停下并报 `the contract changed`;读完变更后更新 `schema_sha256`;
若 schema 版本号变了,先在模板适配,再 vendor 到各 App。

**Q:视频为什么一定要 12 / 15 秒?** Header 视频下限 10 s、Search 下限 15 s(取 Apple 各来源最严读法),
循环模板只提供 8 / 12 / 16(banner_loop)与 8 / 12 / 15(search_card)。

**Q:只用资产库、不用 ascpub 管元数据可以吗?** 可以。listing 只需 `assets.yaml`(ascpub ADR-0011),
`ascpub assets init -b <bundle>` 直接开始,`ascpub doctor --remote` 同样可用。

**Q:listing 在另一个仓库 / 工作区?** `new-creatives --listing <相对路径>` 或改 `creatives.ascpub.listing`;
`assets.yaml` › `manifest` 指向**执行 `listing --write` 的那个检出**的清单,换检出执行会被判为不一致。

---

## 15. 故障排查

跨项目故障统一记录在 [故障知识库](asset-library-troubleshooting.zh-CN.md)：触发条件、证据、根因、修复层及回归测试一起维护。

| 报错(摘要) | 原因 | 处理 |
| --- | --- | --- |
| `ascpub's assets-manifest.schema.json is …, the app follows …: the contract changed` | ascpub 契约变了 | 阅读变更,更新 `schema_sha256` |
| `no ascpub contract at …` / `no ascpub checkout at …` | 找不到 ascpub 检出 | 设 `ASCPUB_ROOT` 或修正 `creatives.ascpub.root` / `--ascpub` |
| `target …: ascpub's listing … declares no such page` | listing 没有该 CPP / PPO treatment | `ascpub assets init --cpp/--ppo`;treatment 名与 target 一致 |
| `… — `store-preview listing --app <app> --write` writes the shelves` | listing 与 `shelf:` 不一致 | `listing --app <app> --write` |
| `manifest: … is not this checkout's …` | `manifest` 指向另一个检出 | 在当前检出 `listing --write` |
| `creatives declare shelves for …: app.yaml creatives.ascpub.listing …` | 声明了货架但没配 listing | 配 `creatives.ascpub.listing` |
| `… binds X, which no creative definition makes` | 手写绑定的 id 不存在 | 改绑定或改用 `shelf:` |
| `shelf.header.default: … is made per {storefront}` | default 用了本地化素材 | default 只放通用素材 |
| `shelf.<slot>.locales: … is universal` | locales 用了通用素材 | 用含 `{storefront}` 的素材 |
| `… is also declared by creatives/…` | 两个定义声明同一页同一槽位 | 只保留一个 |
| `storefront … is not an App Store Connect locale` | storefront id 不是 ASC 代码 | 改 `app.yaml` storefront id |
| `the first scene lasts …; muted, the opening holds one scene for 2s` | 首场景 < 2 s | 加长首场景 |
| `… is outside the spec's 10.0–30.0 s` / `15.0–30.0 s` | 视频时长不够 | Header 用 12 / 16,Search 用 15 |
| `beat … lasts …, the … rhythm allows … ± 2.0s` | 节拍时长超出浮动 | 调场景 `duration` |
| `poster_at … is not inside a finished scene` | 海报帧不在成品画面 | 调 `poster_at` 或标记场景 `finished: true` |
| `… was filmed for X s … does not fit` | 录像不够长 | 调 `from` / `duration`,或延长场景 pause 重录 |
| `the backdrop … is missing for <sf>` / `not a licensed manifest item` | 背景图缺某个 storefront | 媒体清单补齐 |
| `… shows <role> media; app.yaml creatives.authorization maps no <role>` | 画面里的授权媒体没有映射字段 | 在 `authorization` 加映射 |
| `text … lacks the storeCreative prefix` / 违禁词 / 超长 | 文案不合规 | 改 ARB 后 `captions` |
| `contrast …` | 背景太亮 | 换背景,或 `layouts.<比例>.backdrop.brightness` 调暗(只能更严) |
| `loosens the default` | `layouts` 放宽了默认值 | 只能收紧 |
| `new-creatives: … holds no licensed image for every storefront` | 缺授权背景图 | 补媒体清单后重跑 |
| `new-creatives: … already has creative assets` | 已有素材配置 | 直接编辑现有配置 |
| `--cpp …: a custom product page is named once` / `the same treatment as …` | 重复输入 | 去重(一个文件都未写入) |
| `driver.dart_defines_file config/dev.json does not exist` | 新克隆没有本地配置 | `cp config/dev.example.json config/dev.json` 并填写 |
| `N not rendered` | 只渲染了部分 storefront | 预期行为;全量渲染后再写清单 |
| `ld: open() failed, errno=17 (File exists)` | 旧版本原生工具并发构建 | 升级到当前模板(已改为原子构建) |
| `dart test` 崩溃 | FFI transformer | 用 `flutter test` |
| ascpub `找不到 bundle id` / `没有任何 listing` | listing 目录既无 base.yaml 也无 assets.yaml | `ascpub assets init -b <bundle>` |
| ascpub `声明唯一变量为 header:每个 treatment 必须且只能改 header` | treatment 改了两个槽位 | treatment 的 `shelf:` 只声明变量槽位 |
| ascpub `引用的素材条目 … 不在 assets-manifest 中` | 清单未更新 | `store-preview manifest`,并确认 `manifest` 路径 |
| ascpub 退出码 4(在审锁定) | 版本 WAITING_FOR_REVIEW / IN_REVIEW | 等审核结束 |
| ascpub 退出码 3 | 鉴权 / Key 权限 | `ascpub doctor`;Analytics 需报表权限 |

---

## 16. 架构、模块与扩展方式

### 16.1 store-preview 模块(`packages/store_preview/lib/src/`)

| 模块 | 职责 |
| --- | --- |
| `creative/definition.dart` | 解析素材定义、`shelf:` |
| `creative/shelf.dart` | 货架推导、声明规则、漂移检查、写回(yaml_edit) |
| `creative/listing.dart` | 读 ascpub listing:页面、本地化、绑定、manifest 路径 |
| `creative/check.dart` | 不需录制的全部检查 |
| `creative/composer.dart` · `layout.dart` · `graph.dart` | 合成图片与循环视频、EDL |
| `creative/validate.dart` · `measure.dart` · `specs.dart` | 三层校验、规格 |
| `creative/contract.dart` | 读取并锁定契约,JSON Schema 2020-12 校验 |
| `creative/review.dart` | 复核记录与失效 |
| `publish/assets_manifest.dart` | 写清单 |
| `publish/vendor.dart` | vendor 与漂移戳 |
| `scaffold/new_creatives.dart` | `new-creatives` |
| `cli/pipeline.dart` · `project.dart` · `cli.dart` | 编排、联系表、退役清理、命令行 |
| `post/tools.dart` | 原生辅助程序(按源码哈希缓存,原子构建) |

ascpub 对应模块:`schema/assets.ts`(listing 格式)、`schema/assets-manifest.ts`(契约)、`lib/assets-validate.ts` 与
`validate/bindings.ts` · `cpp.ts` · `ppo.ts`(离线规则)、`lib/asset-push.ts`(上传、幂等、对账)、
`lib/placement-plan.ts` · `placement-exec.ts`(展示位)、`commands/cpp.ts` · `ppo.ts` · `analytics.ts`。

### 16.2 决策记录

模板:0009 素材定义与版式 · 0010 契约归 ascpub · 0011 `real_ui` 只来自复核 · 0012 capture 脚本 ·
0013 规格取最严 · 0014 授权取主场景 · 0015 货架。ascpub:0007 契约 · 0010 在审锁定 · 0011 只用资产库的 bundle。

### 16.3 如何扩展(不改业务配置)

| 需求 | 改哪里 | 必做 |
| --- | --- | --- |
| 新 App | 只改配置(§4、§13) | — |
| 新循环模板 / 新节奏 | `packages/store_preview/templates/<id>.yaml`(`format: loop`,必须含 8 与 12 s 节奏);App 也可放自己的模板目录 | 测试 + 文档 |
| 新版式比例或参数 | `defaults/creative.yaml` › `layouts` | 测试 |
| Apple 新规格 / 新展示位 | `defaults/creative.yaml` › `specs` / `placements`;ascpub `creative-specs.ts`;listing 槽位映射 `ascpubSlotPlacements` | 两侧测试 + ADR + `creative-assets-specs.md` |
| 契约升级 | ascpub 先改 schema(升版本号)→ 模板适配 `contract.dart` / `assets_manifest.dart` → 各 App 更新 `schema_sha256` | ADR |
| 工具任何改动 | 只在模板改 → `flutter test` → 各 App `vendor --from <模板> --root <App>` | `vendor --check` |

可持续演进要点:规格与阈值集中在 `defaults/`;App 差异集中在 `store_preview/<app>/`;listing 格式只由 ascpub 定义;
两工具之间只有两个接口——清单(JSON Schema,SHA 锁定)与 listing 的槽位块(ADR-0015),任一侧变化都会被校验拦下。


## 17. CPP 设备截图序列（2026-10-12 扩展）

Header/Search 之外，旧系统 CPP 需要设备截图。新增能力不修改 §0 的职责边界。
素材定义的 slot 显式声明 `device`、`display_target`、`app_screenshot` placement，
使用 `screenshot_iphone_6_9` 或 `screenshot_ipad_13`。录制配置须包含对应设备；
不得用手机截图改尺寸冒充 iPad 实录。

`shelf.media_sets` 按设备组列出有序 ID 模板，结构和完整示例见
`packages/store_preview/README.md` 的 Ordered CPP screenshots。`listing --write`
只负责这些绑定，CPP schema 2、名称、文案、关键词、深链及可见性仍由 ascpub listing 管理。
未声明组不清空；同一组只允许一个定义拥有；次序漂移也报错。

ascpub ADR-0012 将**显式绑定到 CPP media_sets** 的截图/预览纳入素材库上传。
默认页 deliver 与未绑定传统素材保留原路径。远端首次执行必须先 dry-run，
授权后再写入并逐个 locale×device 读回顺序；不能把模拟服务通过当作 Apple 实测。

渲染不产生人工复核结论。即使来源是真实录屏，没有人工记录仍为 `real_ui: false`，
截图真实性闸门将报错。应先完成所有产物和联系表，交人复核后再生成 manifest 和验收，
不删除校验、改成警告或伪造记录以追求 0 错误。
