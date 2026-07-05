import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'history_entry.dart';

/// Persists the quality-run history as an append-only JSONL file at
/// `.relax/quality/history.jsonl`.
///
/// JSONL (one JSON object per line) is chosen over an embedded SQLite database
/// to keep the CLI free of native binaries that vary by platform — the spec's
/// documented fallback. The store is the single source of truth for
/// history/trend data; the dashboard and CI reporter read from it and never
/// recompute a persisted run.
class QualityStore {
  QualityStore({required this.projectRoot, this.retention = 90});

  final String projectRoot;

  /// Maximum number of runs to keep; older runs are dropped on write.
  final int retention;

  String get _path => p.join(projectRoot, '.relax', 'quality', 'history.jsonl');

  /// Loads all persisted entries, oldest first. Malformed lines are skipped.
  List<HistoryEntry> load() {
    final file = File(_path);
    if (!file.existsSync()) return const [];
    final entries = <HistoryEntry>[];
    for (final line in file.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, Object?>) {
          final entry = HistoryEntry.fromJson(decoded);
          if (entry != null) entries.add(entry);
        }
      } on FormatException {
        // Skip a corrupt line rather than failing the whole run.
      }
    }
    return entries;
  }

  /// The most recent entry, or `null` when there is no history.
  HistoryEntry? latest() {
    final all = load();
    return all.isEmpty ? null : all.last;
  }

  /// Appends [entry], enforcing [retention] (keeps the most recent N).
  void record(HistoryEntry entry) {
    final all = [...load(), entry];
    final trimmed = all.length > retention
        ? all.sublist(all.length - retention)
        : all;

    final file = File(_path)..parent.createSync(recursive: true);
    final buffer = StringBuffer();
    for (final e in trimmed) {
      buffer.writeln(jsonEncode(e.toJson()));
    }
    file.writeAsStringSync(buffer.toString());
    _ensureGitignore();
  }

  void _ensureGitignore() {
    final file = File(p.join(projectRoot, '.gitignore'));
    if (!file.existsSync()) return;
    final lines = file.readAsLinesSync();
    if (lines.any((l) => l.trim() == '.relax/' || l.trim() == '.relax')) return;
    file.writeAsStringSync(
      '${file.readAsStringSync().trimRight()}\n\n# relax quality artifacts\n.relax/\n',
    );
  }
}

/// Returns the current git commit SHA for [projectRoot], or `null` when the
/// directory is not a git repository or git is unavailable.
String? currentGitSha(String projectRoot) {
  try {
    final result = Process.runSync(
      'git',
      ['rev-parse', 'HEAD'],
      workingDirectory: projectRoot,
      runInShell: true,
    );
    if (result.exitCode != 0) return null;
    final sha = '${result.stdout}'.trim();
    return sha.isEmpty ? null : sha;
  } on ProcessException {
    return null;
  }
}

/// A short, sortable run id.
String newRunId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);
