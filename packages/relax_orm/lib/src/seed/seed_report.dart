/// Outcome of a single seeder inside a [SeedReport].
enum SeedStatus {
  /// The seeder ran and its rows were committed.
  applied,

  /// The seeder was skipped because the ledger says it already ran.
  skipped,

  /// The seeder threw; its transaction was rolled back.
  failed,
}

/// Result of running one [Seeder].
class SeedResult {
  const SeedResult({
    required this.name,
    required this.status,
    required this.duration,
    this.rows = 0,
    this.error,
    this.stackTrace,
  });

  /// The seeder's [Seeder.name].
  final String name;

  /// What happened.
  final SeedStatus status;

  /// How long the seeder took.
  final Duration duration;

  /// Rows added across the seeder's declared tables (0 when it declares none).
  final int rows;

  /// The thrown error, when [status] is [SeedStatus.failed].
  final Object? error;

  /// Stack trace that goes with [error].
  final StackTrace? stackTrace;

  @override
  String toString() {
    switch (status) {
      case SeedStatus.applied:
        return '$name — applied ($rows row(s), ${duration.inMilliseconds}ms)';
      case SeedStatus.skipped:
        return '$name — skipped (already applied)';
      case SeedStatus.failed:
        return '$name — FAILED: $error';
    }
  }
}

/// Summary of a [SeedRunner] run.
class SeedReport {
  const SeedReport({required this.results, required this.duration});

  /// One entry per seeder that was considered, in execution order.
  final List<SeedResult> results;

  /// Total wall time of the run.
  final Duration duration;

  /// Seeders that actually ran.
  List<SeedResult> get applied =>
      results.where((r) => r.status == SeedStatus.applied).toList();

  /// Seeders skipped because they had already been applied.
  List<SeedResult> get skipped =>
      results.where((r) => r.status == SeedStatus.skipped).toList();

  /// Seeders that threw.
  List<SeedResult> get failed =>
      results.where((r) => r.status == SeedStatus.failed).toList();

  /// Total rows written by this run.
  int get rows => applied.fold(0, (sum, r) => sum + r.rows);

  /// Whether any seeder failed.
  bool get hasFailures => failed.isNotEmpty;

  /// Rethrows the first failure, if any.
  ///
  /// Handy in tests and CI: `(await db.seeds.run()).throwIfFailed();`
  void throwIfFailed() {
    if (!hasFailures) return;
    final first = failed.first;
    Error.throwWithStackTrace(
      StateError('Seeder "${first.name}" failed: ${first.error}'),
      first.stackTrace ?? StackTrace.current,
    );
  }

  @override
  String toString() {
    final lines = <String>[
      'Seed run — ${applied.length} applied, ${skipped.length} skipped, '
          '${failed.length} failed, $rows row(s) in ${duration.inMilliseconds}ms',
      ...results.map((r) => '  • $r'),
    ];
    return lines.join('\n');
  }
}
