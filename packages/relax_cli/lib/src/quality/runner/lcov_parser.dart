import 'dart:convert';

/// Line-coverage counts for a single source file.
class FileCoverage {
  const FileCoverage({required this.covered, required this.total});

  final int covered;
  final int total;

  double get percent => total == 0 ? 0 : covered / total * 100;
}

/// Parses the standard LCOV tracefile format (`coverage/lcov.info`).
///
/// Only the records needed for line coverage are read:
/// - `SF:<path>` starts a file record,
/// - `DA:<line>,<hits>` is a line with an execution count,
/// - `end_of_record` closes it.
///
/// `covered`/`total` are derived by counting `DA` lines (hits > 0 vs. all),
/// which is more reliable than the summary `LH:`/`LF:` records.
class LcovParser {
  Map<String, FileCoverage> parse(String content) {
    final result = <String, FileCoverage>{};

    String? currentPath;
    var covered = 0;
    var total = 0;

    void flush() {
      if (currentPath != null) {
        final existing = result[currentPath];
        result[currentPath!] = existing == null
            ? FileCoverage(covered: covered, total: total)
            : FileCoverage(
                covered: existing.covered + covered,
                total: existing.total + total,
              );
      }
      currentPath = null;
      covered = 0;
      total = 0;
    }

    for (final raw in const LineSplitter().convert(content)) {
      final line = raw.trim();
      if (line.startsWith('SF:')) {
        flush();
        currentPath = _normalize(line.substring(3));
      } else if (line.startsWith('DA:')) {
        final comma = line.indexOf(',');
        if (comma == -1) continue;
        final hits = int.tryParse(line.substring(comma + 1).trim());
        if (hits == null) continue;
        total++;
        if (hits > 0) covered++;
      } else if (line == 'end_of_record') {
        flush();
      }
    }
    flush();

    return result;
  }

  String _normalize(String path) => path.replaceAll(r'\', '/');
}
