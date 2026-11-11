import 'dart:io' show Platform;

import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';
import 'package:url_launcher/url_launcher.dart';

import 'music_messages.dart';

/// Opens [url] externally (browser / App Store / Play). The message controller
/// is captured before the await so a failure message is safe to show afterwards.
Future<void> openExternalUrl(
  BuildContext context,
  String url, {
  required String errorMessage,
}) async {
  final messages = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(messageControllerProvider);
  final uri = Uri.tryParse(url);
  var opened = false;
  if (uri != null) {
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      opened = false;
    }
  }
  if (!opened) {
    messages.error(errorMessage);
  }
}

/// The platform's native manage-subscriptions screen (App Store / Play account).
String manageSubscriptionsUrl() => Platform.isAndroid
    ? 'https://play.google.com/store/account/subscriptions'
    : 'https://apps.apple.com/account/subscriptions';

/// Apple's standard EULA — the Apple-sanctioned Terms of Use for apps that ship
/// no custom agreement. The last-resort terms link on Apple platforms, where
/// App Review 3.1.2 requires a functional EULA link on every subscription
/// screen.
const String appleStandardEulaUrl =
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

/// The legal links the paywall actually renders (App Review 3.1.2 requires the
/// Terms + Privacy links to be present and functional). Server-supplied links
/// (`/app/init`) win; the compile-time `TERMS_URL` / `PRIVACY_URL` defines back
/// them up (the store-build guard requires both, so a backend misconfiguration
/// can no longer make the links vanish); on Apple platforms the terms fall back
/// to [appleStandardEulaUrl] as a last resort. Subscription terms stay
/// server-only — an optional extra with no meaningful generic fallback.
///
/// [isAndroid] is injectable for tests; empty strings count as absent.
LegalInfo effectiveLegalInfo({
  required LegalInfo? server,
  required EnvConfig env,
  bool? isAndroid,
}) {
  final android = isAndroid ?? Platform.isAndroid;
  return LegalInfo(
    termsUrl: _firstUrl([
      server?.termsUrl,
      env.termsUrl,
      if (!android) appleStandardEulaUrl,
    ]),
    privacyUrl: _firstUrl([server?.privacyUrl, env.privacyUrl]),
    subscriptionTermsUrl: _firstUrl([server?.subscriptionTermsUrl]),
  );
}

String? _firstUrl(Iterable<String?> candidates) {
  for (final candidate in candidates) {
    if (candidate != null && candidate.isNotEmpty) return candidate;
  }
  return null;
}
