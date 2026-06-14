import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../utils/sdk_helper.dart';

/// Downloads and installs a Flutter SDK version into the local cache.
class SdkInstallCommand extends Command<int> {
  SdkInstallCommand({required Logger logger}) : _logger = logger {
    argParser
      ..addFlag(
        'force',
        abbr: 'f',
        negatable: false,
        help: 'Re-install even if the version already exists.',
      )
      ..addFlag(
        'skip-pub',
        negatable: false,
        help: 'Skip running flutter pub get after installation.',
      );
  }

  final Logger _logger;

  @override
  String get name => 'install';

  @override
  String get description => 'Install a Flutter SDK version.';

  @override
  String get invocation => 'relax sdk install <version>';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) {
      _logger.err('Missing version argument.');
      _logger.info('Usage: ${lightCyan.wrap(invocation)}');
      return ExitCode.usage.code;
    }

    final version = rest.first;
    final force = argResults!['force'] as bool;
    final skipPub = argResults!['skip-pub'] as bool;

    return installSdk(
      version: version,
      force: force,
      skipPub: skipPub,
      logger: _logger,
    );
  }
}

/// Shared install logic used by both [SdkInstallCommand] and [SdkUseCommand].
Future<int> installSdk({
  required String version,
  required Logger logger,
  bool force = false,
  bool skipPub = false,
}) async {
  // Resolve partial versions (e.g. "3.41" → "3.41.9") before doing anything.
  var resolvedVersion = version;
  if (!isCompleteVersion(version)) {
    final resolveProgress = logger.progress(
      'Resolving ${lightCyan.wrap(version)}...',
    );
    final resolved = await resolvePartialVersion(version);
    if (resolved == null) {
      resolveProgress.fail('Could not resolve version "${lightCyan.wrap(version)}".');
      logger.err(
        'No Flutter release found matching "$version".',
      );
      logger.info(
        'Use a full version (e.g. ${lightCyan.wrap("3.41.9")}) or a channel '
        '(${lightCyan.wrap("stable")}, ${lightCyan.wrap("beta")}).',
      );
      logger.info(
        'Run ${lightCyan.wrap("relax sdk releases")} to browse available versions.',
      );
      return ExitCode.usage.code;
    }
    resolveProgress.complete(
      'Resolved ${lightCyan.wrap(version)} → ${lightCyan.wrap(resolved)}',
    );
    resolvedVersion = resolved;
  }

  if (isSdkInstalled(resolvedVersion) && !force) {
    logger.info(
      'Flutter ${lightCyan.wrap(resolvedVersion)} is already installed. '
      'Use ${lightCyan.wrap("--force")} to re-install.',
    );
    return ExitCode.success.code;
  }

  if (isSdkInstalled(resolvedVersion) && force) {
    final dir = Directory(sdkCachePath(resolvedVersion));
    logger.info('Removing existing installation of ${lightCyan.wrap(resolvedVersion)}...');
    dir.deleteSync(recursive: true);
  }

  final cloneProgress = logger.progress(
    'Cloning Flutter ${lightCyan.wrap(resolvedVersion)} (this may take a while)...',
  );

  try {
    final result = await gitCloneFlutter(resolvedVersion);
    if (result.exitCode != 0) {
      cloneProgress.fail('Git clone failed (exit ${result.exitCode}).');
      final stderr = result.stderr.toString().trim();
      if (stderr.isNotEmpty) logger.err(stderr);
      return ExitCode.software.code;
    }
    cloneProgress.complete(
      'Flutter ${lightCyan.wrap(resolvedVersion)} installed → ${lightCyan.wrap(sdkCachePath(resolvedVersion))}',
    );
  } on ProcessException catch (e) {
    cloneProgress.fail('Could not run git.');
    logger.err(e.message);
    return ExitCode.unavailable.code;
  }

  if (!skipPub) {
    final pubProgress = logger.progress('Running flutter pub get (SDK bootstrap)...');
    try {
      final binary = sdkCachePath(resolvedVersion) +
          (Platform.isWindows ? r'\bin\flutter.bat' : '/bin/flutter');
      final result = await Process.run(
        binary,
        ['--no-version-check', 'pub', 'get'],
        workingDirectory: sdkCachePath(resolvedVersion),
        runInShell: true,
      );
      if (result.exitCode == 0) {
        pubProgress.complete('SDK bootstrap complete.');
      } else {
        pubProgress.fail('SDK bootstrap failed (non-fatal).');
      }
    } on ProcessException {
      pubProgress.fail('Could not run flutter bootstrap (non-fatal).');
    }
  }

  logger.info('');
  logger.success('Flutter ${lightCyan.wrap(resolvedVersion)} ready.');
  logger.info('');
  return ExitCode.success.code;
}
