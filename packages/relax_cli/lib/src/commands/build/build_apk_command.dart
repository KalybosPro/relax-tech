import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../utils/flutter_helper.dart';

/// Formats code then builds an optimized release APK.
///
/// Optimization flags applied:
/// - `--obfuscate` + `--split-debug-info` — reduces binary size
/// - `--tree-shake-icons` — removes unused icon glyphs
/// - `--split-per-abi` — produces per-ABI APKs (~40–60% smaller than universal)
class BuildApkCommand extends Command<int> {
  BuildApkCommand({required Logger logger}) : _logger = logger {
    argParser
      ..addOption(
        'flavor',
        abbr: 'f',
        help: 'Build flavor.',
        allowed: ['development', 'staging', 'production'],
        allowedHelp: {
          'development': 'Development flavor',
          'staging': 'Staging flavor',
          'production': 'Production flavor (default)',
        },
        defaultsTo: 'production',
      )
      ..addOption(
        'target',
        abbr: 't',
        help:
            'Entry-point file (e.g. lib/main_staging.dart). '
            'Defaults to lib/main_<flavor>.dart.',
      );
  }

  final Logger _logger;

  @override
  String get name => 'apk';

  @override
  String get description =>
      'Build a release APK (format + obfuscate + split-per-abi).';

  @override
  String get invocation => 'relax build apk [--flavor <flavor>] [-t <file>]';

  @override
  Future<int> run() async {
    final guard = guardFlutterProject(_logger);
    if (guard != null) return guard;

    final flavor = argResults!['flavor'] as String;
    final target =
        (argResults?['target'] as String?) ?? 'lib/main_$flavor.dart';

    logFvmStatus(_logger);

    // ── Step 1: format code ──────────────────────────────────────────────────
    final fmt = await formatCode(_logger);
    if (fmt != null) return fmt;

    // ── Step 2: build APK ────────────────────────────────────────────────────
    _logger.info('');
    _logger.info(
      'Building release APK '
      '(flavor: ${lightCyan.wrap(flavor)}, target: ${lightCyan.wrap(target)})...',
    );
    _logger.info('');

    final buildProgress = _logger.progress('Running flutter build apk...');
    try {
      final result = await runFlutter([
        'build',
        'apk',
        '--release',
        '--flavor',
        flavor,
        '-t',
        target,
        '--obfuscate',
        '--split-debug-info=.debug-info/',
        '--tree-shake-icons',
        '--split-per-abi',
      ]);
      if (result.exitCode == 0) {
        buildProgress.complete('APK built successfully.');
        _logger.info('');
        _logger.success(
          'Release APKs → ${lightCyan.wrap('build/app/outputs/flutter-apk/')}',
        );
        _logger.info('');
        return ExitCode.success.code;
      }
      buildProgress.fail('flutter build apk failed (exit ${result.exitCode}).');
      final stderr = result.stderr.toString().trim();
      if (stderr.isNotEmpty) _logger.err(stderr);
      return ExitCode.software.code;
    } on ProcessException catch (e) {
      buildProgress.fail('Could not run flutter.');
      _logger.err(e.message);
      return ExitCode.unavailable.code;
    }
  }
}
