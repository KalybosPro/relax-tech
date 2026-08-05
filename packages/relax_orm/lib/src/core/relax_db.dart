import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../database/relax_database.dart';
import '../logging/relax_logger.dart';
import '../migration/migrator.dart';
import '../schema/table_schema.dart';
import '../seed/seed_runner.dart';
import '../sync/offline_queue.dart';
import '../sync/sync_engine.dart';
import 'collection.dart';

/// Callback applied to the raw SQLite database right after opening.
///
/// Use this to run PRAGMAs or install custom functions.
typedef DatabaseSetup = void Function(dynamic rawDb);

/// The main entry point for RelaxORM.
///
/// ```dart
/// final db = await RelaxDB.open(
///   name: 'my_app',
///   schemas: [userSchema, postSchema],
///   encryptionKey: 'optional-secret-key',
/// );
///
/// final users = db.collection<User>();
/// await users.add(user);
/// ```
class RelaxDB {
  final RelaxDatabase _database;
  final Map<Type, TableSchema> _schemas;
  SyncEngine? _syncEngine;
  OfflineQueue? _offlineQueue;
  SeedRunner? _seedRunner;

  /// Whether an encryption key was supplied when the database was opened.
  final bool _encryptionRequested;

  /// The backing file, when known (set by [openFile]). `null` for [open]
  /// (drift_flutter resolves the path internally) and [openInMemory].
  final File? _dbFile;

  RelaxDB._(
    this._database,
    this._schemas, {
    bool encryptionRequested = false,
    File? dbFile,
  }) : _encryptionRequested = encryptionRequested,
       _dbFile = dbFile;

  /// The developer logger attached to this database (disabled by default).
  RelaxLogger get logger => _database.logger;

  /// Opens (or creates) a RelaxORM database using [drift_flutter].
  ///
  /// This is the recommended way to open a database in a Flutter app.
  /// Drift handles platform-specific file paths and isolates.
  ///
  /// - [name]: The database file name (without extension).
  /// - [schemas]: List of table schemas to create.
  /// - [encryptionKey]: Optional encryption key (enables SQLite3MultipleCiphers).
  /// - [logger]: Optional opt-in developer logger. When omitted, logging is off.
  /// - [version]: The schema version this build expects. Raise it whenever a
  ///   change to [schemas] cannot be applied by appending a column, and
  ///   describe the change in [onUpgrade].
  /// - [onUpgrade]: Runs when the stored version is behind [version]. Adding a
  ///   nullable column needs neither — see [Migrator].
  static Future<RelaxDB> open({
    required String name,
    required List<TableSchema> schemas,
    String? encryptionKey,
    RelaxLogger? logger,
    int version = 1,
    RelaxMigration? onUpgrade,
  }) async {
    final log = logger ?? const RelaxLogger.disabled();
    final executor = driftDatabase(
      name: name,
      native: DriftNativeOptions(setup: _buildSetup(encryptionKey, log)),
    );

    return _init(
      RelaxDatabase(executor, logger: log),
      schemas,
      encryptionRequested: encryptionKey != null,
      version: version,
      onUpgrade: onUpgrade,
    );
  }

  /// Opens a database from a specific file path.
  ///
  /// Useful for tests or when you need full control over the file location.
  ///
  /// - [file]: The database file.
  /// - [schemas]: List of table schemas to create.
  /// - [encryptionKey]: Optional encryption key (enables SQLite3MultipleCiphers).
  /// - [logger]: Optional opt-in developer logger. When omitted, logging is off.
  static Future<RelaxDB> openFile({
    required File file,
    required List<TableSchema> schemas,
    String? encryptionKey,
    RelaxLogger? logger,
    int version = 1,
    RelaxMigration? onUpgrade,
  }) async {
    final log = logger ?? const RelaxLogger.disabled();
    final nativeDb = NativeDatabase(
      file,
      setup: _buildSetup(encryptionKey, log),
    );

    return _init(
      RelaxDatabase(nativeDb, logger: log),
      schemas,
      encryptionRequested: encryptionKey != null,
      dbFile: file,
      version: version,
      onUpgrade: onUpgrade,
    );
  }

  /// Opens an in-memory database (for testing).
  ///
  /// Data is not persisted — the database is destroyed when [close] is called.
  ///
  /// Note: encryption is not supported for in-memory databases (SQLite limitation).
  /// Use [openFile] for encrypted databases.
  ///
  /// - [logger]: Optional opt-in developer logger. When omitted, logging is off.
  static Future<RelaxDB> openInMemory({
    required List<TableSchema> schemas,
    RelaxLogger? logger,
    int version = 1,
  }) async {
    final log = logger ?? const RelaxLogger.disabled();
    final nativeDb = NativeDatabase.memory();
    return _init(
      RelaxDatabase(nativeDb, logger: log),
      schemas,
      version: version,
    );
  }

