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
    tempDir = Directory.systemTemp.createTempSync('relax_mod_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<void> createProject(String name) async {
    final originalDir = Directory.current;
    Directory.current = tempDir;
    try {
      await runner.run(['create', name, '-a', 'bloc']);
    } finally {
      Directory.current = originalDir;
    }
  }

  group('ModuleCommand', () {
    test('exits with usage when no module name is given', () async {
      await createProject('app');
      final originalDir = Directory.current;
      Directory.current = Directory('${tempDir.path}/app');

      try {
        final code = await runner.run(['generate', 'module']);
        expect(code, equals(ExitCode.usage.code));
      } finally {
        Directory.current = originalDir;
      }
    });

    test('exits with usage for invalid module name', () async {
      await createProject('app');
      final originalDir = Directory.current;
      Directory.current = Directory('${tempDir.path}/app');

      try {
        final code = await runner.run(['generate', 'module', 'Bad-Name']);
        expect(code, equals(ExitCode.usage.code));
      } finally {
        Directory.current = originalDir;
      }
    });

    test('exits with usage when not in a Flutter project', () async {
      final emptyDir = Directory('${tempDir.path}/empty')..createSync();
      final originalDir = Directory.current;
      Directory.current = emptyDir;

      try {
        final code = await runner.run(['generate', 'module', 'foo']);
        expect(code, equals(ExitCode.usage.code));
      } finally {
        Directory.current = originalDir;
      }
    });

    test('generates module with 5 files in default location', () async {
      await createProject('app');
      final originalDir = Directory.current;
      Directory.current = Directory('${tempDir.path}/app');

      try {
        final code = await runner.run(['generate', 'module', 'product']);
        expect(code, equals(ExitCode.success.code));

        final base = '${tempDir.path}/app/lib/modules/product';
        expect(File('$base/product.dart').existsSync(), isTrue);
        expect(File('$base/models/product.dart').existsSync(), isTrue);
        expect(
          File('$base/repositories/product_repository.dart').existsSync(),
          isTrue,
        );
        expect(
          File('$base/repositories/product_repository_impl.dart').existsSync(),
          isTrue,
        );
        expect(
          File('$base/data_sources/product_data_source.dart').existsSync(),
          isTrue,
        );
      } finally {
        Directory.current = originalDir;
      }
    });

    test('generates module in custom output directory', () async {
      await createProject('app');
      final originalDir = Directory.current;
      Directory.current = Directory('${tempDir.path}/app');

      try {
        final code = await runner.run([
          'generate',
          'module',
          'user',
          '-o',
          'core/domain',
        ]);
        expect(code, equals(ExitCode.success.code));

        final base = '${tempDir.path}/app/lib/core/domain/user';
        expect(Directory(base).existsSync(), isTrue);
        expect(File('$base/models/user.dart').existsSync(), isTrue);
      } finally {
        Directory.current = originalDir;
      }
    });

    test('generated model has correct class name and RelaxORM annotations',
        () async {
      await createProject('app');
      final originalDir = Directory.current;
      Directory.current = Directory('${tempDir.path}/app');

      try {
        await runner.run(['generate', 'module', 'shopping_cart']);

        final model = File(
          '${tempDir.path}/app/lib/modules/shopping_cart/models/shopping_cart.dart',
        ).readAsStringSync();
        expect(model, contains('class ShoppingCart'));
        expect(model, contains('@RelaxTable()'));
        expect(model, contains('@PrimaryKey()'));
        expect(model, contains("part 'shopping_cart.g.dart'"));
      } finally {
        Directory.current = originalDir;
      }
    });

    test('generated repository uses abstract interface class', () async {
      await createProject('app');
      final originalDir = Directory.current;
      Directory.current = Directory('${tempDir.path}/app');

      try {
        await runner.run(['generate', 'module', 'order']);

        final repo = File(
          '${tempDir.path}/app/lib/modules/order/repositories/order_repository.dart',
        ).readAsStringSync();
        expect(repo, contains('abstract interface class OrderRepository'));
      } finally {
        Directory.current = originalDir;
      }
    });

    test('exits with usage when module already exists', () async {
      await createProject('app');
      final originalDir = Directory.current;
      Directory.current = Directory('${tempDir.path}/app');

      try {
        await runner.run(['generate', 'module', 'item']);
        final code = await runner.run(['generate', 'module', 'item']);
        expect(code, equals(ExitCode.usage.code));
      } finally {
        Directory.current = originalDir;
      }
    });
  });
}
