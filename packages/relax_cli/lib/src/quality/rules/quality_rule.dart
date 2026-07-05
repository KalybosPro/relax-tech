import '../analyzer/file_analyzer.dart';
import '../config/quality_config.dart';
import '../models/quality_models.dart';

/// Context passed to every rule during evaluation.
class RuleContext {
  const RuleContext({required this.config, required this.allFiles});

  final QualityConfig config;

  /// All analyzed source files (test files excluded), for cross-file rules
  /// such as duplication and dead code.
  final List<AnalyzedFile> allFiles;
}

/// A single, independent quality rule (plugin-like). Rules are pure: they read
/// a file and return issues without mutating anything.
abstract class QualityRule {
  /// Stable rule identifier, e.g. `function-length`.
  String get id;

  /// Evaluates [file] and returns any issues found.
  List<QualityIssue> evaluate(AnalyzedFile file, RuleContext ctx);
}
