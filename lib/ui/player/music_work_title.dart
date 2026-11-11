import 'package:songlet_kit/songlet_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/music_brand.dart';
import '../create/music_create_labels.dart';

/// "For Alex" — or the template / occasion name when there is no recipient.
String workTitle(AppLocalizations l10n, MusicWork work) => work.recipient.isNotEmpty
    ? l10n.playerTitleFor(work.recipient)
    : workKindName(l10n, template: work.template, occasion: work.occasion);

/// File / folder name for downloads: "Songlet – For Alex (Birthday)".
String workFileName(AppLocalizations l10n, MusicWork work) =>
    l10n.playerExportFileName(
      MusicSongletBrand.name,
      workTitle(l10n, work),
      workKindName(l10n, template: work.template, occasion: work.occasion),
    );

/// The genre as shown for a work ("Based on the prompt" when custom).
String workGenre(AppLocalizations l10n, MusicWork work) =>
    work.hasCustomGenre ? l10n.detailCustomGenre : genreName(l10n, work.genre);
