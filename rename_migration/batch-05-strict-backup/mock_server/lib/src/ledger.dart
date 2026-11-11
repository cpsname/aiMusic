import 'catalog.dart';
import 'core.dart';
import 'jws.dart';

/// Tolerance for a synced `purchaseDate` slightly ahead of the mock clock.
const int _purchaseSlackMs = 5 * 60 * 1000;

/// One App Store transaction the ledger has seen, keyed by `transactionId`
/// (re-syncing the same JWS updates it in place and never re-credits).
class TxRecord {
  TxRecord({
    required this.transactionId,
    required this.originalTransactionId,
    required this.productId,
    required this.accountId,
    required this.purchaseDate,
    this.originalPurchaseDate,
    this.expiresDate,
    this.type,
    this.storefront,
    this.offerType,
    this.revocationDate,
    this.packUsed = 0,
  });

  factory TxRecord.fromJson(Map<String, Object?> j) => TxRecord(
    transactionId: j['transaction_id']! as String,
    originalTransactionId: j['original_transaction_id']! as String,
    productId: j['product_id']! as String,
    accountId: j['account_id']! as String,
    purchaseDate: j['purchase_date']! as int,
    originalPurchaseDate: j['original_purchase_date'] as int?,
    expiresDate: j['expires_date'] as int?,
    type: j['type'] as String?,
    storefront: j['storefront'] as String?,
    offerType: j['offer_type'] as int?,
    revocationDate: j['revocation_date'] as int?,
    packUsed: (j['pack_used'] as int?) ?? 0,
  );

  final String transactionId;
  final String originalTransactionId;
  final String productId;

  /// The account that owns the purchase (the buyer's `app_account_token`, or
  /// an account it was later merged into — always read through
  /// [Ledger.resolve]).
  String accountId;
  final int purchaseDate;
  int? originalPurchaseDate;
  int? expiresDate;
  String? type;
  String? storefront;
  int? offerType;
  int? revocationDate;

  /// Pack songs consumed from this transaction (packs only).
  int packUsed;

  ProductSpec? get spec => Catalog.products[productId];

  bool get revoked => revocationDate != null;

  bool get isTrial => offerType == 1;

  bool get isSubscription => spec?.kind == ProductKind.subscription;

  bool get isPack => spec?.kind == ProductKind.pack;

  bool get isMvPack => spec?.kind == ProductKind.mvPack;

  int get packLeft =>
      isPack ? (spec!.packSongs - packUsed).clamp(0, 1 << 30) : 0;

  /// Subscription end; a JWS without `expiresDate` gets one billing period.
  int get effectiveExpiresDate =>
      expiresDate ??
      addMonths(
        DateTime.fromMillisecondsSinceEpoch(purchaseDate, isUtc: true),
        spec?.isYearly ?? false ? 12 : 1,
      ).millisecondsSinceEpoch;

  Map<String, Object?> toJson() => {
    'transaction_id': transactionId,
    'original_transaction_id': originalTransactionId,
    'product_id': productId,
    'account_id': accountId,
    'purchase_date': purchaseDate,
    'original_purchase_date': originalPurchaseDate,
    'expires_date': expiresDate,
    'type': type,
    'storefront': storefront,
    'offer_type': offerType,
    'revocation_date': revocationDate,
    'pack_used': packUsed,
  };
}

/// Per-account allowance usage. The account id is the `app_account_token`
/// that created it.
class Account {
  Account(this.id);

  factory Account.fromJson(Map<String, Object?> j) =>
      Account(j['id']! as String)
        ..freeClipsUsed = j['free_clips_used']! as int
        ..creditsUsed = (j['credits_used'] as int?) ?? 0
        ..songsUsed.addAll(_intMap(j['songs_used']))
        ..clipsUsed.addAll(_intMap(j['clips_used']))
        ..lastStorefront = j['last_storefront'] as String?
        ..lastStorefrontAt = (j['last_storefront_at'] as int?) ?? 0;

  final String id;
  int freeClipsUsed = 0;

  /// Music-video credits spent (contract v1.1 §5): drawn from the free pocket
  /// and the MV packs, never from song allowances.
  int creditsUsed = 0;

  /// Subscription usage per allowance window key.
  final Map<String, int> songsUsed = {};
  final Map<String, int> clipsUsed = {};

  /// Storefront of the most recent synced transaction (region + tier checks).
  String? lastStorefront;
  int lastStorefrontAt = 0;

