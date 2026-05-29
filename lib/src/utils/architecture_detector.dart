import 'dart:io';

import '../models/architecture.dart';

/// Detects the architecture used by an existing Flutter project
/// by inspecting its pubspec.yaml dependencies.
class ArchitectureDetector {
  /// Detects the [Architecture] from the pubspec.yaml in [projectDir].
  ///
  /// Returns `null` if no known architecture is detected.
  /// Throws [FileSystemException] if pubspec.yaml is not found.
  static Architecture? detect([Directory? projectDir]) {
    final dir = projectDir ?? Directory.current;
    final pubspecFile = File('${dir.path}/pubspec.yaml');

    if (!pubspecFile.existsSync()) {
      throw FileSystemException(
        'pubspec.yaml not found. '
        'Run this command from the root of a Flutter project.',
        pubspecFile.path,
      );
    }

    final content = pubspecFile.readAsStringSync();

    // Order matters: check flutter_riverpod before provider,
    // since riverpod projects might also reference provider.
    if (content.contains('flutter_bloc:')) return Architecture.bloc;
    if (content.contains('flutter_riverpod:')) return Architecture.riverpod;
    if (content.contains('provider:')) return Architecture.provider;
    // Match `get:` only as a standalone package entry (e.g. `  get: ^4.6.0`),
    // not `get_storage:` or other packages that start with "get".
    if (content.contains(RegExp(r'^\s+get:\s', multiLine: true))) {
      return Architecture.getx;
    }

    return null;
  }
}
