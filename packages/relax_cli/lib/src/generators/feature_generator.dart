import 'dart:io';

import 'package:mason/mason.dart';

import '../models/architecture.dart';
import '../templates/feature_template.dart';
import '../utils/source_patcher.dart';

/// How a feature's route was wired into the app router.
enum RouteWiring {
  /// The route was inserted into `lib/app/router/app_router.dart`.
  wired,

  /// Wiring was requested but the route was already present.
  alreadyPresent,

  /// Wiring was requested but no router file was found (legacy project).
  routerMissing,

  /// The router file exists but its `relax:` anchors were removed.
  anchorMissing,

  /// Wiring was not requested (`--no-route`) or unsupported for the
  /// architecture in this release.
  skipped,
}

/// The result of generating a feature: the files created and how (or whether)
/// its route was registered.
class FeatureResult {
  const FeatureResult({required this.files, required this.routeWiring});

  final List<GeneratedFile> files;
  final RouteWiring routeWiring;
}

/// Generates a new feature module inside an existing Flutter project.
class FeatureGenerator {
  const FeatureGenerator({required Logger logger}) : _logger = logger;

  final Logger _logger;

  /// Generates the feature files inside `lib/features/[subPath]/` of
  /// [projectDir].
  ///
  /// [subPath] is an optional parent path (e.g. `auth` or `a/b/c`) that is
  /// created (recursively) before generation. When empty, files land directly
  /// under `lib/features/`.
  ///
  /// When [wireRoute] is true, the feature's `GoRoute` is registered in
  /// `lib/app/router/app_router.dart` (see [RouteWiring] for the outcomes).
  Future<FeatureResult> generate({
    required String featureName,
    required Architecture architecture,
    required Directory projectDir,
    String subPath = '',
    bool wireRoute = true,
  }) async {
    final files = switch (architecture) {
      Architecture.bloc => FeatureTemplate.bloc,
      Architecture.provider => FeatureTemplate.provider,
      Architecture.riverpod => FeatureTemplate.riverpod,
      Architecture.getx => FeatureTemplate.getx,
    };

    // Route identity is derived from the *full* path so that features sharing a
    // leaf name (`auth/login`, `admin/login`) get distinct route names.
    final segments = [
      if (subPath.isNotEmpty) ...subPath.split('/'),
      featureName,
    ];
    final routeName = _camelCase(segments);
    final routePath = '/${segments.join('/')}';

    final generator = MasonGenerator(
      '${architecture.name}_feature',
      '${architecture.label} feature module.',
      files: files,
      vars: ['feature_name', 'route_name', 'route_path'],
    );

    final featuresPath = subPath.isEmpty
        ? '${projectDir.path}/lib/features'
        : '${projectDir.path}/lib/features/$subPath';
    final featuresDir = Directory(featuresPath)..createSync(recursive: true);
    final target = DirectoryGeneratorTarget(featuresDir);

    final generatedFiles = await generator.generate(
      target,
      vars: <String, dynamic>{
        'feature_name': featureName,
        'route_name': routeName,
        'route_path': routePath,
      },
      logger: _logger,
    );

    final wiring = wireRoute
        ? _wireRoute(
            projectDir: projectDir,
            architecture: architecture,
            featureName: featureName,
            subPath: subPath,
          )
        : RouteWiring.skipped;

    return FeatureResult(files: generatedFiles, routeWiring: wiring);
  }

  /// Registers the feature's route in `lib/app/router/app_router.dart` using the
  /// anchor markers emitted by the `create` template.
  RouteWiring _wireRoute({
    required Directory projectDir,
    required Architecture architecture,
    required String featureName,
    required String subPath,
  }) {
    final pageClass = '${_pascalCase(featureName)}Page';
    final featurePath = subPath.isEmpty ? featureName : '$subPath/$featureName';
    final segments = [
      if (subPath.isNotEmpty) ...subPath.split('/'),
      featureName,
    ];
    final routeName = _camelCase(segments);

    // Bloc/Provider/Riverpod use go_router (app_router.dart); GetX uses its own
    // route table (app_pages.dart) so each entry can carry its binding.
    //
    // The go_router entry exposes a nested `routes:` list (anchored per
    // feature) so `relax generate page` can register a page as a child route.
    final (routerFile, routeSnippet) = switch (architecture) {
      Architecture.getx => (
        File('${projectDir.path}/lib/app/router/app_pages.dart'),
        '  GetPage(\n'
            '    name: $pageClass.routePath,\n'
            '    page: () => const $pageClass(),\n'
            '    binding: ${_pascalCase(featureName)}Binding(),\n'
            '  ),',
      ),
      _ => (
        File('${projectDir.path}/lib/app/router/app_router.dart'),
        '    GoRoute(\n'
            '      path: $pageClass.routePath,\n'
            '      name: $pageClass.routeName,\n'
            '      builder: (context, state) => const $pageClass(),\n'
            '      routes: [\n'
            '        // relax:routes-$routeName\n'
            '      ],\n'
            '    ),',
      ),
    };

    if (!routerFile.existsSync()) return RouteWiring.routerMissing;

    // The feature is reached through the aggregate barrel, so register its
    // export there rather than importing it directly into the router.
    final exportResult = exportFeature(
      projectDir: projectDir,
      featurePath: featurePath,
      featureName: featureName,
    );

    final routeResult = SourcePatcher.insertBeforeAnchor(
      routerFile,
      anchor: '// relax:router-routes',
      snippet: routeSnippet,
      guard: '$pageClass.routePath',
    );

    if (routeResult.status == PatchStatus.anchorMissing ||
        exportResult == PatchStatus.anchorMissing ||
        exportResult == PatchStatus.fileMissing) {
      return RouteWiring.anchorMissing;
    }
    if (routeResult.status == PatchStatus.skipped) {
      return RouteWiring.alreadyPresent;
    }
    return RouteWiring.wired;
  }

  /// Adds `export '<featurePath>/<name>.dart';` to the aggregate
  /// `lib/features/features.dart` barrel (idempotent).
  PatchStatus exportFeature({
    required Directory projectDir,
    required String featurePath,
    required String featureName,
  }) {
    final barrel = File('${projectDir.path}/lib/features/features.dart');
    final exportPath = '$featurePath/$featureName.dart';
    return SourcePatcher.insertBeforeAnchor(
      barrel,
      anchor: '// relax:features',
      snippet: "export '$exportPath';",
      guard: "'$exportPath'",
    ).status;
  }

  /// `['auth', 'login']` → `authLogin`; `['user_profile']` → `userProfile`.
  String _camelCase(List<String> segments) {
    final words = segments
        .expand((s) => s.split('_'))
        .where((w) => w.isNotEmpty);
    final buffer = StringBuffer();
    var first = true;
    for (final word in words) {
      if (first) {
        buffer.write(word);
        first = false;
      } else {
        buffer.write(word[0].toUpperCase() + word.substring(1));
      }
    }
    return buffer.toString();
  }

  /// `user_profile` → `UserProfile`.
  String _pascalCase(String snake) => snake
      .split('_')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join();
}
