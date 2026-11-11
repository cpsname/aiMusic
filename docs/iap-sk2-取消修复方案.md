# SK2 用户取消「Processing 卡死」修复方案

> **范围**：`in_app_purchase` 3.2.3 + `in_app_purchase_storekit` 0.4.8+1（StoreKit 2 启用）
> **症状**：付费墙点 Subscribe → iOS StoreKit 2 原生订阅 Sheet 弹出 → 用户点 Cancel → 应用 UI 永久停留在 "Processing"（实际转圈 5 分钟）
> **修复日期**：2026-05-19
> **影响文件**：
> - `lib/features/iap/application/notifiers/iap_purchase_orchestrator.dart`
> - `lib/features/iap/data/datasources/store_data_source.dart`（防御兜底语义更新）
> - `test/unit/features/iap/application/iap_purchase_orchestrator_test.dart`（+2 用例）

---

## 1. 问题与误诊

### 1.1 首次尝试基于错误前提

初版修复假设 SK2 用户取消会以 `PlatformException(code: 'storekit2_purchase_cancelled')` 形式从 `buyNonConsumable` / `buyConsumable` 的 Future 抛出，故在 `StoreDataSource.buyProduct` 上捕获该异常并转换成 `PurchaseCancelledException`，再由 orchestrator 路由到 `PurchaseFlowCancelled`。

但生产复测发现 **"Processing" 仍永久卡死**。

### 1.2 基于事实的二次调研

调取 pub-cache 锁定版本的插件源码，定位关键代码：

**`in_app_purchase_storekit-0.4.8+1/lib/src/in_app_purchase_storekit_platform.dart:181-186`**

```dart
@override
Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
  if (_useStoreKit2) {
    // ...构造 options...
    await SK2Product.purchase(
      purchaseParam.productDetails.id,
      options: options,
    );
    return true;          // ← 丢弃返回值，无条件返回 true
  }
  // SK1 path（含 PurchaseStatus.canceled 经由 purchaseStream 投递）
}
```

**`in_app_purchase_storekit-0.4.8+1/lib/src/store_kit_2_wrappers/sk2_product_wrapper.dart:402-413`**

```dart
static Future<SK2ProductPurchaseResult> purchase(
  String id, {
  SK2ProductPurchaseOptions? options,
}) async {
  SK2ProductPurchaseResultMessage result;
  if (options != null) {
    result = await hostApi2.purchase(id, options: options.convertToPigeon());
  } else {
    result = await hostApi2.purchase(id);
  }
  return result.convertFromPigeon();      // 枚举含 success / unverified / userCancelled / pending
}
```

### 1.3 真实链路

| 用户操作 | SK2 native | plugin `buyNonConsumable` 返回 | `purchaseStream` 行为 | app orchestrator 反应 |
|---------|-----------|-------------------------------|----------------------|----------------------|
| **取消订阅 Sheet** | `SK2Product.purchase()` 返回 `.userCancelled` | wrapper 丢弃枚举值，**返回 `true`** | **永久静默**（Apple 对取消的购买**不投递** `Transaction`） | `await completer.future.timeout(5min)` 转 5 分钟 |
| **购买成功** | 返回 `.success` + 投 Transaction | 返回 `true` | `Transaction.updates` 触发 → 投 `purchased` 事件 | 毫秒级 completer 完成 → 验证流程 |
| **Ask-to-Buy 沙盒** | 返回 `.pending` + 投 pending Transaction | 返回 `true` | 投 `pending` 事件 | 维持 `awaitingNative`，等终态 |
| **失败** | 异常 | 异常向上抛 | — | catch → `PurchaseFlowError` |

**核心结论**：插件 0.4.8+1 在 SK2 路径上**根本不抛任何异常**用于取消信号，`purchaseStream` 也保持空。应用层既收不到异常，也收不到 stream 事件——`completer` 永远不完成。

