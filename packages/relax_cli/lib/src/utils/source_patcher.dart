import 'dart:io';

/// The outcome of a [SourcePatcher] insertion.
enum PatchStatus {
  /// The snippet was inserted into the file.
  inserted,

  /// The snippet was already present (matched by its guard); nothing changed.
  skipped,

  /// The anchor line was not found; the file was left untouched.
  anchorMissing,

  /// The target file does not exist; nothing was done.
  fileMissing,
}

/// Result of a single [SourcePatcher] operation.
class PatchResult {
  const PatchResult(this.status);

  final PatchStatus status;

  bool get changed => status == PatchStatus.inserted;
}

/// Idempotent, anchor-based text insertion into an existing source file.
///
/// The CLI generates source files that contain marker comments (anchors) such
/// as `// relax:router-routes`. [SourcePatcher] inserts a [snippet] on the line
/// immediately *before* the anchor, preserving the anchor for future
/// insertions. A [guard] string makes the operation idempotent: if the guard is
/// already present anywhere in the file, the insertion is skipped.
///
/// This deliberately uses plain text manipulation rather than AST parsing —
/// the anchors are emitted by templates we control, so insertion is
/// deterministic without the weight of a full Dart parser.
abstract final class SourcePatcher {
  /// Inserts [snippet] on its own line just before the first line containing
  /// [anchor].
  ///
  /// - If [guard] is already present in the file, returns
  ///   [PatchStatus.skipped] (safe to call repeatedly).
  /// - If [anchor] is not found, returns [PatchStatus.anchorMissing] and leaves
  ///   the file untouched.
  /// - If [file] does not exist, returns [PatchStatus.fileMissing].
  ///
  /// [snippet] is inserted verbatim; include any desired indentation and a
  /// trailing newline is added automatically if missing.
  static PatchResult insertBeforeAnchor(
    File file, {
    required String anchor,
    required String snippet,
    required String guard,
  }) {
    if (!file.existsSync()) {
      return const PatchResult(PatchStatus.fileMissing);
    }

    final content = file.readAsStringSync();
    if (content.contains(guard)) {
      return const PatchResult(PatchStatus.skipped);
    }

    // Split into lines while remembering the original line terminator style.
    final newline = content.contains('\r\n') ? '\r\n' : '\n';
    final lines = content.split(RegExp('\r?\n'));

    final anchorIndex = lines.indexWhere((line) => line.contains(anchor));
    if (anchorIndex == -1) {
      return const PatchResult(PatchStatus.anchorMissing);
    }

    // Normalize the snippet: no trailing newline, we join with [newline].
    final snippetLines = snippet.replaceAll('\r\n', '\n').split('\n');
    while (snippetLines.isNotEmpty && snippetLines.last.isEmpty) {
      snippetLines.removeLast();
    }

    lines.insertAll(anchorIndex, snippetLines);
    file.writeAsStringSync(lines.join(newline));

    return const PatchResult(PatchStatus.inserted);
  }

  /// Like [insertBeforeAnchor] but inserts [snippet] on the line(s) immediately
  /// *after* the first line containing [anchor]. Useful for appending members
  /// right after a known declaration (e.g. after a constructor line).
  static PatchResult insertAfterAnchor(
    File file, {
    required String anchor,
    required String snippet,
    required String guard,
  }) {
    if (!file.existsSync()) {
      return const PatchResult(PatchStatus.fileMissing);
    }

    final content = file.readAsStringSync();
    if (content.contains(guard)) {
      return const PatchResult(PatchStatus.skipped);
    }

    final newline = content.contains('\r\n') ? '\r\n' : '\n';
    final lines = content.split(RegExp('\r?\n'));

    final anchorIndex = lines.indexWhere((line) => line.contains(anchor));
    if (anchorIndex == -1) {
      return const PatchResult(PatchStatus.anchorMissing);
    }

    final snippetLines = snippet.replaceAll('\r\n', '\n').split('\n');
    while (snippetLines.isNotEmpty && snippetLines.last.isEmpty) {
      snippetLines.removeLast();
    }

    lines.insertAll(anchorIndex + 1, snippetLines);
    file.writeAsStringSync(lines.join(newline));

    return const PatchResult(PatchStatus.inserted);
  }

  /// Replaces the first occurrence of [from] with [to] unless [guard] is
  /// already present (idempotent). Returns [PatchStatus.inserted] on a
  /// successful replacement, [PatchStatus.skipped] if the guard matched, and
  /// [PatchStatus.anchorMissing] if [from] was not found.
  static PatchResult replaceOnce(
    File file, {
    required String from,
    required String to,
    required String guard,
  }) {
    if (!file.existsSync()) {
      return const PatchResult(PatchStatus.fileMissing);
    }

    final content = file.readAsStringSync();
    if (content.contains(guard)) {
      return const PatchResult(PatchStatus.skipped);
    }
    if (!content.contains(from)) {
      return const PatchResult(PatchStatus.anchorMissing);
    }

    file.writeAsStringSync(content.replaceFirst(from, to));
    return const PatchResult(PatchStatus.inserted);
  }

  /// Appends [line] (with a trailing newline) to the end of [file] unless
  /// [guard] is already present (idempotent). Use for anchor-less files such as
  /// feature barrels where export order does not matter.
  static PatchResult ensureLine(
    File file, {
    required String line,
    required String guard,
  }) {
    if (!file.existsSync()) {
      return const PatchResult(PatchStatus.fileMissing);
    }

    final content = file.readAsStringSync();
    if (content.contains(guard)) {
      return const PatchResult(PatchStatus.skipped);
    }

    final newline = content.contains('\r\n') ? '\r\n' : '\n';
    final needsLeadingNewline =
        content.isNotEmpty &&
        !content.endsWith('\n') &&
        !content.endsWith('\r');
    file.writeAsStringSync(
      '$content${needsLeadingNewline ? newline : ''}$line$newline',
    );
    return const PatchResult(PatchStatus.inserted);
  }
}
