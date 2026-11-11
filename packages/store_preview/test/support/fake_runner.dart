import 'dart:async';
import 'dart:io';

import 'package:store_preview/store_preview.dart';

/// Records every command; answers [run] from [answers] (first key the
/// command line contains), started processes through [onStart].
class FakeRunner implements ProcessRunner {
  FakeRunner({Map<String, ProcessOutcome>? answers, this.onStart}) : answers = answers ?? {};

  final Map<String, ProcessOutcome> answers;

  /// Called for each started process with its command line and log file; it
  /// may write the log and finish the process.
  void Function(String command, String logFile, FakeProcess process)? onStart;

  final List<String> calls = [];
  final List<Map<String, String>?> environments = [];
  final List<FakeProcess> started = [];
  int clock = 1000000;

  @override
  Future<ProcessOutcome> run(
    String executable,
    List<String> args, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool check = true,
  }) async {
    final line = [executable, ...args].join(' ');
    calls.add(line);
    environments.add(environment);
    for (final e in answers.entries) {
      if (line.contains(e.key)) {
        if (check && e.value.exitCode != 0) throw ToolError('$line exited ${e.value.exitCode}');
        return e.value;
      }
    }
    return const ProcessOutcome(0, '', '');
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
    final line = [executable, ...args].join(' ');
    calls.add('start $line');
    environments.add(environment);
    File(logFile)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('');
    final process = FakeProcess(this);
    started.add(process);
    onStart?.call(line, logFile, process);
    return process;
  }

  @override
  Future<void> sleep(Duration duration) async {
    clock += duration.inMilliseconds;
    await Future<void>.delayed(Duration.zero);
  }

  @override
  int now() => clock;
}

class FakeProcess implements RunningProcess {
  FakeProcess(this.runner);

  final FakeRunner runner;
  final Completer<int> _exit = Completer<int>();
  final List<String> signals = [];

  void finish(int code) {
    if (!_exit.isCompleted) _exit.complete(code);
  }

  @override
  int get pid => 4242;

  @override
  Future<int> get exitCode => _exit.future;

  @override
  Future<void> interrupt() async {
    signals.add('INT');
    finish(0);
  }

  @override
  Future<void> terminate() async {
    signals.add('TERM');
    finish(143);
  }
}
