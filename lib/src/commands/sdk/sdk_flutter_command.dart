import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../utils/sdk_helper.dart';

/// Runs a Flutter command using the project's (or global) pinned SDK version.
class SdkFlutterCommand extends Command<int> {
  SdkFlutterCommand({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  String get name => 'flutter';

  @override
  String get description =>
      'Run a Flutter command using the pinned SDK version.';

  @override
  String get invocation => 'relax sdk flutter <flutter-args...>';

  // Allow all tokens through — Flutter flags must not be intercepted.
  @override
  ArgParser get argParser => ArgParser.allowAnything();

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    final binary = resolveFlutterBinary();

    if (binary == 'flutter') {
      _logger.detail('No pinned version found — using flutter from PATH.');
    } else {
      _logger.detail('Using Flutter at: $binary');
    }

    try {
      final process = await Process.start(
        binary,
        args,
        runInShell: true,
        mode: ProcessStartMode.inheritStdio,
      );
      return await process.exitCode;
    } on ProcessException catch (e) {
      _logger.err('Could not launch flutter: ${e.message}');
      return ExitCode.unavailable.code;
    }
  }
}
