import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

import '../support/harness.dart';

void main() {
  goldenSheet('paywall', () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              IconCaption(icon: Icons.music_note_outlined, label: 'More songs'),
              IconCaption(icon: Icons.diamond_outlined, label: 'Higher quality'),
              IconCaption(icon: Icons.verified_user_outlined, label: 'Commercial use'),
            ],
          ),
          const SizedBox(height: SongletSpace.x6),
          PlanCard(
            title: 'Pro Yearly',
            price: r'$59.99/yr',
            trial: '7-day free trial',
            ribbon: 'Best value',
            benefits: const ['40 full songs per month', '100 previews per month', 'MP3 download', 'Commercial license'],
            selected: true,
            onTap: () {},
          ),
          gap(),
          PlanCard(
            title: 'Premier Monthly',
            price: r'$24.99/mo',
            benefits: const ['120 full songs per month', 'MP3 + WAV download'],
            selected: false,
            onTap: () {},
          ),
          gap(),
          PackRow(
            title: 'Just need a few?',
            subtitle: '10-song pack',
            price: r'$4.99',
            note: 'never expires',
            selected: false,
            onTap: () {},
          ),
          gap(),
          LinkRow(links: [('Restore purchases', () {}), ('Terms', () {}), ('Privacy', () {})]),
        ],
      ), height: 1100);

  goldenSheet('download', () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StatusPill(label: 'Full song ready', icon: Icons.check_circle_rounded, large: true),
          gap(),
          const SectionHeader(title: 'Download audio', trailing: 'High quality'),
          DownloadRow(
            icon: Icons.audio_file_outlined,
            title: 'MP3 · 320 kbps',
            subtitle: 'Best for sharing and everyday listening',
            actionLabel: 'Download MP3',
            onPressed: () {},
          ),
          gap(),
          DownloadRow(
            icon: Icons.graphic_eq_rounded,
            title: 'WAV · 44.1 kHz (Premier)',
            subtitle: 'Highest quality for professional use',
            actionLabel: 'Download WAV',
            onPressed: () {},
            locked: true,
          ),
          gap(),
          const UsageGrid(items: [
            ('Personal use', 'Gifts, memories, non-commercial'),
            ('Ads & marketing', 'Promotions, paid campaigns'),
            ('Social media', 'TikTok, Instagram, YouTube, etc.'),
            ('Podcasts & videos', 'Monetized content'),
          ]),
          gap(),
          Row(
            children: [
              Expanded(child: CardButton(icon: Icons.folder_outlined, label: 'Save to Files', onPressed: () {})),
              const SizedBox(width: SongletSpace.x3),
              Expanded(child: CardButton(icon: Icons.music_note_rounded, label: 'Add to Music', onPressed: () {})),
            ],
          ),
          gap(),
          NoteBanner(
            icon: Icons.shield_outlined,
            message: 'This song contains a SynthID watermark to identify AI-generated content, even after downloading.',
            linkLabel: 'Learn more',
            onLink: () {},
          ),
        ],
      ), height: 1100);

  goldenSheet('library', () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: SongletSpace.x2,
            children: [
              PillChip(label: 'All', selected: true, onTap: () {}),
              PillChip(label: 'Birthday', onTap: () {}),
              PillChip(label: 'Anniversary', onTap: () {}),
            ],
          ),
          gap(),
          SectionHeader(title: 'Birthday', trailing: 'See all', onTrailing: () {}),
          SurfaceCard(
            padding: EdgeInsetsDirectional.zero,
            child: Column(
              children: [
                WorkRow(
                  cover: const CoverArt(seed: 'a', radius: SongletRadius.thumb),
                  title: 'For Alex',
                  subtitle: 'Alex',
                  meta: const ['0:30', 'Sep 24, 2026'],
                  badge: const StatusPill(label: 'Preview'),
                  onTap: () {},
                  onPlay: () {},
                  onMore: () {},
                  playLabel: 'Play',
                  moreLabel: 'More',
                ),
                WorkRow(
                  cover: const CoverArt(seed: 'b', radius: SongletRadius.thumb),
                  title: 'Another Amazing Year',
                  subtitle: 'Jamie',
                  meta: const ['2:07', 'Aug 16, 2026'],
                  badge: const StatusPill(label: 'Full song', tone: PillTone.success),
                  onTap: () {},
                  onPlay: () {},
                  onMore: () {},
                  playLabel: 'Play',
                  moreLabel: 'More',
                  playing: true,
                ),
              ],
            ),
          ),
          gap(),
          const EmptyState(
            icon: Icons.library_music_outlined,
            title: 'Your songs will live here',
            message: 'Make your first song — it stays on this device.',
            actionLabel: 'Create a song',
            onAction: _noop,
          ),
        ],
      ), height: 1000);

  goldenSheet('detail_settings', () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SurfaceCard(
            child: Column(
              children: const [
                InfoRow(icon: Icons.card_giftcard_rounded, label: 'Occasion', value: 'Birthday'),
                InfoRow(icon: Icons.place_outlined, label: 'Country', value: 'United States'),
                InfoRow(icon: Icons.sell_outlined, label: 'Keywords', value: 'coffee, hiking, Sunday'),
              ],
            ),
          ),
          gap(),
          SurfaceCard(child: CopyField(label: 'Generation ID', value: 'LYR-24A9C7', copyLabel: 'Copy', onCopy: () {})),
          gap(),
          SecondaryButton(label: 'Delete', icon: Icons.delete_outline_rounded, destructive: true, onPressed: () {}),
          gap(),
          SettingsGroup(
            title: 'LIBRARY',
            children: [
              SettingsRow(icon: Icons.cloud_outlined, title: 'iCloud sync', subtitle: 'Off', toggle: false, onToggle: (_) {}),
              SettingsRow(icon: Icons.translate_rounded, title: 'Lyrics language', value: 'English', onTap: () {}),
            ],
          ),
          gap(),
          const FeatureCard(
            icon: Icons.fingerprint_rounded,
            title: 'Built-in watermark',
            body: 'Every song includes a SynthID watermark from Google.',
          ),
          gap(),
          const HighlightBanner(message: 'Every song you share is labeled AI generated.'),
        ],
      ), height: 1100);

  goldenSheet('festival', () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FestivalHero(
            kicker: 'Live your story',
            title: 'Carnaval',
            subtitle: 'is coming!',
            body: 'Make a one-of-a-kind song to celebrate.',
            ctaLabel: 'Make a Carnaval song',
            onCta: () {},
            art: testArt,
          ),
          gap(),
          Row(
            children: [
              Expanded(child: OccasionCard(image: testArt, title: 'Birthday', hint: 'A song for their big day', onTap: () {})),
              const SizedBox(width: SongletSpace.x3),
              Expanded(child: OccasionCard(image: testArt, title: 'Wedding', hint: 'A soundtrack for the big day', onTap: () {})),
            ],
          ),
          gap(),
          LinkCard(icon: Icons.language_rounded, title: 'Songs in your language', subtitle: 'Portuguese and 12 more', onTap: () {}),
          gap(),
          PhotoStrip(
            images: [testArt, testArt],
            counter: '2 / 10',
            onRemove: (_) {},
            removeLabel: 'Remove photo',
            onAdd: () {},
            addLabel: 'Add photos',
          ),
        ],
      ), height: 1000);

  group('behaviour', () {
    testWidgets('PlanCard is a selectable exclusive option', (tester) async {
      var taps = 0;
      await pumpComponent(
        tester,
        PlanCard(title: 'Pro Monthly', price: r'$9.99/mo', benefits: const ['MP3'], selected: false, onTap: () => taps++),
      );
      await tester.tap(find.text('Pro Monthly'));
      expect(taps, 1);
      final node = tester.getSemantics(find.byType(PlanCard));
      expect(node.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
    });

    testWidgets('DownloadRow shows progress and ignores taps while busy', (tester) async {
      var taps = 0;
      await pumpComponent(
        tester,
        DownloadRow(
          icon: Icons.audio_file_outlined,
          title: 'MP3',
          subtitle: 's',
          actionLabel: 'Download MP3',
          onPressed: () => taps++,
          busy: true,
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Download MP3'));
      expect(taps, 0);
    });

    testWidgets('SettingsRow toggles through the whole row', (tester) async {
      bool? value;
      await pumpComponent(
        tester,
        SettingsRow(icon: Icons.cloud_outlined, title: 'iCloud sync', toggle: false, onToggle: (v) => value = v),
      );
      await tester.tap(find.text('iCloud sync'));
      expect(value, isTrue);
    });

    testWidgets('CopyField copies through its button', (tester) async {
      var copied = false;
      await pumpComponent(tester, CopyField(label: 'ID', value: 'LYR-1', copyLabel: 'Copy', onCopy: () => copied = true));
      await tester.tap(find.byTooltip('Copy'));
      expect(copied, isTrue);
    });

    testWidgets('EmptyState hides the action without a callback', (tester) async {
      await pumpComponent(
        tester,
        const EmptyState(icon: Icons.inbox, title: 'Empty', message: 'Nothing yet', actionLabel: 'Create'),
      );
      expect(find.text('Create'), findsNothing);
    });

    testWidgets('PhotoStrip removes by index and offers add until full', (tester) async {
      int? removed;
      await pumpComponent(
        tester,
        PhotoStrip(images: [testArt, testArt], counter: '2 / 10', onRemove: (i) => removed = i, removeLabel: 'Remove photo'),
      );
      await tester.tap(find.byTooltip('Remove photo').last);
      expect(removed, 1);
      expect(find.byIcon(Icons.add_photo_alternate_outlined), findsNothing);
    });
  });
}

void _noop() {}
