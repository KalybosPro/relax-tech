/// Supported column types in RelaxORM.
enum ColumnType {
  text,
  integer,
  real,
  boolean,
  dateTime,
  blob,
}

/// Defines a column in a [TableSchema].
class ColumnDef {
  final String name;
  final ColumnType type;
  final bool isPrimaryKey;
  final bool isNullable;
  final String? defaultValue;

  const ColumnDef({
    required this.name,
    required this.type,
    this.isPrimaryKey = false,
    this.isNullable = false,
    this.defaultValue,
  });

  // -- Convenience constructors --

  const ColumnDef.text(
    this.name, {
    this.isPrimaryKey = false,
    this.isNullable = false,
    this.defaultValue,
  }) : type = ColumnType.text;

  const ColumnDef.integer(
    this.name, {
    this.isPrimaryKey = false,
    this.isNullable = false,
    this.defaultValue,
  }) : type = ColumnType.integer;

  const ColumnDef.real(
    this.name, {
    this.isPrimaryKey = false,
    this.isNullable = false,
    this.defaultValue,
  }) : type = ColumnType.real;

  const ColumnDef.boolean(
    this.name, {
    this.isPrimaryKey = false,
    this.isNullable = false,
    this.defaultValue,
  }) : type = ColumnType.boolean;

  const ColumnDef.dateTime(
    this.name, {
    this.isPrimaryKey = false,
    this.isNullable = false,
    this.defaultValue,
  }) : type = ColumnType.dateTime;

  const ColumnDef.blob(
    this.name, {
    this.isPrimaryKey = false,
    this.isNullable = false,
    this.defaultValue,
  }) : type = ColumnType.blob;

  /// This column's definition as it appears inside `CREATE TABLE`.
  ///
  /// Shared with `ALTER TABLE … ADD COLUMN`, so a column added to a database
  /// that predates it ends up defined exactly as it would have been on a fresh
  /// one. Two spellings of the same column is how schemas quietly drift apart.
  String get definition {
    final parts = <String>[name, sqlType];
    if (isPrimaryKey) parts.add('PRIMARY KEY');
    if (!isNullable && !isPrimaryKey) parts.add('NOT NULL');
    if (defaultValue != null) parts.add('DEFAULT $defaultValue');
    return parts.join(' ');
  }

  /// Whether SQLite can append this column to an existing table.
  ///
  /// `ALTER TABLE … ADD COLUMN` refuses a `PRIMARY KEY`, and refuses `NOT NULL`
  /// without a default — it has no value to write into the rows already there.
  /// Everything else is fair game.
  bool get isAddable => !isPrimaryKey && (isNullable || defaultValue != null);

  /// Returns the SQL type string for this column.
  String get sqlType {
    switch (type) {
      case ColumnType.text:
        return 'TEXT';
      case ColumnType.integer:
        return 'INTEGER';
      case ColumnType.real:
        return 'REAL';
      case ColumnType.boolean:
        return 'INTEGER';
      case ColumnType.dateTime:
        return 'INTEGER';
      case ColumnType.blob:
        return 'BLOB';
    }
  }

  /// Converts a Dart value to its SQL representation.
  Object? toSql(Object? value) {
    if (value == null) return null;
    switch (type) {
      case ColumnType.boolean:
        return (value as bool) ? 1 : 0;
      case ColumnType.dateTime:
        return (value as DateTime).millisecondsSinceEpoch;
      default:
        return value;
    }
  }

  /// Converts a SQL value back to its Dart representation.
  Object? fromSql(Object? value) {
    if (value == null) return null;
    switch (type) {
      case ColumnType.boolean:
        return value == 1;
      case ColumnType.dateTime:
        return DateTime.fromMillisecondsSinceEpoch(value as int);
      default:
        return value;
    }
  }
}
