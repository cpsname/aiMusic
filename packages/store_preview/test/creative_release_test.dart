import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:store_preview/store_preview.dart';

import 'support/creative_fixture.dart';

void main() {
  late Directory root;
  late String dist;
  void write(String relative, String bytes) => (File(p.join(dist, relative))..parent.createSync(recursive: true)).writeAsStringSync(bytes);
  setUp(() {
    root = Directory.systemTemp.createTempSync('creative_release_');
    dist = p.join(root.path, 'dist', 'notes');
    write('creative/en-US/header.png', 'original test image bytes');
    write('creative/en-US/header.edl.json', '{"provenance":"fixture"}');
    write(
      'assets-manifest.json',
      jsonEncode({
        'app': {'store_preview_app': 'notes', 'bundle_id': 'org.example.notes'},
        'entries': [
          {
            'id': 'header.en-US',
            'file': 'creative/en-US/header.png',
            'sha256': fileSha256(p.join(dist, 'creative/en-US/header.png')),
            'source': {'evidence': 'creative/en-US/header.edl.json'},
          },
        ],
      }),
    );
  });
  tearDown(() => root.deleteSync(recursive: true));

  test('a failed render keeps original bytes and creates a verifiable immutable release', () {
    final run = CreativeReleaseRun.begin(dist, app: 'notes', bundleId: 'org.example.notes');
    final archive = run.archive!;
    File(p.join(run.stage.path, 'creative/en-US/header.png')).writeAsStringSync('incomplete render');
    run.close();
    expect(File(p.join(dist, 'creative/en-US/header.png')).readAsStringSync(), 'original test image bytes');
    expect(File(p.join(archive, 'creative/en-US/header.png')).readAsStringSync(), 'original test image bytes');
    expect(archiveCreativeRelease(dist, app: 'notes', bundleId: 'org.example.notes'), archive);
    File(p.join(archive, 'creative/en-US/header.png')).writeAsStringSync('tampered archive');
    expect(() => archiveCreativeRelease(dist, app: 'notes', bundleId: 'org.example.notes'), throwsA(isA<ConfigError>()));
  });

  test('commit publishes files together while the previous generation remains recoverable', () {
    final run = CreativeReleaseRun.begin(dist, app: 'notes', bundleId: 'org.example.notes');
    final archive = run.archive!;
    File(p.join(run.stage.path, 'creative/en-US/header.png')).writeAsStringSync('next generation');
    File(p.join(run.stage.path, 'assets-manifest.json')).writeAsStringSync('{"fixture":"next generation"}');
    run.commit();
    run.close();
    expect(File(p.join(dist, 'creative/en-US/header.png')).readAsStringSync(), 'next generation');
    expect(File(p.join(dist, 'assets-manifest.json')).readAsStringSync(), '{"fixture":"next generation"}');
    expect(File(p.join(archive, 'creative/en-US/header.png')).readAsStringSync(), 'original test image bytes');
  });

  test('preexisting drift cannot be hidden by rerendering or replacing the manifest', () {
    final manifest = File(p.join(dist, 'assets-manifest.json')).readAsStringSync();
    write('creative/en-US/header.png', 'overwritten previously');
    expect(
      () => CreativeReleaseRun.begin(dist, app: 'notes', bundleId: 'org.example.notes'),
      throwsA(isA<ConfigError>().having((e) => e.message, 'message', contains('No hashes were rewritten'))),
    );
    expect(File(p.join(dist, 'assets-manifest.json')).readAsStringSync(), manifest);
    expect(Directory(p.join(dist, '.releases')).existsSync(), isFalse);
  });

  test('unreviewed working files cannot inherit the previous delivery manifest', () {
    final originalManifest = File(p.join(dist, 'assets-manifest.json')).readAsStringSync();
    final run = CreativeReleaseRun.begin(dist, app: 'notes', bundleId: 'org.example.notes');
    final archive = run.archive!;
    File(p.join(run.stage.path, 'creative/en-US/header.png')).writeAsStringSync('new screenshot awaiting a person');
    run.commit(awaitingReview: true);
    run.close();
    expect(File(p.join(dist, 'creative/en-US/header.png')).readAsStringSync(), 'new screenshot awaiting a person');
    expect(File(p.join(dist, 'assets-manifest.json')).existsSync(), isFalse);
    expect(File(p.join(archive, 'assets-manifest.json')).readAsStringSync(), originalManifest);
    expect(File(p.join(archive, 'creative/en-US/header.png')).readAsStringSync(), 'original test image bytes');
  });

  test('wrong app identity and escaping manifest paths are rejected before archiving', () {
    expect(() => releaseFiles(dist, app: 'other', bundleId: 'org.example.other'), throwsA(isA<ConfigError>()));
    expect(() => releasePath(dist, '../other/header.png'), throwsA(isA<ConfigError>()));
    Link(p.join(dist, 'alias')).createSync(root.path);
    expect(() => releasePath(dist, 'alias/secret.txt'), throwsA(isA<ConfigError>()));
    Link(p.join(dist, '.releases')).createSync(root.path);
    expect(() => archiveCreativeRelease(dist, app: 'notes', bundleId: 'org.example.notes'), throwsA(isA<ConfigError>()));
  });

  test('real_ui requires human review of the exact output and EDL, including after a rerecord', () {
    final path = p.join(root.path, 'page.yaml');
    File(path).writeAsStringSync(fixtureCreative);
    final def = loadCreative(path);
    final slot = def.slots[1];
    final asset = slot.assets.first;
    final files = CreativeFiles(distDir: dist, id: 'header', storefront: 'en-US', video: false);
    final log = ReviewLog(p.join(root.path, 'creative_review.yaml'), []);
    log.record(CreativeReview(asset: asset.id, realUi: true, reviewer: 'Regression fixture reviewer', date: '2026-10-13', basis: reviewBasis(slot, asset)));
    expect(log.realUi(slot, asset, files: files), isNull, reason: 'legacy scene-only evidence cannot attest to rendered bytes');
    log.record(
      CreativeReview(
        asset: asset.id,
        realUi: true,
        reviewer: 'Regression fixture reviewer',
        date: '2026-10-13',
        basis: reviewBasis(slot, asset),
        artifacts: {files.id: renderedReviewBasis(files)},
      ),
    );
    expect(ReviewLog.load(log.path).realUi(slot, asset, files: files), isTrue);
    write('creative/en-US/header.edl.json', '{"provenance":"new recording"}');
    expect(log.realUi(slot, asset, files: files), isNull);
  });
}
