import 'package:meta/meta.dart';

import '../../common/billing.dart';

/// The aggregated current-account context returned by `GET /v1/auth/me`.
@immutable
class CurrentAccount {
  const CurrentAccount({
    required this.userId,
    required this.nickname,
    required this.accountType,
    required this.role,
    required this.status,
    required this.isGuest,
    required this.guidance,
    this.avatarUrl,
    this.email,
    this.phone,
    this.tenantId = 0,
    this.createdAt,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.profileComplete = false,
    this.subscription,
    this.wallet,
    this.features = const <WalletFeature>[],
    this.session,
    this.permissions = const <String>[],
  });

  final String userId;
  final String nickname;
  final String accountType; // personal / guest
  final String role;
  final String status; // active / frozen / disabled
  final bool isGuest;
  final Guidance guidance;

  final String? avatarUrl;
  final String? email; // masked by server
  final String? phone; // masked by server
  final int tenantId;
  final DateTime? createdAt;
  final bool emailVerified;
  final bool phoneVerified;
  final bool profileComplete;

  final Subscription? subscription;
  final WalletSnapshot? wallet;
  final List<WalletFeature> features;
  final SessionInfo? session;
  final List<String> permissions;
}

/// Session metadata; degrades to null in the `/me` aggregation.
@immutable
class SessionInfo {
  const SessionInfo({
    this.loginTime,
    this.loginIp,
    this.loginAuthType,
    this.deviceId,
    this.activeSessionCount = 0,
  });

  final DateTime? loginTime;
  final String? loginIp;
  final String? loginAuthType;
  final String? deviceId;
  final int activeSessionCount;
}

/// Pure-computed guidance flags; always present in `/me`.
@immutable
class Guidance {
  const Guidance({
    required this.needsProfileComplete,
    required this.hasActiveSubscription,
    required this.hasCredits,
  });

  final bool needsProfileComplete;
  final bool hasActiveSubscription;
  final bool hasCredits;
}
