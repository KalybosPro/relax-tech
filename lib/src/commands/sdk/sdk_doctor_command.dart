import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../utils/sdk_helper.dart';

/// Checks the Flutter SDK manager environment.
class SdkDoctorCommand extends Command<int> {
  SdkDoctorCommand({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  String get name => 'doctor';

  @override
  String get description => 'Check the Flutter SDK manager environment.';

  @override
  String get invocation => 'relax sdk doctor';

  @override
  Future<int> run() async {
    _logger.info('');
    _logger.info(lightCyan.wrap('relax sdk doctor') ?? 'relax sdk doctor');
    _logger.info('');

    var allGood = true;

    // 1. Git on PATH
    allGood &= await _checkCommand(
      label: 'Git',
      command: 'git',
      args: ['--version'],
      extract: (out) => RegExp(r'git version (\S+)').firstMatch(out)?.group(1),
    );

    // 2. SDK cache directory
    allGood &= _checkDirectory(
      label: 'SDK cache ($sdkCacheHome)',
      path: sdkCacheHome,
    );

    // 3. Installed versions count
    final versions = listInstalledVersions();
    _logger.info(
      '  ${green.wrap("[+]")} Installed versions: ${versions.isEmpty ? darkGray.wrap("none") : lightCyan.wrap(versions.length.toString())}',
    );

    // 4. Global version
    final globalVersion = readGlobalVersion();
    if (globalVersion != null) {
      final installed = isSdkInstalled(globalVersion);
      if (installed) {
        _logger.info(
          '  ${green.wrap("[+]")} Global version: ${lightCyan.wrap(globalVersion)}',
        );
      } else {
        _logger.info(
          '  ${yellow.wrap("[-]")} Global version: ${lightCyan.wrap(globalVersion)} — not installed',
        );
        allGood = false;
      }
    } else {
      _logger.info(
        '  ${yellow.wrap("[-]")} Global version: not set',
      );
    }

    // 5. Project version
    final projectVersion = readProjectVersion();
    if (projectVersion != null) {
      final installed = isSdkInstalled(projectVersion);
      if (installed) {
        _logger.info(
          '  ${green.wrap("[+]")} Project version: ${lightCyan.wrap(projectVersion)}',
        );
      } else {
        _logger.info(
          '  ${yellow.wrap("[-]")} Project version: ${lightCyan.wrap(projectVersion)} — not installed',
        );
      }
    } else {
      _logger.info(
        '  ${darkGray.wrap("[-]")} Project version: not pinned (not in a Flutter project or not configured)',
      );
    }

    _logger.info('');
    if (allGood) {
      _logger.success('All checks passed.');
    } else {
      _logger.warn('Some checks failed. See above for details.');
    }
    _logger.info('');

    return allGood ? ExitCode.success.code : ExitCode.unavailable.code;
  }

  Future<bool> _checkCommand({
    required String label,
    required String command,
    required List<String> args,
    required String? Function(String output) extract,
  }) async {
    try {
      final result = await Process.run(command, args, runInShell: true);
      final output = '${result.stdout}${result.stderr}'.trim();
      if (result.exitCode != 0) {
        _logger.info('  ${red.wrap("[x]")} $label — not working');
        return false;
      }
      final version = extract(output) ?? output.split('\n').first;
      _logger.info('  ${green.wrap("[+]")} $label — $version');
      return true;
    } on ProcessException {
      _logger.info('  ${red.wrap("[x]")} $label — not found on PATH');
      return false;
    }
  }

  bool _checkDirectory({required String label, required String path}) {
    final exists = Directory(path).existsSync();
    if (exists) {
      _logger.info('  ${green.wrap("[+]")} $label — exists');
    } else {
      _logger.info(
        '  ${yellow.wrap("[-]")} $label — not created yet (will be created on first install)',
      );
    }
    return true; // absence of cache dir is not an error
  }
}
