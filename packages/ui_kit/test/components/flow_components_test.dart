import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

import '../support/harness.dart';

const _labels = (play: 'Play', pause: 'Pause', previous: 'Previous section', next: 'Next section', shuffle: 'Shuffle', repeat: 'Repeat');

final _lines = <LyricLineView>[
  (text: 'Happy birthday, Alex', time: '0:00', breakBefore: false),
  (text: "Here's a little song for you", time: '0:05', breakBefore: false),
  (text: 'May your days be brighter', time: '0:12', breakBefore: false),
  (text: 'And your dreams come true', time: '0:18', breakBefore: false),
];

void main() {
  goldenSheet('generating', () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const QueueBanner(
            title: 'Lots of songs being made right now.',
            subtitle: 'Yours is queued.',
            positionLabel: 'Position',
            position: '3',
            waitValue: '≈ 2 min',
            waitLabel: 'estimated wait',
          ),
          gap(),
          const Center(child: PulsingMark(diameter: 96)),
          const ProgressMeter(value: 0.6, percentLabel: '60%'),
          gap(),
          const MetaLine(parts: ['Indie Pop', 'English', 'Birthday']),
          gap(),
          const GlimpseCard(
            title: 'A glimpse of your song',
            lines: ["Here's to you, Alex", 'Brighter days ahead', 'Same kind heart', 'Different adventures', 'Coffee in the morning light'],
          ),
          gap(),
          const GlimpseCard(title: 'A glimpse of your song', lines: []),
        ],
      ), height: 1250);

  goldenSheet('player', () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: SizedBox(width: 220, child: CoverArt(seed: 'work-1', framed: true, badgeLabel: 'AI generated')),
          ),
          gap(),
          WaveformScrubber(
            bars: testBars,
            progress: 0.4,
            elapsedLabel: '0:12',
            totalLabel: '0:30',
            semanticsLabel: 'Position',
            onSeek: (_) {},
          ),
          gap(),
          WaveformScrubber(
            bars: testBars,
            progress: 0.38,
            elapsedLabel: '0:48',
            totalLabel: '2:07',
            semanticsLabel: 'Position',
            playhead: PlayheadStyle.line,
            onSeek: (_) {},
          ),
          const SectionTrack(
            sections: [
              (label: 'Intro', start: 0, end: 0.1),
              (label: 'Verse', start: 0.1, end: 0.35),
              (label: 'Chorus', start: 0.35, end: 0.6),
              (label: 'Bridge', start: 0.6, end: 0.85),
              (label: 'Outro', start: 0.85, end: 1),
            ],
            current: 1,
          ),
          gap(),
          PlaybackControls(
            playing: true,
            onPlayPause: () {},
            labels: _labels,
            onPrevious: () {},
            onNext: () {},
            onShuffle: () {},
            onRepeat: () {},
            repeat: true,
          ),
          gap(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LabeledIconToggle(icon: Icons.repeat_rounded, label: 'Loop', selected: false, onPressed: () {}),
              const SizedBox(width: SongletSpace.x8),
              PlayButton(playing: false, onPressed: () {}, playLabel: 'Play', pauseLabel: 'Pause'),
            ],
          ),
          gap(),
          SyncedLyricsView(lines: _lines, active: 2),
          gap(),
          Row(
            children: [
              for (final (icon, label) in [
                (Icons.download_rounded, 'Download'),
                (Icons.ios_share_rounded, 'Share'),
                (Icons.description_outlined, 'License'),
                (Icons.autorenew_rounded, 'Regenerate'),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(SongletSpace.x1),
                    child: ActionTile(icon: icon, label: label, onPressed: () {}, locked: label == 'Download'),
                  ),
                ),
            ],
          ),
        ],
      ), height: 1400);

  goldenSheet('share_card', () => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ShareCardCanvas(
              brand: 'Songlet',
              tagline: 'A song for someone',
              title: 'For Alex',
              lines: const ['Happy birthday, Alex', 'May your days be brighter', 'And your dreams come true'],
              badgeLabel: 'AI generated',
              bars: testBars,
            ),
          ),
          const SizedBox(width: SongletSpace.x3),
          Column(
            children: [
              for (final p in ArtPalette.values)
                PaletteSwatch(palette: p, selected: p == ArtPalette.terracotta, onTap: () {}, label: p.name),
              gap(),
              LayoutOptionTile(icon: Icons.landscape_outlined, label: 'Scene', selected: true, onTap: () {}),
              gap(),
              LayoutOptionTile(icon: Icons.notes_rounded, label: 'Text', selected: false, onTap: () {}),
            ],
          ),
        ],
      ), height: 900);

  goldenSheet('share_card_text', () => Column(
        children: [
          SizedBox(
            width: 220,
            child: ShareCardCanvas(
              brand: 'Songlet',
              tagline: 'A song for someone',
              title: 'For Alex',
              lines: const ['Happy birthday, Alex', 'May your days be brighter'],
              badgeLabel: 'AI generated',
              bars: testBars,
              palette: ArtPalette.navy,
              layout: ShareCardLayout.text,
            ),
          ),
          gap(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ShareTargetButton(icon: Icons.ios_share_rounded, label: 'Share', onPressed: () {}, primary: true),
              ShareTargetButton(icon: Icons.download_rounded, label: 'Save video', onPressed: () {}),
              ShareTargetButton(icon: Icons.copy_rounded, label: 'Copy lyrics', onPressed: () {}, busy: true),
            ],
          ),
        ],
      ));

  group('behaviour', () {
    testWidgets('QueueBanner leaves the position out when there is none', (tester) async {
      await pumpComponent(
        tester,
        const QueueBanner(
          title: 'Lots of songs being made right now.',
          subtitle: 'Yours is queued.',
          positionLabel: 'Position',
          waitValue: '≈ 2 min',
          waitLabel: 'estimated wait',
        ),
      );
      expect(find.text('Position'), findsNothing);
      expect(find.text('≈ 2 min'), findsOneWidget);
    });

    testWidgets('WaveformScrubber seeks to the tapped fraction (mirrored in RTL)', (tester) async {
      for (final direction in TextDirection.values) {
        double? seek;
        await pumpComponent(
          tester,
          SizedBox(
            width: 300,
            child: WaveformScrubber(
              bars: testBars,
              progress: 0,
              elapsedLabel: '0:00',
              totalLabel: '0:30',
              semanticsLabel: 'Position',
              onSeek: (v) => seek = v,
            ),
          ),
          direction: direction,
        );
        final box = tester.getRect(find.byType(WaveformView));
        await tester.tapAt(Offset(box.left + box.width * 0.25, box.center.dy));
        await tester.pump();
        expect(seek, closeTo(direction == TextDirection.ltr ? 0.25 : 0.75, 0.02), reason: '$direction');
      }
    });

    testWidgets('SectionTrack jumps to a tapped section', (tester) async {
      int? picked;
      await pumpComponent(
        tester,
        SectionTrack(
          sections: const [(label: 'Verse', start: 0, end: 0.5), (label: 'Chorus', start: 0.5, end: 1)],
          current: 0,
          onSelect: (i) => picked = i,
        ),
      );
      await tester.tap(find.text('Chorus'));
      expect(picked, 1);
    });

    testWidgets('SyncedLyricsView reports the tapped line and marks the active one', (tester) async {
      int? tapped;
      await pumpComponent(tester, SyncedLyricsView(lines: _lines, active: 1, onTapLine: (i) => tapped = i));
      await tester.tap(find.text('And your dreams come true'));
      expect(tapped, 3);
      final active = tester.widget<Text>(find.text("Here's a little song for you"));
      expect(active.style!.color, SongletColors.light.accent);
    });

    testWidgets('PlayButton announces play or pause', (tester) async {
      await pumpComponent(tester, PlayButton(playing: true, onPressed: () {}, playLabel: 'Play', pauseLabel: 'Pause'));
      expect(find.bySemanticsLabel('Pause'), findsOneWidget);
    });

    testWidgets('the share card always carries the locked AI badge (PRD D8)', (tester) async {
      await pumpComponent(
        tester,
        ShareCardCanvas(
          brand: 'Songlet',
          tagline: 't',
          title: 'For Alex',
          lines: const [],
          badgeLabel: 'AI generated',
          bars: testBars,
          layout: ShareCardLayout.text,
        ),
      );
      final badge = tester.widget<AiGeneratedBadge>(find.byType(AiGeneratedBadge));
      expect(badge.locked, isTrue);
      expect(find.bySemanticsLabel('AI generated'), findsOneWidget);
    });

    testWidgets('GlimpseCard pages lines four at a time', (tester) async {
      await pumpComponent(
        tester,
        const GlimpseCard(title: 'Glimpse', lines: ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i']),
      );
      expect(find.byType(PageDots), findsOneWidget);
      final dots = tester.widget<PageDots>(find.byType(PageDots));
      expect(dots.count, 3);
    });
  });
}
