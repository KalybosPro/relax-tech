import '../analyzer/file_analyzer.dart';
import '../models/quality_models.dart';
import 'lcov_parser.dart';

/// Result of aggregating raw LCOV data against the analyzed project.
class CoverageAggregation {
  const CoverageAggregation({required this.report, required this.heatmap});

  final CoverageReport report;

  /// feature/module → coverage percentage, for the dashboard heatmap.
  final Map<String, num> heatmap;
}

/// Crosses per-file LCOV coverage with each file's architectural layer (from
/// the analyzer) and its feature (folder under `lib/features/`) to produce the
/// aggregated [CoverageReport] and the heatmap.
class CoverageAggregator {
  CoverageAggregation aggregate({
    required Map<String, FileCoverage> lcov,
    required List<AnalyzedFile> analyzedFiles,
  }) {
    final layerByPath = <String, ArchLayer>{
      for (final f in analyzedFiles) f.relPath: f.info.layer,
    };

    final byLayer = <ArchLayer, _Counter>{};
    final byFeature = <String, _Counter>{};
    final byFile = <String, ({int covered, int total})>{};
    var totalCovered = 0;
    var totalLines = 0;

    lcov.forEach((path, cov) {
      final rel = _relative(path);
      byFile[rel] = (covered: cov.covered, total: cov.total);
      totalCovered += cov.covered;
      totalLines += cov.total;

      final layer = layerByPath[rel] ?? ArchLayer.unknown;
      (byLayer[layer] ??= _Counter()).add(cov);

      final feature = featureOf(rel);
      (byFeature[feature] ??= _Counter()).add(cov);
    });

    final overall = totalLines == 0 ? 0 : totalCovered / totalLines * 100;

    final report = CoverageReport(
      overall: _round(overall),
      byLayer: {
        for (final e in byLayer.entries) e.key.id: _round(e.value.percent),
      },
      byFeature: {
        for (final e in byFeature.entries) e.key: _round(e.value.percent),
      },
      byFile: byFile,
    );

    return CoverageAggregation(
      report: report,
      heatmap: {
        for (final e in byFeature.entries) e.key: _round(e.value.percent),
      },
    );
  }

  /// Feature/module for a source path:
  /// - `lib/features/<x>/…` or `lib/modules/<x>/…` → `<x>`
  /// - otherwise the first segment under `lib/` (e.g. `core`)
  /// - `unknown` when it can't be determined.
  static String featureOf(String relPath) {
    final parts = _relative(relPath).split('/');
    final libIndex = parts.indexOf('lib');
    if (libIndex == -1 || libIndex + 1 >= parts.length) return 'unknown';
    final afterLib = parts.sublist(libIndex + 1);
    if ((afterLib.first == 'features' || afterLib.first == 'modules') &&
        afterLib.length > 1) {
      return afterLib[1];
    }
    return afterLib.length > 1 ? afterLib.first : 'unknown';
  }

  static String _relative(String path) {
    var p = path.replaceAll(r'\', '/');
    if (p.startsWith('./')) p = p.substring(2);
    final idx = p.indexOf('/lib/');
    if (idx != -1) p = p.substring(idx + 1);
    return p;
  }

  num _round(num v) => (v * 10).round() / 10;
}

class _Counter {
  int covered = 0;
  int total = 0;

  void add(FileCoverage c) {
    covered += c.covered;
    total += c.total;
  }

  double get percent => total == 0 ? 0 : covered / total * 100;
}
