import 'package:uuid/uuid.dart';

import 'column_def.dart';

/// Defines the schema for a table in RelaxORM.
///
/// You can either write a [TableSchema] by hand (shown below) or annotate your
/// model with `@RelaxTable()` and let the `relax_orm_generator` build it for you
/// via `dart run build_runner build`. Both styles produce the same
/// [TableSchema] and are fully supported.
///
/// ```dart
/// final userSchema = TableSchema<User>(
///   tableName: 'users',
///   columns: [
///     ColumnDef.text('id', isPrimaryKey: true),
///     ColumnDef.text('name'),
///     ColumnDef.integer('age'),
///     ColumnDef.dateTime('created_at'),
///   ],
///   fromMap: (map) => User(
///     id: map['id'] as String,
///     name: map['name'] as String,
///     age: map['age'] as int,
///     createdAt: map['created_at'] as DateTime,
///   ),
///   toMap: (user) => {
///     'id': user.id,
///     'name': user.name,
///     'age': user.age,
///     'created_at': user.createdAt,
///   },
/// );
/// ```
class TableSchema<T> {
  final String tableName;
  final List<ColumnDef> columns;
  final T Function(Map<String, dynamic>) fromMap;
  final Map<String, dynamic> Function(T) toMap;

  /// Version of this schema's on-the-wire row format.
  ///
  /// Bump this whenever a change to [columns] alters how values are SQL-encoded
  /// (e.g. a column's [ColumnType] changes). Pending sync operations are stored
  /// as SQL-encoded rows; the [SyncEngine] discards any queued operation whose
  /// recorded version no longer matches the current schema version, so it never
  /// decodes stale data with an incompatible schema. Defaults to `1`.
  final int version;

  const TableSchema({
    required this.tableName,
    required this.columns,
    required this.fromMap,
    required this.toMap,
    this.version = 1,
  });

  /// The entity type [T] this schema maps. Used as an O(1) lookup key by
  /// `RelaxDB.collection<T>()`.
  Type get entityType => T;

  /// Returns the primary key column, or throws if none is defined.
  ColumnDef get primaryKey {
    try {
      return columns.firstWhere((c) => c.isPrimaryKey);
    } catch (_) {
      throw StateError(
        'Table "$tableName" has no primary key defined. '
        'Add isPrimaryKey: true to one of your columns.',
      );
    }
  }

  /// Returns the primary key value from an entity.
  Object getPrimaryKeyValue(T entity) {
    final map = toMap(entity);
    final pk = primaryKey;
    final value = map[pk.name];
    if (value == null) {
      throw StateError(
        'Primary key "${pk.name}" is null for entity of type $T.',
      );
    }
    return value;
  }

  /// Generates the CREATE TABLE SQL statement for this schema.
  String toCreateTableSql() {
    final columnsSql = columns
        .map((col) {
          final parts = <String>[col.name, col.sqlType];
          if (col.isPrimaryKey) parts.add('PRIMARY KEY');
          if (!col.isNullable && !col.isPrimaryKey) parts.add('NOT NULL');
          if (col.defaultValue != null) {
            parts.add('DEFAULT ${col.defaultValue}');
          }
          return parts.join(' ');
        })
        .join(', ');

    return 'CREATE TABLE IF NOT EXISTS $tableName ($columnsSql)';
  }

  /// Converts an entity to a SQL-ready map (Dart values → SQL values).
  Map<String, Object?> entityToRow(T entity) {
    final dartMap = toMap(entity);
    final sqlMap = <String, Object?>{};
    for (final col in columns) {
      var value = dartMap[col.name];

      if (value == null && col.isPrimaryKey && col.type == ColumnType.text) {
        value = const Uuid().v4();
      }

      sqlMap[col.name] = col.toSql(value);
    }
    return sqlMap;
  }

  /// Converts a SQL row back to an entity (SQL values → Dart values).
  T rowToEntity(Map<String, dynamic> row) {
    final dartMap = <String, dynamic>{};
    for (final col in columns) {
      dartMap[col.name] = col.fromSql(row[col.name]);
    }
    return fromMap(dartMap);
  }
}
