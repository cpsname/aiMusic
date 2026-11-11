import 'dart:convert';
import 'dart:io';

import '../config/app.dart';
import '../core/errors.dart';
import '../core/process.dart';

/// HTTP for the backend's health and admin calls.
abstract interface class HttpGateway {
  /// The status code, or `null` when nothing answers.
  Future<int?> get(String url);

  /// The status code and body.
  Future<(int, String)> send(String method, String url, Map<String, Object?>? body);
}

class SystemHttpGateway implements HttpGateway {
  const SystemHttpGateway();

  HttpClient _client() => HttpClient()..connectionTimeout = const Duration(seconds: 5);

  @override
  Future<int?> get(String url) async {
    final client = _client();
    try {
      final response = await (await client.getUrl(Uri.parse(url))).close();
      await response.drain<void>();
      return response.statusCode;
    } on SocketException {
      return null;
    } on HttpException {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<(int, String)> send(String method, String url, Map<String, Object?>? body) async {
    final client = _client();
    try {
      final request = await client.openUrl(method, Uri.parse(url));
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }
      final response = await request.close();
      return (response.statusCode, await response.transform(utf8.decoder).join());
    } finally {
      client.close(force: true);
    }
  }
}

/// The local backend the recordings run against (app.yaml `backend`): one
/// per run, a fresh state before every take.
class BackendController {
  BackendController({
    required this.runner,
    required this.config,
    required this.root,
    required this.manifest,
    required this.logFile,
    this.http = const SystemHttpGateway(),
  });

  final ProcessRunner runner;
  final BackendConfig config;
  final String root;
  final String manifest;
  final String logFile;
  final HttpGateway http;
  RunningProcess? _process;

  String get _health => config.fill(config.health, manifest: manifest);

  Future<void> start() async {
    if (await http.get(_health) == 200) {
      throw ToolError('something already serves $_health — stop it (the recordings start their own backend)');
    }
    final process = await runner.start('/bin/sh', ['-c', config.fill(config.start, manifest: manifest)], workingDirectory: root, logFile: logFile);
    _process = process;
    var exited = false;
    process.exitCode.then((_) => exited = true).ignore();
    final deadline = runner.now() + 180000;
    while (await http.get(_health) != 200) {
      if (exited) throw ToolError('the backend exited before it answered $_health (see $logFile)');
      if (runner.now() > deadline) throw ToolError('the backend did not answer $_health within 180 s (see $logFile)');
      await runner.sleep(const Duration(milliseconds: 500));
    }
  }

  /// The calls app.yaml lists under `before_take`.
  Future<void> beforeTake() async {
    final admin = config.admin;
    if (config.beforeTake.isEmpty) return;
    if (admin == null) throw ConfigError('backend.before_take needs backend.admin');
    final base = Uri.parse(config.fill(admin, manifest: manifest));
    for (final call in config.beforeTake) {
      final body = call.body == null ? null : _fillBody(call.body!) as Map<String, Object?>;
      final (status, text) = await http.send(call.method, base.resolve(call.path).toString(), body);
      if (status != 200) throw ToolError('backend ${call.method} ${call.path} → $status $text');
    }
  }

  Object? _fillBody(Object? v) => switch (v) {
    String() => config.fill(v, manifest: manifest),
    Map() => {for (final e in v.entries) '${e.key}': _fillBody(e.value)},
    List() => [for (final e in v) _fillBody(e)],
    _ => v,
  };

  Future<void> stop() async {
    final process = _process;
    if (process == null) return;
    await process.terminate();
    await process.exitCode.timeout(const Duration(seconds: 20), onTimeout: () => -1);
    _process = null;
  }
}
