import '../analyzer/dart_parser.dart';
import '../analyzer/file_analyzer.dart';
import '../models/quality_models.dart';
import 'quality_rule.dart';

/// Detects duplicated method bodies across the project (type-2 clones).
///
/// Each method body of at least [_minLines] lines is normalized (whitespace
/// collapsed, string/number literals blanked) and hashed. Bodies sharing a
/// hash are reported as duplicates. This is a cross-file rule: it inspects
/// [RuleContext.allFiles], so it only emits issues when evaluated once (it
/// guards against re-emitting per file).
class DuplicationRule extends QualityRule {
  static const int _minLines = 8;

  @override
  String get id => 'duplication';

  @override
  List<QualityIssue> evaluate(AnalyzedFile file, RuleContext ctx) {
    // Only run the cross-file scan once, keyed off the first file.
    if (ctx.allFiles.isEmpty || ctx.allFiles.first != file) return const [];

    final byHash = <String, List<_Location>>{};
    for (final f in ctx.allFiles) {
      for (final cls in f.parsed.classes) {
        for (final m in cls.methods) {
          _index(byHash, f.relPath, cls.name, m);
        }
      }
      for (final fn in f.parsed.topLevelFunctions) {
        _index(byHash, f.relPath, null, fn);
      }
    }

    final issues = <QualityIssue>[];
    for (final group in byHash.values) {
      if (group.length < 2) continue;
      final first = group.first;
      final others = group
          .skip(1)
          .map((l) => '${l.filePath}:${l.line}')
          .join(', ');
      issues.add(
        QualityIssue(
          rule: id,
          filePath: first.filePath,
          line: first.line,
          message:
              'Duplicated logic: ${first.label} is repeated ${group.length}× '
              '(also at $others).',
          score: group.length,
          suggestion: 'Extract the shared logic into a single function.',
          severity: Severity.warning,
        ),
      );
    }
    issues.sort((a, b) => a.filePath.compareTo(b.filePath));
    return issues;
  }

  void _index(
    Map<String, List<_Location>> byHash,
    String filePath,
    String? className,
    ParsedMethod method,
  ) {
    if (method.lineCount < _minLines || method.bodySource.isEmpty) return;
    final normalized = _normalize(method.bodySource);
    if (normalized.length < 40) return;
    final label = className == null
        ? '${method.name}()'
        : '$className.${method.name}()';
    byHash
        .putIfAbsent(normalized, () => [])
        .add(_Location(filePath, method.startLine, label));
  }

  /// Type-2 normalization: strip comments, collapse whitespace, blank out
  /// string and numeric literals so cosmetic differences don't hide clones.
  String _normalize(String source) {
    var s = source.replaceAll(RegExp(r'//[^\n]*'), '');
    s = s.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
    s = s.replaceAll(RegExp('''(['"]).*?\\1'''), '""');
    s = s.replaceAll(RegExp(r'\b\d+(\.\d+)?\b'), '0');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }
}

class _Location {
  const _Location(this.filePath, this.line, this.label);
  final String filePath;
  final int line;
  final String label;
}
