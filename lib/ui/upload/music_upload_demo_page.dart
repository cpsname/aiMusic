import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:infra_core/infra_core.dart';
import 'package:media_kit/media_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/music_external_links.dart';
import '../common/music_localized_formats.dart';
import '../common/music_messages.dart';

/// A picked file handed to the upload flow.
typedef MusicUploadPick = ({List<int> bytes, String filename, String mimeType});

/// Reference consumer for media_kit's two-stage presigned direct upload
/// (`hash → sign → [dedup] → PUT to R2 → finalize`). The library ships no UI or
/// picker by design; this page is the wiring a new product copies: progress
/// phases, cancellation, dedup short-circuit, and failures through the app's
/// standard message surface.
class MusicUploadDemoPage extends ConsumerStatefulWidget {
  const MusicUploadDemoPage({super.key, this.pickFile});

  /// Test seam replacing the native gallery picker; null → real [ImagePicker].
  final Future<MusicUploadPick?> Function()? pickFile;

  @override
  ConsumerState<MusicUploadDemoPage> createState() => _UploadDemoPageState();
}

class _UploadDemoPageState extends ConsumerState<MusicUploadDemoPage> {
  UploadProgress? _progress;
  UploadResult? _result;
  UploadCancellation? _cancellation;

  bool get _busy => _cancellation != null;

  static Future<MusicUploadPick?> _pickFromGallery() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return (
      bytes: bytes,
      filename: file.name,
      mimeType: file.mimeType ?? _mimeFromName(file.name),
    );
  }

  /// Extension fallback for platforms where the picker reports no MIME type.
  static String _mimeFromName(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      _ => 'image/jpeg',
    };
  }

  Future<void> _pickAndUpload() async {
    final l10n = AppLocalizations.of(context);
    final messages = ref.read(messageControllerProvider);
    final errors = ref.read(errorHandlerProvider);
    final service = ref.read(uploadServiceProvider);
    final maxMb = ref.read(uploadPolicyProvider).maxBytes ~/ (1024 * 1024);

    final picked = await (widget.pickFile ?? _pickFromGallery)();
    if (picked == null || !mounted) return;

    final cancellation = UploadCancellation();
    setState(() {
      _cancellation = cancellation;
      _result = null;
      _progress = const UploadProgress(phase: UploadPhase.hashing);
    });
    try {
      final result = await service.upload(
        UploadInput(
          bytes: picked.bytes,
          filename: picked.filename,
          mimeType: picked.mimeType,
          contentKind: UploadContentKind.image,
        ),
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress);
        },
        cancellation: cancellation,
      );
      if (mounted) setState(() => _result = result);
    } on UploadCancelledException {
      // User-initiated cancel: reset quietly, no error surface.
    } on UploadPolicyException catch (error) {
      messages.error(switch (error.violation) {
        UploadPolicyViolation.sizeExceeded => l10n.uploadTooLarge(maxMb),
        UploadPolicyViolation.unsupportedType => l10n.uploadUnsupportedType,
        UploadPolicyViolation.invalidHash => l10n.uploadFailed,
      });
    } on Object catch (error, stackTrace) {
      messages.show(
        failureMessage(
          l10n,
          errors.handle(error, stackTrace),
          fallback: l10n.uploadFailed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _cancellation = null;
          _progress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        StudioTokens.spaceLg,
        StudioTokens.spaceXl,
        StudioTokens.spaceLg,
        StudioTokens.space2xl,
      ),
      children: [
        GradientText(l10n.uploadTitle, style: theme.textTheme.displayLarge),
        const SizedBox(height: StudioTokens.spaceSm),
        Text(l10n.uploadSubtitle, style: theme.textTheme.bodyLarge),
        const SizedBox(height: StudioTokens.spaceXl),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_busy)
                _ProgressView(
                  progress: _progress,
                  onCancel: () => _cancellation?.cancel(),
                )
              else if (_result != null)
                _ResultView(result: _result!),
              if (_busy || _result != null)
                const SizedBox(height: StudioTokens.spaceLg),
              ObsButton(
                label: _result == null ? l10n.uploadPick : l10n.uploadAgain,
                icon: Icons.cloud_upload_outlined,
                loading: _busy,
                onPressed: _busy ? null : _pickAndUpload,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressView extends StatelessWidget {
  const _ProgressView({required this.progress, required this.onCancel});

  final UploadProgress? progress;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final phase = progress?.phase ?? UploadPhase.hashing;
    final uploading = phase == UploadPhase.uploading;
    final fraction = progress?.fraction ?? 0;
    final label = switch (phase) {
      UploadPhase.hashing => l10n.uploadPhaseHashing,
      UploadPhase.signing => l10n.uploadPhaseSigning,
      UploadPhase.uploading => l10n.uploadPhaseUploading(
        progressPercent(fraction, l10n.localeName),
      ),
      UploadPhase.finalizing || UploadPhase.done => l10n.uploadPhaseFinalizing,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const SizedBox(height: StudioTokens.spaceSm),
        LinearProgressIndicator(
          // Determinate only while bytes stream to R2; the other phases are
          // short round-trips with no meaningful fraction.
          value: uploading && fraction > 0 ? fraction : null,
          minHeight: 4,
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: onCancel,
            child: Text(l10n.commonCancel),
          ),
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result});

  final UploadResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: StudioTokens.successColor),
            const SizedBox(width: StudioTokens.spaceSm),
            Expanded(
              child: Text(l10n.uploadDone, style: theme.textTheme.titleMedium),
            ),
          ],
        ),
        if (result.dedupHit) ...[
          const SizedBox(height: StudioTokens.spaceXs),
          Text(
            l10n.uploadDedup,
            style: theme.textTheme.labelMedium?.copyWith(
              color: StudioTokens.auroraTeal,
            ),
          ),
        ],
        const SizedBox(height: StudioTokens.spaceXs),
        Text(
          result.bid,
          style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (result.url.isNotEmpty)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => openExternalUrl(
                context,
                result.url,
                errorMessage: l10n.commonLinkError,
              ),
              child: Text(l10n.uploadOpenLink),
            ),
          ),
      ],
    );
  }
}
