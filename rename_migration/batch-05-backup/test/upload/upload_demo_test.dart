import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:songlet/ui/common/messages.dart';
import 'package:songlet/ui/upload/upload_demo_page.dart';
import 'package:ui_kit/ui_kit.dart';

import '../support/pump_app.dart';

class _FakeUploadRepository implements UploadRepository {
  _FakeUploadRepository({this.dedup = false});

  final bool dedup;
  int signCalls = 0;
  int putCalls = 0;
  int finalizeCalls = 0;

  @override
  Future<UploadTicket> sign(
    UploadSpec spec, {
    UploadCancellation? cancellation,
  }) async {
    signCalls += 1;
    return UploadTicket(
      bid: 'bid-1',
      putUrl: dedup ? '' : 'https://r2.example/put',
      publicUrl: 'https://cdn.example/f.png',
      key: 'k',
      dedupHit: dedup,
    );
  }

  @override
  Future<void> putToR2({
    required String putUrl,
    required List<int> bytes,
    required String mimeType,
    void Function(int sent, int total)? onProgress,
    UploadCancellation? cancellation,
  }) async {
    putCalls += 1;
    onProgress?.call(bytes.length, bytes.length);
  }

  @override
  Future<UploadedAsset> finalize(
    String bid, {
    UploadCancellation? cancellation,
  }) async {
    finalizeCalls += 1;
    return UploadedAsset(
      bid: bid,
      url: 'https://cdn.example/f.png',
      fileName: 'f.png',
      fileSize: 3,
      mimeType: 'image/png',
      contentType: 'image',
      accessLevel: 'private',
      tags: const [],
      groupName: '',
      dedupHit: false,
    );
  }
}

Future<UploadPick?> _pick() async =>
    (bytes: <int>[1, 2, 3], filename: 'f.png', mimeType: 'image/png');

/// Wraps the page in a [MessageHost] bound to the app's controller, mirroring
/// how `StudioApp` mounts the overlay via `MaterialApp.builder`.
Widget _withMessages(Widget child) => Consumer(
  builder: (context, ref, _) => MessageHost(
    controller: ref.watch(messageControllerProvider),
    child: child,
  ),
);

void main() {
  testWidgets('happy path: sign → PUT → finalize, result rendered', (
    tester,
  ) async {
    final repo = _FakeUploadRepository();
    await pumpApp(
      tester,
      const UploadDemoPage(pickFile: _pick),
      overrides: [uploadRepositoryProvider.overrideWithValue(repo)],
    );

    await tester.tap(find.text('Choose image & upload'));
    await tester.pump();
    await tester.pump();

    expect(repo.signCalls, 1);
    expect(repo.putCalls, 1);
    expect(repo.finalizeCalls, 1);
    expect(find.text('Uploaded.'), findsOneWidget);
    expect(find.text('View file'), findsOneWidget);
    expect(find.text('Upload another'), findsOneWidget);
  });

  testWidgets('dedup hit: PUT and finalize are skipped, badge shown', (
    tester,
  ) async {
    final repo = _FakeUploadRepository(dedup: true);
    await pumpApp(
      tester,
      const UploadDemoPage(pickFile: _pick),
      overrides: [uploadRepositoryProvider.overrideWithValue(repo)],
    );

    await tester.tap(find.text('Choose image & upload'));
    await tester.pump();
    await tester.pump();

    expect(repo.signCalls, 1);
    expect(repo.putCalls, 0);
    expect(repo.finalizeCalls, 0);
    expect(find.textContaining('already existed'), findsOneWidget);
  });

  testWidgets('policy rejection fails fast with a precise, local message', (
    tester,
  ) async {
    final repo = _FakeUploadRepository();
    await pumpApp(
      tester,
      _withMessages(const UploadDemoPage(pickFile: _pick)),
      overrides: [
        uploadRepositoryProvider.overrideWithValue(repo),
        // 3-byte pick vs a 2-byte ceiling → sizeExceeded before any network.
        uploadPolicyProvider.overrideWithValue(const UploadPolicy(maxBytes: 2)),
      ],
    );

    await tester.tap(find.text('Choose image & upload'));
    await tester.pump();
    await tester.pump();

    expect(repo.signCalls, 0);
    expect(find.textContaining('too large'), findsOneWidget);
  });
}
