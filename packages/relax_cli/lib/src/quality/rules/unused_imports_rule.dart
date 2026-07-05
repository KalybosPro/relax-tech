import '../analyzer/file_analyzer.dart';
import '../models/quality_models.dart';
import 'quality_rule.dart';

/// Flags high-confidence import problems: duplicate imports of the same URI,
/// and `show` clauses whose names are never referenced in the file.
///
/// Full unused-import detection needs resolved types; this rule deliberately
/// only reports cases that are certain from the syntactic AST, to keep false
/// positives at zero (see the spec's risk table on false positives).
class UnusedImportsRule extends QualityRule {
  @override
  String get id => 'unused-imports';

  @override
  List<QualityIssue> evaluate(AnalyzedFile file, RuleContext ctx) {
    final issues = <QualityIssue>[];
    final referenced = file.parsed.referencedNames;
    final seenUris = <String, int>{};

    for (final import in file.parsed.importDirectives) {
      // Duplicate import of the same URI.
      final firstLine = seenUris[import.uri];
      if (firstLine != null) {
        issues.add(
          QualityIssue(
            rule: id,
            filePath: file.relPath,
            line: import.line,
            message:
                "Duplicate import of '${import.uri}' (first at line $firstLine).",
            suggestion: 'Remove the duplicate import.',
            severity: Severity.warning,
          ),
        );
        continue;
      }
      seenUris[import.uri] = import.line;

      // Unused names in a `show` clause (skip prefixed imports — names are
      // accessed through the prefix and won't appear bare).
      if (import.shownNames.isNotEmpty && !import.hasPrefix) {
        final unused = import.shownNames
            .where((n) => !referenced.contains(n))
            .toList();
        if (unused.length == import.shownNames.length) {
          issues.add(
            QualityIssue(
              rule: id,
              filePath: file.relPath,
              line: import.line,
              message:
                  "Unused import '${import.uri}': none of "
                  '${unused.join(', ')} are used.',
              suggestion: 'Remove this import.',
              severity: Severity.warning,
            ),
          );
        } else if (unused.isNotEmpty) {
          issues.add(
            QualityIssue(
              rule: id,
              filePath: file.relPath,
              line: import.line,
              message:
                  "Unused shown name(s) in '${import.uri}': "
                  '${unused.join(', ')}.',
              suggestion: 'Trim the show clause to used names only.',
              severity: Severity.info,
            ),
          );
        }
      }
    }
    return issues;
  }
}
