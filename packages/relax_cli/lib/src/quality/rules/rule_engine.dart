import '../analyzer/file_analyzer.dart';
import '../config/quality_config.dart';
import '../models/quality_models.dart';
import 'build_method_size_rule.dart';
import 'cyclomatic_complexity_rule.dart';
import 'dead_code_rule.dart';
import 'duplication_rule.dart';
import 'file_length_rule.dart';
import 'function_length_rule.dart';
import 'quality_rule.dart';
import 'unused_imports_rule.dart';

/// Runs the full catalog of quality rules over the analyzed files and
/// aggregates their findings into a single, sorted list of issues.
class RuleEngine {
  RuleEngine({List<QualityRule>? rules}) : rules = rules ?? defaultRules();

  final List<QualityRule> rules;

  /// The default rule catalog (order defines evaluation order, not reporting
  /// order — issues are re-sorted by severity/location at the end).
  static List<QualityRule> defaultRules() => [
    FileLengthRule(),
    FunctionLengthRule(),
    CyclomaticComplexityRule(),
    DuplicationRule(),
    DeadCodeRule(),
    UnusedImportsRule(),
    BuildMethodSizeRule(),
  ];

  List<QualityIssue> run(List<AnalyzedFile> files, QualityConfig config) {
    final sources = files.where((f) => !f.info.isTest).toList();
    final ctx = RuleContext(config: config, allFiles: sources);
    final issues = <QualityIssue>[];

    for (final file in sources) {
      for (final rule in rules) {
        issues.addAll(rule.evaluate(file, ctx));
      }
    }

    issues.sort((a, b) {
      final bySeverity = b.severity.index.compareTo(a.severity.index);
      if (bySeverity != 0) return bySeverity;
      final byFile = a.filePath.compareTo(b.filePath);
      if (byFile != 0) return byFile;
      return a.line.compareTo(b.line);
    });
    return issues;
  }
}