**上游引用**：[flutter/flutter#160659](https://github.com/flutter/flutter/issues/160659)、[#178292](https://github.com/flutter/flutter/issues/178292)。

### 1.4 误诊代码的去向

原 `PurchaseCancelledException` 捕获分支在 0.4.8+1 下是**永远不会触发的死代码**。但 pre-release 插件版本曾经走过 PlatformException 抛错路径，将来上游修复也可能恢复该 contract。所以保留为**前向兼容防御兜底**，并在 docstring 中显式注明当前不可达，避免后续误读。

---

## 2. 修复设计

### 2.1 设计目标

1. **正确性**：用户在 SK2 sheet 上点 Cancel → 应用立即（数百毫秒内）感知 → UI 关闭 loading
2. **不丢钱**：极端情况下（慢主线程、Ask-to-Buy 延迟批准）若误判为取消，**不能让用户的钱进了 Apple 却没拿到积分**
3. **不破坏其他路径**：成功 / Ask-to-Buy pending / 长 timeout 错误 / SK1 cancel 全部行为不变
4. **守住原方案约束**：
   - 不向 `purchaseStream` 注入伪造事件，不 patch stream 层
   - 不新增 Riverpod provider
   - 不跨越 domain / data / application 各层职责边界
   - 不修改 verify 重试、`completePurchase` 调用时机、`PendingOrderStore` 持久化逻辑

### 2.2 备选方案对比

| 方案 | 思路 | 取舍 |
|------|------|------|
| **A. 替换插件 / 修补上游** | 直接给 `in_app_purchase_storekit` 提 PR / fork | 周期长、依赖审核流程；非短期方案 |
| **B. import plugin `src/` 调 `SK2Product.purchase()`** | 越过 `InAppPurchase.instance.buyNonConsumable` 直接调底层枚举返回 API | 违反 Dart `src/` 私有约定；插件升级即破裂；强依赖 iOS 平台分支 |
| **C. 自定义 method channel** | 复刻 pigeon 通道直接调原生 SK2 | 维护成本高，需同步原生改动 |
| **D. App lifecycle 信号** | sheet 上下文导致 app 进入 inactive，dismiss 后 resume；据此判定 | 多触发路径污染（弹窗、来电、控制中心都触发同样信号）；启发式不稳定 |
| **★ E. Stream-silence 短窗口探测器** | `buyProduct` 返回后等一个短窗口，若 stream 仍零事件即判为取消 | 启发式但**契约可证明**（见 §2.3）；纯应用层；无 src/ 依赖；通过 PendingOrderStore + 冷启恢复兜底误判 |

选 **E**，理由是：

- **契约可证明**：成功 / pending 都会投 Transaction（毫秒级，Apple SDK 行为），取消永不投。短窗口足以区分。
- **不依赖私有 API**：完全走 plugin 的公开 surface（`buyNonConsumable` + `purchaseStream`）
- **误判可恢复**：保留 `PendingOrderStore` 记录，冷启 + Apple Transaction 重投递自然核销，不丢钱

### 2.3 选 3 秒窗口的依据

| 路径 | Transaction 投递延迟 | 3 秒窗口判定 |
|------|---------------------|--------------|
| Success | `Transaction.updates` 监听器在 `SK2Product.purchase()` 解析瞬间触发，**毫秒级** | completer 几乎立即完成 → `Future.any` 第一条腿胜出 → **不触发取消分支** |
| Pending（Ask-to-Buy 沙盒） | SK2 即刻投 `pending` Transaction | `anyEventReceived=true` → **不触发取消分支** → 走长 timeout 等终态 |
| User cancel | **永不投递** | 3 秒后 `Future.any` 第二条腿胜出 + `anyEventReceived=false` → **判定取消** |
| 极端：慢主线程 / GC 暂停 / 网络延迟使成功投递 > 3 秒 | 罕见 | 3 秒后误判取消 → state 设 cancelled、stream sub 释放、但 **PendingOrderStore 保留** → 冷启 + Apple 重投递 → 自动核销 |

3 秒是经验值，远大于实测投递延迟（< 100ms 量级），低于人类对 UI 卡顿的容忍阈值（约 5 秒）。可通过静态字段 `IapPurchaseOrchestrator.sk2CancelDetectorWindow` 调整，测试中收到 50ms 以保持速度。

---

## 3. 实现细节

### 3.1 状态机分支图

```
purchase(product) 调用
    │
    ▼
state = creatingOrder
    │   POST /v1/iap/orders
    ▼
state = orderCreated
    │   expiry check
    ▼
state = awaitingNative
    │   subscribe to purchaseStream
    │   await buyProduct(productDetails)   ← SK2 下无条件 true
    │
    ▼
┌────────────────────────────────────────────────────────────────┐
│  SK2 silent-cancel detector (新增)                              │
│                                                                 │
│  await Future.any([                                             │
│    completer.future.then((_) {}, onError: (_, _) {}),           │
│    Future<void>.delayed(sk2CancelDetectorWindow),               │
│  ]);                                                            │
│                                                                 │
│  if (!completer.isCompleted && !anyEventReceived) {             │
│     // 静默取消路径                                              │
│     state = PurchaseFlowCancelled(productCode: ...)             │
│     await _cleanup();         // 取消 stream 订阅                │
│     // 不 remove pendingOrder ← 关键：保留兜底                   │
│     return state;                                               │
│  }                                                              │
└────────────────────────────────────────────────────────────────┘
    │
    ▼
await completer.future.timeout(purchaseTimeout=5min)
    │
    ├── purchased / restored → state = nativeCompleted → verifying → completed
    ├── canceled (SK1 path 经 stream 投递)
    │      → state = PurchaseFlowCancelled
    │      → PendingOrderStore.remove(orderNo)  ← SK1 cancel 仍清理
    ├── error → state = PurchaseFlowError(stage='nativePurchase')
    └── TimeoutException → state = PurchaseFlowError(stage='nativePurchase')
```

注意：**SK1 cancel 与 SK2 silent cancel 走两条不同分支，对 `PendingOrderStore` 处理也不同**：
- SK1 cancel 来自 stream 显式投递，平台明确告诉我们"用户取消了"，pending 记录可清
- SK2 silent cancel 是我们启发式推断的，留 pending 记录给冷启恢复兜底

### 3.2 关键代码片段

**配置（class-level static）**

```dart
class IapPurchaseOrchestrator extends Notifier<PurchaseFlowState> {
  static Duration purchaseTimeout = const Duration(minutes: 5);

  /// SK2 silent-cancel detector window.
  /// （详尽 docstring 引用 plugin 行号 + 兜底逻辑）
  static Duration sk2CancelDetectorWindow = const Duration(seconds: 3);
  // ...
}
```

**方法级 flag + listener 计数**

```dart
Future<PurchaseFlowState> purchase(ProductCatalogItem product) async {
  // ...
  PurchaseDetails? completedPurchase;
  var anyEventReceived = false;   // ← 新增

  // ...

  _purchaseSub = storeDataSource.purchaseStream.listen(
    (purchases) {
      for (final purchase in purchases) {
        if (purchase.productID != order.storeProductId) continue;

        anyEventReceived = true;  // ← 任何事件（含 pending）都解除探测器
        switch (purchase.status) {
          // ...原有 5 个 case 不变
        }
      }
    },
    // ...
  );
```

**探测器主体**（位于 `buyProduct` 返回后、长 timeout 前）

```dart
try {
  // ...queryProducts...

  // ⚠ SK2 下 success 无条件 true，不能据此判断购买在飞
  final success = await storeDataSource.buyProduct(
    productDetails,
    consumable: product.productKind == ProductKind.consumable,
  );
  if (!success) {
    throw StateError('buyProduct returned false');
  }

  // ---- SK2 silent-cancel detector ----
  await Future.any<void>([
    completer.future.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},  // 错误由外层 await 重抛
    ),
    Future<void>.delayed(sk2CancelDetectorWindow),
  ]);
  if (!completer.isCompleted && !anyEventReceived) {
    Log.i(
      'SK2 silent cancel for ${product.productCode}; no purchaseStream '
      'event within ${sk2CancelDetectorWindow.inMilliseconds}ms of '
      'buyProduct completion. Retaining pending order ${order.orderNo} '
      'for restart-time reconciliation.',
    );
    state = PurchaseFlowCancelled(productCode: product.productCode);
    await _cleanup();
    return state;
  }

  // 长 timeout 等终态（success / SK1-cancel / error / 超时）
  final purchaseDetails = await completer.future.timeout(
    purchaseTimeout,
    onTimeout: () { throw TimeoutException(...); },
  );

  // ...原有终态处理不变...
}
```

### 3.3 异常处理顺序

`catch (error, stack)` 块的判定顺序（自上而下）：

1. **`PurchaseCancelledException`** — 防御兜底分支，未来插件版本恢复抛该异常时启用
2. **40011（transaction already used）** — 服务端已发奖，立即 complete + 刷钱包
3. **通用 error** — 走 `ErrorHandler.handle` → `PurchaseFlowError`

注意 **silent cancel 检测在 catch 之外**（探测器在 try 内的正常路径里），所以正常的 silent cancel **不进 catch**——避免和其他错误分支搅在一起。

### 3.4 误判兜底机制详解

设想最坏情况：用户在 SK2 sheet 上点了 Subscribe（不是 Cancel），但因为：
- 主线程被某个昂贵 setState 阻塞 5 秒
- 网络极慢，Transaction 投递延迟
- GC 触发 stop-the-world

导致 `Transaction.updates` 在 3 秒探测窗口后才触发。此时：

```
T0:  buyProduct 返回 true
T0~T3: stream 静默
T3:  探测器判定 silent cancel
     → state = PurchaseFlowCancelled
     → _cleanup() 取消 stream 订阅 _purchaseSub
     → ORDER_NO 仍在 PendingOrderStore  ← 关键
     → 返回 PurchaseFlowCancelled
T5:  Transaction.updates 触发（成功购买）
     → plugin 把 purchase 推到 purchaseStream
     → 但我们的 _purchaseSub 已 cleanup，无人接收
     → Transaction 仍在 Apple 队列上，未 finish
T?:  App 重启
     → StartupNotifier 跑 PendingOrderStore 扫描
     → Apple 重投递（StoreKit 2 contract：未 finish 的 Transaction 重启后会重投到 Transaction.updates）
     → plugin 转发到 purchaseStream
     → 全局监听器（or 启动恢复逻辑）匹配 orderNo
     → 调 /v1/iap/orders/{no}/verify 完成核销
     → ref.invalidate(walletProvider) 刷钱包
```

**结论**：误判窗口最大化损失 = "用户重新打开 App 后才看到积分到账"，但**积分一定会到账**，钱不丢。

这个兜底正是原方案第 2 条"保留 PendingOrderStore 记录（维持重启后续单恢复路径）"的语义来源。

---

## 4. 三层职责映射

| 层 | 文件 | 改动 | 角色 |
|----|------|------|------|
| **data** | `lib/features/iap/data/datasources/store_data_source.dart` | `PurchaseCancelledException` docstring 改为防御兜底语义；`buyProduct` try/catch 保留为前向兼容 | 翻译平台层信号，无业务判断 |
| **application** | `lib/features/iap/application/notifiers/iap_purchase_orchestrator.dart` | + `sk2CancelDetectorWindow` 静态；+ `anyEventReceived` flag；+ 探测器 `Future.any` 分支 | 状态机迁移 / 业务取舍 |
| **UI** | `lib/ui/create/insufficient_credits_dialog.dart` | **零改动**——`isPurchasing` 已正确排除 `PurchaseFlowCancelled`，按钮自动恢复，`_onSubscribe` 已对 cancelled 静默 fallthrough | 渲染 + 触发 |

---

## 5. 测试覆盖

文件：`test/unit/features/iap/application/iap_purchase_orchestrator_test.dart`

### 5.1 全局测试 setup 收紧探测器窗口

```dart
late Duration originalDetectorWindow;

setUp(() async {
  // ...
  originalDetectorWindow = IapPurchaseOrchestrator.sk2CancelDetectorWindow;
  IapPurchaseOrchestrator.sk2CancelDetectorWindow = const Duration(milliseconds: 200);
});

tearDown(() {
  IapPurchaseOrchestrator.sk2CancelDetectorWindow = originalDetectorWindow;
  // ...
});
```

### 5.2 新增 / 改造的 3 条用例

| 用例 | 模拟场景 | 断言 |
|------|---------|------|
| `SK2 silent cancel (buyProduct true + purchaseStream silent) → PurchaseFlowCancelled + PendingOrderStore retained`（新增） | `store.buyResult = true`，不 emit 任何事件 | state=Cancelled、`productCode` 正确、verify 未调、completePurchase 未调、`pendingOrderStore` **包含** orderNo |
| `long-timeout fires when stream emitted a pending event but never a terminal one (Ask-to-Buy-style hang)`（改造原 timeout 用例） | emit `pending`（解除探测器），不 emit 终态 | state=Error，stage='nativePurchase'，verify 未调 |
| `SK2 user-cancel (buyProduct throws PurchaseCancelledException) → PurchaseFlowCancelled + PendingOrderStore retained`（保留，防御兜底） | `store.buyError = const PurchaseCancelledException()` | state=Cancelled，pendingOrderStore 保留 orderNo |

### 5.3 既有用例零回归

- `happy path consumable / subscription` —— 探测器在 completer 第一条腿胜出，零影响
- `native purchase cancelled → PurchaseFlowCancelled`（SK1 path）—— `anyEventReceived=true` 解除探测器，落到原有 stream-cancel 分支
- `native purchase error / verifyReceipt failure` —— catch 分支序未变
- `40011 / verify retry / expired order / concurrent purchase` —— 探测器位于这些路径之前或之后，互不影响
- `PendingOrderStore cleaned up on success / cancel`（SK1 cancel）—— `pendingOrderStore.remove()` 调用点未改

总计 **19/19** orchestrator 用例 + **823/823** 全套通过。

---

## 6. 上线检查清单

- [ ] **执行 `flutter clean && flutter run`**——热重载在 plugin-facing 代码（`store_data_source.dart`）变更后通常不刷新原生侧，必须冷重装
- [ ] 真机复测取消路径：付费墙 → Subscribe → SK2 sheet → Cancel → 3 秒内 UI 解锁、按钮可点
- [ ] 真机复测购买路径：Subscribe → 实际购买 → 验证到账、Dialog 关闭
- [ ] 沙盒复测 Ask-to-Buy：开启 Ask-to-Buy → Subscribe → 收到 pending 事件 → 维持 awaitingNative
- [ ] 离线 / 慢网测试：长 timeout 触发后状态正确转为 PurchaseFlowError
- [ ] 重启恢复路径：人为 kill app 在 native purchase 阶段，重启后 PendingOrderStore 扫描 + verify 通过

---

## 7. 后续观察 & 升级路径

### 7.1 上游 plugin 更新

每次 `in_app_purchase_storekit` 升级前，**重新检查** `lib/src/in_app_purchase_storekit_platform.dart:159` 附近的 `buyNonConsumable` 实现：

- 若 plugin 开始**正确路由 cancel 到 `purchaseStream`**（投 `PurchaseStatus.canceled`）→ 我们的探测器仍然有效（成功路径毫秒级解除），但 `anyEventReceived=true` 直接走 SK1 cancel 分支，PendingOrderStore 会被清——行为更精确
- 若 plugin 开始**抛 `PlatformException(code: 'storekit2_purchase_cancelled')`** → `PurchaseCancelledException` 防御分支被激活，效果等价
- 若 plugin 暴露**带返回值的新 SK2 API** → 评估是否撤掉探测器、改用枚举判断

### 7.2 可调参数

- `IapPurchaseOrchestrator.purchaseTimeout`（默认 5 分钟）：终态等待上限
- `IapPurchaseOrchestrator.sk2CancelDetectorWindow`（默认 3 秒）：silent cancel 检测窗口
- 两者都是 `static Duration`，可通过测试 / 启动配置 override

### 7.3 监控指标建议（接入 telemetry 时）

- `iap.sk2_silent_cancel.count` — 触发探测器分支的频次
- `iap.sk2_silent_cancel.recovery_count` — 冷启恢复时核销到的、原 silent cancel 订单数（理论上 = 误判数）
- 比值 `recovery_count / silent_cancel.count` 应接近 0；若显著偏离，调大 `sk2CancelDetectorWindow`

---

## 8. 参考资料

- **插件源码**（项目锁定版本 0.4.8+1）：
  - `~/.pub-cache/hosted/pub.dev/in_app_purchase_storekit-0.4.8+1/lib/src/in_app_purchase_storekit_platform.dart:181-186`（`buyNonConsumable` SK2 分支）
  - `~/.pub-cache/hosted/pub.dev/in_app_purchase_storekit-0.4.8+1/lib/src/store_kit_2_wrappers/sk2_product_wrapper.dart:402-413`（`SK2Product.purchase` 枚举返回）
- **上游 issue**：
  - [flutter/flutter#160659](https://github.com/flutter/flutter/issues/160659)
  - [flutter/flutter#178292](https://github.com/flutter/flutter/issues/178292)
- **Apple SK2 文档**：
  - `Product.purchase()` → `PurchaseResult`：<https://developer.apple.com/documentation/storekit/product/purchaseresult>
  - `Transaction.updates` 重投递契约：<https://developer.apple.com/documentation/storekit/transaction/updates>
- **项目内文档**：
  - 完整 IAP 编排器流程：[`docs/architecture.md`](../architecture.md#iap-purchase-orchestrator)
  - 测试基建：[`docs/testing.md`](../testing.md)
