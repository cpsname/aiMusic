import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../export/domain/id3_tagger.dart';
import '../domain/work_repository.dart';
import 'library_location.dart';

/// [AudioStore] on the local file system. Audio is fetched with a **bare** Dio
/// (the link is a pre-signed object-storage URL valid 24 h — the BFF chain's
/// auth / signature / envelope would not apply) the moment a job succeeds
/// (PRD §6.3), then ID3-tagged (user-defined text frame `AI_GENERATED=Lyria 3`, PRD §9.4).
class MusicFileAudioStore implements AudioStore {
  MusicFileAudioStore({required LibraryLocation location, required Dio downloadDio})
      : _location = location,
        _dio = downloadDio;

  final LibraryLocation _location;
  final Dio _dio;

  @override
  Future<String> download({
    required String url,
    required String workId,
    required String title,
  }) async {
    final response = await _dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = Uint8List.fromList(response.data ?? const <int>[]);
    if (bytes.isEmpty) {
      throw const FileSystemException('empty audio download');
    }
    final fileName = '$workId.mp3';
    final dir = await _location.audioDirectory();
    final tagged = Id3Tagger.tag(bytes, title: title);
    await File(p.join(dir.path, fileName)).writeAsBytes(tagged, flush: true);
    return fileName;
  }

  @override
  Future<String> pathOf(String fileName) async =>
      p.join((await _location.audioDirectory()).path, fileName);

  @override
  Future<String> scratchDirectory() async => (await _location.scratchDirectory()).path;

  @override
  Future<String> importFile({required String sourcePath, required String workId}) async {
    final fileName = '$workId.mp3';
    await File(sourcePath).copy(p.join((await _location.audioDirectory()).path, fileName));
    return fileName;
  }

  @override
  Future<String> fetchToScratch({required String url, required String fileName}) async {
    final response = await _dio.get<List<int>>(url, options: Options(responseType: ResponseType.bytes));
    final bytes = response.data ?? const <int>[];
    if (bytes.isEmpty) throw const FileSystemException('empty download');
    final path = p.join((await _location.scratchDirectory()).path, fileName);
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }

  @override
  Future<void> delete(String fileName) async {
    final file = File(await pathOf(fileName));
    if (file.existsSync()) await file.delete();
  }
}
