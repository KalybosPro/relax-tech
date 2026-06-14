import 'dart:async';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

/// Runs `dart run build_runner build --delete-conflicting-outputs` in
/// [workingDirectory] (defaults to [Directory.current]).
///
/// Logs progress and warnings via [logger]; never throws.
Future<void> runBuildRunner(
  Logger logger, {
  Directory? workingDirectory,
  Duration timeout = const Duration(minutes: 2),
}) async {
  final dir = workingDirectory ?? Directory.current;

  logger.info('Running build_runner to generate schema...');

  try {
    final result = await Process.run(
      'dart',
      ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
      workingDirectory: dir.path,
      runInShell: true,
    ).timeout(timeout);

    if (result.exitCode == 0) {
      logger.success('Code generation completed.');
    } else {
      logger.warn(
        'build_runner finished with errors. '
        'Run ${lightCyan.wrap('dart run build_runner build')} manually.',
      );
      final stderr = result.stderr.toString().trim();
      if (stderr.isNotEmpty) logger.err(stderr);
    }
  } on TimeoutException {
    logger.warn(
      'build_runner timed out. '
      'Run ${lightCyan.wrap('dart run build_runner build')} manually.',
    );
  } on ProcessException {
    logger.warn(
      'Could not run build_runner. '
      'Run ${lightCyan.wrap('dart run build_runner build')} manually.',
    );
  }
}