  /// Returns a typed [Collection] for the given entity type.
  ///
  /// The type [T] must match one of the schemas registered at [open].
  ///
  /// ```dart
  /// final users = db.collection<User>();
  /// ```
  Collection<T> collection<T>() {
    final schema = _findSchema<T>();
    return Collection<T>(_database, schema, syncEngine: _syncEngine);
  }

  /// The [SeedRunner] attached to this database, created lazily.
  ///
  /// Register your seeders on it, then call `run()` — already-applied seeders
  /// are skipped, so it is safe to call on every app start.
  ///
  /// ```dart
  /// db.seeds.registerAll([UserSeeder(), PostSeeder(count: 50)]);
  /// await db.seeds.run();
  /// ```
  SeedRunner get seeds => _seedRunner ??= SeedRunner(this, _database);

  /// Returns the [SyncEngine], creating it lazily if needed.
  ///
  /// Use this to register sync adapters and control the sync lifecycle.
  ///
  /// ```dart
  /// db.sync.register(SyncConfig(
  ///   schema: userSchema,
  ///   adapter: UserSyncAdapter(api),
  /// ));
  /// db.sync.connectivityStream = connectivityStream;
  /// db.sync.start();
  /// ```
  Future<SyncEngine> get sync async {
    if (_syncEngine != null) return _syncEngine!;

    _offlineQueue = OfflineQueue(_database);
    await _offlineQueue!.init();
    _syncEngine = SyncEngine(_database, _offlineQueue!);
    return _syncEngine!;
  }

  /// Closes the database connection and disposes the sync engine.
  Future<void> close() async {
    await _syncEngine?.dispose();
    await _database.close();
  }

  // -- Private helpers --

  static Future<RelaxDB> _init(
    RelaxDatabase database,
    List<TableSchema> schemas, {
    bool encryptionRequested = false,
    File? dbFile,
    int version = 1,
    RelaxMigration? onUpgrade,
  }) async {
    try {
      await _upgrade(database, schemas, version: version, onUpgrade: onUpgrade);
    } catch (_) {
      // An open that fails must not keep the file: the caller is handed an
      // error and never a database, so it has nothing to close, and the file
      // would stay locked for the rest of the process.
      await database.close();
      rethrow;
    }

    final schemaMap = <Type, TableSchema>{};
    for (final schema in schemas) {
      // Key by the mapped entity type (T), not the schema's runtimeType, so
      // collection<T>() resolves in O(1) via a direct lookup.
      schemaMap[schema.entityType] = schema;
    }

    final db = RelaxDB._(
      database,
      schemaMap,
      encryptionRequested: encryptionRequested,
      dbFile: dbFile,
    );

    final log = database.logger;
    if (log.isLoggable(RelaxLogCategory.database, RelaxLogLevel.info)) {
      log.log(
        RelaxLogCategory.database,
        'Database opened (${schemas.length} schema(s))',
        level: RelaxLogLevel.info,
      );
    }
    if (log.isLoggable(RelaxLogCategory.encryption, RelaxLogLevel.info)) {
      final available = await db.isEncryptionAvailable();
      log.log(
        RelaxLogCategory.encryption,
        'Encryption key requested: $encryptionRequested · '
        'cipher available: $available',
        level: RelaxLogLevel.info,
      );
    }

    return db;
  }

