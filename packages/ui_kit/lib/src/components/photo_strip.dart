import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';

/// Picked photos with remove buttons and an "n / 10" counter (docs/ui P04).
class PhotoStrip extends StatelessWidget {
  const PhotoStrip({
    super.key,
    required this.images,
    required this.counter,
    required this.onRemove,
    required this.removeLabel,
    this.onAdd,
    this.addLabel,
  });

  final List<ImageProvider> images;
  final String counter;
  final ValueChanged<int> onRemove;
  final String removeLabel;

  /// Adds more photos; null when the cap is reached.
  final VoidCallback? onAdd;
  final String? addLabel;

  /// Thumbnail width ÷ height (P04).
  static const double thumbAspect = 0.72;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    const height = SongletSize.coverLarge * 0.5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Text(
            counter,
            style: SongletType.subhead.copyWith(color: c.inkSecondary),
          ),
        ),
        const SizedBox(height: SongletSpace.x3),
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length + (onAdd == null ? 0 : 1),
            separatorBuilder: (_, _) => const SizedBox(width: SongletSpace.x3),
            itemBuilder: (context, i) {
              if (i == images.length) {
                return Semantics(
                  container: true,
                  button: true,
                  label: addLabel,
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: onAdd,
                    borderRadius: SongletRadius.controlAll,
                    child: Container(
                      width: height * thumbAspect,
                      decoration: BoxDecoration(
                        color: c.surfaceMuted,
                        borderRadius: SongletRadius.controlAll,
                        border: Border.all(color: c.hairline),
                      ),
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        color: c.accent,
                        size: SongletSize.iconXl,
                      ),
                    ),
                  ),
                );
              }
              return SizedBox(
                width: height * thumbAspect,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: SongletRadius.controlAll,
                      child: Image(
                        image: images[i],
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                      ),
                    ),
                    PositionedDirectional(
                      top: SongletSpace.x1,
                      end: SongletSpace.x1,
                      child: Material(
                        color: c.accentSoft,
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: removeLabel,
                          visualDensity: VisualDensity.compact,
                          onPressed: () => onRemove(i),
                          icon: Icon(
                            Icons.close_rounded,
                            size: SongletSize.iconSm,
                            color: c.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
