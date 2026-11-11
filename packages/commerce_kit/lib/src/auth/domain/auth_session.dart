import 'package:meta/meta.dart';

/// In-memory session: the token pair plus the identity established by
/// guest-register / login / refresh.
@immutable
class TokenBundle {
  const TokenBundle({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.isGuest,
    this.expiresAt,
    this.isNewUser = false,
  });

  final String accessToken;
  final String refreshToken;
  final String userId;
  final bool isGuest;

  /// Access-token expiry decoded from the JWT (used for proactive refresh).
  final DateTime? expiresAt;

  /// Only meaningful right after guest-register.
  final bool isNewUser;

  TokenBundle copyWith({String? userId, bool? isGuest, DateTime? expiresAt}) =>
      TokenBundle(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userId ?? this.userId,
        isGuest: isGuest ?? this.isGuest,
        expiresAt: expiresAt ?? this.expiresAt,
        isNewUser: isNewUser,
      );
}

/// The `app` block sent on guest-register, identifying the distribution.
@immutable
class AppDescriptor {
  const AppDescriptor({
    required this.distributionCode,
    required this.appCode,
    required this.bundleId,
    required this.channel,
  });

  final String distributionCode;
  final String appCode;
  final String bundleId;
  final String channel;

  Map<String, dynamic> toJson() => {
        'distribution_code': distributionCode,
        'app_code': appCode,
        'bundle_id': bundleId,
        'channel': channel,
      };
}
