/// Core data model for the `relax quality` subsystem.
///
/// These types mirror the interfaces described in the quality specification,
/// adapted to Dart. They are intentionally plain (immutable value objects) so
/// they can be serialized to JSON for the CI report and the future dashboard.
library;

/// Architectural layer a Dart file/class belongs to.
enum ArchLayer {
  widget,
  controller,
  usecase,
  repository,
  datasource,
  apiService,
  model,
  unknown;

  /// Stable string used in JSON payloads.
  String get id => switch (this) {
    ArchLayer.apiService => 'api_service',
    _ => name,
  };
}

/// State management flavor detected in a file.
enum StateManagementKind {
  getx,
  bloc,
  cubit,
  riverpod,
  provider,
  mobx,
  none;

  String get id => name;
}

/// Severity shared by violations and quality issues.
enum Severity {
  info,
  warning,
  error;

  String get id => name;
}

/// A parameter of a function/method signature.
class ParamInfo {
  const ParamInfo({required this.name, required this.type});

  final String name;
  final String type;

  Map<String, Object?> toJson() => {'name': name, 'type': type};
}

/// The signature of a business function (as written, syntactic types).
class FunctionSignature {
  const FunctionSignature({
    required this.name,
    required this.isAsync,
    required this.returnType,
    required this.params,
  });

  final String name;
  final bool isAsync;
  final String returnType;
  final List<ParamInfo> params;

  Map<String, Object?> toJson() => {
    'name': name,
    'isAsync': isAsync,
    'returnType': returnType,
    'params': params.map((p) => p.toJson()).toList(),
  };
}

/// An outgoing call reference, used to trace UI → … → API.
class FunctionCallRef {
  const FunctionCallRef({required this.target, this.receiver});

  /// Method or function name being called (e.g. `login`).
  final String target;

  /// Receiver expression if any (e.g. `_repository`, `api`).
  final String? receiver;

  Map<String, Object?> toJson() => {'target': target, 'receiver': receiver};
}

/// A detected business function (login, createOrder, …).
class BusinessFunction {
  const BusinessFunction({
    required this.name,
    required this.filePath,
    required this.signature,
    required this.layer,
    required this.calls,
    required this.bodyStartLine,
    required this.bodyEndLine,
    this.className,
    this.dependencies = const [],
  });

  final String name;
  final String filePath;
  final String? className;
  final FunctionSignature signature;
  final ArchLayer layer;
  final List<FunctionCallRef> calls;
  final int bodyStartLine;
  final int bodyEndLine;

  /// Instance fields/dependencies of the enclosing class (name → type), used
  /// by the test generator to synthesize mocks.
  final List<ParamInfo> dependencies;

  Map<String, Object?> toJson() => {
    'name': name,
    'filePath': filePath,
    'className': className,
    'signature': signature.toJson(),
    'layer': layer.id,
    'calls': calls.map((c) => c.toJson()).toList(),
    'bodyRange': [bodyStartLine, bodyEndLine],
  };
}

/// A single parsed Dart file plus its derived classification.
class DartFileInfo {
  DartFileInfo({
    required this.path,
    required this.hash,
    required this.layer,
    required this.stateManagement,
    required this.classNames,
    required this.imports,
    required this.lineCount,
    required this.businessFunctions,
  });

  final String path;
  final String hash;
  ArchLayer layer;
  StateManagementKind stateManagement;
  final List<String> classNames;
  final List<String> imports;
  final int lineCount;
  final List<BusinessFunction> businessFunctions;

  /// `true` when the file lives under a `test/` directory.
  bool get isTest => path.replaceAll(r'\', '/').contains('/test/');
}

/// A node in the dependency graph (one per file/class).
class GraphNode {
  const GraphNode({
    required this.id,
    required this.layer,
    required this.filePath,
    required this.label,
  });

  final String id;
  final ArchLayer layer;
  final String filePath;
  final String label;

  Map<String, Object?> toJson() => {
    'id': id,
    'layer': layer.id,
    'filePath': filePath,
    'label': label,
  };
}

/// An edge in the dependency graph.
class GraphEdge {
  const GraphEdge({required this.from, required this.to, required this.kind});

  final String from;
  final String to;

