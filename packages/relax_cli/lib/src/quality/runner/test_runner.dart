import 'dart:io';

import '../../utils/flutter_helper.dart';
import '../models/quality_models.dart';
import 'machine_test_parser.dart';

/// Outcome of a test run, distinguishing "ran and parsed" from "couldn't run".
class TestRunOutcome {
  const TestRunOutcome({required this.result, this.error});

  /// Parsed result, or `null` when the run could not be executed.
  final TestRunResult? result;

  /// Human-readable reason the run failed to execute (missing flutter, etc.).
  final String? error;

  bool get ran => result != null;
}

/// Runs `flutter test --machine` and parses its structured output.
class TestRunner {
  TestRunner({MachineTestParser? parser})
    : _parser = parser ?? MachineTestParser();

  final MachineTestParser _parser;

  /// Executes the project's test suite. When [coverage] is true, adds
  /// `--coverage` so `coverage/lcov.info` is written. Returns an outcome that
  /// either carries a [TestRunResult] or an [error] describing why it could not
  /// run.
  Future<TestRunOutcome> run({bool coverage = false}) async {
    try {
      final result = await runFlutter([
        'test',
        '--machine',
        if (coverage) '--coverage',
      ]);
      final output = '${result.stdout}';
      final parsed = _parser.parse(output);
      // If nothing parsed and the process failed, surface stderr.
      if (parsed.total == 0 && result.exitCode != 0) {
        final stderr = '${result.stderr}'.trim();
        return TestRunOutcome(
          result: null,
          error: stderr.isEmpty
              ? 'flutter test exited with ${result.exitCode}'
              : stderr,
        );
      }
      return TestRunOutcome(result: parsed);
    } on ProcessException catch (e) {
      return TestRunOutcome(result: null, error: e.message);
    }
  }
}
