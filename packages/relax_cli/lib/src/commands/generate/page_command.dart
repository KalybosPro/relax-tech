import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../generators/page_generator.dart';
import '../../models/architecture.dart';
import '../../utils/architecture_detector.dart';
import '../../utils/validation.dart';

/// Generates a Page + View pair inside an existing feature folder.
class PageCommand extends Command<int> {
  PageCommand({required Logger logger}) : _logger = logger {
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
  String get name => 'page';

  @override
  String get description =>
      'Generate a new page inside an existing feature folder.';

  @override
  String get invocation => 'relax generate page <folder_name> <page_name>';

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.length < 2) {
      _logger.err('Missing arguments.');
      _logger.info('Usage: $invocation');
      return ExitCode.usage.code;
    }

    final folderName = args[0];
    final pageName = args[1];

    if (!isValidDartName(folderName)) {
      return invalidNameError(_logger, 'Folder', folderName);
    }

    if (!isValidDartName(pageName)) {
      return invalidNameError(_logger, 'Page', pageName);
    }

    if (!Directory('${Directory.current.path}/lib').existsSync()) {
      _logger.err('No lib/ directory found.');
      _logger.info('Run this command from the root of a Flutter project.');
      return ExitCode.usage.code;
    }

    final featureDir =
        Directory('${Directory.current.path}/lib/features/$folderName');
    if (!featureDir.existsSync()) {
      _logger.err('Feature "$folderName" does not exist.');
      _logger.info(
        'Create it first with: relax generate feature $folderName',
      );
      return ExitCode.usage.code;
    }

    final pageFile = File('${featureDir.path}/view/${pageName}_page.dart');
    if (pageFile.existsSync()) {
      _logger.err(
        'Page "$pageName" already exists in feature "$folderName".',
      );
      return ExitCode.usage.code;
    }

    final architecture = _resolveArchitecture();
    if (architecture == null) return ExitCode.usage.code;

    _logger.info('');
    _logger.info(
      'Generating page ${lightCyan.wrap(pageName)} '
      'in feature ${lightCyan.wrap(folderName)} '
      'with ${lightCyan.wrap(architecture.label)}...',
    );
    _logger.info('');

    final generator = PageGenerator(logger: _logger);

    try {
      final generatedFiles = await generator.generate(
        folderName: folderName,
        pageName: pageName,
        architecture: architecture,
        projectDir: Directory.current,
      );

      _logger.info('');
      _logger.success(
        'Generated page "$pageName" in feature "$folderName" '
        '(${generatedFiles.length} files).',
      );
      _logger.info('');
      _logger.info(
        "Add to ${lightCyan.wrap('lib/features/$folderName/$folderName.dart')}: "
        "export 'view/${pageName}_page.dart';",
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
