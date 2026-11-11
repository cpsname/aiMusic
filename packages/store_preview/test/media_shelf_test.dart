import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:store_preview/src/creative/media_binding.dart';
import 'package:store_preview/store_preview.dart';
import 'package:yaml/yaml.dart';

void main() {
  late Directory root;
  setUp(() => root = Directory.systemTemp.createTempSync('media_shelf'));
  tearDown(() => root.deleteSync(recursive: true));
  const group = 'IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE';
  const target = 'custom_product_page:products';
  File write(String name, String text) => File(p.join(root.path, name))
    ..createSync(recursive: true)
    ..writeAsStringSync(text);
  const definition = '''
id: page
title: Product screenshots
targets: [custom_product_page:products]
backdrop: {role: photo, script: Q, index: 0}
slots:
  - placements: [app_screenshot]
    spec: screenshot_iphone_6_9
    device: iphone
    display_target: IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE
    text: caption
    assets:
      - {id: "proof.{storefront}", type: image, frame: {script: Q, scene: proof, at: 1}}
      - {id: "workflow.{storefront}", type: image, frame: {script: Q, scene: workflow, at: 1}}
shelf:
  media_sets:
    - placement: app_screenshot
      display_target: IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE
      locales: ["proof.{storefront}", "workflow.{storefront}"]
''';
  CreativeDefinition read(String text) => loadCreative(write('page.yaml', text).path);

  test('ordered shelves expand locale IDs and validate the device and owner', () {
    final d = read(definition);
    expect(checkShelfDeclarations([d]), isEmpty);
    final shelves = deriveMediaShelves([d], ['en-US', 'ja']);
    expect(shelves[target]!.single.locales['ja'], ['proof.ja', 'workflow.ja']);
    expect(checkShelfDeclarations([d, d]), contains(contains('also declared')));
    expect(
      checkShelfDeclarations([
        read(
          definition.replaceFirst(
            'device: iphone\n    display_target: IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE',
            'device: ipad\n    display_target: IPAD_13_PROFILE',
          ),
        ),
      ]),
      contains(contains('must be made for this device')),
    );
    expect(
      checkShelfDeclarations([
        read(definition.replaceFirst('locales: ["proof.{storefront}", "workflow.{storefront}"]', 'locales: ["proof.{storefront}", "proof.{storefront}"]')),
      ]),
      contains(contains('nonempty and unique')),
    );
  });

  test('writing exact sequences preserves metadata, unmanaged groups and limits locales', () {
    write('assets.yaml', 'schema: 1\nmanifest: assets.json\n');
    final cpp = write('cpp/products.yaml', '''
schema: 2
name: Products
visible: false
deep_link: ""
locales:
  en-US: {promotional_text: "Animate a photo and preview the result.", keywords: [image]}
media_sets:
  - placement: app_preview
    display_target: IPAD_13_PROFILE
    locales: {en-US: [existing.video]}
''');
    final shelves = deriveMediaShelves([read(definition)], ['en-US', 'ja']);
    final manifest = p.join(root.path, 'assets.json');
    var listing = AscpubListing.load(root.path);
    expect(shelfDrift(listing, {}, manifestPath: manifest, fix: 'write', mediaShelves: shelves), hasLength(1));
    writeShelves(listing, {}, manifestPath: manifest, mediaShelves: shelves);
    listing = AscpubListing.load(root.path);
    final sets = listing.pages[target]!.mediaSets;
    expect(sets.first.locales['en-US'], ['existing.video']);
    expect(sets.last.locales, {
      'en-US': ['proof.en-US', 'workflow.en-US'],
    });
    final map = loadYaml(cpp.readAsStringSync()) as YamlMap;
    expect(map['locales']['en-US']['keywords'], ['image']);
    expect(map['visible'], false);
    expect(writeShelves(listing, {}, manifestPath: manifest, mediaShelves: shelves), isEmpty);
    final reverse = {
      target: [
        const MediaSetBinding(
          placement: 'app_screenshot',
          displayTarget: group,
          locales: {
            'en-US': ['workflow.en-US', 'proof.en-US'],
          },
        ),
      ],
    };
    expect(shelfDrift(listing, {}, manifestPath: manifest, fix: 'write', mediaShelves: reverse), hasLength(1));
  });

  test('review evidence changes when recording device or display group changes', () {
    final phone = read(definition).slots.first;
    final ipad = read(definition.replaceAll('device: iphone', 'device: ipad').replaceAll(group, 'IPAD_13_PROFILE')).slots.first;
    expect(reviewBasis(phone, phone.assets.first), isNot(reviewBasis(ipad, ipad.assets.first)));
  });
}
