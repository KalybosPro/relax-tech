import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../quality/config/quality_config.dart';
import '../../quality/models/quality_models.dart';
import '../../quality/analyzer/file_analyzer.dart';
import '../../quality/dashboard/dashboard_server.dart';
import '../../quality/quality_analyzer.dart';
import '../../quality/report/ci_reporter.dart';
import '../../quality/report/console_reporter.dart';
import '../../quality/runner/coverage_aggregator.dart';
import '../../quality/runner/lcov_parser.dart';
import '../../quality/runner/test_runner.dart';
import '../../quality/scoring/score_calculator.dart';
import '../../quality/store/history_entry.dart';
import '../../quality/store/quality_store.dart';
import '../../quality/test_engine/test_generation_service.dart';
import '../../quality/usecase_engine/usecase_service.dart';
import '../../version.dart';

/// `relax quality` — analyzes a Flutter project's architecture and code quality.
///
/// Analysis is always read-only. Two optional actions extend it:
/// `--generate-tests` writes test scaffolds for untested business functions
/// (new files only, never overwriting), and `--test` runs `flutter test`
/// and folds the result into the score. Source files are never modified.
class QualityCommand extends Command<int> {
  QualityCommand({required Logger logger}) : _logger = logger {
    argParser
      ..addFlag(
        'check',
        negatable: false,
        help:
            'Run the read-only analysis and print a console report '
            '(default).',
      )
      ..addFlag(
        'generate-tests',
        negatable: false,
        help:
            'Generate test scaffolds for untested business functions '
            '(new files only).',
      )
      ..addFlag(
        'generate-usecases',
        negatable: false,
        help:
            'Generate UseCase files for business functions that lack one '
            '(new files only, never rewrites source).',
      )
      ..addFlag(
        'test',
        negatable: false,
        help: 'Run `flutter test` and include the result in the report/score.',
      )
      ..addFlag(
        'dry-run',
        negatable: false,
        help:
            'With --generate-tests, list files that would be created '
            'without writing them.',
      )
      ..addFlag(
        'yes',
        abbr: 'y',
        negatable: false,
        help: 'Skip the confirmation prompt when generating tests.',
      )
      ..addFlag(
        'coverage',
        negatable: false,
        help:
            'Run `flutter test --coverage`, aggregate LCOV by layer/feature, '
            'and fold coverage into the score.',
      )
      ..addFlag(
        'dashboard',
        negatable: false,
        help:
            'Serve an interactive web dashboard on localhost '
            '(combine with --test/--coverage for those panels).',
      )
      ..addFlag(
        'open',
        defaultsTo: true,
        help: 'With --dashboard, open the browser automatically.',
      )
      ..addOption(
        'port',
        help: 'Port for --dashboard (default 8080).',
        defaultsTo: '8080',
      )
      ..addFlag(
        'no-history',
        negatable: false,
        help:
            'Do not read or record run history '
            '(.relax/quality/history.jsonl).',
      )
      ..addFlag(
        'ci',
        negatable: false,
        help:
            'CI mode: write JSON + JUnit reports and exit non-zero if '
            'configured thresholds are exceeded.',
      )
      ..addFlag(
        'json',
        negatable: false,
        help: 'Write ${CiReporter.jsonFileName} to the project root.',
      )
      ..addOption(
        'path',
        abbr: 'p',
        help: 'Restrict analysis to a sub-path (e.g. lib/features/orders).',
      );
  }

  final Logger _logger;

  @override
  String get name => 'quality';

  @override
  String get description => 'Analyze architecture and code quality.';

  @override
  String get invocation =>
      'relax quality [--check] [--generate-tests] [--generate-usecases] '
      '[--test] [--coverage] [--dashboard] [--ci] [-p <path>]';

