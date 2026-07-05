import '../analyzer/file_analyzer.dart';
import '../models/quality_models.dart';
import 'quality_rule.dart';

/// Flags oversized `build()` methods on widgets — a common source of deep,
/// hard-to-read widget trees and broad rebuilds.
class BuildMethodSizeRule extends QualityRule {
  @override
  String get id => 'build-method-size';

  @override
  List<QualityIssue> evaluate(AnalyzedFile file, RuleContext ctx) {
    if (file.info.layer != ArchLayer.widget) return const [];
    final max = ctx.config.maxBuildMethodLength;
    final issues = <QualityIssue>[];

    for (final cls in file.parsed.classes) {
      for (final m in cls.methods) {
        if (m.name != 'build') continue;
        if (m.lineCount <= max) continue;
        issues.add(
          QualityIssue(
            rule: id,
            filePath: file.relPath,
            line: m.startLine,
            message: '${cls.name}.build() is ${m.lineCount} lines (max $max).',
            score: m.lineCount,
            suggestion:
                'Extract sub-trees into smaller widgets to reduce rebuild '
                'scope and improve readability.',
            severity: m.lineCount > max * 2 ? Severity.error : Severity.warning,
          ),
        );
      }
    }
    return issues;
  }
}
