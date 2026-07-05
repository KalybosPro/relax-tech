import 'dart:io';

import 'package:path/path.dart' as p;

import '../config/quality_config.dart';

/// Recursively scans a project directory for analyzable Dart files.
///
/// Honors the ignore globs from [QualityConfig] and an optional `.relaxignore`
/// file (one pattern per line) at the project root. Both `lib/` and `test/`
/// are scanned — `test/` is needed to detect missing-test gaps.
class ProjectScanner {
  ProjectScanner({
    required this.projectRoot,
    required this.config,
    this.scopePath,
  });

  /// Absolute or relative path to the project root (contains `pubspec.yaml`).
  final String projectRoot;
  final QualityConfig config;

  /// Optional sub-path (relative to root) to restrict analysis, e.g.
  /// `lib/features/orders`.
  final String? scopePath;

  /// Returns the list of Dart source files under `lib/` for analysis.
  List<String> scanSource() => _scanDir(scopePath ?? 'lib');

  /// Returns the list of Dart test files under `test/`.
  List<String> scanTests() => _scanDir('test');

  List<String> _scanDir(String relative) {
    final root = Directory(p.join(projectRoot, relative));
    if (!root.existsSync()) return const [];

    final extraIgnores = _readRelaxIgnore();
    final results = <String>[];
    for (final entity in root.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final path = entity.path;
      if (!path.endsWith('.dart')) continue;
      final rel = p.relative(path, from: projectRoot).replaceAll(r'\', '/');
      if (_isIgnored(rel, extraIgnores)) continue;
      results.add(path);
    }
    results.sort();
    return results;
  }

  bool _isIgnored(String relPath, List<String> extra) {
    for (final glob in [...config.ignoreGlobs, ...extra]) {
      if (glob.isEmpty) continue;
      // Substring match keeps this simple and predictable: matches directory
      // segments (`build`), suffixes (`.g.dart`), and folders (`generated`).
      if (relPath.contains(glob)) return true;
    }
    return false;
  }

  List<String> _readRelaxIgnore() {
    final file = File(p.join(projectRoot, '.relaxignore'));
    if (!file.existsSync()) return const [];
    return file
        .readAsLinesSync()
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('#'))
        .toList();
  }
}
