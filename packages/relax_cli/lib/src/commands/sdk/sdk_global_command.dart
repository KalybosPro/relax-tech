import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../utils/sdk_helper.dart';

/// Gets or sets the global Flutter SDK version.
class SdkGlobalCommand extends Command<int> {
  SdkGlobalCommand({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  String get name => 'global';

  @override
  String get description => 'Get or set the global Flutter SDK version.';

  @override
  String get invocation => 'relax sdk global [<version>]';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;

    if (rest.isEmpty) {
      // Show current global version.
      final version = readGlobalVersion();
      _logger.info('');
      if (version != null) {
        final installed = isSdkInstalled(version);
        _logger.info(
          'Global Flutter version: ${lightCyan.wrap(version)}'
          '${installed ? "" : "  ${yellow.wrap("(not installed)")}"}',
        );
      } else {
        _logger.info('No global Flutter version set.');
        _logger.info(
          'Run ${lightCyan.wrap("relax sdk global <version>")} to set one.',
        );
      }
      _logger.info('');
      return ExitCode.success.code;
    }

    final version = rest.first;

    if (!isSdkInstalled(version)) {
      _logger.err(
        'Flutter ${lightCyan.wrap(version)} is not installed.',
      );
      _logger.info(
        'Run ${lightCyan.wrap("relax sdk install $version")} first.',
      );
      return ExitCode.usage.code;
    }

    writeGlobalVersion(version);
    _logger.success('Global version set to ${lightCyan.wrap(version)}.');
    _logger.info('');
    return ExitCode.success.code;
  }
}
