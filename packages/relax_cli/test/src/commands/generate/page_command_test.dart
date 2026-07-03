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
    tempDir = Directory.systemTemp.createTempSync('relax_page_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } on FileSystemException {
        // Windows may still hold a handle from a build_runner subprocess.
      }
    }
  });

  Future<void> createProject(String name, String arch) async {
    final originalDir = Directory.current;
    Directory.current = tempDir;
    try {
      await runner.run(['create', name, '-a', arch]);
    } finally {
      Directory.current = originalDir;
    }
  }

  group('PageCommand', () {
    test('two-arg form generates and auto-exports the page', () async {
      await createProject('app', 'bloc');
      final originalDir = Directory.current;
      Directory.current = Directory('${tempDir.path}/app');

      try {
        final code = await runner.run(['g', 'page', 'home', 'detail']);
        expect(code, equals(ExitCode.success.code));

        expect(
          File(
            '${tempDir.path}/app/lib/features/home/view/detail_page.dart',
          ).existsSync(),
          isTrue,
        );

        // The page is auto-exported from the feature barrel.
        final barrel = File(
          '${tempDir.path}/app/lib/features/home/home.dart',
        ).readAsStringSync();
        expect(barrel, contains("export 'view/detail_page.dart';"));
      } finally {
        Directory.current = originalDir;
      }
    });

    test('single-arg path spec (feature/page) works', () async {
      await createProject('app', 'bloc');
      final originalDir = Directory.current;
      Directory.current = Directory('${tempDir.path}/app');

      try {
        final code = await runner.run(['g', 'page', 'home/settings']);
        expect(code, equals(ExitCode.success.code));

        expect(
          File(
            '${tempDir.path}/app/lib/features/home/view/settings_page.dart',
          ).existsSync(),
          isTrue,
        );
        final barrel = File(
          '${tempDir.path}/app/lib/features/home/home.dart',
        ).readAsStringSync();
        expect(barrel, contains("export 'view/settings_page.dart';"));
      } finally {
        Directory.current = originalDir;
      }
    });

    test('registers the page as a child route of its feature', () async {
      await createProject('app', 'bloc');
      final originalDir = Directory.current;
      Directory.current = Directory('${tempDir.path}/app');

      try {
        // Mother feature first, then a child page under it.
        await runner.run(['g', 'feature', 'product']);
        final code = await runner.run(['g', 'page', 'product/product_details']);
        expect(code, equals(ExitCode.success.code));

        final router = File(
          '${tempDir.path}/app/lib/app/router/app_router.dart',
        ).readAsStringSync();

        // The child GoRoute is nested under the product feature route.
        expect(router, contains('// relax:routes-product'));
        expect(router, contains('path: ProductDetailsPage.routePath,'));
        final childIndex = router.indexOf('ProductDetailsPage');
        final anchorIndex = router.indexOf('// relax:routes-product');
        expect(
          childIndex,
          lessThan(anchorIndex),
          reason: 'child route sits inside the product routes list',
        );

        final page = File(
          '${tempDir.path}/app/lib/features/product/view/product_details_page.dart',
        ).readAsStringSync();
        expect(
          page,
          contains("static const routeName = 'productProductDetails';"),
        );
        expect(page, contains("static const routePath = 'product_details';"));
      } finally {
        Directory.current = originalDir;
      }
    });

    test('--no-route skips route registration', () async {
      await createProject('app', 'bloc');
      final originalDir = Directory.current;
      Directory.current = Directory('${tempDir.path}/app');

      try {
        await runner.run(['g', 'feature', 'product']);
        final router = File(
          '${tempDir.path}/app/lib/app/router/app_router.dart',
        );
        final before = router.readAsStringSync();

        await runner.run([
          'g',
          'page',
          'product/product_details',
          '--no-route',
        ]);
        expect(router.readAsStringSync(), equals(before));
      } finally {
        Directory.current = originalDir;
      }
    });

    test('exits with usage for a bare single arg (no slash)', () async {
      await createProject('app', 'bloc');
      final originalDir = Directory.current;
      Directory.current = Directory('${tempDir.path}/app');

      try {
        final code = await runner.run(['g', 'page', 'home']);
        expect(code, equals(ExitCode.usage.code));
      } finally {
        Directory.current = originalDir;
      }
    });
  });
}
