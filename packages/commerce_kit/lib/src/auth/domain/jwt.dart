import 'dart:convert';

import 'package:meta/meta.dart';

/// Claims the client reads from an (unverified) access token. The server is the
/// only verifier; the client decodes `exp` for proactive refresh and `abid`
/// for the user id.
@immutable
class JwtClaims {
  const JwtClaims({
    this.subject,
    this.abid,
    this.expiresAt,
    this.role,
    this.sessionId,
  });

  /// The account id: the `abid` claim, or the standard `sub` as a fallback.
  /// Used broadly as "the current account/user id".
  final String? subject;

  /// The account **business id** (`abid`) specifically — no `sub` fallback.
  /// The IAP `appAccountToken`/`push_token` binding requires this exact value
  /// (see BACKEND_COORDINATION §3.1); a standard `sub` is not interchangeable.
  final String? abid;

  final DateTime? expiresAt;
  final String? role;
  final String? sessionId;
}

abstract final class JwtUtils {
  static JwtClaims decode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return const JwtClaims();
      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final map = jsonDecode(payload);
      if (map is! Map<String, dynamic>) return const JwtClaims();
      final exp = map['exp'];
      return JwtClaims(
        subject: (map['abid'] ?? map['sub']) as String?,
        abid: map['abid'] as String?,
        role: map['role'] as String?,
        sessionId: map['sid'] as String?,
        expiresAt: exp is int
            ? DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true)
            : null,
      );
    } on Object {
      return const JwtClaims();
    }
  }

  /// True when the token is expired or expires within [skew]. An undecodable
  /// expiry is treated as expired so the caller refreshes rather than sends a
  /// stale token.
  static bool isExpired(
    String token, {
    Duration skew = const Duration(seconds: 60),
    DateTime? now,
  }) {
    final expiresAt = decode(token).expiresAt;
    if (expiresAt == null) return true;
    final reference = (now ?? DateTime.now().toUtc()).add(skew);
    return !expiresAt.isAfter(reference);
  }

  /// True only when the token **decodes** to a JWT whose `exp` is at/before now
  /// (plus [skew]). Unlike [isExpired], an undecodable/opaque token returns
  /// `false` — we cannot prove an opaque refresh token is expired, so the caller
  /// should still attempt it and let the server decide. Used by 防线② to skip a
  /// doomed `/auth/refresh` only when the refresh token is provably stale.
  static bool isProvablyExpired(
    String token, {
    Duration skew = Duration.zero,
    DateTime? now,
  }) {
    final expiresAt = decode(token).expiresAt;
    if (expiresAt == null) return false;
    final reference = (now ?? DateTime.now().toUtc()).add(skew);
    return !expiresAt.isAfter(reference);
  }
}
