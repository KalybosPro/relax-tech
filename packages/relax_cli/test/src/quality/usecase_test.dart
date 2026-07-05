import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:path/path.dart' as p;
import 'package:relax_cli/src/quality/config/quality_config.dart';
import 'package:relax_cli/src/quality/diff/patch_journal.dart';
import 'package:relax_cli/src/quality/models/quality_models.dart';
import 'package:relax_cli/src/quality/quality_analyzer.dart';
import 'package:relax_cli/src/quality/usecase_engine/usecase_detector.dart';
import 'package:relax_cli/src/quality/usecase_engine/usecase_generator.dart';
import 'package:relax_cli/src/quality/usecase_engine/usecase_service.dart';
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
  calls: [FunctionCallRef(target: 'login', receiver: 'repository')],
  bodyStartLine: 1,
  bodyEndLine: 5,
  dependencies: [ParamInfo(name: 'repository', type: 'AuthRepository')],
);

void main() {
  group('UseCaseDetector', () {
    test('suggests file/class names and detects no existing usecase', () {
      final candidate = UseCaseDetector().detect(_loginFn(), const []);
      expect(candidate.existingUseCaseFound, isFalse);
      expect(candidate.suggestedFileName, 'login_usecase.dart');
      expect(candidate.suggestedClassName, 'LoginUseCase');
    });
  });

  group('UseCaseGenerator', () {
    test(
      'generates a valid class with deps, execute(), and the infra call',
      () {
        final candidate = UseCaseDetector().detect(_loginFn(), const []);
        final generated = UseCaseGenerator().generate(candidate);

        expect(
          generated.filePath,
          'lib/features/auth/usecases/login_usecase.dart',
        );
        expect(generated.content, contains('class LoginUseCase {'));
        expect(generated.content, contains('final AuthRepository repository;'));
        expect(
          generated.content,
          contains('Future<User> execute(String email, String password) async'),
        );
        expect(
          generated.content,
          contains('return repository.login(email, password);'),
        );

        // Must be syntactically valid Dart.
        final result = parseString(
          content: generated.content,
          throwIfDiagnostics: false,
        );
        final errors = result.errors
            .where((e) => e.diagnosticCode.severity.name == 'ERROR')
            .toList();
        expect(errors, isEmpty, reason: errors.join('\n'));
      },
    );
  });

  group('PatchJournal', () {
    test('builds a unified diff for a new file', () {
      final diff = PatchJournal.newFileDiff((
        relPath: 'a.dart',
        content: 'x\ny',
      ));
      expect(diff, contains('--- /dev/null'));
      expect(diff, contains('+++ a.dart'));
      expect(diff, contains('+x'));
      expect(diff, contains('+y'));
    });
  });

  group('UseCaseService (fs)', () {
    late Directory tempDir;
    setUp(() => tempDir = Directory.systemTemp.createTempSync('relax_uc'));
    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    QualityReport analyze() {
      File(
        p.join(tempDir.path, 'pubspec.yaml'),
      ).writeAsStringSync('name: demo\n');
      return QualityAnalyzer(
        projectRoot: tempDir.path,
        config: const QualityConfig(),
      ).run();
    }

    test('generates a UseCase and journals a reversible patch', () {
      File(
          p.join(
            tempDir.path,
            'lib/features/auth/controller/auth_controller.dart',
          ),
        )
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('''
class AuthController {
  AuthController(this.repository);
  final AuthRepository repository;

  Future<User> login(String email, String password) async {
    return repository.login(email, password);
  }
}
''');

      analyze();
      final analyzer = QualityAnalyzer(
        projectRoot: tempDir.path,
        config: const QualityConfig(),
      )..run();

      final service = UseCaseService(projectRoot: tempDir.path);
      final plan = service.plan(analyzer.analyzedFiles);
      expect(plan.toCreate, hasLength(1));
      expect(
        plan.toCreate.single.filePath,
        'lib/features/auth/usecases/login_usecase.dart',
      );

      final result = service.write(plan);
      expect(
        File(p.join(tempDir.path, result.written.single)).existsSync(),
        isTrue,
      );
      // A reversible patch was journaled.
      expect(
        Directory(p.join(tempDir.path, result.patchDir)).existsSync(),
        isTrue,
      );
      expect(
        File(
          p.join(tempDir.path, result.patchDir, 'changes.diff'),
        ).existsSync(),
        isTrue,
      );

      // Re-planning now skips the existing file.
      final second = service.plan(analyzer.analyzedFiles);
      expect(second.toCreate, isEmpty);
      expect(second.skippedExisting, hasLength(1));
    });

    test('detects an existing UseCase and does not regenerate it', () {
      final dir = p.join(tempDir.path, 'lib/features/auth');
      File(p.join(dir, 'controller/auth_controller.dart'))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('''
class AuthController {
  AuthController(this.repository);
  final AuthRepository repository;
  Future<User> login(String e, String p) async => repository.login(e, p);
}
''');
      File(p.join(dir, 'usecases/login_usecase.dart'))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('class LoginUsecase {}\n');

      final analyzer = QualityAnalyzer(
        projectRoot: tempDir.path,
        config: const QualityConfig(),
      )..run();
      final plan = UseCaseService(
        projectRoot: tempDir.path,
      ).plan(analyzer.analyzedFiles);

      expect(plan.toCreate, isEmpty);
      expect(plan.alreadyImplemented, isNotEmpty);
    });
  });
}
