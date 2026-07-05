import '../analyzer/file_analyzer.dart';
import '../models/quality_models.dart';

/// Detects business functions that lack a corresponding test file.
///
/// For each detected business function, the expected test file is
/// `<snake_case_name>_test.dart`. A gap exists when no test file path ends with
/// that name. This is a read-only signal for `--check`; actual test generation
/// is out of scope for this phase.
class TestGapDetector {
  List<TestGap> detect({
    required List<AnalyzedFile> sourceFiles,
    required List<String> testFilePaths,
  }) {
    final normalizedTests = testFilePaths
        .map((p) => p.replaceAll(r'\', '/'))
        .toList();

    final gaps = <TestGap>[];
    final seen = <String>{};

    for (final file in sourceFiles) {
      if (file.info.isTest) continue;
      for (final fn in file.info.businessFunctions) {
        final expected = '${_toSnakeCase(fn.name)}_test.dart';
        // De-duplicate by function name + file so we don't report the same
        // logical gap many times.
        final key = '${fn.filePath}#${fn.name}';
        if (!seen.add(key)) continue;
        final exists = normalizedTests.any((t) => t.endsWith(expected));
        if (!exists) {
          gaps.add(
            TestGap(
              businessFunction: fn,
              expectedTestFile: expected,
              exists: false,
            ),
          );
        }
      }
    }
    return gaps;
  }

  String _toSnakeCase(String name) {
    final cleaned = name.startsWith('_') ? name.substring(1) : name;
    return cleaned
        .replaceAllMapped(
          RegExp('[A-Z]'),
          (m) => '_${m.group(0)!.toLowerCase()}',
        )
        .replaceAll(RegExp('^_'), '')
        .replaceAll(RegExp('_+'), '_');
  }
}
