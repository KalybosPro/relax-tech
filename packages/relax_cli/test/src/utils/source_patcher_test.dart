import 'dart:io';

import 'package:relax_cli/src/utils/source_patcher.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('relax_patcher_test');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  File writeFile(String content) {
    final file = File('${tempDir.path}/app_router.dart');
    file.writeAsStringSync(content);
    return file;
  }

  const anchor = '// relax:router-routes';
  const routerSource = '''
final appRouter = GoRouter(
  routes: [
    // relax:router-routes
  ],
);
''';

  group('insertBeforeAnchor', () {
    test('inserts the snippet before the anchor line', () {
      final file = writeFile(routerSource);

      final result = SourcePatcher.insertBeforeAnchor(
        file,
        anchor: anchor,
        snippet: '    GoRoute(path: CartPage.routePath),',
        guard: 'CartPage.routePath',
      );

      expect(result.status, PatchStatus.inserted);
      expect(result.changed, isTrue);

      final content = file.readAsStringSync();
      expect(content, contains('GoRoute(path: CartPage.routePath),'));
      // The snippet must appear before the anchor, and the anchor is preserved.
      expect(
        content.indexOf('CartPage.routePath'),
        lessThan(content.indexOf(anchor)),
      );
      expect(content, contains(anchor));
    });

    test('is idempotent: a second identical call is skipped', () {
      final file = writeFile(routerSource);
      const snippet = '    GoRoute(path: CartPage.routePath),';

      SourcePatcher.insertBeforeAnchor(
        file,
        anchor: anchor,
        snippet: snippet,
        guard: 'CartPage.routePath',
      );
      final second = SourcePatcher.insertBeforeAnchor(
        file,
        anchor: anchor,
        snippet: snippet,
        guard: 'CartPage.routePath',
      );

      expect(second.status, PatchStatus.skipped);
      expect(second.changed, isFalse);
      // Guard prevents duplication.
      final matches = 'CartPage.routePath'.allMatches(file.readAsStringSync());
      expect(matches.length, 1);
    });

    test('reports anchorMissing and leaves the file untouched', () {
      final file = writeFile('final appRouter = GoRouter(routes: []);\n');
      final before = file.readAsStringSync();

      final result = SourcePatcher.insertBeforeAnchor(
        file,
        anchor: anchor,
        snippet: '    GoRoute(),',
        guard: 'GoRoute()',
      );

      expect(result.status, PatchStatus.anchorMissing);
      expect(file.readAsStringSync(), before);
    });

    test('reports fileMissing when the file does not exist', () {
      final result = SourcePatcher.insertBeforeAnchor(
        File('${tempDir.path}/does_not_exist.dart'),
        anchor: anchor,
        snippet: 'x',
        guard: 'x',
      );

      expect(result.status, PatchStatus.fileMissing);
    });

    test('supports two anchors in the same file independently', () {
      final file = writeFile('''
import '../../features/home/home.dart';
// relax:router-imports

final appRouter = GoRouter(
  routes: [
    // relax:router-routes
  ],
);
''');

      SourcePatcher.insertBeforeAnchor(
        file,
        anchor: '// relax:router-imports',
        snippet: "import '../../features/cart/cart.dart';",
        guard: 'features/cart/cart.dart',
      );
      SourcePatcher.insertBeforeAnchor(
        file,
        anchor: '// relax:router-routes',
        snippet: '    GoRoute(name: CartPage.routeName),',
        guard: 'CartPage.routeName',
      );

      final content = file.readAsStringSync();
      expect(content, contains("import '../../features/cart/cart.dart';"));
      expect(content, contains('GoRoute(name: CartPage.routeName),'));
      // Import lands above the router block.
      expect(
        content.indexOf('features/cart/cart.dart'),
        lessThan(content.indexOf('CartPage.routeName')),
      );
    });
  });

  group('insertAfterAnchor', () {
    test('inserts on the line after the anchor', () {
      final file = writeFile('class HomePage {\n  const HomePage();\n}\n');
      final result = SourcePatcher.insertAfterAnchor(
        file,
        anchor: 'const HomePage();',
        snippet: "  static const routePath = '/';",
        guard: 'routePath',
      );

      expect(result.status, PatchStatus.inserted);
      final lines = file.readAsStringSync().split('\n');
      expect(lines[1], contains('const HomePage();'));
      expect(lines[2], contains("static const routePath = '/';"));
    });

    test('is idempotent via guard', () {
      final file = writeFile('class HomePage {\n  const HomePage();\n}\n');
      SourcePatcher.insertAfterAnchor(
        file,
        anchor: 'const HomePage();',
        snippet: "  static const routePath = '/';",
        guard: 'routePath',
      );
      final second = SourcePatcher.insertAfterAnchor(
        file,
        anchor: 'const HomePage();',
        snippet: "  static const routePath = '/';",
        guard: 'routePath',
      );
      expect(second.status, PatchStatus.skipped);
    });
  });

  group('replaceOnce', () {
    test('replaces the first occurrence when guard absent', () {
      final file = writeFile('MaterialApp(home: HomePage());\n');
      final result = SourcePatcher.replaceOnce(
        file,
        from: 'MaterialApp(',
        to: 'MaterialApp.router(',
        guard: 'MaterialApp.router(',
      );
      expect(result.status, PatchStatus.inserted);
      expect(file.readAsStringSync(), contains('MaterialApp.router('));
    });

    test('skips when guard already present', () {
      final file = writeFile('MaterialApp.router(routerConfig: r);\n');
      final result = SourcePatcher.replaceOnce(
        file,
        from: 'MaterialApp(',
        to: 'MaterialApp.router(',
        guard: 'MaterialApp.router(',
      );
      expect(result.status, PatchStatus.skipped);
    });

    test('reports anchorMissing when the pattern is absent', () {
      final file = writeFile('CupertinoApp();\n');
      final result = SourcePatcher.replaceOnce(
        file,
        from: 'MaterialApp(',
        to: 'MaterialApp.router(',
        guard: 'MaterialApp.router(',
      );
      expect(result.status, PatchStatus.anchorMissing);
    });
  });

  group('ensureLine', () {
    test('appends the line when guard absent', () {
      final file = writeFile("export 'a.dart';\n");
      final result = SourcePatcher.ensureLine(
        file,
        line: "export 'b.dart';",
        guard: 'b.dart',
      );
      expect(result.status, PatchStatus.inserted);
      expect(file.readAsStringSync(), contains("export 'b.dart';"));
    });

    test('is idempotent', () {
      final file = writeFile("export 'a.dart';\n");
      SourcePatcher.ensureLine(file, line: "export 'b.dart';", guard: 'b.dart');
      final second = SourcePatcher.ensureLine(
        file,
        line: "export 'b.dart';",
        guard: 'b.dart',
      );
      expect(second.status, PatchStatus.skipped);
      expect("export 'b.dart';".allMatches(file.readAsStringSync()).length, 1);
    });
  });
}
