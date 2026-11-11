import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/music_error_retry_view.dart';
import '../common/music_external_links.dart';
import '../common/music_messages.dart';
import 'music_login_sheet.dart';

/// Profile: consumes `currentAccountProvider` + wallet providers, with the
/// `AsyncValue` three states (skeleton / data / error-with-retry) and a guest
/// sign-in entry.
class MusicProfilePage extends ConsumerWidget {
  const MusicProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(currentAccountProvider);
    return account.when(
      loading: () => const _ProfileSkeleton(),
      error: (error, stackTrace) => MusicErrorRetryView(
        failure: ref.read(errorHandlerProvider).handle(error, stackTrace),
        onRetry: () => ref.invalidate(currentAccountProvider),
        fullScreen: false,
      ),
      data: (data) => _ProfileContent(account: data),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.account});

  final CurrentAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final wallet = ref.watch(walletSnapshotProvider);
    final features = ref.watch(activeWalletFeaturesProvider);
    final entitlement = ref.watch(subscriptionEntitlementProvider);

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        StudioTokens.spaceLg,
        StudioTokens.spaceXl,
        StudioTokens.spaceLg,
        StudioTokens.space2xl,
      ),
      children: [
        _header(context, l10n),
        const SizedBox(height: StudioTokens.spaceLg),
        _balanceCard(context, l10n, wallet),
        const SizedBox(height: StudioTokens.spaceMd),
        _subscriptionCard(context, l10n, entitlement),
        const SizedBox(height: StudioTokens.spaceMd),
        _featuresCard(context, l10n, features),
        const SizedBox(height: StudioTokens.spaceXl),
        if (account.isGuest)
          ObsButton(
            label: l10n.signIn,
            icon: Icons.login,
            onPressed: () => showLoginSheet(context, ref),
          )
        else
          OutlinedButton(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            child: Text(l10n.signOut),
          ),
        // Account deletion (App Review 5.1.1(v)) — guest lifecycle only: the
        // guest is anchored to the Keychain device id, so wiping it makes the
        // account permanently unreachable. A signed-in account keeps sign-out
        // only until the backend delete endpoint exists (a local wipe would
        // masquerade as deletion while the server account survives).
        if (account.isGuest) ...[
          const SizedBox(height: StudioTokens.spaceSm),
          Center(
            child: TextButton(
              onPressed: () => _confirmDeleteAccount(context, l10n),
              child: Text(
                l10n.profileDeleteAccount,
                style: const TextStyle(color: StudioTokens.errorColor),
              ),
            ),
          ),
        ],
        if (account.createdAt != null) ...[
          const SizedBox(height: StudioTokens.spaceLg),
          Center(
            child: Text(
              l10n.profileMemberSince(account.createdAt!.toLocal()),
              style: theme.textTheme.labelMedium,
            ),
          ),
        ],
      ],
    );
  }

  Widget _header(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Row(
      children: [
        _Avatar(url: account.avatarUrl),
        const SizedBox(width: StudioTokens.spaceMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientText(
                account.isGuest ? l10n.profileGuestTitle : account.nickname,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: StudioTokens.spaceXs),
              Text(
                account.isGuest
                    ? l10n.profileGuestSubtitle
                    : (account.email ?? ''),
                style: theme.textTheme.bodyMedium,
              ),
              if (account.userId.isNotEmpty) ...[
                const SizedBox(height: StudioTokens.spaceXs),
                Text(
                  l10n.profileAccountIdWithValue(account.userId),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.hintColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _balanceCard(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<WalletSnapshot> wallet,
  ) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Row(
        children: [
          const Icon(Icons.bolt, color: StudioTokens.auroraTeal),
          const SizedBox(width: StudioTokens.spaceMd),
          Expanded(
            child: Text(
              l10n.profileBalanceLabel,
              style: theme.textTheme.titleMedium,
            ),
          ),
          wallet.when(
            loading: () => const AuraSkeleton(width: 64, height: 26),
            error: (_, _) => Text('—', style: theme.textTheme.titleLarge),
            data: (snapshot) => Text(
              l10n.profileBalanceValue(snapshot.balance),
              style: theme.textTheme.titleLarge?.copyWith(
                color: StudioTokens.auroraTeal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subscriptionCard(
    BuildContext context,
    AppLocalizations l10n,
    SubscriptionEntitlement entitlement,
  ) {
    final theme = Theme.of(context);
    final active = account.subscription?.isActive ?? false;
    // Apple expects an easy path to manage/cancel a subscription; keep a
    // persistent entry whenever the account holds one (entitled — incl. grace
    // period — or in billing retry, where "manage" is exactly the fix).
    final canManage =
        entitlement.isEntitled || entitlement.needsBillingAttention;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                active ? Icons.verified : Icons.workspace_premium_outlined,
                color: active
                    ? StudioTokens.auroraViolet
                    : StudioTokens.textSecondary,
              ),
              const SizedBox(width: StudioTokens.spaceMd),
              Expanded(
                child: Text(
                  l10n.profileSubscriptionLabel,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Text(
                active ? l10n.subscriptionActive : l10n.subscriptionInactive,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
          if (canManage)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => openExternalUrl(
                  context,
                  manageSubscriptionsUrl(),
                  errorMessage: l10n.commonLinkError,
                ),
                child: Text(l10n.profileManageSubscription),
              ),
            ),
        ],
      ),
    );
  }

  Widget _featuresCard(
    BuildContext context,
    AppLocalizations l10n,
    List<WalletFeature> features,
  ) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.profileFeaturesLabel, style: theme.textTheme.titleMedium),
          const SizedBox(height: StudioTokens.spaceMd),
          if (features.isEmpty)
            Text(l10n.profileNoFeatures, style: theme.textTheme.bodyMedium)
          else
            Wrap(
              spacing: StudioTokens.spaceSm,
              runSpacing: StudioTokens.spaceSm,
              children: [
                for (final feature in features)
                  Chip(
                    label: Text(
                      feature.name.isNotEmpty
                          ? feature.name
                          : l10n.profileFeaturesLabel,
                    ),
                    backgroundColor: StudioTokens.auroraViolet.withValues(
                      alpha: 0.18,
                    ),
                    side: const BorderSide(color: StudioTokens.glassStroke),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  /// Confirms, then deletes the guest account and establishes a fresh one. One
  /// tagged message tracks the flow (working → deleted / failure); the action
  /// is retryable end-to-end (the wipe is idempotent, registration is
  /// re-attempted). Providers are re-read via the container so the flow
  /// survives this widget being rebuilt across the awaits.
  Future<void> _confirmDeleteAccount(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteAccountTitle),
        content: Text(l10n.deleteAccountMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.deleteAccountConfirm,
              style: const TextStyle(color: StudioTokens.errorColor),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final messages = container.read(messageControllerProvider);
    const tag = 'delete_account';
    messages.loading(l10n.deleteAccountWorking, tag: tag);
    try {
      await container.read(authControllerProvider.notifier).deleteAccount();
      messages.success(l10n.deleteAccountDone, tag: tag);
    } on Object catch (error, stackTrace) {
      messages.show(
        failureMessage(
          l10n,
          container.read(errorHandlerProvider).handle(error, stackTrace),
        ),
        tag: tag,
      );
    } finally {
      // The old account is gone either way — never keep showing its data.
      container.invalidate(currentAccountProvider);
      container.invalidate(walletSnapshotProvider);
    }
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    const size = 64.0;
    const fallback = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: StudioTokens.auroraGradient,
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(Icons.person, color: Colors.white, size: 32),
      ),
    );
    final avatarUrl = url;
    if (avatarUrl == null || avatarUrl.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        avatarUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(StudioTokens.spaceLg),
      children: const [
        SizedBox(height: StudioTokens.spaceXl),
        Row(
          children: [
            AuraSkeleton(width: 64, height: 64),
            SizedBox(width: StudioTokens.spaceMd),
            Expanded(child: AuraSkeleton(height: 28)),
          ],
        ),
        SizedBox(height: StudioTokens.spaceXl),
        AuraSkeleton(height: 64),
        SizedBox(height: StudioTokens.spaceMd),
        AuraSkeleton(height: 64),
        SizedBox(height: StudioTokens.spaceMd),
        AuraSkeleton(height: 120),
      ],
    );
  }
}
