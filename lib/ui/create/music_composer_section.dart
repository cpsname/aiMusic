import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/music_art.dart';
import '../common/music_failure_copy.dart';
import '../common/music_localized_formats.dart';
import '../common/music_messages.dart';
import '../common/music_test_id.dart';
import '../routing/music_navigation.dart';
import '../routing/music_routes.dart';
import 'music_composer_model.dart';
import 'music_create_flow.dart';
import 'music_create_labels.dart';
import 'music_inspiration_labels.dart';
import 'music_panels.dart';

/// Where the composer shows a preflight issue (docs/ui P18): under the field
/// that holds the offending text, else in the message banner.
enum _Field { prompt, name, keywords, lyrics, banner }

/// The create home's composer (docs/ui P01 / P03, ADR-0033), bound to the
/// draft. One mental model — who it is for, what to say, how it sounds,
/// start — in three states:
/// * **A, free input**: the prompt field ("+" photos, the mic), the summary
///   row (length · vocals · genre) and the primary action;
/// * **B, a picked card**: the card's head (photo, name, ✕) and its fields —
///   name and three words, "Your words" for a card that asks for them — in
///   place of the prompt field;
/// * **C, options** (over A or B, `?options=1`): the Length / MusicVocals / MusicGenre
///   selectors (P02a–c), own lyrics and, for the full song, the video switch.
///
/// The primary action is the only way to start a song from the create home.
/// Panels, options and dictation are routes, so they deep-link and survive
/// rebuilds; this widget opens what the route asks for.
class MusicComposerSection extends ConsumerStatefulWidget {
  const MusicComposerSection({
    super.key,
    this.panel,
    this.voice = false,
    this.options = false,
    this.wide = false,
  });

  final MusicCreatePanel? panel;
  final bool voice;

  /// The options are unfolded (state C).
  final bool options;

  /// Laid out beside the grid (iPad), not under it: the prompt's placeholder
  /// does not point "above".
  final bool wide;

  @override
  ConsumerState<MusicComposerSection> createState() => _ComposerSectionState();
}

class _ComposerSectionState extends ConsumerState<MusicComposerSection> {
  /// Free input's prompt field (A).
  final _prompt = TextEditingController();
  final _promptFocus = FocusNode();

  /// The picked card's "Your words" field (B, `input_required`): the same
  /// draft text as [_prompt], its own field (both show while they switch).
  final _words = TextEditingController();
  final _wordsFocus = FocusNode();
  final _name = TextEditingController();
  final _nameFocus = FocusNode();
  final _lyrics = TextEditingController();
  final _anchors = {for (final p in MusicCreatePanel.values) p: GlobalKey()};

  /// The summary row: with the options under it, scrolled into view as they
  /// unfold.
  final _summaryKey = GlobalKey();
  MusicCreatePanel? _open;
  bool _lyricsOpen = false;

  /// MusicPreflight issues of the last press (P18), refreshed as the user edits.
  List<MusicPreflightIssue> _issues = const [];

