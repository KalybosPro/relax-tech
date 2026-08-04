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

/// Opts a `@RelaxTable` model into seeder generation.
///
/// Run `dart run relax_orm --seed` (or `dart run build_runner build` with the
/// `seed` builder option) and the generator emits a `TableSeeder` subclass next
/// to the schema — `User` → `UserSeeder` — that fills the table with
/// deterministic fake data.
///
/// ```dart
/// @RelaxTable()
/// @RelaxSeed(count: 25, order: 1)
/// class User { ... }
/// ```
///
/// Without this annotation, `--seed` still generates a seeder for every
/// `@RelaxTable` model. Use `@RelaxSeed(enabled: false)` to opt a single model
/// out.
class RelaxSeed {
  /// How many rows the generated seeder inserts by default.
  final int count;

  /// Execution order of the generated seeder (ascending). Lower runs first —
  /// use it when one table's rows reference another's.
  final int order;

  /// Whether to generate a seeder for this model.
  ///
  /// `true` forces generation even without the `--seed` flag; `false` opts the
  /// model out even with it.
  final bool enabled;

  const RelaxSeed({this.count = 10, this.order = 0, this.enabled = true});
}

// Shorthand constants for cleaner annotation syntax.
const relaxTable = RelaxTable();
const primaryKey = PrimaryKey();
const ignore = Ignore();
const relaxSeed = RelaxSeed();
