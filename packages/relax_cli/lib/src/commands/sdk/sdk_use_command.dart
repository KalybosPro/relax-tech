import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../utils/sdk_helper.dart';
import 'sdk_install_command.dart';

/// Pins a Flutter SDK version for the current project.
class SdkUseCommand extends Command<int> {
  SdkUseCommand({required Logger logger}) : _logger = logger {
    argParser
      ..addFlag(
        'force',
        abbr: 'f',
        negatable: false,
        help: 'Install the version if it is not already installed.',
      )
      ..addFlag(
        'global',
        abbr: 'g',
        negatable: false,
        help: 'Also set this version as the global default.',
      );
  }

  final Logger _logger;

  @override
  String get name => 'use';

  @override
  String get description => 'Pin a Flutter SDK version for this project.';

  @override
  String get invocation => 'relax sdk use <version> [--force] [--global]';

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
    final setGlobal = argResults!['global'] as bool;

    if (!isSdkInstalled(version)) {
      if (force) {
        _logger.info(
          'Flutter ${lightCyan.wrap(version)} is not installed. Installing now...',
        );
        _logger.info('');
        final code = await installSdk(version: version, logger: _logger);
        if (code != ExitCode.success.code) return code;
      } else {
        _logger.err(
          'Flutter ${lightCyan.wrap(version)} is not installed.',
        );
        _logger.info(
          'Run ${lightCyan.wrap("relax sdk install $version")} to install it, '
          'or use ${lightCyan.wrap("--force")} to install automatically.',
        );
        return ExitCode.usage.code;
      }
    }

    writeProjectVersion(version);
    _logger.success(
      'Project pinned to Flutter ${lightCyan.wrap(version)}.',
    );

    try {
      linkProjectSdk(version);
      _logger.detail('SDK link created at .dart_tool/flutter_sdk');
    } catch (e) {
      _logger.warn('Could not create SDK link: $e');
    }

    if (setGlobal) {
      writeGlobalVersion(version);
      _logger.success('Global version set to ${lightCyan.wrap(version)}.');
    }

    _logger.info('');
    return ExitCode.success.code;
  }
}
