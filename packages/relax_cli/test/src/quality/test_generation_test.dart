import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:path/path.dart' as p;
import 'package:relax_cli/src/quality/config/quality_config.dart';
import 'package:relax_cli/src/quality/mock_engine/fake_generator.dart';
import 'package:relax_cli/src/quality/mock_engine/mock_generator.dart';
import 'package:relax_cli/src/quality/models/quality_models.dart';
import 'package:relax_cli/src/quality/quality_analyzer.dart';
import 'package:relax_cli/src/quality/runner/machine_test_parser.dart';
import 'package:relax_cli/src/quality/test_engine/scenario_library.dart';
import 'package:relax_cli/src/quality/test_engine/test_generation_service.dart';
import 'package:relax_cli/src/quality/test_engine/test_generator.dart';
import 'package:test/test.dart';

BusinessFunction _loginFn() => const BusinessFunction(
  name: 'login',
  filePath: 'lib/features/auth/controller/auth_controller.dart',
  className: 'AuthController',
  signature: FunctionSignature(
    name: 'login',
    isAsync: true,
    returnType: 'Future<User>',
    params: [
      ParamInfo(name: 'email', type: 'String'),
      ParamInfo(name: 'password', type: 'String'),
    ],
  ),
  layer: ArchLayer.controller,
  calls: [],
  bodyStartLine: 1,
  bodyEndLine: 5,
  dependencies: [ParamInfo(name: 'repository', type: 'AuthRepository')],
);

void main() {
  group('ScenarioLibrary', () {
    final lib = ScenarioLibrary();

    test('object return type yields the full scenario set', () {
      final kinds = lib.forReturnType('Future<User>').map((s) => s.kind);
      expect(kinds, containsAll(['success', 'invalid_input', 'network_error']));
    });

    test('void and list return types differ', () {
      expect(
        lib.forReturnType('Future<void>').map((s) => s.kind),
        isNot(contains('invalid_input')),
      );
      final list = lib.forReturnType('Future<List<Order>>');
      expect(list.where((s) => s.kind == 'success'), hasLength(2));
    });

    test('elementType unwraps futures and lists', () {
      expect(ScenarioLibrary.elementType('Future<List<User>>'), 'User');
      expect(ScenarioLibrary.elementType('Future<bool>'), 'bool');
    });
  });

  group('MockGenerator / FakeGenerator', () {
    test('mocks only infrastructure dependencies', () {
      final specs = MockGenerator().specsFor(_loginFn());
      expect(specs, hasLength(1));
      expect(specs.single.mockClassName, 'MockAuthRepository');
    });

    test('fake targets the return element type, not primitives', () {
      expect(
        FakeGenerator().specForReturnType('Future<User>')?.fakeClassName,
        'FakeUser',
      );
      expect(FakeGenerator().specForReturnType('Future<bool>'), isNull);
      expect(FakeGenerator().specForReturnType('Future<void>'), isNull);
    });
  });

  group('TestGenerator', () {
    test('produces a syntactically valid, well-named scaffold', () {
      final generated = TestGenerator(packageName: 'demo').generate(_loginFn());

      expect(
        generated.filePath,
        'test/features/auth/controller/auth_controller_test.dart',
      );
      expect(generated.content, contains("group('AuthController.login'"));
      expect(generated.content, contains('package:demo/features/auth'));
      expect(generated.scenarios.length, greaterThanOrEqualTo(4));

      // The generated Dart must parse without errors.
      final result = parseString(
        content: generated.content,
        throwIfDiagnostics: false,
      );
      final errors = result.errors
          .where((e) => e.diagnosticCode.severity.name == 'ERROR')
          .toList();
      expect(errors, isEmpty, reason: errors.join('\n'));
    });
  });

  group('MachineTestParser', () {
    test('parses passed/failed/skipped from machine JSON', () {
      const output = '''
{"type":"start","time":0}
{"type":"testStart","test":{"id":1,"name":"loading foo"},"time":1}
{"type":"testStart","test":{"id":2,"name":"a passes"},"time":2}
{"type":"testDone","testID":2,"result":"success","hidden":false,"time":3}
{"type":"testStart","test":{"id":3,"name":"b fails"},"time":4}
{"type":"error","testID":3,"error":"boom","time":5}
{"type":"testDone","testID":3,"result":"failure","hidden":false,"time":6}
{"type":"testStart","test":{"id":4,"name":"c skipped"},"time":7}
{"type":"testDone","testID":4,"result":"success","skipped":true,"hidden":false,"time":8}
{"type":"done","success":false,"time":10}
''';
      final result = MachineTestParser().parse(output);
      expect(result.total, 3);
      expect(result.passed, 1);
      expect(result.failed, 1);
      expect(result.skipped, 1);
      expect(result.durationMs, 10);
      expect(result.failures.single.testName, 'b fails');
      expect(result.failures.single.message, 'boom');
    });
  });

  group('TestGenerationService', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('relax_gen_test');
    });
    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('writes new test files but never overwrites existing ones', () {
      final service = TestGenerationService(
        projectRoot: tempDir.path,
        packageName: 'demo',
      );
      final gap = TestGap(
        businessFunction: _loginFn(),
        expectedTestFile: 'login_test.dart',
        exists: false,
      );

      final plan = service.plan([gap]);
      expect(plan.toCreate, hasLength(1));
      final written = service.write(plan);
      expect(written, hasLength(1));
      final createdPath = p.join(tempDir.path, written.single);
      expect(File(createdPath).existsSync(), isTrue);

      // Second run: file now exists, so it is skipped.
      final secondPlan = service.plan([gap]);
      expect(secondPlan.toCreate, isEmpty);
      expect(secondPlan.skipped, hasLength(1));
    });

    test('readPackageName reads pubspec name', () {
      File(
        p.join(tempDir.path, 'pubspec.yaml'),
      ).writeAsStringSync('name: my_app\nversion: 1.0.0\n');
      expect(readPackageName(tempDir.path), 'my_app');
    });
  });

  group('QualityAnalyzer + generation integration', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('relax_gen_e2e');
    });
    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('generates a scaffold for a detected untested function', () {
      File(
        p.join(tempDir.path, 'pubspec.yaml'),
      ).writeAsStringSync('name: demo\n');
      final src = File(
        p.join(
          tempDir.path,
          'lib/features/auth/controller/auth_controller.dart',
        ),
      )..parent.createSync(recursive: true);
      src.writeAsStringSync('''
class AuthController {
  AuthController(this.repository);
  final AuthRepository repository;

  Future<User> login(String email, String password) async {
    return repository.login(email, password);
  }
}
''');

      final report = QualityAnalyzer(
        projectRoot: tempDir.path,
        config: const QualityConfig(),
      ).run();

      expect(
        report.testGaps.map((g) => g.businessFunction.name),
        contains('login'),
      );

      final service = TestGenerationService(
        projectRoot: tempDir.path,
        packageName: readPackageName(tempDir.path),
      );
      final written = service.write(service.plan(report.testGaps));
      expect(
        written,
        contains('test/features/auth/controller/auth_controller_test.dart'),
      );
    });
  });
}
