/// Port the [AuthInterceptor] uses to inject the bearer token, refresh on
/// `40102`, and clear the session on `40106`.
///
/// infra_core owns this interface (so the interceptor has no reverse dependency
/// on commerce_kit); commerce_kit implements it and overrides the provider.
abstract interface class AuthGateway {
  /// The current access token, or null when unauthenticated.
  String? get accessToken;

  /// Attempts a single-flight token refresh. Returns true on success. Must use
  /// a Dio without the [AuthInterceptor] to avoid recursion.
  Future<bool> refresh();

  /// Clears the local session (tokens) on an unrecoverable auth failure.
  Future<void> forceLogout();
}

/// Default no-op gateway used until commerce_kit overrides the provider. It is
/// a real implementation (not a placeholder): an app with no auth simply stays
/// unauthenticated.
final class UnauthenticatedAuthGateway implements AuthGateway {
  const UnauthenticatedAuthGateway();

  @override
  String? get accessToken => null;

  @override
  Future<bool> refresh() async => false;

  @override
  Future<void> forceLogout() async {}
}
