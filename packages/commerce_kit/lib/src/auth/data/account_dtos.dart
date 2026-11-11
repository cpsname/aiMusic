import '../../common/billing.dart';
import '../../common/feature_dto.dart';
import '../../common/json.dart';
import '../domain/current_account.dart';

/// Parses `CurrentAccountResponse` from `GET /v1/auth/me`, degrading gracefully:
/// optional sections (subscription / wallet / session) may be absent, features
/// default to an empty list, and guidance is always derived.
class CurrentAccountDto {
  const CurrentAccountDto(this._json);

  factory CurrentAccountDto.fromJson(Map<String, dynamic> json) =>
      CurrentAccountDto(json);

  final Map<String, dynamic> _json;

  CurrentAccount toDomain() {
    final subscription = _subscription(_json['subscription']);
    final wallet = _wallet(_json['wallet']);
    final features = _features(_json['features']);
    return CurrentAccount(
      userId: asString(_json['user_id']),
      nickname: asString(_json['nickname']),
      accountType: asString(_json['account_type'], 'personal'),
      role: asString(_json['role'], 'user'),
      status: asString(_json['status'], 'active'),
      isGuest: asBool(_json['is_guest']),
      avatarUrl: _json['avatar_url'] as String?,
      email: _json['email'] as String?,
      phone: _json['phone'] as String?,
      tenantId: asInt(_json['tenant_id']),
      createdAt: dateFromEpochSeconds(_json['created_at']),
      emailVerified: asBool(_json['email_verified']),
      phoneVerified: asBool(_json['phone_verified']),
      profileComplete: asBool(_json['profile_complete']),
      subscription: subscription,
      wallet: wallet,
      features: features,
      session: _session(_json['session']),
      permissions: asStringList(_json['permissions']),
      guidance: _guidance(_json['guidance'], subscription, wallet),
    );
  }

  static Subscription? _subscription(Object? raw) {
    if (raw is! Map) return null;
    final json = asMap(raw);
    return Subscription(
      status: asString(json['status']),
      billingCycle: json['billing_cycle'] as String?,
      isAutoRenew: asBool(json['is_auto_renew']),
      currentPeriodEnd: dateFromEpochSeconds(json['current_period_end']),
      trialEndAt: dateFromEpochSeconds(json['trial_end_at']),
    );
  }

  static WalletSnapshot? _wallet(Object? raw) {
    if (raw is! Map) return null;
    final json = asMap(raw);
    return WalletSnapshot(
      balance: asInt(json['balance']),
      frozen: asInt(json['frozen']),
      totalCredited: asInt(json['total_credited']),
      totalDebited: asInt(json['total_debited']),
    );
  }

  static List<WalletFeature> _features(Object? raw) =>
      asMapList(raw).map(featureFromJson).toList(growable: false);

  static SessionInfo? _session(Object? raw) {
    if (raw is! Map) return null;
    final json = asMap(raw);
    return SessionInfo(
      loginTime: dateFromEpochSeconds(json['login_time']),
      loginIp: json['login_ip'] as String?,
      loginAuthType: json['login_auth_type'] as String?,
      deviceId: json['device_id'] as String?,
      activeSessionCount: asInt(json['active_session_count']),
    );
  }

  static Guidance _guidance(
    Object? raw,
    Subscription? subscription,
    WalletSnapshot? wallet,
  ) {
    if (raw is Map) {
      final json = asMap(raw);
      return Guidance(
        needsProfileComplete: asBool(json['needs_profile_complete']),
        hasActiveSubscription: asBool(json['has_active_subscription']),
        hasCredits: asBool(json['has_credits']),
      );
    }
    // Degrade: derive from the sections we did parse.
    return Guidance(
      needsProfileComplete: false,
      hasActiveSubscription: subscription?.isActive ?? false,
      hasCredits: (wallet?.balance ?? 0) > 0,
    );
  }
}
