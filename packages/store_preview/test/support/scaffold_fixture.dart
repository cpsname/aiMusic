import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// A minimal Flutter app repo on the template: pubspec, iOS project, icon,
/// l10n with English and Simplified Chinese.
String appRepo() {
  final root = Directory.systemTemp.createTempSync('new_app').path;
  void write(String path, String content) {
    File(p.join(root, path))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  write('pubspec.yaml', 'name: demo_app\n');
  write('ios/Runner.xcodeproj/project.pbxproj', '''
PRODUCT_BUNDLE_IDENTIFIER = org.example.demo;
TARGETED_DEVICE_FAMILY = "1,2";
PRODUCT_BUNDLE_IDENTIFIER = org.example.demo.RunnerTests;
PRODUCT_BUNDLE_IDENTIFIER = org.example.demo;
TARGETED_DEVICE_FAMILY = "1,2";
''');
  write('ios/Runner/Info.plist', '<plist><dict><key>CFBundleDisplayName</key>\n\t<string>Demo Studio</string></dict></plist>');
  write('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png', 'x');
  write('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png', 'x' * 100);
  write('l10n.yaml', 'arb-dir: lib/l10n/arb\ntemplate-arb-file: app_en.arb\n');
  write('lib/l10n/arb/app_en.arb', jsonEncode({'@@locale': 'en', 'title': 'Demo'}));
  write('lib/l10n/arb/app_zh.arb', jsonEncode({'@@locale': 'zh', 'title': '演示', 'storePreviewCta': '马上试试'}));
  write('config/dev.json', '{}');
  return root;
}
