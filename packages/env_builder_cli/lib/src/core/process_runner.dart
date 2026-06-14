import 'dart:async';
import 'dart:io';

// ignore_for_file: avoid_print

import 'core.dart';

/// Handles process execution
///
/// Provides utilities for running external commands, particularly
/// Flutter and Dart commands, with proper error handling and
/// working directory support.
class ProcessRunner {
  /// Runs a flutter/dart command
  static Future<ProcessResult> runFlutterCommand(
    List<String> arguments, {
    String? path,
    String engine = 'flutter',
  }) async => Process.run(
      engine,
      arguments,
      workingDirectory: path,
      runInShell: true,
    );

  /// Runs a dart command specifically
  static Future<ProcessResult> runDartCommand(
    List<String> arguments,
    String? path,
  ) async => runFlutterCommand(arguments, path: path, engine: 'dart');

  /// Runs a flutter command with real-time streaming of output
  static Future<Process> runFlutterCommandStreaming(
    List<String> arguments, {
    String? path,
    String engine = 'flutter',
  }) async {
    final process = await Process.start(
      engine,
      arguments,
      workingDirectory: path,
      runInShell: true,
    );

    // Stream stdout and stderr to terminal in real-time for progress indicators
    unawaited(stdout.addStream(process.stdout));
    unawaited(stderr.addStream(process.stderr));

    return process;
  }
}
