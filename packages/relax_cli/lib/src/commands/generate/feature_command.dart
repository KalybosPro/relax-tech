import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../generators/feature_generator.dart';
import '../../models/architecture.dart';
import '../../utils/architecture_detector.dart';
import '../../utils/validation.dart';

/// Generates a new feature module in the current Flutter project.
class FeatureCommand extends Command<int> {
  FeatureCommand({required Logger logger}) : _logger = logger {
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
  String get name => 'feature';

  @override
  String get description => 'Generate a new feature module.';

  @override
  String get invocation => 'relax generate feature <feature_name>';

  @override
  Future<int> run() async {
    final featureName = _getFeatureName();
    if (featureName == null) return ExitCode.usage.code;

    if (!isValidDartName(featureName)) {
      return invalidNameError(_logger, 'Feature', featureName);
    }

    // Check we're inside a Flutter project
    final featuresDir = Directory('${Directory.current.path}/lib/features');
    if (!Directory('${Directory.current.path}/lib').existsSync()) {
      _logger.err('No lib/ directory found.');
      _logger.info('Run this command from the root of a Flutter project.');
      return ExitCode.usage.code;
    }

    // Check feature doesn't already exist
    final featureDir = Directory('${featuresDir.path}/$featureName');
    if (featureDir.existsSync()) {
      _logger.err('Feature "$featureName" already exists.');
      return ExitCode.usage.code;
    }

    // Resolve architecture
    final architecture = _resolveArchitecture();
    if (architecture == null) return ExitCode.usage.code;

    _logger.info('');
    _logger.info(
      'Generating feature ${lightCyan.wrap(featureName)} '
      'with ${lightCyan.wrap(architecture.label)}...',
    );
    _logger.info('');

    final generator = FeatureGenerator(logger: _logger);

    try {
      final generatedFiles = await generator.generate(
        featureName: featureName,
        architecture: architecture,
        projectDir: Directory.current,
      );

      _logger.info('');
      _logger.success(
        'Generated feature "$featureName" '
        '(${generatedFiles.length} files).',
      );
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

  String? _getFeatureName() {
    final args = argResults!.rest;
    if (args.isEmpty) {
      _logger.err('No feature name specified.');
      _logger.info('Usage: $invocation');
      return null;
    }
    return args.first;
  }

  Architecture? _resolveArchitecture() {
    // Explicit flag takes priority
    final archArg = argResults?['architecture'] as String?;
    if (archArg != null) {
      return Architecture.values.byName(archArg);
    }

    // Auto-detect from pubspec.yaml
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
