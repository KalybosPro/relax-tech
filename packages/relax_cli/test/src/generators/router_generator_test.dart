import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:relax_cli/relax_cli.dart';
import 'package:test/test.dart';

/// Builds a minimal "legacy" project (no router) so we can test the
/// retroactive scaffold without running the slow `create` pipeline.
void _seedLegacyProject(Directory dir, {required bool getx}) {
  File('${dir.path}/pubspec.yaml')
    ..createSync(recursive: true)
    ..writeAsStringSync('''
name: app
dependencies:
  ${getx ? 'get: ^4.7.2' : 'flutter_bloc: ^9.1.1'}
  get_it: ^8.0.3
''');

  final appView = getx
      ? '''
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/core.dart';
import '../../features/home/home.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'app',
      initialBinding: HomeBinding(),
      home: const HomePage(),
    );
  }
}
'''
      : '''
import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../features/home/home.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'app',
      home: const HomePage(),
    );
  }
}
''';

  File('${dir.path}/lib/app/view/app.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync(appView);

  File('${dir.path}/lib/features/home/home.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync("export 'presentation/pages/home_page.dart';\n");

  File('${dir.path}/lib/features/home/presentation/pages/home_page.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync('''
import 'package:flutter/material.dart';

import 'home_view.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeView();
  }
}
''');
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('relax_router_gen_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('RouterGenerator', () {
    test('scaffolds go_router into a legacy Bloc project', () async {
      _seedLegacyProject(tempDir, getx: false);
      final gen = RouterGenerator(logger: Logger(level: Level.quiet));

      final result = await gen.scaffold(
        architecture: Architecture.bloc,
        projectDir: tempDir,
      );

      expect(result.routerCreated, isTrue);
      expect(result.appViewWired, isTrue);
      expect(result.homePageWired, isTrue);
      expect(result.pubspecUpdated, isTrue);

      final router = File('${tempDir.path}/lib/core/routing/app_router.dart');
      expect(router.existsSync(), isTrue);

      // The aggregate barrel is created and exports the existing home feature.
      final barrel = File('${tempDir.path}/lib/features/features.dart');
      expect(barrel.existsSync(), isTrue);
      expect(barrel.readAsStringSync(), contains("export 'home/home.dart';"));

      final appView = File(
        '${tempDir.path}/lib/app/view/app.dart',
      ).readAsStringSync();
      expect(appView, contains('MaterialApp.router('));
      expect(appView, contains('routerConfig: appRouter'));
      expect(appView, contains("import '../../core/routing/app_router.dart';"));
      // The now-unused home barrel import is dropped.
      expect(appView, isNot(contains("features/home/home.dart")));

      final home = File(
        '${tempDir.path}/lib/features/home/presentation/pages/home_page.dart',
      ).readAsStringSync();
      expect(home, contains("static const routePath = '/';"));

      final pubspec = File('${tempDir.path}/pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('go_router:'));
    });

    test('scaffolds GetX getPages into a legacy GetX project', () async {
      _seedLegacyProject(tempDir, getx: true);
      final gen = RouterGenerator(logger: Logger(level: Level.quiet));

      final result = await gen.scaffold(
        architecture: Architecture.getx,
        projectDir: tempDir,
      );

      expect(result.routerCreated, isTrue);
      expect(result.appViewWired, isTrue);
      // GetX does not need go_router.
      expect(result.pubspecUpdated, isFalse);

      expect(
        File('${tempDir.path}/lib/core/routing/app_pages.dart').existsSync(),
        isTrue,
      );

      final appView = File(
        '${tempDir.path}/lib/app/view/app.dart',
      ).readAsStringSync();
      expect(appView, contains('getPages: appPages'));
      expect(appView, contains('initialRoute: HomePage.routePath'));
      expect(appView, contains("import '../../core/routing/app_pages.dart';"));
      // GetX still references HomePage.routePath, so its import stays.
      expect(appView, contains('features/home/home.dart'));

      final pubspec = File('${tempDir.path}/pubspec.yaml').readAsStringSync();
      expect(pubspec, isNot(contains('go_router:')));
    });

    test('is idempotent: a second scaffold reports alreadyPresent', () async {
      _seedLegacyProject(tempDir, getx: false);
      final gen = RouterGenerator(logger: Logger(level: Level.quiet));

      await gen.scaffold(architecture: Architecture.bloc, projectDir: tempDir);
      final second = await gen.scaffold(
        architecture: Architecture.bloc,
        projectDir: tempDir,
      );

      expect(second.alreadyPresent, isTrue);
      expect(second.routerCreated, isFalse);
    });

    test('warns when the home page is missing instead of failing', () async {
      _seedLegacyProject(tempDir, getx: false);
      File(
        '${tempDir.path}/lib/features/home/presentation/pages/home_page.dart',
      ).deleteSync();
      final gen = RouterGenerator(logger: Logger(level: Level.quiet));

      final result = await gen.scaffold(
        architecture: Architecture.bloc,
        projectDir: tempDir,
      );

      expect(result.routerCreated, isTrue);
      expect(result.homePageWired, isFalse);
      expect(result.warnings, isNotEmpty);
    });
  });

  group('generate router command', () {
    test('creates the router via the CLI and detects architecture', () async {
      _seedLegacyProject(tempDir, getx: false);
      final runner = RelaxCommandRunner();
      final originalDir = Directory.current;
      Directory.current = tempDir;

      try {
        final code = await runner.run(['generate', 'router']);
        expect(code, equals(ExitCode.success.code));
        expect(
          File('${tempDir.path}/lib/core/routing/app_router.dart').existsSync(),
          isTrue,
        );
      } finally {
        Directory.current = originalDir;
      }
    });
  });
}
