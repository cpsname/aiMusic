/// Backend envelope `code` values the client explicitly reacts to.
///
/// The authoritative, exhaustive list lives in `docs/api/error-codes.md`; only
/// the codes that drive client behaviour are named here.
abstract final class ApiCodes {
  // ── Auth (401xx) ──────────────────────────────────────────────────────────
  static const int invalidPassword = 40101;
  static const int tokenExpired = 40102; // → silent refresh + replay
  static const int refreshInvalid = 40103;
  static const int tokenRevoked = 40104;
  static const int sessionInvalid = 40105;
  static const int refreshReused = 40106; // → force logout
  static const int refreshMismatch = 40107;

  // ── Validation (400xx) ────────────────────────────────────────────────────
  static const int validationFailed = 40001; // carries field-level `details`

  // ── Payment (402xx) ───────────────────────────────────────────────────────
  static const int insufficientCredits = 40200;

  // ── App signature (overview §5.7 + iap) ───────────────────────────────────
  static const int signatureHeaderMissing = 40110;
  static const int signatureTimestampInvalid = 40111;
  static const int signatureExpired = 40112;
  static const int signatureNonceReused = 40113;
  static const int signatureInvalid = 40114;
  static const int iapSignatureInvalid = 40015;

  // ── IAP order / verify (iap BC) ───────────────────────────────────────────
  static const int orderNotPending = 40010; // → processing, back off
  static const int orderAlreadyUsed = 40011; // → treat as complete + refresh wallet
  static const int receiptInvalid = 40012;
  static const int orderVerifying = 40016; // → back off + retry
  static const int orderNotFound = 40405;
  static const int concurrentUpdate = 40912; // → auto retry
  static const int storeUnavailable = 50301;
  static const int storePlatformError = 50302;

  // ── Content moderation (451xx) ────────────────────────────────────────────
  static const int promptRejected = 45100;
  static const int contentFiltered = 45110;

  // ── Server ────────────────────────────────────────────────────────────────
  static const int serverError = 50000;
}
