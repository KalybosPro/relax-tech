import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../generators/module_generator.dart';
import '../../utils/build_runner_helper.dart';
import '../../utils/validation.dart';

/// Generates a new domain/data module in the current Flutter project.
class ModuleCommand extends Command<int> {
  ModuleCommand({required Logger logger}) : _logger = logger {
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Output directory relative to lib/ (default: modules).',
      defaultsTo: 'modules',
    );
  }

  final Logger _logger;

  @override
  String get name => 'module';

  @override
  String get description =>
      'Generate a domain/data module (model, repository, data source).';

  @override
  String get invocation => 'relax generate module <module_name>';

  @override
  Future<int> run() async {
    final moduleSpec = _getModuleName();
    if (moduleSpec == null) return ExitCode.usage.code;

    if (!isValidPathSpec(moduleSpec)) {
      return invalidNameError(_logger, 'Module', moduleSpec);
    }

    // Split a path spec like `account/user` into a parent folder and the name.
    final (:subPath, :name) = parsePathSpec(moduleSpec);
    final moduleName = name;

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
    final moduleDir = Directory('${outputDir.path}/$moduleName');

    if (moduleDir.existsSync()) {
      _logger.err('Module "$moduleSpec" already exists in $outputDirName/.');
      return ExitCode.usage.code;
    }

    _logger.info('');
    _logger.info(
      'Generating module ${lightCyan.wrap(moduleSpec)} '
      'in ${lightCyan.wrap('lib/$outputDirName/')}...',
    );
    _logger.info('');

    final generator = ModuleGenerator(logger: _logger);

    try {
      final generatedFiles = await generator.generate(
        moduleName: moduleName,
        outputDir: outputDir,
      );

      _logger.info('');
      _logger.success(
        'Generated module "$moduleSpec" '
        '(${generatedFiles.length} files).',
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

  String? _getModuleName() {
    final args = argResults!.rest;
    if (args.isEmpty) {
      _logger.err('No module name specified.');
      _logger.info('Usage: $invocation');
      return null;
    }
    return args.first;
  }
}