  Map<String, Object?> toJson() => {
    'id': id,
    'free_clips_used': freeClipsUsed,
    'credits_used': creditsUsed,
    'songs_used': songsUsed,
    'clips_used': clipsUsed,
    'last_storefront': lastStorefront,
    'last_storefront_at': lastStorefrontAt,
  };

  static Map<String, int> _intMap(Object? raw) => raw is Map
      ? {for (final e in raw.entries) '${e.key}': (e.value as num).toInt()}
      : {};
}

/// Where a job's credit came from, so a failure refunds the same bucket and a
/// refunded purchase can lock the job's license.
class Charge {
  const Charge({
    required this.bucket,
    required this.kind,
    this.windowKey,
    this.transactionId,
  });

  factory Charge.fromJson(Map<String, Object?> j) => Charge(
    bucket: j['bucket']! as String,
    kind: j['kind']! as String,
    windowKey: j['window_key'] as String?,
    transactionId: j['transaction_id'] as String?,
  );

  static const String free = 'free';
  static const String subscription = 'subscription';
  static const String pack = 'pack';

  final String bucket;

  /// `clip` | `song`.
  final String kind;
  final String? windowKey;
  final String? transactionId;

  Map<String, Object?> toJson() => {
    'bucket': bucket,
    'kind': kind,
    'window_key': windowKey,
    'transaction_id': transactionId,
  };
}

/// The current allowance period of the active subscription.
class AllowanceWindow {
  const AllowanceWindow({
    required this.tx,
    required this.start,
    required this.end,
    required this.songs,
    required this.clips,
  });

  final TxRecord tx;
  final int start;
  final int end;
  final int songs;
  final int clips;

  String get key => '${tx.originalTransactionId}@$start';
}

class LedgerStatus {
  const LedgerStatus({
    required this.tier,
    required this.songsLeft,
    required this.clipsLeft,
    required this.resetAt,
  });

  final String tier;
  final int songsLeft;
  final int clipsLeft;
  final int? resetAt;

  Map<String, Object?> toJson() => {
    'tier': tier,
    'songs_left': songsLeft,
    'clips_left': clipsLeft,
    'reset_at': resetAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            resetAt!,
            isUtc: true,
          ).toIso8601String(),
  };
}

/// The credit ledger (contract §5 / PRD §8.4): free lifetime clips,
/// subscription allowances with monthly windows, never-expiring packs,
/// charge-at-creation + refund-on-failure, refund freezes, restore linking.
class Ledger {
  final Map<String, Account> accounts = {};

  /// `app_account_token` (or merged account id) → the account it now uses.
  final Map<String, String> links = {};

  final Map<String, TxRecord> transactions = {};

  void clear() {
    accounts.clear();
    links.clear();
    transactions.clear();
  }

  /// Follows restore links to the account [tokenOrAccountId] currently uses.
  String resolve(String tokenOrAccountId) {
    var id = tokenOrAccountId;
    for (var hops = 0; hops < 32 && links.containsKey(id); hops++) {
      id = links[id]!;
    }
    return id;
  }

  Account accountFor(String token) {
    final id = resolve(token);
    return accounts.putIfAbsent(id, () => Account(id));
  }

  Iterable<TxRecord> _transactionsOf(String accountId) =>
      transactions.values.where((t) => resolve(t.accountId) == accountId);

  // ── Sync ──────────────────────────────────────────────────────────────────

  /// Applies synced JWS transactions for [callerToken]. Returns whether the
  /// caller got linked to another account (restore on a new device).
  bool sync(String callerToken, List<SignedTransaction> signed) {
    var linked = false;
    for (final st in signed) {
      final existing =
          transactions[st.transactionId] ??
          transactions.values
              .where((t) => t.originalTransactionId == st.originalTransactionId)
              .firstOrNull;
      final String ownerId;
      if (existing != null) {
        ownerId = resolve(existing.accountId);
      } else if (st.appAccountToken != null) {
        ownerId = accountFor(st.appAccountToken!).id;
      } else {
        ownerId = accountFor(callerToken).id;
      }
      accounts.putIfAbsent(ownerId, () => Account(ownerId));
      if (resolve(callerToken) != ownerId) {
        _link(callerToken, ownerId);
        linked = true;
      }
      _upsert(st, ownerId);
    }
    return linked;
  }

