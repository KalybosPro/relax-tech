import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:relax_cli/src/quality/config/quality_config.dart';
import 'package:relax_cli/src/quality/models/quality_models.dart';
import 'package:relax_cli/src/quality/quality_analyzer.dart';
import 'package:relax_cli/src/quality/report/ci_reporter.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('relax_quality_test');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  void write(String relPath, String content) {
    final file = File(p.join(tempDir.path, relPath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  QualityReport analyze() => QualityAnalyzer(
    projectRoot: tempDir.path,
    config: const QualityConfig(),
  ).run();

  group('QualityAnalyzer end-to-end', () {
    test('detects controller→api violation, state mgmt, and test gap', () {
      write('pubspec.yaml', 'name: sample\n');
      write('lib/features/auth/controller/auth_controller.dart', '''
class AuthController extends GetxController {
  final apiClient = ApiClient();

  Future<User> login(String email, String password) async {
    final response = await apiClient.post('/login', {'email': email});
    return User.fromJson(response);
  }
}
''');

      final report = analyze();

      expect(report.filesAnalyzed, 1);
      expect(report.stateManagement, contains(StateManagementKind.getx));

      final types = report.violations.map((v) => v.type);
      expect(types, contains('controller_to_api'));
      // No repository layer exists, so this is also flagged.
      expect(types, contains('missing_repository'));

      expect(
        report.testGaps.map((g) => g.businessFunction.name),
        contains('login'),
      );
      expect(report.projectScore, lessThan(100));
    });

    test('a clean layered project scores 100 with no violations', () {
      write('pubspec.yaml', 'name: sample\n');
      write('lib/features/auth/repository/auth_repository.dart', '''
class AuthRepository {
  Future<void> save() async {}
}
''');
      write('lib/features/auth/controller/auth_controller.dart', '''
class AuthController {
  AuthController(this.repository);
  final AuthRepository repository;
}
''');

      final report = analyze();
      expect(report.violations, isEmpty);
      expect(report.projectScore, 100);
    });

    test('CI reporter writes valid JSON and JUnit and gates on thresholds', () {
      write('pubspec.yaml', 'name: sample\n');
      write('lib/controller/x_controller.dart', '''
class XController extends Cubit<int> {
  Future<void> fetch() async {
    await api.get('/x');
  }
}
''');

      final report = analyze();
      final reporter = CiReporter(projectRoot: tempDir.path);

      final jsonPath = reporter.writeJson(report);
      final decoded = jsonDecode(File(jsonPath).readAsStringSync());
      expect(decoded['schemaVersion'], '1.0');
      expect(decoded['violations'], isNotEmpty);

      final junitPath = reporter.writeJunit(report);
      final xml = File(junitPath).readAsStringSync();
      expect(xml, startsWith('<?xml'));
      expect(xml, contains('<testsuite'));

      final gate = reporter.evaluateGate(
        report,
        const CiThresholds(maxViolations: 0),
      );
      expect(gate.passed, isFalse);
      expect(gate.reasons.single, contains('violations'));
    });
  });
}
