import '../../common/json.dart';
import '../domain/auth_session.dart';
import '../domain/jwt.dart';

/// `LoginResponse` / `TokenResponse` (login + refresh share this shape).
class TokenResponseDto {
  const TokenResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.accountType,
    this.userId,
    this.guestId,
  });

  factory TokenResponseDto.fromJson(Map<String, dynamic> json) =>
      TokenResponseDto(
        accessToken: asString(json['access_token']),
        refreshToken: asString(json['refresh_token']),
        expiresIn: asInt(json['expires_in']),
        accountType: json['account_type'] as String?,
        userId: json['user_id'] as String?,
        guestId: json['guest_id'] as String?,
      );

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String? accountType;
  final String? userId;
  final String? guestId;

  TokenBundle toDomain() {
    final claims = JwtUtils.decode(accessToken);
    final isGuest = accountType == 'guest' || guestId != null;
    return TokenBundle(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId ?? claims.subject ?? '',
      isGuest: isGuest,
      expiresAt: claims.expiresAt,
    );
  }
}

/// `GuestRegisterResponse` — independent shape (no `account_type`).
class GuestRegisterResponseDto {
  const GuestRegisterResponseDto({
    required this.userId,
    required this.guestId,
    required this.isNewUser,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory GuestRegisterResponseDto.fromJson(Map<String, dynamic> json) =>
      GuestRegisterResponseDto(
        userId: asString(json['user_id']),
        guestId: asString(json['guest_id']),
        isNewUser: asBool(json['is_new_user']),
        accessToken: asString(json['access_token']),
        refreshToken: asString(json['refresh_token']),
        expiresIn: asInt(json['expires_in']),
      );

  final String userId;
  final String guestId;
  final bool isNewUser;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  TokenBundle toDomain() => TokenBundle(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userId,
        isGuest: true,
        isNewUser: isNewUser,
        expiresAt: JwtUtils.decode(accessToken).expiresAt,
      );
}
