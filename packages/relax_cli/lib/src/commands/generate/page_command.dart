import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../generators/feature_generator.dart' show RouteWiring;
import '../../generators/page_generator.dart';
import '../../models/architecture.dart';
import '../../utils/architecture_detector.dart';
import '../../utils/source_patcher.dart';
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
    argParser.addFlag(
      'route',
      defaultsTo: true,
      help: 'Register the page as a child route of its feature.',
    );
  }

  final Logger _logger;

  @override
  String get name => 'page';

  @override
  String get description =>
      'Generate a new page inside an existing feature folder.';

  @override
  String get invocation =>
      'relax generate page <folder_name> <page_name>  (or <folder>/<page>)';

  @override
  Future<int> run() async {
    final args = argResults!.rest;

    // Two accepted forms:
    //   relax g page product product_details   (two args)
    //   relax g page product/product_details    (single path spec — last
    //                                             segment is the page name)
    final String folderName;
    final String pageName;
    if (args.length >= 2) {
      folderName = args[0];
      pageName = args[1];
    } else if (args.length == 1 &&
        (args[0].contains('/') || args[0].contains(r'\'))) {
      final parsed = parsePathSpec(args[0]);
      folderName = parsed.subPath;
      pageName = parsed.name;
      if (folderName.isEmpty) {
        _logger.err('Missing feature folder.');
        _logger.info('Usage: $invocation');
        return ExitCode.usage.code;
      }
    } else {
      _logger.err('Missing arguments.');
      _logger.info('Usage: $invocation');
      return ExitCode.usage.code;
    }

    if (!isValidPathSpec(folderName)) {
      return invalidNameError(_logger, 'Folder', folderName);
    }

    if (!isValidDartName(pageName)) {
      return invalidNameError(_logger, 'Page', pageName);
    }

    // The leaf segment of a (possibly nested) feature path drives class names.
    final (subPath: _, name: featureName) = parsePathSpec(folderName);

    if (!Directory('${Directory.current.path}/lib').existsSync()) {
      _logger.err('No lib/ directory found.');
      _logger.info('Run this command from the root of a Flutter project.');
      return ExitCode.usage.code;
    }

    final featureDir = Directory(
      '${Directory.current.path}/lib/features/$folderName',
    );
    if (!featureDir.existsSync()) {
      _logger.err('Feature "$folderName" does not exist.');
      _logger.info('Create it first with: relax generate feature $folderName');
      return ExitCode.usage.code;
    }

    final pageFile = File('${featureDir.path}/view/${pageName}_page.dart');
    if (pageFile.existsSync()) {
      _logger.err('Page "$pageName" already exists in feature "$folderName".');
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

    final wireRoute = argResults?['route'] as bool? ?? true;
    final generator = PageGenerator(logger: _logger);

    try {
      final result = await generator.generate(
        folderName: folderName,
        featureName: featureName,
        pageName: pageName,
        architecture: architecture,
        projectDir: Directory.current,
        wireRoute: wireRoute,
      );

      _logger.info('');
      _logger.success(
        'Generated page "$pageName" in feature "$folderName" '
        '(${result.files.length} files).',
      );

      // Auto-export the new page from the feature barrel.
      final barrel = File('${featureDir.path}/$featureName.dart');
      final exportLine = "export 'view/${pageName}_page.dart';";
      final export = SourcePatcher.ensureLine(
        barrel,
        line: exportLine,
        guard: 'view/${pageName}_page.dart',
      );
      if (export.status == PatchStatus.inserted) {
        _logger.info(
          'Exported from '
          '${lightCyan.wrap('lib/features/$folderName/$featureName.dart')}.',
        );
      } else if (export.status == PatchStatus.fileMissing) {
        _logger.warn(
          'Barrel lib/features/$folderName/$featureName.dart not found — '
          "add `$exportLine` manually.",
        );
      }

      _reportRouteWiring(result.routeWiring, folderName);
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

  void _reportRouteWiring(RouteWiring wiring, String folderName) {
    switch (wiring) {
      case RouteWiring.wired:
        _logger.info('Registered as a child route of "$folderName".');
      case RouteWiring.alreadyPresent:
        _logger.info('Route already registered — router left unchanged.');
      case RouteWiring.routerMissing:
        _logger.warn(
          'No app router found — page route not registered. '
          'Run `relax generate router` first.',
        );
      case RouteWiring.anchorMissing:
        _logger.warn(
          'Feature "$folderName" has no route to nest under — '
          'register the page route manually.',
        );
      case RouteWiring.skipped:
        break;
    }
  }
}
