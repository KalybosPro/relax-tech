import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

// ── Home directory ────────────────────────────────────────────────────────────

String get _userHome {
  if (Platform.isWindows) {
    return Platform.environment['USERPROFILE'] ??
        Platform.environment['HOMEPATH'] ??
        r'C:\Users\Default';
  }
  return Platform.environment['HOME'] ?? '/tmp';
}

// ── SDK cache directory ───────────────────────────────────────────────────────

/// Root of the SDK cache. Honour $RELAX_SDK_HOME; fall back to ~/relax/sdk/versions.
String get sdkCacheHome {
  final env = Platform.environment['RELAX_SDK_HOME'];
  if (env != null && env.isNotEmpty) return env;
  return p.join(_userHome, 'relax', 'sdk', 'versions');
}

/// Full path to the cached SDK for `version`.
String sdkCachePath(String version) => p.join(sdkCacheHome, version);

// ── Config file paths ─────────────────────────────────────────────────────────

/// Global config: ~/.relax/sdk_config.json
String get globalConfigPath => p.join(_userHome, '.relax', 'sdk_config.json');

/// Project config: <cwd>/.dart_tool/relax_sdk.json
String get projectConfigPath =>
    p.join(Directory.current.path, '.dart_tool', 'relax_sdk.json');

/// Legacy FVM project config path (read-only fallback for compatibility).
String get _legacyProjectConfigPath =>
    p.join(Directory.current.path, '.fvm', 'fvm_config.json');

/// Project SDK link: <cwd>/.dart_tool/flutter_sdk
String get projectSdkLinkPath =>
    p.join(Directory.current.path, '.dart_tool', 'flutter_sdk');

// ── Releases API URL ──────────────────────────────────────────────────────────

/// Flutter releases JSON URL for the current OS.
String get releasesUrl {
  final os = Platform.isWindows
      ? 'windows'
      : Platform.isMacOS
          ? 'macos'
          : 'linux';
  return 'https://storage.googleapis.com/flutter_infra_release/releases/releases_$os.json';
}

/// Git URL for the Flutter SDK repository.
const String flutterGitUrl = 'https://github.com/flutter/flutter.git';

// ── SDK presence checks ───────────────────────────────────────────────────────

/// Returns true if [version] is installed and the flutter binary exists.
bool isSdkInstalled(String version) {
  final dir = Directory(sdkCachePath(version));
  if (!dir.existsSync()) return false;
  final binary = Platform.isWindows
      ? p.join(sdkCachePath(version), 'bin', 'flutter.bat')
      : p.join(sdkCachePath(version), 'bin', 'flutter');
  return File(binary).existsSync();
}

/// Lists all installed version names (subdirectory names under `sdkCacheHome`).
List<String> listInstalledVersions() {
  final dir = Directory(sdkCacheHome);
  if (!dir.existsSync()) return [];
  return dir
      .listSync()
      .whereType<Directory>()
      .map((d) => p.basename(d.path))
      .toList()
    ..sort();
}

// ── Project config R/W ────────────────────────────────────────────────────────

/// Reads the project-pinned version.
/// Checks .dart_tool/relax_sdk.json first, then falls back to .fvm/fvm_config.json.
String? readProjectVersion() {
  final primary = File(projectConfigPath);
  if (primary.existsSync()) {
    final json = jsonDecode(primary.readAsStringSync()) as Map<String, dynamic>;
    return json['flutterSdkVersion'] as String?;
  }
  // Compatibility fallback: read existing FVM config if present.
  final legacy = File(_legacyProjectConfigPath);
  if (legacy.existsSync()) {
    final json = jsonDecode(legacy.readAsStringSync()) as Map<String, dynamic>;
    return json['flutterSdkVersion'] as String?;
  }
  return null;
}

/// Writes the project-pinned version to .dart_tool/relax_sdk.json.
void writeProjectVersion(String version) {
  final file = File(projectConfigPath);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    const JsonEncoder.withIndent('  ')
        .convert({'flutterSdkVersion': version}),
  );
}

// ── Global config R/W ─────────────────────────────────────────────────────────

Map<String, dynamic> _readGlobalConfigJson() {
  final file = File(globalConfigPath);
  if (!file.existsSync()) return {};
  try {
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  } catch (_) {
    return {};
  }
}

void _writeGlobalConfigJson(Map<String, dynamic> data) {
  final file = File(globalConfigPath);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
}

/// Reads the globally pinned Flutter version.
String? readGlobalVersion() =>
    _readGlobalConfigJson()['flutterSdkVersion'] as String?;

/// Writes the globally pinned Flutter version.
void writeGlobalVersion(String version) {
  final config = _readGlobalConfigJson();
  config['flutterSdkVersion'] = version;
  _writeGlobalConfigJson(config);
}

