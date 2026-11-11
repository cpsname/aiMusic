import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

import '../support/harness.dart';

void main() {
  goldenSheet('mv', () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          gap(),
          MvLevelCard(
            icon: Icons.subtitles_outlined,
            title: 'Lyric video',
            description: 'Your lyrics over a moving scene',
            meta: 'Whole song · 9:16',
            price: 'Free',
            selected: false,
            onTap: () {},
          ),
          gap(),
          MvLevelCard(
            icon: Icons.movie_filter_outlined,
            title: 'Chorus video',
            description: '30 seconds of the chorus, shot by AI',
            meta: '30 s · 9:16',
            price: '2,169',
            priceNote: '2,103 more needed',
            badge: 'Recommended',
            selected: true,
            onTap: () {},
          ),
          gap(),
          const MvLevelCard(
            icon: Icons.theaters_outlined,
            title: 'Full video',
            description: 'The whole song, scene by scene',
            meta: '2:07 · 9:16',
            price: '8,280',
            statusLabel: 'Making…',
            selected: false,
            onTap: null,
          ),
          gap(),
          InlineProgressBanner(
            icon: Icons.subtitles_outlined,
            title: 'Making your lyric video',
            detail: 'Rendering scene 2 of 3',
            value: 0.66,
            percentLabel: '66%',
            actionLabel: 'View',
            onAction: () {},
          ),
          gap(),
          InlineProgressBanner(
            icon: Icons.timer_outlined,
            title: 'A lyric video starts in 8 s',
            detail: 'Free, made from your song',
            actionLabel: 'Cancel',
            onAction: () {},
          ),
        ],
      ), height: 900);

  testWidgets('a level card is a selectable radio-like button; a level in flight is not', (tester) async {
    var taps = 0;
    await pumpComponent(
      tester,
      Column(children: [
        MvLevelCard(icon: Icons.movie, title: 'Chorus video', description: 'd', price: '2,169', selected: true, onTap: () => taps++),
        const MvLevelCard(icon: Icons.movie, title: 'Full video', description: 'd', price: '8,280', statusLabel: 'Making…', selected: false, onTap: null),
      ]),
    );
    await tester.tap(find.text('Chorus video'));
    await tester.tap(find.text('Full video'));
    expect(taps, 1);
    expect(find.text('8,280'), findsNothing, reason: 'the status replaces the price');
    final chorus = tester.getSemantics(find.ancestor(of: find.text('Chorus video'), matching: find.byType(Semantics)).first);
    expect(chorus.flagsCollection.isSelected, Tristate.isTrue);
    expect(chorus.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
  });

  testWidgets('the banner reports its action and stays still under reduce motion', (tester) async {
    var actions = 0;
    await pumpComponent(
      tester,
      InlineProgressBanner(icon: Icons.timer, title: 'Starts in 8 s', actionLabel: 'Cancel', onAction: () => actions++),
    );
    await tester.tap(find.text('Cancel'));
    expect(actions, 1);
    final bar = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(bar.value, 0, reason: 'no sweeping bar when motion is reduced');
  });

  testWidgets('accessibility sizes stack the card and move the banner action under the bar', (tester) async {
    await pumpComponent(
      tester,
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(3.1)),
        child: Column(children: [
          MvLevelCard(icon: Icons.movie, title: 'Chorus video', description: 'd', price: '2,169', selected: false, onTap: () {}),
          InlineProgressBanner(icon: Icons.timer, title: 'Starts in 8 s', value: 0.2, actionLabel: 'Cancel', onAction: () {}),
        ]),
      ),
      height: 1400,
    );
    expect(tester.takeException(), isNull);
    final price = tester.getTopLeft(find.text('2,169'));
    final title = tester.getTopLeft(find.text('Chorus video'));
    expect(price.dy, greaterThan(title.dy), reason: 'price under the text');
    final cancel = tester.getTopLeft(find.text('Cancel'));
    final banner = tester.getTopLeft(find.text('Starts in 8 s'));
    expect(cancel.dy, greaterThan(banner.dy));
  });
}
