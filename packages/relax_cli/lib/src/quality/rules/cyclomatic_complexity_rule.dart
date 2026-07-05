import '../analyzer/file_analyzer.dart';
import '../models/quality_models.dart';
import 'quality_rule.dart';

/// Flags functions whose cyclomatic complexity exceeds the threshold.
///
/// Complexity is computed as the number of branch points
/// (`if`, `for`, `while`, `case`, `catch`, `&&`, `||`, `??`, `?:`) plus one.
class CyclomaticComplexityRule extends QualityRule {
  @override
  String get id => 'cyclomatic-complexity';

  @override
  List<QualityIssue> evaluate(AnalyzedFile file, RuleContext ctx) {
    final max = ctx.config.maxCyclomaticComplexity;
    final issues = <QualityIssue>[];

    void check(String name, int score, int line, int length, String? cls) {
      if (score <= max) return;
      final label = cls == null ? '$name()' : '$cls.$name()';
      issues.add(
        QualityIssue(
          rule: id,
          filePath: file.relPath,
          line: line,
          message: 'High complexity — $label ($length lines). Score $score.',
          score: score,
          suggestion: 'Split into multiple methods.',
          severity: score > max * 2 ? Severity.error : Severity.warning,
        ),
      );
    }

    for (final cls in file.parsed.classes) {
      for (final m in cls.methods) {
        check(
          m.name,
          m.cyclomaticComplexity,
          m.startLine,
          m.lineCount,
          cls.name,
        );
      }
    }
    for (final fn in file.parsed.topLevelFunctions) {
      check(fn.name, fn.cyclomaticComplexity, fn.startLine, fn.lineCount, null);
    }
    return issues;
  }
}
