import '../config/quality_config.dart';
import '../models/quality_models.dart';

/// Computes the global project score (0–100) from the analysis signals.
///
/// The spec combines four weighted components: coverage, violations, issues,
/// and test health. In read-only `--check` runs, coverage and test health are
/// not measured; those components are dropped and the remaining weights are
/// renormalized so the score reflects only what was actually assessed.
class ScoreCalculator {
  const ScoreCalculator(this.weights);

  final ScoreWeights weights;

  static int severityWeight(Severity s) => switch (s) {
    Severity.info => 1,
    Severity.warning => 3,
    Severity.error => 5,
  };

  int compute({
    required List<ArchitectureViolation> violations,
    required List<QualityIssue> issues,
    CoverageReport? coverage,
    TestRunResult? testRun,
  }) {
    final components = <double, double>{}; // score → weight

    if (coverage != null) {
      components[coverage.overall.toDouble()] = weights.coverage;
    }

    final totalViolationOccurrences = violations.fold<int>(
      0,
      (sum, v) => sum + v.occurrences,
    );
    final violationsScore = 100 - _min100(totalViolationOccurrences * 5);
    components[violationsScore.toDouble()] = weights.violations;

    final issuePenalty = issues.fold<int>(
      0,
      (sum, i) => sum + severityWeight(i.severity),
    );
    final issuesScore = 100 - _min100(issuePenalty);
    components[issuesScore.toDouble()] = weights.issues;

    if (testRun != null && testRun.total > 0) {
      components[testRun.passed / testRun.total * 100] = weights.testHealth;
    }

    final totalWeight = components.values.fold<double>(0, (a, b) => a + b);
    if (totalWeight == 0) return 100;

    final weighted = components.entries.fold<double>(
      0,
      (sum, e) => sum + e.key * e.value,
    );
    return (weighted / totalWeight).round().clamp(0, 100);
  }

  int _min100(int v) => v > 100 ? 100 : v;
}

/// Qualitative label for a numeric score, matching the dashboard wording.
String scoreLabel(int score) {
  if (score >= 90) return 'Excellent';
  if (score >= 75) return 'Good';
  if (score >= 60) return 'Fair';
  if (score >= 40) return 'Needs work';
  return 'Critical';
}
