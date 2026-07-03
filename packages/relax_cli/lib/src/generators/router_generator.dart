import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

import '../models/architecture.dart';
import '../templates/shared_template.dart';
import '../utils/source_patcher.dart';

/// Outcome of scaffolding the app router into an existing project.
class RouterScaffoldResult {
  RouterScaffoldResult({
    required this.alreadyPresent,
    required this.routerCreated,
    required this.homePageWired,
    required this.appViewWired,
    required this.pubspecUpdated,
    required this.warnings,
  });

  /// The router file already existed; nothing was created.
  final bool alreadyPresent;

  /// The router file was written.
  final bool routerCreated;

  /// `HomePage` now exposes `routeName` / `routePath` (added or already there).
  final bool homePageWired;

  /// `app/view/app.dart` now uses the router (patched or already wired).
  final bool appViewWired;

  /// A `go_router` dependency was added to pubspec.yaml.
  final bool pubspecUpdated;

  /// Human-readable notes about steps that need manual attention.
  final List<String> warnings;
}

/// Retroactively scaffolds the navigation layer into an **existing** project:
/// creates the router file in the app composition root, gives `HomePage` its
/// route identity, and rewires `app/view/app.dart` to drive the router.
///
/// Every step is guarded so the command is safe to re-run, and unrecognized
/// (hand-customized) `app.dart` shapes degrade to a warning with manual
/// instructions instead of corrupting the file.
class RouterGenerator {
  const RouterGenerator({required Logger logger}) : _logger = logger;

  final Logger _logger;

  Future<RouterScaffoldResult> scaffold({
    required Architecture architecture,
    required Directory projectDir,
  }) async {
    final isGetx = architecture == Architecture.getx;
    final routerRelPath = isGetx
        ? 'lib/app/router/app_pages.dart'
        : 'lib/app/router/app_router.dart';
    final routerFile = File('${projectDir.path}/$routerRelPath');

    if (routerFile.existsSync()) {
      return RouterScaffoldResult(
        alreadyPresent: true,
        routerCreated: false,
        homePageWired: true,
        appViewWired: true,
        pubspecUpdated: true,
        warnings: const [],
      );
    }

    final warnings = <String>[];

    // 1. Give HomePage its route identity (idempotent).
    final homePageWired = _wireHomePage(projectDir, warnings);

    // 2. Ensure the aggregate features barrel exists (the router imports it).
    _ensureFeaturesBarrel(projectDir);

    // 3. Write the router file.
    routerFile.parent.createSync(recursive: true);
    routerFile.writeAsStringSync(
      isGetx ? SharedTemplate.appPagesGetx : SharedTemplate.appRouter,
    );
    _logger.detail('Created $routerRelPath');

    // 4. Rewire app/view/app.dart to drive the router.
    final appViewWired = _wireAppView(
      projectDir,
      isGetx: isGetx,
      warnings: warnings,
    );

    // 5. Add the go_router dependency (go_router architectures only).
    final pubspecUpdated = isGetx
        ? false
        : _addGoRouterDependency(projectDir, warnings);

    return RouterScaffoldResult(
      alreadyPresent: false,
      routerCreated: true,
      homePageWired: homePageWired,
      appViewWired: appViewWired,
      pubspecUpdated: pubspecUpdated,
      warnings: warnings,
    );
  }

