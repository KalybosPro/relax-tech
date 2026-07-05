import 'package:mason_logger/mason_logger.dart';

import '../models/quality_models.dart';
import '../scoring/score_calculator.dart';

/// Renders a [QualityReport] to the console using the existing [Logger] style.
class ConsoleReporter {
  ConsoleReporter(this._logger);

  final Logger _logger;

  void report(QualityReport report) {
    _logger.info('');
    _reportScore(report);
    _reportSummary(report);
    _reportStateManagement(report);
    _reportCoverage(report);
    _reportTestRun(report);
    _reportViolations(report);
    _reportIssues(report);
    _reportTestGaps(report);

    _logger.info('');
  }

  /// Reports the outcome of a test-generation run.
  void reportGeneration({
    required List<String> created,
    required List<String> skipped,
    required bool dryRun,
  }) {
    _logger
      ..info('')
      ..info(styleBold.wrap('Test generation') ?? 'Test generation');
    if (created.isEmpty && skipped.isEmpty) {
      _logger.info(
        '  ${darkGray.wrap('Nothing to generate — no untested functions.')}',
      );
      return;
    }
    final verb = dryRun ? 'Would create' : 'Created';
    for (final path in created) {
      _logger.info('  ${green.wrap('[+]')} $verb $path');
    }
    for (final path in skipped) {
      _logger.info('  ${darkGray.wrap('[=] Skipped (exists) $path')}');
    }
  }

  void _reportCoverage(QualityReport report) {
    final coverage = report.coverage;
    if (coverage == null) return;
    _logger
      ..info('')
      ..info(styleBold.wrap('Coverage') ?? 'Coverage')
      ..info(
        '  Overall: ${_coverageColor(coverage.overall).wrap('${coverage.overall}%')}',
      );

    if (coverage.byLayer.isNotEmpty) {
      final layers = coverage.byLayer.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      final parts = layers.map((e) => '${e.key} ${e.value}%').join(' · ');
      _logger.info(darkGray.wrap('  By layer: $parts') ?? '');
    }

    if (coverage.byFeature.isNotEmpty) {
      _logger.info(darkGray.wrap('  By feature:') ?? '');
      final features = coverage.byFeature.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      for (final e in features) {
        final pct = e.value;
        final bar = _bar(pct);
        _logger.info(
          '    ${_coverageColor(pct).wrap(bar)} '
          '${pct.toString().padLeft(5)}%  ${e.key}',
        );
      }
    }
  }

  /// A 10-cell heatmap bar (red <40, orange 40–70, green >70 via color).
  String _bar(num percent) {
    final filled = (percent / 10).round().clamp(0, 10);
    return '█' * filled + '░' * (10 - filled);
  }

  AnsiCode _coverageColor(num pct) {
    if (pct >= 70) return green;
    if (pct >= 40) return yellow;
    return red;
  }

  /// Reports the outcome of a UseCase-generation run.
  void reportUseCaseGeneration({
    required List<String> created,
    required List<String> skipped,
    required List<String> alreadyImplemented,
    required bool dryRun,
    String? patchDir,
  }) {
    _logger
      ..info('')
      ..info(styleBold.wrap('UseCase generation') ?? 'UseCase generation');
    if (created.isEmpty && skipped.isEmpty && alreadyImplemented.isEmpty) {
      _logger.info(
        '  ${darkGray.wrap('No extractable business functions found.')}',
      );
      return;
    }
    final verb = dryRun ? 'Would create' : 'Created';
    for (final path in created) {
      _logger.info('  ${green.wrap('[+]')} $verb $path');
    }
    for (final name in alreadyImplemented) {
      _logger.info('  ${darkGray.wrap('[=] Exists $name')}');
    }
    for (final path in skipped) {
      _logger.info('  ${darkGray.wrap('[=] Skipped (file exists) $path')}');
    }
    if (!dryRun && created.isNotEmpty) {
      _logger.info(
        darkGray.wrap(
              '      Add the domain-type imports to each new file before use.',
            ) ??
            '',
      );
      if (patchDir != null) {
        _logger.info(darkGray.wrap('      Reversible patch: $patchDir') ?? '');
      }
    }
  }

