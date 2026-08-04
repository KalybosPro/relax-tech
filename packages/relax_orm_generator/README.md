# RelaxORM Generator

Code generator for [relax_orm](https://pub.dev/packages/relax_orm). Generates `TableSchema` definitions from annotated Dart classes.

## Setup

```yaml
dependencies:
  relax_orm: ^1.1.0

dev_dependencies:
  relax_orm_generator: ^1.0.0
  build_runner: ^2.4.0
```

## Usage

Annotate your model classes with `@RelaxTable()`:

```dart
import 'package:relax_orm/relax_orm.dart';

part 'user.g.dart';

@RelaxTable()
class User {
  @PrimaryKey()
  final String id;
  final String name;
  final int age;
  final DateTime createdAt;

  User({required this.id, required this.name, required this.age, required this.createdAt});
}
```

Run the generator:

```bash
dart run build_runner build     # or: dart run relax_orm
```

This generates `user.g.dart`:

```dart
final userSchema = TableSchema<User>(
  tableName: 'users',
  columns: [
    ColumnDef.text('id', isPrimaryKey: true),
    ColumnDef.text('name'),
    ColumnDef.integer('age'),
    ColumnDef.dateTime('created_at'),
  ],
  fromMap: (map) => User(
    id: map['id'] as String,
    name: map['name'] as String,
    age: map['age'] as int,
    createdAt: map['created_at'] as DateTime,
  ),
  toMap: (entity) => {
    'id': entity.id,
    'name': entity.name,
    'age': entity.age,
    'created_at': entity.createdAt,
  },
);
```

## Seeders

The generator can also emit a `TableSeeder` per model, filling the table with
deterministic fake data. It is **off by default**; turn it on for the whole
project with the CLI flag:

```bash
dart run relax_orm --seed                    # every @RelaxTable model
dart run relax_orm --seed --seed-count=25    # 25 rows instead of 10
```

…which is shorthand for a `build_runner` define:

```bash
dart run build_runner build \
  --define="relax_orm_generator:relax_orm=seed=true"
```

Or set it permanently in `build.yaml`:

```yaml
targets:
  $default:
    builders:
      relax_orm_generator:relax_orm:
        options:
          seed: true
          seed_count: 25
```

Per model, `@RelaxSeed()` wins over both — it generates a seeder without any
flag, and `@RelaxSeed(enabled: false)` opts a model out despite one:

```dart
@RelaxTable()
@RelaxSeed(count: 25, order: 1)
class User { ... }
```

For `User`, this generates:

```dart
class UserSeeder extends TableSeeder<User> {
  @override
  String get tableName => 'users';

  @override
  int get defaultCount => 25;

  @override
  int get defaultOrder => 1;

  @override
  User buildOne(int index, SeedFaker faker) => User(
        id: faker.uuid(),
        name: faker.fullName(),
        age: faker.integer(min: 18, max: 80),
        createdAt: faker.pastDateTime(),
      );
}
```

The faker call comes from the column type and its name (`email` → an address,
`price` → money-shaped numbers, `created_at` → a past date). Nested models and
`List<T>` fields are walked recursively; nullable columns get `faker.maybe(...)`.

Running the seeders is `relax_orm`'s job — see its
[Seeding docs](https://pub.dev/packages/relax_orm#seeding).

## Annotations

| Annotation | Effect |
|---|---|
| `@RelaxTable()` | Generates a schema for the class |
| `@RelaxTable(name: 'custom')` | Custom table name |
| `@PrimaryKey()` | Marks the primary key |
| `@Column(name: 'col')` | Custom column name |
| `@Ignore()` | Excludes a field |
| `@RelaxSeed()` | Also generates a `TableSeeder` for the class |
| `@RelaxSeed(count: 25, order: 1)` | Rows to generate, and run order |
| `@RelaxSeed(enabled: false)` | Never generate a seeder, even with `--seed` |

## Naming conventions

- **Table names**: `User` -> `users`, `BlogPost` -> `blog_posts`
- **Column names**: `createdAt` -> `created_at`, `firstName` -> `first_name`

Override with `@RelaxTable(name: ...)` or `@Column(name: ...)`.

## Supported types

`String`, `int`, `double`, `bool`, `DateTime`, `Uint8List` (and nullable variants).

## License

MIT
