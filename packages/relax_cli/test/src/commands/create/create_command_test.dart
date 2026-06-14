import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:relax_cli/relax_cli.dart';
import 'package:test/test.dart';

void main() {
  late RelaxCommandRunner runner;
  late Directory tempDir;

  setUp(() {
    runner = RelaxCommandRunner();
    tempDir = Directory.systemTemp.createTempSync('relax_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('CreateCommand', () {
    test('exits with usage code when no project name is given', () async {
      final exitCode = await runner.run(['create']);
      expect(exitCode, equals(ExitCode.usage.code));
    });

    test('exits with usage code for invalid project name', () async {
      final exitCode = await runner.run(['create', 'Invalid-Name']);
      expect(exitCode, equals(ExitCode.usage.code));
    });

    test('exits with usage code for name starting with digit', () async {
      final exitCode = await runner.run(['create', '1app']);
      expect(exitCode, equals(ExitCode.usage.code));
    });

    test('exits with usage code for name with special chars', () async {
      final exitCode = await runner.run(['create', 'my-app']);
      expect(exitCode, equals(ExitCode.usage.code));
    });

    test('exits with usage code when directory already exists', () async {
      final existing = Directory('${tempDir.path}/existing_app')
        ..createSync();

      final originalDir = Directory.current;
      Directory.current = tempDir;

      try {
        final exitCode = await runner.run(['create', 'existing_app']);
        expect(exitCode, equals(ExitCode.usage.code));
      } finally {
        Directory.current = originalDir;
        existing.deleteSync(recursive: true);
      }
    });

    test('generates bloc project successfully', () async {
      final originalDir = Directory.current;
      Directory.current = tempDir;

      try {
        final exitCode = await runner.run([
          'create',
          'test_app',
          '-a',
          'bloc',
        ]);
        expect(exitCode, equals(ExitCode.success.code));

        final projectDir = Directory('${tempDir.path}/test_app');
        expect(projectDir.existsSync(), isTrue);

        // Verify key files exist
        final expectedFiles = [
          'pubspec.yaml',
          'lib/bootstrap.dart',
          'lib/main_development.dart',
          'lib/main_staging.dart',
          'lib/main_production.dart',
          'lib/app/app.dart',
          'lib/app/view/app.dart',
          'lib/core/core.dart',
          'lib/core/theme/app_theme.dart',
          'lib/core/theme/app_colors.dart',
          'lib/core/theme/app_typography.dart',
          'lib/features/home/home.dart',
          'lib/features/home/bloc/home_bloc.dart',
          'lib/features/home/bloc/home_event.dart',
          'lib/features/home/bloc/home_state.dart',
          'lib/features/home/view/home_page.dart',
          'lib/features/home/view/home_view.dart',
          'test/app/view/app_test.dart',
          'analysis_options.yaml',
          'README.md',
        ];

        for (final path in expectedFiles) {
          expect(
            File('${projectDir.path}/$path').existsSync(),
            isTrue,
            reason: 'Expected file $path to exist',
          );
        }
      } finally {
        Directory.current = originalDir;
      }
    });

    test('generated pubspec.yaml contains correct project name', () async {
      final originalDir = Directory.current;
      Directory.current = tempDir;

      try {
        await runner.run(['create', 'cool_app', '-a', 'bloc']);

        final pubspec =
            File('${tempDir.path}/cool_app/pubspec.yaml').readAsStringSync();
        expect(pubspec, contains('name: cool_app'));
        expect(pubspec, contains('flutter_bloc'));
        expect(pubspec, contains('equatable'));
      } finally {
        Directory.current = originalDir;
      }
    });

    test('generated app view contains title-cased project name', () async {
      final originalDir = Directory.current;
      Directory.current = tempDir;

      try {
        await runner.run(['create', 'my_cool_app', '-a', 'bloc']);

        final appView = File('${tempDir.path}/my_cool_app/lib/app/view/app.dart')
            .readAsStringSync();
        expect(appView, contains("'My Cool App'"));
      } finally {
        Directory.current = originalDir;
      }
    });

    test('custom org is used for android application id', () async {
      final originalDir = Directory.current;
      Directory.current = tempDir;

      try {
        await runner.run([
          'create',
          'org_app',
          '-a',
          'bloc',
          '-o',
          'dev.acme',
        ]);

        final buildGradle = File(
          '${tempDir.path}/org_app/android/app/build.gradle.kts',
        ).readAsStringSync();
        expect(buildGradle, contains('namespace = "dev.acme.org_app"'));
        expect(buildGradle, contains('applicationId = "dev.acme.org_app"'));
      } finally {
        Directory.current = originalDir;
      }
    });

    for (final arch in ['provider', 'riverpod', 'getx']) {
      test('generates $arch project successfully', () async {
        final originalDir = Directory.current;
        Directory.current = tempDir;

        try {
          final exitCode = await runner.run([
            'create',
            '${arch}_app',
            '-a',
            arch,
          ]);
          expect(exitCode, equals(ExitCode.success.code));
          expect(
            Directory('${tempDir.path}/${arch}_app').existsSync(),
            isTrue,
          );
        } finally {
          Directory.current = originalDir;
        }
      });
    }
  });
}
