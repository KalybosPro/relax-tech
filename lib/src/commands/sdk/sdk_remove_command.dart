import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../utils/sdk_helper.dart';

/// Removes an installed Flutter SDK version from the local cache.
class SdkRemoveCommand extends Command<int> {
  SdkRemoveCommand({required Logger logger}) : _logger = logger {
    argParser.addFlag(
      'force',
      abbr: 'f',
      negatable: false,
      help: 'Skip confirmation prompt.',
    );
  }

  final Logger _logger;

  @override
  String get name => 'remove';

  @override
  List<String> get aliases => ['rm'];

  @override
  String get description => 'Remove an installed Flutter SDK version.';

  @override
  String get invocation => 'relax sdk remove <version>';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) {
      _logger.err('Missing version argument.');
      _logger.info('Usage: ${lightCyan.wrap(invocation)}');
      return ExitCode.usage.code;
    }

    final version = rest.first;
    final force = argResults!['force'] as bool;

    if (!isSdkInstalled(version)) {
      _logger.err(
        'Flutter ${lightCyan.wrap(version)} is not installed.',
      );
      return ExitCode.usage.code;
    }

    if (!force) {
      final confirm = _logger.prompt(
        'Remove Flutter ${lightCyan.wrap(version)}? (y/N)',
      );
      if (confirm.trim().toLowerCase() != 'y') {
        _logger.info('Aborted.');
        return ExitCode.success.code;
      }
    }

    final progress = _logger.progress('Removing Flutter ${lightCyan.wrap(version)}...');
    try {
      Directory(sdkCachePath(version)).deleteSync(recursive: true);
      progress.complete('Flutter ${lightCyan.wrap(version)} removed.');
    } catch (e) {
      progress.fail('Failed to remove: $e');
      return ExitCode.software.code;
    }

    // Warn if project still references this version.
    final projectVersion = readProjectVersion();
    if (projectVersion == version) {
      _logger.warn(
        'Your project still references ${lightCyan.wrap(version)}. '
        'Run ${lightCyan.wrap("relax sdk use <version>")} to switch.',
      );
    }

    final globalVersion = readGlobalVersion();
    if (globalVersion == version) {
      _logger.warn(
        'Your global version is still ${lightCyan.wrap(version)}. '
        'Run ${lightCyan.wrap("relax sdk global <version>")} to update it.',
      );
    }

    _logger.info('');
    return ExitCode.success.code;
  }
}
