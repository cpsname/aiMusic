import 'package:app_config/app_config.dart';
import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/error_retry_view.dart';
import '../common/external_links.dart';
import '../common/messages.dart';
import '../common/page_layout.dart';
import '../common/remote_flags.dart';
import '../common/test_id.dart';
import '../mv/mv_labels.dart';
import '../routing/routes.dart';

/// P08 — the Songlet paywall (PRD §8.1 / §8.2 / §8.5). Products are the store's
/// live, localized details (no hardcoded prices); allowances come from the
/// catalogue for the storefront's pricing tier (the PRD wins over the art,
/// ADR-0008). Buying drives commerce_kit's `IapPurchaseOrchestrator`; the
/// route pops `true` once a purchase or restore went through.
///
/// Review-sensitive copy (PRD §8.5): packs "never expire"; every subscription
/// shows price, period and the auto-renewal terms, with Manage subscription,
/// Restore and functional Terms / Privacy links (App Review 3.1.1 / 3.1.2);
/// nothing is called free or unlimited — everything costs credits (contract
/// 02 v2.1), stated in songs or credits.
///
/// Which side leads comes from the `QUOTA_EXHAUSTED` that opened it
/// ([offer]): the plans (Weekly Pro preselected) — also when the envelope had
/// no offer — or the credit packs, with "See subscriptions" at the bottom.
class PaywallPage extends ConsumerStatefulWidget {
  const PaywallPage({
    super.key,
    this.reason = PaywallReason.upgrade,
    this.productId,
    this.offer,
  });

  final PaywallReason reason;

  /// `packs` leads with the credit packs; anything else, the plans.
  final QuotaOffer? offer;

  /// Preselected product — the pack a `QUOTA_EXHAUSTED` recommended
  /// (`recommended_product_id`, PRD ch.15 / ADR-0020). Null = the default.
  final String? productId;