  void _upsert(SignedTransaction st, String ownerId) {
    final record = transactions[st.transactionId];
    if (record == null) {
      transactions[st.transactionId] = TxRecord(
        transactionId: st.transactionId,
        originalTransactionId: st.originalTransactionId,
        productId: st.productId,
        accountId: ownerId,
        purchaseDate: st.purchaseDate,
        originalPurchaseDate: st.originalPurchaseDate,
        expiresDate: st.expiresDate,
        type: st.type,
        storefront: st.storefront,
        offerType: st.offerType,
        revocationDate: st.revocationDate,
      );
    } else {
      // Same transaction re-synced: refresh the mutable facts only; pack usage
      // and ownership are ledger state and never reset.
      record
        ..expiresDate = st.expiresDate ?? record.expiresDate
        ..revocationDate = st.revocationDate ?? record.revocationDate
        ..storefront = st.storefront ?? record.storefront
        ..originalPurchaseDate =
            st.originalPurchaseDate ?? record.originalPurchaseDate;
    }
    final account = accounts[ownerId]!;
    if (st.storefront != null && st.purchaseDate >= account.lastStorefrontAt) {
      account
        ..lastStorefront = st.storefront
        ..lastStorefrontAt = st.purchaseDate;
    }
  }

  /// Links [callerToken] to [ownerId], merging whatever the caller's previous
  /// account held (usage, free clips) so nothing it bought is orphaned.
  void _link(String callerToken, String ownerId) {
    final oldId = resolve(callerToken);
    final owner = accounts.putIfAbsent(ownerId, () => Account(ownerId));
    final old = accounts.remove(oldId);
    if (old != null) {
      old.songsUsed.forEach((k, v) {
        owner.songsUsed[k] = (owner.songsUsed[k] ?? 0) + v;
      });
      old.clipsUsed.forEach((k, v) {
        owner.clipsUsed[k] = (owner.clipsUsed[k] ?? 0) + v;
      });
      owner.freeClipsUsed = (owner.freeClipsUsed + old.freeClipsUsed).clamp(
        0,
        Catalog.freeLifetimeClips,
      );
      owner.creditsUsed += old.creditsUsed;
      if (old.lastStorefrontAt > owner.lastStorefrontAt) {
        owner
          ..lastStorefront = old.lastStorefront
          ..lastStorefrontAt = old.lastStorefrontAt;
      }
    }
    if (oldId != ownerId) links[oldId] = ownerId;
    if (callerToken != oldId) links[callerToken] = ownerId;
  }

  // ── Allowance ─────────────────────────────────────────────────────────────

  /// The active subscription's current allowance window, or null.
  AllowanceWindow? activeWindow(String token, int nowMs) {
    final accountId = resolve(token);
    final active =
        _transactionsOf(accountId)
            .where(
              (t) =>
                  t.isSubscription &&
                  !t.revoked &&
                  t.purchaseDate - _purchaseSlackMs <= nowMs &&
                  nowMs < t.effectiveExpiresDate,
            )
            .toList()
          ..sort((a, b) {
            final byRank = b.spec!.rank.compareTo(a.spec!.rank);
            return byRank != 0
                ? byRank
                : b.purchaseDate.compareTo(a.purchaseDate);
          });
    if (active.isEmpty) return null;
    final tx = active.first;
    final expires = tx.effectiveExpiresDate;
    var start = tx.purchaseDate;
    var end = expires;
    if (tx.spec!.isYearly && !tx.isTrial) {
      // Yearly: monthly windows anchored on the original purchase, no rollover.
      final anchor = DateTime.fromMillisecondsSinceEpoch(
        tx.originalPurchaseDate ?? tx.purchaseDate,
        isUtc: true,
      );
      var k = 0;
      while (addMonths(anchor, k + 1).millisecondsSinceEpoch <= nowMs) {
        k++;
      }
      start = addMonths(anchor, k).millisecondsSinceEpoch;
      final next = addMonths(anchor, k + 1).millisecondsSinceEpoch;
      end = next < expires ? next : expires;
    }
    final account = accountFor(token);
    final base = tx.spec!.allowance(tx.storefront ?? account.lastStorefront);
    return AllowanceWindow(
      tx: tx,
      start: start,
      end: end,
      songs: tx.isTrial && tx.spec!.isYearly
          ? (base.songs < Catalog.trialSongCap
                ? base.songs
                : Catalog.trialSongCap)
          : base.songs,
      clips: base.clips,
    );
  }

