import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../utils/sdk_helper.dart';

/// Removes all Flutter SDK manager data (cache and global config).
class SdkDestroyCommand extends Command<int> {
  SdkDestroyCommand({required Logger logger}) : _logger = logger {
    argParser.addFlag(
      'force',
      abbr: 'f',
      negatable: false,
      help: 'Skip confirmation prompt.',
    );
  }

  final Logger _logger;

  @override
  String get name => 'destroy';

  @override
  String get description =>
      'Remove all Flutter SDK manager data (cache + global config).';

  @override
  String get invocation => 'relax sdk destroy [--force]';

  @override
  Future<int> run() async {
    final force = argResults!['force'] as bool;

    _logger.warn('This will permanently delete:');
    _logger.info('  • SDK cache: ${lightCyan.wrap(sdkCacheHome)}');
    _logger.info('  • Global config: ${lightCyan.wrap(globalConfigPath)}');
    _logger.info('');

    if (!force) {
      final confirm = _logger.prompt('Continue? (y/N)');
      if (confirm.trim().toLowerCase() != 'y') {
        _logger.info('Aborted.');
        return ExitCode.success.code;
      }
    }

    var exitCode = ExitCode.success.code;

    final cacheDir = Directory(sdkCacheHome);
    if (cacheDir.existsSync()) {
      final progress = _logger.progress('Deleting SDK cache...');
      try {
        cacheDir.deleteSync(recursive: true);
        progress.complete('SDK cache deleted.');
      } catch (e) {
        progress.fail('Failed to delete SDK cache: $e');
        exitCode = ExitCode.software.code;
      }
    } else {
      _logger.detail('SDK cache does not exist, skipping.');
    }

    final configFile = File(globalConfigPath);
    if (configFile.existsSync()) {
      try {
        configFile.deleteSync();
        _logger.detail('Global config deleted.');
      } catch (e) {
        _logger.warn('Could not delete global config: $e');
        exitCode = ExitCode.software.code;
      }
    }

    if (exitCode == ExitCode.success.code) {
      _logger.info('');
      _logger.success('All Flutter SDK manager data removed.');
    }
    _logger.info('');

    return exitCode;
  }
}
