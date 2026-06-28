/// Marks a class as a RelaxORM table entity.
///
/// Run `dart run build_runner build` with the `relax_orm_generator` package to
/// generate a `TableSchema` for the annotated class automatically. Writing the
/// schema by hand with `TableSchema` remains fully supported.
///
/// ```dart
/// @RelaxTable()
/// class User {
///   @PrimaryKey()
///   final String id;
///   final String name;
///   final int age;
///
///   User({required this.id, required this.name, required this.age});
/// }
/// ```
class RelaxTable {
  final String? name;

  const RelaxTable({this.name});
}

/// Marks a field as the primary key of the table.
class PrimaryKey {
  const PrimaryKey();
}

/// Customizes how a field is stored in the database.
class Column {
  /// Override the column name in the database.
  final String? name;

  /// Whether the column accepts null values.
  final bool nullable;

  /// Default value for the column (as SQL expression).
  final String? defaultValue;

  const Column({this.name, this.nullable = false, this.defaultValue});
}

/// Marks a field to be ignored by the ORM.
class Ignore {
  const Ignore();
}

// Shorthand constants for cleaner annotation syntax.
const relaxTable = RelaxTable();
const primaryKey = PrimaryKey();
const ignore = Ignore();
