import 'package:flutter_test/flutter_test.dart';
import 'package:relax_orm/relax_orm.dart';

// -- Test models --

class User {
  final String id;
  final String name;
  final int age;

  User({required this.id, required this.name, required this.age});
}

class Post {
  final String id;
  final String title;

  Post({required this.id, required this.title});
}

final userSchema = TableSchema<User>(
  tableName: 'users',
  columns: [
    ColumnDef.text('id', isPrimaryKey: true),
    ColumnDef.text('name'),
    ColumnDef.integer('age'),
  ],
  fromMap: (map) => User(
    id: map['id'] as String,
    name: map['name'] as String,
    age: map['age'] as int,
  ),
  toMap: (entity) => {'id': entity.id, 'name': entity.name, 'age': entity.age},
);

final postSchema = TableSchema<Post>(
  tableName: 'posts',
  columns: [ColumnDef.text('id', isPrimaryKey: true), ColumnDef.text('title')],
  fromMap: (map) =>
      Post(id: map['id'] as String, title: map['title'] as String),
  toMap: (entity) => {'id': entity.id, 'title': entity.title},
);

// -- Seeders (shaped exactly like the generated ones) --

class UserSeeder extends TableSeeder<User> {
  UserSeeder({
    super.count,
    super.records,
    super.builder,
    super.randomSeed,
    super.order,
  });

  @override
  String get tableName => 'users';

  @override
  int get defaultCount => 3;

  @override
  User buildOne(int index, SeedFaker faker) => User(
    id: faker.uuid(),
    name: faker.fullName(),
    age: faker.integer(min: 18, max: 80),
  );
}

class PostSeeder extends TableSeeder<Post> {
  PostSeeder({super.count, super.order});

  @override
  String get tableName => 'posts';

  @override
  int get defaultCount => 2;

  @override
  int get defaultOrder => 1;

  @override
  Post buildOne(int index, SeedFaker faker) =>
      Post(id: faker.uuid(), title: faker.sentence(words: 3));
}

class FailingSeeder extends Seeder {
  @override
  Future<void> run(RelaxDB db) async => throw StateError('boom');
}

class RecordingSeeder extends Seeder {
  RecordingSeeder(this._name, this._order, this._log);

  final String _name;
  final int _order;
  final List<String> _log;

  @override
  String get name => _name;

  @override
  int get order => _order;

  @override
  Future<void> run(RelaxDB db) async => _log.add(_name);
}

