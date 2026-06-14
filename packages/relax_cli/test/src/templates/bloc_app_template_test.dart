import 'package:relax_cli/src/templates/bloc_app_template.dart';
import 'package:test/test.dart';

void main() {
  group('BlocAppTemplate', () {
    test('contains 17 template files', () {
      expect(BlocAppTemplate.files, hasLength(25));
    });

    test('all file paths start with project_name variable', () {
      for (final file in BlocAppTemplate.files) {
        expect(
          file.path,
          startsWith('{{project_name.snakeCase()}}'),
          reason: 'File path "${file.path}" should start with project_name',
        );
      }
    });

    test('includes pubspec.yaml', () {
      final paths = BlocAppTemplate.files.map((f) => f.path).toList();
      expect(
        paths.any((p) => p.endsWith('pubspec.yaml')),
        isTrue,
      );
    });

    test('includes bootstrap and flavor entry points', () {
      final paths = BlocAppTemplate.files.map((f) => f.path).toList();
      expect(paths.any((p) => p.endsWith('bootstrap.dart')), isTrue);
      expect(paths.any((p) => p.endsWith('main_development.dart')), isTrue);
      expect(paths.any((p) => p.endsWith('main_staging.dart')), isTrue);
      expect(paths.any((p) => p.endsWith('main_production.dart')), isTrue);
    });

    test('includes theme files', () {
      final paths = BlocAppTemplate.files.map((f) => f.path).toList();
      expect(paths.any((p) => p.contains('app_theme.dart')), isTrue);
      expect(paths.any((p) => p.contains('app_colors.dart')), isTrue);
      expect(paths.any((p) => p.contains('app_typography.dart')), isTrue);
    });

    test('includes bloc files', () {
      final paths = BlocAppTemplate.files.map((f) => f.path).toList();
      expect(paths.any((p) => p.contains('home_bloc.dart')), isTrue);
      expect(paths.any((p) => p.contains('home_event.dart')), isTrue);
      expect(paths.any((p) => p.contains('home_state.dart')), isTrue);
    });

    test('includes test file', () {
      final paths = BlocAppTemplate.files.map((f) => f.path).toList();
      expect(
        paths.any((p) => p.contains('test/') && p.endsWith('_test.dart')),
        isTrue,
      );
    });
  });
}
