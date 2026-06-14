import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../utils/sdk_helper.dart';

/// Runs a command with a specific Flutter SDK version on PATH, without
/// permanently pinning that version to the project.
class SdkSpawnCommand extends Command<int> {
  SdkSpawnCommand({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  String get name => 'spawn';

  @override
  String get description =>
      'Run a command using a specific SDK version (without pinning it).';

  @override
  String get invocation => 'relax sdk spawn <version> <command> [args...]';

  @override
  ArgParser get argParser => ArgParser.allowAnything();

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length < 2) {
      _logger.err('Usage: ${lightCyan.wrap(invocation)}');
      return ExitCode.usage.code;
    }

    final version = rest[0];
    final command = rest[1];
    final args = rest.skip(2).toList();

    if (!isSdkInstalled(version)) {
      _logger.err(
        'Flutter ${lightCyan.wrap(version)} is not installed.',
      );
      _logger.info(
        'Run ${lightCyan.wrap("relax sdk install $version")} first.',
      );
      return ExitCode.usage.code;
    }

    final sdkBin = resolveSdkBinDir(overrideVersion: version)!;
    final env = Map<String, String>.from(Platform.environment);
    final sep = Platform.isWindows ? ';' : ':';
    env['PATH'] = '$sdkBin$sep${env['PATH'] ?? ''}';

    _logger.detail(
      'Spawning ${lightCyan.wrap(command)} with Flutter $version',
    );

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
}
