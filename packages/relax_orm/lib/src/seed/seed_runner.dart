import '../core/relax_db.dart';
import '../database/relax_database.dart';
import '../logging/relax_logger.dart';
import 'seed_report.dart';
import 'seeder.dart';

/// Runs [Seeder]s against a [RelaxDB], exactly once each.
///
/// Every applied seeder is recorded in the `_relax_seeds` ledger table, so
/// calling [run] again on an already-seeded database is a no-op. That makes it
/// safe to call on every app start.
///
/// ```dart
/// final db = await RelaxDB.open(name: 'app', schemas: [userSchema, postSchema]);
///
/// db.seeds.registerAll([UserSeeder(), PostSeeder(count: 50)]);
///
/// final report = await db.seeds.run();
/// print(report); // Seed run — 2 applied, 0 skipped, 0 failed, 60 row(s)
/// ```
///
/// During development, [fresh] wipes the seeded tables and re-runs everything.
class SeedRunner {
  SeedRunner(this._db, this._database);

  /// Name of the ledger table tracking which seeders have been applied.
  static const String ledgerTable = '_relax_seeds';

  final RelaxDB _db;
  final RelaxDatabase _database;
  final List<Seeder> _seeders = [];

  bool _ledgerReady = false;

  RelaxLogger get _logger => _database.logger;

  /// The registered seeders, in execution order (by [Seeder.order], then
  /// registration order).
  List<Seeder> get seeders => _ordered();

  /// Registers a seeder. Registering the same [Seeder.name] twice throws.
  void register(Seeder seeder) {
    if (_seeders.any((s) => s.name == seeder.name)) {
      throw StateError(
        'A seeder named "${seeder.name}" is already registered.',
      );
    }
    _seeders.add(seeder);
  }

  /// Registers several seeders at once.
  void registerAll(Iterable<Seeder> seeders) {
    for (final seeder in seeders) {
      register(seeder);
    }
  }

  /// Removes every registered seeder (the ledger is untouched).
  void clear() => _seeders.clear();

  /// Runs the pending seeders.
  ///
  /// - [only]: restrict the run to these seeder names.
  /// - [force]: run even seeders the ledger already recorded.
  /// - [continueOnError]: keep going after a failing seeder instead of
  ///   stopping at the first one. Failures are always reported in the returned
  ///   [SeedReport] rather than thrown — call [SeedReport.throwIfFailed] if
  ///   you want them to surface as exceptions.
  Future<SeedReport> run({
    Iterable<String>? only,
    bool force = false,
    bool continueOnError = false,
  }) async {
    await _ensureLedger();

    final selected = _select(only);
    final alreadyApplied = force ? const <String>{} : await appliedNames();
    final results = <SeedResult>[];
    final total = Stopwatch()..start();

    for (final seeder in selected) {
      if (alreadyApplied.contains(seeder.name)) {
        results.add(
          SeedResult(
            name: seeder.name,
            status: SeedStatus.skipped,
            duration: Duration.zero,
          ),
        );
        continue;
      }

      final watch = Stopwatch()..start();
      try {
        final before = await _countRows(seeder.tables);
        // One transaction per seeder: a throwing seeder leaves no partial rows
        // behind and no ledger entry, so the next run retries it cleanly.
        await _database.transaction(() async {
          await seeder.run(_db);
          await _record(seeder.name);
        });
        final after = await _countRows(seeder.tables);
        watch.stop();

        results.add(
          SeedResult(
            name: seeder.name,
            status: SeedStatus.applied,
            duration: watch.elapsed,
            rows: after - before,
          ),
        );
        _logger.log(
          RelaxLogCategory.database,
          'Seeder "${seeder.name}" applied (${after - before} row(s))',
          level: RelaxLogLevel.info,
        );
      } catch (error, stackTrace) {
        watch.stop();
        results.add(
          SeedResult(
            name: seeder.name,
            status: SeedStatus.failed,
            duration: watch.elapsed,
            error: error,
            stackTrace: stackTrace,
          ),
        );
        _logger.log(
          RelaxLogCategory.database,
          'Seeder "${seeder.name}" failed: $error',
          level: RelaxLogLevel.error,
          details: stackTrace,
        );
        if (!continueOnError) break;
      }
    }

    total.stop();
    return SeedReport(results: results, duration: total.elapsed);
  }

