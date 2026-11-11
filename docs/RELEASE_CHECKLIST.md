# 发布 Checklist(复制模板 → 上架一个具体产品)

模板阶段刻意不承载**产品身份与签名**(2026-08-27 决策):这些只在真正发包时才有意义,
且每个产品各不相同。本清单把它们固化为发包前的逐项检查——模板侧的守卫
(`make` GUARD/GUARD_SHIP、Xcode「Verify Build Config」、启动期 `ConfigFailure`)
只能拦住 *配置* 类错误,身份与签名仍需人工完成以下步骤。

## 1. 产品身份(复制仓后第一件事)

- [ ] **iOS/macOS Bundle ID**:Xcode → Runner target → `PRODUCT_BUNDLE_IDENTIFIER`
      (当前模板值 `org.vizgo.ai`);与 App Store Connect 中创建的 App 一致。
- [ ] **Android applicationId**:`android/app/build.gradle.kts` 的
      `namespace` / `applicationId`(当前模板值 `com.example.iap_template`),
      并同步 `android/app/src/main/kotlin/` 包路径。
- [ ] **双端一致性**:`config/*.json` 的 `BUNDLE_ID` 与上面两处一致
      (后端按它签发/校验)。
- [ ] **显示名**:`ios/Runner/Info.plist` `CFBundleDisplayName`(当前 "Iap Template")、
      `android/app/src/main/AndroidManifest.xml` `android:label`。
- [ ] App 图标 / 启动图(双端)。

## 2. 配置注入

- [ ] `config/prod.json`:从 `dev.example.json` 复制,填**全部**键——含
      `TERMS_URL` / `PRIVACY_URL`(store 构建守卫强制非空)。`BASE_URL` 必须
      https 且非 localhost(GUARD_SHIP 强制)。
- [ ] Xcode Archive 前:`make xcconfig`(iOS)/ `make macos-xcconfig`(macOS),
      **之后不要再跑 `make run`**;或直接 `make ipa` 一步到位。

## 3. 签名(模板不承载,逐产品配置)

- [ ] **iOS**:Xcode → Signing & Capabilities:Team、分发证书、Provisioning
      Profile(当前模板 Release 为 Manual + 空 Team,Archive 必须先配好)。
- [ ] **Android**:生成上传 keystore;`android/key.properties`(不入库);
      `android/app/build.gradle.kts` 将 release `signingConfig` 从 debug 桩换成
      读取 key.properties 的正式配置(当前模板仍是 Flutter 模板的 debug 桩——
      **不改则 `make aab` 产物 Play 必拒**);Play Console 开启 Play App Signing。
- [ ] 评估 R8/`shrinkResources`(模板未启用)。

## 4. 商店合规(模板已承载的部分打 ✓ 即可)

- [x] 隐私清单 `ios/Runner/PrivacyInfo.xcprivacy`(已挂 Resources,加原生依赖时同步)。
- [x] 出口合规 `ITSAppUsesNonExemptEncryption=false`(双端 Info.plist 已声明;
      若引入非豁免加密需改为申报)。
- [x] Paywall:法务链接三级兜底 + 自动续订披露 + 恢复购买(G1)。
- [x] 账号删除(游客生命周期,G2;正式账号待后端端点)。
- [ ] App Store Connect:隐私营养标签(若接入真实遥测 vendor,须同步申报采集类型,
      并更新 PrivacyInfo `NSPrivacyCollectedDataTypes`)。
- [ ] ASC 元数据文案过 `asc-copy-validator`(禁 emoji/特殊字符与长度限制)。
- [ ] 订阅商品在 ASC/Play Console 配置齐全并与后端 catalog 的 `storeProductId` 一致。

## 5. 发包与验证

- [ ] `make gates` 全绿(CI 同款入口)。
- [ ] `make ipa` / `make aab`(GUARD_SHIP 会强制 prod 配置完整性)。
- [ ] 真机 + 沙箱账号跑通:购买 → 权益下发 → 恢复购买 → 取消续订路径。
- [ ] 上传后核对 App Store Connect 处理无告警(出口合规不再弹问 = §4 声明生效)。
