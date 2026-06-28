# RelaxORM

A **local-first ORM** for Flutter with offline support, real-time streams, automatic sync, and encryption.

Inspired by Firebase and PowerSync — but free, self-hosted, and with no SaaS dependency.

## Features

- **Simple API** — `db.collection<User>()` with typed CRUD
- **Real-time streams** — `watchAll()` / `watchOne()` for reactive UI
- **Offline-first** — all operations succeed locally, sync when back online
- **Sync engine** — push/pull with configurable conflict resolution
- **Encryption** — transparent AES database encryption via SQLite3MultipleCiphers
- **Query builder** — fluent, type-safe filters, sorting, pagination
- **Code generation** — annotate your models, schemas are generated automatically
- **Zero SaaS** — bring your own API, no vendor lock-in

## Quick Start

### 1. Add dependencies

```yaml
dependencies:
  relax_orm: ^1.0.0

dev_dependencies:
  relax_orm_generator: ^0.1.6
  build_runner: ^2.4.0
```

### 2. Define your model

```dart
import 'package:relax_orm/relax_orm.dart';

part 'user.g.dart';

@RelaxTable()
class User {
  @PrimaryKey()
  final String id;
  final String name;
  final int age;
  final bool active;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.age,
    required this.active,
    required this.createdAt,
  });
}
```

### 3. Generate the schema

```bash
dart run build_runner build
```

This generates `user.g.dart` containing a `userSchema` variable with all the column definitions, mappers, and type conversions.

### 4. Open the database and use it

```dart
final db = await RelaxDB.open(
  name: 'my_app',
  schemas: [userSchema],
  encryptionKey: 'optional-secret', // omit for no encryption
);

final users = db.collection<User>();
```

## CRUD Operations

```dart
// Create — returns the stored entity, including a generated id when the
// primary key is a null text column (the original object is left untouched).
final stored = await users.add(User(id: '1', name: 'Alice', age: 30, active: true, createdAt: DateTime.now()));

// Read
final user = await users.get('1');
final all = await users.getAll();
final count = await users.count();

// Update
await users.update(user.copyWith(name: 'Alice Updated'));

// Upsert (insert or update)
await users.upsert(user);

// Delete
await users.delete('1');
await users.deleteAll();

// Batch insert — returns the stored entities; active watchAll/watchOne
// streams are notified so the UI refreshes after a bulk import.
final storedAll = await users.addAll([user1, user2, user3]);
```

## Queries

```dart
final adults = await users
    .query()
    .where('age', greaterThan: 18)
    .where('active', equals: 1)
    .orderBy('name')
    .limit(10)
    .offset(20)
    .find();

// Single result
final admin = await users.query().where('name', equals: 'Admin').findOne();

// Count matching
final activeCount = await users.query().where('active', equals: 1).count();
```

### Available filters

| Filter | Example |
|---|---|
| `equals` | `.where('name', equals: 'Alice')` |
| `notEquals` | `.where('status', notEquals: 'banned')` |
| `greaterThan` | `.where('age', greaterThan: 18)` |
| `greaterThanOrEquals` | `.where('age', greaterThanOrEquals: 18)` |
| `lessThan` | `.where('age', lessThan: 65)` |
| `lessThanOrEquals` | `.where('score', lessThanOrEquals: 100)` |
| `contains` | `.where('name', contains: 'ali')` |
| `startsWith` | `.where('name', startsWith: 'Al')` |
| `endsWith` | `.where('email', endsWith: '.com')` |
| `isIn` | `.where('role', isIn: ['admin', 'mod'])` |
| `isNull` | `.where('deletedAt', isNull: true)` |

## Real-time Streams

```dart
// Watch all entities (re-emits on every table change)
users.watchAll().listen((list) {
  setState(() => _users = list);
});

// Watch a single entity
users.watchOne('1').listen((user) {
  setState(() => _currentUser = user);
});

// Watch a query
users.query().where('active', equals: 1).watch().listen((activeUsers) {
  setState(() => _activeUsers = activeUsers);
});
```

## Sync Engine

### 1. Implement a SyncAdapter for your API

