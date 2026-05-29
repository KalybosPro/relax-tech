import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../utils/sdk_helper.dart';

/// Executes a command with the project's pinned Flutter SDK bin directory
/// prepended to PATH.
class SdkExecCommand extends Command<int> {
  SdkExecCommand({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  String get name => 'exec';

  @override
  String get description =>
      'Execute a command with the pinned Flutter SDK on PATH.';

  @override
  String get invocation => 'relax sdk exec <command> [args...]';

  @override
  ArgParser get argParser => ArgParser.allowAnything();

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) {
      _logger.err('Missing command argument.');
      _logger.info('Usage: ${lightCyan.wrap(invocation)}');
      return ExitCode.usage.code;
    }

    final command = rest.first;
    final args = rest.skip(1).toList();
    final env = _buildEnv();

    _logger.detail('Executing: $command ${args.join(' ')}');

    try {
      final process = await Process.start(
        command,
        args,
        environment: env,
        runInShell: true,
        mode: ProcessStartMode.inheritStdio,
      );
      return await process.exitCode;
    } on ProcessException catch (e) {
      _logger.err('Could not execute command: ${e.message}');
      return ExitCode.unavailable.code;
    }
  }

  Map<String, String> _buildEnv() {
    final env = Map<String, String>.from(Platform.environment);
    final sdkBin = resolveSdkBinDir();
    if (sdkBin != null) {
      final sep = Platform.isWindows ? ';' : ':';
      env['PATH'] = '$sdkBin$sep${env['PATH'] ?? ''}';
      _logger.detail('Prepending SDK bin to PATH: $sdkBin');
    } else {
      _logger.detail('No pinned version found — using system PATH.');
    }
    return env;
  }
}
