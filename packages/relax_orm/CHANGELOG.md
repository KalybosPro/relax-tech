## 1.0.0

First stable release. Addresses the findings of the 0.1.7 technical audit (sync
engine, persistence, schema) and commits to a stable public API. Two changes to
the `SyncAdapter` contract since 0.1.7 are breaking; see below.

### Breaking

- `SyncAdapter.pushDeletes` now returns `Future<List<Object>>` (the ids the
  server confirmed as deleted) instead of `Future<void>` (SY-2).
- `SyncAdapter.push` semantics tightened: return **only** the entities the
  server accepted. Entities omitted from the result are treated as not-yet-synced
  and stay queued for retry instead of being silently completed (SY-1).
- `Collection.add` now returns `Future<T>` and `Collection.addAll` returns
  `Future<List<T>>` (the stored entities). This is source-compatible with
  existing `await`-and-ignore call sites (ORM-2).

### Fixed

- **SY-1 — Silent loss of unconfirmed pushes.** The engine now completes only
  the queued operations whose entity the adapter confirmed (matched by primary
  key); unconfirmed operations remain pending and are retried on the next sync.
- **SY-2 — Partial deletes.** `pushDeletes` reports confirmed ids, so a partial
  server-side delete no longer marks the whole batch as synced.
- **ORM-1 — `addAll` didn't refresh streams.** `rawBatchInsert` now emits an
  explicit table update, so active `watchAll()` / `watchOne()` listeners refresh
  after a bulk import.
- **ORM-2 — Generated ids unreachable.** `add()`/`addAll()` return the stored
  entity (with any generated UUID primary key) instead of `void`.
- **ORM-3 — `upsert()` race.** The existence check and the write now run inside a
  single transaction, so a concurrent write to the same key can't turn the insert
  into a `PRIMARY KEY` violation.

### Changed

- **SY-3 — Conflict-resolution asymmetry documented.** `SyncConfig.conflictResolver`
  runs only on pull; push-confirmation write-backs are authoritative. Documented
  in the docstring and README.
- **SY-4 — Targeted queue clear.** `OfflineQueue.clear({String? tableName})` can
  now purge a single table's pending operations.
- **ORM-4 — Schema versioning for the offline queue.** `TableSchema` gains a
  `version` field; queued operations record it, and the engine discards
  operations whose recorded version no longer matches the current schema so stale
  SQL-encoded rows are never decoded with an incompatible schema. (Existing
  queued rows are treated as version `0`/"unspecified" and kept, so upgrading is
  lossless.)
- **ORM-5 — O(1) schema lookup.** `RelaxDB.collection<T>()` resolves schemas via
  a direct type-keyed lookup instead of a linear scan.
- **GEN-1 — Generator status.** Removed the stale "Phase 1a/Phase 2" comments;
  the `relax_orm_generator` is available now, alongside hand-written schemas.

## 0.1.7

### Fixed

- Long debug-log messages are no longer truncated by the console/logcat: the default `dart:developer` sink splits long text (by line, then into 800-character chunks), tagging multi-chunk records with `[i/n]`.

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
