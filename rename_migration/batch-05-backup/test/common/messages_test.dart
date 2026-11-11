import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:songlet/l10n/generated/app_localizations.dart';
import 'package:songlet/ui/common/messages.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  late AppLocalizations l10n;
  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('failureMessage', () {
    test('非空 message 优先(后端已本地化),error 变体、无 action', () {
      final spec = failureMessage(l10n, const ServerFailure(message: 'boom'));
      expect(spec.variant, MessageVariant.error);
      expect(spec.text, 'boom');
      expect(spec.hasAction, isFalse);
    });

    test('NetworkFailure 空 message → 网络兜底', () {
      final spec = failureMessage(l10n, const NetworkFailure(message: ''));
      expect(spec.text, l10n.commonNetworkError);
    });

    test('offline NetworkFailure → 离线专属文案(与卡片一致)', () {
      final spec = failureMessage(
        l10n,
        const NetworkFailure(message: '', kind: NetworkFailureKind.offline),
      );
      // PRD §6.5 NETWORK_OFFLINE copy.
      expect(spec.text, l10n.errorNetworkOffline);
    });

    test('AuthFailure 空 message → 鉴权兜底', () {
      final spec = failureMessage(l10n, const AuthFailure(message: ''));
      expect(spec.text, l10n.commonAuthError);
    });

    test('其它 Failure 空 message → 调用方 fallback,缺省退通用', () {
      expect(
        failureMessage(
          l10n,
          const ServerFailure(message: ''),
          fallback: 'X',
        ).text,
        'X',
      );
      expect(
        failureMessage(l10n, const ServerFailure(message: '')).text,
        l10n.commonError,
      );
    });

    test('onRetry 提供 → 带重试 action', () {
      final spec = failureMessage(
        l10n,
        const ServerFailure(message: 'x'),
        onRetry: () {},
      );
      expect(spec.hasAction, isTrue);
      expect(spec.actionLabel, l10n.commonRetry);
    });
  });
}