  bool get _optionsShown => widget.options || widget.panel != null;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(creationDraftProvider).draft;
    _prompt.text = draft?.prompt ?? '';
    _words.text = draft?.prompt ?? '';
    _name.text = draft?.recipient ?? '';
    _lyrics.text = draft?.userLyrics ?? '';
    _lyricsOpen = draft?.hasUserLyrics ?? false;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _syncRoute(null, false),
    );
    if (_optionsShown) _revealOptions();
  }

  @override
  void didUpdateWidget(MusicComposerSection old) {
    super.didUpdateWidget(old);
    final wasShown = old.options || old.panel != null;
    if (_optionsShown && !wasShown) _revealOptions();
    if (old.panel != widget.panel || old.voice != widget.voice) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _syncRoute(old.panel, old.voice),
      );
    }
  }

  @override
  void dispose() {
    _prompt.dispose();
    _promptFocus.dispose();
    _words.dispose();
    _wordsFocus.dispose();
    _name.dispose();
    _nameFocus.dispose();
    _lyrics.dispose();
    super.dispose();
  }

  String get _speechLocale {
    final draft = ref.read(creationDraftProvider).draft;
    return draft?.lyricLanguage.code ??
        Localizations.localeOf(context).toLanguageTag();
  }

  void _syncRoute(MusicCreatePanel? oldPanel, bool oldVoice) {
    if (!mounted) return;
    final panel = widget.panel;
    if (panel != null && panel != _open) _openPanel(panel);
    final picked =
        MusicComposerSubject.of(ref.read(creationDraftProvider).draft) ==
        MusicComposerSubject.picked;
    if (widget.voice && picked) {
      // Dictation is free input: a picked card has no mic.
      context.goTo(MusicCreateRoute(options: widget.options));
    } else if (widget.voice && !oldVoice) {
      ref.read(dictationProvider.notifier).start(_speechLocale);
    } else if (!widget.voice && oldVoice) {
      ref.read(dictationProvider.notifier).cancel();
    }
  }

  Future<void> _openPanel(MusicCreatePanel panel) async {
    final anchor = _anchors[panel]!.currentContext;
    if (anchor == null) return;
    setState(() => _open = panel);
    final l10n = AppLocalizations.of(context);
    await showAnchoredPanel<void>(
      context: context,
      anchorContext: anchor,
      barrierLabel: l10n.commonClose,
      maxWidth: panel == MusicCreatePanel.genre
          ? SongletSize.anchoredPanelWideWidth
          : SongletSize.anchoredPanelWidth,
      builder: (_) => switch (panel) {
        MusicCreatePanel.length => const MusicLengthPanel(),
        MusicCreatePanel.vocals => const MusicVocalsPanel(),
        MusicCreatePanel.genre => const MusicGenrePanel(),
      },
    );
    if (!mounted) return;
    setState(() => _open = null);
    // Closing the panel returns to the options it opened from, unless the
    // panel itself navigated elsewhere (region sheet, paywall).
    if (widget.panel == panel) context.goTo(const MusicCreateRoute(options: true));
  }

  /// Unfolded under a picked card's fields, the options may start below the
  /// composer's fold (a small phone): bring the summary row to the top of its
  /// view, the selectors under it.
  void _revealOptions() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final summary = _summaryKey.currentContext;
      if (!mounted || summary == null) return;
      Scrollable.ensureVisible(
        summary,
        duration: MotionPolicy.reduceMotion(context)
            ? SongletMotion.none
            : SongletMotion.state,
        curve: SongletMotion.emphasizedCurve,
      );
    });
  }

  void _toggleOptions() =>
      context.goTo(MusicCreateRoute(options: !_optionsShown, voice: widget.voice));

  /// The picked tile, or null for free input. An entry the list no longer
  /// has still names the pick by its template, if any.
  MusicIdea? _pickedIdea(MusicCreationDraft? draft) {
    if (draft == null || !draft.hasPick) return null;
    for (final idea in ref.read(ideasProvider)) {
      if (idea.isPickedIn(draft)) return idea;
    }
    final template = draft.template;
    return template == null ? null : MusicIdea.template(template);
  }

  void _edit(MusicCreationDraft Function(MusicCreationDraft d) change) {
    ref.read(creationDraftProvider.notifier).update(change);
    if (_issues.isNotEmpty) {
      setState(() => _issues = MusicCreateFlow(context, ref).issues());
    }
  }

  /// Where each issue shows for [draft] as the composer lays it out: an
  /// artist or imitation goes under the first shown field whose text has it.
  Map<_Field, List<MusicPreflightIssue>> _place(MusicCreationDraft draft) {
    final picked = draft.hasPick;
    final promptShown = !picked || draft.sendsPromptWithPick;
    final lyricsShown = draft.vocals != MusicVocals.instrumental;
    final preflight = ref.read(preflightProvider);
    final placed = <_Field, List<MusicPreflightIssue>>{};
    void put(_Field field, MusicPreflightIssue issue) =>
        (placed[field] ??= []).add(issue);
    for (final issue in _issues) {
      switch (issue) {
        case MusicPreflightIssue.promptTooLong:
          put(promptShown ? _Field.prompt : _Field.banner, issue);
        case MusicPreflightIssue.recipientMissing ||
            MusicPreflightIssue.recipientTooLong ||
            MusicPreflightIssue.recipientArtistName:
          put(picked ? _Field.name : _Field.banner, issue);
        case MusicPreflightIssue.keywordTooLong || MusicPreflightIssue.tooManyKeywords:
          put(picked ? _Field.keywords : _Field.banner, issue);
        case MusicPreflightIssue.lyricsTooLong ||
            MusicPreflightIssue.lyricsNotOriginal ||
            MusicPreflightIssue.lyricsOwnershipUnconfirmed:
          put(lyricsShown ? _Field.lyrics : _Field.banner, issue);
        case MusicPreflightIssue.artistName || MusicPreflightIssue.styleImitation:
          final field = [
            if (promptShown) (_Field.prompt, draft.prompt),
            if (picked) (_Field.keywords, draft.keywords.join('\n')),
            if (lyricsShown) (_Field.lyrics, draft.userLyrics ?? ''),
          ].where((f) => preflight.screen(f.$2).contains(issue)).firstOrNull;
          put(field?.$1 ?? _Field.banner, issue);
        case MusicPreflightIssue.briefMissing || MusicPreflightIssue.tooManyPhotos:
          put(_Field.banner, issue);
      }
    }
    return placed;
  }

  String _issueText(AppLocalizations l10n, MusicPreflightIssue issue) =>
      preflightIssueText(
        l10n,
        issue,
        limit: MusicLyricsFormatter.limitFor(_lyrics.text),
      );

  Future<void> _submit() async {
    final draft = ref.read(creationDraftProvider).draft;
    if (draft == null || !MusicCreateAction.hasMaterial(draft)) return;
    FocusScope.of(context).unfocus();
    final flow = MusicCreateFlow(context, ref);
    final outcome = await flow.submit();
    if (!mounted) return;
    if (outcome != MusicSubmitOutcome.rejected) {
      if (_issues.isNotEmpty) setState(() => _issues = const []);
      return;
    }
    setState(() => _issues = flow.issues());
    final placed = _place(draft);
    // A lyrics issue is shown with the lyrics: open the options to them.
    if (placed.containsKey(_Field.lyrics)) {
      setState(() => _lyricsOpen = true);
      if (!_optionsShown) context.goTo(const MusicCreateRoute(options: true));
    }
    final banner = placed[_Field.banner];
    if (banner != null) {
      final l10n = AppLocalizations.of(context);
      final first = banner.first;
      ref
          .read(messageControllerProvider)
          .error(
            first == MusicPreflightIssue.artistName ||
                    first == MusicPreflightIssue.styleImitation
                ? songletErrorText(l10n, MusicErrorCode.safetyBlocked)
                : _issueText(l10n, first),
          );
    }
  }

  void _useTranscript(String transcript) {
    ref.read(creationDraftProvider.notifier).applyTranscript(transcript);
    ref.read(dictationProvider.notifier).reset();
    final draft = ref.read(creationDraftProvider).draft;
    // The field keeps its own controller (and may hold focus): show the
    // words where they went.
    if (draft != null) _prompt.text = draft.prompt;
    ref
        .read(messageControllerProvider)
        .success(AppLocalizations.of(context).voiceApplied);
    context.goTo(MusicCreateRoute(options: widget.options));
  }

  void _insertTag(String tag) {
    final text = _lyrics.text;
    final insert = '${text.isEmpty || text.endsWith('\n') ? '' : '\n'}$tag\n';
    _lyrics.text = '$text$insert';
    _edit((d) => d.copyWith(userLyrics: _lyrics.text));
  }

  /// Puts [value] in [controller] when the draft changed it from elsewhere (a
  /// pick, a deep link, dictation) — never under the user's cursor.
  static void _sync(
    TextEditingController controller,
    FocusNode? focus,
    String value,
  ) {
    if (controller.text != value && !(focus?.hasFocus ?? false)) {
      controller.text = value;
    }
  }

  /// The mic in the prompt field: dictate, stop, or leave dictation.
  Widget _mic(AppLocalizations l10n, MusicDictationState dictation) {
    final recording =
        widget.voice &&
        (dictation is MusicDictationRecording || dictation is MusicDictationStarting);
    return MusicTestId(
      'composer.mic',
      child: ComposerRoundButton(
        icon: recording ? Icons.stop_rounded : Icons.mic_none_rounded,
        tooltip: recording ? l10n.composerStopDictation : l10n.composerDictate,
        emphasis: recording
            ? ComposerButtonEmphasis.solid
            : ComposerButtonEmphasis.tinted,
        onPressed: () {
          if (!widget.voice) {
            context.goTo(MusicCreateRoute(voice: true, options: widget.options));
          } else if (dictation is MusicDictationRecording && !dictation.finished) {
            ref.read(dictationProvider.notifier).stop();
          } else {
            context.goTo(MusicCreateRoute(options: widget.options));
          }
        },
      ),
    );
  }

  /// State A: the prompt field, or the voice panel while dictating (P03a).
  Widget _freeBody(
    AppLocalizations l10n,
    MusicCreationDraft? draft,
    MusicDictationState dictation,
    Map<_Field, List<MusicPreflightIssue>> placed,
  ) {
    if (widget.voice) {
      return KeyedSubtree(
        key: const ValueKey('composer.body.voice'),
        child: _VoicePrompt(
          state: dictation,
          onUse: _useTranscript,
          trailing: _mic(l10n, dictation),
        ),
      );
    }
    final photos = draft?.photos.length ?? 0;
    final promptIssue = placed[_Field.prompt]?.firstOrNull;
    return KeyedSubtree(
      key: const ValueKey('composer.body.free'),
      child: MusicTestId(
        'composer.prompt',
        child: ComposerPromptField(
          controller: _prompt,
          focusNode: _promptFocus,
          hint: widget.wide
              ? l10n.composerPromptHintWide
              : l10n.composerPromptHint,
          maxLength: MusicPreflight.maxPrompt,
          errorText: promptIssue == null ? null : _issueText(l10n, promptIssue),
          onChanged: (v) => _edit((d) => d.copyWith(prompt: v)),
          leading: MusicTestId(
            'composer.photos',
            child: ComposerRoundButton(
              icon: photos == 0
                  ? Icons.add_rounded
                  : Icons.photo_library_rounded,
              tooltip: photos == 0
                  ? l10n.composerAddPhotos
                  : l10n.composerPhotosAttached(photos),
              emphasis: photos == 0
                  ? ComposerButtonEmphasis.neutral
                  : ComposerButtonEmphasis.tinted,
              onPressed: () => context.open(const MusicPhotosRoute()),
            ),
          ),
          trailing: _mic(l10n, dictation),
        ),
      ),
    );
  }

  /// State B: the picked card's fields — "Your words" first for a card that
  /// lives on them, then the name and three words, P18 errors under each.
  Widget _pickedBody(
    AppLocalizations l10n,
    MusicCreationDraft draft,
    MusicIdea idea,
    Map<_Field, List<MusicPreflightIssue>> placed,
  ) {
    final c = SongletColors.of(context);
    String? error(_Field field) {
      final issue = placed[field]?.firstOrNull;
      return issue == null ? null : _issueText(l10n, issue);
    }

    final composer = idea.inspiration?.composer;
    final template = idea.template;
    final nameError = error(_Field.name);
    final keywordError = error(_Field.keywords);
    return KeyedSubtree(
      key: const ValueKey('composer.body.picked'),
      child: MusicTestId(
        'composer.fields',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (draft.sendsPromptWithPick) ...[
              FormFieldSection(
                label: l10n.composerWordsLabel,
                error: error(_Field.prompt),
                child: MusicTestId(
                  'composer.words',
                  child: ComposerPromptField(
                    controller: _words,
                    focusNode: _wordsFocus,
                    // The card's hint is the placeholder only — never sent.
                    hint: composer != null
                        ? inspirationHint(context, composer)
                        : template != null
                        ? templateHint(l10n, template)
                        : l10n.composerPromptHintWide,
                    maxLength: MusicPreflight.maxPrompt,
                    onChanged: (v) => _edit((d) => d.copyWith(prompt: v)),
                  ),
                ),
              ),
              const SizedBox(height: SongletSpace.x3),
            ],
            FormFieldSection(
              label: draft.requiresRecipient
                  ? l10n.inputNameLabel
                  : l10n.inputNameOptionalLabel,
              error: nameError,
              child: MusicTestId(
                'composer.name',
                child: TextField(
                  controller: _name,
                  focusNode: _nameFocus,
                  maxLength: MusicPreflight.maxRecipient,
                  textInputAction: TextInputAction.next,
                  onChanged: (v) => _edit((d) => d.copyWith(recipient: v)),
                  decoration: InputDecoration(
                    hintText: l10n.inputNameHint,
                    counterText: '',
                    // The message renders under the section (P18); the field
                    // only takes the danger outline.
                    enabledBorder: nameError == null
                        ? null
                        : OutlineInputBorder(
                            borderRadius: SongletRadius.controlAll,
                            borderSide: BorderSide(
                              color: c.danger,
                              width: SongletSize.focusRing,
                            ),
                          ),
                    suffixIcon: ValueListenableBuilder(
                      valueListenable: _name,
                      builder: (context, value, _) => value.text.isEmpty
                          ? const SizedBox.shrink()
                          : IconButton(
                              tooltip: l10n.nameClear,
                              icon: const Icon(Icons.cancel_rounded),
                              onPressed: () {
                                _name.clear();
                                _edit((d) => d.copyWith(recipient: ''));
                              },
                            ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: SongletSpace.x3),
            FormFieldSection(
              label: l10n.inputKeywordsLabel,
              error: keywordError,
              child: MusicTestId(
                'composer.keywords',
                child: KeywordChipInput(
                  values: draft.keywords,
                  maxCount: MusicPreflight.maxKeywords,
                  maxLength: MusicPreflight.maxKeyword,
                  addHint: l10n.keywordAdd,
                  removeLabel: l10n.keywordRemove,
                  error: keywordError != null,
                  onChanged: (words) =>
                      _edit((d) => d.copyWith(keywords: words)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// State C: the selectors (anchors of P02a–c), own lyrics (not for an
  /// instrumental, which takes none — contract 02 v2.1 §2.4) and, for the
  /// full song, "also make a lyric video" (ADR-0022, ADR-0033).
  Widget _options(
    AppLocalizations l10n,
    MusicCreationDraft draft,
    Map<_Field, List<MusicPreflightIssue>> placed,
  ) {
    final c = SongletColors.of(context);
    final full = draft.model == MusicSongModel.fullSong;
    final chorus = full && draft.autoVideo == MusicAutoVideo.chorus;
    final selectors = [
      for (final (panel, icon, label, value) in [
        (
          MusicCreatePanel.length,
          Icons.schedule_rounded,
          l10n.paramLength,
          chorus ? l10n.lengthSongAndChorus : lengthName(l10n, draft.model),
        ),
        (
          MusicCreatePanel.vocals,
          vocalsIcon(draft.vocals),
          l10n.paramVocals,
          vocalsName(l10n, draft.vocals),
        ),
        (
          MusicCreatePanel.genre,
          Icons.equalizer_rounded,
          l10n.paramGenre,
          genreName(l10n, draft.genre),
        ),
      ])
        MusicTestId(
          'composer.${panel.wire}',
          child: KeyedSubtree(
            key: _anchors[panel],
            child: ParamChip(
              icon: icon,
              label: label,
              value: value,
              open: _open == panel,
              onTap: () =>
                  context.goTo(MusicCreateRoute(panel: panel, options: true)),
            ),
          ),
        ),
    ];
    final lyricsLength = _lyrics.text.runes.length;
    final lyricsLimit = MusicLyricsFormatter.limitFor(_lyrics.text);
    final lyricsIssue = placed[_Field.lyrics]?.firstOrNull;
    return MusicTestId(
      'composer.options',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Accessibility sizes: one selector per row, labels in full.
          if (SongletType.isAccessibilitySize(context))
            for (final (i, selector) in selectors.indexed) ...[
              if (i > 0) const SizedBox(height: SongletSpace.x2),
              selector,
            ]
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, selector) in selectors.indexed) ...[
                  if (i > 0) const SizedBox(width: SongletSpace.x2),
                  Expanded(child: selector),
                ],
              ],
            ),
          if (draft.vocals != MusicVocals.instrumental) ...[
            const SizedBox(height: SongletSpace.x3),
            MusicTestId(
              'composer.lyrics',
              child: LyricsEditor(
                controller: _lyrics,
                expanded: _lyricsOpen,
                onExpandedChanged: (v) => setState(() => _lyricsOpen = v),
                title: l10n.lyricsOptional,
                counter: l10n.lyricsCounter(lyricsLength, lyricsLimit),
                overLimit: lyricsLength > lyricsLimit,
                hint: l10n.inputLyricsHint,
                sectionTags: const ['[Verse]', '[Chorus]', '[Bridge]'],
                sectionTagLabels: [
                  l10n.sectionVerse,
                  l10n.sectionChorus,
                  l10n.sectionBridge,
                ],
                onInsertTag: _insertTag,
                onChanged: (v) => _edit(
                  (d) => d.copyWith(
                    userLyrics: v,
                    clearUserLyrics: v.trim().isEmpty,
                  ),
                ),
                errorText: lyricsIssue == null
                    ? null
                    : _issueText(l10n, lyricsIssue),
                ownership: CheckboxListTile(
                  contentPadding: EdgeInsetsDirectional.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: draft.lyricsOwnershipConfirmed,
                  title: Text(
                    l10n.inputLyricsOwnership,
                    style: SongletType.footnote,
                  ),
                  onChanged: (v) => _edit(
                    (d) => d.copyWith(lyricsOwnershipConfirmed: v ?? false),
                  ),
                ),
              ),
            ),
          ],
          // Premier's song + chorus video already brings its video.
          if (full && !chorus)
            MusicTestId(
              'composer.video',
              child: SwitchListTile.adaptive(
                contentPadding: const EdgeInsetsDirectional.symmetric(
                  horizontal: SongletSpace.x2,
                ),
                secondary: Icon(
                  Icons.subtitles_outlined,
                  color: c.inkSecondary,
                ),
                title: Text(
                  l10n.lengthAutoVideo,
                  style: SongletType.callout.copyWith(color: c.ink),
                ),
                subtitle: Text(
                  l10n.lengthAutoVideoHint,
                  style: SongletType.footnote.copyWith(color: c.inkSecondary),
                ),
                value: draft.autoVideo == MusicAutoVideo.lyric,
                onChanged: (on) => ref
                    .read(creationDraftProvider.notifier)
                    .setAutoVideo(on ? MusicAutoVideo.lyric : MusicAutoVideo.none),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(creationDraftProvider).draft;
    final dictation = ref.watch(dictationProvider);
    final entitlement = ref.watch(musicEntitlementProvider).value;
    final busy = ref.watch(generationControllerProvider).isBusy;
    ref.listen(dictationProvider, (previous, next) {
      if (next is MusicDictationUnavailable) {
        ref
            .read(messageControllerProvider)
            .error(
              next.reason == MusicSpeechAvailability.denied
                  ? l10n.voicePermissionDenied
                  : l10n.voiceUnavailable,
            );
        context.goTo(MusicCreateRoute(options: widget.options));
      }
    });
    // The selectors (a panel's anchors) show once the home has started the
    // draft: a panel the route asked for before that opens now.
    ref.listen(creationDraftProvider.select((s) => s.draft != null), (
      previous,
      started,
    ) {
      final panel = widget.panel;
      if (started && previous != true && panel != null && _open == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.panel == panel && _open == null) {
            _openPanel(panel);
          }
        });
      }
    });
    // A new pick: issues of the previous press no longer apply; a card that
    // lives on the user's words takes the focus.
    ref.listen(
      creationDraftProvider.select(
        (s) => (s.draft?.inspirationSlug, s.draft?.template),
      ),
      (previous, next) {
        if (next == previous) return;
        if (_issues.isNotEmpty) setState(() => _issues = const []);
        // The card's fields above the options changed: keep them in view.
        if (_optionsShown) _revealOptions();
        final latest = ref.read(creationDraftProvider).draft;
        if (latest?.sendsPromptWithPick ?? false) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _wordsFocus.requestFocus();
          });
        }
      },
    );
    if (draft != null) {
      _sync(_prompt, _promptFocus, draft.prompt);
      _sync(_words, _wordsFocus, draft.prompt);
      _sync(_name, _nameFocus, draft.recipient);
      _sync(_lyrics, null, draft.userLyrics ?? '');
    }

    final idea = _pickedIdea(draft);
    final placed = draft == null
        ? const <_Field, List<MusicPreflightIssue>>{}
        : _place(draft);
    final action = MusicCreateAction.of(
      draft: draft,
      entitlement: entitlement,
      busy: busy,
    );
    final parts = draft == null
        ? const <String>[]
        : [
            for (final part in summaryParts(draft, optionsShown: _optionsShown))
              summaryPartName(l10n, part, draft),
          ];

    return MusicTestId(
      'composer',
      child: ComposerCard(
        head: idea == null ? null : _Head(idea: idea),
        body: draft != null && idea != null
            ? _pickedBody(l10n, draft, idea, placed)
            : _freeBody(l10n, draft, dictation, placed),
        summary: MusicTestId(
          'composer.summary',
          key: _summaryKey,
          child: ComposerSummary(
            parts: parts,
            expanded: _optionsShown,
            onTap: _toggleOptions,
            semanticLabel: l10n.composerOptionsSummary(parts.join(', ')),
            semanticHint: _optionsShown
                ? l10n.composerOptionsHide
                : l10n.composerOptionsShow,
          ),
        ),
        options: draft != null && _optionsShown
            ? _options(l10n, draft, placed)
            : null,
        primaryAction: MusicTestId(
          'composer.create',
          child: ObsButton(
            label: createActionLabel(l10n, action),
            onPressed: action.enabled ? _submit : null,
          ),
        ),
      ),
    );
  }
}

/// The picked card at the composer's head (state B): photo, name, ✕.
class _Head extends ConsumerWidget {
  const _Head({required this.idea});

  final MusicIdea idea;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final name = ideaName(context, idea);
    return FutureBuilder<Set<String>>(
      future: MusicSongletArt.bundledInspirationArt(DefaultAssetBundle.of(context)),
      initialData: const <String>{},
      builder: (context, art) => MusicTestId(
        'composer.inspiration',
        child: ComposerTag(
          label: name,
          removeLabel: l10n.composerRemoveInspiration(name),
          image: MusicSongletArt.idea(idea, art.data ?? const <String>{}),
          fallbackImage: MusicSongletArt.ideaFallback(idea),
          onRemove: ref.read(creationDraftProvider.notifier).clearPick,
        ),
      ),
    );
  }
}

class _VoicePrompt extends StatelessWidget {
  const _VoicePrompt({
    required this.state,
    required this.onUse,
    required this.trailing,
  });

  final MusicDictationState state;

  /// The transcript becomes the prompt (dictation is free input, ADR-0033).
  final ValueChanged<String> onUse;

  /// The mic, as stop / leave.
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final recording = state is MusicDictationRecording
        ? state as MusicDictationRecording
        : null;
    final transcript = recording?.transcript ?? '';
    final elapsed = recording?.elapsed ?? Duration.zero;
    return VoiceCapturePanel(
      statusLabel: recording == null ? l10n.voiceStarting : l10n.voiceRecording,
      recording: recording != null && !recording.finished,
      elapsed: mediaDuration(elapsed.inMilliseconds / 1000, l10n.localeName),
      levels: recording?.levels ?? const [],
      transcript: transcript,
      placeholder: l10n.voiceListening,
      onDeviceLabel: l10n.voiceOnDevice,
      trailing: trailing,
      actions: [
        VoiceCaptureAction(
          icon: Icons.edit_note_rounded,
          label: l10n.voiceUseText,
          onUse: () => onUse(transcript),
        ),
      ],
    );
  }
}
