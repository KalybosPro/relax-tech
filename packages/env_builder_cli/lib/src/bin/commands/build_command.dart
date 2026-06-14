import 'package:args/command_runner.dart';
import 'package:env_builder_cli/env_builder_cli.dart' as env_builder_cli;
import 'package:path/path.dart' as p;

import '../../core/cli_colors.dart';
import '../../core/core.dart';
import '../cli_config.dart';
import '../dart_file_generator.dart';
import '../directory_manager.dart';
import '../file_copier.dart';
import '../file_validator.dart';
import '../package_configurator.dart';

// ignore_for_file: avoid_print

/// Command for building env packages from .env files
class BuildCommand extends Command<int> {

  BuildCommand() {
    argParser.addOption(
      'env-file',
      abbr: 'e',
      help:
          'Environment file(s) - if not specified, all .env* files will be used',
    );
    argParser.addOption(
      'output-dir',
      abbr: 'o',
      help: 'Custom output directory for the env package',
      defaultsTo: 'env',
    );
    argParser.addFlag(
      'no-encrypt',
      help: 'Skip encryption of sensitive variables',
      negatable: false,
    );
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: 'Show detailed output during build process',
    );
    argParser.addFlag(
      'no-color',
      help: 'Disable colored output',
      negatable: false,
    );
  }
  static bool _verbose = false;

  static bool get isVerbose => _verbose;

  @override
  String get description => 'Build env package from .env files';

  @override
  String get name => 'build';

  @override
  Future<int> run() async {
    try {
      // Set verbose flag and colors
      _verbose = argResults!['verbose'] as bool;
      final noColor = argResults!['no-color'] as bool;
      CliLogger.setVerbose(_verbose);
      CliColors.setUseColors(!noColor);

      CliLogger.info('Starting env package build process...');

      final envFileArg = argResults!['env-file'] as String?;
      List<String> envFilePaths;

      if (envFileArg == null || envFileArg.isEmpty) {
        // Scan for .env* files if no specific file provided
        CliLogger.debug('Scanning for .env* files in current directory...');
        envFilePaths = _findEnvFilesInDirectory(Directory.current);
        if (envFilePaths.isEmpty) {
          throw ArgumentError(
            'No .env* files found in current directory and --env-file not specified',
          );
        }
        CliLogger.success('Found ${envFilePaths.length} .env file(s): ${envFilePaths.join(', ')}');
      } else {
        // Extract environment file paths from argument
        envFilePaths = envFileArg
            .split(',')
            .where((path) => path.trim().isNotEmpty)
            .map((path) => path.trim())
            .toList();

        if (envFilePaths.isEmpty) {
          throw ArgumentError('No environment files specified');
        }

        // Validate environment files exist
        CliLogger.debug('Validating environment files...');
        FileValidator.validateEnvFiles(envFilePaths);
        CliLogger.success('Validated ${envFilePaths.length} environment file(s)');
      }

      final outputDirArg = argResults!['output-dir'] as String;

      final envBuilder = env_builder_cli.EnvBuilderCli();
      final dartFileGenerator = DartFileGenerator(envBuilder);
      final packageConfigurator = PackageConfigurator(envBuilder);

      // Setup directories
      CliLogger.step('Setting up package directories...');
      final currentDir = Directory.current.path;
      final envPackageDir = await DirectoryManager.getEnvPackageDirectory(
        currentDir,
        'packages/$outputDirArg',
        envBuilder,
      );

      TextTemplates.packageName = p.basename(envPackageDir.path);

      // Copy environment files
      CliLogger.step('Copying environment files...');
      await FileCopier.copyEnvFiles(envFilePaths, envPackageDir);

      // Create source directory
      CliLogger.debug('Creating source directory structure...');
      final srcDirPath = p.join(
        envPackageDir.path,
        CliConfig.libFolderName,
        CliConfig.srcFolderName,
      );
      DirectoryManager.ensureDirectoryExists(srcDirPath);
      final srcDir = Directory(srcDirPath);

      // Generate Dart files
      CliLogger.step('Generating Dart files...');
      await dartFileGenerator.generateEnvDartFiles(envFilePaths, srcDir);
      dartFileGenerator.generateEnumsFile(envFilePaths.first, srcDir);
      dartFileGenerator.generateLibraryExportFile(envFilePaths, envPackageDir);
      dartFileGenerator.generateAppFlavorFile(envFilePaths, srcDir);

      // Configure package
      CliLogger.step('Configuring package...');
      await packageConfigurator.configureEnvPackage(envPackageDir);
      packageConfigurator.updateRootPubspec(currentDir);
      await packageConfigurator.runPubGet();

      // Run flutter pub get in env package to resolve dependencies
      await _runPubGetInEnvPackage(envPackageDir.path);

      // Run build_runner build in the env package
      await _runBuildRunner(envPackageDir.path);

      final noEncrypt = argResults!['no-encrypt'] as bool;
      if (!noEncrypt) {
        await _wantToEncryptEnvFile(envFilePaths.length);
      } else {
        // Show warning about plain text .env files if encryption is skipped
        if (envFilePaths.isNotEmpty) {
          CliLogger.warning(
            'Skipping encryption. Consider removing plain .env files before deployment for security.',
          );
        }
      }

      // Success message
      CliLogger.success(TextTemplates.successMessage);
      CliLogger.info(TextTemplates.successImport);
      print(TextTemplates.successPackage);

      return 0; // Exit success code
    } catch (e) {
      _handleError(e);
      return 64; // Exit usage code
    }
  }

  void _handleError(dynamic error) {
    if (error is ArgumentError) {
      CliLogger.error(error.message);
      CliLogger.info('Use --env-file=<file1>,<file2>,... to specify environment files');
    } else if (error is FileSystemException) {
      CliLogger.error('File system error: ${error.message}');
    } else if (error is ProcessException) {
      CliLogger.error('Process error: ${error.message}');
    } else {
      CliLogger.error('Unexpected error: ${error.toString()}');
    }
  }

  Future<void> _runPubGetInEnvPackage(String envPackagePath) async {
    CliLogger.progress('Running flutter pub get in env package...');

    final pubGetResult = await ProcessRunner.runFlutterCommand(
      ['pub', 'get'],
      path: envPackagePath,
    );

    if (pubGetResult.exitCode == 0) {
      CliLogger.done('flutter pub get succeeded in env package');
    } else {
      CliLogger.error('flutter pub get failed in env package');
      stderr.write(pubGetResult.stderr);
      throw ProcessException(
        'flutter',
        ['pub', 'get'],
        'flutter pub get failed in env package',
        pubGetResult.exitCode,
      );
    }
  }

  Future<void> _runBuildRunner(String envPackagePath) async {
    CliLogger.progress('Running dart run build_runner build in env package...');

    try {
      final result = await ProcessRunner.runDartCommand([
        'run',
        'build_runner',
        'build',
      ], envPackagePath);

      if (result.exitCode == 0) {
        CliLogger.done('build_runner build succeeded in env package');
      } else {
        CliLogger.error('build_runner build failed');
        stderr.write(result.stderr);
        throw ProcessException(
          'dart',
          ['run', 'build_runner', 'build'],
          'build_runner build failed',
          result.exitCode,
        );
      }
    } catch (e) {
      CliLogger.error('Error running build_runner: $e');
      rethrow;
    }
  }

  Future<void> _wantToEncryptEnvFile(int envFilesLength) async {
    if (envFilesLength > 0) {
      print(TextTemplates.wantToEncryptPrompt);
      try {
        final response = stdin.readLineSync();
        final re = response != null && response.toLowerCase() == 'y';

        if (re) {
          final password = EnvCrypto.askPassword(TextTemplates.enterSecretKey);
          print(TextTemplates.encryptingFiles);
          for (final file in FileCopier.envFiles) {
            final output = '$file.encrypted';
            await EnvCrypto.encryptFile(file, output, password);
          }
          for (final path in FileCopier.envFiles) {
            File(path).deleteSync();
          }
          print(TextTemplates.removeFiles);
        } else {
          print(TextTemplates.skippingEncryption);
          print(TextTemplates.rememberNoPlainEnv);
        }
      } catch (e) {
        print(
          TextTemplates.errorInputRead.replaceAll('{message}', e.toString()),
        );
      }
    }
  }

  /// Finds all .env* files in the given directory
  List<String> _findEnvFilesInDirectory(Directory directory) {
    final envFiles = <String>[];
    final entities = directory.listSync(recursive: false);

    for (final entity in entities) {
      if (entity is File) {
        final fileName = p.basename(entity.path);
        if (fileName.startsWith('.env')) {
          envFiles.add(entity.path);
        }
      }
    }

    // Sort the files to have consistent ordering
    envFiles.sort();
    return envFiles;
  }
}
