import 'dart:async';
import 'dart:io';

import 'package:songlet_mock_server/songlet_mock_music_server.dart';

const String _usage = '''
Songlet backend mock (dev only).

Usage: dart run songlet_mock_server:server [--port <n>] [--state-file <path>]
       [--profile demo --demo-manifest <path>]

  --port <n>              listen port (default: \$PORT or 8787)
  --state-file <path>     persist state as JSON across restarts
  --profile demo          serve the App Store preview media (store_preview/songlet)
  --demo-manifest <path>  the preview manifest the demo profile serves
  -h, --help           this help

Env: SONGLET_MOCK_SECRET (default "songlet-mock-secret"),
     SONGLET_MOCK_DISTRIBUTION_CODE (default "songlet_ios").
''';

Future<void> main(List<String> args) async {
  final env = Platform.environment;
  var port = int.tryParse(env['PORT'] ?? '') ?? 8787;
  String? stateFile;
  String? profile;
  String? demoManifest;
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    String value() {
      if (arg.contains('=')) return arg.substring(arg.indexOf('=') + 1);
      if (i + 1 >= args.length) _fail('missing value for $arg');
      return args[++i];
    }

    if (arg == '-h' || arg == '--help') {
      stdout.write(_usage);
      return;
    } else if (arg.startsWith('--port')) {
      port = int.tryParse(value()) ?? _fail('--port must be an integer');
    } else if (arg.startsWith('--state-file')) {
      stateFile = value();
    } else if (arg.startsWith('--profile')) {
      profile = value();
      if (profile != 'demo') _fail('unknown profile $profile (only "demo")');
    } else if (arg.startsWith('--demo-manifest')) {
      demoManifest = value();
    } else {
      _fail('unknown argument $arg');
    }
  }

  if ((profile == 'demo') != (demoManifest != null)) {
    _fail('--profile demo and --demo-manifest go together');
  }
  final server = MusicMockServer(
    secret: env['SONGLET_MOCK_SECRET'] ?? MusicMockServer.defaultSecret,
    distributionCode:
        env['SONGLET_MOCK_DISTRIBUTION_CODE'] ??
        MusicMockServer.defaultDistributionCode,
    stateFile: stateFile,
    demoManifest: demoManifest,
  );
  await server.start(port: port);
  stdout.writeln(
    'Songlet mock listening on http://0.0.0.0:${server.port} '
    '(BASE_URL http://localhost:${server.port}/v1, assets ${server.assetsDir})',
  );

  late final StreamSubscription<ProcessSignal> sigint;
  sigint = ProcessSignal.sigint.watch().listen((_) async {
    stdout.writeln('shutting down');
    await sigint.cancel();
    await server.close();
    exit(0);
  });
}

Never _fail(String message) {
  stderr
    ..writeln(message)
    ..write(_usage);
  exit(64);
}
