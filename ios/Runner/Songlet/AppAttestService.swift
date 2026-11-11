import CryptoKit
import DeviceCheck
import Foundation

/// App Attest for the Songlet bridge (PRD §6.3 `/v1/attest`, §14.1 anti-abuse).
///
/// `appAttestAssertion(challenge)` returns a JSON object string (the fixed
/// bridge returns a single `String`):
/// * `{"key_id", "attestation"}` — the first call for a freshly generated key
///   (`DCAppAttestService.attestKey`), which the server verifies once and stores;
/// * `{"key_id", "assertion"}` — every later call
///   (`DCAppAttestService.generateAssertion`);
/// * `{"unsupported": true}` — App Attest is unavailable: the simulator, or a
///   build signed without the App Attest capability (the app ships without it
///   since 2026-10-04 — `isSupported` can still say yes on a device, but key
///   generation then fails). The platform's attest gate lets it through in
///   `off` / `optional` mode and rejects it (40140) only in `required`; the dev
///   mock accepts it.
///
/// The client-data hash is `SHA256(challenge)`. A key the system reports as
/// invalid (reinstall / device restore) is discarded and re-attested.
final class AppAttestService {
  private static let keyIdDefaultsKey = "songlet.appattest.key_id"

  private let service = DCAppAttestService.shared
  private let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  func assertion(challenge: String) async throws -> String {
    guard service.isSupported else { return try Self.unsupported() }
    do {
      return try await attest(challenge: challenge)
    } catch is DCError {
      // No App Attest entitlement (or the service refuses this device): say
      // so instead of failing the login.
      return try Self.unsupported()
    }
  }

  private func attest(challenge: String) async throws -> String {
    let clientDataHash = Data(SHA256.hash(data: Data(challenge.utf8)))

    if let keyId = defaults.string(forKey: Self.keyIdDefaultsKey) {
      do {
        let assertion = try await service.generateAssertion(keyId, clientDataHash: clientDataHash)
        return try Self.json(["key_id": keyId, "assertion": assertion.base64EncodedString()])
      } catch let error as DCError where error.code == .invalidKey {
        defaults.removeObject(forKey: Self.keyIdDefaultsKey)
      }
    }

    let keyId = try await service.generateKey()
    let attestation = try await service.attestKey(keyId, clientDataHash: clientDataHash)
    defaults.set(keyId, forKey: Self.keyIdDefaultsKey)
    return try Self.json(["key_id": keyId, "attestation": attestation.base64EncodedString()])
  }

  private static func unsupported() throws -> String { try json(["unsupported": true]) }

  private static func json(_ object: [String: Any]) throws -> String {
    let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    return String(decoding: data, as: UTF8.self)
  }
}
