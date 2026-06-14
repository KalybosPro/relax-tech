// ignore_for_file: avoid_print

import 'dart:io';

import 'package:env_builder_cli/src/core/env_file_parser.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('env_cache_test_');
    // Clear cache before each test
    EnvFileParser.clearCache();
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
    // Clear cache after each test
    EnvFileParser.clearCache();
  });

  group('EnvFileParser Caching', () {
    test('should cache parsed file on first read', () async {
      // Arrange
      const envContent = 'API_KEY=test123\nDB_HOST=localhost';
      final envFile = File(p.join(tempDir.path, '.env'));
      await envFile.writeAsString(envContent);

      // Act
      final firstRead = EnvFileParser.parseEnvFile(envFile);
      final secondRead = EnvFileParser.parseEnvFile(envFile);

      // Assert
      expect(firstRead['API_KEY'], equals('test123'));
      expect(secondRead['API_KEY'], equals('test123'));
      expect(firstRead, equals(secondRead),
          reason: 'Results should be identical');
    });

    test('should return different instance from cache (not reference)', () async {
      // Arrange
      const envContent = 'KEY=value';
      final envFile = File(p.join(tempDir.path, '.env'));
      await envFile.writeAsString(envContent);

      // Act
      final firstRead = EnvFileParser.parseEnvFile(envFile);
      final secondRead = EnvFileParser.parseEnvFile(envFile);

      // Assert - should be equal but not the same instance
      expect(firstRead, equals(secondRead),
          reason: 'Content should be equal');
      expect(identical(firstRead, secondRead), false,
          reason: 'Should return different Map instances');
    });

    test('should invalidate cache when file is modified', () async {
      // Arrange
      final envFile = File(p.join(tempDir.path, '.env'));
      await envFile.writeAsString('KEY=original');

      // Act - first read
      final firstRead = EnvFileParser.parseEnvFile(envFile);
      expect(firstRead['KEY'], equals('original'));

      // Modify file with sufficient delay to ensure different timestamp
      // (File system timestamp resolution can be ~1000ms on some systems)
      await Future.delayed(const Duration(milliseconds: 1100));
      await envFile.writeAsString('KEY=modified');

      // Second read should get new value
      final secondRead = EnvFileParser.parseEnvFile(envFile);

      // Assert
      expect(secondRead['KEY'], equals('modified'),
          reason: 'Cache should be invalidated after file modification');
    });

    test('should handle multiple different files independently', () async {
      // Arrange
      final envFile1 = File(p.join(tempDir.path, '.env.dev'));
      final envFile2 = File(p.join(tempDir.path, '.env.prod'));

      await envFile1.writeAsString('ENV=development');
      await envFile2.writeAsString('ENV=production');

      // Act
      final dev = EnvFileParser.parseEnvFile(envFile1);
      final prod = EnvFileParser.parseEnvFile(envFile2);

      // Assert
      expect(dev['ENV'], equals('development'));
      expect(prod['ENV'], equals('production'));
    });

    test('should improve performance with cached files', () async {
      // Arrange
      final largeContent = StringBuffer();
      for (var i = 0; i < 1000; i++) {
        largeContent.writeln('KEY_$i=value$i');
      }
      final envFile = File(p.join(tempDir.path, '.env.large'));
      await envFile.writeAsString(largeContent.toString());

      // Act - measure first read (uncached)
      final stopwatch1 = Stopwatch()..start();
      final firstRead = EnvFileParser.parseEnvFile(envFile);
      stopwatch1.stop();
      final firstReadTime = stopwatch1.elapsedMilliseconds;

      // Measure second read (cached)
      final stopwatch2 = Stopwatch()..start();
      final secondRead = EnvFileParser.parseEnvFile(envFile);
      stopwatch2.stop();
      final secondReadTime = stopwatch2.elapsedMilliseconds;

      // Assert
      expect(firstRead, equals(secondRead),
          reason: 'Content should be identical');
      expect(secondReadTime, lessThanOrEqualTo(firstReadTime),
          reason: 'Cached read should be faster or equal');
      print(
          'First read: ${firstReadTime}ms, Cached read: ${secondReadTime}ms');
    });

    test('clearCache should remove all cached entries', () async {
      // Arrange
      final envFile = File(p.join(tempDir.path, '.env'));
      await envFile.writeAsString('KEY=value1');

      // Act - parse and cache
      final firstRead = EnvFileParser.parseEnvFile(envFile);
      expect(firstRead['KEY'], equals('value1'));

      // Modify file
      await Future.delayed(const Duration(milliseconds: 100));
      await envFile.writeAsString('KEY=value2');

      // Clear cache
      EnvFileParser.clearCache();

      // Read again - should get new value
      final secondRead = EnvFileParser.parseEnvFile(envFile);

      // Assert
      expect(secondRead['KEY'], equals('value2'),
          reason: 'After cache clear, should read modified file');
    });

    test('clearCacheForFile should remove specific file cache', () async {
      // Arrange
      final envFile1 = File(p.join(tempDir.path, '.env.1'));
      final envFile2 = File(p.join(tempDir.path, '.env.2'));

      await envFile1.writeAsString('FILE=1');
      await envFile2.writeAsString('FILE=2');

      // Act - parse both
      EnvFileParser.parseEnvFile(envFile1);
      EnvFileParser.parseEnvFile(envFile2);

      // Modify file 1 and clear its cache
      await Future.delayed(const Duration(milliseconds: 1100));
      await envFile1.writeAsString('FILE=1_modified');
      EnvFileParser.clearCacheForFile(envFile1);

      // Read file 1 - should get modified value
      final read1 = EnvFileParser.parseEnvFile(envFile1);

      // Read file 2 again - should still return cached value (not modified)
      final read2 = EnvFileParser.parseEnvFile(envFile2);

      // Assert
      expect(read1['FILE'], equals('1_modified'),
          reason: 'Cleared cache should cause file re-read');
      expect(read2['FILE'], equals('2'),
          reason: 'Non-cleared cache should return cached value');
    });

    test('should handle file with same path after rewrite', () async {
      // Arrange
      final envFile = File(p.join(tempDir.path, '.env'));
      await envFile.writeAsString('KEY=first');

      // Act - first parse
      final first = EnvFileParser.parseEnvFile(envFile);

      // Delete and recreate file with sufficient delay
      await envFile.delete();
      await Future.delayed(const Duration(milliseconds: 1100));
      await envFile.writeAsString('KEY=second');

      // Second parse
      final second = EnvFileParser.parseEnvFile(envFile);

      // Assert
      expect(first['KEY'], equals('first'));
      expect(second['KEY'], equals('second'),
          reason: 'Should detect file recreation and reparse');
    });

    test('should cache files with similar names independently', () async {
      // Arrange
      final envFile = File(p.join(tempDir.path, '.env'));
      final envFileDev = File(p.join(tempDir.path, '.env.dev'));

      await envFile.writeAsString('TYPE=base');
      await envFileDev.writeAsString('TYPE=dev');

      // Act
      final baseResult = EnvFileParser.parseEnvFile(envFile);
      final devResult = EnvFileParser.parseEnvFile(envFileDev);

      // Assert
      expect(baseResult['TYPE'], equals('base'));
      expect(devResult['TYPE'], equals('dev'),
          reason: 'Different files should not share cache');
    });

    test('should handle concurrent access safely', () async {
      // Arrange
      final envFile = File(p.join(tempDir.path, '.env'));
      await envFile.writeAsString('KEY=value');

      // Act - simulate concurrent reads
      final results = await Future.wait([
        Future.microtask(() => EnvFileParser.parseEnvFile(envFile)),
        Future.microtask(() => EnvFileParser.parseEnvFile(envFile)),
        Future.microtask(() => EnvFileParser.parseEnvFile(envFile)),
      ]);

      // Assert
      expect(results[0]['KEY'], equals('value'));
      expect(results[1]['KEY'], equals('value'));
      expect(results[2]['KEY'], equals('value'));
    });
  });
}
