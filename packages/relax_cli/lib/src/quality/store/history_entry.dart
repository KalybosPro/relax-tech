import '../models/quality_models.dart';

/// One persisted quality run, used for trend charts and regression gating.
class HistoryEntry {
  const HistoryEntry({
    required this.runId,
    required this.timestamp,
    required this.projectScore,
    required this.coverageOverall,
    required this.testsTotal,
    required this.testsPassed,
    required this.testsFailed,
    required this.violationsCount,
    this.gitCommitSha,
  });

  final String runId;
  final DateTime timestamp;
  final int projectScore;

  /// Overall line coverage (0–100), or `null` when coverage wasn't measured.
  final num? coverageOverall;
  final int testsTotal;
  final int testsPassed;
  final int testsFailed;
  final int violationsCount;
  final String? gitCommitSha;

  /// Builds a history entry from a completed [QualityReport].
  factory HistoryEntry.fromReport(
    QualityReport report, {
    required String runId,
    String? gitCommitSha,
  }) {
    final run = report.testRun;
    return HistoryEntry(
      runId: runId,
      timestamp: report.generatedAt,
      projectScore: report.projectScore,
      coverageOverall: report.coverage?.overall,
      testsTotal: run?.total ?? 0,
      testsPassed: run?.passed ?? 0,
      testsFailed: run?.failed ?? 0,
      violationsCount: report.violations.length,
      gitCommitSha: gitCommitSha,
    );
  }

  Map<String, Object?> toJson() => {
    'runId': runId,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'projectScore': projectScore,
    'coverageOverall': coverageOverall,
    'testsTotal': testsTotal,
    'testsPassed': testsPassed,
    'testsFailed': testsFailed,
    'violationsCount': violationsCount,
    'gitCommitSha': gitCommitSha,
  };

  static HistoryEntry? fromJson(Map<String, Object?> json) {
    final ts = json['timestamp'];
    final score = json['projectScore'];
    if (ts is! String || score is! int) return null;
    final parsed = DateTime.tryParse(ts);
    if (parsed == null) return null;
    return HistoryEntry(
      runId: (json['runId'] as String?) ?? '',
      timestamp: parsed,
      projectScore: score,
      coverageOverall: json['coverageOverall'] as num?,
      testsTotal: (json['testsTotal'] as num?)?.toInt() ?? 0,
      testsPassed: (json['testsPassed'] as num?)?.toInt() ?? 0,
      testsFailed: (json['testsFailed'] as num?)?.toInt() ?? 0,
      violationsCount: (json['violationsCount'] as num?)?.toInt() ?? 0,
      gitCommitSha: json['gitCommitSha'] as String?,
    );
  }
}
