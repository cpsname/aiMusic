import Foundation
import OSLog
import StoreKit
import UIKit

/// StoreKit 2 for the Songlet bridge (PRD §6.4 / §8): product lookup, purchase
/// bound to the StoreKit `appAccountToken`, `Transaction.currentEntitlements`,
/// and the app-lifetime `Transaction.updates` listener.
///
/// Finishing policy. The fixed bridge has no "finish" call, so this side owns
/// `Transaction.finish()`:
/// * a purchase is finished right after StoreKit verifies it — its JWS travels
///   back to Dart in the same reply, where the entitlement sync persists it until
///   the server acknowledges it (and the server also gets App Store Server
///   Notifications V2 for the same transaction);
/// * an update (renewal, Ask-to-Buy approval, refund/revocation, re-delivery) is
///   finished only after `onTransactionUpdated` was **delivered** to Dart. If the
///   Flutter side is not listening yet (cold start), the JWS stays queued and is
///   re-sent on the next bridge call, so nothing is finished unseen.
@MainActor
final class StoreKitService {
  typealias Deliver = (String, @escaping (Bool) -> Void) -> Void

  private static let log = Logger(subsystem: "com.songlet.ios", category: "StoreKit")

  private var updatesTask: Task<Void, Never>?
  private var queued: [(jws: String, transaction: Transaction)] = []
  private var flushing = false
  private let deliver: Deliver

  init(deliver: @escaping Deliver) {
    self.deliver = deliver
  }

  deinit { updatesTask?.cancel() }

  /// Starts the app-lifetime listener. Idempotent. Also drains transactions
  /// left unfinished by a previous run (e.g. the app was killed mid-purchase).
  func startListening() {
    guard updatesTask == nil else { return }
    updatesTask = Task { [weak self] in
      for await unfinished in Transaction.unfinished {
        self?.enqueue(unfinished)
      }
      for await update in Transaction.updates {
        self?.enqueue(update)
      }
    }
  }

  /// Re-sends queued updates. Called whenever Dart talks to the bridge (it is
  /// demonstrably listening then).
  func flushPending() {
    guard !flushing, let next = queued.first else { return }
    flushing = true
    deliver(next.jws) { [weak self] delivered in
      guard let self else { return }
      Task { @MainActor in
        self.flushing = false
        guard delivered else { return }
        self.queued.removeFirst()
        await next.transaction.finish()
        self.flushPending()
      }
    }
  }

  func fetchProducts(ids: [String]) async throws -> [SKProductDto] {
    let products = try await Product.products(for: ids)
    let storefront = await Storefront.current?.countryCode
    var dtos: [SKProductDto] = []
    // Keep the caller's order (StoreKit returns an unordered set).
    for id in ids {
      guard let product = products.first(where: { $0.id == id }) else { continue }
      dtos.append(await Self.dto(for: product, storefront: storefront))
    }
    return dtos
  }

  func purchase(productId: String, appAccountToken: String) async throws -> PurchaseResultDto {
    let result: PurchaseResultDto
    do {
      result = try await runPurchase(productId: productId, appAccountToken: appAccountToken)
    } catch {
      Self.log.error(
        "purchase \(productId, privacy: .public) threw: \(String(describing: error), privacy: .public)")
      throw error
    }
    Self.log.notice(
      "purchase \(productId, privacy: .public) → \(result.status, privacy: .public) \(result.errorMessage ?? "", privacy: .public)")
    return result
  }

