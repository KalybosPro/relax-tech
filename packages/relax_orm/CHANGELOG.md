## 0.1.6

### Added

- Opt-in debug logging via `RelaxLogger`, passed to `RelaxDB.open`/`openFile`/`openInMemory`. Disabled by default; supports category filtering (`database`, `encryption`, `crud`, `query`, `sync`, `queue`), a minimum level, and a custom sink. Defaults to `dart:developer`'s `log()` (Flutter DevTools "Logging" view).
- `RelaxDB.debugCheckEncryption()` — inspects the database file header and reports whether data on disk is actually encrypted (`EncryptionCheck.isEncrypted` / `.isMisconfigured`), the direct answer to "are my data really encrypted?".

## 0.1.5

### Added

- `SyncPullResult.serverTime` — an optional server-authoritative watermark reused as the `since` value for the next pull, avoiding client/server clock drift
- Offline-queue coalescing: repeated edits to the same entity are folded both on write (one row per entity) and on push (one server write per entity); offline create-then-delete is dropped entirely

### Changed

- Queued sync payloads are now SQL-encoded, so entities with `DateTime`/`bool` fields no longer break the offline queue's JSON serialization
- `SyncAdapter.push` return values (server-confirmed entities) are written back to the local database
- Pull changes are applied inside a single transaction

### Fixed

- Failed sync operations are now retried by the periodic auto-sync (previously only on reconnect/restart), honoring each table's `maxRetries`
- Unique operation ids no longer collide when many operations are queued within the same clock tick

## 0.1.4

### Added

- Added public `RelaxOrmJson` helpers for generated schemas that need JSON serialization and deserialization
- Added base64 helpers for `Uint8List` values used inside JSON-backed fields

### Changed

- Exported `src/core/relax_orm_json.dart` from the main `relax_orm.dart` library
- Bumped `relax_orm_generator` to `^0.1.6` to support generated mappings for nested objects and `List<T>` fields

## 0.1.3

- Update dependencies

## 0.1.2

### Added

- Automatic UUID generation for text primary keys when inserting an entity with a null ID

### Changed

- `Collection.add()` now queues the persisted entity after ID generation so sync payloads keep the effective primary key
- Bumped `relax_orm_generator` to `^0.1.2`

### Fixed

- Synced inserts with generated text primary keys now keep database rows and queued operations aligned

## 0.1.1

### Changed

- Annotations (`@RelaxTable`, `@PrimaryKey`, `@Column`, `@Ignore`) are now the single source of truth in this package
- Added `relax_orm_annotations.dart` — lightweight export without Flutter/Drift dependencies, safe for use by code generators and pure-Dart contexts
- SDK constraint is now bounded (`>=3.11.0 <4.0.0`)
- Added `license`, `platforms`, `issue_tracker` metadata to pubspec

### Fixed

- Removed runtime dependency on `relax_orm_generator` — heavy build-time packages (`analyzer`, `source_gen`, `build`) are no longer pulled into the app's dependency tree

## 0.1.0

- Initial release
- **ORM Core**: `RelaxDB`, `Collection<T>` with full CRUD (add, addAll, update, upsert, delete, deleteAll, get, getAll, count)
- **Real-time streams**: `watchAll()`, `watchOne()` with Drift-powered reactive queries
- **Query builder**: fluent API with filters (equals, greaterThan, contains, isIn, isNull...), orderBy, limit, offset
- **Encryption**: transparent SQLite3MultipleCiphers encryption via `encryptionKey` parameter
- **Sync engine**: offline queue, push/pull sync, configurable conflict resolution (remoteWins, localWins, custom)
- **Code generation**: `@RelaxTable`, `@PrimaryKey`, `@Column`, `@Ignore` annotations with automatic schema generation
- **Schema definition**: `TableSchema<T>` with type-safe column definitions and automatic Dart/SQL type conversion
