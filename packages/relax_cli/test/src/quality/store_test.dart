import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:relax_cli/src/quality/config/quality_config.dart';
import 'package:relax_cli/src/quality/models/quality_models.dart';
import 'package:relax_cli/src/quality/report/ci_reporter.dart';
import 'package:relax_cli/src/quality/store/history_entry.dart';
import 'package:relax_cli/src/quality/store/quality_store.dart';
import 'package:test/test.dart';

QualityReport _report(int score, {int? previous, CoverageReport? coverage}) =>
    QualityReport(
      generatedAt: DateTime.utc(2026, 7, 5),
      projectScore: score,
      previousScore: previous,
      filesAnalyzed: 3,
      stateManagement: const {},
      violations: const [],
      issues: const [],
      testGaps: const [],
      graph: DependencyGraph(nodes: {}, edges: const []),
      heatmap: const {},
      coverage: coverage,
    );

void main() {
  late Directory tempDir;
  setUp(() => tempDir = Directory.systemTemp.createTempSync('relax_store'));
  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('QualityStore', () {
    test('records and reloads entries, latest() returns the newest', () {
      final store = QualityStore(projectRoot: tempDir.path);
      expect(store.latest(), isNull);

      store.record(HistoryEntry.fromReport(_report(70), runId: 'a'));
      store.record(HistoryEntry.fromReport(_report(85), runId: 'b'));

      final all = store.load();
      expect(all, hasLength(2));
      expect(all.first.projectScore, 70);
      expect(store.latest()!.projectScore, 85);
      expect(store.latest()!.runId, 'b');
    });

    test('writes JSONL at .relax/quality/history.jsonl', () {
      QualityStore(
        projectRoot: tempDir.path,
      ).record(HistoryEntry.fromReport(_report(50), runId: 'x'));
      final file = File(
        p.join(tempDir.path, '.relax', 'quality', 'history.jsonl'),
      );
      expect(file.existsSync(), isTrue);
      final decoded = jsonDecode(file.readAsLinesSync().single);
      expect(decoded['projectScore'], 50);
      expect(decoded['runId'], 'x');
    });

    test('enforces retention (keeps the most recent N)', () {
      final store = QualityStore(projectRoot: tempDir.path, retention: 3);
      for (var i = 0; i < 6; i++) {
        store.record(HistoryEntry.fromReport(_report(i), runId: '$i'));
      }
      final all = store.load();
      expect(all, hasLength(3));
      expect(all.map((e) => e.projectScore), [3, 4, 5]);
    });

    test('carries coverage and test data through a round trip', () {
      final report =
          _report(
            90,
            coverage: const CoverageReport(
              overall: 82,
              byLayer: {},
              byFeature: {},
            ),
          ).copyWith(
            testRun: const TestRunResult(
              total: 10,
              passed: 9,
              failed: 1,
              skipped: 0,
              durationMs: 500,
            ),
          );
      final store = QualityStore(projectRoot: tempDir.path);
      store.record(
        HistoryEntry.fromReport(report, runId: 'r', gitCommitSha: 'abc123'),
      );

      final entry = store.latest()!;
      expect(entry.coverageOverall, 82);
      expect(entry.testsPassed, 9);
      expect(entry.testsFailed, 1);
      expect(entry.gitCommitSha, 'abc123');
    });

    test('failOnRegression gate fails when the score drops below previous', () {
      final reporter = CiReporter(projectRoot: tempDir.path);
      final regressed = _report(80, previous: 90);
      final gate = reporter.evaluateGate(
        regressed,
        const CiThresholds(failOnRegression: true),
      );
      expect(gate.passed, isFalse);
      expect(gate.reasons.single, contains('regressed'));

      final improved = _report(95, previous: 90);
      expect(
        reporter
            .evaluateGate(improved, const CiThresholds(failOnRegression: true))
            .passed,
        isTrue,
      );
    });

    test('skips corrupt lines without failing', () {
      final file = File(
        p.join(tempDir.path, '.relax', 'quality', 'history.jsonl'),
      )..parent.createSync(recursive: true);
      file.writeAsStringSync(
        '{"timestamp":"2026-07-05T00:00:00Z","projectScore":60}\n'
        'not json\n'
        '{"timestamp":"bad","projectScore":70}\n',
      );
      final all = QualityStore(projectRoot: tempDir.path).load();
      expect(all, hasLength(1));
      expect(all.single.projectScore, 60);
    });
  });
}