void main() {
  group('SeedFaker', () {
    test('is deterministic for a given seed', () {
      final a = SeedFaker(seed: 42);
      final b = SeedFaker(seed: 42);
      for (var i = 0; i < 10; i++) {
        expect(a.fullName(), b.fullName());
        expect(a.integer(), b.integer());
        expect(a.uuid(), b.uuid());
      }
    });

    test('different seeds diverge', () {
      expect(SeedFaker(seed: 1).uuid(), isNot(SeedFaker(seed: 2).uuid()));
    });

    test('seedFromString is stable and differs per input', () {
      expect(
        SeedFaker.seedFromString('UserSeeder'),
        SeedFaker.seedFromString('UserSeeder'),
      );
      expect(
        SeedFaker.seedFromString('UserSeeder'),
        isNot(SeedFaker.seedFromString('PostSeeder')),
      );
    });

    test('uuid has the v4 shape', () {
      final uuid = SeedFaker(seed: 7).uuid();
      expect(
        uuid,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-'
            r'[0-9a-f]{12}$',
          ),
        ),
      );
    });

    test('integer and decimal stay inside their bounds', () {
      final faker = SeedFaker(seed: 3);
      for (var i = 0; i < 200; i++) {
        expect(faker.integer(min: 5, max: 9), inInclusiveRange(5, 9));
        expect(faker.decimal(min: -1, max: 1), inInclusiveRange(-1.0, 1.0));
      }
    });

    test('dateTime respects the reference now', () {
      final now = DateTime(2024, 6, 1);
      final faker = SeedFaker(seed: 1, now: now);
      expect(
        faker.pastDateTime().isAfter(now.subtract(const Duration(days: 366))),
        isTrue,
      );
      expect(faker.pastDateTime().isBefore(now), isTrue);
      expect(faker.futureDateTime().isAfter(now), isTrue);
    });

    test('maybe returns null sometimes and a value sometimes', () {
      final faker = SeedFaker(seed: 11);
      final values = List.generate(200, (_) => faker.maybe('x'));
      expect(values, contains(null));
      expect(values, contains('x'));
    });

    test('email and username look like identifiers', () {
      final faker = SeedFaker(seed: 5);
      expect(faker.email(), matches(RegExp(r'^[a-z.]+\d+@[\w.]+$')));
      expect(faker.username(), matches(RegExp(r'^[a-z]+\.[a-z]+\d+$')));
    });
  });

  group('TableSeeder', () {
    test('generates defaultCount entities, reproducibly', () {
      final first = UserSeeder().build();
      final second = UserSeeder().build();

      expect(first, hasLength(3));
      expect(first.map((u) => u.id), second.map((u) => u.id));
      expect(first.map((u) => u.name), second.map((u) => u.name));
    });

    test('count overrides defaultCount', () {
      expect(UserSeeder(count: 7).build(), hasLength(7));
    });

    test('records bypass generation entirely', () {
      final seeder = UserSeeder(
        records: [User(id: 'fixed', name: 'Admin', age: 42)],
      );
      expect(seeder.count, 1);
      expect(seeder.build().single.id, 'fixed');
    });

    test('builder replaces buildOne', () {
      final seeder = UserSeeder(
        count: 2,
        builder: (index, faker) =>
            User(id: 'user-$index', name: faker.firstName(), age: 20),
      );
      expect(seeder.build().map((u) => u.id), ['user-0', 'user-1']);
    });

    test('randomSeed changes the generated data', () {
      final a = UserSeeder(randomSeed: 1).build();
      final b = UserSeeder(randomSeed: 2).build();
      expect(a.first.id, isNot(b.first.id));
    });

    test('exposes its table', () {
      expect(UserSeeder().tables, ['users']);
    });
  });

  group('SeedRunner', () {
    late RelaxDB db;

    setUp(() async {
      db = await RelaxDB.openInMemory(schemas: [userSchema, postSchema]);
    });

    tearDown(() async {
      await db.close();
    });

    test('runs registered seeders and reports rows', () async {
      db.seeds.registerAll([UserSeeder(), PostSeeder()]);

      final report = await db.seeds.run();

      expect(report.hasFailures, isFalse);
      expect(report.applied, hasLength(2));
      expect(report.rows, 5); // 3 users + 2 posts
      expect(await db.collection<User>().count(), 3);
      expect(await db.collection<Post>().count(), 2);
    });

    test('is idempotent — a second run skips everything', () async {
      db.seeds.register(UserSeeder());

      await db.seeds.run();
      final second = await db.seeds.run();

      expect(second.applied, isEmpty);
      expect(second.skipped, hasLength(1));
      expect(await db.collection<User>().count(), 3);
    });

    test(
      'force re-runs applied seeders, converging on the same rows',
      () async {
        db.seeds.register(UserSeeder());

        await db.seeds.run();
        final before = await db.collection<User>().getAll();
        final forced = await db.seeds.run(force: true);
        final after = await db.collection<User>().getAll();

        expect(forced.applied, hasLength(1));
        // Deterministic data + upsert: no duplicate-key error, no extra rows.
        expect(after, hasLength(3));
        expect(after.map((u) => u.id).toSet(), before.map((u) => u.id).toSet());
      },
    );

    test('only restricts the run', () async {
      db.seeds.registerAll([UserSeeder(), PostSeeder()]);

      await db.seeds.run(only: ['PostSeeder']);

      expect(await db.collection<User>().count(), 0);
      expect(await db.collection<Post>().count(), 2);
      expect(await db.seeds.appliedNames(), {'PostSeeder'});
    });

    test('only throws on an unknown seeder name', () async {
      db.seeds.register(UserSeeder());
      expect(
        () => db.seeds.run(only: ['NopeSeeder']),
        throwsA(isA<StateError>()),
      );
    });

    test('respects order, then registration order', () async {
      final log = <String>[];
      db.seeds.registerAll([
        RecordingSeeder('third', 10, log),
        RecordingSeeder('first', -1, log),
        RecordingSeeder('second', 0, log),
      ]);

      await db.seeds.run();

      expect(log, ['first', 'second', 'third']);
    });

    test('fresh wipes the tables and re-seeds', () async {
      db.seeds.register(UserSeeder());
      await db.seeds.run();
      await db.collection<User>().add(User(id: 'manual', name: 'x', age: 1));
      expect(await db.collection<User>().count(), 4);

      final report = await db.seeds.fresh();

      expect(report.applied, hasLength(1));
      expect(await db.collection<User>().count(), 3);
      expect(await db.collection<User>().get('manual'), isNull);
    });

    test('forget lets a seeder run again without deleting rows', () async {
      db.seeds.register(UserSeeder());
      await db.seeds.run();

      await db.seeds.forget(['UserSeeder']);
      expect(await db.seeds.hasRun('UserSeeder'), isFalse);

      final report = await db.seeds.run();
      expect(report.applied, hasLength(1));
      expect(await db.collection<User>().count(), 3);
    });

    test(
      'a failing seeder is reported, not thrown, and leaves no ledger entry',
      () async {
        db.seeds.registerAll([FailingSeeder(), UserSeeder()]);

        final report = await db.seeds.run();

        expect(report.hasFailures, isTrue);
        expect(report.failed.single.name, 'FailingSeeder');
        expect(report.failed.single.error, isA<StateError>());
        expect(await db.seeds.appliedNames(), isEmpty);
        // Stopped at the first failure, so UserSeeder never ran.
        expect(await db.collection<User>().count(), 0);
        expect(report.throwIfFailed, throwsA(isA<StateError>()));
      },
    );

    test('continueOnError keeps going past a failure', () async {
      db.seeds.registerAll([FailingSeeder(), UserSeeder()]);

      final report = await db.seeds.run(continueOnError: true);

      expect(report.failed, hasLength(1));
      expect(report.applied, hasLength(1));
      expect(await db.collection<User>().count(), 3);
    });

    test('registering the same name twice throws', () {
      db.seeds.register(UserSeeder());
      expect(() => db.seeds.register(UserSeeder()), throwsA(isA<StateError>()));
    });

    test('the ledger survives a reopen of the same schemas', () async {
      db.seeds.register(UserSeeder());
      await db.seeds.run();

      // Same connection, fresh runner state.
      db.seeds.clear();
      db.seeds.register(UserSeeder());
      final report = await db.seeds.run();

      expect(report.skipped, hasLength(1));
    });
  });
}
