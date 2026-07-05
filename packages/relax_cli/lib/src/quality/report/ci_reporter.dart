import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../config/quality_config.dart';
import '../models/quality_models.dart';

/// Result of a CI gate evaluation.
class CiGateResult {
  const CiGateResult({required this.passed, required this.reasons});

  final bool passed;
  final List<String> reasons;
}

/// Writes machine-readable outputs for CI: a versioned JSON report and a JUnit
/// XML file, and evaluates configured thresholds into a pass/fail gate.
class CiReporter {
  CiReporter({required this.projectRoot});

  final String projectRoot;

  static const String jsonFileName = 'relax-quality-report.json';
  static const String junitFileName = 'relax-quality-junit.xml';

  /// Writes the JSON report to the project root and returns its path.
  String writeJson(QualityReport report) {
    final file = File(p.join(projectRoot, jsonFileName));
    const encoder = JsonEncoder.withIndent('  ');
    file.writeAsStringSync(encoder.convert(report.toJson()));
    return file.path;
  }

  /// Writes a JUnit XML report and returns its path.
  ///
  /// Each architecture violation and quality issue becomes a `<testcase>` with
  /// a nested `<failure>`; untested functions become skipped cases. This lets
  /// GitLab CI / GitHub Actions / Jenkins surface findings natively.
  String writeJunit(QualityReport report) {
    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>');

    final failures =
        report.violations.length +
        report.issues.where((i) => i.severity == Severity.error).length;
    final tests =
        report.violations.length +
        report.issues.length +
        report.testGaps.length;

    buffer.writeln(
      '<testsuite name="relax-quality" tests="$tests" '
      'failures="$failures" skipped="${report.testGaps.length}">',
    );

    for (final v in report.violations) {
      buffer
        ..writeln(
          '  <testcase classname="architecture.${v.type}" '
          'name="${_attr(v.filePath)}">',
        )
        ..writeln(
          '    <failure message="${_attr(v.message)}">'
          '${_text(v.message)} (${v.occurrences}×)</failure>',
        )
        ..writeln('  </testcase>');
    }

    for (final i in report.issues) {
      buffer.write(
        '  <testcase classname="rule.${i.rule}" '
        'name="${_attr('${i.filePath}:${i.line}')}">',
      );
      if (i.severity == Severity.error) {
        buffer
          ..writeln()
          ..writeln(
            '    <failure message="${_attr(i.message)}">'
            '${_text(i.message)}\n${_text(i.suggestion)}</failure>',
          )
          ..writeln('  </testcase>');
      } else {
        buffer.writeln('</testcase>');
      }
    }

    for (final gap in report.testGaps) {
      buffer
        ..writeln(
          '  <testcase classname="test-gap" '
          'name="${_attr(gap.businessFunction.name)}">',
        )
        ..writeln(
          '    <skipped message="Missing ${_attr(gap.expectedTestFile)}"/>',
        )
        ..writeln('  </testcase>');
    }

    buffer.writeln('</testsuite>');

    final file = File(p.join(projectRoot, junitFileName));
    file.writeAsStringSync(buffer.toString());
    return file.path;
  }

  /// Evaluates CI thresholds against the report.
  CiGateResult evaluateGate(QualityReport report, CiThresholds thresholds) {
    final reasons = <String>[];

    final maxViolations = thresholds.maxViolations;
    if (maxViolations != null && report.violations.length > maxViolations) {
      reasons.add(
        'violations ${report.violations.length} > max $maxViolations',
      );
    }

    final maxIssues = thresholds.maxIssues;
    if (maxIssues != null && report.issues.length > maxIssues) {
      reasons.add('issues ${report.issues.length} > max $maxIssues');
    }

    final minCoverage = thresholds.minCoverage;
    final coverage = report.coverage?.overall;
    if (minCoverage != null && coverage != null && coverage < minCoverage) {
      reasons.add('coverage $coverage% < min $minCoverage%');
    }

    if (thresholds.failOnRegression &&
        report.previousScore != null &&
        report.projectScore < report.previousScore!) {
      reasons.add(
        'score regressed ${report.previousScore} → ${report.projectScore}',
      );
    }

    return CiGateResult(passed: reasons.isEmpty, reasons: reasons);
  }

  String _attr(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  String _text(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
