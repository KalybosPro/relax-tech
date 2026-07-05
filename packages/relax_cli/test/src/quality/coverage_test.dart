import 'package:relax_cli/src/quality/analyzer/dart_parser.dart';
import 'package:relax_cli/src/quality/analyzer/file_analyzer.dart';
import 'package:relax_cli/src/quality/models/quality_models.dart';
import 'package:relax_cli/src/quality/runner/coverage_aggregator.dart';
import 'package:relax_cli/src/quality/runner/lcov_parser.dart';
import 'package:relax_cli/src/quality/scoring/score_calculator.dart';
import 'package:relax_cli/src/quality/config/quality_config.dart';
import 'package:test/test.dart';

AnalyzedFile _file(String relPath, ArchLayer layer) {
  final parsed = DartParser().parse('class C {}');
  return AnalyzedFile(
    relPath: relPath,
    absPath: '/tmp/$relPath',
    parsed: parsed,
    info: DartFileInfo(
      path: relPath,
      hash: 'h',
      layer: layer,
      stateManagement: StateManagementKind.none,
      classNames: const ['C'],
      imports: const [],
      lineCount: 1,
      businessFunctions: const [],
    ),
  );
}

void main() {
  group('LcovParser', () {
    test('counts covered/total from DA records', () {
      const lcov = '''
SF:lib/features/auth/auth_repository.dart
DA:1,1
DA:2,0
DA:3,5
LF:3
LH:2
end_of_record
SF:lib/features/orders/orders_bloc.dart
DA:1,0
DA:2,0
end_of_record
''';
      final parsed = LcovParser().parse(lcov);
      expect(parsed, hasLength(2));
      final auth = parsed['lib/features/auth/auth_repository.dart']!;
      expect(auth.covered, 2);
      expect(auth.total, 3);
      expect(parsed['lib/features/orders/orders_bloc.dart']!.covered, 0);
    });
  });

  group('CoverageAggregator', () {
    test('aggregates overall, by layer, and by feature', () {
      final lcov = {
        'lib/features/auth/auth_repository.dart': const FileCoverage(
          covered: 9,
          total: 10,
        ),
        'lib/features/orders/orders_bloc.dart': const FileCoverage(
          covered: 4,
          total: 10,
        ),
      };
      final analyzed = [
        _file('lib/features/auth/auth_repository.dart', ArchLayer.repository),
        _file('lib/features/orders/orders_bloc.dart', ArchLayer.controller),
      ];

      final agg = CoverageAggregator().aggregate(
        lcov: lcov,
        analyzedFiles: analyzed,
      );

      expect(agg.report.overall, 65); // 13/20
      expect(agg.report.byLayer['repository'], 90);
      expect(agg.report.byLayer['controller'], 40);
      expect(agg.report.byFeature['auth'], 90);
      expect(agg.report.byFeature['orders'], 40);
      expect(agg.heatmap['orders'], 40);
      expect(
        agg.report.byFile['lib/features/auth/auth_repository.dart']?.covered,
        9,
      );
    });

    test('featureOf resolves features, modules, and fallbacks', () {
      expect(CoverageAggregator.featureOf('lib/features/auth/x.dart'), 'auth');
      expect(CoverageAggregator.featureOf('lib/modules/cart/x.dart'), 'cart');
      expect(CoverageAggregator.featureOf('lib/core/theme/x.dart'), 'core');
      expect(CoverageAggregator.featureOf('lib/main.dart'), 'unknown');
    });
  });

  group('ScoreCalculator with coverage', () {
    test('coverage lifts/lowers the score via its weight', () {
      const calc = ScoreCalculator(ScoreWeights());
      final low = calc.compute(
        violations: [],
        issues: [],
        coverage: const CoverageReport(overall: 0, byLayer: {}, byFeature: {}),
        testRun: const TestRunResult(
          total: 1,
          passed: 1,
          failed: 0,
          skipped: 0,
          durationMs: 1,
        ),
      );
      final high = calc.compute(
        violations: [],
        issues: [],
        coverage: const CoverageReport(
          overall: 100,
          byLayer: {},
          byFeature: {},
        ),
        testRun: const TestRunResult(
          total: 1,
          passed: 1,
          failed: 0,
          skipped: 0,
          durationMs: 1,
        ),
      );
      expect(high, greaterThan(low));
    });
  });
}
