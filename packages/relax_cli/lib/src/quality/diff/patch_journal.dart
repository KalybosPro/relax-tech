import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// A proposed new file (Phase 4 only creates files; it never rewrites source).
typedef ProposedFile = ({String relPath, String content});

/// Builds unified diffs for proposed changes and journals them under
/// `.relax/quality/patches/<timestamp>/` so any applied change is reversible.
class PatchJournal {
  PatchJournal({required this.projectRoot});

  final String projectRoot;

  /// Builds a unified diff for a new file (all additions).
  static String newFileDiff(ProposedFile file) {
    final buffer = StringBuffer()
      ..writeln('--- /dev/null')
      ..writeln('+++ ${file.relPath}');
    final lines = const LineSplitter().convert(file.content);
    buffer.writeln('@@ -0,0 +1,${lines.length} @@');
    for (final line in lines) {
      buffer.writeln('+$line');
    }
    return buffer.toString();
  }

  /// Concatenates the unified diff for all [files].
  static String buildDiff(List<ProposedFile> files) =>
      files.map(newFileDiff).join('\n');

  /// Writes the full patch (per-file copies + a combined `.diff` + a manifest)
  /// under `.relax/quality/patches/<timestamp>/` and returns that directory's
  /// path (relative to the project root). Does not modify the working tree.
  String journal(List<ProposedFile> files, {String action = 'generate'}) {
    final timestamp = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final relDir = '.relax/quality/patches/$timestamp';
    final dir = Directory(p.join(projectRoot, relDir))
      ..createSync(recursive: true);

    // Snapshot each proposed file's content.
    for (final file in files) {
      final dest = File(p.join(dir.path, 'files', file.relPath))
        ..parent.createSync(recursive: true);
      dest.writeAsStringSync(file.content);
    }

    File(p.join(dir.path, 'changes.diff')).writeAsStringSync(buildDiff(files));
    File(p.join(dir.path, 'manifest.json')).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'action': action,
        'generatedAt': DateTime.now().toUtc().toIso8601String(),
        'files': files.map((f) => f.relPath).toList(),
      }),
    );

    _ensureGitignore();
    return relDir;
  }

  /// Adds `.relax/` to `.gitignore` if a gitignore exists and doesn't list it.
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
