import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../utils/flutter_helper.dart';

/// Runs `flutter pub add <package>` in the current Flutter project.
class PubAddCommand extends Command<int> {
  PubAddCommand({required Logger logger}) : _logger = logger {
    argParser.addOption(
      'version',
      abbr: 'V',
      help: 'Version constraint (e.g. ^1.0.0). Omit to use the latest.',
    );
  }

  final Logger _logger;

  @override
  String get name => 'add';

  @override
  String get description => 'Add a package with flutter pub add.';

  @override
  String get invocation => 'relax pub add <package_name>';

  @override
  Future<int> run() async {
    final packageName = _getPackageName();
    if (packageName == null) return ExitCode.usage.code;

    final guard = guardFlutterProject(_logger);
    if (guard != null) return guard;

    logFvmStatus(_logger);

    final version = argResults?['version'] as String?;
    // flutter pub add accepts "package:^1.0.0" syntax for pinned versions
    final packageSpec =
        version != null ? '$packageName:$version' : packageName;

    final progress = _logger.progress(
      'Adding ${lightCyan.wrap(packageName)}...',
    );
    try {
      final result = await runFlutter(['pub', 'add', packageSpec]);
      if (result.exitCode == 0) {
        progress.complete('Package added.');
        _logger.success('Added $packageName.');
        return ExitCode.success.code;
      }
      progress.fail('flutter pub add failed (exit ${result.exitCode}).');
      final stderr = result.stderr.toString().trim();
      if (stderr.isNotEmpty) _logger.err(stderr);
      return ExitCode.software.code;
    } on ProcessException catch (e) {
      progress.fail('Could not run flutter.');
      _logger.err(e.message);
      return ExitCode.unavailable.code;
    }
  }

  String? _getPackageName() {
    final rest = argResults!.rest;
    if (rest.isEmpty) {
      _logger.err('No package name specified.');
      _logger.info('Usage: $invocation');
      return null;
    }
    return rest.first;
  }
}
