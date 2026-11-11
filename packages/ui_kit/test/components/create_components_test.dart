import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

import '../support/harness.dart';

enum _State { free, picked, options, voice }

Widget _composer(_State state) {
  final picked = state == _State.picked || state == _State.options;
  return ComposerCard(
    head: picked
        ? ComposerTag(label: 'Birthday Wish', removeLabel: 'Remove Birthday Wish', onRemove: () {}, image: testArt)
        : null,
    body: switch (state) {
      _State.voice => VoiceCapturePanel(
          statusLabel: 'Recording…',
          elapsed: '0:12',
          levels: testBars,
          transcript: "It's Alex's thirtieth birthday, she loves hiking and Sunday coffee",
          placeholder: 'Listening…',
          onDeviceLabel: 'On-device transcription',
          actions: [VoiceCaptureAction(icon: Icons.edit_note_rounded, label: 'Use this text', onUse: () {})],
        ),
      _State.free => ComposerPromptField(
          controller: TextEditingController(),
          hint: 'Describe the song, or pick an idea above',
          leading: ComposerRoundButton(icon: Icons.add_rounded, tooltip: 'Add photos', onPressed: () {}),
          trailing: ComposerRoundButton(
            icon: Icons.mic_none_rounded,
            tooltip: 'Dictate',
            emphasis: ComposerButtonEmphasis.tinted,
            onPressed: () {},
          ),
        ),
      _State.picked || _State.options => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: TextEditingController(text: 'Alex'), decoration: const InputDecoration(labelText: 'Their name')),
            gap(),
            KeywordChipInput(
              values: const ['coffee', 'hiking'],
              onChanged: (_) {},
              addHint: 'Add a word',
              removeLabel: (w) => 'Remove $w',
              maxCount: 3,
              maxLength: 20,
            ),
          ],
        ),
    },
    summary: ComposerSummary(
      parts: const ['Preview', 'Vocals on', 'Indie Pop'],
      expanded: state == _State.options,
      onTap: () {},
      semanticLabel: 'Song options: Preview, Vocals on, Indie Pop',
    ),
    options: state == _State.options
        ? Row(
            children: [
              Expanded(child: ParamChip(icon: Icons.schedule_rounded, label: 'Length', value: 'Short', onTap: () {})),
              const SizedBox(width: SongletSpace.x2),
              Expanded(child: ParamChip(icon: Icons.person_outline_rounded, label: 'Vocals', value: 'Vocals on', onTap: () {}, open: true)),
              const SizedBox(width: SongletSpace.x2),
              Expanded(child: ParamChip(icon: Icons.equalizer_rounded, label: 'Genre', value: 'Indie Pop', onTap: () {})),
            ],
          )
        : null,
    primaryAction: ObsButton(label: picked ? "Create Alex's preview · free" : 'Create preview · free', onPressed: () {}),
  );
}

