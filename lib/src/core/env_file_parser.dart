// ignore_for_file: avoid_print

import 'dart:collection';

import 'cli_colors.dart';
import 'core.dart';

/// Internal class to store cached parse results with file metadata
class _CachedParse {

  _CachedParse({required this.lastModified, required this.data}) {
    lastAccessTime = DateTime.now();
  }
  final DateTime lastModified;
  final Map<String, String> data;
  late DateTime lastAccessTime;
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
  static const int maxCacheSize = 500; // Max files to cache
  static const int maxCacheMemoryMB = 100; // Max ~100MB in cache

  // Cache for parsed files: key = absolute path, value = (lastModified, parsedMap)
  static final Map<String, _CachedParse> _cache = <String, _CachedParse>{};
  
  // Cache statistics for monitoring
  static int _cacheHits = 0;
  static int _cacheMisses = 0;

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
        _cacheHits++;
        // Update access time for LRU tracking (O(1) with no copy!)
        cached.lastAccessTime = DateTime.now();
        // Return immutable view - O(1) operation, no copying!
        return UnmodifiableMapView<String, String>(cached.data);
      }
    }

    _cacheMisses++;
    // Cache miss or file modified - parse the file
    final parsedData = _parseEnvFileImpl(file);
    final lastModified = file.lastModifiedSync();

    // Enforce cache limits before adding new entry
    _enforceMemoryCacheLimits();

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

  /// Enforce cache memory limits using LRU eviction
  /// Removes least-recently-used items when limits are exceeded
  static void _enforceMemoryCacheLimits() {
    // Check count limit
    if (_cache.length >= maxCacheSize) {
      // Remove least recently used item
      var lruKey = '';
      var lruTime = DateTime.now();
      
      for (final key in _cache.keys) {
        final accessTime = _cache[key]!.lastAccessTime;
        if (accessTime.isBefore(lruTime)) {
          lruTime = accessTime;
          lruKey = key;
        }
      }
      
      if (lruKey.isNotEmpty) {
        _cache.remove(lruKey);
      }
    }
    
    // Check memory limit (rough estimate: ~100 bytes per env var)
    final estimatedMemoryMB = (_cache.values.fold(0, (sum, cached) => sum + (cached.data.length * 100)) / (1024 * 1024)).toInt();
    
    if (estimatedMemoryMB > maxCacheMemoryMB) {
      // Clear oldest 20% of cache
      final itemsToRemove = (_cache.length * 0.2).ceil().clamp(1, _cache.length);
      final sortedByAccess = _cache.entries
          .map((e) => MapEntry(e.key, e.value.lastAccessTime))
          .toList()
          ..sort((a, b) => a.value.compareTo(b.value));
      
      for (var i = 0; i < itemsToRemove && i < sortedByAccess.length; i++) {
        _cache.remove(sortedByAccess[i].key);
      }
    }
  }

  /// Get cache statistics for monitoring and debugging
  static Map<String, dynamic> getCacheStats() {
    final totalVars = _cache.values.fold(0, (sum, p) => sum + p.data.length);
    final totalHitsMisses = _cacheHits + _cacheMisses;
    final hitRate = totalHitsMisses > 0 ? (_cacheHits / totalHitsMisses * 100) : 0.0;
    
    return {
      'cacheSize': _cache.length,
      'totalVariables': totalVars,
      'cacheHits': _cacheHits,
      'cacheMisses': _cacheMisses,
      'hitRate': hitRate.toStringAsFixed(2),
      'estimatedMemoryMB': (_cache.values.fold(0, (sum, p) => sum + (p.data.length * 100)) / (1024 * 1024)).toStringAsFixed(2),
    };
  }

  /// Reset cache statistics (useful for benchmarking)
  static void resetCacheStats() {
    _cacheHits = 0;
    _cacheMisses = 0;
  }

  /// Internal implementation of the .env file parsing logic
  /// Uses optimal memory-based parsing via readAsLinesSync
  static Map<String, String> _parseEnvFileImpl(File file) {
    try {
      return _parseEnvFileMemory(file);
    } catch (e) {
      CliLogger.warning('Failed to parse .env file "${file.path}": $e');
      // Return empty map on parse error
      return <String, String>{};
    }
  }

  /// Standard memory-based parsing for smaller files
  static Map<String, String> _parseEnvFileMemory(File file) {
    final envVars = <String, String>{};

    final lines = file.readAsLinesSync();
    for (final line in lines) {
      final parsed = _parseEnvLine(line);
      if (parsed != null) {
        envVars[parsed.key] = parsed.value;
      }
    }

    return envVars;
  }

  /// Parse a single .env line and return key-value pair
  /// Optimized for minimal allocations and early termination
  static _EnvLineParseResult? _parseEnvLine(String line) {
    final length = line.length;
    // Fast path: empty line or comment
    if (length == 0 || line.codeUnitAt(0) == hash) {
      return null;
    }

    final index = line.indexOf('=');
    if (index <= 0) {
      CliLogger.debug('Skipping malformed line (no = found): "$line"');
      return null; // No = or = at start
    }

    final key = line.substring(0, index).trim();
    if (key.isEmpty) {
      CliLogger.debug('Skipping line with empty key: "$line"');
      return null;
    }

    // Parse value with optimized quote removal
    var value = line.substring(index + 1).trim();

    // Optimized quote removal: avoid substring if possible
    if (value.length >= 2) {
      final firstChar = value.codeUnitAt(0);
      // Check if it's a quote character
      if (firstChar == doubleQuote || firstChar == singleQuote) {
        final lastChar = value.codeUnitAt(value.length - 1);
        // Only substring if quotes match
        if (firstChar == lastChar) {
          // Avoid unnecessary substring allocation
          value = value.substring(1, value.length - 1);
        } else {
          CliLogger.debug('Skipping line with mismatched quotes: "$line"');
          return null;
        }
      }
    }

    return _EnvLineParseResult(key, value);
  }
}

/// Helper class for parsing results
class _EnvLineParseResult {

  _EnvLineParseResult(this.key, this.value);
  final String key;
  final String value;
}
