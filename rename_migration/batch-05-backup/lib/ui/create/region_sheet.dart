import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../l10n/ui_locale.dart';
import '../common/test_id.dart';
import 'create_labels.dart';

/// P02 — "Where will it be heard?": the 14 region presets (PRD §7.3) with
/// search and the lyrics-language row. Region shapes culture only — genres,
/// language, festivals — never availability (ADR-0005).
class RegionSheet extends ConsumerStatefulWidget {
  const RegionSheet({super.key});

  @override
  ConsumerState<RegionSheet> createState() => _RegionSheetState();
}

class _RegionSheetState extends ConsumerState<RegionSheet> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final locale = ref.read(systemUiLocaleProvider);
      ref
          .read(creationDraftProvider.notifier)
          .ensureStarted(
            deviceLanguage: locale.languageCode,
            deviceScript: locale.scriptCode,
          );
    });
  }

  List<RegionPreset> _matches(AppLocalizations l10n) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return RegionPresets.all;
    return RegionPresets.all
        .where(
          (r) =>
              countryName(l10n, r.code).toLowerCase().contains(q) ||
              r.code.toLowerCase() == q,
        )
        .toList(growable: false);
  }

  Future<void> _pickLanguage(CreationDraft draft) async {
    final l10n = AppLocalizations.of(context);
    final ordered = [
      ...draft.region.languages,
      ...LyricLanguage.values.where((l) => !draft.region.languages.contains(l)),
    ];
    final picked = await showModalBottomSheet<LyricLanguage>(
      context: context,
      isScrollControlled: true,
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
              horizontal: SongletSpace.sheetInset,
            ),
            children: [
              Text(
                l10n.regionLanguageSheetTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: SongletSpace.x2),
              for (final language in ordered)
                OptionRow(
                  title: languageName(l10n, language),
                  dense: true,
                  selected: language == draft.lyricLanguage,
                  onTap: () => Navigator.of(context).pop(language),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) {
      ref
          .read(creationDraftProvider.notifier)
          .update((d) => d.copyWith(lyricLanguage: picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = SongletColors.of(context);
    final draft = ref.watch(creationDraftProvider).draft;
    final matches = _matches(l10n);
    final deviceLanguage = ref.read(systemUiLocaleProvider).languageCode;
    Widget row(int i) {
      final region = matches[i];
      return TestId(
        'region.${region.code}',
        child: CountryRow(
          flag: region.flag,
          name: countryName(l10n, region.code),
          selected: draft?.region.code == region.code,
          showDivider: i < matches.length - 1,
          onTap: () => ref
              .read(creationDraftProvider.notifier)
              .selectRegion(region, deviceLanguage: deviceLanguage),
        ),
      );
    }

    // At accessibility text sizes the fixed parts alone outgrow the sheet, so
    // the whole sheet scrolls as one list instead of just the countries.
    final accessible = SongletType.isAccessibilitySize(context);
    final Widget countries = matches.isEmpty
        ? Center(
            child: Text(
              l10n.regionNoMatch,
              style: SongletType.callout.copyWith(color: c.inkSecondary),
            ),
          )
        : SurfaceCard(
            padding: EdgeInsetsDirectional.zero,
            child: accessible
                ? Column(
                    children: [for (var i = 0; i < matches.length; i++) row(i)],
                  )
                : ListView.builder(
                    padding: EdgeInsetsDirectional.zero,
                    itemCount: matches.length,
                    itemBuilder: (context, i) => row(i),
                  ),
          );
    final children = <Widget>[
      Semantics(
        header: true,
        child: Text(
          l10n.regionTitle,
          style: SongletType.title1.copyWith(
            color: c.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(height: SongletSpace.x4),
      SearchField(
        hint: l10n.regionSearchHint,
        onChanged: (v) => setState(() => _query = v),
      ),
      const SizedBox(height: SongletSpace.x4),
      if (accessible) countries else Expanded(child: countries),
      const SizedBox(height: SongletSpace.x4),
      if (draft != null)
        TestId(
          'region.language',
          child: SurfaceCard(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: SongletSpace.x4,
              vertical: SongletSpace.x4,
            ),
            onTap: () => _pickLanguage(draft),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.regionLyricsRow(
                      languageName(l10n, draft.lyricLanguage),
                    ),
                    style: SongletType.body.copyWith(color: c.ink),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: c.inkTertiary),
              ],
            ),
          ),
        ),
      Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          SongletSpace.x4,
          SongletSpace.x2,
          SongletSpace.x4,
          SongletSpace.x4,
        ),
        child: Text(
          l10n.regionHelper,
          style: SongletType.footnote.copyWith(color: c.inkSecondary),
        ),
      ),
      TestId(
        'region.done',
        child: ObsButton(
          label: l10n.commonDone,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      const SizedBox(height: SongletSpace.x4),
    ];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: SongletSpace.sheetInset,
        ),
        child: accessible
            ? ListView(children: children)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
      ),
    );
  }
}
