import '../analyzer/file_analyzer.dart';
import '../models/quality_models.dart';
import 'quality_rule.dart';

/// Flags functions/methods longer than the configured threshold.
class FunctionLengthRule extends QualityRule {
  @override
  String get id => 'function-length';

  @override
  List<QualityIssue> evaluate(AnalyzedFile file, RuleContext ctx) {
    final max = ctx.config.maxFunctionLength;
    final issues = <QualityIssue>[];

    void check(String name, int length, int line, String? className) {
      if (length <= max) return;
      final label = className == null ? '$name()' : '$className.$name()';
      issues.add(
        QualityIssue(
          rule: id,
          filePath: file.relPath,
          line: line,
          message: '$label — $length lines (max $max).',
          score: length,
          suggestion: 'Split into multiple methods.',
          severity: length > max * 2 ? Severity.error : Severity.warning,
        ),
      );
    }

    for (final cls in file.parsed.classes) {
      for (final m in cls.methods) {
        check(m.name, m.lineCount, m.startLine, cls.name);
      }
    }
    for (final fn in file.parsed.topLevelFunctions) {
      check(fn.name, fn.lineCount, fn.startLine, null);
    }
    return issues;
  }
}