  @override
  ConsumerState<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends ConsumerState<PaywallPage> {
  /// The product the user tapped.
  String? _selected;

  /// "See subscriptions" was tapped on the pack-led page.
  bool _plansOpen = false;

  /// The credit packs lead and the plans are behind the link.
  bool get _packsLead => widget.offer == QuotaOffer.packs && !_plansOpen;

  @override
  void initState() {
    super.initState();
    // IAP funnel entry point (DF②): the paywall was shown, and why.
    ref
        .read(telemetrySinkProvider)
        .logEvent(
          'paywall_view',
          properties: {
            'reason': widget.reason.wire,
            if (widget.productId != null) 'product_code': widget.productId,
            if (widget.offer != null) 'offer': widget.offer!.wire,
          },
        );
  }

  /// Pops with whether a purchase went through (go_router forwards the
  /// result to `openPaywall`).
  void _close({bool bought = false}) => Navigator.of(context).maybePop(bought);

  /// The selected product: a tap, else the recommended product (which a
  /// subscription offer overrides when it is a pack: the plans lead, Weekly
  /// Pro preselected), else the side that leads — Weekly Pro, or the first
  /// credit pack.
  StoreProduct? _current(List<StoreProduct> products) {
    if (products.isEmpty) return null;
    StoreProduct? byId(String? id) =>
        products.where((p) => p.storeProductId == id).firstOrNull;
    final tapped = byId(_selected);
    // Once the plans were opened from the pack-led page, Weekly Pro takes over.
    final recommended = _plansOpen ? null : byId(widget.productId);
    final picked =
        tapped ??
        (recommended != null &&
                (widget.offer != QuotaOffer.subscription ||
                    recommended.isSubscription)
            ? recommended
            : null);
    // On the pack-led page a subscription pick (a leftover) does not count.
    if (picked != null && !(_packsLead && picked.isSubscription)) return picked;
    if (_packsLead)
      return products.where((p) => p.isConsumable).firstOrNull ??
          products.first;
    return byId(MusicCatalog.recommendedSubscription) ??
        products.where((p) => p.isSubscription).firstOrNull ??
        products.first;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ref.listen<IapPurchaseState>(
      iapPurchaseOrchestratorProvider,
      (_, next) => _onPurchaseState(l10n, next),
    );

    // Kill-switch (AppConfig): the server can disable purchases at runtime.
    final killed = ref.watch(
      isFeatureKilledProvider(AppFeatureCodes.iapPurchase),
    );
    final products = ref.watch(storeProductsProvider);
    final list = products.value ?? const <StoreProduct>[];
    final selected = _current(list);

    return Scaffold(
      body: PageFrame(
        header: Row(
          children: [
            TestId(
              'paywall.close',
              child: IconCircleButton(
                icon: Icons.close_rounded,
                tooltip: l10n.paywallClose,
                onPressed: _close,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: _close,
              style: TextButton.styleFrom(
                foregroundColor: SongletColors.of(context).inkSecondary,
              ),
              child: Text(l10n.commonNotNow),
            ),
          ],
        ),
        footer: killed || selected == null ? null : _Cta(product: selected),
        children: [
          _Hero(forVideo: widget.reason == PaywallReason.mv),
          const SizedBox(height: SongletSpace.x6),
          if (killed)
            StatusView(
              title: l10n.featureUnavailable,
              icon: Icons.do_not_disturb_on_outlined,
              expand: false,
            )
          else
            products.when(
              loading: () => const _Skeleton(),
              error: (error, stackTrace) => ErrorRetryView(
                failure: ref
                    .read(errorHandlerProvider)
                    .handle(error, stackTrace),
                onRetry: () => ref.invalidate(storeCatalogQueryProvider),
                title: l10n.paywallProductsErrorTitle,
                fullScreen: false,
              ),
              data: (items) => items.isEmpty
                  ? EmptyState(
                      icon: Icons.storefront_outlined,
                      title: l10n.paywallNoProducts,
                      message: l10n.paywallSubtitle,
                    )
                  : _Plans(
                      forVideo: widget.reason == PaywallReason.mv,
                      packsLead: _packsLead,
                      onSeePlans: () => setState(() {
                        _plansOpen = true;
                        _selected = null;
                      }),
                      products: items,
                      selected: selected!,
                      onSelect: (p) =>
                          setState(() => _selected = p.storeProductId),
                    ),
            ),
          const SizedBox(height: SongletSpace.x2),
          // Restore and the legal links stay reachable whatever the catalog
          // state: a restore is how an empty or failed store query recovers,
          // and App Review 3.1.2 wants Terms / Privacy on every paywall.
          const _Links(),
        ],
      ),
    );
  }

  /// Drives ONE tagged message through the orchestrator's flow.
  void _onPurchaseState(AppLocalizations l10n, IapPurchaseState state) {
    const tag = 'purchase';
    final messages = ref.read(messageControllerProvider);
    switch (state) {
      case IapCreatingOrder() || IapOrderCreated() || IapAwaitingNative():
        messages.loading(l10n.paywallProcessing, tag: tag);
      case IapVerifying():
        messages.loading(l10n.paywallVerifying, tag: tag);
      case IapCompleted():
        messages.success(l10n.paywallPurchaseSuccess, tag: tag);
        ref.invalidate(musicEntitlementProvider);
        _close(bought: true);
      case IapFailed(:final failure):
        messages.show(
          failureMessage(l10n, failure, fallback: l10n.paywallPurchaseFailed),
          tag: tag,
        );
      case IapDeferred():
        messages.info(l10n.paywallDeferred, tag: tag);
      case IapAlreadySubscribed():
        messages.info(
          l10n.paywallAlreadySubscribed,
          tag: tag,
          actionLabel: l10n.paywallManage,
          onAction: () => openExternalUrl(
            context,
            manageSubscriptionsUrl(),
            errorMessage: l10n.commonLinkError,
          ),
        );
      case IapCancelled():
        messages.dismissTag(tag);
      case IapRestoring():
        messages.loading(l10n.paywallRestoreStarted, tag: tag);
      case IapRestored(:final restoredCount):
        ref.invalidate(musicEntitlementProvider);
        if (restoredCount > 0) {
          messages.success(l10n.paywallRestoreSuccess(restoredCount), tag: tag);
          _close(bought: true);
        } else {
          messages.info(l10n.paywallRestoreNothing, tag: tag);
        }
      case IapIdle():
        break;
    }
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.forVideo});

  /// Opened for a music video: the headline talks about the video, not the
  /// full song.
  final bool forVideo;

  /// Flex weights of the hero copy column and the cover art beside it.
  static const int _copyFlex = 3;
  static const int _artFlex = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = SongletColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: _copyFlex,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      forVideo
                          ? l10n.paywallMvHeroTitle
                          : l10n.paywallHeroTitle,
                      style: SongletType.largeTitle.copyWith(color: c.ink),
                    ),
                  ),
                  const SizedBox(height: SongletSpace.x2),
                  Text(
                    forVideo
                        ? l10n.paywallMvHeroSubtitle
                        : l10n.paywallHeroSubtitle,
                    style: SongletType.callout.copyWith(color: c.inkSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: SongletSpace.x3),
            const Expanded(
              flex: _artFlex,
              child: ExcludeSemantics(
                child: CoverArt(
                  seed: 'songlet-paywall',
                  palette: ArtPalette.terracotta,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: SongletSpace.x5),
        // Equal thirds: long or enlarged captions wrap in their column.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: IconCaption(
                icon: Icons.music_note_outlined,
                label: l10n.paywallBenefitSongs,
              ),
            ),
            Expanded(
              child: IconCaption(
                icon: Icons.diamond_outlined,
                label: l10n.paywallBenefitQuality,
              ),
            ),
            Expanded(
              child: IconCaption(
                icon: Icons.verified_user_outlined,
                label: l10n.paywallBenefitCommercial,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Plans extends ConsumerWidget {
  const _Plans({
    required this.forVideo,
    required this.packsLead,
    required this.onSeePlans,
    required this.products,
    required this.selected,
    required this.onSelect,
  });

  /// Opened for a music video: the video packs lead (docs/ui P29).
  final bool forVideo;

  /// The credit packs lead and the plans wait behind "See subscriptions"
  /// ([onSeePlans]); otherwise the plans lead and the packs follow.
  final bool packsLead;
  final VoidCallback onSeePlans;
  final List<StoreProduct> products;
  final StoreProduct selected;
  final ValueChanged<StoreProduct> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = SongletColors.of(context);
    final tier = ref.watch(pricingTierProvider);
    final needsBilling = ref
        .watch(subscriptionEntitlementProvider)
        .needsBillingAttention;
    final entitlement = ref.watch(musicEntitlementProvider).value;
    // Remote config (AppConfig): an optional server-driven promo line.
    final promo = ref
        .watch(appConfigProvider)
        .configValue<String>('promo_text', '');
    final subscriptions = products.where((p) => p.isSubscription).toList();
    final packs = products
        .where(
          (p) => p.isConsumable && !MusicCatalog.isMvPack(p.storeProductId),
        )
        .toList();
    final mvPacks = products
        .where((p) => MusicCatalog.isMvPack(p.storeProductId))
        .toList();
    final trial = selected.introductoryOffer;
    final selectedTrial =
        selected.isSubscription && trial != null && trial.isFreeTrial;
    final selectedIntro = selected.isSubscription
        ? _introDiscount(selected)
        : null;

    // Music-video packs (PRD ch.15, docs/ui P29): one video of their level,
    // never expire; first when the paywall opened for a video.
    final videoGroup = <Widget>[
      if (mvPacks.isNotEmpty) ...[
        if (!forVideo) const SizedBox(height: SongletSpace.x2),
        TestId(
          'paywall.videoGroup',
          child: SectionHeader(title: l10n.paywallVideoGroup),
        ),
        const SizedBox(height: SongletSpace.x3),
      ],
      for (final pack in mvPacks) ...[
        TestId(
          'paywall.product.${pack.storeProductId}',
          child: PackRow(
            title: l10n.mvPackTitle,
            subtitle: mvPackSubtitle(l10n, pack.storeProductId),
            price: pack.displayPrice,
            note: l10n.packNote,
            selected: pack.storeProductId == selected.storeProductId,
            onTap: () => onSelect(pack),
          ),
        ),
        const SizedBox(height: SongletSpace.x3),
      ],
      if (forVideo && mvPacks.isNotEmpty)
        const SizedBox(height: SongletSpace.x3),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (forVideo) ...videoGroup,
        if (promo.isNotEmpty) ...[
          NoteBanner(icon: Icons.campaign_outlined, message: promo),
          const SizedBox(height: SongletSpace.x4),
        ],
        if (needsBilling) ...[
          InlineErrorBanner(message: l10n.paywallBillingRetry),
          const SizedBox(height: SongletSpace.x4),
        ],
        if (entitlement != null && entitlement.tier.hasSubscription) ...[
          NoteBanner(
            icon: Icons.verified_rounded,
            message: l10n.paywallCurrentPlan(entitlement.songsLeft),
          ),
          const SizedBox(height: SongletSpace.x4),
        ],
        if (!packsLead)
          for (final product in subscriptions) ...[
            TestId(
              'paywall.product.${product.storeProductId}',
              child: PlanCard(
                title: product.displayName,
                price: _price(l10n, product),
                ribbon: product.highlightTag == 'best_value'
                    ? l10n.paywallBestValue
                    : null,
                trial: _planBadge(l10n, product),
                benefits: _benefits(
                  l10n,
                  product,
                  tier,
                  wav: wavExportEnabled(ref),
                ),
                selected: product.storeProductId == selected.storeProductId,
                onTap: () => onSelect(product),
              ),
            ),
            const SizedBox(height: SongletSpace.x4),
          ],
        for (final pack in packs) ...[
          TestId(
            'paywall.product.${pack.storeProductId}',
            child: PackRow(
              title: l10n.packTitle,
              subtitle: l10n.packSubtitle(
                MusicCatalog.packSongs(pack.storeProductId),
              ),
              price: pack.displayPrice,
              note: l10n.packNote,
              selected: pack.storeProductId == selected.storeProductId,
              onTap: () => onSelect(pack),
            ),
          ),
          const SizedBox(height: SongletSpace.x3),
        ],
        if (packsLead && subscriptions.isNotEmpty)
          TestId(
            'paywall.seePlans',
            child: TextButton(
              onPressed: onSeePlans,
              child: Text(l10n.paywallSeePlans),
            ),
          ),
        if (!forVideo) ...videoGroup,
        const SizedBox(height: SongletSpace.x3),
        Row(
          children: [
            for (final (icon, label) in [
              (Icons.all_inclusive_rounded, l10n.valueForever),
              (Icons.download_rounded, l10n.valueDownloads),
              (Icons.lock_outline_rounded, l10n.valueCommercial),
              (Icons.favorite_border_rounded, l10n.valuePrivate),
            ])
              Expanded(
                child: IconCaption(icon: icon, label: label, tinted: false),
              ),
          ],
        ),
        const SizedBox(height: SongletSpace.x5),
        // Auto-renewal disclosure (App Review 3.1.2).
        if (selected.isSubscription)
          Text(
            [
              if (selectedTrial)
                l10n.paywallTrialDisclosure(_price(l10n, selected)),
              if (selectedIntro != null)
                l10n.paywallIntroDisclosure(
                  selectedIntro.price,
                  _price(l10n, selected),
                ),
              l10n.paywallAutoRenewNotice,
            ].join(' '),
            textAlign: TextAlign.center,
            style: SongletType.caption.copyWith(color: c.inkSecondary),
          ),
      ],
    );
  }

  /// [wav]: WAV export is offered (remote switch) — never sold before it is.
  static List<String> _benefits(
    AppLocalizations l10n,
    StoreProduct product,
    PricingTier tier, {
    required bool wav,
  }) {
    final id = product.storeProductId;
    // Weekly Pro renews credits, not a monthly songs allowance.
    if (MusicCatalog.isWeekly(id))
      return [l10n.planCreditsWeekly, l10n.planMp3, l10n.planLicense];
    final allowance = MusicCatalog.allowance(id, tier);
    final premier = MusicCatalog.isPremier(id);
    return [
      l10n.planSongs(allowance.songs),
      l10n.planPreviews(allowance.clips),
      if (premier && wav) l10n.planMp3Wav else l10n.planMp3,
      l10n.planLicense,
      if (premier || id == MusicCatalog.proYearly) l10n.planPriority,
      // PRD §15.4 / X-56: the allowance is not raised; it also makes videos.
      if (premier) l10n.planVideoIncluded,
    ];
  }

  /// Price with its billing period, from the store's own period (the catalog's
  /// `billingCycle` only when the store did not say).
  static String _price(AppLocalizations l10n, StoreProduct product) {
    final unit =
        product.subscriptionPeriod?.unit ??
        switch (product.product.billingCycle) {
          'annual' => PeriodUnit.year,
          'weekly' => PeriodUnit.week,
          _ => PeriodUnit.month,
        };
    return switch (unit) {
      PeriodUnit.year => l10n.planPerYear(product.displayPrice),
      PeriodUnit.week => l10n.planPerWeek(product.displayPrice),
      PeriodUnit.day ||
      PeriodUnit.month => l10n.planPerMonth(product.displayPrice),
    };
  }

  /// The plan card's offer caption: the free trial's length, else the intro
  /// discount ("50% off your first week").
  static String? _planBadge(AppLocalizations l10n, StoreProduct product) {
    final offer = product.introductoryOffer;
    if (offer != null && offer.isFreeTrial)
      return l10n.planTrial(_days(offer.period));
    final intro = _introDiscount(product);
    return intro == null
        ? null
        : l10n.paywallIntroOffer(intro.percent, intro.unit.name);
  }

  /// A discounted first period the user can still redeem (the store reports it
  /// only while they are eligible), as the store's price, the percent off the
  /// regular price and the period's unit; null for a free trial, an offer
  /// that spans several periods, or one with no real discount.
  static ({String price, int percent, PeriodUnit unit})? _introDiscount(
    StoreProduct product,
  ) {
    final offer = product.introductoryOffer;
    final regular = product.details.rawPrice;
    if (offer == null ||
        offer.isFreeTrial ||
        offer.numberOfPeriods != 1 ||
        regular <= 0)
      return null;
    final percent = ((1 - offer.rawPrice / regular) * 100).round();
    if (percent < 1 || percent > 99) return null;
    return (
      price: offer.formattedPrice,
      percent: percent,
      unit: offer.period.unit,
    );
  }

  /// Calendar approximations for the "N-day trial" caption; App Store
  /// Connect only offers month / year trials in whole units.
  static const int _daysPerMonth = 30;
  static const int _daysPerYear = 365;

  static int _days(SubscriptionPeriodValue period) => switch (period.unit) {
    PeriodUnit.day => period.numberOfUnits,
    PeriodUnit.week => period.numberOfUnits * DateTime.daysPerWeek,
    PeriodUnit.month => period.numberOfUnits * _daysPerMonth,
    PeriodUnit.year => period.numberOfUnits * _daysPerYear,
  };
}

class _Cta extends ConsumerWidget {
  const _Cta({required this.product});

  final StoreProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final purchase = ref.watch(iapPurchaseOrchestratorProvider);
    final trial = product.introductoryOffer;
    final label = !product.isSubscription
        ? l10n.paywallBuyPack
        : (trial != null && trial.isFreeTrial
              ? l10n.paywallStartTrial
              : l10n.paywallSubscribe);
    if (purchase.isDeferredFor(product.productCode)) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ObsButton(label: l10n.paywallContinue),
          const SizedBox(height: SongletSpace.x1),
          Text(l10n.paywallDeferred, style: SongletType.footnote),
        ],
      );
    }
    return TestId(
      'paywall.buy',
      child: ObsButton(
        label: label,
        loading: purchase.isBusyFor(product.productCode),
        onPressed: purchase.isInProgress
            ? null
            : () => ref
                  .read(iapPurchaseOrchestratorProvider.notifier)
                  .purchase(product),
      ),
    );
  }
}

