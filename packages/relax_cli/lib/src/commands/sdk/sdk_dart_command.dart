import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../utils/sdk_helper.dart';

/// Runs a Dart command using the project's (or global) pinned SDK version.
class SdkDartCommand extends Command<int> {
  SdkDartCommand({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  String get name => 'dart';

  @override
  String get description =>
      'Run a Dart command using the pinned SDK version.';

  @override
  String get invocation => 'relax sdk dart <dart-args...>';

  // Allow all tokens through — Dart flags must not be intercepted.
  @override
  ArgParser get argParser => ArgParser.allowAnything();

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    final binary = resolveDartBinary();

    if (binary == 'dart') {
      _logger.detail('No pinned version found — using dart from PATH.');
    } else {
      _logger.detail('Using Dart at: $binary');
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
      _logger.err('Could not launch dart: ${e.message}');
      return ExitCode.unavailable.code;
    }
  }
}
