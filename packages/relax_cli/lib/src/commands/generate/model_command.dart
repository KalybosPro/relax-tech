import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../generators/model_generator.dart';
import '../../utils/build_runner_helper.dart';
import '../../utils/validation.dart';

/// Generates a new RelaxORM model in the current Flutter project.
///
/// Usage: `relax generate model user_profile`
/// Alias: `relax g model user_profile`
class ModelCommand extends Command<int> {
  ModelCommand({required Logger logger}) : _logger = logger {
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Output directory relative to lib/ (default: models).',
      defaultsTo: 'models',
    );
  }

  final Logger _logger;

  @override
  String get name => 'model';

  @override
  String get description =>
      'Generate a RelaxORM model class with @RelaxTable annotation.';

  @override
  String get invocation => 'relax generate model <model_name>';

  @override
  Future<int> run() async {
    final modelSpec = _getModelName();
    if (modelSpec == null) return ExitCode.usage.code;

    if (!isValidPathSpec(modelSpec)) {
      return invalidNameError(_logger, 'Model', modelSpec);
    }

    // Split a path spec like `user/profile` into a parent folder and the name.
    final (:subPath, :name) = parsePathSpec(modelSpec);
    final modelName = name;

    final libDir = Directory('${Directory.current.path}/lib');
    if (!libDir.existsSync()) {
      _logger.err('No lib/ directory found.');
      _logger.info('Run this command from the root of a Flutter project.');
      return ExitCode.usage.code;
    }

    final outputDirName = argResults?['output'] as String;
    final outputDir = subPath.isEmpty
        ? Directory('${libDir.path}/$outputDirName')
        : Directory('${libDir.path}/$outputDirName/$subPath');
    final modelFile = File('${outputDir.path}/$modelName.dart');

    if (modelFile.existsSync()) {
      _logger.err('Model "$modelSpec" already exists in $outputDirName/.');
      return ExitCode.usage.code;
    }

    _logger.info('');
    _logger.info(
      'Generating model ${lightCyan.wrap(modelSpec)} '
      'in ${lightCyan.wrap('lib/$outputDirName/')}...',
    );
    _logger.info('');

    final generator = ModelGenerator(logger: _logger);

    try {
      final generatedFiles = await generator.generate(
        modelName: modelName,
        outputDir: outputDir,
      );

      _logger.info('');
      _logger.success(
        'Generated model "$modelSpec" '
        '(${generatedFiles.length} file).',
      );
      _logger.info('');

      await runBuildRunner(_logger);
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

  String? _getModelName() {
    final args = argResults!.rest;
    if (args.isEmpty) {
      _logger.err('No model name specified.');
      _logger.info('Usage: $invocation');
      return null;
    }
    return args.first;
  }
}
