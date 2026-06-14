import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../utils/flutter_helper.dart';

/// Runs `flutter clean` in the current Flutter project.
class CleanCommand extends Command<int> {
  CleanCommand({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  String get name => 'clean';

  @override
  String get description => 'Clean the Flutter project build artifacts.';

  @override
  Future<int> run() async {
    final guard = guardFlutterProject(_logger);
    if (guard != null) return guard;

    logFvmStatus(_logger);

    final progress = _logger.progress('Running flutter clean...');
    try {
      final result = await runFlutter(['clean']);
      if (result.exitCode == 0) {
        progress.complete('Project cleaned.');
        return ExitCode.success.code;
      }
      progress.fail('flutter clean failed (exit ${result.exitCode}).');
      final stderr = result.stderr.toString().trim();
      if (stderr.isNotEmpty) _logger.err(stderr);
      return ExitCode.software.code;
    } on ProcessException catch (e) {
      progress.fail('Could not run flutter.');
      _logger.err(e.message);
      return ExitCode.unavailable.code;
    }
  }
}
