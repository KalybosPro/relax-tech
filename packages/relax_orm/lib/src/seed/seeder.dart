import '../core/relax_db.dart';
import 'seed_faker.dart';

/// A unit of seed data.
///
/// Extend this directly when you need full control over what a seed does
/// (custom SQL, cross-table fixtures, calling an API, …). For the common
/// "fill this table with rows" case, prefer [TableSeeder] — the
/// `relax_orm_generator` writes one for you from your `@RelaxTable` model.
///
/// ```dart
/// class AdminSeeder extends Seeder {
///   @override
///   int get order => -1; // runs before everything else
///
///   @override
///   List<String> get tables => const ['users'];
///
///   @override
///   Future<void> run(RelaxDB db) async {
///     await db.collection<User>().add(User(id: 'admin', name: 'Admin'));
///   }
/// }
/// ```
abstract class Seeder {
  const Seeder();

  /// Unique name of this seeder.
  ///
  /// Used as the key in the `_relax_seeds` ledger, so a seeder never runs
  /// twice. Defaults to the runtime type name — override it if you register
  /// several instances of the same class.
  String get name => runtimeType.toString();

  /// Execution order (ascending). Seeders with the same order keep their
  /// registration order. Use it to satisfy foreign-key-ish dependencies —
  /// e.g. authors before posts.
  int get order => 0;

  /// Tables this seeder writes to.
  ///
  /// [SeedRunner.fresh] clears these before re-running, and the runner uses
  /// them to report how many rows were written. Return an empty list if the
  /// seeder doesn't map to tables.
  List<String> get tables => const [];

  /// Performs the seeding.
  Future<void> run(RelaxDB db);
}

/// A [Seeder] that fills one table with generated (or explicit) entities.
///
/// The `relax_orm_generator` emits a subclass per `@RelaxTable` model when
/// seeding is enabled — see `dart run relax_orm --seed`. The generated class
/// implements [buildOne] with a [SeedFaker] call per column; everything else
/// comes from here.
///
/// ```dart
/// // Generated defaults (10 rows of fake data).
/// db.seeds.register(UserSeeder());
///
/// // 50 rows instead.
/// db.seeds.register(UserSeeder(count: 50));
///
/// // Your own generator.
/// db.seeds.register(UserSeeder(
///   count: 3,
///   builder: (i, faker) => User(id: 'user-$i', name: faker.fullName()),
/// ));
///
/// // Fixed records — no randomness at all.
/// db.seeds.register(UserSeeder(records: [adminUser, guestUser]));
/// ```
abstract class TableSeeder<T> extends Seeder {
  /// Creates a table seeder.
  ///
  /// - [count]: how many entities to generate (defaults to [defaultCount]).
  /// - [records]: explicit entities to insert; disables generation entirely.
  /// - [builder]: replaces [buildOne] for generating a single entity.
  /// - [randomSeed]: seed of the [SeedFaker]; defaults to a stable hash of
  ///   [name], so the same seeder always produces the same rows.
  /// - [order]: overrides [defaultOrder].
  TableSeeder({
    int? count,
    List<T>? records,
    T Function(int index, SeedFaker faker)? builder,
    int? randomSeed,
    int? order,
  }) : _count = count,
       _records = records,
       _builder = builder,
       _randomSeed = randomSeed,
       _order = order;

  final int? _count;
  final List<T>? _records;
  final T Function(int index, SeedFaker faker)? _builder;
  final int? _randomSeed;
  final int? _order;

  /// Number of rows generated when no `count` is passed to the constructor.
  ///
  /// Generated seeders override this with the `@RelaxSeed(count: …)` value.
  int get defaultCount => 10;

  /// Order used when none is passed to the constructor.
  int get defaultOrder => 0;

  /// The table this seeder writes to.
  String get tableName;

  /// Builds a single entity. Implemented by generated seeders.
  T buildOne(int index, SeedFaker faker);

  /// Effective number of rows this seeder will insert.
  int get count => _records?.length ?? _count ?? defaultCount;

  @override
  int get order => _order ?? defaultOrder;

  @override
  List<String> get tables => [tableName];

  /// The entities that [run] will insert.
  ///
  /// Deterministic: calling it twice on the same seeder yields equal data.
  List<T> build() {
    final records = _records;
    if (records != null) return List<T>.of(records);

    final faker = SeedFaker(
      seed: _randomSeed ?? SeedFaker.seedFromString(name),
    );
    final build = _builder ?? buildOne;
    return List<T>.generate(count, (index) => build(index, faker));
  }

  /// Inserts [build]'s entities, overwriting rows that share their primary key.
  ///
  /// Because [build] is deterministic, running the same seeder twice converges
  /// on the same rows instead of failing on a duplicate key — so `force` and
  /// `fresh` re-runs stay safe.
  @override
  Future<void> run(RelaxDB db) async {
    final entities = build();
    if (entities.isEmpty) return;
    await db.collection<T>().upsertAll(entities);
  }
}
