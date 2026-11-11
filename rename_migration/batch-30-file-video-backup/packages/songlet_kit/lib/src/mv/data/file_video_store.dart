import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../library/data/music_library_location.dart';
import '../domain/music_video.dart';

/// Video files under the library container's `video/` directory, downloaded
/// from the pre-signed MP4 links the moment an MV succeeds (the link lives
/// 1 h, the object 24 h — contract v1.1).
class FileVideoStore implements VideoStore {
  FileVideoStore({required MusicLibraryLocation location, required Dio downloadDio})
      : _location = location,
        _dio = downloadDio;

  final MusicLibraryLocation _location;
  final Dio _dio;

  Future<Directory> _directory() async {
    final dir = Directory(p.join((await _location.root()).path, 'video'));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  @override
  Future<String> download({required String url, required String videoId}) async {
    final response = await _dio.get<List<int>>(url, options: Options(responseType: ResponseType.bytes));
    final bytes = response.data ?? const <int>[];
    if (bytes.isEmpty) throw const FileSystemException('empty video download');
    final fileName = '$videoId.mp4';
    await File(p.join((await _directory()).path, fileName)).writeAsBytes(bytes, flush: true);
    return fileName;
  }

  @override
  Future<String> pathOf(String fileName) async => p.join((await _directory()).path, fileName);

  @override
  Future<void> delete(String fileName) async {
    final file = File(await pathOf(fileName));
    if (file.existsSync()) await file.delete();
  }
}