  private func runPurchase(productId: String, appAccountToken: String) async throws -> PurchaseResultDto {
    guard let product = try await Product.products(for: [productId]).first else {
      return PurchaseResultDto(status: "failed", productId: productId, errorMessage: "product_not_found")
    }
    var options: Set<Product.PurchaseOption> = []
    // StoreKit silently drops a non-UUID token, so only a valid UUID is attached.
    if let token = UUID(uuidString: appAccountToken) {
      options.insert(.appAccountToken(token))
    }

    let result: Product.PurchaseResult
    if let scene = Self.purchaseScene() {
      Self.log.notice(
        "purchase \(productId, privacy: .public): presenting in scene (state \(scene.activationState.rawValue, privacy: .public))")
      result = try await product.purchase(confirmIn: scene, options: options)
    } else {
      Self.log.notice("purchase \(productId, privacy: .public): no window scene, presenting without one")
      result = try await product.purchase(options: options)
    }

    switch result {
    case .success(let verification):
      switch verification {
      case .verified(let transaction):
        let jws = verification.jwsRepresentation
        await transaction.finish()
        return PurchaseResultDto(
          status: "success",
          signedTransaction: jws,
          transactionId: String(transaction.id),
          productId: transaction.productID)
      case .unverified(_, let error):
        return PurchaseResultDto(
          status: "failed", productId: productId,
          errorMessage: "unverified: \(error.localizedDescription)")
      }
    case .pending:
      return PurchaseResultDto(status: "pending", productId: productId)
    case .userCancelled:
      return PurchaseResultDto(status: "userCancelled", productId: productId)
    @unknown default:
      return PurchaseResultDto(status: "failed", productId: productId, errorMessage: "unknown_result")
    }
  }

  /// JWS of every verified current entitlement (active subscriptions, plus any
  /// consumable not yet finished) — PRD §8.4 restore path.
  func currentSignedTransactions() async -> [String] {
    var result: [String] = []
    for await entitlement in Transaction.currentEntitlements {
      if case .verified = entitlement {
        result.append(entitlement.jwsRepresentation)
      }
    }
    return result
  }

  private func enqueue(_ result: VerificationResult<Transaction>) {
    // Unverified transactions are never forwarded (the server would reject them
    // anyway) and never finished — StoreKit keeps them for a later re-check.
    guard case .verified(let transaction) = result else { return }
    let jws = result.jwsRepresentation
    if queued.contains(where: { $0.transaction.id == transaction.id }) { return }
    queued.append((jws, transaction))
    flushPending()
  }

  /// The scene to present the purchase sheet in: the active one, else one
  /// that is merely inactive (a system alert is up, an iPhone app on iPad in
  /// compatibility mode), else any window scene. Only with no scene at all does
  /// the purchase fall back to the scene-less call.
  private static func purchaseScene() -> UIWindowScene? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    return scenes.first { $0.activationState == .foregroundActive }
      ?? scenes.first { $0.activationState == .foregroundInactive }
      ?? scenes.first
  }

  private static func dto(for product: Product, storefront: String?) async -> SKProductDto {
    let subscription = product.subscription
    let intro = subscription?.introductoryOffer
    let eligible = await subscription?.isEligibleForIntroOffer ?? false
    return SKProductDto(
      id: product.id,
      displayName: product.displayName,
      productDescription: product.description,
      displayPrice: product.displayPrice,
      price: NSDecimalNumber(decimal: product.price).doubleValue,
      currencyCode: product.priceFormatStyle.currencyCode,
      type: typeName(product.type),
      periodUnit: subscription.map { unitName($0.subscriptionPeriod.unit) },
      periodValue: subscription.map { Int64($0.subscriptionPeriod.value) },
      introPaymentMode: intro.map { paymentModeName($0.paymentMode) },
      introDisplayPrice: intro?.displayPrice,
      introPeriodUnit: intro.map { unitName($0.period.unit) },
      introPeriodValue: intro.map { Int64($0.period.value) },
      introPeriodCount: intro.map { Int64($0.periodCount) },
      isEligibleForIntroOffer: eligible,
      storefrontCountryCode: storefront)
  }

  private static func typeName(_ type: Product.ProductType) -> String {
    switch type {
    case .autoRenewable: return "autoRenewable"
    case .consumable: return "consumable"
    case .nonConsumable: return "nonConsumable"
    case .nonRenewable: return "nonRenewable"
    default: return "unknown"
    }
  }

  private static func unitName(_ unit: Product.SubscriptionPeriod.Unit) -> String {
    switch unit {
    case .day: return "day"
    case .week: return "week"
    case .month: return "month"
    case .year: return "year"
    @unknown default: return "month"
    }
  }

  private static func paymentModeName(_ mode: Product.SubscriptionOffer.PaymentMode) -> String {
    switch mode {
    case .freeTrial: return "freeTrial"
    case .payAsYouGo: return "payAsYouGo"
    case .payUpFront: return "payUpFront"
    default: return "unknown"
    }
  }
}
