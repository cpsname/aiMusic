# Reuse Notes acceptance inputs

This independent example exercises the public CLI from a fresh Flutter iOS app.
Run the complete procedure in `../../asset-library-reuse.zh-CN.md`, section 5.

The app stores two toggles in memory and shows a note, a checklist and a pinned
state. English and Chinese UI strings come from ARB. There is no backend, account,
payment, external URL scheme or store integration. CPP deep links remain empty.
The example does not claim to be a production IAP product or an ASO experiment
with measured uplift.

`main.dart.txt` is copied to the generated app's `lib/main.dart`; the text suffix
keeps an incomplete app input out of the template's analyzer. Generated l10n code
comes from Flutter in the new app, never from a copied business app.

The backdrop is a locally authored solid color made by the documented ffmpeg
command. Its manifest license identifies this test fixture; use real licensing
evidence for production media. No media binary, recording or credential is in
this example. Rendering produces actual simulator footage in the new app.

The generated app chooses iOS 15 for this example. The SDK preflight rejects it
if the installed SDK does not support that target. This does not authorize
changing an existing application's deployment policy.