/// Restore · Terms · Privacy · Manage. Apple requires functional EULA +
/// Privacy links on any auto-renewable-subscription screen (App Review
/// 3.1.2); the compile-time fallbacks back them up via [effectiveLegalInfo].
class _Links extends ConsumerWidget {
  const _Links();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final legal = effectiveLegalInfo(
      server: ref.watch(legalInfoProvider),
      env: ref.watch(envConfigProvider),
    );
    void open(String url) =>
        openExternalUrl(context, url, errorMessage: l10n.commonLinkError);
    return TestId(
      'paywall.links',
      child: LinkRow(
        links: [
          // Restore is user-initiated only (PRD §8.4: currentEntitlements).
          (
            l10n.paywallRestore,
            () => ref
                .read(iapPurchaseOrchestratorProvider.notifier)
                .restorePurchases(),
          ),
          if (legal.termsUrl case final url? when url.isNotEmpty)
            (l10n.paywallTermsOfUse, () => open(url)),
          if (legal.privacyUrl case final url? when url.isNotEmpty)
            (l10n.paywallPrivacyPolicy, () => open(url)),
          if (legal.subscriptionTermsUrl case final url? when url.isNotEmpty)
            (l10n.paywallSubscriptionTerms, () => open(url)),
          (l10n.paywallManage, () => open(manageSubscriptionsUrl())),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  /// Placeholder heights of the hero, plan list and CTA blocks.
  static const double _heroHeight = SongletSize.coverLarge * 0.7;
  static const double _plansHeight = SongletSize.coverLarge * 0.6;
  static const double _ctaHeight = SongletSize.coverLarge * 0.35;

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      AuraSkeleton(height: _heroHeight, borderRadius: SongletRadius.cardAll),
      SizedBox(height: SongletSpace.x4),
      AuraSkeleton(height: _plansHeight, borderRadius: SongletRadius.cardAll),
      SizedBox(height: SongletSpace.x4),
      AuraSkeleton(height: _ctaHeight, borderRadius: SongletRadius.cardAll),
    ],
  );
}