```dart
class UserSyncAdapter implements SyncAdapter<User> {
  final ApiClient api;
  UserSyncAdapter(this.api);

  @override
  Future<List<User>> push(List<User> entities) async {
    final response = await api.post('/users/batch', entities);
    // Return ONLY the entities the server accepted. Any entity you omit is
    // treated as not-yet-synced and stays queued for the next sync, so a
    // partial success never silently drops a change. Throw to fail the batch.
    return response.acceptedUsers;
  }

  @override
  Future<List<Object>> pushDeletes(List<Object> ids) async {
    // Return the ids the server confirmed as deleted (same retry contract).
    return await api.delete('/users/batch', ids);
  }

  @override
  Future<SyncPullResult<User>> pull({DateTime? since}) async {
    // `since` is the watermark from the previous pull (null on first sync).
    final response = await api.get('/users/changes', since: since);
    return SyncPullResult(
      upserts: response.updated,
      deletedIds: response.deleted,
      // Return the server's own timestamp so the next pull resumes exactly
      // where this one stopped — immune to client/server clock drift.
      serverTime: response.serverTime,
    );
  }
}
```

> **Tip — `serverTime`:** the engine uses it as the `since` value for the next
> pull of that table. When your API can return its authoritative cursor
> (a server timestamp, a change id, etc.), always set it. If you leave it
> `null`, the engine falls back to the client clock captured *before* the sync,
> which is less precise under clock skew but still works.

### 2. Configure and start

```dart
final engine = await db.sync;

engine.register(SyncConfig<User>(
  schema: userSchema,
  adapter: UserSyncAdapter(api),
  conflictResolver: ConflictResolver.remoteWins(), // default
  autoSyncInterval: Duration(minutes: 5),          // optional
  maxRetries: 5,                                   // optional, default 5
));

// Connect your connectivity stream (e.g. from connectivity_plus)
engine.connectivityStream = Connectivity().onConnectivityChanged
    .map((result) => result != ConnectivityResult.none);

// Listen to sync status
engine.status.listen((status) {
  print(status); // idle, syncing, synced, offline, error
});

// Start syncing
await engine.start();
```

### 3. That's it

All CRUD operations on synced collections are automatically queued and pushed when connectivity is restored.

### Manual sync

```dart
await engine.syncAll();               // sync all registered tables
await engine.syncTable('users');      // sync a specific table
final pending = await engine.pendingCount(); // number of queued operations
```

### Offline queue & coalescing

Every CRUD call on a synced collection is persisted to an internal SQLite queue,
so changes survive app restarts and are replayed when connectivity returns. To
avoid flooding your API with intermediate states, the queue **coalesces** repeated
edits to the same entity at two levels:

- **On write (storage):** a new operation is folded into the entity's existing
  *pending* row, so the queue holds **one row per entity** instead of one per edit.
- **On push (network):** whatever remains pending is folded once more, so the
  server receives **a single write per entity** per sync.

Folding rules (in chronological order, per entity):

| Sequence | Result sent to the server |
|---|---|
| `add` → `update` → … | a single **create** with the final state |
| `update` → `update` → … | a single **update** with the final state |
| `add` → `delete` | **nothing** (the entity never reached the server) |
| `update` → `delete` | a **delete** |
| `delete` → `add` | an **update** (re-creation of an existing remote entity) |

So editing a row ten times offline pushes it **once**, and creating then deleting
a row offline pushes **nothing**. Operations that have already failed mid-flight
are never silently merged — they keep their own row and are retried on the next
sync (up to `maxRetries`).

### Conflict Resolution

```dart
// Remote always wins (default)
ConflictResolver.remoteWins<User>()

// Local always wins
ConflictResolver.localWins<User>()

// Custom logic
ConflictResolver<User>.custom((local, remote) {
  return remote.updatedAt.isAfter(local.updatedAt) ? remote : local;
})
```

> **Note — where the resolver runs:** `conflictResolver` is applied only when
> applying a **pull** (changes coming *from* the server). The server-confirmed
> versions written back after a successful **push** are treated as authoritative
> and overwrite the local row *without* running the resolver — a confirmed push
> already reflects the state the server accepted.

