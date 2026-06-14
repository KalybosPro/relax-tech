import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../version.dart';

/// Checks the development environment for required tools.
class DoctorCommand extends Command<int> {
  DoctorCommand({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  String get name => 'doctor';

  @override
  String get description =>
      'Check your environment for required dependencies.';

  @override
  Future<int> run() async {
    _logger.info('');
    _logger.info(
      lightCyan.wrap('relax doctor') ?? 'relax doctor',
    );
    _logger.info(darkGray.wrap('v$version') ?? 'v$version');
    _logger.info('');

    var allGood = true;

    allGood &= await _check(
      name: 'Dart SDK',
      command: 'dart',
      args: ['--version'],
      extract: _extractVersion,
    );

    allGood &= await _check(
      name: 'Flutter SDK',
      command: 'flutter',
      args: ['--version', '--machine'],
      extract: _extractFlutterVersion,
    );

    allGood &= _checkDirectory(
      name: 'Flutter project',
      path: 'pubspec.yaml',
      required: false,
    );

    _logger.info('');
    if (allGood) {
      _logger.success('All checks passed!');
    } else {
      _logger.warn('Some checks failed. See above for details.');
    }
    _logger.info('');

    return allGood ? ExitCode.success.code : ExitCode.unavailable.code;
  }

  Future<bool> _check({
    required String name,
    required String command,
    required List<String> args,
    required String? Function(String output) extract,
  }) async {
    try {
      final result = await Process.run(command, args);
      final output = '${result.stdout}${result.stderr}'.trim();

      if (result.exitCode != 0) {
        _logger.info('  ${red.wrap('[x]')} $name — not working');
        return false;
      }

      final version = extract(output) ?? output.split('\n').first;
      _logger.info('  ${green.wrap('[+]')} $name — $version');
      return true;
    } on ProcessException {
      _logger.info('  ${red.wrap('[x]')} $name — not installed');
      return false;
    }
  }

  bool _checkDirectory({
    required String name,
    required String path,
    required bool required,
  }) {
    final exists = File(path).existsSync();
    if (exists) {
      _logger.info('  ${green.wrap('[+]')} $name — detected');
    } else if (required) {
      _logger.info('  ${red.wrap('[x]')} $name — not found');
    } else {
      _logger.info(
        '  ${yellow.wrap('[-]')} $name — not in a project directory',
      );
    }
    return exists || !required;
  }

  String? _extractVersion(String output) {
    final match = RegExp(r'Dart SDK version:\s*(\S+)').firstMatch(output);
    return match?.group(1);
  }

  String? _extractFlutterVersion(String output) {
    // --machine outputs JSON, but fallback to line parsing
    final match = RegExp(r'"frameworkVersion"\s*:\s*"([^"]+)"').firstMatch(output);
    if (match != null) return match.group(1);
    // Fallback: "Flutter X.Y.Z ..."
    final fallback = RegExp(r'Flutter\s+(\S+)').firstMatch(output);
    return fallback?.group(1);
  }
}
