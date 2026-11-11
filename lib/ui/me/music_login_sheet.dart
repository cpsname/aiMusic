import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/music_failure_copy.dart';

/// Opens the sign-in sheet for a guest to upgrade to a real account.
Future<void> showLoginSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _LoginSheet(),
  );
}

class _LoginSheet extends ConsumerStatefulWidget {
  const _LoginSheet();

  @override
  ConsumerState<_LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends ConsumerState<_LoginSheet> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(username: _username.text.trim(), password: _password.text);
      if (mounted) Navigator.of(context).pop();
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() {
        _error = failureMessageText(AppLocalizations.of(context), failure);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: StudioTokens.spaceLg,
        end: StudioTokens.spaceLg,
        top: StudioTokens.spaceLg,
        bottom: MediaQuery.of(context).viewInsets.bottom + StudioTokens.spaceLg,
      ),
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.loginTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: StudioTokens.spaceLg),
            TextField(
              controller: _username,
              autocorrect: false,
              enabled: !_loading,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: l10n.loginUsername),
            ),
            const SizedBox(height: StudioTokens.spaceMd),
            TextField(
              controller: _password,
              obscureText: true,
              enabled: !_loading,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(labelText: l10n.loginPassword),
            ),
            if (_error != null) ...[
              const SizedBox(height: StudioTokens.spaceMd),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: StudioTokens.spaceLg),
            ObsButton(
              label: l10n.loginSubmit,
              loading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
