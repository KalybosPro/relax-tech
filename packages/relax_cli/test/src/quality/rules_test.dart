import 'package:relax_cli/src/quality/analyzer/dart_parser.dart';
import 'package:relax_cli/src/quality/analyzer/file_analyzer.dart';
import 'package:relax_cli/src/quality/config/quality_config.dart';
import 'package:relax_cli/src/quality/models/quality_models.dart';
import 'package:relax_cli/src/quality/rules/dead_code_rule.dart';
import 'package:relax_cli/src/quality/rules/function_length_rule.dart';
import 'package:relax_cli/src/quality/rules/quality_rule.dart';
import 'package:relax_cli/src/quality/rules/unused_imports_rule.dart';
import 'package:relax_cli/src/quality/scoring/score_calculator.dart';
import 'package:test/test.dart';

/// Builds an [AnalyzedFile] from raw source without touching the filesystem.
AnalyzedFile analyzedFrom(
  String source, {
  String relPath = 'lib/foo.dart',
  ArchLayer layer = ArchLayer.controller,
}) {
  final parsed = DartParser().parse(source);
  final info = DartFileInfo(
    path: relPath,
    hash: 'h',
    layer: layer,
    stateManagement: StateManagementKind.none,
    classNames: parsed.classes.map((c) => c.name).toList(),
    imports: parsed.imports,
    lineCount: parsed.lineCount,
    businessFunctions: const [],
  );
  return AnalyzedFile(
    relPath: relPath,
    absPath: '/tmp/$relPath',
    info: info,
    parsed: parsed,
  );
}

void main() {
  const config = QualityConfig();

  RuleContext ctx(List<AnalyzedFile> files) =>
      RuleContext(config: config, allFiles: files);

  group('FunctionLengthRule', () {
    test('flags functions above the threshold', () {
      final body = List.filled(60, '    doStuff();').join('\n');
      final file = analyzedFrom('class C {\n  void big() {\n$body\n  }\n}');
      final issues = FunctionLengthRule().evaluate(file, ctx([file]));
      expect(issues, hasLength(1));
      expect(issues.single.rule, 'function-length');
      expect(issues.single.suggestion, 'Split into multiple methods.');
    });
  });

  group('DeadCodeRule', () {
    test('flags unused private methods but not referenced ones', () {
      final file = analyzedFrom('''
class C {
  void run() { _used(); }
  void _used() {}
  void _dead() {}
}
''');
      final issues = DeadCodeRule().evaluate(file, ctx([file]));
      expect(issues, hasLength(1));
      expect(issues.single.message, contains('_dead'));
      expect(issues.single.severity, Severity.info);
    });
  });

  group('UnusedImportsRule', () {
    test('flags duplicate imports and unused show clauses', () {
      final file = analyzedFrom('''
import 'a.dart';
import 'a.dart';
import 'b.dart' show Unused;
class C {}
''');
      final issues = UnusedImportsRule().evaluate(file, ctx([file]));
      expect(issues.map((i) => i.message), [
        contains('Duplicate import'),
        contains("Unused import 'b.dart'"),
      ]);
    });
  });

  group('ScoreCalculator', () {
    const calc = ScoreCalculator(ScoreWeights());

    test('is 100 when nothing is wrong', () {
      expect(calc.compute(violations: [], issues: []), 100);
    });

    test('drops below 100 as violations and issues accumulate', () {
      final score = calc.compute(
        violations: [
          const ArchitectureViolation(
            type: 'controller_to_api',
            filePath: 'lib/a.dart',
            functionName: 'load',
            message: 'x',
            occurrences: 4,
            severity: Severity.error,
          ),
        ],
        issues: [
          const QualityIssue(
            rule: 'function-length',
            filePath: 'lib/a.dart',
            line: 1,
            message: 'x',
            suggestion: 'y',
            severity: Severity.error,
          ),
        ],
      );
      expect(score, lessThan(100));
      expect(score, greaterThan(0));
    });
  });
}
