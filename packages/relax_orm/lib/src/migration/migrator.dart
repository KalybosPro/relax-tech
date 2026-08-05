import '../database/relax_database.dart';
import '../logging/relax_logger.dart';
import '../schema/column_def.dart';
import '../schema/table_schema.dart';

/// What an app does when its database is older than its code.
///
/// Handed to the `onUpgrade` callback of `RelaxDB.open`, with the version the
/// database is at and the one it should reach. It is the only place a schema
/// change that isn't purely additive can be described — adding a column needs
/// no migration at all, RelaxORM reconciles those on its own.
///
/// ```dart
/// await RelaxDB.open(
///   name: 'my_app',
///   schemas: [messageSchema],
///   version: 2,
///   onUpgrade: (m, from, to) async {
///     if (from < 2) await m.renameColumn('messages', from: 'body', to: 'text');
///   },
/// );
/// ```
///
/// Why this can't be inferred: given an old schema and a new one, a renamed
/// column and a dropped-then-added column look exactly alike. Whether the rows
/// should follow is a question only the author can answer, which is why the
/// steps are declared rather than derived.
typedef RelaxMigration =
    Future<void> Function(Migrator migrator, int from, int to);

/// The operations a migration can perform.
///
/// Created by `RelaxDB.open`; there is no reason to build one yourself.
class Migrator {
  Migrator(this._database);

  final RelaxDatabase _database;

  /// Runs a raw statement that returns no rows.
  Future<void> execute(String sql, [List<Object?> arguments = const []]) =>
      _database.customStatement(sql, arguments);

  /// Runs a raw query and returns its rows.
  Future<List<Map<String, Object?>>> select(
    String sql, [
    List<Object?> arguments = const [],
  ]) async {
    final rows = await _database
        .customSelect(sql, variables: _database.variablesOf(arguments))
        .get();

    return rows.map((row) => row.data).toList();
  }

  /// The columns [table] currently has, as SQLite reports them.
  Future<Set<String>> columnsOf(String table) async {
    final rows = await select('PRAGMA table_info($table)');
    return {for (final row in rows) row['name'] as String};
  }

  /// Appends [column] to [table].
  ///
  /// Throws a [StateError] when SQLite cannot append it — see
  /// [ColumnDef.isAddable]. A `NOT NULL` column needs a `defaultValue`, since
  /// the rows already in the table must be given something.
  Future<void> addColumn(String table, ColumnDef column) async {
    if (!column.isAddable) {
      throw StateError(_cannotAdd(table, column));
    }

    await execute('ALTER TABLE $table ADD COLUMN ${column.definition}');
    _database.logger.log(
      RelaxLogCategory.database,
      'ADD COLUMN $table.${column.name}',
      level: RelaxLogLevel.info,
    );
  }

  /// Renames a column, keeping its rows.
  ///
  /// Needs SQLite 3.25 or newer, which every platform RelaxORM supports ships.
  Future<void> renameColumn(
    String table, {
    required String from,
    required String to,
  }) async {
    await execute('ALTER TABLE $table RENAME COLUMN $from TO $to');
    _database.logger.log(
      RelaxLogCategory.database,
      'RENAME COLUMN $table.$from → $to',
      level: RelaxLogLevel.info,
    );
  }

  /// Rebuilds [schema]'s table into its current shape, carrying the rows over.
  ///
  /// This is the escape hatch for everything SQLite cannot alter in place: a
  /// column that changes type, loses `NOT NULL`, joins the primary key, or goes
  /// away. It follows the procedure the SQLite documentation prescribes —
  /// create the new table beside the old one, copy, drop, rename — inside a
  /// single transaction, so a failure leaves the old table untouched.
  ///
  /// Each new column is filled from the old table by the same name. [from]
  /// overrides that for the columns where it doesn't hold, mapping a **new**
  /// column name to any SQL expression over the **old** table:
  ///
  /// ```dart
  /// await m.rebuildTable(
  ///   messageSchema,
  ///   from: {'text': 'body', 'sent_at': "strftime('%s', created_at) * 1000"},
  /// );
  /// ```
  ///
  /// A new column that the old table has nothing for is filled with `NULL` —
  /// or, when it is `NOT NULL`, with its `defaultValue`. Without either, the
  /// copy would fail halfway through, so it throws before starting.
  Future<void> rebuildTable(
    TableSchema schema, {
    Map<String, String> from = const {},
  }) async {
    final table = schema.tableName;
    final scratch = '${table}__relax_rebuild';
    final present = await columnsOf(table);

    // Everything is resolved before a single statement runs: a rebuild that
    // discovers halfway through that it has nothing to put in a NOT NULL column
    // would leave the table dropped and the copy unfinished.
    final targets = <String>[];
    final sources = <String>[];
    for (final column in schema.columns) {
      final expression =
          from[column.name] ??
          (present.contains(column.name)
              ? column.name
              : column.defaultValue ?? (column.isNullable ? 'NULL' : null));

      if (expression == null) {
        throw StateError(_cannotFill(table, column));
      }

      targets.add(column.name);
      sources.add(expression);
    }

    await _database.transaction(() async {
      // A leftover scratch table from an interrupted run would otherwise be
      // reused, and its rows would join the copy.
      await execute('DROP TABLE IF EXISTS $scratch');
      await execute(schema.toCreateTableSql(as: scratch, ifNotExists: false));
      await execute(
        'INSERT INTO $scratch (${targets.join(', ')}) '
        'SELECT ${sources.join(', ')} FROM $table',
      );
      await execute('DROP TABLE $table');
      await execute('ALTER TABLE $scratch RENAME TO $table');
    });

    _database.logger.log(
      RelaxLogCategory.database,
      'REBUILD $table (${targets.length} column(s))',
      level: RelaxLogLevel.info,
    );
  }

  static String _cannotAdd(String table, ColumnDef column) {
    final reason = column.isPrimaryKey
        ? 'SQLite cannot append a PRIMARY KEY column'
        : 'a NOT NULL column needs a defaultValue, so that the rows already in '
              'the table have something to hold';

    return 'Cannot add column "${column.name}" to "$table": $reason. '
        'Give the column a defaultValue, make it nullable, or rebuild the '
        'table from a migration (Migrator.rebuildTable).';
  }

  static String _cannotFill(String table, ColumnDef column) =>
      'Cannot rebuild "$table": column "${column.name}" is NOT NULL, the old '
      'table has nothing to fill it with, and it has no defaultValue. '
      'Pass an expression for it in `from`, or give it a defaultValue.';
}