  /// Brings the database's tables up to the shape [schemas] describe.
  ///
  /// Three passes, in this order, and the order is the whole design:
  ///
  /// 1. **Create.** `CREATE TABLE IF NOT EXISTS` per schema. A table that is
  ///    already there is left exactly as it is — SQLite compares names, never
  ///    shapes.
  /// 2. **Upgrade.** When the stored version is behind [version], [onUpgrade]
  ///    runs. This is where renames, type changes and drops are described; see
  ///    [Migrator]. It runs *before* the next pass so that a rename happens
  ///    while the old column is still there.
  /// 3. **Reconcile.** Any column a schema declares and the table lacks is
  ///    appended. This is what makes adding a nullable column need no
  ///    migration at all, and it catches the schema that changed without the
  ///    version being bumped.
  ///
  /// A database that predates versioning reports version 0, which is also what
  /// [onUpgrade] receives as `from` — "unknown, assume the oldest".
  static Future<void> _upgrade(
    RelaxDatabase database,
    List<TableSchema> schemas, {
    required int version,
    RelaxMigration? onUpgrade,
  }) async {
    // Read before creating anything: afterwards every table exists, and a
    // first launch becomes indistinguishable from an upgrade.
    final known = await _existingTables(database, schemas);
    final recorded = await _storedVersion(database);

    // No record means one of two things, and the tables tell them apart: no
    // tables at all is a first launch, already at [version]; tables without a
    // record is a database from before versioning, whose schema is anyone's
    // guess — hence 0, the oldest.
    final stored = recorded ?? (known.isEmpty ? version : 0);

    for (final schema in schemas) {
      await database.createTable(schema.toCreateTableSql());
    }

    if (stored > version) {
      throw StateError(
        'Database is at version $stored, but this build opens it at '
        '$version. Opening a database written by a newer build would read '
        'its rows with a schema that no longer describes them.',
      );
    }

    final migrator = Migrator(database);

    // A database created just now is already at [version] — there is nothing
    // to upgrade, and running migrations over empty tables would at best waste
    // work and at worst fail on columns their old shape never had.
    if (known.isNotEmpty && stored < version && onUpgrade != null) {
      await onUpgrade(migrator, stored, version);
    }

    for (final schema in schemas) {
      await _reconcile(migrator, schema);
    }

    if (recorded != version) await _setStoredVersion(database, version);
  }

  /// Appends the columns [schema] declares and its table does not have.
  static Future<void> _reconcile(Migrator migrator, TableSchema schema) async {
    final present = await migrator.columnsOf(schema.tableName);

    for (final column in schema.columns) {
      if (present.contains(column.name)) continue;

      // Loud rather than skipped: a column silently left out comes back as a
      // failed INSERT much later, far from the change that caused it.
      await migrator.addColumn(schema.tableName, column);
    }
  }

  /// Which of [schemas]' tables the database already holds.
  static Future<Set<String>> _existingTables(
    RelaxDatabase database,
    List<TableSchema> schemas,
  ) async {
    final rows = await database
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();
    final present = {for (final row in rows) row.data['name'] as String};

    return {
      for (final schema in schemas)
        if (present.contains(schema.tableName)) schema.tableName,
    };
  }

  /// The table holding the schema version, alongside `_relax_sync_queue` and
  /// `_relax_seeds`.
  ///
  /// Not `PRAGMA user_version`, tempting as the SQLite header is: Drift already
  /// keeps *its* `schemaVersion` there. Writing our number into it makes Drift
  /// read a version it never wrote, conclude the schema was bumped without a
  /// migration strategy, and refuse to open the database — and it overwrites
  /// the value on its own besides. The header is taken; we bring our own table.
  static const _versionTable = '_relax_schema';

  /// The schema version recorded in the database, or null if never recorded —
  /// which is both a brand-new database and one from before versioning. The
  /// tables tell those apart; see [_upgrade].
  static Future<int?> _storedVersion(RelaxDatabase database) async {
    // The CHECK is what keeps this a single-row table: one database, one
    // version, and no way to end up with two answers.
    await database.createTable(
      'CREATE TABLE IF NOT EXISTS $_versionTable ('
      'id INTEGER PRIMARY KEY CHECK (id = 1), '
      'version INTEGER NOT NULL)',
    );

    final rows = await database
        .customSelect('SELECT version FROM $_versionTable WHERE id = 1')
        .get();

    return rows.isEmpty ? null : rows.first.data['version'] as int?;
  }

  static Future<void> _setStoredVersion(
    RelaxDatabase database,
    int version,
  ) async {
    await database.customStatement(
      'INSERT OR REPLACE INTO $_versionTable (id, version) VALUES (1, ?)',
      [version],
    );
  }

  /// Runs a raw SQL statement that returns no rows.
  ///
  /// The escape hatch for what the typed API does not cover — a migration run
  /// by hand, an index, a `VACUUM`. Name the tables it writes in [updates], or
  /// active `watch()` streams will not learn of the change: Drift tracks the
  /// queries it builds itself, and cannot see inside raw SQL.
  Future<void> execute(
    String sql, [
    List<Object?> arguments = const [],
    Set<String> updates = const {},
  ]) async {
    await _database.customStatement(sql, arguments);
    if (updates.isNotEmpty) _database.notifyTables(updates);
  }

  /// Runs a raw SQL query and returns its rows.
  Future<List<Map<String, Object?>>> select(
    String sql, [
    List<Object?> arguments = const [],
  ]) async {
    final rows = await _database
        .customSelect(sql, variables: _database.variablesOf(arguments))
        .get();

    return rows.map((row) => row.data).toList();
  }

