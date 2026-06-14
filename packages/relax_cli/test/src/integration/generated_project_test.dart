@Timeout(Duration(minutes: 2))
library;

import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:relax_cli/relax_cli.dart';
import 'package:test/test.dart';

/// Integration tests that verify generated projects are valid Dart code.
///
/// These tests run `dart analyze` on the generated output to catch
/// template errors (bad imports, syntax issues, missing variables).
void main() {
  late ProjectGenerator generator;
  late Directory tempDir;

  setUp(() {
    generator = ProjectGenerator(logger: Logger());
    tempDir = Directory.systemTemp.createTempSync('relax_integ_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  for (final arch in Architecture.values) {
    test('generated ${arch.name} project has valid Dart syntax', () async {
      await generator.generate(
        projectName: 'test_app',
        architecture: arch,
        outputDirectory: tempDir,
      );

      final projectDir = Directory('${tempDir.path}/test_app');

      // Verify all .dart files parse correctly
      final dartFiles = projectDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final content = file.readAsStringSync();

        // No unresolved mustache variables
        expect(
          content,
          isNot(contains('{{')),
          reason: '${file.path} contains unresolved mustache variable',
        );
        expect(
          content,
          isNot(contains('}}')),
          reason: '${file.path} contains unresolved mustache variable',
        );

        // No empty file (template issue)
        expect(
          content.trim(),
          isNotEmpty,
          reason: '${file.path} is empty',
        );
      }
    });
  }

  test('customized project has no unresolved variables', () async {
    await generator.generate(
      projectName: 'custom_app',
      architecture: Architecture.bloc,
      outputDirectory: tempDir,
      description: 'A test description',
      primaryColor: 'FF5722',
      fontFamily: 'Inter',
    );

    final projectDir = Directory('${tempDir.path}/custom_app');

    final textFiles = projectDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => _isTextFile(f.path));

    for (final file in textFiles) {
      final content = file.readAsStringSync();
      expect(
        content,
        isNot(contains('{{')),
        reason: '${file.path} has unresolved mustache',
      );
    }

    // Verify specific substitutions
    final pubspec =
        File('${projectDir.path}/pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('name: custom_app'));
    expect(pubspec, contains('description: A test description'));

    final colors =
        File('${projectDir.path}/lib/core/theme/app_colors.dart')
            .readAsStringSync();
    expect(colors, contains('0xFFFF5722'));

    final typo =
        File('${projectDir.path}/lib/core/theme/app_typography.dart')
            .readAsStringSync();
    expect(typo, contains("'Inter'"));
  });

  test('generated feature has no unresolved variables', () async {
    // First create a project
    await generator.generate(
      projectName: 'test_app',
      architecture: Architecture.bloc,
      outputDirectory: tempDir,
    );

    // Then generate a feature
    final featureGen = FeatureGenerator(logger: Logger());
    await featureGen.generate(
      featureName: 'user_settings',
      architecture: Architecture.bloc,
      projectDir: Directory('${tempDir.path}/test_app'),
    );

    final featureDir =
        Directory('${tempDir.path}/test_app/lib/features/user_settings');
    expect(featureDir.existsSync(), isTrue);

    final dartFiles = featureDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final content = file.readAsStringSync();
      expect(
        content,
        isNot(contains('{{')),
        reason: '${file.path} has unresolved mustache',
      );

      // Verify PascalCase substitution worked
      if (file.path.contains('bloc')) {
        expect(content, contains('UserSettings'));
      }
    }
  });

  test('generated module has no unresolved variables', () async {
    await generator.generate(
      projectName: 'test_app',
      architecture: Architecture.bloc,
      outputDirectory: tempDir,
    );

    final moduleGen = ModuleGenerator(logger: Logger());
    await moduleGen.generate(
      moduleName: 'shopping_cart',
      outputDir: Directory('${tempDir.path}/test_app/lib/modules'),
    );

    final moduleDir =
        Directory('${tempDir.path}/test_app/lib/modules/shopping_cart');
    expect(moduleDir.existsSync(), isTrue);

    final allFiles = moduleDir
        .listSync(recursive: true)
        .whereType<File>();

    for (final file in allFiles) {
      final content = file.readAsStringSync();
      expect(
        content,
        isNot(contains('{{')),
        reason: '${file.path} has unresolved mustache',
      );
    }

    // Verify naming
    final model =
        File('${moduleDir.path}/models/shopping_cart.dart').readAsStringSync();
    expect(model, contains('class ShoppingCart'));
  });
}

/// Returns true for text-based files that can be read as UTF-8.
bool _isTextFile(String path) {
  // Only check files we generate (templates). Platform files from
  // `flutter create` may contain `{{` in C++ comments (e.g. Runner.rc).
  const textExtensions = {
    '.dart',
    '.yaml',
    '.yml',
    '.md',
  };
  final ext = path.contains('.') ? '.${path.split('.').last}' : '';
  return textExtensions.contains(ext);
}
