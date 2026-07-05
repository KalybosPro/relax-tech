import 'dart:convert';

import '../models/quality_models.dart';

/// Parses the newline-delimited JSON emitted by `flutter test --machine` /
/// `dart test --reporter json` into a [TestRunResult].
///
/// The stream is a sequence of events: `testStart` (with a test id + name),
/// `testDone` (with `result` and `hidden`/`skipped` flags), `error`, and a
/// final `done`. Hidden framework tests (e.g. `loading …`) are ignored.
class MachineTestParser {
  TestRunResult parse(String output) {
    final names = <int, String>{};
    final failures = <TestFailure>[];
    final errorByTest = <int, String>{};

    var passed = 0;
    var failed = 0;
    var skipped = 0;
    var startTime = 0;
    var endTime = 0;

    for (final line in const LineSplitter().convert(output)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || !trimmed.startsWith('{')) continue;
      final Object? decoded;
      try {
        decoded = jsonDecode(trimmed);
      } on FormatException {
        continue;
      }
      if (decoded is! Map<String, Object?>) continue;

      switch (decoded['type']) {
        case 'testStart':
          final test = decoded['test'];
          if (test is Map<String, Object?>) {
            final id = _asInt(test['id']);
            final name = (test['name'] as String?) ?? '';
            if (id != null && !_isHidden(name)) names[id] = name;
          }
        case 'error':
          final id = _asInt(decoded['testID']);
          final err = (decoded['error'] as String?) ?? 'error';
          if (id != null) errorByTest[id] = err;
        case 'testDone':
          if (decoded['hidden'] == true) continue;
          final id = _asInt(decoded['testID']);
          if (id == null || !names.containsKey(id)) continue;
          final result = decoded['result'] as String?;
          if (decoded['skipped'] == true) {
            skipped++;
          } else if (result == 'success') {
            passed++;
          } else {
            failed++;
            failures.add(
              TestFailure(
                testName: names[id] ?? 'unknown',
                filePath: '',
                message: errorByTest[id] ?? result ?? 'failed',
              ),
            );
          }
        case 'start':
          startTime = _asInt(decoded['time']) ?? 0;
        case 'done':
          endTime = _asInt(decoded['time']) ?? endTime;
      }
    }

    return TestRunResult(
      total: passed + failed + skipped,
      passed: passed,
      failed: failed,
      skipped: skipped,
      durationMs: (endTime - startTime).clamp(0, 1 << 62),
      failures: failures,
    );
  }

  bool _isHidden(String name) => name.startsWith('loading ') || name.isEmpty;

  int? _asInt(Object? v) => v is int ? v : (v is num ? v.toInt() : null);
}
