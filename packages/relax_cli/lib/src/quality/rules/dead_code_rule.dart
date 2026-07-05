import '../analyzer/file_analyzer.dart';
import '../models/quality_models.dart';
import 'quality_rule.dart';

/// Flags private methods that are never referenced within their own file.
///
/// Private (`_`-prefixed) members cannot be used outside their library, so a
/// private method whose name never appears as a reference in the same file is
/// almost certainly dead. Using [ParsedFile.referencedNames] (which captures
/// calls *and* tear-offs like `onPressed: _submit`) keeps false positives low.
class DeadCodeRule extends QualityRule {
  /// Framework hooks that may be invoked reflectively/by the framework and
  /// must never be flagged even when no in-file reference exists.
  static const Set<String> _frameworkMethods = <String>{};

  @override
  String get id => 'dead-code';

  @override
  List<QualityIssue> evaluate(AnalyzedFile file, RuleContext ctx) {
    final referenced = file.parsed.referencedNames;
    final issues = <QualityIssue>[];

    for (final cls in file.parsed.classes) {
      for (final m in cls.methods) {
        if (!m.name.startsWith('_')) continue;
        if (_frameworkMethods.contains(m.name)) continue;
        if (referenced.contains(m.name)) continue;
        issues.add(
          QualityIssue(
            rule: id,
            filePath: file.relPath,
            line: m.startLine,
            message:
                'Unused private method ${cls.name}.${m.name}() is never '
                'referenced.',
            suggestion: 'Remove it or wire it up.',
            severity: Severity.info,
          ),
        );
      }
    }
    return issues;
  }
}