void main() {
  goldenSheet('create_home', () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BrandHeader(
            title: 'Songlet',
            tagline: 'Songs for the people you love',
          ),
          gap(),
          Row(
            children: [
              for (final t in ['Birthday Wish', 'Love Story', 'Thank a Friend', 'Rap Battle'])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(SongletSpace.x1),
                    child: TemplateTile(title: t, image: testArt, onTap: () {}, onPlay: () {}, playing: t == 'Love Story'),
                  ),
                ),
            ],
          ),
          Row(
            children: [
              for (final title in ['Soundscape', 'Background Music', 'Memorize Something', 'Weather Report'])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(SongletSpace.x1),
                    child: TemplateTile(
                      title: title,
                      image: testArt,
                      onTap: () {},
                      onPlay: () {},
                      playing: title == 'Weather Report',
                      selected: title == 'Background Music',
                    ),
                  ),
                ),
            ],
          ),
          gap(),
          _composer(_State.free),
          gap(),
          _composer(_State.picked),
          gap(),
          _composer(_State.options),
          gap(),
          _composer(_State.voice),
        ],
      ), height: 2000);

  goldenSheet('create_form', () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormFieldSection(
            label: 'Their name',
            error: "Artist names can't be used.",
            child: TextField(controller: TextEditingController(text: 'Taylor Swift style')),
          ),
          gap(),
          FormFieldSection(
            label: 'Three words about them',
            child: KeywordChipInput(
              values: const ['coffee', 'hiking'],
              onChanged: (_) {},
              addHint: 'Add a word',
              removeLabel: (w) => 'Remove $w',
              maxCount: 3,
              maxLength: 20,
            ),
          ),
          gap(),
          LyricsEditor(
            controller: TextEditingController(),
            expanded: false,
            onExpandedChanged: (_) {},
            title: 'Write your own lyrics (optional)',
            counter: '0 / 1,200',
            sectionTags: const ['[Verse]', '[Chorus]'],
            onInsertTag: (_) {},
          ),
          gap(),
          Row(
            children: [
              Expanded(child: ParamChip(icon: Icons.schedule_rounded, label: 'Length', value: 'Short', onTap: () {})),
              const SizedBox(width: SongletSpace.x2),
              Expanded(child: ParamChip(icon: Icons.mic_external_on_outlined, label: 'Vocals', value: 'Vocals on', onTap: () {})),
              const SizedBox(width: SongletSpace.x2),
              Expanded(child: ParamChip(icon: Icons.music_note_outlined, label: 'Genre', value: 'Indie Pop', onTap: () {})),
            ],
          ),
          gap(),
          InlineErrorBanner(
            message: "We can't make this one — try different words, and skip artist names.",
            actionLabel: 'Rewrite',
            onAction: () {},
          ),
        ],
      ), height: 1100);

  goldenSheet('create_panels', () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SurfaceCard(
            child: AnchoredPanelBody(
              title: 'Length',
              children: [
                OptionRow(title: 'Short', hint: '30-second preview, free', icon: Icons.schedule_rounded, selected: true, onTap: () {}),
                OptionRow(title: 'Standard', hint: 'about 2 minutes, Pro', icon: Icons.schedule_rounded, selected: false, onTap: () {}),
              ],
            ),
          ),
          gap(),
          SurfaceCard(
            child: AnchoredPanelBody(
              title: 'Genre',
              onClose: () {},
              closeLabel: 'Close',
              children: [
                OptionRow(title: 'Custom', subtitle: 'based on your prompt', icon: Icons.edit_note_rounded, selected: false, onTap: () {}),
                const PanelSectionHeader(label: 'Popular in United States'),
                OptionRow(title: 'Indie Pop', icon: Icons.equalizer_rounded, emphasizeIcon: true, selected: true, dense: true, onTap: () {}),
                OptionRow(title: 'Contemporary R&B', icon: Icons.music_note_outlined, selected: false, dense: true, onTap: () {}),
              ],
            ),
          ),
          gap(),
          SearchField(hint: 'Search country', onChanged: (_) {}),
          gap(),
          SurfaceCard(
            padding: EdgeInsetsDirectional.zero,
            child: Column(
              children: [
                CountryRow(flag: '🇺🇸', name: 'United States', selected: true, onTap: () {}),
                CountryRow(flag: '🇨🇦', name: 'Canada', selected: false, onTap: () {}, showDivider: false),
              ],
            ),
          ),
        ],
      ), height: 1000);

  group('behaviour', () {
    testWidgets('SegmentedToggle reports the tapped value and marks selection', (tester) async {
      int? picked;
      await pumpComponent(
        tester,
        SegmentedToggle<int>(segments: const [(0, 'Preview'), (1, 'Full')], selected: 0, onChanged: (v) => picked = v),
      );
      await tester.tap(find.text('Full'));
      expect(picked, 1);
      expect(tester.getSemantics(find.text('Preview')), matchesSemantics(isButton: true, isSelected: true, hasSelectedState: true, label: 'Preview', hasTapAction: true, isFocusable: true, hasFocusAction: true));
    });

    testWidgets('TemplateTile separates open and play', (tester) async {
      var opened = 0, played = 0;
      await pumpComponent(
        tester,
        SizedBox(
          width: 120,
          child: TemplateTile(title: 'Wedding', image: testArt, onTap: () => opened++, onPlay: () => played++, playLabel: 'Play sample'),
        ),
      );
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.tap(find.text('Wedding'));
      expect((opened, played), (1, 1));
    });

    testWidgets('TemplateTile: the description joins the label; a pick settles inward with the outline', (tester) async {
      Future<void> pump({required bool selected}) => pumpComponent(
            tester,
            SizedBox(
              width: 120,
              child: TemplateTile(
                title: 'Soundscape',
                description: 'Ambient textures, no vocals',
                image: testArt,
                selected: selected,
                onTap: () {},
                onPlay: () {},
              ),
            ),
          );
      await pump(selected: false);
      expect(find.bySemanticsLabel('Soundscape, Ambient textures, no vocals'), findsOneWidget);
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      await pump(selected: true);
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, TemplateTile.selectedScale);
      expect(tester.getSemantics(find.bySemanticsLabel('Soundscape, Ambient textures, no vocals')), isSemantics(isSelected: true));
    });

    testWidgets('TemplateTile: a failing photo throws nothing', (tester) async {
      await pumpComponent(
        tester,
        SizedBox(
          width: 120,
          child: TemplateTile(
            title: 'Ringtone',
            image: const NetworkImage('http://127.0.0.1:1/missing.jpg'),
            onTap: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    });

    test('CoverGradients: the same seed always gives the same gradient, and the seeds spread over the palette', () {
      expect(CoverGradients.of('a').colors, CoverGradients.of('a').colors);
      final used = {for (var i = 0; i < 60; i++) CoverGradients.of('inspiration:id-$i').colors.first.toARGB32()};
      expect(used.length, greaterThan(CoverGradients.count ~/ 2));
    });

    testWidgets('KeywordChipInput commits on enter, dedupes and caps at three', (tester) async {
      var values = <String>['coffee'];
      await pumpComponent(
        tester,
        StatefulBuilder(
          builder: (context, setState) => KeywordChipInput(
            values: values,
            onChanged: (v) => setState(() => values = v),
            addHint: 'Add a word',
            removeLabel: (w) => 'Remove $w',
            maxCount: 3,
            maxLength: 20,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Coffee');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(values, ['coffee']);
      await tester.enterText(find.byType(TextField), 'hiking');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(tester.testTextInput.isVisible, isTrue, reason: 'room for one more: keep typing');
      await tester.enterText(find.byType(TextField), 'Sunday');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(values, ['coffee', 'hiking', 'Sunday']);
      expect(find.byType(TextField), findsNothing, reason: 'full → no add field');
      expect(tester.testTextInput.isVisible, isFalse, reason: 'the third word closes the keyboard');
      await tester.tap(find.byTooltip('Remove hiking'));
      await tester.pump();
      expect(values, ['coffee', 'Sunday']);
    });

    testWidgets('LyricsEditor toggles and inserts tags', (tester) async {
      var expanded = false;
      final tags = <String>[];
      await pumpComponent(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LyricsEditor(
            controller: TextEditingController(),
            expanded: expanded,
            onExpandedChanged: (v) => setState(() => expanded = v),
            title: 'Write your own lyrics',
            counter: '0 / 1,200',
            sectionTags: const ['[Verse]', '[Chorus]'],
            onInsertTag: tags.add,
          ),
        ),
      );
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.text('Write your own lyrics'));
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
      await tester.tap(find.text('[Chorus]'));
      expect(tags, ['[Chorus]']);
    });

    testWidgets('VoiceCapturePanel disables the actions until words arrive', (tester) async {
      await pumpComponent(
        tester,
        VoiceCapturePanel(
          statusLabel: 'Recording…',
          elapsed: '0:01',
          levels: const [],
          transcript: '',
          placeholder: 'Listening…',
          onDeviceLabel: 'On-device transcription',
          actions: [
            VoiceCaptureAction(icon: Icons.edit_note_rounded, label: 'Use this text', onUse: () {}),
            VoiceCaptureAction(icon: Icons.music_note_outlined, label: 'Use as lyrics', onUse: () {}),
          ],
        ),
      );
      final button = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Use this text'));
      expect(button.onPressed, isNull);
      expect(find.text('Listening…'), findsOneWidget);
    });

    testWidgets('ComposerTag names the picked card and its close button drops it', (tester) async {
      var removed = 0;
      final semantics = tester.ensureSemantics();
      await pumpComponent(
        tester,
        ComposerTag(label: 'Soundscape', removeLabel: 'Remove Soundscape', onRemove: () => removed++, image: testArt),
      );
      expect(find.text('Soundscape'), findsOneWidget);
      expect(find.bySemanticsLabel('Remove Soundscape'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsNothing, reason: 'the photo stands in for the sparkle');
      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(removed, 1);
      semantics.dispose();
    });

    testWidgets('ComposerSummary reads as one expandable button', (tester) async {
      var taps = 0;
      final semantics = tester.ensureSemantics();
      await pumpComponent(
        tester,
        ComposerSummary(
          parts: const ['Preview', 'Vocals on', 'Indie Pop'],
          expanded: false,
          onTap: () => taps++,
          semanticLabel: 'Song options: Preview, Vocals on, Indie Pop',
          semanticHint: 'Show song options',
        ),
      );
      expect(find.text('Preview  ·  Vocals on  ·  Indie Pop'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(ComposerSummary)),
        matchesSemantics(
          label: 'Song options: Preview, Vocals on, Indie Pop',
          hint: 'Show song options',
          isButton: true,
          hasExpandedState: true,
          hasTapAction: true,
        ),
      );
      expect(tester.getSize(find.byType(ComposerSummary)).height, greaterThanOrEqualTo(SongletSize.minTap));
      await tester.tap(find.byType(ComposerSummary));
      expect(taps, 1);
      semantics.dispose();
    });

    testWidgets('ComposerCard: bounded, the fields scroll between a fixed head and primary action', (tester) async {
      await pumpComponent(
        tester,
        SizedBox(
          height: 260,
          child: ComposerCard(
            head: ComposerTag(label: 'Birthday Wish', removeLabel: 'Remove', onRemove: () {}),
            body: Column(children: [for (var i = 0; i < 8; i++) SizedBox(height: 60, child: Text('field $i'))]),
            summary: ComposerSummary(parts: const ['Preview'], expanded: false, onTap: () {}, semanticLabel: 'Options'),
            primaryAction: ObsButton(label: 'Create preview', onPressed: () {}),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final card = tester.getRect(find.byType(ComposerCard));
      expect(tester.getRect(find.byType(ObsButton)).bottom, lessThanOrEqualTo(card.bottom));
      expect(find.descendant(of: find.byType(ComposerCard), matching: find.byType(SingleChildScrollView)), findsOneWidget);
      expect(find.text('Birthday Wish').hitTestable(), findsOneWidget);
      expect(find.text('Create preview').hitTestable(), findsOneWidget);
    });

    testWidgets('ComposerCard: unbounded, laid out in full', (tester) async {
      await pumpComponent(
        tester,
        SingleChildScrollView(
          child: ComposerCard(
            body: const SizedBox(height: 400),
            summary: ComposerSummary(parts: const ['Preview'], expanded: false, onTap: () {}, semanticLabel: 'Options'),
            primaryAction: ObsButton(label: 'Create preview', onPressed: () {}),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.descendant(of: find.byType(ComposerCard), matching: find.byType(SingleChildScrollView)), findsNothing);
    });

    testWidgets('VoiceCapturePanel with one action: a single "use this text" button, enabled with words', (tester) async {
      var used = 0;
      await pumpComponent(
        tester,
        VoiceCapturePanel(
          statusLabel: 'Recording…',
          elapsed: '0:05',
          levels: const [],
          transcript: 'A cozy cooking vlog',
          placeholder: 'Listening…',
          onDeviceLabel: 'On-device transcription',
          actions: [VoiceCaptureAction(icon: Icons.edit_note_rounded, label: 'Use this text', onUse: () => used++)],
        ),
      );
      expect(find.byType(OutlinedButton), findsOneWidget);
      await tester.tap(find.text('Use this text'));
      expect(used, 1);
    });

    testWidgets('TemplateTile swaps a photo that fails to load for its fallback picture', (tester) async {
      const fallback = AssetImage('assets/occasions/soundtrack.jpg');
      Widget tile(ImageProvider? image) => SizedBox(
            width: 120,
            child: TemplateTile(title: 'Soundscape', image: image, fallbackImage: fallback, onTap: () {}),
          );
      ImageProvider? shown() => ((tester.widget<Ink>(find.byType(Ink)).decoration! as BoxDecoration).image)?.image;

      await pumpComponent(tester, tile(_BrokenImage()));
      await tester.pump();
      await tester.pump();
      expect(shown(), fallback);
      expect(tester.takeException(), isNull, reason: 'a failed cover is not an error');

      await pumpComponent(tester, tile(testArt));
      await tester.pump();
      expect(shown(), testArt, reason: 'a photo that loads stays');
    });

    testWidgets('showAnchoredPanel opens above a low anchor and pops a value', (tester) async {
      String? result;
      await pumpComponent(
        tester,
        SizedBox(
          height: 700,
          child: Align(
            alignment: AlignmentDirectional.bottomCenter,
            child: Builder(
              builder: (anchor) => TextButton(
                onPressed: () async {
                  result = await showAnchoredPanel<String>(
                    context: anchor,
                    anchorContext: anchor,
                    barrierLabel: 'Dismiss',
                    builder: (context) => AnchoredPanelBody(
                      title: 'Length',
                      children: [
                        OptionRow(title: 'Short', selected: true, onTap: () => Navigator.pop(context, 'short')),
                      ],
                    ),
                  );
                },
                child: const Text('Length'),
              ),
            ),
          ),
        ),
      );
      final anchorTop = tester.getTopLeft(find.text('Length')).dy;
      await tester.tap(find.text('Length'));
      await tester.pumpAndSettle();
      expect(tester.getBottomLeft(find.text('Short')).dy, lessThan(anchorTop));
      await tester.tap(find.text('Short'));
      await tester.pumpAndSettle();
      expect(result, 'short');
    });
  });

  group('PanelGeometry', () {
    const screen = Size(393, 852);
    test('places the panel on the side with more room, clamped to the gutter', () {
      final low = PanelGeometry.resolve(
        screen: screen,
        anchor: const Rect.fromLTWH(20, 700, 100, 44),
        safe: EdgeInsets.zero,
        maxWidth: 300,
      );
      expect(low.above, isTrue);
      expect(low.left, SongletSpace.gutter);
      expect(low.arrowX, closeTo(70 - SongletSpace.gutter, 0.01));
      final high = PanelGeometry.resolve(
        screen: screen,
        anchor: const Rect.fromLTWH(300, 80, 60, 44),
        safe: EdgeInsets.zero,
        maxWidth: 300,
      );
      expect(high.above, isFalse);
      expect(high.left + high.width, lessThanOrEqualTo(screen.width - SongletSpace.gutter));
    });
  });
}

/// An image that always fails to load.
class _BrokenImage extends ImageProvider<_BrokenImage> {
  @override
  Future<_BrokenImage> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(_BrokenImage key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(Future<ImageInfo>.error(StateError('broken')));
}
