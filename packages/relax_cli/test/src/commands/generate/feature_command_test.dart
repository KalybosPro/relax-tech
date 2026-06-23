@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:relax_cli/relax_cli.dart';
import 'package:test/test.dart';

void main() {
  late RelaxCommandRunner runner;
  late Directory tempDir;

  setUp(() {
    runner = RelaxCommandRunner();
    tempDir = Directory.systemTemp.createTempSync('relax_feat_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } on FileSystemException {
        // On Windows a build_runner subprocess may still hold a handle on the
        // temp dir; ignore the transient lock so cleanup doesn't fail the test.
      }
    }
  });

  /// Helper: create a project then cd into it.
  Future<void> createProject(String name, String arch) async {
    final originalDir = Directory.current;
    Directory.current = tempDir;
    try {
      await runner.run(['create', name, '-a', arch]);
    } finally {
      Directory.current = originalDir;
    }
  }

  group('FeatureCommand', () {
    test('exits with usage when no feature name is given', () async {
      await createProject('app', 'bloc');
      final originalDir = Directory.current;
      Directory.current = Directory('${tempDir.path}/app');

      try {
        final code = await runner.run(['generate', 'feature']);
        expect(code, equals(ExitCode.usage.code));
      } finally {
        Directory.current = originalDir;
      }
    });

    test('exits with usage for invalid feature name', () async {
      await createProject('app', 'bloc');
      final originalDir = Directory.current;
      Directory.current = Directory('${tempDir.path}/app');

      try {
        final code = await runner.run(['generate', 'feature', 'My-Feature']);
        expect(code, equals(ExitCode.usage.code));
      } finally {
        Directory.current = originalDir;
      }
    });

    test('exits with usage when not in a Flutter project', () async {
      final emptyDir = Directory('${tempDir.path}/empty')..createSync();
      final originalDir = Directory.current;
      Directory.current = emptyDir;

      try {
        final code = await runner.run(['generate', 'feature', 'foo', '-a', 'bloc']);
        expect(code, equals(ExitCode.usage.code));
      } finally {
        Directory.current = originalDir;
      }
    });

    test('exits with usage when feature already exists', () async {
      await createProject('app', 'bloc');
      final originalDir = Directory.current;
      Directory.current = Directory('${tempDir.path}/app');

      try {
        // home already exists from project generation
        final code = await runner.run(['generate', 'feature', 'home']);
        expect(code, equals(ExitCode.usage.code));
      } finally {
        Directory.current = originalDir;
      }
    });

    for (final arch in ['bloc', 'provider', 'riverpod', 'getx']) {
      test('generates feature for $arch architecture', () async {
        await createProject('app_$arch', arch);
        final originalDir = Directory.current;
        Directory.current = Directory('${tempDir.path}/app_$arch');

        try {
          final code = await runner.run(['generate', 'feature', 'settings']);
          expect(code, equals(ExitCode.success.code));

          final featureDir = Directory(
            '${tempDir.path}/app_$arch/lib/features/settings',
          );
          expect(featureDir.existsSync(), isTrue);

          // All architectures generate a barrel + page + view
          expect(
            File('${featureDir.path}/settings.dart').existsSync(),
            isTrue,
            reason: 'barrel file',
          );
          expect(
            File('${featureDir.path}/view/settings_page.dart').existsSync(),
            isTrue,
            reason: 'page file',
          );
          expect(
            File('${featureDir.path}/view/settings_view.dart').existsSync(),
            isTrue,
            reason: 'view file',
          );
        } finally {
          Directory.current = originalDir;
        }
      });
    }

    test('auto-detects bloc architecture', () async {
      await createProject('app', 'bloc');
      final originalDir = Directory.current;
      Directory.current = Directory('${tempDir.path}/app');

      try {
        await runner.run(['generate', 'feature', 'profile']);

        // Bloc-specific: should have bloc/ directory
        expect(
          File('${tempDir.path}/app/lib/features/profile/bloc/profile_bloc.dart')
              .existsSync(),
          isTrue,
        );
      } finally {
        Directory.current = originalDir;
      }
    });

    test('auto-detects riverpod architecture', () async {
      await createProject('app', 'riverpod');
      final originalDir = Directory.current;
      Directory.current = Directory('${tempDir.path}/app');

      try {
        await runner.run(['generate', 'feature', 'cart']);

        // Riverpod-specific: should have providers/ directory
        expect(
          File('${tempDir.path}/app/lib/features/cart/providers/cart_provider.dart')
              .existsSync(),
          isTrue,
        );
      } finally {
        Directory.current = originalDir;
      }
    });

    test('--architecture flag overrides detection', () async {
      await createProject('app', 'bloc');
      final originalDir = Directory.current;
      Directory.current = Directory('${tempDir.path}/app');

      try {
        // Override detected bloc with provider
        await runner.run([
          'generate',
          'feature',
          'mixed',
          '-a',
          'provider',
        ]);

        // Should use provider pattern despite project being bloc
        expect(
          File('${tempDir.path}/app/lib/features/mixed/notifiers/mixed_notifier.dart')
              .existsSync(),
          isTrue,
        );
      } finally {
        Directory.current = originalDir;
      }
    });

    test('creates parent folder then feature for a path spec', () async {
      await createProject('app', 'bloc');
      final originalDir = Directory.current;
      Directory.current = Directory('${tempDir.path}/app');

      try {
        final code = await runner.run(['g', 'feature', 'auth/login']);
        expect(code, equals(ExitCode.success.code));

        // Parent folder created, feature nested inside it.
        final base = '${tempDir.path}/app/lib/features/auth/login';
        expect(
          Directory('${tempDir.path}/app/lib/features/auth').existsSync(),
          isTrue,
          reason: 'parent folder',
        );
        expect(File('$base/login.dart').existsSync(), isTrue);

        // Class names derive from the leaf segment only (login -> LoginBloc).
        final bloc = File('$base/bloc/login_bloc.dart');
        expect(bloc.existsSync(), isTrue);
        expect(bloc.readAsStringSync(), contains('class LoginBloc'));
        expect(bloc.readAsStringSync(), isNot(contains('AuthLogin')));
      } finally {
        Directory.current = originalDir;
      }
    });

    test('supports arbitrarily deep path specs', () async {
      await createProject('app', 'bloc');
      final originalDir = Directory.current;
      Directory.current = Directory('${tempDir.path}/app');

      try {
        final code = await runner.run(['g', 'feature', 'a/b/c/login']);
        expect(code, equals(ExitCode.success.code));
        expect(
          File('${tempDir.path}/app/lib/features/a/b/c/login/login.dart')
              .existsSync(),
          isTrue,
        );
      } finally {
        Directory.current = originalDir;
      }
    });

    test('exits with usage when a path segment is invalid', () async {
      await createProject('app', 'bloc');
      final originalDir = Directory.current;
      Directory.current = Directory('${tempDir.path}/app');

      try {
        final code = await runner.run(['g', 'feature', 'auth/My-Feature']);
        expect(code, equals(ExitCode.usage.code));
      } finally {
        Directory.current = originalDir;
      }
    });

    test('supports alias "g" for generate', () async {
      await createProject('app', 'bloc');
      final originalDir = Directory.current;
      Directory.current = Directory('${tempDir.path}/app');

      try {
        final code = await runner.run(['g', 'feature', 'dashboard']);
        expect(code, equals(ExitCode.success.code));
        expect(
          Directory('${tempDir.path}/app/lib/features/dashboard').existsSync(),
          isTrue,
        );
      } finally {
        Directory.current = originalDir;
      }
    });
  });
}
