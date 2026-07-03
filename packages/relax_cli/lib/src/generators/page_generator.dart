import 'dart:io';

import 'package:mason/mason.dart';

import '../models/architecture.dart';
import '../templates/page_template.dart';
import '../utils/source_patcher.dart';
import 'feature_generator.dart' show RouteWiring;

/// The result of generating a page: the files created and how (or whether) its
/// route was registered as a child of the feature route.
class PageResult {
  const PageResult({required this.files, required this.routeWiring});

  final List<GeneratedFile> files;
  final RouteWiring routeWiring;
}

/// Generates a Page + View pair inside an existing feature folder.
class PageGenerator {
  const PageGenerator({required Logger logger}) : _logger = logger;

  final Logger _logger;

  /// Generates page files inside `lib/features/[folderName]/view/` of
  /// [projectDir].
  ///
  /// [folderName] is the feature path under `lib/features/` and may be nested
  /// (e.g. `auth/login`). [featureName] is the leaf segment used to derive class
  /// names (e.g. the bloc/notifier referenced by the page).
  ///
  /// When [wireRoute] is true, the page is registered as a **child route** of
  /// its feature (nested `GoRoute` for go_router, flat `GetPage` for GetX).
  Future<PageResult> generate({
    required String folderName,
    required String featureName,
    required String pageName,
    required Architecture architecture,
    required Directory projectDir,
    bool wireRoute = true,
  }) async {
    final files = switch (architecture) {
      Architecture.bloc => PageTemplate.bloc,
      Architecture.provider => PageTemplate.provider,
      Architecture.riverpod => PageTemplate.riverpod,
      Architecture.getx => PageTemplate.getx,
    };

    final parentSegments = folderName.split('/').where((s) => s.isNotEmpty);
    final routeName = _camelCase([...parentSegments, pageName]);
    // go_router child paths are relative; GetX has no nesting so it needs the
    // absolute path.
    final routePath = architecture == Architecture.getx
        ? '/${parentSegments.join('/')}/$pageName'
        : pageName;

    final generator = MasonGenerator(
      '${architecture.name}_page',
      '${architecture.label} page.',
      files: files,
      vars: ['feature_name', 'page_name', 'route_name', 'route_path'],
    );

    final featureDir = Directory('${projectDir.path}/lib/features/$folderName');
    final target = DirectoryGeneratorTarget(featureDir);

    final generatedFiles = await generator.generate(
      target,
      vars: <String, dynamic>{
        'feature_name': featureName,
        'page_name': pageName,
        'route_name': routeName,
        'route_path': routePath,
      },
      logger: _logger,
    );

    final wiring = wireRoute
        ? _wireChildRoute(
            projectDir: projectDir,
            architecture: architecture,
            folderName: folderName,
            featureName: featureName,
            pageName: pageName,
          )
        : RouteWiring.skipped;

    return PageResult(files: generatedFiles, routeWiring: wiring);
  }

  /// Registers the page under its feature's route.
  RouteWiring _wireChildRoute({
    required Directory projectDir,
    required Architecture architecture,
    required String folderName,
    required String featureName,
    required String pageName,
  }) {
    final parentSegments = folderName
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();
    final parentRouteName = _camelCase(parentSegments);
    final pageClass = '${_pascalCase(pageName)}Page';

    // GetX is flat: register a top-level GetPage carrying the feature binding.
    if (architecture == Architecture.getx) {
      final file = File('${projectDir.path}/lib/app/router/app_pages.dart');
      if (!file.existsSync()) return RouteWiring.routerMissing;
      return _map(
        SourcePatcher.insertBeforeAnchor(
          file,
          anchor: '// relax:router-routes',
          snippet:
              '  GetPage(\n'
              '    name: $pageClass.routePath,\n'
              '    page: () => const $pageClass(),\n'
              '    binding: ${_pascalCase(featureName)}Binding(),\n'
              '  ),',
          guard: 'const $pageClass()',
        ).status,
      );
    }

    // go_router: nest the page under the feature's `routes:` list.
    final file = File('${projectDir.path}/lib/app/router/app_router.dart');
    if (!file.existsSync()) return RouteWiring.routerMissing;

    final anchor = '// relax:routes-$parentRouteName';
    final parentPageClass = '${_pascalCase(featureName)}Page';

    // Older feature routes were generated flat (no child list). Upgrade the
    // feature's GoRoute in place by inserting a `routes:` list after its
    // builder, so the page has somewhere to nest.
    if (!file.readAsStringSync().contains(anchor)) {
      final upgrade = SourcePatcher.insertAfterAnchor(
        file,
        anchor: 'builder: (context, state) => const $parentPageClass(),',
        snippet: '      routes: [\n        $anchor\n      ],',
        guard: anchor,
      );
      if (upgrade.status != PatchStatus.inserted) {
        return RouteWiring.anchorMissing;
      }
    }

    return _map(
      SourcePatcher.insertBeforeAnchor(
        file,
        anchor: anchor,
        snippet:
            '        GoRoute(\n'
            '          path: $pageClass.routePath,\n'
            '          name: $pageClass.routeName,\n'
            '          builder: (context, state) => const $pageClass(),\n'
            '        ),',
        guard: 'const $pageClass()',
      ).status,
    );
  }

  RouteWiring _map(PatchStatus status) => switch (status) {
    PatchStatus.inserted => RouteWiring.wired,
    PatchStatus.skipped => RouteWiring.alreadyPresent,
    _ => RouteWiring.anchorMissing,
  };

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

  String _pascalCase(String snake) => snake
      .split('_')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join();
}