  /// Creates `lib/features/features.dart` if missing, re-exporting every
  /// existing feature barrel (a `<dir>/<dir>.dart` file). Left untouched if it
  /// already exists.
  void _ensureFeaturesBarrel(Directory projectDir) {
    final barrel = File('${projectDir.path}/lib/features/features.dart');
    if (barrel.existsSync()) return;

    final featuresDir = Directory('${projectDir.path}/lib/features');
    if (!featuresDir.existsSync()) return;

    final exports = <String>[];
    for (final entity in featuresDir.listSync(recursive: true)) {
      if (entity is! Directory) continue;
      final dirName = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
      final featureBarrel = File('${entity.path}/$dirName.dart');
      if (!featureBarrel.existsSync()) continue;
      final rel = featureBarrel.path
          .substring(featuresDir.path.length + 1)
          .replaceAll(r'\', '/');
      exports.add("export '$rel';");
    }
    exports.sort();

    barrel.writeAsStringSync('${exports.join('\n')}\n// relax:features\n');
    _logger.detail('Created lib/features/features.dart');
  }

  bool _wireHomePage(Directory projectDir, List<String> warnings) {
    final homePage = File(
      '${projectDir.path}/lib/features/home/view/home_page.dart',
    );
    if (!homePage.existsSync()) {
      warnings.add(
        'lib/features/home/view/home_page.dart not found — add '
        "`static const routeName` / `routePath` to your home page manually.",
      );
      return false;
    }

    final result = SourcePatcher.insertAfterAnchor(
      homePage,
      anchor: 'const HomePage({super.key});',
      snippet: '''

  /// Route name used with the app router.
  static const routeName = 'home';

  /// URL path registered in the app router.
  static const routePath = '/';''',
      guard: 'routePath',
    );

    if (result.status == PatchStatus.anchorMissing) {
      warnings.add(
        'Could not locate the HomePage constructor — add '
        "`static const routeName = 'home';` and `static const routePath = '/';` "
        'to HomePage manually.',
      );
      return false;
    }
    return true;
  }

  bool _wireAppView(
    Directory projectDir, {
    required bool isGetx,
    required List<String> warnings,
  }) {
    final appView = File('${projectDir.path}/lib/app/view/app.dart');
    if (!appView.existsSync()) {
      warnings.add(
        'lib/app/view/app.dart not found — wire the router manually.',
      );
      return false;
    }

    final importSnippet = isGetx
        ? "import '../router/app_pages.dart';"
        : "import '../router/app_router.dart';";
    SourcePatcher.insertAfterAnchor(
      appView,
      anchor: "import '../../core/core.dart';",
      snippet: importSnippet,
      guard: isGetx ? 'router/app_pages.dart' : 'router/app_router.dart',
    );

    if (isGetx) {
      final home = SourcePatcher.replaceOnce(
        appView,
        from: 'home: const HomePage(),',
        to: 'getPages: appPages,',
        guard: 'getPages: appPages',
      );
      SourcePatcher.replaceOnce(
        appView,
        from: 'initialBinding: HomeBinding(),',
        to: 'initialRoute: HomePage.routePath,',
        guard: 'initialRoute: HomePage.routePath',
      );
      if (home.status == PatchStatus.anchorMissing) {
        warnings.add(
          'Could not rewire app.dart automatically — replace `home:`/'
          '`initialBinding:` with `getPages: appPages` and '
          '`initialRoute: HomePage.routePath` in GetMaterialApp.',
        );
        return false;
      }
      return true;
    }

    final mat = SourcePatcher.replaceOnce(
      appView,
      from: 'MaterialApp(',
      to: 'MaterialApp.router(',
      guard: 'MaterialApp.router(',
    );
    final home = SourcePatcher.replaceOnce(
      appView,
      from: 'home: const HomePage(),',
      to: 'routerConfig: appRouter,',
      guard: 'routerConfig: appRouter',
    );
    if (mat.status == PatchStatus.anchorMissing ||
        home.status == PatchStatus.anchorMissing) {
      warnings.add(
        'Could not rewire app.dart automatically — switch `MaterialApp(` to '
        '`MaterialApp.router(` and replace `home:` with '
        '`routerConfig: appRouter`.',
      );
      return false;
    }
    _removeUnusedHomeImport(appView);
    return true;
  }

  /// Drops the `features/home/home.dart` import once nothing in the file
  /// references a `Home*` symbol anymore (Bloc/Riverpod after rewiring). Kept
  /// for Provider (`HomeNotifier`) and GetX (`HomePage.routePath`).
  void _removeUnusedHomeImport(File appView) {
    const homeImport = "import '../../features/home/home.dart';";
    final content = appView.readAsStringSync();
    if (!content.contains(homeImport)) return;

    final body = content.replaceFirst(homeImport, '');
    if (RegExp(r'Home[A-Z]\w*').hasMatch(body)) return;

    appView.writeAsStringSync(
      content.replaceFirst('$homeImport\n', '').replaceFirst(homeImport, ''),
    );
  }

  bool _addGoRouterDependency(Directory projectDir, List<String> warnings) {
    final pubspec = File('${projectDir.path}/pubspec.yaml');
    if (!pubspec.existsSync()) return false;

    final result = SourcePatcher.insertAfterAnchor(
      pubspec,
      anchor: 'get_it:',
      snippet: '  go_router: ^14.6.0',
      guard: 'go_router:',
    );
    if (result.status == PatchStatus.anchorMissing) {
      warnings.add(
        'Add `go_router: ^14.6.0` to pubspec.yaml, then run pub get.',
      );
      return false;
    }
    if (result.status == PatchStatus.inserted) {
      warnings.add('Added go_router to pubspec.yaml — run `relax pub get`.');
    }
    return result.status == PatchStatus.inserted;
  }
}
