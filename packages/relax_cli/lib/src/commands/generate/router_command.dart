import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../generators/router_generator.dart';
import '../../models/architecture.dart';
import '../../utils/architecture_detector.dart';

/// Retroactively scaffolds the app router into an existing project.
///
/// Useful for projects created before navigation support existed, or when the
/// router file was removed. Safe to re-run — every step is idempotent.
class RouterCommand extends Command<int> {
  RouterCommand({required Logger logger}) : _logger = logger {
    argParser.addOption(
      'architecture',
      abbr: 'a',
      help: 'Override the detected architecture.',
      allowed: Architecture.values.map((a) => a.name),
      allowedHelp: {
        for (final arch in Architecture.values) arch.name: arch.label,
      },
    );
  }

  final Logger _logger;

  @override
  String get name => 'router';

  @override
  String get description =>
      'Scaffold the app router into an existing project (idempotent).';

  @override
  String get invocation => 'relax generate router';

  @override
  Future<int> run() async {
    if (!Directory('${Directory.current.path}/lib').existsSync()) {
      _logger.err('No lib/ directory found.');
      _logger.info('Run this command from the root of a Flutter project.');
      return ExitCode.usage.code;
    }

    final architecture = _resolveArchitecture();
    if (architecture == null) return ExitCode.usage.code;

    final generator = RouterGenerator(logger: _logger);

    try {
      final result = await generator.scaffold(
        architecture: architecture,
        projectDir: Directory.current,
      );

      _logger.info('');
      if (result.alreadyPresent) {
        _logger.info('Router already present — nothing to do.');
        return ExitCode.success.code;
      }

      _logger.success('Scaffolded the app router (${architecture.label}).');
      for (final warning in result.warnings) {
        _logger.warn(warning);
      }
      _logger.info('');
      return ExitCode.success.code;
    } on FileSystemException catch (e) {
      _logger.err('File system error: ${e.message}');
      return ExitCode.ioError.code;
    } on Exception catch (e) {
      _logger.err('Unexpected error: $e');
      return ExitCode.software.code;
    }
  }

  Architecture? _resolveArchitecture() {
    final archArg = argResults?['architecture'] as String?;
    if (archArg != null) {
      return Architecture.values.byName(archArg);
    }

    try {
      final detected = ArchitectureDetector.detect();
      if (detected != null) {
        _logger.detail('Detected architecture: ${detected.label}');
        return detected;
      }
      _logger.err(
        'Could not detect architecture from pubspec.yaml.\n'
        'Use --architecture (-a) to specify it manually.',
      );
      return null;
    } on FileSystemException catch (e) {
      _logger.err(e.message);
      return null;
    }
  }
}
