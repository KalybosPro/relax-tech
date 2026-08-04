## 1.0.0

First stable release. The generated `TableSchema` output is unchanged from
0.1.7 — the version bump commits to the current builder API and adds seeder
generation.

### Added

- **Seeder generation.** When enabled, every `@RelaxTable` model also gets a
  `TableSeeder` subclass — `User` → `UserSeeder` — whose `buildOne` fills each
  column with a `SeedFaker` call. Off by default; enable it with
  `dart run relax_orm --seed`, the `seed` builder option, or per model with
  `@RelaxSeed()`.
- `@RelaxSeed(count:, order:, enabled:)` support: `count` sets the generated
  `defaultCount`, `order` the `defaultOrder`, and `enabled: false` opts a model
  out even when seeding is on globally.
- Builder options `seed` (bool, default `false`) and `seed_count` (int, default
  `10`), readable from `build.yaml` or a `--define`.
- Faker calls are picked from the column type **and** its name, so `email` gets
  an address, `price` money-shaped numbers, `created_at` a past date. Nested
  models and `List<T>` fields are walked recursively; nullable columns are
  wrapped in `faker.maybe(...)`. Self-referencing non-nullable models are
  reported as a generation error instead of recursing forever.

### Changed

- Requires `relax_orm >=1.1.0` — generated seeders reference `TableSeeder` and
  `SeedFaker`, which that version introduces.

## 0.1.7

### Changed

- Widened the `relax_orm` dependency constraint to `>=0.1.7 <2.0.0` so the
  generator works with the stable `relax_orm` 1.0.0 release. Generated output is
  unchanged (the generator only uses the `TableSchema` API, which is unaffected
  by the 1.0.0 sync-adapter changes).

## 0.1.6

### Added

- Added support for JSON-backed serialization of nested model objects
- Added support for `List<T>` fields when `T` is a supported primitive or nested model type

### Changed

- Generator now encodes complex fields with `RelaxOrmJson.encode(...)` and decodes them with `RelaxOrmJson.decode(...)`
- Extended generated mapping support for nested values such as `DateTime` and `Uint8List` inside JSON-backed objects and lists

## 0.1.5

- Update dependencies

## 0.1.4

- Fixed conflict of analyser's version with other packages

## 0.1.3

### Fixed

- Fixed package repository accessibility on Github

## 0.1.2

### Fixed

- Fixed package publication metadata validation

## 0.1.1

### Changed

- Annotations are no longer duplicated in this package — now imported from `package:relax_orm/relax_orm_annotations.dart` (single source of truth)
- Added `relax_orm: ^0.1.0` as a dependency
- Added `issue_tracker`, `platforms` metadata to pubspec

### Removed

- Removed local `lib/src/annotations/` directory (duplicate of `relax_orm`)
- Removed `lib/relax_orm_annotations.dart` re-export (no longer needed)

## 0.1.0

- Initial release
- `RelaxTableGenerator` generates `TableSchema<T>` from `@RelaxTable()` annotated classes
- Automatic camelCase to snake_case conversion for table and column names
- Support for `@PrimaryKey()`, `@Column(name:, nullable:, defaultValue:)`, `@Ignore()`
- Supported types: `String`, `int`, `double`, `bool`, `DateTime`, `Uint8List` (+ nullable)
