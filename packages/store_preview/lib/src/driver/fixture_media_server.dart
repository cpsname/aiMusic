import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../config/manifest.dart';
import '../core/errors.dart';

/// Read-only loopback media transport for production image/video widgets.
/// Only manifest files are exposed, never a generator, directory or live API.
class FixtureMediaServer {
  FixtureMediaServer._(this._server, this._files, this._manifest);
  final HttpServer _server;
  final Map<String, _MediaFile> _files;
  final Map<String, Object?> _manifest;

  Uri get origin => Uri.parse('http://127.0.0.1:${_server.port}/');

  static Future<FixtureMediaServer> start(
    Manifest manifest, {
    int port = 0,
  }) async {
    if (port < 0 || port > 65535) {
      throw ConfigError('serve-media: invalid port');
    }
    final root = Directory(p.dirname(manifest.path)).resolveSymbolicLinksSync();
    final files = <String, _MediaFile>{};
    final entries = <Map<String, Object?>>[];
    for (final entry in manifest.entries) {
      if (entry.id.isEmpty || files.containsKey(entry.id)) {
        throw ConfigError('serve-media: empty or duplicate media id');
      }
      final license = entry.license;
      if ([
            license.provider,
            license.id,
            license.model,
          ].any((s) => s.trim().isEmpty) ||
          DateTime.tryParse(license.generatedAt) == null) {
        throw ConfigError(
          'serve-media: ${entry.id} has no complete license record',
        );
      }
      final file = File(entry.file);
      if (!file.existsSync()) {
        throw ConfigError('serve-media: ${entry.id} file is missing');
      }
      final real = file.resolveSymbolicLinksSync();
      if (!p.isWithin(root, real)) {
        throw ConfigError(
          'serve-media: ${entry.id} escapes the media directory',
        );
      }
      final mime = _mime[p.extension(real).toLowerCase()];
      if (mime == null || !mime.startsWith('${entry.type}/')) {
        throw ConfigError(
          'serve-media: ${entry.id} has an unsupported media type',
        );
      }
      final hash = (await sha256.bind(file.openRead()).first).toString();
      final expected = entry.data['sha256'];
      if (expected != null && expected != hash) {
        throw ConfigError(
          'serve-media: ${entry.id} does not match data.sha256',
        );
      }
      final stat = await file.stat();
      if (stat.size == 0) {
        throw ConfigError('serve-media: ${entry.id} is empty');
      }
      files[entry.id] = _MediaFile(file, real, mime, stat, hash);
      entries.add({
        ...entry.raw,
        'media_url': '/media/${Uri.encodeComponent(entry.id)}',
      });
    }
    final http = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    final result = FixtureMediaServer._(http, files, {
      'schema': manifestSchema,
      'entries': entries,
    });
    http.listen((request) => unawaited(result._handle(request)));
    return result;
  }

  Future<void> close() async {
    await _server.close(force: true);
  }

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
    response.headers.set('X-Content-Type-Options', 'nosniff');
    try {
      final host = request.headers.value(HttpHeaders.hostHeader);
      final source = request.headers.value('origin');
      if (host != origin.authority ||
          (source != null && source != origin.origin)) {
        response.statusCode = HttpStatus.forbidden;
        return;
      }
      if (request.method != 'GET' && request.method != 'HEAD') {
        response.statusCode = HttpStatus.methodNotAllowed;
        response.headers.set(HttpHeaders.allowHeader, 'GET, HEAD');
        return;
      }
      if (request.uri.path == '/health') {
        response.headers.contentType = ContentType.text;
        if (request.method == 'GET') response.write('ready');
        return;
      }
      if (request.uri.path == '/manifest') {
        response.headers.contentType = ContentType.json;
        if (request.method == 'GET') response.write(jsonEncode(_manifest));
        return;
      }
      final path = request.uri.pathSegments;
      final item = path.length == 2 && path.first == 'media'
          ? _files[path.last]
          : null;
      if (item == null) {
        response.statusCode = HttpStatus.notFound;
        return;
      }
      final stat = await item.file.stat();
      if (stat.type != FileSystemEntityType.file ||
          stat.size != item.stat.size ||
          stat.modified != item.stat.modified ||
          item.file.resolveSymbolicLinksSync() != item.realPath ||
          (await sha256.bind(item.file.openRead()).first).toString() !=
              item.hash) {
        response.statusCode = HttpStatus.conflict;
        return; // changed source: validate and restart, never repair it
      }
      final length = stat.size;
      final range = request.headers.value(HttpHeaders.rangeHeader);
      var start = 0;
      var end = length - 1;
      if (range != null) {
        final match = RegExp(r'^bytes=(\d*)-(\d*)$').firstMatch(range);
        if (match == null || (match[1]!.isEmpty && match[2]!.isEmpty)) {
          response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
          response.headers.set(
            HttpHeaders.contentRangeHeader,
            'bytes */$length',
          );
          return;
        }
        if (match[1]!.isEmpty) {
          final suffix = int.tryParse(match[2]!);
          if (suffix == null || suffix <= 0) {
            response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
            response.headers.set(
              HttpHeaders.contentRangeHeader,
              'bytes */$length',
            );
            return;
          }
          start = (length - suffix).clamp(0, length);
        } else {
          start = int.tryParse(match[1]!) ?? length;
          end = match[2]!.isEmpty
              ? end
              : (int.tryParse(match[2]!) ?? -1).clamp(-1, end);
        }
        if (start >= length || end < start) {
          response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
          response.headers.set(
            HttpHeaders.contentRangeHeader,
            'bytes */$length',
          );
          return;
        }
        response.statusCode = HttpStatus.partialContent;
        response.headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes $start-$end/$length',
        );
      }
      response.headers.contentType = ContentType.parse(item.mime);
      response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
      response.contentLength = end - start + 1;
      if (request.method == 'GET') {
        await response.addStream(item.file.openRead(start, end + 1));
      }
    } on FileSystemException {
      response.statusCode = HttpStatus.conflict;
    } on SocketException {
      // A player can cancel obsolete range requests.
    } on HttpException {
      // The player closed the stream.
    } finally {
      try {
        await response.close();
      } on SocketException {
        // The player disconnected.
      } on HttpException {
        // The player disconnected.
      }
    }
  }
}

class _MediaFile {
  const _MediaFile(this.file, this.realPath, this.mime, this.stat, this.hash);
  final File file;
  final String realPath;
  final String mime;
  final FileStat stat;
  final String hash;
}

const _mime = {
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.heic': 'image/heic',
  '.mp4': 'video/mp4',
  '.mov': 'video/quicktime',
  '.mp3': 'audio/mpeg',
  '.m4a': 'audio/mp4',
  '.wav': 'audio/wav',
};
