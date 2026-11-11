import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';
import 'package:intl/intl.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../l10n/ui_locale.dart';
import '../common/brand.dart';
import '../common/external_links.dart';
import '../common/messages.dart';
import '../common/page_layout.dart';
import '../common/test_id.dart';
import '../create/create_labels.dart';
import '../routing/navigation.dart';
import '../routing/routes.dart';
import 'ui_language_sheet.dart';

/// P14 — settings (no prototype; composed from the design system, ADR-0009):
/// the profile (credits and the account ID, with a copy button),
/// upgrade, interface and default lyrics
/// languages, "About generation" (App Review
/// 5.1.2(i), PRD §9.4) and the legal links.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final current = ref.read(lyricLanguagePreferenceProvider);
    final picked = await showModalBottomSheet<({LyricLanguage? language})>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.sizeOf(context).height *
                SongletSize.pickerSheetFactor,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: SongletSpace.gutter,
            ),
            children: [
              OptionRow(
                title: l10n.settingsLyricsLanguageAuto,
                dense: true,
                selected: current == null,
                onTap: () => Navigator.pop(context, (language: null)),
              ),
              for (final language in LyricLanguage.values)
                OptionRow(
                  title: languageName(l10n, language),
                  dense: true,
                  selected: current == language,
                  onTap: () => Navigator.pop(context, (language: language)),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) {
      await ref
          .read(lyricLanguagePreferenceProvider.notifier)
          .set(picked.language);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = SongletColors.of(context);
    final language = ref.watch(lyricLanguagePreferenceProvider);
    final uiPreference = ref.watch(uiLanguagePreferenceProvider);
    final uiLocale = ref.watch(uiLocaleProvider);
    final version = ref.watch(deviceProfileProvider).value?.appVersion ?? '';
    final legal = effectiveLegalInfo(
      server: ref.watch(legalInfoProvider),
      env: ref.watch(envConfigProvider),
    );
    void open(String url) =>
        openExternalUrl(context, url, errorMessage: l10n.commonLinkError);

    return Scaffold(
      body: PageFrame(
        header: BrandHeader(title: SongletBrand.name, tagline: l10n.appTagline),
        children: [
          PageTitle(title: l10n.settingsTitle),
          const _ProfileGroup(),
          const SizedBox(height: SongletSpace.x6),
          TestId(
            'settings.upgrade',
            child: ObsButton(
              label: l10n.settingsUpgrade,
              icon: Icons.auto_awesome,
              onPressed: () => context.openPaywall(PaywallReason.upgrade),
            ),
          ),
          const SizedBox(height: SongletSpace.x6),
          SettingsGroup(
            title: l10n.settingsSectionLanguage,
            children: [
              TestId(
                'settings.uiLanguage',
                child: SettingsRow(
                  icon: Icons.language_rounded,
                  title: l10n.settingsAppLanguage,
                  value: uiPreference == null
                      ? l10n.settingsLanguageSystemValue(
                          uiLanguageName(uiLocale),
                        )
                      : uiLanguageName(uiPreference),
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useRootNavigator: true,
                    builder: (_) => const UiLanguageSheet(),
                  ),
                ),
              ),
              TestId(
                'settings.language',
                child: SettingsRow(
                  icon: Icons.translate_rounded,
                  title: l10n.settingsLyricsLanguage,
                  subtitle: l10n.settingsLyricsLanguageHint,
                  value: language == null
                      ? l10n.settingsLyricsLanguageAuto
                      : languageName(l10n, language),
                  onTap: () => _pickLanguage(context, ref),
                ),
              ),
            ],
          ),
          const SizedBox(height: SongletSpace.x6),
          SettingsGroup(
            title: l10n.settingsSectionAbout,
            children: [
              TestId(
                'settings.about',
                child: SettingsRow(
                  icon: Icons.auto_awesome_outlined,
                  title: l10n.aboutTitle,
                  onTap: () => context.open(const AboutRoute()),
                ),
              ),
              if (legal.termsUrl case final url? when url.isNotEmpty)
                SettingsRow(
                  icon: Icons.description_outlined,
                  title: l10n.settingsTerms,
                  onTap: () => open(url),
                ),
              if (legal.privacyUrl case final url? when url.isNotEmpty)
                SettingsRow(
                  icon: Icons.privacy_tip_outlined,
                  title: l10n.settingsPrivacy,
                  onTap: () => open(url),
                ),
            ],
          ),
          // DEV debug builds only: `devKeychainResetAvailable` is a
          // compile-time constant, so elsewhere this entry is not built at all.
          if (devKeychainResetAvailable) ...[
            const SizedBox(height: SongletSpace.x6),
            const _DevTools(),
          ],
          if (version.isNotEmpty) ...[
            const SizedBox(height: SongletSpace.x6),
            Text(
              l10n.settingsVersion(version),
              textAlign: TextAlign.center,
              style: SongletType.footnote.copyWith(color: c.inkSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// Profile: the account's credits (`credits_available`, server truth — "—"
/// while unknown) and its account ID, the UUID of the device session (`abid`,
/// also StoreKit's `appAccountToken`), shown in full with a one-tap copy for
/// support requests.
class _ProfileGroup extends ConsumerWidget {
  const _ProfileGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final credits = ref.watch(musicEntitlementProvider).value?.creditsAvailable;
    final accountId = ref.watch(appAccountTokenProvider);
    Future<void> copy(String id) async {
      await Clipboard.setData(ClipboardData(text: id));
      ref.read(messageControllerProvider).success(l10n.commonCopied);
    }

    return SettingsGroup(
      title: l10n.settingsSectionProfile,
      children: [
        TestId(
          'settings.credits',
          child: SettingsRow(
            icon: Icons.toll_outlined,
            title: l10n.settingsCredits,
            value: credits == null
                ? '—'
                : NumberFormat.decimalPattern(l10n.localeName).format(credits),
          ),
        ),
        TestId(
          'settings.accountId',
          child: SettingsRow(
            icon: Icons.badge_outlined,
            title: l10n.settingsAccountId,
            subtitle: accountId ?? '—',
            onTap: accountId == null ? null : () => copy(accountId),
            trailing: accountId == null
                ? null
                : TestId(
                    'settings.copyAccountId',
                    child: IconButton(
                      tooltip: l10n.settingsCopyAccountId,
                      icon: const Icon(Icons.copy_rounded),
                      onPressed: () => copy(accountId),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// DEV-only tools (built only when [devKeychainResetAvailable]): deleting the
/// app's Keychain keys, behind an explicit confirmation.
class _DevTools extends ConsumerWidget {
  const _DevTools();

  Future<void> _resetKeychain(BuildContext context, WidgetRef ref) async {
    final reset = ref.read(devKeychainResetProvider);
    if (reset == null) return;
    final l10n = AppLocalizations.of(context);
    final c = SongletColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.devKeychainResetConfirmTitle),
        content: Text(l10n.devKeychainResetConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TestId(
            'settings.dev.keychainReset.confirm',
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: c.danger),
              child: Text(l10n.commonDelete),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messages = ref.read(messageControllerProvider);
    try {
      await reset.run();
      messages.success(l10n.devKeychainResetDone);
    } on Object catch (error, stackTrace) {
      final failure = ref.read(errorHandlerProvider).handle(error, stackTrace);
      messages.show(failureMessage(l10n, failure));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(devKeychainResetProvider) == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return SettingsGroup(
      title: l10n.devSectionTitle,
      children: [
        TestId(
          'settings.dev.keychainReset',
          child: SettingsRow(
            icon: Icons.key_off_outlined,
            title: l10n.devKeychainReset,
            subtitle: l10n.devKeychainResetHint,
            destructive: true,
            onTap: () => _resetKeychain(context, ref),
          ),
        ),
      ],
    );
  }
}
