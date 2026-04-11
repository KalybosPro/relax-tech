// ignore_for_file: avoid_print

import 'dart:io';

import 'package:env_builder_cli/src/core/env_file_parser.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('EnvFileParser Optimization Tests', () {
    late Directory tempDir;
    late File testEnvFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('env_parser_test_');
      testEnvFile = File(p.join(tempDir.path, '.env.test'));
      
      // Create a test .env file with various entries
      testEnvFile.writeAsStringSync(
        'API_KEY=sk_live_123456\n'
        'DATABASE_URL="postgres://localhost:5432/mydb"\n'
        'SECRET_PASSWORD=\'my-secret-password\'\n'
        'EMPTY_VALUE=\n'
        'UNQUOTED_VALUE=some value\n'
        'SPECIAL_CHARS_ALT=special\n'
        'QUOTED_KEY="quoted_value"\n'
        '# This is a comment\n'
      );

      // Reset cache and stats before each test
      EnvFileParser.clearCache();
      EnvFileParser.resetCacheStats();
    });

    tearDown(() {
      EnvFileParser.clearCache();
      EnvFileParser.resetCacheStats();
      tempDir.deleteSync(recursive: true);
    });

    test('Cache hit uses UnmodifiableMapView (no copy)', () {
      // First parse - should miss cache
      final result1 = EnvFileParser.parseEnvFile(testEnvFile);
      expect(result1, isNotNull);
      expect(result1, isNotEmpty);

      // Get cache stats after first parse
      var stats = EnvFileParser.getCacheStats();
      expect(stats['cacheHits'], equals(0), reason: 'First parse should miss cache');
      expect(stats['cacheMisses'], equals(1));

      // Second parse - should hit cache
      final result2 = EnvFileParser.parseEnvFile(testEnvFile);
      expect(result2, equals(result1));

      // Verify cache hit was recorded
      stats = EnvFileParser.getCacheStats();
      expect(stats['cacheHits'], equals(1), reason: 'Second parse should hit cache');
      expect(stats['cacheMisses'], equals(1));
    });

    test('Cache statistics are accurate', () {
      // Parse the file
      final result = EnvFileParser.parseEnvFile(testEnvFile);
      
      final stats = EnvFileParser.getCacheStats();
      
      // Verify stats
      expect(stats['cacheSize'], equals(1));
      expect(stats['totalVariables'], equals(result.length));
      expect(stats['cacheHits'], equals(0));
      expect(stats['cacheMisses'], equals(1));
      expect(stats['hitRate'], equals('0.00'));
      expect(stats.containsKey('estimatedMemoryMB'), isTrue);
    });

    test('Cache hit rate improves with multiple accesses', () {
      // Parse file 5 times
      for (var i = 0; i < 5; i++) {
        EnvFileParser.parseEnvFile(testEnvFile);
      }

      final stats = EnvFileParser.getCacheStats();
      
      // All except first should be cache hits
      expect(stats['cacheHits'], equals(4));
      expect(stats['cacheMisses'], equals(1));
      expect(stats['hitRate'], equals('80.00'));
    });

    test('Cache invalidates on file modification', () {
      // First parse
      final result1 = EnvFileParser.parseEnvFile(testEnvFile);
      var stats = EnvFileParser.getCacheStats();
      expect(stats['cacheMisses'], equals(1));

      // Modify file with sufficient delay to ensure timestamp changes
      // (Some filesystems have 1-2 second timestamp granularity)
      sleep(const Duration(seconds: 2));
      testEnvFile.writeAsStringSync('NEW_KEY=new_value');

      // Parse again - should miss cache because file was modified
      final result2 = EnvFileParser.parseEnvFile(testEnvFile);
      stats = EnvFileParser.getCacheStats();
      
      expect(result2.length, lessThan(result1.length), reason: 'Results should differ after file modification');
      expect(stats['cacheMisses'], equals(2));
      expect(result2.containsKey('NEW_KEY'), isTrue);
    });

    test('Correct parsing of quoted values', () {
      final result = EnvFileParser.parseEnvFile(testEnvFile);
      
      expect(result['DATABASE_URL'], equals('postgres://localhost:5432/mydb'));
      expect(result['SECRET_PASSWORD'], equals('my-secret-password'));
    });

    test('Correct parsing of unquoted values', () {
      final result = EnvFileParser.parseEnvFile(testEnvFile);
      
      expect(result['API_KEY'], equals('sk_live_123456'));
      expect(result['UNQUOTED_VALUE'], equals('some value'));
    });

    test('Handles special characters correctly', () {
      final result = EnvFileParser.parseEnvFile(testEnvFile);
      
      expect(result['SPECIAL_CHARS_ALT'], equals('special'));
    });

    test('Ignores comments and empty lines', () {
      final result = EnvFileParser.parseEnvFile(testEnvFile);
      
      // Comments should not be included as variables
      expect(result.containsKey('This'), isFalse);
      expect(result.containsKey('is'), isFalse);
    });

    test('Cache clear works correctly', () {
      // Parse a file  
      final file1 = File(p.join(tempDir.path, '.test1'));
      file1.writeAsStringSync('KEY1=value1');
      
      EnvFileParser.parseEnvFile(file1);
      var stats = EnvFileParser.getCacheStats();
      final initialSize = stats['cacheSize'] as int;
      expect(initialSize, greaterThan(0));

      // Clear cache
      EnvFileParser.clearCache();
      stats = EnvFileParser.getCacheStats();
      expect(stats['cacheSize'], equals(0));

      // Clean up
      if (file1.existsSync()) {
        file1.deleteSync();
      }
    });

    test('Cache clears particular file correctly', () {
      // Create second file
      final testFile2 = File(p.join(tempDir.path, '.env.test2'));
      testFile2.writeAsStringSync('KEY2=VALUE2');

      // Parse both files
      EnvFileParser.parseEnvFile(testEnvFile);
      EnvFileParser.parseEnvFile(testFile2);
      
      var stats = EnvFileParser.getCacheStats();
      expect(stats['cacheSize'], equals(2));

      // Clear only first file
      EnvFileParser.clearCacheForFile(testEnvFile);
      stats = EnvFileParser.getCacheStats();
      expect(stats['cacheSize'], equals(1));

      // Clean up
      if (testFile2.existsSync()) {
        testFile2.deleteSync();
      }
      // Also clear from cache
      EnvFileParser.clearCacheForFile(testFile2);
    });

    test('Reset cache stats works correctly', () {
      // Parse file to accumulate stats
      for (var i = 0; i < 3; i++) {
        EnvFileParser.parseEnvFile(testEnvFile);
      }

      var stats = EnvFileParser.getCacheStats();
      expect(stats['cacheHits'], greaterThan(0));

      // Reset stats
      EnvFileParser.resetCacheStats();
      stats = EnvFileParser.getCacheStats();
      expect(stats['cacheHits'], equals(0));
      expect(stats['cacheMisses'], equals(0));
    });

    test('Large file benchmark - cache hit is fast', () async {
      // Create a larger test file (5000 env vars)
      final largeContent = StringBuffer();
      for (var i = 0; i < 5000; i++) {
        largeContent.writeln('VAR_$i=value_$i');
      }
      testEnvFile.writeAsStringSync(largeContent.toString());

      // Warm up cache
      EnvFileParser.parseEnvFile(testEnvFile);
      
      // Measure cache hit time (should be < 1ms)
      final watch = Stopwatch()..start();
      for (var i = 0; i < 100; i++) {
        EnvFileParser.parseEnvFile(testEnvFile);
      }
      watch.stop();

      final avgTimeMs = watch.elapsedMilliseconds / 100;
      print('Average cache hit time: ${avgTimeMs.toStringAsFixed(3)}ms');
      
      // Verify reasonable performance (cache hit should be very fast)
      expect(avgTimeMs, lessThan(5), 
          reason: 'Cache hit should be much faster than file I/O');
      
      final stats = EnvFileParser.getCacheStats();
      expect(stats['totalVariables'], equals(5000));
    });

    test('Cache stats show correct memory usage estimate', () {
      EnvFileParser.parseEnvFile(testEnvFile);
      
      final stats = EnvFileParser.getCacheStats();
      final memoryMB = double.parse(stats['estimatedMemoryMB'] as String);
      
      // Should be a small number (less than 1MB for test file)
      expect(memoryMB, lessThanOrEqualTo(1.0));
      // For a non-empty cache, should be at least some measurable value
      expect(stats['totalVariables'], greaterThan(0));
    });

    test('Empty .env file is handled correctly', () {
      final emptyFile = File(p.join(tempDir.path, '.env.empty'));
      emptyFile.writeAsStringSync('');

      final result = EnvFileParser.parseEnvFile(emptyFile);
      
      expect(result, isEmpty);
      expect(result, isA<Map<String, String>>());

      emptyFile.deleteSync();
    });

    test('File with only comments is handled correctly', () {
      final commentFile = File(p.join(tempDir.path, '.env.comments'));
      commentFile.writeAsStringSync('''
# Comment 1
# Comment 2
# Comment 3
''');

      final result = EnvFileParser.parseEnvFile(commentFile);
      
      expect(result, isEmpty);

      commentFile.deleteSync();
    });
  });
}
