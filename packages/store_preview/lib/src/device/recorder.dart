import 'dart:io';

import '../core/errors.dart';
import '../core/process.dart';

/// `simctl io recordVideo` at the simulator's native resolution. Its log
/// lines carry the host clock, so "Recording started" dates frame 0 against
/// the scene marks (the simulator shares the host clock).
class ScreenRecorder {
  ScreenRecorder(this.runner);

  final ProcessRunner runner;

  Future<Recording> start({required String udid, required String out, required String logFile}) async {
    final process = await runner.start(
      'xcrun',
      ['simctl', 'io', udid, 'recordVideo', '--codec=h264', '--force', out],
      logFile: logFile,
      stampLines: true,
    );
    final started = await pollUntil(
      runner,
      () => File(logFile).existsSync() && File(logFile).readAsStringSync().contains('Recording started'),
      timeout: const Duration(seconds: 30),
      step: const Duration(milliseconds: 100),
    );
    if (!started) {
      await process.terminate();
      throw ToolError('the screen recorder did not start (see $logFile)');
    }
    return Recording(process);
  }
}

class Recording {
  Recording(this.process);

  final RunningProcess process;

  /// SIGINT finalizes the file.
  Future<void> stop() async {
    await process.interrupt();
    await process.exitCode.timeout(const Duration(seconds: 60), onTimeout: () => throw ToolError('the screen recorder did not stop'));
  }
}
