import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../common/json.dart';
import '../domain/music_inspiration.dart';
import '../domain/music_template_samples.dart';

/// `GET /v1/templates` (authed business Dio): the template sample clips
/// (`templates[]`, ADR-0008) and the create home's inspirations
/// (`inspirations[]`, contract 02 v1.2, ADR-0029). The endpoint has no ETag
/// or version, so the response is fetched once per session and shared by
/// both; a failed fetch is retried on the next use. Audio files go through a
/// bare Dio (absolute URLs, played as given) and persist in [cacheDir].
class MusicRemoteTemplateCatalog implements MusicTemplateSampleSource, MusicInspirationSource {
  MusicRemoteTemplateCatalog({
    required Dio apiDio,
    required Dio downloadDio,
    required Future<String> Function() cacheDir,
  })  : _api = apiDio,
        _download = downloadDio,
        _cacheDir = cacheDir;

  final Dio _api;
  final Dio _download;
  final Future<String> Function() _cacheDir;
  Future<Map<String, Object?>>? _catalogue;

  Future<Map<String, Object?>> _fetch() => _catalogue ??= () async {
        final response = await _api.get<dynamic>('/templates');
        return asMap(response.data);
      }()
        ..catchError((Object _) {
          _catalogue = null;
          return const <String, Object?>{};
        });

  Future<Map<String, String>> _sampleUrls() async => {
        for (final t in asMapList((await _fetch())['templates']))
          asString(t['id']): asString(t['sample_url']),
      }..removeWhere((id, url) => id.isEmpty || url.isEmpty);

  @override
  Future<String> samplePath(String templateId) async {
    final url = (await _sampleUrls())[templateId];
    return _cached(p.join('samples', '$templateId.mp3'), url, missing: 'no sample for $templateId');
  }

  @override
  Future<List<MusicInspiration>> inspirations() async {
    final catalogue = await _fetch();
    final list = [
      for (final raw in asMapList(catalogue['inspirations'])) ?inspirationFromJson(raw),
    ]..sort((a, b) {
        final bySort = a.sort.compareTo(b.sort);
        return bySort != 0 ? bySort : a.slug.compareTo(b.slug);
      });
    return list;
  }

  /// Keyed by the URL (UUID v5): when the platform moves the previews to its
  /// own storage (ADR-S12), the new audio is downloaded, not the old file
  /// replayed.
  @override
  Future<String> previewPath(MusicInspiration inspiration) => _cached(
        p.join('inspirations', '${const Uuid().v5(Namespace.url.value, inspiration.previewAudioUrl)}.mp3'),
        inspiration.previewAudioUrl,
        missing: 'no preview for ${inspiration.slug}',
      );

  Future<String> _cached(String relative, String? url, {required String missing}) async {
    final file = File(p.join(await _cacheDir(), relative));
    if (file.existsSync() && file.lengthSync() > 0) return file.path;
    if (url == null || url.isEmpty) throw StateError(missing);
    final response = await _download.get<List<int>>(url, options: Options(responseType: ResponseType.bytes));
    final bytes = response.data ?? const <int>[];
    if (bytes.isEmpty) throw const FileSystemException('empty audio download');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}

/// One `MusicInspiration`, or null when a required field is missing or the
/// preview is not an absolute http(s) URL (the entry is then left out).
MusicInspiration? inspirationFromJson(Map<String, Object?> json) {
  MusicLocalizedText? text(Object? raw) {
    final map = asMap(raw);
    final en = asNullableString(map['en']);
    if (en == null) return null;
    return MusicLocalizedText(en: en, zh: asNullableString(map['zh']) ?? en);
  }

  final id = asNullableString(json['id']);
  final slug = asNullableString(json['slug']);
  final name = text(json['name']);
  final style = text(json['style']);
  final url = asNullableString(json['preview_audio_url']);
  final uri = url == null ? null : Uri.tryParse(url);
  final sort = json['sort'] is num ? (json['sort']! as num).toInt() : null;
  if (id == null || slug == null || name == null || style == null || sort == null) return null;
  if (uri == null || !uri.isAbsolute || !(uri.scheme == 'https' || uri.scheme == 'http')) return null;
  final cover = asNullableString(json['cover_image_url']);
  final coverUri = cover == null ? null : Uri.tryParse(cover);
  final validCover = coverUri != null && coverUri.isAbsolute && (coverUri.scheme == 'https' || coverUri.scheme == 'http');
  final composerJson = asMap(json['composer']);
  final hint = text(composerJson['hint']);
  final composer = hint == null
      ? null
      : MusicInspirationComposer(hint: hint, inputRequired: composerJson['input_required'] != false);
  final duration = json['duration_sec'] is num ? (json['duration_sec']! as num).toInt() : null;
  return MusicInspiration(
    id: id,
    slug: slug,
    name: name,
    style: style,
    previewAudioUrl: url!,
    sort: sort,
    durationSec: duration != null && duration > 0 ? duration : null,
    linkedTemplateId: asNullableString(json['linked_template_id']),
    coverImageUrl: validCover ? cover : null,
    occasionWire: asNullableString(json['occasion']),
    defaultModelWire: asNullableString(json['default_model']),
    defaultVocalsWire: asNullableString(json['default_vocals']),
    suggestedGenre: asNullableString(json['suggested_genre']),
    composer: composer,
    requiresRecipient: json['requires_recipient'] is bool ? json['requires_recipient']! as bool : null,
    defaultOnVideo: json['default_on_video'] is bool ? json['default_on_video']! as bool : null,
  );
}
