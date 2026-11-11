import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/errors.dart';
import '../creative/definition.dart';
import 'app.dart';
import 'script.dart';

/// "Free" in the languages the App Store serves most, and other pricing
/// words: App Review 2.3.7 keeps prices and such terms out of previews.
/// app.yaml `captions.banned_words` adds to it (other apps' names, …).
const List<String> builtInBannedWords = [
  'free', 'gratis', 'gratuit', 'gratuite', 'kostenlos', 'grátis', 'gratuito', 'gratuita', 'gratuitamente', //
  'ücretsiz', 'miễn phí', 'मुफ़्त', 'मुफ्त', '無料', '免费', '免費', '무료', 'бесплатно', 'darmowy', 'gratuïtament',
  'zdarma', 'ilmainen', 'ingyenes', 'percuma', 'ฟรี', 'مجاني', 'חינם',
];

/// Currency signs and price-like amounts.
final RegExp pricePattern = RegExp(r'[$€£¥₹₩₫₺₽]|\d+[.,]\d{2}\b|\bR\$|\bRp\b|\b(USD|EUR|GBP|JPY|CNY)\b');

/// Dates and seasonal references that age a preview (Apple: "Avoid any
/// seasonal or timely references that will age your video").
final RegExp timelyPattern = RegExp(
  r'\b(19|20)\d{2}\b|\bnew for\b|\bthis (spring|summer|fall|autumn|winter|year|season)\b|\blimited time\b',
  caseSensitive: false,
);

/// Website addresses and copyright signs (Apple, asset best practices:
/// "Don't include specific pricing, discounts, website URLs, copyright
/// symbols").
final RegExp urlPattern = RegExp(r'https?://|\bwww\.|\b[a-z0-9-]+\.(com|net|org|io|app|co)\b', caseSensitive: false);
final RegExp copyrightPattern = RegExp('[©℗]');

/// Claims that cannot be verified and Apple's own recognitions ("Avoid
/// claims that can't be verified, such as awards or recognition …", "don't
/// include any Apple-designated recognitions"), and other platforms ("Don't
/// include logos or references to other platforms or marketplaces").
/// app.yaml `captions.banned_words` adds an app's own (localized) ones.
const List<String> builtInClaimWords = [
  "editor's choice", "editors' choice", 'app of the day', 'game of the day', 'apple design award', 'award-winning', //
  'award winning', '#1', 'no. 1', 'number one', 'google play', 'play store', 'android', 'galaxy store', 'amazon appstore',
  'microsoft store',
];

/// Unicode code points — the strict count (a Devanagari vowel sign or a
/// Vietnamese tone mark counts as its own character).
int textLength(String text) => text.runes.length;

/// The prefix strings of one storefront's ARB: key → text.
Map<String, String> captionsFromArb(String root, PreviewApp app, Storefront storefront) {
  final file = File(p.join(root, app.captions.arbDir, app.captions.arbName(storefront.uiLocale)));
  if (!file.existsSync()) throw ConfigError('no ARB for ${storefront.id}: ${file.path}');
  final arb = jsonDecode(file.readAsStringSync());
  if (arb is! Map) throw ConfigError('${file.path}: not a JSON object');
  return {
    for (final e in arb.entries)
      if (('${e.key}'.startsWith(app.captions.prefix) || '${e.key}'.startsWith(app.captions.creativePrefix)) && e.value is String)
        '${e.key}': e.value as String,
  };
}

/// What text a storefront's previews and creative assets show, and where it
/// is checked.
enum TextUse { caption, claim, cta, disclosure, creative }

/// Every ARB key the scripts, the brand and the creative assets put on
/// screen, with its use.
Map<String, TextUse> usedTexts(PreviewApp app, Iterable<PreviewScript> scripts, {Iterable<CreativeDefinition> creatives = const []}) => {
  for (final s in scripts) ...{
    for (final c in s.captions) c.key: TextUse.caption,
    for (final card in s.cards)
      if (card.textKey != null) card.textKey!: TextUse.claim,
  },
  if (scripts.any((s) => !s.isCapture)) app.brand.ctaKey: TextUse.cta,
  if (scripts.any((s) => !s.isCapture) && app.requiresPurchase && app.brand.disclosureKey != null) app.brand.disclosureKey!: TextUse.disclosure,
  for (final d in creatives)
    for (final slot in d.slots)
      if (slot.text != null && slot.assets.any((a) => a.perStorefront)) slot.text!: TextUse.creative,
};

