import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../l10n/ui_locale.dart';

class UiLanguageSheet extends ConsumerStatefulWidget {
  const UiLanguageSheet({super.key});

  @override
  ConsumerState<UiLanguageSheet> createState() => _UiLanguageSheetState();
}

class _UiLanguageSheetState extends ConsumerState<UiLanguageSheet> {
  bool _saving = false;
  bool _failed = false;

  Future<void> _select(Locale? locale) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await ref.read(uiLanguagePreferenceProvider.notifier).select(locale);
      if (mounted) Navigator.of(context).pop();
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(uiLanguagePreferenceProvider);
    return PopScope(
      canPop: !_saving,
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.sizeOf(context).height *
                SongletSize.pickerSheetFactor,
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(SongletSpace.gutter),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.settingsAppLanguage,
                    style: SongletType.title2,
                  ),
                ),
                if (_saving) const LinearProgressIndicator(),
                if (_failed)
                  Text(
                    l10n.settingsLanguageSaveFailed,
                    style: SongletType.callout.copyWith(
                      color: SongletColors.of(context).danger,
                    ),
                  ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      OptionRow(
                        key: const ValueKey('settings.uiLanguage.system'),
                        title: l10n.settingsLanguageSystem,
                        selected: selected == null,
                        onTap: _saving ? null : () => _select(null),
                      ),
                      for (final locale in supportedUiLocales)
                        OptionRow(
                          key: ValueKey(
                            'settings.uiLanguage.${locale.toLanguageTag()}',
                          ),
                          title: uiLanguageName(locale),
                          selected: selected == locale,
                          onTap: _saving ? null : () => _select(locale),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
