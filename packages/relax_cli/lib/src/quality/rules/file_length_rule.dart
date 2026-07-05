import '../analyzer/file_analyzer.dart';
import '../models/quality_models.dart';
import 'quality_rule.dart';

/// Flags files longer than the configured threshold.
class FileLengthRule extends QualityRule {
  @override
  String get id => 'file-length';

  @override
  List<QualityIssue> evaluate(AnalyzedFile file, RuleContext ctx) {
    final max = ctx.config.maxFileLength;
    if (file.info.lineCount <= max) return const [];
    return [
      QualityIssue(
        rule: id,
        filePath: file.relPath,
        line: 1,
        message: 'File is ${file.info.lineCount} lines (max $max).',
        score: file.info.lineCount,
        suggestion: 'Split this file into smaller, focused units.',
        severity: file.info.lineCount > max * 2
            ? Severity.error
            : Severity.warning,
      ),
    ];
  }
}
