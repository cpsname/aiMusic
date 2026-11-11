# store_preview_driver

The app side of [store_preview](../store_preview/README.md): it runs the
recording plan the recorder hands an app's `integration_test` (as the
`STORE_PREVIEW_PLAN` dart-define), prints the scene marks post-production cuts
by, and lets the app add its own steps and playback readers.

```dart
// integration_test/store_preview_test.dart
import 'package:my_app/main.dart' as app;
import 'package:store_preview_driver/store_preview_driver.dart';

void main() => storePreviewTest(
  appMain: app.main,
  registry: StepRegistry()
    ..step('signInAsDemo', (c, step) async {/* … */})
    ..position('video', (c, at) async {/* the player's position at `at`, s */ return 0}),
);
```

Built-in steps mean the same in every app and cannot be redefined: `pause`,
`waitFor`, `waitGone`, `tap`, `type`, `submit`, `dismissKeyboard`, `scrollTo`,
`fling`, `pop`, `admin`, `pickPhotos`, `waitSync`, `waitHelper`, `screenshot`.
A step handler gets a `StepContext`: the tester, `hold`, `waitFor`,
`waitUntil`, `tap`, `type`, `reveal`, `postAdmin`, `remembered`.

Without a plan the test is skipped, so it is harmless in a normal test run.
