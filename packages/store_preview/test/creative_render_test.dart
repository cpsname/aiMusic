import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:store_preview/store_preview.dart';

import 'support/creative_fixture.dart';
import 'support/fixture.dart';

/// The real creative renderer — native tools, ffmpeg — on synthetic footage
/// from two takes: every asset meets the spec, compliance and narrative
/// layers, the manifest passes ascpub's contract and matches its files; and
/// the spec layer refuses real files that break each rule. Needs macOS with
/// Xcode and ffmpeg; skipped elsewhere.
void main() {
  final tools = Process.runSync('which', ['ffmpeg', 'swiftc']).stdout.toString().trim().split('\n').length == 2;
  const runner = SystemProcessRunner();

  late String pkg;
  setUpAll(() async => pkg = await packageRoot());

  Future<void> ff(List<String> args) async {
    final r = await Process.run('ffmpeg', ['-v', 'error', '-y', ...args]);
    if (r.exitCode != 0) fail('ffmpeg ${args.join(' ')}: ${r.stderr}');
  }

  group('render', () {
    late FixtureRepo repo;
    setUp(() => repo = creativeRepo(pkg));
    tearDown(() => repo.delete());

    test(
      'images and a seamless muted loop from two takes, the manifest in the contract',
      () async {
        await synthesizeCreativeTakes(repo);
        final project = Project.load(root: repo.root, appId: 'demo', packageRoot: pkg);
        final texts = project.textsFromArb();
        project.checkConfig(texts: texts).throwIfAny('config');
        writeCaptionFiles(project.app.captionsDir, texts);
        final native = await NativeTools.ensure(runner, packageRoot: pkg, binDir: p.join(pkg, '.dart_tool', 'store_preview_test_bin'));
        final composer = CreativeComposer(
          runner: runner,
          app: project.app,
          scripts: project.allScripts,
          manifest: project.manifest(),
          defaults: project.creativeDefaults,
          templates: project.templates,
          tools: native,
          root: repo.root,
          buildDir: project.buildDir,
        );
        final jobs = creativeJobs(project.creatives, project.app, storefronts: [project.app.storefront('en-US')]);
        expect(jobs.map((j) => j.id), ['header.universal', 'header.en-US', 'header.en-US.video', 'search.en-US']);
        final reports = <CreativeReport>[];
        for (final job in jobs) {
          final files = await composer.render(job, texts: project.texts('en-US'), distDir: project.distDir, slotId: 'iphone');
          reports.add(
            await checkCreative(
              job,
              files,
              app: project.app,
              defaults: project.creativeDefaults,
              templates: project.templates,
              runner: runner,
              workDir: p.join(project.buildDir, 'check', job.id),
            ),
          );
        }
        for (final r in reports) {
          expect(r.failures, isEmpty, reason: r.id);
        }
        final info = <String, VideoStream>{
          for (final j in jobs)
            j.id: const FfprobeProber().probe(CreativeFiles(distDir: project.distDir, id: j.id, storefront: j.storefront, video: j.asset.isVideo).file)!.video!,
        };
        expect('${info['header.universal']!.width}×${info['header.universal']!.height}', '5244×2950');
        expect('${info['header.en-US']!.width}×${info['header.en-US']!.height}', '3840×1646');
        expect(info['header.en-US']!.pixFmt, 'rgb24');
        expect('${info['search.en-US']!.width}×${info['search.en-US']!.height}', '3840×2560');
        final video = CreativeFiles(distDir: project.distDir, id: 'header.en-US.video', storefront: 'en-US', video: true);
        final probe = const FfprobeProber().probe(video.file)!;
        expect(probe.duration, closeTo(12, 0.04));
        expect(probe.video!.frameRate, 30);
        expect(probe.video!.codec, 'h264');
        expect(probe.audioStreams, 0);
        expect(probe.video!.rotation, 0);
        expect(probe.container, 'mp4');

        final edl = CreativeEdl.load(video.edl);
        expect(edl.transitions.map((t) => '${t.type} ${t.between}'), ['dissolve player→hold', 'dissolve hold→player (loop)']);
        expect(edl.sources.where((s) => s.kind == 'recording').map((s) => s.detail['run']), ['20261008T100000Z', '20261008T110000Z']);
        expect(edl.media.map((m) => '${m.id}:${m.use}'), [
          'song.A.en-US:footage',
          'photo.A.en-US.2:footage',
          'photo.A.en-US.1:backdrop',
        ], reason: 'W\'s hold shows photo 2 (its `shows`), the backdrop is photo 1');
        expect(edl.primaryMedia, ['song.A.en-US'], reason: 'the poster frame (2 s) is in A\'s player');
        expect(edl.composition.scale, lessThan(1));
        expect(edl.measurements['loop_psnr'], greaterThanOrEqualTo(40));
        final universal = CreativeEdl.load(CreativeFiles(distDir: project.distDir, id: 'header.universal', storefront: null, video: false).edl);
        expect(universal.texts.map((t) => t.source), ['brand'], reason: 'a universal asset shows no phrase');

        // The manifest: every asset of the app, so ja first (on the same takes).
        await Process.run('cp', ['-R', p.join(project.buildDir, 'raw', 'en-US'), p.join(project.buildDir, 'raw', 'ja')]);
        for (final job in creativeJobs(project.creatives, project.app, storefronts: [project.app.storefront('ja')])) {
          await composer.render(job, texts: project.texts('ja'), distDir: project.distDir, slotId: 'iphone');
        }
        final all = creativeJobs(project.allCreatives, project.app, storefronts: project.app.storefronts);
        Future<Map<String, Object?>> build() => buildAssetsManifest(
          all,
          app: project.app,
          distDir: project.distDir,
          review: project.review(),
          contract: project.contract,
          generator: {'name': 'store_preview', 'version': '1.0.0'},
          now: () => '2026-10-08T12:00:00Z',
        );
        final manifest = await build();
        final entries = [for (final e in manifest['entries']! as List) (e as Map).cast<String, Object?>()];
        expect(entries, hasLength(7));
        final v = entries.firstWhere((e) => e['id'] == 'header.ja.video');
        expect(v['type'], 'header_video');
        expect(v['locale'], 'ja');
        expect((v['video'] as Map)['has_audio'], isFalse);
        expect((v['source'] as Map)['real_ui'], isFalse, reason: 'no human review yet');
        expect((v['source'] as Map)['script'], 'A+W');
        // Per field: the primary scene's item, then the other scenes', the
        // backdrop last (ADR-0014); the EDL lists all three.
        expect(v['authorization'], {'interaction_id': 'song-ja', 'mv_id': null, 'generation_id': 'photo2-ja', 'license_provider': 'test'});
        final aRecording = CreativeEdl.load(
          CreativeFiles(distDir: project.distDir, id: 'header.ja.video', storefront: 'ja', video: true).edl,
        ).sources.firstWhere((s) => s.detail['run'] == '20261008T100000Z');
        expect(v['derived_from'], aRecording.sha256, reason: 'the poster frame\'s scene was cut from A\'s run');
        final search = entries.firstWhere((e) => e['id'] == 'search.ja');
        expect(search['authorization'], {
          'interaction_id': null,
          'mv_id': null,
          'generation_id': 'photo2-ja',
          'license_provider': 'test',
        }, reason: 'the frame (W) shows photo 2, which is also the backdrop');

        // A shown item that is also the backdrop keeps both uses in the EDL.
        final searchEdl = CreativeEdl.load(CreativeFiles(distDir: project.distDir, id: 'search.ja', storefront: 'ja', video: false).edl);
        expect(searchEdl.media.map((m) => '${m.id}:${m.use}'), ['photo.A.ja.2:footage', 'photo.A.ja.2:backdrop']);
        final u = entries.firstWhere((e) => e['id'] == 'header.universal');
        expect(u['locale'], isNull);
        expect(u['placement_intents'], [
          {'placement': 'product_page_header', 'target': 'app_store_version'},
          {'placement': 'app_store_search_results', 'target': 'app_store_version'},
        ]);
        final path = p.join(project.distDir, assetsManifestName);
        File(path).writeAsStringSync(jsonEncode(manifest));
        expect(checkAssetsManifest(path, contract: project.contract), isEmpty);

        final pipeline = Pipeline(project: project, storefronts: project.app.storefronts, slots: project.app.slots.values.toList(), say: (_) {});
        expect(pipeline.checkManifest(), isTrue);
        void rejectMutation(void Function(Map<String, Object?>) mutate) {
          final changed = (jsonDecode(jsonEncode(manifest)) as Map).cast<String, Object?>();
          mutate(changed);
          File(path).writeAsStringSync(jsonEncode(changed));
          expect(pipeline.checkManifest(), isFalse);
          File(path).writeAsStringSync(jsonEncode(manifest));
        }

        rejectMutation((m) => (m['app'] as Map)['bundle_id'] = 'org.example.another');
        rejectMutation((m) => ((m['entries'] as List).first as Map)['id'] = 'undefined.asset');
        rejectMutation((m) => (m['entries'] as List).removeLast());
        rejectMutation((m) => (((m['entries'] as List).first as Map)['source'] as Map)['real_ui'] = true);

        // A person's review carries into real_ui.
        final def = project.allCreatives['page']!;
        final slot = def.slots[1];
        project.review().record(
          CreativeReview(
            asset: 'header.{storefront}.video',
            realUi: true,
            reviewer: 'Test Reviewer',
            date: '2026-10-08',
            basis: reviewBasis(slot, slot.assets[1]),
            artifacts: {
              for (final sf in project.app.storefronts)
                'header.${sf.id}.video': renderedReviewBasis(
                  CreativeFiles(distDir: project.distDir, id: 'header.${sf.id}.video', storefront: sf.id, video: true),
                ),
            },
          ),
        );
        final reviewed = await build();
        final rv = (reviewed['entries']! as List).cast<Map>().firstWhere((e) => e['id'] == 'header.ja.video');
        expect((rv['source'] as Map)['real_ui'], isTrue);

        // A file changed after the manifest: refused, never patched.
        File(p.join(project.distDir, 'creative', 'ja', 'header.ja.png')).writeAsBytesSync([1, 2, 3], mode: FileMode.append);
        expect(
          checkAssetsManifest(path, contract: project.contract),
          contains(contains('header.ja: creative/ja/header.ja.png changed after the manifest was written')),
        );
      },
      skip: tools ? false : 'needs macOS with Xcode and ffmpeg',
      timeout: const Timeout(Duration(minutes: 8)),
    );
  });

  group('served localizations (ADR-0017)', () {
    late FixtureRepo repo;
    setUp(() {
      repo = creativeRepo(pkg);
      final app = File(repo.path('store_preview/demo/app.yaml'));
      app.writeAsStringSync(app.readAsStringSync().replaceFirst('vars: {region: US}}', 'vars: {region: US}, serves: [en-GB, en-AU]}'));
    });
    tearDown(() => repo.delete());

    test(
      'the manifest lists the storefront\'s assets again under each served locale, rendered once',
      () async {
        await synthesizeCreativeTakes(repo);
        await Process.run('cp', ['-R', p.join(repo.root, 'build', 'store_preview', 'demo', 'raw', 'en-US'), p.join(repo.root, 'build', 'store_preview', 'demo', 'raw', 'ja')]);
        final project = Project.load(root: repo.root, appId: 'demo', packageRoot: pkg);
        final texts = project.textsFromArb();
        project.checkConfig(texts: texts).throwIfAny('config');
        writeCaptionFiles(project.app.captionsDir, texts);
        final native = await NativeTools.ensure(runner, packageRoot: pkg, binDir: p.join(pkg, '.dart_tool', 'store_preview_test_bin'));
        final composer = CreativeComposer(
          runner: runner,
          app: project.app,
          scripts: project.allScripts,
          manifest: project.manifest(),
          defaults: project.creativeDefaults,
          templates: project.templates,
          tools: native,
          root: repo.root,
          buildDir: project.buildDir,
        );
        final all = creativeJobs(project.allCreatives, project.app, storefronts: project.app.storefronts);
        expect(all.map((j) => j.storefront).toSet(), {null, 'en-US', 'ja'}, reason: 'no job for a served locale');
        for (final job in all) {
          await composer.render(job, texts: project.texts(job.storefront ?? 'en-US'), distDir: project.distDir, slotId: 'iphone');
        }
        expect(Directory(p.join(project.distDir, 'creative', 'en-GB')).existsSync(), isFalse);

        final manifest = await buildAssetsManifest(
          all,
          app: project.app,
          distDir: project.distDir,
          review: project.review(),
          contract: project.contract,
          generator: {'name': 'store_preview', 'version': '1.0.0'},
          now: () => '2026-10-16T12:00:00Z',
        );
        final entries = {for (final e in manifest['entries']! as List) (e as Map)['id'] as String: e.cast<String, Object?>()};
        expect(entries.length, 7 + 2 * 3, reason: 'the three en-US assets again for en-GB and en-AU');
        final parent = entries['header.en-US']!;
        final alias = entries['header.en-GB']!;
        expect(alias['locale'], 'en-GB');
        expect(alias['derived_from'], 'header.en-US');
        for (final key in ['type', 'file', 'sha256', 'bytes', 'pixels', 'placement_intents', 'source', 'authorization', 'experiment_tags']) {
          expect(alias[key], parent[key], reason: key);
        }
        expect(entries['header.en-AU.video']!['video'], entries['header.en-US.video']!['video']);
        expect(entries.keys.where((id) => id.contains('universal')), ['header.universal'], reason: 'a universal asset has no alias');

        final path = p.join(project.distDir, assetsManifestName);
        File(path).writeAsStringSync(jsonEncode(manifest));
        expect(checkAssetsManifest(path, contract: project.contract), isEmpty);
        final pipeline = Pipeline(project: project, storefronts: project.app.storefronts, slots: project.app.slots.values.toList(), say: (_) {});
        expect(pipeline.checkManifest(), isTrue);
        void rejects(String id, void Function(Map<String, Object?>) mutate) {
          final changed = (jsonDecode(jsonEncode(manifest)) as Map).cast<String, Object?>();
          mutate(((changed['entries'] as List).cast<Map<String, Object?>>()).firstWhere((e) => e['id'] == id));
          File(path).writeAsStringSync(jsonEncode(changed));
          expect(pipeline.checkManifest(), isFalse, reason: id);
          File(path).writeAsStringSync(jsonEncode(manifest));
        }

        rejects('header.en-GB', (e) => e['derived_from'] = parent['derived_from']);
        rejects('header.en-GB', (e) => e['locale'] = 'en-US');
        rejects('search.en-AU', (e) => e['file'] = entries['search.ja']!['file']);
      },
      skip: tools ? false : 'needs macOS with Xcode and ffmpeg',
      timeout: const Timeout(Duration(minutes: 8)),
    );
  });

  group('the spec layer on real files', () {
    late Directory dir;
    late CreativeDefaults defaults;
    setUp(() {
      dir = Directory.systemTemp.createTempSync('creative_spec');
      defaults = loadCreativeDefaults(
        Directory.current.path.endsWith('store_preview') ? Directory.current.path : p.join(Directory.current.path, 'packages', 'store_preview'),
      );
    });
    tearDown(() => dir.deleteSync(recursive: true));

    Future<List<String>> check(String file, String specId, {required bool video, double? duration}) async {
      final spec = defaults.specs[specId]!;
      final result = await checkCreativeFile(
        file,
        spec: spec,
        rule: spec.rule(video ? 'video' : 'image')!,
        video: video,
        duration: duration,
        maxBytes: defaults.maxBytes,
        videoCodecs: defaults.videoCodecs,
        runner: runner,
      );
      return result.problems.items;
    }

    Future<String> image(String name, String size, {String pixFmt = 'rgb24', String? codec}) async {
      final out = p.join(dir.path, name);
      await ff([
        '-f',
        'lavfi',
        '-i',
        'testsrc=s=$size:d=1',
        '-frames:v',
        '1',
        '-pix_fmt',
        pixFmt,
        if (codec != null) ...['-c:v', codec, '-f', 'image2'],
        out,
      ]);
      return out;
    }

    Future<String> clip(String name, String size, {double seconds = 12, int fps = 30, bool audio = false, int? rotate}) async {
      final out = p.join(dir.path, name);
      await ff([
        '-f', 'lavfi', '-i', 'testsrc=s=$size:r=$fps:d=$seconds', //
        if (audio) ...['-f', 'lavfi', '-i', 'sine=d=$seconds'],
        '-c:v', 'libx264', '-preset', 'ultrafast', '-pix_fmt', 'yuv420p', if (audio) ...['-c:a', 'aac'] else '-an',
        '-t', '$seconds', rotate == null ? out : '$out.src.mp4',
      ]);
      // Rotation is display-matrix side data: set on the input, carried by a copy.
      if (rotate != null) await ff(['-display_rotation:v:0', '$rotate', '-i', '$out.src.mp4', '-c', 'copy', out]);
      return out;
    }

    test('exact sizes match pixel for pixel, not by ratio', () async {
      expect(await check(await image('a.png', '3840x1646'), 'header_21x9', video: false), isEmpty, reason: '3840/1646 ≠ 21/9, still Apple\'s size');
      expect(await check(await image('b.png', '3840x1647'), 'header_21x9', video: false), contains(contains('3840×1647 is not 3840×1646')));
      expect(await check(await image('c.png', '3840x1645'), 'header_21x9', video: false), isNotEmpty);
      expect(await check(await image('d.png', '5244x2950'), 'universal_16x9', video: false), isEmpty);
    }, skip: tools ? false : 'needs ffmpeg');

    test('a range holds its ratio exactly, at both ends and between', () async {
      for (final ok in ['1920x1280', '2400x1600', '3840x2560']) {
        expect(await check(await image('$ok.png', ok), 'search_3x2', video: false), isEmpty, reason: ok);
      }
      for (final bad in ['2401x1600', '1918x1280', '3843x2562']) {
        expect(await check(await image('$bad.png', bad), 'search_3x2', video: false), isNotEmpty, reason: bad);
      }
    }, skip: tools ? false : 'needs ffmpeg');

    test('alpha, a disguised format and a wrong extension are refused', () async {
      expect(await check(await image('alpha.png', '3840x1646', pixFmt: 'rgba'), 'header_21x9', video: false), contains(contains('carries alpha')));
      final jpeg = await image('jpeg.png', '3840x1646', pixFmt: 'yuvj420p', codec: 'mjpeg');
      expect(await check(jpeg, 'header_21x9', video: false), contains(contains('extension and format disagree')));
      final realJpeg = await image('real.jpg', '2400x1600', pixFmt: 'yuvj420p', codec: 'mjpeg');
      expect(await check(realJpeg, 'search_3x2', video: false), isEmpty, reason: 'a JPEG is fine for search results');
      expect(
        await check(await image('header.jpg', '3840x1646', pixFmt: 'yuvj420p', codec: 'mjpeg'), 'header_21x9', video: false),
        contains(contains('.jpg is not accepted')),
        reason: 'RefData takes PNG only for the 21:9 header',
      );
    }, skip: tools ? false : 'needs ffmpeg');

    test(
      'a video: muted, exactly 30 or 60 fps, within its length, no rotation, decodable',
      () async {
        expect(await check(await clip('ok.mp4', '3840x1646'), 'header_21x9', video: true), isEmpty);
        expect(await check(await clip('sixty.mp4', '2880x1920', seconds: 15, fps: 60), 'search_3x2', video: true), isEmpty);
        expect(await check(await clip('audio.mp4', '3840x1646', audio: true), 'header_21x9', video: true), contains(contains('audio stream')));
        expect(await check(await clip('pal.mp4', '3840x1646', fps: 25), 'header_21x9', video: true), contains(contains('is not exactly 30 or 60')));
        expect(await check(await clip('short.mp4', '3840x1646', seconds: 9.9), 'header_21x9', video: true), contains(contains('outside 10.0–30.0 s')));
        expect(await check(await clip('long.mp4', '3840x1646', seconds: 30.5), 'header_21x9', video: true), contains(contains('outside 10.0–30.0 s')));
        expect(await check(await clip('edge.mp4', '2880x1920', seconds: 15), 'search_3x2', video: true), isEmpty, reason: 'exactly the minimum');
        expect(await check(await clip('ten.mp4', '3840x1646', seconds: 10), 'header_21x9', video: true), isEmpty, reason: 'exactly the header\'s minimum');
        expect(await check(await clip('thirty.mp4', '3840x1646', seconds: 30), 'header_21x9', video: true), isEmpty, reason: 'exactly the maximum');
        expect(await check(await clip('sixtyh.mp4', '3840x1646', fps: 60), 'header_21x9', video: true), isEmpty);
        final ntsc = p.join(dir.path, 'ntsc.mp4');
        await ff(['-f', 'lavfi', '-i', 'testsrc=s=3840x1646:r=30000/1001:d=12', '-c:v', 'libx264', '-preset', 'ultrafast', '-pix_fmt', 'yuv420p', '-an', ntsc]);
        expect(await check(ntsc, 'header_21x9', video: true), contains(contains('is not exactly 30 or 60')), reason: '29.97 is not 30');
        expect(await check(await clip('range.mp4', '1920x1282', seconds: 15), 'search_3x2', video: true), contains(contains('1920×1282 is not 1920×1280')));
        expect(await check(await clip('short15.mp4', '2880x1920', seconds: 14.9), 'search_3x2', video: true), contains(contains('outside 15.0–30.0 s')));
        expect(await check(await clip('rot.mp4', '3840x1646', rotate: 90), 'header_21x9', video: true), contains(contains('rotation metadata')));
        final cut = await clip('cut.mp4', '3840x1646');
        final bytes = File(cut).readAsBytesSync();
        File(p.join(dir.path, 'truncated.mp4')).writeAsBytesSync(bytes.sublist(0, bytes.length * 2 ~/ 3));
        expect(await check(p.join(dir.path, 'truncated.mp4'), 'header_21x9', video: true), isNotEmpty);
        final mov = p.join(dir.path, 'container.mp4');
        await ff(['-i', await clip('src.mp4', '3840x1646'), '-c', 'copy', '-f', 'mov', mov]);
        expect(await check(mov, 'header_21x9', video: true), contains(contains('extension and format disagree')));
      },
      skip: tools ? false : 'needs ffmpeg',
      timeout: const Timeout(Duration(minutes: 4)),
    );
  });
}
