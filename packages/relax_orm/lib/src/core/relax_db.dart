import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../database/relax_database.dart';
import '../logging/relax_logger.dart';
import '../schema/table_schema.dart';
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
  })  : _encryptionRequested = encryptionRequested,
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
  static Future<RelaxDB> open({
    required String name,
    required List<TableSchema> schemas,
    String? encryptionKey,
    RelaxLogger? logger,
  }) async {
    final log = logger ?? const RelaxLogger.disabled();
    final executor = driftDatabase(
      name: name,
      native: DriftNativeOptions(
        setup: _buildSetup(encryptionKey, log),
      ),
    );

    return _init(
      RelaxDatabase(executor, logger: log),
      schemas,
      encryptionRequested: encryptionKey != null,
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
  }) async {
    final log = logger ?? const RelaxLogger.disabled();
    final nativeDb = NativeDatabase.memory();
    return _init(RelaxDatabase(nativeDb, logger: log), schemas);
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
  }) async {
    for (final schema in schemas) {
      await database.createTable(schema.toCreateTableSql());
    }

    final schemaMap = <Type, TableSchema>{};
    for (final schema in schemas) {
      schemaMap[schema.runtimeType] = schema;
    }

    final db = RelaxDB._(
      database,
      schemaMap,
      encryptionRequested: encryptionRequested,
      dbFile: dbFile,
    );

    final log = database.logger;
    if (log.isLoggable(RelaxLogCategory.database, RelaxLogLevel.info)) {
      log.log(RelaxLogCategory.database,
          'Database opened (${schemas.length} schema(s))',
          level: RelaxLogLevel.info);
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
      logger.log(RelaxLogCategory.encryption, 'PRAGMA key applied (cipher active)',
          level: RelaxLogLevel.info);
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
        level: check.isMisconfigured
            ? RelaxLogLevel.error
            : RelaxLogLevel.info,
        details: check,
      );
      return check;
    }

    if (target == null) {
      return emit(EncryptionCheck(
        isEncrypted: null,
        keyRequested: _encryptionRequested,
        headerHex: '',
        message: 'No file to inspect — pass a File '
            '(in-memory or drift_flutter-managed database).',
      ));
    }
    if (!await target.exists()) {
      return emit(EncryptionCheck(
        isEncrypted: null,
        keyRequested: _encryptionRequested,
        headerHex: '',
        message: 'Database file does not exist: ${target.path}',
      ));
    }

    final raf = await target.open();
    Uint8List header;
    try {
      header = await raf.read(16);
    } finally {
      await raf.close();
    }

    final headerHex =
        header.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');

    // The 16-byte magic string that prefixes every unencrypted SQLite file.
    final magic = 'SQLite format 3 '.codeUnits;
    final isPlaintext = header.length >= magic.length &&
        List.generate(magic.length, (i) => header[i] == magic[i])
            .every((m) => m);
    final isEncrypted = !isPlaintext;

    final String message;
    if (isPlaintext && _encryptionRequested) {
      message = 'Data is NOT encrypted: file is plaintext SQLite even though an '
          'encryption key was provided (misconfigured).';
    } else if (isPlaintext) {
      message = 'Data is NOT encrypted: file is plaintext SQLite '
          '(no encryption key was provided).';
    } else {
      message = 'Data appears encrypted: file does not start with the plaintext '
          'SQLite header.';
    }

    return emit(EncryptionCheck(
      isEncrypted: isEncrypted,
      keyRequested: _encryptionRequested,
      headerHex: headerHex,
      message: message,
    ));
  }

  TableSchema<T> _findSchema<T>() {
    for (final schema in _schemas.values) {
      if (schema is TableSchema<T>) return schema;
    }
    throw StateError(
      'No schema registered for type $T. '
      'Make sure you passed a TableSchema<$T> to RelaxDB.open().',
    );
  }
}
