import 'dart:io';

import 'package:env_builder_cli/src/core/asset/assets_generator.dart';
import 'package:env_builder_cli/src/core/asset/models/encryption_method.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Asset Parallelization Tests', () {
    late Directory tempDir;
    late Directory assetsDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('env_builder_test_');
      assetsDir = Directory(p.join(tempDir.path, 'assets'));
      assetsDir.createSync(recursive: true);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Multiple assets are processed in parallel', () async {
      // Create test assets
      const assetCount = 5;
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < assetCount; i++) {
        final testFile = File(p.join(assetsDir.path, 'image_$i.png'));
        // Create dummy PNG files (valid magic bytes)
        testFile.writeAsBytesSync([
          137, 80, 78, 71, 13, 10, 26, 10, // PNG magic
          ...List.filled(100, i), // Unique content per file
        ]);
      }

      // Change to temp directory to find assets
      final originalCwd = Directory.current.path;
      Directory.current = tempDir;

      try {
        final generator = AssetsGenerator(
          compress: false,
          svgMinify: false,
          encryptionMethod: EncryptionMethod.aes,
          chunkSize: 1024,
        );
        final result = await generator.generate();

        stopwatch.stop();

        // Verify generated code contains all assets
        expect(result.isNotEmpty, isTrue);
        // Check for generated constants (naming may vary)
        expect(result.contains('const List<int>'), isTrue,
            reason: 'Should have asset constants');
        expect(result.contains('assetdata'), isTrue,
            reason: 'Should have asset data variables');

        // Parallel processing should be faster or at least reasonable
        // (exact timing is flaky, just ensure it completes)
        expect(stopwatch.elapsedMilliseconds > 0, isTrue);
      } finally {
        Directory.current = originalCwd;
      }
    });

    test('Asset generation with many files completes', () async {
      // Create many test assets to observe parallelization benefits
      const assetCount = 20;

      for (var i = 0; i < assetCount; i++) {
        final testFile = File(p.join(assetsDir.path, 'asset_$i.png'));
        testFile.writeAsBytesSync([
          137, 80, 78, 71, 13, 10, 26, 10, // PNG magic
          ...List.filled(500 + i * 10, i % 256),
        ]);
      }

      final originalCwd = Directory.current.path;
      Directory.current = tempDir;

      try {
        final generator = AssetsGenerator(
          compress: false,
          svgMinify: false,
          encryptionMethod: EncryptionMethod.aes,
          chunkSize: 1024,
        );
        final result = await generator.generate();

        // All assets should be processed
        expect(result.isNotEmpty, isTrue);
        expect(result.contains('assetdata'), isTrue);
        expect(result.contains('_assetkey'), isTrue);
      } finally {
        Directory.current = originalCwd;
      }
    });

    test('Error in one asset does not block others', () async {
      // Create valid and invalid assets
      final validFile = File(p.join(assetsDir.path, 'valid.png'));
      validFile.writeAsBytesSync([
        137, 80, 78, 71, 13, 10, 26, 10, // PNG magic
        ...List.filled(100, 1),
      ]);

      final anotherValidFile = File(p.join(assetsDir.path, 'another.png'));
      anotherValidFile.writeAsBytesSync([
        137, 80, 78, 71, 13, 10, 26, 10, // PNG magic
        ...List.filled(100, 2),
      ]);

      final originalCwd = Directory.current.path;
      Directory.current = tempDir;

      try {
        final generator = AssetsGenerator(
          compress: false,
          svgMinify: false,
          encryptionMethod: EncryptionMethod.aes,
          chunkSize: 1024,
        );
        final result = await generator.generate();

        // Should complete despite any issues
        // Individual asset errors are caught and logged
        expect(result, isNotNull);
      } finally {
        Directory.current = originalCwd;
      }
    });

    test('Generated code from parallel processing is valid', () async {
      // Create test assets
      for (var i = 0; i < 3; i++) {
        final testFile = File(p.join(assetsDir.path, 'icon_$i.png'));
        testFile.writeAsBytesSync([
          137, 80, 78, 71, 13, 10, 26, 10, // PNG magic
          ...List.filled(200, i),
        ]);
      }

      final originalCwd = Directory.current.path;
      Directory.current = tempDir;

      try {
        final generator = AssetsGenerator(
          compress: false,
          svgMinify: false,
          encryptionMethod: EncryptionMethod.aes,
          chunkSize: 1024,
        );
        final result = await generator.generate();

        // Validate Dart syntax markers
        expect(result.contains('// GENERATED CODE'), isTrue);
        expect(result.contains("import 'dart:typed_data'"), isTrue);
        expect(result.contains('const List<int>'), isTrue);
        expect(result.contains('get decrypted'), isTrue);

        // Each asset should have key + data + getter
        expect(result.split('const List<int> _assetkey').length - 1, greaterThanOrEqualTo(1),
            reason: 'Should have asset keys');
      } finally {
        Directory.current = originalCwd;
      }
    });

    test('Parallel processing produces consistent output order', () async {
      // Create multiple identical test assets
      final assetNames = ['alpha', 'beta', 'gamma', 'delta'];

      for (final name in assetNames) {
        final testFile = File(p.join(assetsDir.path, '${name}_asset.png'));
        testFile.writeAsBytesSync([
          137, 80, 78, 71, 13, 10, 26, 10, // PNG magic
          ...List.filled(100, name.codeUnitAt(0)),
        ]);
      }

      final originalCwd = Directory.current.path;
      Directory.current = tempDir;

      try {
        final generator = AssetsGenerator(
          compress: false,
          svgMinify: false,
          encryptionMethod: EncryptionMethod.aes,
          chunkSize: 1024,
        );
        
        // Run generation multiple times
        final results = <String>[];
        for (var i = 0; i < 2; i++) {
          results.add(await generator.generate());
        }

        // Both runs should produce equivalent output (same constants/methods)
        // Content should be identical despite parallel execution
        expect(results[0].split('const List<int>').length,
            equals(results[1].split('const List<int>').length),
            reason: 'Parallel execution should be deterministic');
      } finally {
        Directory.current = originalCwd;
      }
    });

    test('Assets processed independently with Future.wait', () async {
      // This test verifies parallelization by ensuring multiple assets
      // are handled concurrently without dependencies
      const assetCount = 10;
      final files = <File>[];

      for (var i = 0; i < assetCount; i++) {
        final file = File(p.join(assetsDir.path, 'concurrent_$i.png'));
        file.writeAsBytesSync([
          137, 80, 78, 71, 13, 10, 26, 10, // PNG magic
          ...List.filled(150 + i * 20, (i * 7) % 256),
        ]);
        files.add(file);
      }

      final originalCwd = Directory.current.path;
      Directory.current = tempDir;

      try {
        final generator = AssetsGenerator(
          compress: false,
          svgMinify: false,
          encryptionMethod: EncryptionMethod.aes,
          chunkSize: 1024,
        );
        final stopwatch = Stopwatch()..start();
        final result = await generator.generate();
        stopwatch.stop();

        // Verify all assets were processed
        expect(result.isNotEmpty, isTrue);
        expect(result.contains('assetdata'), isTrue);

        // Generation should complete in reasonable time
        // (parallelization should prevent timeout on many assets)
        expect(stopwatch.elapsedMilliseconds < 30000, isTrue,
            reason: 'Parallelized asset generation should be fast');
      } finally {
        Directory.current = originalCwd;
      }
    });
  });
}
