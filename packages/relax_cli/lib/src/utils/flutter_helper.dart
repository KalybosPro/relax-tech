import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

import 'sdk_helper.dart';

final String _workDir = Directory.current.path;

/// Returns `ExitCode.usage.code` if no `pubspec.yaml` is found in
/// `Directory.current`, logging a helpful message. Returns `null` on success.
int? guardFlutterProject(Logger logger) {
  if (!File('$_workDir/pubspec.yaml').existsSync()) {
    logger.err('No pubspec.yaml found.');
    logger.info('Run this command from the root of a Flutter project.');
    return ExitCode.usage.code;
  }
  return null;
}

/// Logs a detail line when a pinned SDK version is detected.
/// Call this after [guardFlutterProject] and before running flutter commands.
void logFvmStatus(Logger logger) {
  final version = readProjectVersion() ?? readGlobalVersion();
  if (version != null && isSdkInstalled(version)) {
    logger.detail('Pinned Flutter $version detected — using managed SDK.');
  }
}

/// Formats all Dart files in `Directory.current` using `dart format .`.
///
/// Returns `null` on success, or an exit code int on failure — meant to be
/// returned directly from `Command.run`:
/// ```dart
/// final fmt = await formatCode(_logger);
/// if (fmt != null) return fmt;
/// ```
Future<int?> formatCode(Logger logger) async {
  final progress = logger.progress('Formatting code...');
  try {
    final result = await Process.run(
      'dart',
      ['format', '.'],
      workingDirectory: _workDir,
      runInShell: true,
    );
    if (result.exitCode == 0) {
      progress.complete('Code formatted.');
      return null;
    }
    progress.fail('dart format failed.');
    final stderr = result.stderr.toString().trim();
    if (stderr.isNotEmpty) logger.err(stderr);
    return ExitCode.software.code;
  } on ProcessException catch (e) {
    progress.fail('Could not run dart format.');
    logger.err(e.message);
    return ExitCode.unavailable.code;
  }
}

/// Runs `flutter <args>` in `Directory.current`, using the project-pinned or
/// global SDK version when available, otherwise falling back to `flutter` on PATH.
///
/// Throws [ProcessException] if no flutter executable is found.
Future<ProcessResult> runFlutter(List<String> args) {
  final binary = resolveFlutterBinary();
  return Process.run(
    binary,
    args,
    workingDirectory: _workDir,
    runInShell: true,
  );
}
