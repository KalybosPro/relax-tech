// ignore_for_file: avoid_print

import 'core.dart';

/// Internal class to store cached parse results with file metadata
class _CachedParse {
  final DateTime lastModified;
  final Map<String, String> data;

  _CachedParse({required this.lastModified, required this.data});
}

/// Handles .env file parsing operations with optimized performance
///
/// Parses environment files according to standard .env file format:
/// - Ignores comment lines starting with #
/// - Trims whitespace from keys and values
/// - Removes surrounding quotes from values
/// - Handles key-value pairs separated by =
/// - Optimized parsing with minimal allocations
/// - Includes intelligent caching to avoid re-parsing unchanged files
class EnvFileParser {
  static const int doubleQuote = 0x22;
  static const int singleQuote = 0x27;
  static const int hash = 0x23;

  // Cache for parsed files: key = absolute path, value = (lastModified, parsedMap)
  static final Map<String, _CachedParse> _cache = <String, _CachedParse>{};

  /// Parses an .env file and returns key-value pairs with optimized performance
  /// Results are cached to avoid re-parsing unchanged files
  static Map<String, String> parseEnvFile(File file) {
    final absolutePath = file.absolute.path;

    // Check cache first
    if (_cache.containsKey(absolutePath)) {
      final cached = _cache[absolutePath]!;
      final currentModified = file.lastModifiedSync();

      // If file hasn't been modified since caching, return cached result
      if (cached.lastModified == currentModified) {
        return Map<String, String>.from(cached.data);
      }
    }

    // Cache miss or file modified - parse the file
    final parsedData = _parseEnvFileImpl(file);
    final lastModified = file.lastModifiedSync();

    // Store in cache for future use
    _cache[absolutePath] = _CachedParse(
      lastModified: lastModified,
      data: parsedData,
    );

    return parsedData;
  }

  /// Clear all cached parse results
  /// Useful for testing or when file system changes are expected
  static void clearCache() {
    _cache.clear();
  }

  /// Clear cache for a specific file
  static void clearCacheForFile(File file) {
    _cache.remove(file.absolute.path);
  }

  /// Internal implementation of the .env file parsing logic
  static Map<String, String> _parseEnvFileImpl(File file) {
    final Map<String, String> envVars = <String, String>{};

    final lines = file.readAsLinesSync();
    for (final line in lines) {
      final length = line.length;
      if (length == 0 || line.codeUnitAt(0) == hash) continue;

      final index = line.indexOf('=');
      if (index == -1 || index == 0) continue;

      final key = line.substring(0, index).trim();
      if (key.isEmpty) continue;

      var value = line.substring(index + 1).trim();

      // Fast quote removal without regex
      if (value.length >= 2) {
        final firstChar = value.codeUnitAt(0);
        final lastChar = value.codeUnitAt(value.length - 1);
        if ((firstChar == doubleQuote || firstChar == singleQuote) &&
            firstChar == lastChar) {
          value = value.substring(1, value.length - 1);
        }
      }

      envVars[key] = value;
    }

    return envVars;
  }
}