  @override
  Future<int> run() async {
    final projectRoot = Directory.current.path;
    if (!File('$projectRoot/pubspec.yaml').existsSync()) {
      _logger
        ..err('No pubspec.yaml found.')
        ..info('Run this command from the root of a Flutter project.');
      return ExitCode.usage.code;
    }

    final ci = argResults!['ci'] == true;
    final json = argResults!['json'] == true;
    final generateTests = argResults!['generate-tests'] == true;
    final generateUseCases = argResults!['generate-usecases'] == true;
    final wantCoverage = argResults!['coverage'] == true;
    final runTests = argResults!['test'] == true || wantCoverage;
    final dryRun = argResults!['dry-run'] == true;
    final assumeYes = argResults!['yes'] == true;
    final dashboard = argResults!['dashboard'] == true;
    final openBrowser = argResults!['open'] == true;
    final noHistory = argResults!['no-history'] == true;
    final port = int.tryParse(argResults!['port'] as String? ?? '8080') ?? 8080;
    final scopePath = argResults!['path'] as String?;

    final config = QualityConfig.load(projectRoot);

    if (!ci) {
      _logger
        ..info('')
        ..info(lightCyan.wrap('relax quality') ?? 'relax quality')
        ..info(darkGray.wrap('v$version') ?? 'v$version');
    }

    final progress = ci ? null : _logger.progress('Analyzing project…');
    QualityReport report;
    final QualityAnalyzer analyzer;
    try {
      analyzer = QualityAnalyzer(
        projectRoot: projectRoot,
        config: config,
        scopePath: scopePath,
        onProgress: (m) => progress?.update(m),
      );
      report = analyzer.run();
      progress?.complete('Analysis complete.');
    } on Object catch (e) {
      progress?.fail('Analysis failed.');
      _logger.err('$e');
      return ExitCode.software.code;
    }

    final reporter = ConsoleReporter(_logger);

    // ── Optional: run the test suite (+coverage) and fold it into the score ──
    if (runTests) {
      final label = wantCoverage
          ? 'Running flutter test --coverage…'
          : 'Running flutter test…';
      final testProgress = ci ? null : _logger.progress(label);
      final outcome = await TestRunner().run(coverage: wantCoverage);
      if (outcome.ran) {
        final testRun = outcome.result!;

        CoverageReport? coverage;
        Map<String, num>? heatmap;
        if (wantCoverage) {
          final agg = _readCoverage(projectRoot, analyzer.analyzedFiles);
          if (agg != null) {
            coverage = agg.report;
            heatmap = agg.heatmap;
          } else {
            _logger.warn(
              'Coverage requested but coverage/lcov.info was not produced.',
            );
          }
        }

        final newScore = ScoreCalculator(config.weights).compute(
          violations: report.violations,
          issues: report.issues,
          testRun: testRun,
          coverage: coverage,
        );
        report = report.copyWith(
          projectScore: newScore,
          testRun: testRun,
          coverage: coverage,
          heatmap: heatmap,
        );
        final covSuffix = coverage == null
            ? ''
            : ', coverage ${coverage.overall}%';
        testProgress?.complete(
          'Tests: ${testRun.passed}/${testRun.total} passed$covSuffix.',
        );
      } else {
        testProgress?.fail('Could not run flutter test.');
        _logger.warn(outcome.error ?? 'Unknown error running tests.');
      }
    }

    // ── History: set the previous score and record this run ──────────────────
    var history = const <Map<String, Object?>>[];
    if (!noHistory) {
      final store = QualityStore(
        projectRoot: projectRoot,
        retention: config.historyRetention,
      );
      final previous = store.latest();
      if (previous != null) {
        report = report.copyWith(previousScore: previous.projectScore);
      }
      store.record(
        HistoryEntry.fromReport(
          report,
          runId: newRunId(),
          gitCommitSha: currentGitSha(projectRoot),
        ),
      );
      history = store.load().map((e) => e.toJson()).toList();
    }

    // ── Optional: generate missing tests (new files only) ────────────────────
    if (generateTests) {
      _generateTests(
        projectRoot: projectRoot,
        report: report,
        reporter: reporter,
        dryRun: dryRun,
        assumeYes: assumeYes || ci,
        interactive: !ci,
      );
    }

    // ── Optional: generate missing UseCases (new files only) ─────────────────
    if (generateUseCases) {
      _generateUseCases(
        projectRoot: projectRoot,
        analyzedFiles: analyzer.analyzedFiles,
        reporter: reporter,
        dryRun: dryRun,
        assumeYes: assumeYes || ci,
        interactive: !ci,
      );
    }

    // ── Optional: serve the interactive dashboard (blocking) ─────────────────
    if (dashboard) {
      return _serveDashboard(
        report,
        history: history,
        port: port,
        open: openBrowser,
      );
    }

    // ── Machine-readable outputs ─────────────────────────────────────────────
    if (ci || json) {
      final ciReporter = CiReporter(projectRoot: projectRoot);
      final jsonPath = ciReporter.writeJson(report);
      _logger.info('Wrote ${_rel(projectRoot, jsonPath)}');
      if (ci) {
        final junitPath = ciReporter.writeJunit(report);
        _logger.info('Wrote ${_rel(projectRoot, junitPath)}');

        final gate = ciReporter.evaluateGate(report, config.ci);
        if (!gate.passed) {
          _logger
            ..info('')
            ..err('Quality gate failed:');
          for (final reason in gate.reasons) {
            _logger.err('  • $reason');
          }
          return ExitCode.software.code;
        }
        _logger.success('Quality gate passed (score ${report.projectScore}).');
        return ExitCode.success.code;
      }
    }

    // ── Human-readable console report ────────────────────────────────────────
    if (!ci) {
      reporter.report(report);
    }

    return ExitCode.success.code;
  }

