import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

/// Theme specimen: every colour role, the type scale, radii, elevation and the
/// themed Material controls, rendered from the tokens in both brightnesses.
class _Specimen extends StatelessWidget {
  const _Specimen();

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final e = SongletElevation.of(context);
    final roles = <(String, Color)>[
      ('canvas', c.canvas), ('surface', c.surface), ('muted', c.surfaceMuted),
      ('hairline', c.hairline), ('accent', c.accent), ('pressed', c.accentPressed),
      ('soft', c.accentSoft), ('ink', c.ink), ('ink 2', c.inkSecondary),
      ('ink 3', c.inkTertiary), ('success', c.success), ('warning', c.warning),
      ('danger', c.danger), ('badge', c.badgeFill),
    ];
    final type = <(String, TextStyle)>[
      ('Large Title', SongletType.largeTitle), ('Title 1', SongletType.title1),
      ('Title 2', SongletType.title2), ('Title 3', SongletType.title3),
      ('Headline', SongletType.headline), ('Body', SongletType.body),
      ('Callout', SongletType.callout), ('Subhead', SongletType.subhead),
      ('Footnote', SongletType.footnote), ('Caption', SongletType.caption),
      ('Caption 2', SongletType.caption2),
    ];
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SongletSpace.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: SongletSpace.x2,
              runSpacing: SongletSpace.x2,
              children: [
                for (final (name, color) in roles)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: SongletSize.thumbnail,
                        height: SongletSize.thumbnail,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: SongletRadius.thumbAll,
                          border: Border.all(color: c.hairline),
                        ),
                      ),
                      Text(name, style: SongletType.caption2.copyWith(color: c.inkSecondary)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: SongletSpace.x6),
            for (final (name, style) in type)
              Text(name, style: style.copyWith(color: c.ink)),
            const SizedBox(height: SongletSpace.x6),
            Row(
              children: [
                for (final (radius, shadow) in [
                  (SongletRadius.control, e.level1),
                  (SongletRadius.card, e.level2),
                  (SongletRadius.sheet, e.level3),
                ])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: SongletSpace.x4),
                    child: Container(
                      width: SongletSize.thumbnail + SongletSpace.x6,
                      height: SongletSize.thumbnail + SongletSpace.x6,
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(radius),
                        boxShadow: shadow,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: SongletSpace.x6),
            const TextField(decoration: InputDecoration(hintText: 'Recipient name')),
            const SizedBox(height: SongletSpace.x4),
            Row(
              children: [
                Switch(value: true, onChanged: (_) {}),
                Switch(value: false, onChanged: (_) {}),
                const SizedBox(width: SongletSpace.x4),
                const Expanded(child: LinearProgressIndicator(value: 0.6)),
              ],
            ),
            const SizedBox(height: SongletSpace.x4),
            ObsButton(label: 'Create preview', onPressed: () {}),
          ],
        ),
      ),
    );
  }
}

void main() {
  for (final (name, theme) in [
    ('light', AuraTheme.warm),
    ('dark', AuraTheme.warmDark),
  ]) {
    testWidgets('theme specimen · $name', (tester) async {
      tester.view.physicalSize = const Size(393 * 3, 852 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: const MotionPolicyOverride(reduceMotion: true, child: _Specimen()),
      ));
      await tester.pump();
      await expectLater(
        find.byType(_Specimen),
        matchesGoldenFile('goldens/theme_$name.png'),
      );
    });
  }
}
