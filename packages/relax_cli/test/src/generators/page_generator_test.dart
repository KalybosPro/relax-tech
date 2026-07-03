import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:relax_cli/relax_cli.dart';
import 'package:test/test.dart';

/// A go_router file whose `cart` feature route is flat (no child `routes:`),
/// mimicking a project generated before nested page routing existed.
const _flatRouter = '''
import 'package:go_router/go_router.dart';

import '../../features/features.dart';

final appRouter = GoRouter(
  initialLocation: HomePage.routePath,
  routes: [
    GoRoute(
      path: CartPage.routePath,
      name: CartPage.routeName,
      builder: (context, state) => const CartPage(),
    ),
    // relax:router-routes
  ],
);
''';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('relax_page_gen_');
    Directory(
      '${tempDir.path}/lib/features/cart/view',
    ).createSync(recursive: true);
    File(
      '${tempDir.path}/lib/features/cart/cart.dart',
    ).writeAsStringSync("export 'view/cart_page.dart';\n");
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('PageGenerator route wiring', () {
    test('upgrades a flat feature route and nests the page under it', () async {
      final router = File('${tempDir.path}/lib/app/router/app_router.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync(_flatRouter);

      final gen = PageGenerator(logger: Logger(level: Level.quiet));
      final result = await gen.generate(
        folderName: 'cart',
        featureName: 'cart',
        pageName: 'cart_details',
        architecture: Architecture.bloc,
        projectDir: tempDir,
      );

      expect(result.routeWiring, RouteWiring.wired);

      final content = router.readAsStringSync();
      // The feature route gained a child routes list with the per-feature anchor.
      expect(content, contains('// relax:routes-cart'));
      // The page is nested inside it (before the anchor, after the builder).
      expect(content, contains('path: CartDetailsPage.routePath,'));
      expect(
        content.indexOf('CartDetailsPage'),
        lessThan(content.indexOf('// relax:routes-cart')),
      );

      // The page carries a relative child path and a unique route name.
      final page = File(
        '${tempDir.path}/lib/features/cart/view/cart_details_page.dart',
      ).readAsStringSync();
      expect(page, contains("static const routePath = 'cart_details';"));
      expect(page, contains("static const routeName = 'cartCartDetails';"));
    });

    test('is idempotent when the page route already exists', () async {
      File('${tempDir.path}/lib/app/router/app_router.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync(_flatRouter);

      final gen = PageGenerator(logger: Logger(level: Level.quiet));
      await gen.generate(
        folderName: 'cart',
        featureName: 'cart',
        pageName: 'cart_details',
        architecture: Architecture.bloc,
        projectDir: tempDir,
      );
      // Regenerate (page files overwrite) — route must not be duplicated.
      final second = await gen.generate(
        folderName: 'cart',
        featureName: 'cart',
        pageName: 'cart_details',
        architecture: Architecture.bloc,
        projectDir: tempDir,
      );

      expect(second.routeWiring, RouteWiring.alreadyPresent);
      final content = File(
        '${tempDir.path}/lib/app/router/app_router.dart',
      ).readAsStringSync();
      expect('const CartDetailsPage()'.allMatches(content).length, 1);
    });

    test('warns (anchorMissing) when the feature has no route', () async {
      // Router without any cart route.
      File('${tempDir.path}/lib/app/router/app_router.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:go_router/go_router.dart';
final appRouter = GoRouter(routes: [
  // relax:router-routes
]);
''');

      final gen = PageGenerator(logger: Logger(level: Level.quiet));
      final result = await gen.generate(
        folderName: 'cart',
        featureName: 'cart',
        pageName: 'cart_details',
        architecture: Architecture.bloc,
        projectDir: tempDir,
      );

      expect(result.routeWiring, RouteWiring.anchorMissing);
    });
  });
}
