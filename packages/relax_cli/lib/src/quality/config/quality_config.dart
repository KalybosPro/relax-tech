/// Configuration for the `relax quality` subsystem.
///
/// Values come from sensible defaults and can be overridden by a `quality`
/// section in a `.relaxrc` file at the project root (JSON). Only the fields
/// relevant to the read-only analysis + quality-rules scope are wired here;
/// the schema is forward-compatible with the full specification.
library;

import 'dart:convert';
import 'dart:io';

/// Weights used to combine the score components. Must sum to 1.0.
class ScoreWeights {
  const ScoreWeights({
    this.coverage = 0.35,
    this.violations = 0.25,
    this.issues = 0.25,
    this.testHealth = 0.15,
  });

  final double coverage;
  final double violations;
  final double issues;
  final double testHealth;

  factory ScoreWeights.fromJson(Map<String, Object?> json) => ScoreWeights(
    coverage: _asDouble(json['coverage'], 0.35),
    violations: _asDouble(json['violations'], 0.25),
    issues: _asDouble(json['issues'], 0.25),
    testHealth: _asDouble(json['testHealth'], 0.15),
  );
}

/// CI gating thresholds. A run fails (non-zero exit) if any is exceeded.
class CiThresholds {
  const CiThresholds({
    this.minCoverage,
    this.maxViolations,
    this.maxIssues,
    this.failOnRegression = false,
  });

  final int? minCoverage;
  final int? maxViolations;
  final int? maxIssues;
  final bool failOnRegression;

  factory CiThresholds.fromJson(Map<String, Object?> json) => CiThresholds(
    minCoverage: _asIntOrNull(json['minCoverage']),
    maxViolations: _asIntOrNull(json['maxViolations']),
    maxIssues: _asIntOrNull(json['maxIssues']),
    failOnRegression: json['failOnRegression'] == true,
  );
}

/// Full quality configuration.
class QualityConfig {
  const QualityConfig({
    this.maxFileLength = 400,
    this.maxFunctionLength = 50,
    this.maxCyclomaticComplexity = 10,
    this.maxBuildMethodLength = 60,
    this.businessVerbs = defaultBusinessVerbs,
    this.ignoreGlobs = defaultIgnoreGlobs,
    this.weights = const ScoreWeights(),
    this.ci = const CiThresholds(),
    this.historyRetention = 90,
  });

  final int maxFileLength;
  final int maxFunctionLength;
  final int maxCyclomaticComplexity;
  final int maxBuildMethodLength;
  final List<String> businessVerbs;
  final List<String> ignoreGlobs;
  final ScoreWeights weights;
  final CiThresholds ci;

  /// Maximum number of runs kept in the history store.
  final int historyRetention;

  /// Default dictionary of business verbs (prefixes) used to detect
  /// business functions.
  static const List<String> defaultBusinessVerbs = [
    'login',
    'logout',
    'register',
    'signin',
    'signup',
    'signout',
    'authenticate',
    'create',
    'add',
    'update',
    'edit',
    'delete',
    'remove',
    'cancel',
    'fetch',
    'load',
    'get',
    'submit',
    'send',
    'save',
    'upload',
    'download',
    'search',
    'refresh',
    'sync',
    'pay',
    'checkout',
    'confirm',
    'validate',
  ];

  /// Directories/patterns excluded from analysis by default.
  static const List<String> defaultIgnoreGlobs = [
    '.dart_tool',
    'build',
    '.g.dart',
    '.freezed.dart',
    '.gr.dart',
    '.config.dart',
    '.mocks.dart',
    '.i18n.dart',
    'generated',
    'l10n',
  ];

  /// Loads config from `<projectRoot>/.relaxrc` if present, falling back to
  /// defaults. Malformed files are ignored (defaults returned).
  static QualityConfig load(String projectRoot) {
    final file = File('$projectRoot/.relaxrc');
    if (!file.existsSync()) return const QualityConfig();
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, Object?>) return const QualityConfig();
      final quality = decoded['quality'];
      if (quality is! Map<String, Object?>) return const QualityConfig();
      return QualityConfig.fromJson(quality);
    } on Object {
      return const QualityConfig();
    }
  }

  factory QualityConfig.fromJson(Map<String, Object?> json) {
    const d = QualityConfig();
    final rules = json['rules'];
    final rulesMap = rules is Map<String, Object?> ? rules : const {};
    final weights = json['weights'];
    final ci = json['ci'];
    return QualityConfig(
      maxFileLength: _asInt(rulesMap['maxFileLength'], d.maxFileLength),
      maxFunctionLength: _asInt(
        rulesMap['maxFunctionLength'],
        d.maxFunctionLength,
      ),
      maxCyclomaticComplexity: _asInt(
        rulesMap['maxCyclomaticComplexity'],
        d.maxCyclomaticComplexity,
      ),
      maxBuildMethodLength: _asInt(
        rulesMap['maxBuildMethodLength'],
        d.maxBuildMethodLength,
      ),
      businessVerbs: _asStringList(json['businessVerbs'], d.businessVerbs),
      ignoreGlobs: _asStringList(json['ignore'], d.ignoreGlobs),
      weights: weights is Map<String, Object?>
          ? ScoreWeights.fromJson(weights)
          : const ScoreWeights(),
      ci: ci is Map<String, Object?>
          ? CiThresholds.fromJson(ci)
          : const CiThresholds(),
      historyRetention: _asInt(json['historyRetention'], d.historyRetention),
    );
  }
}

double _asDouble(Object? v, double fallback) =>
    v is num ? v.toDouble() : fallback;

int _asInt(Object? v, int fallback) => v is num ? v.toInt() : fallback;

int? _asIntOrNull(Object? v) => v is num ? v.toInt() : null;

List<String> _asStringList(Object? v, List<String> fallback) {
  if (v is List) {
    final out = v.whereType<String>().toList();
    if (out.isNotEmpty) return out;
  }
  return fallback;
}
