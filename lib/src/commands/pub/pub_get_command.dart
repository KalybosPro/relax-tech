import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../utils/flutter_helper.dart';

/// Runs `flutter pub get` in the current Flutter project.
class PubGetCommand extends Command<int> {
  PubGetCommand({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  String get name => 'get';

  @override
  String get description => 'Run flutter pub get in the current project.';

  @override
  String get invocation => 'relax pub get';

  @override
  Future<int> run() async {
    final guard = guardFlutterProject(_logger);
    if (guard != null) return guard;

    logFvmStatus(_logger);

    final progress = _logger.progress('Running flutter pub get...');
    try {
      final result = await runFlutter(['pub', 'get']);
      if (result.exitCode == 0) {
        progress.complete('Packages updated.');
        _logger.success('flutter pub get completed.');
        return ExitCode.success.code;
      }
      progress.fail('flutter pub get failed (exit ${result.exitCode}).');
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
