import 'analyzer/dependency_graph_builder.dart';
import 'analyzer/file_analyzer.dart';
import 'analyzer/project_scanner.dart';
import 'architecture/architecture_analyzer.dart';
import 'config/quality_config.dart';
import 'models/quality_models.dart';
import 'rules/rule_engine.dart';
import 'scoring/score_calculator.dart';
import 'test_engine/test_gap_detector.dart';

/// Read-only orchestrator for `relax quality`.
///
/// Runs the pipeline described in the spec's Phase 1 + Phase 3 (analysis and
/// quality rules), producing a [QualityReport] without writing anything or
/// executing `flutter test`. Higher phases (test/usecase generation, coverage
/// execution, dashboard) plug into this same report shape later.
class QualityAnalyzer {
  QualityAnalyzer({
    required this.projectRoot,
    required this.config,
    this.scopePath,
    void Function(String message)? onProgress,
  }) : _onProgress = onProgress;

  final String projectRoot;
  final QualityConfig config;
  final String? scopePath;
  final void Function(String message)? _onProgress;

  final List<AnalyzedFile> _analyzedFiles = [];

  /// The files analyzed by the most recent [run]. Exposed so callers (e.g. the
  /// coverage step) can map LCOV data to each file's layer.
  List<AnalyzedFile> get analyzedFiles => List.unmodifiable(_analyzedFiles);

  QualityReport run() {
    final scanner = ProjectScanner(
      projectRoot: projectRoot,
      config: config,
      scopePath: scopePath,
    );

    final sourcePaths = scanner.scanSource();
    final testPaths = scanner.scanTests();
    _onProgress?.call('Scanning ${sourcePaths.length} source file(s)…');

    final fileAnalyzer = FileAnalyzer(projectRoot: projectRoot, config: config);
    final analyzed = <AnalyzedFile>[];
    for (final path in sourcePaths) {
      final result = fileAnalyzer.analyze(path);
      if (result != null) analyzed.add(result);
    }
    _analyzedFiles
      ..clear()
      ..addAll(analyzed);
    _onProgress?.call('Analyzed ${analyzed.length} file(s).');

    final graph = DependencyGraphBuilder().build(analyzed);
    final violations = ArchitectureAnalyzer().analyze(analyzed);
    final issues = RuleEngine().run(analyzed, config);

    final testRelPaths = testPaths
        .map((p) => p.replaceAll(projectRoot, '').replaceAll(r'\', '/'))
        .toList();
    final testGaps = TestGapDetector().detect(
      sourceFiles: analyzed,
      testFilePaths: testRelPaths,
    );

    final stateManagement = analyzed
        .where((f) => f.info.stateManagement != StateManagementKind.none)
        .map((f) => f.info.stateManagement)
        .toSet();

    final score = ScoreCalculator(
      config.weights,
    ).compute(violations: violations, issues: issues);

    return QualityReport(
      generatedAt: DateTime.now(),
      projectScore: score,
      filesAnalyzed: analyzed.length,
      stateManagement: stateManagement,
      violations: violations,
      issues: issues,
      testGaps: testGaps,
      graph: graph,
      heatmap: const {},
    );
  }
}
