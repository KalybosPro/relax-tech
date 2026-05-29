import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../utils/sdk_helper.dart';

/// Lists all locally installed Flutter SDK versions.
class SdkListCommand extends Command<int> {
  SdkListCommand({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  String get name => 'list';

  @override
  List<String> get aliases => ['ls'];

  @override
  String get description => 'List all installed Flutter SDK versions.';

  @override
  String get invocation => 'relax sdk list';

  @override
  Future<int> run() async {
    final versions = listInstalledVersions();
    final projectVersion = readProjectVersion();
    final globalVersion = readGlobalVersion();

    _logger.info('');
    _logger.info('Installed Flutter SDK versions:');
    _logger.info('');

    if (versions.isEmpty) {
      _logger.warn('No Flutter SDK versions installed.');
      _logger.info('Run ${lightCyan.wrap("relax sdk install <version>")} to install one.');
      _logger.info('');
      return ExitCode.success.code;
    }

    for (final v in versions) {
      final tags = <String>[];
      if (v == projectVersion) tags.add(green.wrap('project')!);
      if (v == globalVersion) tags.add(cyan.wrap('global')!);
      final suffix = tags.isEmpty ? '' : '  ${tags.join(', ')}';
      _logger.info('  ${lightCyan.wrap(v)}$suffix');
    }

    _logger.info('');
    _logger.info('Cache: ${darkGray.wrap(sdkCacheHome)}');
    _logger.info('');

    return ExitCode.success.code;
  }
}
