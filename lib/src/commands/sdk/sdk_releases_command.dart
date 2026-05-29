import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:http/http.dart' as http;
import 'package:mason_logger/mason_logger.dart';

import '../../utils/sdk_helper.dart';

/// Lists available Flutter SDK releases from the official Google Storage API.
class SdkReleasesCommand extends Command<int> {
  SdkReleasesCommand({required Logger logger}) : _logger = logger {
    argParser
      ..addOption(
        'channel',
        abbr: 'c',
        help: 'Filter releases by channel.',
        allowed: ['stable', 'beta', 'dev'],
        allowedHelp: {
          'stable': 'Stable channel',
          'beta': 'Beta channel',
          'dev': 'Dev channel',
        },
      )
      ..addOption(
        'limit',
        abbr: 'n',
        help: 'Maximum number of releases to show.',
        defaultsTo: '20',
      );
  }

  final Logger _logger;

  @override
  String get name => 'releases';

  @override
  String get description => 'List available Flutter SDK releases.';

  @override
  String get invocation => 'relax sdk releases [--channel <channel>] [--limit <n>]';

  @override
  Future<int> run() async {
    final channel = argResults?['channel'] as String?;
    final limitStr = argResults?['limit'] as String? ?? '20';
    final limit = int.tryParse(limitStr) ?? 20;

    final progress = _logger.progress('Fetching releases...');
    try {
      final response = await http.get(Uri.parse(releasesUrl));
      if (response.statusCode != 200) {
        progress.fail('Failed to fetch releases (HTTP ${response.statusCode}).');
        return ExitCode.software.code;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final allReleases = (json['releases'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      final filtered = channel != null
          ? allReleases.where((r) => r['channel'] == channel).toList()
          : allReleases;

      final releases = filtered.take(limit).toList();

      progress.complete('Found ${filtered.length} release(s).');
      _logger.info('');

      if (releases.isEmpty) {
        _logger.warn('No releases found for the given filter.');
        return ExitCode.success.code;
      }

      // Header
      _logger.info(
        '  ${_col("Version", 20)}${_col("Channel", 10)}${_col("Dart SDK", 14)}Release date',
      );
      _logger.info('  ${"─" * 68}');

      for (final r in releases) {
        final v = (r['version'] as String?) ?? '—';
        final ch = (r['channel'] as String?) ?? '—';
        final dart = (r['dart_sdk_version'] as String?) ?? '—';
        final date = _formatDate((r['release_date'] as String?) ?? '');
        final vColored = ch == 'stable'
            ? green.wrap(v)!
            : ch == 'beta'
                ? yellow.wrap(v)!
                : lightCyan.wrap(v)!;
        _logger.info('  ${_col(vColored, 20 + _ansiPad(vColored, v))}${_col(ch, 10)}${_col(dart, 14)}$date');
      }

      _logger.info('');
      if (filtered.length > limit) {
        _logger.info(
          darkGray.wrap(
            'Showing $limit of ${filtered.length} releases. Use --limit to see more.',
          ) ?? '',
        );
        _logger.info('');
      }

      return ExitCode.success.code;
    } on http.ClientException catch (e) {
      progress.fail('Network error: ${e.message}');
      return ExitCode.unavailable.code;
    } catch (e) {
      progress.fail('Unexpected error: $e');
      return ExitCode.software.code;
    }
  }

  String _col(String text, int width) =>
      text.padRight(width);

  /// Extra padding to compensate for ANSI escape codes in coloured strings.
  int _ansiPad(String coloured, String plain) =>
      coloured.length - plain.length;

  String _formatDate(String iso) {
    if (iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso.substring(0, iso.length.clamp(0, 10));
    }
  }
}