  List<TxRecord> _livePacks(String accountId) =>
      _transactionsOf(accountId).where((t) => t.isPack && !t.revoked).toList()
        ..sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));

  LedgerStatus status(String token, int nowMs) {
    final account = accountFor(token);
    final window = activeWindow(token, nowMs);
    final packs = _livePacks(account.id);
    final packLeft = packs.fold<int>(0, (sum, t) => sum + t.packLeft);
    final subSongs = window == null
        ? 0
        : (window.songs - (account.songsUsed[window.key] ?? 0)).clamp(
            0,
            1 << 30,
          );
    final clips = window == null
        ? (Catalog.freeLifetimeClips - account.freeClipsUsed).clamp(
            0,
            Catalog.freeLifetimeClips,
          )
        : (window.clips - (account.clipsUsed[window.key] ?? 0)).clamp(
            0,
            1 << 30,
          );
    final mvPacks = _liveMvPacks(account.id);
    return LedgerStatus(
      tier: window?.tx.spec!.tier ??
          (packs.isNotEmpty || mvPacks.isNotEmpty ? 'pack' : 'free'),
      songsLeft: subSongs + packLeft,
      clipsLeft: clips,
      resetAt: window?.end,
    );
  }

  /// Pre-charges one credit for a job of [kind] (`clip` | `song`): a clip
  /// takes the subscription clip allowance (or a lifetime free clip); a song
  /// takes the subscription songs first, then the oldest pack. Nothing left →
  /// QUOTA_EXHAUSTED.
  Charge charge(String token, String kind, int nowMs) {
    final account = accountFor(token);
    final window = activeWindow(token, nowMs);
    if (kind == 'clip') {
      if (window != null) {
        final used = account.clipsUsed[window.key] ?? 0;
        if (used < window.clips) {
          account.clipsUsed[window.key] = used + 1;
          return Charge(
            bucket: Charge.subscription,
            kind: kind,
            windowKey: window.key,
            transactionId: window.tx.transactionId,
          );
        }
      } else if (account.freeClipsUsed < Catalog.freeLifetimeClips) {
        account.freeClipsUsed++;
        return Charge(bucket: Charge.free, kind: kind);
      }
      throw _quotaExhausted(token, Catalog.clipCredits, reason: 'insufficient');
    }
    if (window != null) {
      final used = account.songsUsed[window.key] ?? 0;
      if (used < window.songs) {
        account.songsUsed[window.key] = used + 1;
        return Charge(
          bucket: Charge.subscription,
          kind: kind,
          windowKey: window.key,
          transactionId: window.tx.transactionId,
        );
      }
    }
    for (final pack in _livePacks(account.id)) {
      if (pack.packLeft > 0) {
        pack.packUsed++;
        return Charge(
          bucket: Charge.pack,
          kind: kind,
          transactionId: pack.transactionId,
        );
      }
    }
    // A never-paid account is behind the hard paywall (PRD §8.2); a paid one
    // simply ran out.
    final paid = window != null || _livePacks(account.id).isNotEmpty;
    throw _quotaExhausted(token, Catalog.songCredits, reason: paid ? 'insufficient' : 'paywall');
  }

  /// 49303 with the contract's `QuotaExhaustedDetails` (v1.1: every
  /// QUOTA_EXHAUSTED carries the gap and a product to buy).
  ApiException _quotaExhausted(String token, int required, {required String reason, String? recommendedProductId}) =>
      ApiException(
        SongletErrors.codes[SongletErrors.quotaExhausted]!,
        SongletErrors.messages[SongletErrors.quotaExhausted]!,
        details: {
          'error_code': SongletErrors.quotaExhausted,
          'reason': reason,
          'required_credits': required,
          'available_credits': creditsAvailable(token),
          'recommended_product_id': recommendedProductId ?? Catalog.songPack,
        },
      );

  // ── Music-video credits (contract v1.1 §5) ────────────────────────────────

  List<TxRecord> _liveMvPacks(String accountId) =>
      _transactionsOf(accountId).where((t) => t.isMvPack && !t.revoked).toList();

  /// Credits the account can spend on music videos: the free pocket plus
  /// every unrevoked MV pack, minus what it already spent. A refunded pack
  /// takes its credits away (the balance can go negative until spent ones
  /// settle; it is shown as 0).
  int creditsAvailable(String token) {
    final account = accountFor(token);
    final granted = _liveMvPacks(account.id).fold<int>(0, (sum, t) => sum + t.spec!.credits);
    return (Catalog.freeCredits + granted - account.creditsUsed).clamp(0, 1 << 30);
  }

  /// Freezes [amount] credits for a music video; not enough → QUOTA_EXHAUSTED
  /// with the contract's `QuotaExhaustedDetails`.
  void chargeCredits(String token, int amount, {String? recommendedProductId}) {
    if (creditsAvailable(token) < amount) {
      throw _quotaExhausted(token, amount, reason: 'insufficient', recommendedProductId: recommendedProductId);
    }
    accountFor(token).creditsUsed += amount;
  }

  /// Returns [amount] credits (a failed, cancelled or partially settled MV).
  void refundCredits(String accountId, int amount) {
    final account = accountFor(accountId);
    account.creditsUsed = (account.creditsUsed - amount).clamp(0, 1 << 30);
  }

  /// Returns a failed job's credit to the bucket it came from.
  void refund(String accountId, Charge charge) {
    final account = accountFor(accountId);
    switch (charge.bucket) {
      case Charge.free:
        if (account.freeClipsUsed > 0) account.freeClipsUsed--;
      case Charge.subscription:
        final map = charge.kind == 'clip'
            ? account.clipsUsed
            : account.songsUsed;
        final used = map[charge.windowKey] ?? 0;
        if (used > 0) map[charge.windowKey!] = used - 1;
      case Charge.pack:
        final tx = transactions[charge.transactionId];
        if (tx != null && tx.packUsed > 0) tx.packUsed--;
    }
  }

  /// True when the transaction that funded [charge] has been refunded.
  bool fundingRevoked(Charge charge) =>
      charge.transactionId != null &&
      (transactions[charge.transactionId]?.revoked ?? false);

  // ── App Store Server Notifications V2 (emulated) ──────────────────────────

  /// Applies `REFUND` | `EXPIRED` | `DID_RENEW` to the transaction(s) named
  /// by [transactionId] and/or [originalTransactionId]. Returns a summary.
  Map<String, Object?> notify({
    required String type,
    required int nowMs,
    String? transactionId,
    String? originalTransactionId,
  }) {
    final direct = transactionId == null ? null : transactions[transactionId];
    final orig = originalTransactionId ?? direct?.originalTransactionId;
    final chain = orig == null
        ? <TxRecord>[]
        : (transactions.values
              .where((t) => t.originalTransactionId == orig)
              .toList()
            ..sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate)));
    if (direct == null && chain.isEmpty) {
      throw ApiException(ApiCodes.notFound, 'no such transaction');
    }
    switch (type) {
      case 'REFUND':
        final targets = originalTransactionId != null ? chain : [direct!];
        for (final t in targets) {
          t.revocationDate ??= nowMs;
        }
        return {
          'revoked': [for (final t in targets) t.transactionId],
        };
      case 'EXPIRED':
        final expired = <String>[];
        for (final t in chain.where((t) => t.isSubscription)) {
          if (t.effectiveExpiresDate > nowMs) {
            t.expiresDate = nowMs;
            expired.add(t.transactionId);
          }
        }
        return {'expired': expired};
      case 'DID_RENEW':
        final latest = chain.lastWhere(
          (t) => t.isSubscription,
          orElse: () => throw ApiException.validation(
            'transaction_id',
            'is not a subscription',
          ),
        );
        final start = latest.effectiveExpiresDate > nowMs
            ? latest.effectiveExpiresDate
            : nowMs;
        final end = addMonths(
          DateTime.fromMillisecondsSinceEpoch(start, isUtc: true),
          latest.spec!.isYearly ? 12 : 1,
        ).millisecondsSinceEpoch;
        final renewal = TxRecord(
          transactionId: '${latest.originalTransactionId}.r${chain.length}',
          originalTransactionId: latest.originalTransactionId,
          productId: latest.productId,
          accountId: latest.accountId,
          purchaseDate: start,
          originalPurchaseDate:
              latest.originalPurchaseDate ?? chain.first.purchaseDate,
          expiresDate: end,
          type: latest.type,
          storefront: latest.storefront,
        );
        transactions[renewal.transactionId] = renewal;
        return {'renewal_transaction_id': renewal.transactionId};
      default:
        throw ApiException.validation(
          'notification_type',
          'must be REFUND, EXPIRED or DID_RENEW',
        );
    }
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Map<String, Object?> toJson() => {
    'accounts': [for (final a in accounts.values) a.toJson()],
    'links': links,
    'transactions': [for (final t in transactions.values) t.toJson()],
  };

  void loadJson(Map<String, Object?> j) {
    clear();
    for (final a in (j['accounts'] as List?) ?? const []) {
      final account = Account.fromJson((a as Map).cast<String, Object?>());
      accounts[account.id] = account;
    }
    links.addAll(((j['links'] as Map?) ?? const {}).cast<String, String>());
    for (final t in (j['transactions'] as List?) ?? const []) {
      final tx = TxRecord.fromJson((t as Map).cast<String, Object?>());
      transactions[tx.transactionId] = tx;
    }
  }
}
