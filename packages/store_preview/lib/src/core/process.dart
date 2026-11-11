import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'errors.dart';

class ProcessOutcome {
  const ProcessOutcome(this.exitCode, this.stdout, this.stderr);

  final int exitCode;
  final String stdout;
  final String stderr;
}

/// A process the pipeline started and keeps running (the screen recorder,
/// the test run, the backend).
abstract interface class RunningProcess {
  int get pid;

  /// Completes once the process exited and its output reached the log.
  Future<int> get exitCode;

  /// SIGINT to the process and its children (the recorder finalizes its
  /// file on it).
  Future<void> interrupt();

  /// SIGTERM to the process's children, then to itself.
  Future<void> terminate();
}

/// Every external command goes through here, so a test can assert the exact
/// command sequence without a simulator.
abstract interface class ProcessRunner {
  /// Runs to completion. [check]: a non-zero exit throws [ToolError].
  Future<ProcessOutcome> run(
    String executable,
    List<String> args, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool check = true,
  });

  /// Starts a process whose stdout and stderr go, line by line, to
  /// [logFile]; [stampLines] prefixes each line with the host clock in ms.
  Future<RunningProcess> start(
    String executable,
    List<String> args, {
    required String logFile,
    String? workingDirectory,
    Map<String, String>? environment,
    bool stampLines = false,
  });

  Future<void> sleep(Duration duration);

  /// Host clock, ms since the epoch.
  int now();
}

class SystemProcessRunner implements ProcessRunner {
  const SystemProcessRunner();

  @override
  Future<ProcessOutcome> run(
    String executable,
    List<String> args, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool check = true,
  }) async {
    final ProcessResult result;
    try {
      result = await Process.run(
        executable,
        args,
        workingDirectory: workingDirectory,
        environment: environment,
        stdoutEncoding: const Utf8Codec(allowMalformed: true),
        stderrEncoding: const Utf8Codec(allowMalformed: true),
      );
    } on ProcessException catch (e) {
      throw ToolError('$executable: ${e.message}');
    }
    final outcome = ProcessOutcome(result.exitCode, '${result.stdout}', '${result.stderr}');
    if (check && outcome.exitCode != 0) {
      final tail = (outcome.stderr.trim().isEmpty ? outcome.stdout : outcome.stderr).trim();
      throw ToolError('$executable ${args.take(4).join(' ')}… exited ${outcome.exitCode}: '
          '${tail.length > 1200 ? tail.substring(tail.length - 1200) : tail}');
    }
    return outcome;
  }

  @override
  Future<RunningProcess> start(
    String executable,
    List<String> args, {
    required String logFile,
    String? workingDirectory,
    Map<String, String>? environment,
    bool stampLines = false,
  }) async {
    final Process process;
    try {
      process = await Process.start(executable, args, workingDirectory: workingDirectory, environment: environment);
    } on ProcessException catch (e) {
      throw ToolError('$executable: ${e.message}');
    }
    final sink = File(logFile).openWrite();
    void line(String l) => sink.writeln(stampLines ? '${DateTime.now().millisecondsSinceEpoch} $l' : l);
    final decoder = const Utf8Codec(allowMalformed: true).decoder;
    final out = process.stdout.transform(decoder).transform(const LineSplitter()).listen(line).asFuture<void>();
    final err = process.stderr.transform(decoder).transform(const LineSplitter()).listen(line).asFuture<void>();
    final done = () async {
      final code = await process.exitCode;
      await Future.wait([out, err]);
      await sink.flush();
      await sink.close();
      return code;
    }();
    return _SystemProcess(process.pid, done);
  }

  @override
  Future<void> sleep(Duration duration) => Future<void>.delayed(duration);

  @override
  int now() => DateTime.now().millisecondsSinceEpoch;
}

class _SystemProcess implements RunningProcess {
  _SystemProcess(this.pid, this.exitCode);

  @override
  final int pid;

  @override
  final Future<int> exitCode;

  Future<void> _signal(String signal, ProcessSignal own) async {
    // Children first (`dart run`, `xcrun` and `sh -c` start the real work in
    // a child), then the process itself.
    await Process.run('pkill', ['-$signal', '-P', '$pid']);
    Process.killPid(pid, own);
  }

  @override
  Future<void> interrupt() => _signal('INT', ProcessSignal.sigint);

  @override
  Future<void> terminate() => _signal('TERM', ProcessSignal.sigterm);
}

/// Polls [done] every [step] until it holds or [timeout] passes.
Future<bool> pollUntil(ProcessRunner runner, bool Function() done, {required Duration timeout, Duration step = const Duration(milliseconds: 200)}) async {
  final deadline = runner.now() + timeout.inMilliseconds;
  while (!done()) {
    if (runner.now() > deadline) return false;
    await runner.sleep(step);
  }
  return true;
}
