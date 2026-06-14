import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:relax_cli/relax_cli.dart';
import 'package:test/test.dart';

void main() {
  late ProjectGenerator generator;
  late Directory tempDir;

  setUp(() {
    generator = ProjectGenerator(logger: Logger());
    tempDir = Directory.systemTemp.createTempSync('relax_gen_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('ProjectGenerator', () {
    test('generates project directory named after project', () async {
      await generator.generate(
        projectName: 'my_project',
        architecture: Architecture.bloc,
        outputDirectory: tempDir,
      );

      expect(
        Directory('${tempDir.path}/my_project').existsSync(),
        isTrue,
      );
    });

    test('generated files contain substituted project name', () async {
      await generator.generate(
        projectName: 'awesome_app',
        architecture: Architecture.bloc,
        outputDirectory: tempDir,
      );

      final pubspec =
          File('${tempDir.path}/awesome_app/pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('name: awesome_app'));

      final appView =
          File('${tempDir.path}/awesome_app/lib/app/view/app.dart')
              .readAsStringSync();
      expect(appView, contains('Awesome App'));
    });

    test('generated theme files contain light and dark themes', () async {
      await generator.generate(
        projectName: 'test_app',
        architecture: Architecture.bloc,
        outputDirectory: tempDir,
      );

      final theme =
          File('${tempDir.path}/test_app/lib/core/theme/app_theme.dart')
              .readAsStringSync();
      expect(theme, contains('static ThemeData get light'));
      expect(theme, contains('static ThemeData get dark'));
      expect(theme, contains('useMaterial3: true'));
      expect(theme, contains('ColorScheme.fromSeed'));
    });

    test('generated color file contains seed color', () async {
      await generator.generate(
        projectName: 'test_app',
        architecture: Architecture.bloc,
        outputDirectory: tempDir,
      );

      final colors =
          File('${tempDir.path}/test_app/lib/core/theme/app_colors.dart')
              .readAsStringSync();
      expect(colors, contains('static const seed'));
      expect(colors, contains('0xFF6750A4'));
    });

    test('custom primary color is substituted', () async {
      await generator.generate(
        projectName: 'test_app',
        architecture: Architecture.bloc,
        outputDirectory: tempDir,
        primaryColor: '1565C0',
      );

      final colors =
          File('${tempDir.path}/test_app/lib/core/theme/app_colors.dart')
              .readAsStringSync();
      expect(colors, contains('0xFF1565C0'));
    });

    test('custom font family is substituted', () async {
      await generator.generate(
        projectName: 'test_app',
        architecture: Architecture.bloc,
        outputDirectory: tempDir,
        fontFamily: 'Poppins',
      );

      final typo =
          File('${tempDir.path}/test_app/lib/core/theme/app_typography.dart')
              .readAsStringSync();
      expect(typo, contains("'Poppins'"));
    });

    test('custom description is substituted', () async {
      await generator.generate(
        projectName: 'test_app',
        architecture: Architecture.bloc,
        outputDirectory: tempDir,
        description: 'My custom app description',
      );

      final pubspec =
          File('${tempDir.path}/test_app/pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('description: My custom app description'));
    });
  });

  group('Bloc template', () {
    test('generates 17 files', () async {
      final files = await generator.generate(
        projectName: 'test_app',
        architecture: Architecture.bloc,
        outputDirectory: tempDir,
      );
      expect(files, hasLength(25));
    });

    test('uses sealed classes for events and states', () async {
      await generator.generate(
        projectName: 'test_app',
        architecture: Architecture.bloc,
        outputDirectory: tempDir,
      );

      final event =
          File('${tempDir.path}/test_app/lib/features/home/bloc/home_event.dart')
              .readAsStringSync();
      expect(event, contains('sealed class HomeEvent'));

      final state =
          File('${tempDir.path}/test_app/lib/features/home/bloc/home_state.dart')
              .readAsStringSync();
      expect(state, contains('sealed class HomeState'));
    });

    test('pubspec includes flutter_bloc and equatable', () async {
      await generator.generate(
        projectName: 'test_app',
        architecture: Architecture.bloc,
        outputDirectory: tempDir,
      );

      final pubspec =
          File('${tempDir.path}/test_app/pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('flutter_bloc'));
      expect(pubspec, contains('equatable'));
    });
  });

  group('Provider template', () {
    test('generates 16 files', () async {
      final files = await generator.generate(
        projectName: 'test_app',
        architecture: Architecture.provider,
        outputDirectory: tempDir,
      );
      expect(files, hasLength(24));
    });

    test('uses ChangeNotifier pattern', () async {
      await generator.generate(
        projectName: 'test_app',
        architecture: Architecture.provider,
        outputDirectory: tempDir,
      );

      final notifier = File(
        '${tempDir.path}/test_app/lib/features/home/notifiers/home_notifier.dart',
      ).readAsStringSync();
      expect(notifier, contains('class HomeNotifier extends ChangeNotifier'));

      final view =
          File('${tempDir.path}/test_app/lib/features/home/view/home_view.dart')
              .readAsStringSync();
      expect(view, contains('context.watch<HomeNotifier>()'));
    });

    test('pubspec includes provider', () async {
      await generator.generate(
        projectName: 'test_app',
        architecture: Architecture.provider,
        outputDirectory: tempDir,
      );

      final pubspec =
          File('${tempDir.path}/test_app/pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('provider:'));
    });
  });

  group('Riverpod template', () {
    test('generates 16 files', () async {
      final files = await generator.generate(
        projectName: 'test_app',
        architecture: Architecture.riverpod,
        outputDirectory: tempDir,
      );
      expect(files, hasLength(24));
    });

    test('uses Notifier and ConsumerWidget pattern', () async {
      await generator.generate(
        projectName: 'test_app',
        architecture: Architecture.riverpod,
        outputDirectory: tempDir,
      );

      final provider = File(
        '${tempDir.path}/test_app/lib/features/home/providers/home_provider.dart',
      ).readAsStringSync();
      expect(provider, contains('class HomeNotifier extends Notifier'));

      final view =
          File('${tempDir.path}/test_app/lib/features/home/view/home_view.dart')
              .readAsStringSync();
      expect(view, contains('ConsumerWidget'));
      expect(view, contains('ref.watch(homeProvider)'));
    });

    test('bootstrap.dart wraps with ProviderScope', () async {
      await generator.generate(
        projectName: 'test_app',
        architecture: Architecture.riverpod,
        outputDirectory: tempDir,
      );

      final bootstrap =
          File('${tempDir.path}/test_app/lib/bootstrap.dart')
              .readAsStringSync();
      expect(bootstrap, contains('ProviderScope'));
    });

    test('pubspec includes flutter_riverpod', () async {
      await generator.generate(
        projectName: 'test_app',
        architecture: Architecture.riverpod,
        outputDirectory: tempDir,
      );

      final pubspec =
          File('${tempDir.path}/test_app/pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('flutter_riverpod'));
    });
  });

  group('GetX template', () {
    test('generates 16 files', () async {
      final files = await generator.generate(
        projectName: 'test_app',
        architecture: Architecture.getx,
        outputDirectory: tempDir,
      );
      expect(files, hasLength(24));
    });

    test('uses GetxController and Obx pattern', () async {
      await generator.generate(
        projectName: 'test_app',
        architecture: Architecture.getx,
        outputDirectory: tempDir,
      );

      final controller = File(
        '${tempDir.path}/test_app/lib/features/home/controllers/home_controller.dart',
      ).readAsStringSync();
      expect(controller, contains('class HomeController extends GetxController'));

      final view =
          File('${tempDir.path}/test_app/lib/features/home/view/home_view.dart')
              .readAsStringSync();
      expect(view, contains('GetView<HomeController>'));
      expect(view, contains('Obx('));
    });

    test('uses GetMaterialApp', () async {
      await generator.generate(
        projectName: 'test_app',
        architecture: Architecture.getx,
        outputDirectory: tempDir,
      );

      final appView =
          File('${tempDir.path}/test_app/lib/app/view/app.dart')
              .readAsStringSync();
      expect(appView, contains('GetMaterialApp'));
    });

    test('has bindings', () async {
      await generator.generate(
        projectName: 'test_app',
        architecture: Architecture.getx,
        outputDirectory: tempDir,
      );

      final binding = File(
        '${tempDir.path}/test_app/lib/features/home/bindings/home_binding.dart',
      ).readAsStringSync();
      expect(binding, contains('class HomeBinding extends Bindings'));
    });

    test('pubspec includes get', () async {
      await generator.generate(
        projectName: 'test_app',
        architecture: Architecture.getx,
        outputDirectory: tempDir,
      );

      final pubspec =
          File('${tempDir.path}/test_app/pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('get:'));
    });
  });

  group('All architectures share theme', () {
    for (final arch in Architecture.values) {
      test('${arch.name} includes theme files', () async {
        await generator.generate(
          projectName: 'test_app',
          architecture: arch,
          outputDirectory: tempDir,
        );

        final base = '${tempDir.path}/test_app/lib/core/theme';
        expect(File('$base/app_theme.dart').existsSync(), isTrue);
        expect(File('$base/app_colors.dart').existsSync(), isTrue);
        expect(File('$base/app_typography.dart').existsSync(), isTrue);
      });
    }
  });
}
