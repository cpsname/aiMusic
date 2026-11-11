import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';
import 'level_meter.dart';

/// The composer's dictation state (docs/ui P03a): recording indicator,
/// elapsed time, live level meter, the transcript so far, the on-device
/// badge and what to do with the words ([actions]).
class VoiceCapturePanel extends StatelessWidget {
  const VoiceCapturePanel({
    super.key,
    required this.statusLabel,
    required this.elapsed,
    required this.levels,
    required this.transcript,
    required this.placeholder,
    required this.onDeviceLabel,
    required this.actions,
    this.recording = true,
    this.trailing,
  });

  final String statusLabel;
  final String elapsed;
  final List<double> levels;
  final String transcript;

  /// Shown until the first words arrive.
  final String placeholder;
  final String onDeviceLabel;
  final bool recording;

  /// Where the words can go ("Use this text"): one fills the width, several
  /// share a row. Disabled while there is no transcript.
  final List<VoiceCaptureAction> actions;

  /// A control at the end of the status row (stop / cancel).
  final Widget? trailing;

  /// Most transcript lines shown before it ellipsizes.
  static const int transcriptMaxLines = 4;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final hasText = transcript.trim().isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: SongletSize.iconXl,
              height: SongletSize.iconXl,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.accentSoft,
                shape: BoxShape.circle,
              ),
              child: Container(
                width: SongletSize.iconSm,
                height: SongletSize.iconSm,
                decoration: BoxDecoration(
                  color: recording ? c.accent : c.inkTertiary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: SongletSpace.x2),
            Expanded(
              child: Text(
                statusLabel,
                style: SongletType.callout.copyWith(
                  color: recording ? c.accent : c.inkSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              elapsed,
              style: SongletType.callout.copyWith(
                color: c.inkSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: SongletSpace.x2),
              trailing!,
            ],
          ],
        ),
        const SizedBox(height: SongletSpace.x3),
        ExcludeSemantics(
          child: LevelMeter(levels: levels, color: c.accent),
        ),
        const SizedBox(height: SongletSpace.x3),
        Semantics(
          liveRegion: true,
          child: Text(
            hasText ? '“${transcript.trim()}”' : placeholder,
            textAlign: TextAlign.center,
            maxLines: transcriptMaxLines,
            overflow: TextOverflow.ellipsis,
            style: (hasText ? SongletType.title3 : SongletType.callout)
                .copyWith(color: hasText ? c.ink : c.inkSecondary),
          ),
        ),
        const SizedBox(height: SongletSpace.x3),
        Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: SongletSpace.x3,
            vertical: SongletSpace.x1,
          ),
          decoration: BoxDecoration(
            color: c.surfaceMuted,
            borderRadius: SongletRadius.pillAll,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.graphic_eq_rounded,
                size: SongletSize.iconSm,
                color: c.inkSecondary,
              ),
              const SizedBox(width: SongletSpace.x1),
              Flexible(
                child: Text(
                  onDeviceLabel,
                  style: SongletType.footnote.copyWith(color: c.inkSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: SongletSpace.x4),
        Row(
          children: [
            for (final (i, action) in actions.indexed) ...[
              if (i > 0) const SizedBox(width: SongletSpace.x3),
              Expanded(
                child: _UseButton(
                  icon: action.icon,
                  label: action.label,
                  onPressed: hasText ? action.onUse : null,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// One thing to do with a transcript (see [VoiceCapturePanel.actions]).
@immutable
class VoiceCaptureAction {
  const VoiceCaptureAction({
    required this.icon,
    required this.label,
    required this.onUse,
  });

  final IconData icon;
  final String label;
  final VoidCallback onUse;
}

class _UseButton extends StatelessWidget {
  const _UseButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: SongletSize.iconMd),
      label: FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1)),
      style: OutlinedButton.styleFrom(
        foregroundColor: c.ink,
        disabledForegroundColor: c.inkTertiary,
        minimumSize: const Size.fromHeight(SongletSize.controlHeight),
        side: BorderSide(color: c.hairline),
        shape: const RoundedRectangleBorder(
          borderRadius: SongletRadius.controlAll,
        ),
        textStyle: themedTextStyle(
          context,
          SongletType.subhead.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