  /// Clears the seeded tables, forgets their ledger entries, then re-runs.
  ///
  /// Development helper — it deletes **all** rows of every table declared by
  /// the selected seeders ([Seeder.tables]), not just the previously seeded
  /// ones. Don't call it on a database holding real user data.
  Future<SeedReport> fresh({
    Iterable<String>? only,
    bool continueOnError = false,
  }) async {
    await _ensureLedger();

    final selected = _select(only);

    // Reverse order so dependents are cleared before their dependencies.
    final tables = <String>{};
    for (final seeder in selected.reversed) {
      tables.addAll(seeder.tables);
    }
    for (final table in tables) {
      await _database.rawDelete(table, where: '1 = 1', whereArgs: const []);
    }

    await forget(selected.map((s) => s.name));

    return run(only: only, force: true, continueOnError: continueOnError);
  }

  /// Names of the seeders recorded in the ledger.
  Future<Set<String>> appliedNames() async {
    await _ensureLedger();
    final rows = await _database.rawSelect(ledgerTable);
    return rows.map((row) => row['name'] as String).toSet();
  }

  /// Whether a seeder with this [name] has already been applied.
  Future<bool> hasRun(String name) async {
    return (await appliedNames()).contains(name);
  }

  /// Removes ledger entries so the matching seeders run again on the next
  /// [run]. Pass `null` to forget every seeder. Rows already inserted are
  /// **not** deleted — use [fresh] for that.
  Future<void> forget([Iterable<String>? names]) async {
    await _ensureLedger();
    if (names == null) {
      await _database.rawDelete(
        ledgerTable,
        where: '1 = 1',
        whereArgs: const [],
      );
      return;
    }
    for (final name in names) {
      await _database.rawDelete(
        ledgerTable,
        where: 'name = ?',
        whereArgs: [name],
      );
    }
  }

  // -- Private helpers --

  List<Seeder> _ordered() {
    final indexed = _seeders.indexed.toList()
      ..sort((a, b) {
        final byOrder = a.$2.order.compareTo(b.$2.order);
        return byOrder != 0 ? byOrder : a.$1.compareTo(b.$1);
      });
    return indexed.map((entry) => entry.$2).toList();
  }

  List<Seeder> _select(Iterable<String>? only) {
    final ordered = _ordered();
    if (only == null) return ordered;

    final wanted = only.toSet();
    final selected = ordered.where((s) => wanted.contains(s.name)).toList();
    final missing = wanted.difference(selected.map((s) => s.name).toSet());
    if (missing.isNotEmpty) {
      throw StateError(
        'No seeder registered named ${missing.map((n) => '"$n"').join(', ')}. '
        'Registered: ${ordered.map((s) => '"${s.name}"').join(', ')}.',
      );
    }
    return selected;
  }

  Future<void> _ensureLedger() async {
    if (_ledgerReady) return;
    await _database.createTable(
      'CREATE TABLE IF NOT EXISTS $ledgerTable ('
      'name TEXT PRIMARY KEY, '
      'applied_at INTEGER NOT NULL)',
    );
    _ledgerReady = true;
  }

  Future<void> _record(String name) async {
    // Replace, not insert: a `force: true` re-run has to overwrite the existing
    // ledger row rather than trip the primary key.
    await _database.rawInsert(ledgerTable, {
      'name': name,
      'applied_at': DateTime.now().millisecondsSinceEpoch,
    }, replace: true);
  }

  Future<int> _countRows(List<String> tables) async {
    var total = 0;
    for (final table in tables) {
      total += await _database.rawCount(table);
    }
    return total;
  }
}