  /// `calls`, `imports`, or `injects`.
  final String kind;

  Map<String, Object?> toJson() => {'from': from, 'to': to, 'kind': kind};
}

/// The dependency graph: UI → Controller → UseCase → Repository → … → API.
class DependencyGraph {
  DependencyGraph({required this.nodes, required this.edges});

  final Map<String, GraphNode> nodes;
  final List<GraphEdge> edges;

  Map<String, Object?> toJson() => {
    'nodes': nodes.values.map((n) => n.toJson()).toList(),
    'edges': edges.map((e) => e.toJson()).toList(),
  };
}

/// An architecture violation (e.g. Controller → API directly).
class ArchitectureViolation {
  const ArchitectureViolation({
    required this.type,
    required this.filePath,
    required this.functionName,
    required this.message,
    required this.occurrences,
    required this.severity,
  });

  /// One of: `controller_to_api`, `missing_repository`, `missing_usecase`,
  /// `layer_skip`.
  final String type;
  final String filePath;
  final String functionName;
  final String message;
  final int occurrences;
  final Severity severity;

  Map<String, Object?> toJson() => {
    'type': type,
    'filePath': filePath,
    'functionName': functionName,
    'message': message,
    'occurrences': occurrences,
    'severity': severity.id,
  };
}

/// A quality-rule finding.
class QualityIssue {
  const QualityIssue({
    required this.rule,
    required this.filePath,
    required this.line,
    required this.message,
    required this.suggestion,
    required this.severity,
    this.score,
  });

  final String rule;
  final String filePath;
  final int line;
  final String message;
  final String suggestion;
  final Severity severity;

  /// Optional numeric score (e.g. cyclomatic complexity 18).
  final num? score;

  Map<String, Object?> toJson() => {
    'rule': rule,
    'filePath': filePath,
    'line': line,
    'message': message,
    'score': score,
    'suggestion': suggestion,
    'severity': severity.id,
  };
}

/// A missing-test gap for a business function.
class TestGap {
  const TestGap({
    required this.businessFunction,
    required this.expectedTestFile,
    required this.exists,
  });

  final BusinessFunction businessFunction;
  final String expectedTestFile;
  final bool exists;

  Map<String, Object?> toJson() => {
    'function': businessFunction.name,
    'filePath': businessFunction.filePath,
    'expectedTestFile': expectedTestFile,
    'exists': exists,
  };
}

/// The result of checking whether a business function already has a UseCase.
class UseCaseCandidate {
  const UseCaseCandidate({
    required this.businessFunction,
    required this.existingUseCaseFound,
    required this.matchedClassNames,
    required this.suggestedFileName,
    required this.suggestedClassName,
  });

  final BusinessFunction businessFunction;
  final bool existingUseCaseFound;

  /// Existing classes that matched the UseCase name patterns.
  final List<String> matchedClassNames;

  /// e.g. `login_usecase.dart`.
  final String suggestedFileName;

  /// e.g. `LoginUseCase`.
  final String suggestedClassName;
}

/// A generated UseCase file (a new file — never a source rewrite).
class GeneratedUseCase {
  const GeneratedUseCase({
    required this.filePath,
    required this.content,
    required this.candidate,
  });

  /// Path relative to the project root, using forward slashes.
  final String filePath;
  final String content;
  final UseCaseCandidate candidate;
}

/// A single test scenario synthesized for a business function.
class TestScenario {
  const TestScenario({
    required this.name,
    required this.kind,
    required this.setup,
    required this.assertion,
  });

  final String name;

  /// success | invalid_input | network_error | server_error | timeout |
  /// null_response.
  final String kind;

  /// Mock setup code (the `when(...)` line(s)).
  final String setup;

  /// The assertion/act code (the `expect(...)` line(s)).
  final String assertion;
}

/// A generated test file for a business function.
class GeneratedTestFile {
  const GeneratedTestFile({
    required this.filePath,
    required this.content,
    required this.scenarios,
    required this.businessFunction,
  });

  /// Path relative to the project root, using forward slashes.
  final String filePath;
  final String content;
  final List<TestScenario> scenarios;
  final BusinessFunction businessFunction;
}

/// Specification for a generated mock class (mocktail).
class MockSpec {
  const MockSpec({required this.targetClassName, required this.mockClassName});