## Encryption

RelaxORM uses SQLite3MultipleCiphers for transparent database encryption.

### Setup

Add to your app's `pubspec.yaml`:

```yaml
hooks:
  user_defines:
    sqlite3:
      source: sqlite3mc
```

### Usage

```dart
final db = await RelaxDB.open(
  name: 'my_app',
  schemas: [userSchema],
  encryptionKey: 'your-secret-key',
);
```

The entire database file is encrypted. Without the correct key, the file is unreadable.

## Debug Logging

RelaxORM is silent by default. During development you can opt in to a structured
logger to observe what the ORM does — database lifecycle, **encryption status**,
CRUD, queries, sync and the offline queue. It is **off by default** (no runtime
cost, no console noise for your users) and only the developer turns it on.

```dart
final db = await RelaxDB.open(
  name: 'my_app',
  schemas: [userSchema],
  encryptionKey: 'your-secret-key',
  logger: const RelaxLogger(), // enabled; logs to Flutter DevTools "Logging"
);
```

By default records go to `dart:developer`'s `log()` (grouped under
`relax_orm.<category>` in DevTools). You can filter by category, set a minimum
level, or forward records to your own sink:

```dart
final db = await RelaxDB.open(
  name: 'my_app',
  schemas: [userSchema],
  logger: RelaxLogger(
    categories: {RelaxLogCategory.crud, RelaxLogCategory.encryption},
    minLevel: RelaxLogLevel.debug,
    sink: (record) => print(record), // your console, a file, a crash reporter…
  ),
);
```

Categories: `database`, `encryption`, `crud`, `query`, `sync`, `queue`.

### Verifying your data is really encrypted

`isEncryptionAvailable()` only tells you the cipher is *linked*. To confirm the
bytes **on disk** are actually ciphertext, use `debugCheckEncryption()`:

```dart
final check = await db.debugCheckEncryption();
print(check.isEncrypted);     // true → file is ciphertext, false → plaintext
print(check.isMisconfigured); // true → a key was set but the file is still plaintext
print(check.message);         // human-readable explanation (also logged)
```

It inspects the file header: an unencrypted SQLite file always begins with
`SQLite format 3`. For databases opened with `open()` (where drift_flutter
resolves the path), pass the `File` explicitly: `debugCheckEncryption(file: ...)`.
In-memory databases cannot be inspected and return `isEncrypted == null`.

## Annotations Reference

| Annotation | Usage |
|---|---|
| `@RelaxTable()` | Marks a class as an ORM entity |
| `@RelaxTable(name: 'custom')` | Custom table name |
| `@PrimaryKey()` | Marks the primary key field |
| `@Column(name: 'col')` | Custom column name |
| `@Column(nullable: true)` | Nullable column |
| `@Ignore()` | Excludes a field from the schema |

### Supported types

`String`, `int`, `double`, `bool`, `DateTime`, `Uint8List`

Nullable variants (`String?`, `int?`, etc.) are also supported.

## Database Access

```dart
// Production (recommended) — Drift handles paths & isolates
final db = await RelaxDB.open(name: 'app', schemas: [...]);

// Custom file path
final db = await RelaxDB.openFile(file: File('path.db'), schemas: [...]);

// In-memory (testing) — encryption not supported in-memory
final db = await RelaxDB.openInMemory(schemas: [...]);

// Check if the linked SQLite library supports encryption
final supported = await db.isEncryptionAvailable();

// Close when done (also disposes sync engine)
await db.close();
```

## Architecture

```
+--------------------------------------------------+
|                  Your Flutter App                 |
+--------------------------------------------------+
|   RelaxDB          Collection<T>     QueryBuilder |
|   (entry point)    (typed CRUD)      (fluent API) |
+--------------------------------------------------+
|   SyncEngine       OfflineQueue      Conflict     |
|   (push/pull)      (persisted)       Resolver     |
+--------------------------------------------------+
|   Drift (SQLite)   SQLite3MultipleCiphers         |
|   (hidden)         (encryption)                   |
+--------------------------------------------------+
```

## License

MIT
