import 'package:app_config/app_config.dart';
import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/music_messages.dart';
import '../common/music_test_id.dart';
import '../routing/music_navigation.dart';
import '../routing/music_routes.dart';
import 'music_mv_labels.dart';

/// P22 — not enough credits for a video (PRD §15.4, ADR-0023): what is
/// missing and the pack the platform recommended, bought right here through
/// StoreKit 2 (commerce_kit's purchase orchestrator, as on the paywall).
/// Resolves true once the purchase went through — the caller then sends the
/// kept request again; false when the user closed it or cancelled the
/// purchase (the hub keeps every choice).
///
/// Not a route: it acts on the request held by the hub (a deep link to it
/// would have nothing to buy for).
Future<bool> showMvQuotaSheet(
  BuildContext context, {
  required MusicQuotaGap gap,
  required MusicMvLevel level,
}) async {
  final bought = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => MusicMvQuotaSheet(gap: gap, level: level),
  );
  return bought ?? false;
}

class MusicMvQuotaSheet extends ConsumerStatefulWidget {
  const MusicMvQuotaSheet({super.key, required this.gap, required this.level});

  final MusicQuotaGap gap;
  final MusicMvLevel level;

  @override
  ConsumerState<MusicMvQuotaSheet> createState() => _MvQuotaSheetState();
}

class _MvQuotaSheetState extends ConsumerState<MusicMvQuotaSheet> {
  Failure? _failure;
  bool _deferred = false;

  /// The paywall is open over the sheet: it handles the purchase events.
  bool _inPaywall = false;

  void _close(bool bought) => Navigator.of(context).pop(bought);

  void _onPurchase(IapPurchaseState state) {
    if (_inPaywall) return;
    switch (state) {
      case IapCompleted():
        ref
          ..invalidate(musicEntitlementProvider)
          ..invalidate(walletSnapshotProvider);
        _close(true);
      case IapCancelled():
        _close(false);
      case IapFailed(:final failure):
        setState(() => _failure = failure);
      case IapDeferred():
        setState(() => _deferred = true);
      case IapIdle() ||
          IapCreatingOrder() ||
          IapOrderCreated() ||
          IapAwaitingNative() ||
          IapVerifying() ||
          IapAlreadySubscribed() ||
          IapRestoring() ||
          IapRestored():
        break;
    }
  }

  Future<void> _seePlans() async {
    final navigator = Navigator.of(context);
    _inPaywall = true;
    final bought = await context.openPaywall(
      MusicPaywallReason.mv,
      productId: widget.gap.recommendedProductId,
      offer: widget.gap.offer,
    );
    _inPaywall = false;
    if (!mounted) return;
    if (bought) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = SongletColors.of(context);
    ref.listen<IapPurchaseState>(
      iapPurchaseOrchestratorProvider,
      (_, next) => _onPurchase(next),
    );
    final purchase = ref.watch(iapPurchaseOrchestratorProvider);
    final killed = ref.watch(
      isFeatureKilledProvider(AppFeatureCodes.iapPurchase),
    );
    final tier = ref.watch(pricingTierProvider);
    final productId = widget.gap.recommendedProductId;
    final products =
        ref.watch(storeProductsProvider).value ?? const <StoreProduct>[];
    final product = productId == null
        ? null
        : products.where((p) => p.storeProductId == productId).firstOrNull;
    final packCredits = productId == null
        ? 0
        : MusicCatalog.mvPackCredits(productId, tier);
    final mayNeedTwice = packCredits > 0 && widget.gap.gapCredits > packCredits;
    final failure = _failure;

    return MusicTestId(
      'mv.quota',
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          SongletSpace.sheetInset,
          0,
          SongletSpace.sheetInset,
          SongletSpace.x5,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.mvQuotaTitle,
                  style: SongletType.title2.copyWith(color: c.ink),
                ),
              ),
              const SizedBox(height: SongletSpace.x2),
              MusicTestId(
                'mv.quota.need',
                child: Text(
                  l10n.mvQuotaNeed(
                    mvLevelName(l10n, widget.level),
                    widget.gap.requiredCredits,
                    widget.gap.availableCredits,
                  ),
                  style: SongletType.body.copyWith(color: c.inkSecondary),
                ),
              ),
              const SizedBox(height: SongletSpace.x3),
              StatusPill(
                label: l10n.mvGapCredits(widget.gap.gapCredits),
                tone: PillTone.danger,
                icon: Icons.add_card_outlined,
              ),
              const SizedBox(height: SongletSpace.x5),
              if (killed)
                NoteBanner(
                  icon: Icons.do_not_disturb_on_outlined,
                  message: l10n.featureUnavailable,
                )
              else if (product != null) ...[
                MusicTestId(
                  'mv.quota.pack',
                  child: PackRow(
                    title: l10n.mvPackTitle,
                    subtitle: mvPackSubtitle(l10n, product.storeProductId),
                    price: product.displayPrice,
                    note: l10n.packNote,
                    selected: true,
                    onTap: () {},
                  ),
                ),
                if (mayNeedTwice) ...[
                  const SizedBox(height: SongletSpace.x3),
                  NoteBanner(
                    icon: Icons.info_outline_rounded,
                    message: l10n.mvQuotaMayNeedTwice,
                  ),
                ],
                const SizedBox(height: SongletSpace.x3),
                Text(
                  l10n.mvQuotaAutoRetry,
                  style: SongletType.footnote.copyWith(color: c.inkSecondary),
                ),
              ],
              if (failure != null) ...[
                const SizedBox(height: SongletSpace.x3),
                InlineErrorBanner(
                  message: failureMessage(
                    l10n,
                    failure,
                    fallback: l10n.paywallPurchaseFailed,
                  ).text,
                ),
              ],
              if (_deferred) ...[
                const SizedBox(height: SongletSpace.x3),
                NoteBanner(
                  icon: Icons.hourglass_top_rounded,
                  message: l10n.paywallDeferred,
                ),
              ],
              const SizedBox(height: SongletSpace.x5),
              if (!killed && product != null)
                MusicTestId(
                  'mv.quota.buy',
                  child: ObsButton(
                    label: l10n.mvQuotaBuyAndContinue,
                    icon: Icons.shopping_bag_outlined,
                    loading: purchase.isBusyFor(product.productCode),
                    onPressed: purchase.isInProgress || _deferred
                        ? null
                        : () {
                            setState(() => _failure = null);
                            ref
                                .read(iapPurchaseOrchestratorProvider.notifier)
                                .purchase(product);
                          },
                  ),
                ),
              if (!killed) ...[
                const SizedBox(height: SongletSpace.x2),
                MusicTestId(
                  'mv.quota.plans',
                  child: TextButton(
                    onPressed: purchase.isInProgress ? null : _seePlans,
                    style: TextButton.styleFrom(foregroundColor: c.accent),
                    child: Text(l10n.paywallSeePlans),
                  ),
                ),
              ],
              MusicTestId(
                'mv.quota.close',
                child: TextButton(
                  onPressed: purchase.isInProgress ? null : () => _close(false),
                  style: TextButton.styleFrom(foregroundColor: c.inkSecondary),
                  child: Text(l10n.commonNotNow),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