  final String targetClassName;
  final String mockClassName;
}

/// Specification for a generated fake data object.
class FakeSpec {
  const FakeSpec({required this.targetTypeName, required this.fakeClassName});

  final String targetTypeName;
  final String fakeClassName;
}

/// Coverage aggregation. Populated only when tests are executed
/// (out of scope for `--check`); kept for report-shape compatibility.
class CoverageReport {
  const CoverageReport({
    required this.overall,
    required this.byLayer,
    required this.byFeature,
    this.byFile = const {},
  });

  final num overall;
  final Map<String, num> byLayer;
  final Map<String, num> byFeature;

  /// Per-file `{ covered, total }` counts.
  final Map<String, ({int covered, int total})> byFile;

  Map<String, Object?> toJson() => {
    'overall': overall,
    'byLayer': byLayer,
    'byFeature': byFeature,
    'byFile': {
      for (final e in byFile.entries)
        e.key: {'covered': e.value.covered, 'total': e.value.total},
    },
  };
}

/// A single failing test.
class TestFailure {
  const TestFailure({
    required this.testName,
    required this.filePath,
    required this.message,
  });

  final String testName;
  final String filePath;
  final String message;

  Map<String, Object?> toJson() => {
    'testName': testName,
    'filePath': filePath,
    'message': message,
  };
}

/// Result of executing `flutter test`.
class TestRunResult {
  const TestRunResult({
    required this.total,
    required this.passed,
    required this.failed,
    required this.skipped,
    required this.durationMs,
    this.failures = const [],
  });

  final int total;
  final int passed;
  final int failed;
  final int skipped;
  final int durationMs;
  final List<TestFailure> failures;

  Map<String, Object?> toJson() => {
    'total': total,
    'passed': passed,
    'failed': failed,
    'skipped': skipped,
    'durationMs': durationMs,
    'failures': failures.map((f) => f.toJson()).toList(),
  };
}

/// The full quality report produced by an analysis run.
class QualityReport {
  QualityReport({
    required this.generatedAt,
    required this.projectScore,
    required this.filesAnalyzed,
    required this.stateManagement,
    required this.violations,
    required this.issues,
    required this.testGaps,
    required this.graph,
    required this.heatmap,
    this.previousScore,
    this.coverage,
    this.testRun,
  });

  static const String schemaVersion = '1.0';

  final DateTime generatedAt;
  final int projectScore;
  final int? previousScore;
  final int filesAnalyzed;
  final Set<StateManagementKind> stateManagement;
  final List<ArchitectureViolation> violations;
  final List<QualityIssue> issues;
  final List<TestGap> testGaps;
  final DependencyGraph graph;

  /// module/feature → coverage percentage (0 when not measured).
  final Map<String, num> heatmap;
  final CoverageReport? coverage;
  final TestRunResult? testRun;

  /// Returns a copy with selected fields replaced. Used to attach a test run
  /// or coverage (and the rescored [projectScore]) after execution.
  QualityReport copyWith({
    int? projectScore,
    int? previousScore,
    TestRunResult? testRun,
    CoverageReport? coverage,
    Map<String, num>? heatmap,
  }) => QualityReport(
    generatedAt: generatedAt,
    projectScore: projectScore ?? this.projectScore,
    filesAnalyzed: filesAnalyzed,
    stateManagement: stateManagement,
    violations: violations,
    issues: issues,
    testGaps: testGaps,
    graph: graph,
    heatmap: heatmap ?? this.heatmap,
    previousScore: previousScore ?? this.previousScore,
    coverage: coverage ?? this.coverage,
    testRun: testRun ?? this.testRun,
  );

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'projectScore': projectScore,
    'previousScore': previousScore,
    'filesAnalyzed': filesAnalyzed,
    'stateManagement': stateManagement.map((s) => s.id).toList(),
    'coverage': coverage?.toJson(),
    'testRun': testRun?.toJson(),
    'violations': violations.map((v) => v.toJson()).toList(),
    'issues': issues.map((i) => i.toJson()).toList(),
    'testGaps': testGaps.map((g) => g.toJson()).toList(),
    'heatmap': heatmap,
    'graph': graph.toJson(),
  };
}