/// Reads the custom cache path override from global config (if set).
String? readCachePathOverride() =>
    _readGlobalConfigJson()['cachePath'] as String?;

/// Writes the custom cache path override to global config.
void writeCachePathOverride(String path) {
  final config = _readGlobalConfigJson();
  config['cachePath'] = path;
  _writeGlobalConfigJson(config);
}

/// Reads the custom Flutter git URL override from global config (if set).
String? readFlutterUrlOverride() =>
    _readGlobalConfigJson()['flutterUrl'] as String?;

/// Writes the custom Flutter git URL override to global config.
void writeFlutterUrlOverride(String url) {
  final config = _readGlobalConfigJson();
  config['flutterUrl'] = url;
  _writeGlobalConfigJson(config);
}

// ── SDK link management ───────────────────────────────────────────────────────

/// Creates (or replaces) the .dart_tool/flutter_sdk link pointing to [version]'s SDK.
/// On Windows, Link.createSync with a directory target creates an NTFS junction
/// (does not require Developer Mode or elevated privileges).
void linkProjectSdk(String version) {
  final target = sdkCachePath(version);
  final link = Link(projectSdkLinkPath);
  if (link.existsSync()) link.deleteSync();
  Directory(p.dirname(projectSdkLinkPath)).createSync(recursive: true);
  link.createSync(target);
}

// ── Binary resolution ─────────────────────────────────────────────────────────

/// Returns the absolute path to the flutter binary for [overrideVersion],
/// the project-pinned version, or the global version — whichever is available.
/// Falls back to 'flutter' on PATH.
String resolveFlutterBinary({String? overrideVersion}) {
  final version =
      overrideVersion ?? readProjectVersion() ?? readGlobalVersion();
  if (version != null && isSdkInstalled(version)) {
    return Platform.isWindows
        ? p.join(sdkCachePath(version), 'bin', 'flutter.bat')
        : p.join(sdkCachePath(version), 'bin', 'flutter');
  }
  return 'flutter';
}

/// Returns the absolute path to the dart binary for [overrideVersion],
/// the project-pinned version, or the global version — whichever is available.
/// Falls back to 'dart' on PATH.
String resolveDartBinary({String? overrideVersion}) {
  final version =
      overrideVersion ?? readProjectVersion() ?? readGlobalVersion();
  if (version != null && isSdkInstalled(version)) {
    return Platform.isWindows
        ? p.join(sdkCachePath(version), 'bin', 'dart.exe')
        : p.join(sdkCachePath(version), 'bin', 'dart');
  }
  return 'dart';
}

/// Returns the bin directory for [version]'s SDK, or null if not installed.
String? resolveSdkBinDir({String? overrideVersion}) {
  final version =
      overrideVersion ?? readProjectVersion() ?? readGlobalVersion();
  if (version != null && isSdkInstalled(version)) {
    return p.join(sdkCachePath(version), 'bin');
  }
  return null;
}

// ── Version resolution ────────────────────────────────────────────────────────

/// Known Flutter release channels accepted as version identifiers.
const List<String> flutterChannels = ['stable', 'beta', 'dev', 'master'];

/// Returns true if [version] is a channel name or a full semver tag (X.Y.Z).
bool isCompleteVersion(String version) {
  if (flutterChannels.contains(version)) return true;
  return RegExp(r'^\d+\.\d+\.\d+').hasMatch(version);
}

/// Resolves a partial version prefix (e.g. `"3.41"` → `"3.41.9"`) by
/// fetching the official releases list and returning the latest matching
/// stable release. Falls back to any channel if no stable match is found.
/// Returns null on network error or no match.
Future<String?> resolvePartialVersion(String partial) async {
  try {
    final response = await http.get(Uri.parse(releasesUrl));
    if (response.statusCode != 200) return null;
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final releases =
        (json['releases'] as List<dynamic>).cast<Map<String, dynamic>>();

    // Prefer latest stable match.
    for (final r in releases) {
      final v = r['version'] as String? ?? '';
      if (v.startsWith('$partial.') && r['channel'] == 'stable') return v;
    }
    // Fallback: any channel.
    for (final r in releases) {
      final v = r['version'] as String? ?? '';
      if (v.startsWith('$partial.')) return v;
    }
    return null;
  } catch (_) {
    return null;
  }
}

// ── Git installation ──────────────────────────────────────────────────────────

/// Clones the Flutter SDK at [version] (tag or channel) into the SDK cache.
/// Uses --depth 1 for a shallow clone (faster download).
Future<ProcessResult> gitCloneFlutter(String version) {
  final dest = sdkCachePath(version);
  Directory(dest).createSync(recursive: true);
  final gitUrl = readFlutterUrlOverride() ?? flutterGitUrl;
  return Process.run(
    'git',
    ['clone', '-b', version, '--depth', '1', gitUrl, dest],
    runInShell: true,
  );
}
