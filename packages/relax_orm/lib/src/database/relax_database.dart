import 'package:drift/drift.dart';

import '../logging/relax_logger.dart';

/// Internal Drift database used by RelaxORM.
///
/// This class is an implementation detail — it is never exposed to the developer.
/// It provides raw SQL access while benefiting from Drift's connection management,
/// isolate support, and SQLite3MultipleCiphers encryption.
class RelaxDatabase extends GeneratedDatabase {
  /// Opt-in developer logger shared by every RelaxORM collaborator. Defaults to
  /// a disabled (no-op) logger.
  final RelaxLogger logger;

  RelaxDatabase(super.executor, {this.logger = const RelaxLogger.disabled()});

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          // Table creation is handled by RelaxDB.open() via raw SQL,
          // so we don't use Drift's migration system.
        },
      );

  /// Executes a raw CREATE TABLE statement.
  Future<void> createTable(String sql) async {
    await customStatement(sql);
    logger.log(RelaxLogCategory.database, 'createTable',
        level: RelaxLogLevel.info, details: sql);
  }

  /// Inserts a row and returns the number of affected rows.
  Future<int> rawInsert(String table, Map<String, Object?> values) async {
    final columns = values.keys.join(', ');
    final placeholders = values.keys.map((_) => '?').join(', ');
    final sql = 'INSERT INTO $table ($columns) VALUES ($placeholders)';
    final affected = await customInsert(
      sql,
      variables: _toVariables(values.values),
      updates: {tableRef(table)},
    );
    logger.log(RelaxLogCategory.crud, 'INSERT $table ($affected row(s))',
        details: sql);
    return affected;
  }

  /// Updates rows matching a WHERE clause.
  Future<int> rawUpdate(
    String table,
    Map<String, Object?> values, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    final sets = values.keys.map((k) => '$k = ?').join(', ');
    final sql = 'UPDATE $table SET $sets WHERE $where';
    final allArgs = [...values.values, ...whereArgs];
    final affected = await customUpdate(
      sql,
      variables: _toVariables(allArgs),
      updates: {tableRef(table)},
    );
    logger.log(RelaxLogCategory.crud, 'UPDATE $table ($affected row(s))',
        details: sql);
    return affected;
  }

  /// Deletes rows matching a WHERE clause.
  Future<int> rawDelete(
    String table, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    final sql = 'DELETE FROM $table WHERE $where';
    final affected = await customUpdate(
      sql,
      variables: _toVariables(whereArgs),
      updates: {tableRef(table)},
    );
    logger.log(RelaxLogCategory.crud, 'DELETE $table ($affected row(s))',
        details: sql);
    return affected;
  }

  /// Selects all rows, optionally with a WHERE clause.
  Future<List<Map<String, dynamic>>> rawSelect(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    final buffer = StringBuffer('SELECT * FROM $table');
    if (where != null) buffer.write(' WHERE $where');
    if (orderBy != null) buffer.write(' ORDER BY $orderBy');

    final results = await customSelect(
      buffer.toString(),
      variables: _toVariables(whereArgs ?? []),
    ).get();

    logger.log(RelaxLogCategory.crud, 'SELECT $table (${results.length} row(s))',
        details: buffer.toString());
    return results.map((row) => row.data).toList();
  }

  /// Selects a single row by primary key, or null if not found.
  Future<Map<String, dynamic>?> rawSelectOne(
    String table, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    final sql = 'SELECT * FROM $table WHERE $where LIMIT 1';
    final results = await customSelect(
      sql,
      variables: _toVariables(whereArgs),
    ).get();

    logger.log(RelaxLogCategory.crud,
        'SELECT $table LIMIT 1 (${results.isEmpty ? 0 : 1} row(s))',
        details: sql);
    if (results.isEmpty) return null;
    return results.first.data;
  }

  /// Watches all rows in a table (returns a reactive stream).
  Stream<List<Map<String, dynamic>>> rawWatch(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    final buffer = StringBuffer('SELECT * FROM $table');
    if (where != null) buffer.write(' WHERE $where');

    return customSelect(
      buffer.toString(),
      variables: _toVariables(whereArgs ?? []),
      readsFrom: {tableRef(table)},
    ).watch().map((rows) => rows.map((row) => row.data).toList());
  }

  /// Watches a single row by primary key.
  Stream<Map<String, dynamic>?> rawWatchOne(
    String table, {
    required String where,
    required List<Object?> whereArgs,
  }) {
    final sql = 'SELECT * FROM $table WHERE $where LIMIT 1';
    return customSelect(
      sql,
      variables: _toVariables(whereArgs),
      readsFrom: {tableRef(table)},
    ).watch().map((rows) => rows.isEmpty ? null : rows.first.data);
  }

  /// Inserts multiple rows in a single batch.
  ///
  /// Raw `customStatement`s inside a [batch] don't tell Drift which table was
  /// written, so active `watch()` streams wouldn't be notified on their own.
  /// We therefore emit an explicit [TableUpdate] for [table] after the batch so
  /// that `watchAll()` / `watchOne()` listeners refresh (e.g. after a bulk
  /// `Collection.addAll` import).
  Future<void> rawBatchInsert(
    String table,
    List<Map<String, Object?>> rows,
  ) async {
    if (rows.isEmpty) return;
    await batch((b) {
      for (final row in rows) {
        final columns = row.keys.join(', ');
        final placeholders = row.keys.map((_) => '?').join(', ');
        final sql = 'INSERT INTO $table ($columns) VALUES ($placeholders)';
        b.customStatement(sql, [...row.values]);
      }
    });
    notifyUpdates({TableUpdate(table, kind: UpdateKind.insert)});
    logger.log(RelaxLogCategory.crud,
        'BATCH INSERT $table (${rows.length} row(s))');
  }

  /// Returns the number of rows in a table.
  Future<int> rawCount(String table) async {
    final results = await customSelect(
      'SELECT COUNT(*) as c FROM $table',
    ).get();
    final count = results.first.data['c'] as int;
    logger.log(RelaxLogCategory.crud, 'COUNT $table = $count');
    return count;
  }

  /// Creates a [ResultSetImplementation] reference for Drift's change tracking.
  ResultSetImplementation tableRef(String tableName) {
    return _RawTableReference(tableName);
  }

  List<Variable<Object>> _toVariables(Iterable<Object?> values) {
    return values.map((v) => Variable(v)).toList();
  }
}

/// A minimal table reference so Drift can track which tables are read/written
/// and notify stream watchers accordingly.
class _RawTableReference extends ResultSetImplementation<Table, dynamic> {
  @override
  final String entityName;

  _RawTableReference(this.entityName);

  @override
  String get aliasedName => entityName;

  @override
  Map<String, GeneratedColumn<Object>> get columnsByName => {};

  @override
  List<GeneratedColumn<Object>> get $columns => [];

  @override
  dynamic map(Map<String, dynamic> data, {String? tablePrefix}) => data;

  @override
  DatabaseConnectionUser get attachedDatabase =>
      throw UnsupportedError('Not needed for stream tracking');

  @override
  Table get asDslTable => throw UnsupportedError('Not needed for stream tracking');

  @override
  ResultSetImplementation<Table, dynamic> createAlias(String alias) => this;
}
