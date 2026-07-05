import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../utils/flutter_helper.dart';

/// Formats code then builds an optimized release AAB (Android App Bundle).
///
/// Optimization flags applied:
/// - `--obfuscate` + `--split-debug-info` — reduces binary size
/// - `--tree-shake-icons` — removes unused icon glyphs
///
/// Note: `--split-per-abi` is intentionally omitted — AABs are always
/// universal; Google Play handles per-ABI splitting server-side.
class BuildAabCommand extends Command<int> {
  BuildAabCommand({required Logger logger}) : _logger = logger {
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
  String get name => 'aab';

  @override
  String get description =>
      'Build a release AAB (format + obfuscate, Google Play optimized).';

  @override
  String get invocation => 'relax build aab [--flavor <flavor>] [-t <file>]';

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

    // ── Step 2: build AAB ────────────────────────────────────────────────────
    _logger.info('');
    _logger.info(
      'Building release AAB '
      '(flavor: ${lightCyan.wrap(flavor)}, target: ${lightCyan.wrap(target)})...',
    );
    _logger.info('');

    final buildProgress = _logger.progress(
      'Running flutter build appbundle...',
    );
    try {
      final result = await runFlutter([
        'build',
        'appbundle',
        '--release',
        '--flavor',
        flavor,
        '-t',
        target,
        '--obfuscate',
        '--split-debug-info=.debug-info/',
        '--tree-shake-icons',
      ]);
      if (result.exitCode == 0) {
        buildProgress.complete('AAB built successfully.');
        _logger.info('');
        _logger.success(
          'Release AAB → ${lightCyan.wrap('build/app/outputs/bundle/${flavor}Release/')}',
        );
        _logger.info('');
        return ExitCode.success.code;
      }
      buildProgress.fail(
        'flutter build appbundle failed (exit ${result.exitCode}).',
      );
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