  /// Returns `true` if the SQLite library supports encryption
  /// (SQLite3MultipleCiphers is linked).
  ///
  /// Requires an open database. Call after [open], [openFile], or [openInMemory].
  Future<bool> isEncryptionAvailable() async {
    try {
      final rows = await _database.customSelect('PRAGMA cipher').get();
      return rows.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static DatabaseSetup? _buildSetup(String? encryptionKey, RelaxLogger logger) {
    if (encryptionKey == null) return null;
    return (rawDb) {
      // Verify cipher support before applying key.
      final cipherResult = rawDb.select('PRAGMA cipher');
      if (cipherResult.isEmpty) {
        logger.log(
          RelaxLogCategory.encryption,
          'Encryption requested but SQLite3MultipleCiphers is not available',
          level: RelaxLogLevel.error,
        );
        throw StateError(
          'Encryption requested but SQLite3MultipleCiphers is not available. '
          'Add this to your pubspec.yaml:\n'
          'hooks:\n'
          '  user_defines:\n'
          '    sqlite3:\n'
          '      source: sqlite3mc',
        );
      }
      rawDb.execute("PRAGMA key = '$encryptionKey'");
      logger.log(
        RelaxLogCategory.encryption,
        'PRAGMA key applied (cipher active)',
        level: RelaxLogLevel.info,
      );
    };
  }

  /// Inspects the raw database file on disk and reports whether the data is
  /// actually encrypted — the direct answer to "are my data really encrypted?".
  ///
  /// An unencrypted SQLite file always starts with the 16-byte magic header
  /// `"SQLite format 3 "`. If the file starts with that header it is
  /// **plaintext**; otherwise it appears to be ciphertext.
  ///
  /// Pass [file] for databases opened with [open] (where the path is resolved
  /// internally by drift_flutter). For [openFile] the file is detected
  /// automatically. In-memory databases cannot be inspected.
  ///
  /// The result is also written to the logger under
  /// [RelaxLogCategory.encryption].
  ///
  /// ```dart
  /// final check = await db.debugCheckEncryption();
  /// print(check.isEncrypted); // true when the bytes on disk are ciphertext
  /// ```
  Future<EncryptionCheck> debugCheckEncryption({File? file}) async {
    final target = file ?? _dbFile;

    EncryptionCheck emit(EncryptionCheck check) {
      logger.log(
        RelaxLogCategory.encryption,
        check.message,
        level: check.isMisconfigured ? RelaxLogLevel.error : RelaxLogLevel.info,
        details: check,
      );
      return check;
    }

    if (target == null) {
      return emit(
        EncryptionCheck(
          isEncrypted: null,
          keyRequested: _encryptionRequested,
          headerHex: '',
          message:
              'No file to inspect — pass a File '
              '(in-memory or drift_flutter-managed database).',
        ),
      );
    }
    if (!await target.exists()) {
      return emit(
        EncryptionCheck(
          isEncrypted: null,
          keyRequested: _encryptionRequested,
          headerHex: '',
          message: 'Database file does not exist: ${target.path}',
        ),
      );
    }

    final raf = await target.open();
    Uint8List header;
    try {
      header = await raf.read(16);
    } finally {
      await raf.close();
    }

    final headerHex = header
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(' ');

    // The 16-byte magic string that prefixes every unencrypted SQLite file.
    final magic = 'SQLite format 3 '.codeUnits;
    final isPlaintext =
        header.length >= magic.length &&
        List.generate(
          magic.length,
          (i) => header[i] == magic[i],
        ).every((m) => m);
    final isEncrypted = !isPlaintext;

    final String message;
    if (isPlaintext && _encryptionRequested) {
      message =
          'Data is NOT encrypted: file is plaintext SQLite even though an '
          'encryption key was provided (misconfigured).';
    } else if (isPlaintext) {
      message =
          'Data is NOT encrypted: file is plaintext SQLite '
          '(no encryption key was provided).';
    } else {
      message =
          'Data appears encrypted: file does not start with the plaintext '
          'SQLite header.';
    }

    return emit(
      EncryptionCheck(
        isEncrypted: isEncrypted,
        keyRequested: _encryptionRequested,
        headerHex: headerHex,
        message: message,
      ),
    );
  }

  TableSchema<T> _findSchema<T>() {
    final schema = _schemas[T];
    if (schema is TableSchema<T>) return schema;
    throw StateError(
      'No schema registered for type $T. '
      'Make sure you passed a TableSchema<$T> to RelaxDB.open().',
    );
  }
}
