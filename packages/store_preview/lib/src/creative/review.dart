import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:yaml/yaml.dart';

import '../core/errors.dart';
import '../core/fields.dart';
import 'composer.dart';
import 'definition.dart';

/// A person's verdict belongs to the rendered bytes and their provenance,
/// not just a scene name that may later resolve to another recording.
String renderedReviewBasis(CreativeFiles files) {
  final parts = <String>[];
  for (final path in [files.file, files.edl, if (files.video) files.poster]) {
    final file = File(path);
    if (!file.existsSync()) throw ConfigError('review: render every storefront before reviewing (${files.id} is incomplete)');
    parts.add(sha256.convert(file.readAsBytesSync()).toString());
  }
  return sha256.convert(utf8.encode(jsonEncode([files.id, ...parts]))).toString();
}

/// What a review vouches for: the asset's type, spec and placements, and
/// exactly which footage it shows. A change to any of them makes the review
/// stale.
String reviewBasis(CreativeSlot slot, CreativeAsset asset) {
  final basis = {
    'type': asset.type,
    'spec': slot.spec,
    'placements': slot.placements,
    if (slot.device != null) 'device': slot.device,
    if (slot.displayTarget != 'universal') 'display_target': slot.displayTarget,
    'footage': [
      for (final f in asset.footage) {'script': f.script, 'scene': f.scene, 'from': f.from},
    ],
    if (asset.isVideo) 'durations': [for (final s in asset.scenes) s.duration],
  };
  return sha256.convert(utf8.encode(jsonEncode(basis))).toString();
}

/// One person's review of an asset (all its storefronts).
class CreativeReview {
  const CreativeReview({
    required this.asset,
    required this.realUi,
    required this.reviewer,
    required this.date,
    required this.basis,
    this.note,
    this.artifacts = const {},
  });

  factory CreativeReview.read(Fields f) {
    f.only({'asset', 'real_ui', 'reviewer', 'date', 'basis', 'note', 'artifacts'});
    final date = f.string('date');
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) throw ConfigError('${f.where} › date: YYYY-MM-DD');
    final realUi = f.raw['real_ui'];
    if (realUi is! bool) throw ConfigError('${f.where} › real_ui: true or false');
    return CreativeReview(
      asset: f.string('asset'),
      realUi: realUi,
      reviewer: f.string('reviewer'),
      date: date,
      basis: f.string('basis'),
      note: f.optString('note'),
      artifacts: {for (final e in (f.optMap('artifacts')?.raw ?? const <String, Object?>{}).entries) e.key: '${e.value}'},
    );
  }

  /// The asset id as written in the definition (`header.{storefront}`).
  final String asset;

  /// The asset shows the app in real use (App Review 2.3.3), as the reviewer
  /// judged from its frames.
  final bool realUi;
  final String reviewer;
  final String date;
  final String basis;
  final String? note;
  final Map<String, String> artifacts;

  Map<String, Object?> toJson() => {
    'asset': asset,
    'real_ui': realUi,
    'reviewer': reviewer,
    'date': date,
    'basis': basis,
    'note': ?note,
    if (artifacts.isNotEmpty) 'artifacts': artifacts,
  };
}

/// `store_preview/<app>/creative_review.yaml`: the only source of a manifest
/// entry's `real_ui` (template ADR-0011). Written by `store-preview review`,
/// run by the person who looked at the assets — never derived from a file
/// name, a model's judgement or the tool's own guess. No (or a stale) review
/// means `real_ui: false`.
class ReviewLog {
  ReviewLog(this.path, this.reviews);

  factory ReviewLog.load(String path) {
    final file = File(path);
    if (!file.existsSync()) return ReviewLog(path, []);
    final f = readYamlFile(path)..only({'reviews'});
    return ReviewLog(path, [for (final r in f.maps('reviews')) CreativeReview.read(r)]);
  }

  final String path;
  final List<CreativeReview> reviews;

  CreativeReview? of(String asset) => reviews.where((r) => r.asset == asset).lastOrNull;

  /// The review's verdict for [asset] if it still matches what the asset
  /// shows; null when there is none or it is stale.
  bool? realUi(CreativeSlot slot, CreativeAsset asset, {CreativeFiles? files}) {
    final r = of(asset.id);
    if (r == null || r.basis != reviewBasis(slot, asset)) return null;
    if (files != null) {
      if (!r.artifacts.containsKey(files.id)) return null;
      try {
        if (r.artifacts[files.id] != renderedReviewBasis(files)) return null;
      } on ConfigError {
        return null;
      }
    }
    return r.realUi;
  }

  /// Records [review], replacing an earlier one of the same asset.
  void record(CreativeReview review) {
    reviews
      ..removeWhere((r) => r.asset == review.asset)
      ..add(review);
    final out = StringBuffer()
      ..writeln('# Human review of what each creative asset shows (store-preview review;')
      ..writeln('# template ADR-0011). real_ui feeds the assets manifest; a review goes stale')
      ..writeln('# when the asset\'s footage, spec or placements change. Never edited by a tool')
      ..writeln('# on its own judgement.')
      ..writeln('reviews:');
    for (final r in reviews) {
      out.writeln('  - ${jsonEncode(r.toJson())}');
    }
    File(path).writeAsStringSync(out.toString());
    // Round-trip: what was written reads back the same.
    loadYaml(File(path).readAsStringSync());
  }
}