/// The content rules every on-screen text obeys: no banned word ("free",
/// other apps …), no price, no date or season, no website or copyright sign,
/// no unverifiable claim or other platform. The first problem, or null.
String? contentProblem(String text, List<String> banned) {
  final word = bannedWordIn(text, [...banned, ...builtInClaimWords]);
  if (word != null) return 'contains "$word"';
  if (pricePattern.hasMatch(text)) return 'looks like a price';
  if (timelyPattern.hasMatch(text)) return 'carries a date or seasonal reference';
  if (urlPattern.hasMatch(text)) return 'holds a website address';
  if (copyrightPattern.hasMatch(text)) return 'holds a copyright sign';
  return null;
}

/// A banned word in [text] ([words] lower-case): whole words for Latin
/// words, substrings for the rest.
String? bannedWordIn(String text, List<String> words) {
  final lower = text.toLowerCase();
  for (final word in words) {
    final w = word.toLowerCase();
    final latin = RegExp(r'^[a-z ]+$').hasMatch(w);
    final hit = latin
        ? RegExp('(^|[^\\p{L}])${RegExp.escape(w)}(\$|[^\\p{L}])', unicode: true).hasMatch(lower)
        : lower.contains(w);
    if (hit) return word;
  }
  return null;
}

/// Checks every on-screen text of [app] in every storefront.
Problems checkCaptions(
  Map<String, Map<String, String>> byStorefront,
  PreviewApp app,
  Iterable<PreviewScript> scripts, {
  Iterable<CreativeDefinition> creatives = const [],
}) {
  final problems = Problems();
  final used = usedTexts(app, scripts, creatives: creatives);
  final banned = [...builtInBannedWords, ...app.captions.bannedWords];
  for (final s in app.storefronts) {
    final texts = byStorefront[s.id] ?? const {};
    for (final MapEntry(key: key, value: use) in used.entries) {
      final text = texts[key];
      if (text == null || text.trim().isEmpty) {
        problems.add('${s.id}: $key is missing (add it to ${app.captions.arbName(s.uiLocale)})');
        continue;
      }
      final limit = textLimit(use, s, app.captions);
      final length = textLength(text);
      problems.check(length <= limit, '${s.id}: $key "$text" is $length characters (≤ $limit)');
      final content = contentProblem(text, banned);
      problems.check(content == null, '${s.id}: $key "$text" $content');
    }
  }
  return problems;
}

/// The character limit of a text of [use] in [storefront].
int textLimit(TextUse use, Storefront storefront, CaptionRules rules) => switch (use) {
  TextUse.disclosure => storefront.isCjk ? rules.maxDisclosureCharsCjk : rules.maxDisclosureChars,
  TextUse.creative => storefront.isCjk ? rules.creativeMaxCharsCjk : rules.creativeMaxChars,
  _ => storefront.isCjk ? rules.maxCharsCjk : rules.maxChars,
};

/// Writes `captions/<storefront>.json` (sorted keys: what the renderer reads).
void writeCaptionFiles(String dir, Map<String, Map<String, String>> byStorefront) {
  Directory(dir).createSync(recursive: true);
  for (final e in byStorefront.entries) {
    final sorted = Map.fromEntries(e.value.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    File(p.join(dir, '${e.key}.json')).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(sorted)}\n');
  }
}

Map<String, String> readCaptionFile(String dir, String storefront) {
  final file = File(p.join(dir, '$storefront.json'));
  if (!file.existsSync()) throw ConfigError('no ${file.path} — run `store-preview captions`');
  final raw = jsonDecode(file.readAsStringSync());
  if (raw is! Map) throw ConfigError('${file.path}: not a JSON object');
  return {for (final e in raw.entries) '${e.key}': '${e.value}'};
}

String srtStamp(double s) {
  final ms = (s * 1000).round();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(ms ~/ 3600000)}:${two(ms ~/ 60000 % 60)}:${two(ms ~/ 1000 % 60)},${(ms % 1000).toString().padLeft(3, '0')}';
}

/// SubRip of every on-screen text of [script] in one storefront: the cards'
/// lines and the captions, in time order.
String srt(List<({double from, double to, String text})> cues) {
  final sorted = [...cues]..sort((a, b) => a.from.compareTo(b.from));
  final out = StringBuffer();
  for (final (i, c) in sorted.indexed) {
    out
      ..writeln(i + 1)
      ..writeln('${srtStamp(c.from)} --> ${srtStamp(c.to)}')
      ..writeln(c.text)
      ..writeln();
  }
  return out.toString();
}