  /// Handles `--generate-tests`. Returns an exit code to short-circuit, or
  /// `null` to continue.
  int? _generateTests({
    required String projectRoot,
    required QualityReport report,
    required ConsoleReporter reporter,
    required bool dryRun,
    required bool assumeYes,
    required bool interactive,
  }) {
    final service = TestGenerationService(
      projectRoot: projectRoot,
      packageName: readPackageName(projectRoot),
    );
    final plan = service.plan(report.testGaps);

    if (plan.isEmpty) {
      reporter.reportGeneration(
        created: const [],
        skipped: plan.skipped,
        dryRun: dryRun,
      );
      return null;
    }

    final paths = plan.toCreate.map((f) => f.filePath).toList();

    if (dryRun) {
      reporter.reportGeneration(
        created: paths,
        skipped: plan.skipped,
        dryRun: true,
      );
      return null;
    }

    if (interactive && !assumeYes) {
      _logger.info('');
      final proceed = _logger.confirm(
        'Generate ${plan.toCreate.length} test scaffold(s)?',
        defaultValue: true,
      );
      if (!proceed) {
        _logger.info('Skipped test generation.');
        return null;
      }
    }

    final written = service.write(plan);
    reporter.reportGeneration(
      created: written,
      skipped: plan.skipped,
      dryRun: false,
    );
    return null;
  }

  /// Handles `--generate-usecases`. New files only; a reversible patch is
  /// journaled under `.relax/quality/patches/` before anything is written.
  void _generateUseCases({
    required String projectRoot,
    required List<AnalyzedFile> analyzedFiles,
    required ConsoleReporter reporter,
    required bool dryRun,
    required bool assumeYes,
    required bool interactive,
  }) {
    final service = UseCaseService(projectRoot: projectRoot);
    final plan = service.plan(analyzedFiles);

    if (plan.isEmpty) {
      reporter.reportUseCaseGeneration(
        created: const [],
        skipped: plan.skippedExisting,
        alreadyImplemented: plan.alreadyImplemented,
        dryRun: dryRun,
      );
      return;
    }

    final paths = plan.toCreate.map((g) => g.filePath).toList();

    if (dryRun) {
      reporter.reportUseCaseGeneration(
        created: paths,
        skipped: plan.skippedExisting,
        alreadyImplemented: plan.alreadyImplemented,
        dryRun: true,
      );
      _logger
        ..info('')
        ..info(service.diff(plan));
      return;
    }

    if (interactive && !assumeYes) {
      _logger.info('');
      final proceed = _logger.confirm(
        'Generate ${plan.toCreate.length} UseCase file(s)?',
        defaultValue: true,
      );
      if (!proceed) {
        _logger.info('Skipped UseCase generation.');
        return;
      }
    }

    final result = service.write(plan);
    reporter.reportUseCaseGeneration(
      created: result.written,
      skipped: plan.skippedExisting,
      alreadyImplemented: plan.alreadyImplemented,
      dryRun: false,
      patchDir: result.patchDir,
    );
  }

  /// Starts the dashboard server, opens the browser, and blocks until the user
  /// interrupts (Ctrl+C). Returns a success exit code once stopped.
  Future<int> _serveDashboard(
    QualityReport report, {
    required List<Map<String, Object?>> history,
    required int port,
    required bool open,
  }) async {
    final server = DashboardServer(report: report, history: history);
    final Uri url;
    try {
      url = await server.start(preferredPort: port);
    } on Object catch (e) {
      _logger.err('Could not start dashboard server: $e');
      return ExitCode.software.code;
    }

    _logger
      ..info('')
      ..success('Dashboard running at ${lightCyan.wrap(url.toString())}')
      ..info(darkGray.wrap('Press Ctrl+C to stop.') ?? 'Press Ctrl+C to stop.');
    if (open) await openInBrowser(url);

    // Block until interrupted, then shut down cleanly.
    final done = Completer<void>();
    late final StreamSubscription<ProcessSignal> sub;
    sub = ProcessSignal.sigint.watch().listen((_) async {
      await sub.cancel();
      await server.stop();
      if (!done.isCompleted) done.complete();
    });
    await done.future;
    _logger.info('Dashboard stopped.');
    return ExitCode.success.code;
  }

  /// Reads and aggregates `coverage/lcov.info`, returning `null` when the file
  /// is absent (e.g. flutter did not emit coverage).
  CoverageAggregation? _readCoverage(
    String projectRoot,
    List<AnalyzedFile> analyzedFiles,
  ) {
    final file = File('$projectRoot/coverage/lcov.info');
    if (!file.existsSync()) return null;
    final lcov = LcovParser().parse(file.readAsStringSync());
    if (lcov.isEmpty) return null;
    return CoverageAggregator().aggregate(
      lcov: lcov,
      analyzedFiles: analyzedFiles,
    );
  }

  String _rel(String root, String path) =>
      path.startsWith(root) ? path.substring(root.length + 1) : path;
}
