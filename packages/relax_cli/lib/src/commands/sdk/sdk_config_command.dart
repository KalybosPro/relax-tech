import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../utils/sdk_helper.dart';

/// Shows or updates the Flutter SDK manager configuration.
class SdkConfigCommand extends Command<int> {
  SdkConfigCommand({required Logger logger}) : _logger = logger {
    argParser
      ..addOption(
        'cache-path',
        help: 'Override the SDK cache directory path.',
      )
      ..addOption(
        'flutter-url',
        help: 'Override the Flutter git repository URL.',
      );
  }

  final Logger _logger;

  @override
  String get name => 'config';

  @override
  String get description => 'Show or update Flutter SDK manager configuration.';

  @override
  String get invocation =>
      'relax sdk config [--cache-path <path>] [--flutter-url <url>]';

  @override
  Future<int> run() async {
    final newCachePath = argResults?['cache-path'] as String?;
    final newFlutterUrl = argResults?['flutter-url'] as String?;

    var changed = false;

    if (newCachePath != null) {
      writeCachePathOverride(newCachePath);
      _logger.success('Cache path set to: ${lightCyan.wrap(newCachePath)}');
      changed = true;
    }

    if (newFlutterUrl != null) {
      writeFlutterUrlOverride(newFlutterUrl);
      _logger.success('Flutter URL set to: ${lightCyan.wrap(newFlutterUrl)}');
      changed = true;
    }

    if (!changed) {
      _logger.info('');
      _logger.info(lightCyan.wrap('relax sdk config') ?? 'relax sdk config');
      _logger.info('');
      _logger.info('  SDK cache:    ${lightCyan.wrap(sdkCacheHome)}');
      _logger.info('  Global config: ${lightCyan.wrap(globalConfigPath)}');

      final globalVersion = readGlobalVersion();
      _logger.info(
        '  Global version: ${globalVersion != null ? lightCyan.wrap(globalVersion) : darkGray.wrap("not set")}',
      );

      final urlOverride = readFlutterUrlOverride();
      _logger.info(
        '  Flutter URL:  ${lightCyan.wrap(urlOverride ?? flutterGitUrl)}${urlOverride == null ? darkGray.wrap(" (default)") : ""}',
      );

      _logger.info('');
      _logger.info(
        darkGray.wrap(
          'Use --cache-path or --flutter-url to override defaults.',
        ) ?? '',
      );
      _logger.info('');
    }

    return ExitCode.success.code;
  }
}