  void _reportTestRun(QualityReport report) {
    final run = report.testRun;
    if (run == null) return;
    final failedColor = run.failed > 0 ? red : green;
    _logger
      ..info('')
      ..info(styleBold.wrap('Tests') ?? 'Tests')
      ..info(
        '  ${run.total} total · ${green.wrap('${run.passed} passed')} · '
        '${failedColor.wrap('${run.failed} failed')} · '
        '${run.skipped} skipped · ${(run.durationMs / 1000).toStringAsFixed(1)}s',
      );
    for (final f in run.failures.take(10)) {
      _logger.info('  ${red.wrap('[x]')} ${f.testName}');
      if (f.message.isNotEmpty) {
        final firstLine = f.message.split('\n').first;
        _logger.info(darkGray.wrap('      $firstLine') ?? '');
      }
    }
  }

  void _reportScore(QualityReport report) {
    final score = report.projectScore;
    final label = scoreLabel(score);
    final colored = _scoreColor(score).wrap('$score/100') ?? '$score/100';
    var line = 'Project score: $colored — $label';
    if (report.previousScore != null) {
      final delta = score - report.previousScore!;
      final sign = delta >= 0 ? '+' : '';
      line += ' ($sign$delta)';
    }
    _logger
      ..info(line)
      ..info('');
  }

  void _reportSummary(QualityReport report) {
    final errors = report.issues
        .where((i) => i.severity == Severity.error)
        .length;
    final warnings = report.issues
        .where((i) => i.severity == Severity.warning)
        .length;
    final infos = report.issues
        .where((i) => i.severity == Severity.info)
        .length;
    _logger.info(
      '${report.filesAnalyzed} file(s) analyzed · '
      '${report.violations.length} architecture violation(s) · '
      '$errors error(s), $warnings warning(s), $infos info · '
      '${report.testGaps.length} untested function(s)',
    );
  }

  void _reportStateManagement(QualityReport report) {
    if (report.stateManagement.isEmpty) return;
    final names = report.stateManagement.map((s) => s.id).toList()..sort();
    _logger.info(darkGray.wrap('State management: ${names.join(', ')}') ?? '');
  }

  void _reportViolations(QualityReport report) {
    if (report.violations.isEmpty) return;
    _logger
      ..info('')
      ..info(styleBold.wrap('Architecture violations') ?? 'Violations');
    for (final v in report.violations) {
      final tag = _severityTag(v.severity);
      _logger.info('  $tag ${v.message}');
      _logger.info(
        darkGray.wrap(
              '      ${v.filePath}'
              '${v.functionName.isEmpty ? '' : ' · ${v.functionName}'}'
              ' · ${v.occurrences}×',
            ) ??
            '',
      );
    }
  }

  void _reportIssues(QualityReport report) {
    if (report.issues.isEmpty) return;
    _logger
      ..info('')
      ..info(styleBold.wrap('Quality issues') ?? 'Quality issues');
    for (final i in report.issues) {
      final tag = _severityTag(i.severity);
      final scoreSuffix = i.score == null
          ? ''
          : ' ${darkGray.wrap('[${i.score}]')}';
      _logger.info('  $tag [${i.rule}] ${i.message}$scoreSuffix');
      _logger.info(
        darkGray.wrap('      ${i.filePath}:${i.line} — ${i.suggestion}') ?? '',
      );
    }
  }

  void _reportTestGaps(QualityReport report) {
    if (report.testGaps.isEmpty) return;
    _logger
      ..info('')
      ..info(styleBold.wrap('Missing tests') ?? 'Missing tests');
    for (final gap in report.testGaps) {
      final fn = gap.businessFunction;
      final owner = fn.className == null
          ? fn.name
          : '${fn.className}.${fn.name}';
      _logger.info('  ${yellow.wrap('[-]')} $owner()');
      _logger.info(
        darkGray.wrap(
              '      ${fn.filePath} → expected ${gap.expectedTestFile}',
            ) ??
            '',
      );
    }
  }

  String _severityTag(Severity severity) => switch (severity) {
    Severity.error => red.wrap('[x]') ?? '[x]',
    Severity.warning => yellow.wrap('[!]') ?? '[!]',
    Severity.info => darkGray.wrap('[i]') ?? '[i]',
  };

  AnsiCode _scoreColor(int score) {
    if (score >= 75) return green;
    if (score >= 50) return yellow;
    return red;
  }
}
