import 'dart:developer' as developer;

/// Severity of a [RelaxLogRecord].
enum RelaxLogLevel { debug, info, warning, error }

/// The subsystem a log record originated from.
///
/// Use these to filter what you want to see via
/// [RelaxLogger.categories].
enum RelaxLogCategory {
  /// Database lifecycle: open, close, table creation.
  database,

  /// Encryption status and the on-disk encryption check.
  encryption,

  /// Create/read/update/delete operations on collections.
  crud,

  /// Queries built with [QueryBuilder].
  query,

  /// Sync engine activity: push/pull, status, conflicts.
  sync,

  /// Offline queue activity: enqueue, coalesce, retry.
  queue,
}

/// A single structured log entry emitted by RelaxORM.
class RelaxLogRecord {
  final RelaxLogLevel level;
  final RelaxLogCategory category;
  final String message;

  /// Optional structured payload (e.g. SQL, counts, a result object).
  final Object? details;
  final DateTime time;

  RelaxLogRecord({
    required this.level,
    required this.category,
    required this.message,
    this.details,
    DateTime? time,
  }) : time = time ?? DateTime.now();

  @override
  String toString() {
    final base = '[relax_orm.${category.name}] $message';
    return details == null ? base : '$base — $details';
  }
}

/// Destination for log records. Implement your own to forward records to a
/// file, a crash reporter, or an in-app console.
typedef RelaxLogSink = void Function(RelaxLogRecord record);

/// Opt-in developer logger for RelaxORM.
///
/// Logging is **disabled by default** — pass a configured instance to
/// [RelaxDB.open] (or [RelaxDB.openFile] / [RelaxDB.openInMemory]) to turn it
/// on. When disabled, every [log] call returns immediately, so there is no
/// runtime cost in production.
///
/// ```dart
/// final db = await RelaxDB.open(
///   name: 'my_app',
///   schemas: [userSchema],
///   encryptionKey: 'secret',
///   logger: const RelaxLogger(), // enabled, all categories, DevTools output
/// );
///
/// // Only show CRUD + encryption, forward to your own sink:
/// final db2 = await RelaxDB.open(
///   name: 'my_app',
///   schemas: [userSchema],
///   logger: RelaxLogger(
///     categories: {RelaxLogCategory.crud, RelaxLogCategory.encryption},
///     sink: (record) => myConsole.add(record.toString()),
///   ),
/// );
/// ```
class RelaxLogger {
  /// Whether logging is active. A [RelaxLogger.disabled] logger has this `false`.
  final bool enabled;

  /// Categories to emit. `null` means *all* categories.
  final Set<RelaxLogCategory>? categories;

  /// Minimum level to emit; records below this level are dropped.
  final RelaxLogLevel minLevel;

  /// Where records are sent. Defaults to [developerLogSink].
  final RelaxLogSink sink;

  const RelaxLogger({
    this.enabled = true,
    this.categories,
    this.minLevel = RelaxLogLevel.debug,
    RelaxLogSink? sink,
  }) : sink = sink ?? developerLogSink;

  /// A no-op logger. This is the internal default when no logger is provided.
  const RelaxLogger.disabled()
      : enabled = false,
        categories = null,
        minLevel = RelaxLogLevel.debug,
        sink = developerLogSink;

  /// Whether records in [category] at [level] would be emitted. Useful to guard
  /// the construction of an expensive [details] payload.
  bool isLoggable(RelaxLogCategory category, [RelaxLogLevel level = RelaxLogLevel.debug]) {
    if (!enabled) return false;
    if (level.index < minLevel.index) return false;
    if (categories != null && !categories!.contains(category)) return false;
    return true;
  }

  /// Emits a log record, unless logging is disabled or the record is filtered
  /// out by [categories] / [minLevel].
  void log(
    RelaxLogCategory category,
    String message, {
    RelaxLogLevel level = RelaxLogLevel.debug,
    Object? details,
  }) {
    if (!isLoggable(category, level)) return;
    sink(RelaxLogRecord(
      level: level,
      category: category,
      message: message,
      details: details,
    ));
  }
}

/// Default sink: forwards records to `dart:developer`'s `log`, which shows up in
/// the Flutter DevTools "Logging" view, grouped by `relax_orm.<category>`.
void developerLogSink(RelaxLogRecord record) {
  developer.log(
    record.details == null ? record.message : '${record.message} — ${record.details}',
    name: 'relax_orm.${record.category.name}',
    level: _developerLevel(record.level),
    time: record.time,
  );
}

/// Maps a [RelaxLogLevel] to a `dart:developer` level (roughly the
/// `package:logging` scale).
int _developerLevel(RelaxLogLevel level) {
  switch (level) {
    case RelaxLogLevel.debug:
      return 500; // FINE
    case RelaxLogLevel.info:
      return 800; // INFO
    case RelaxLogLevel.warning:
      return 900; // WARNING
    case RelaxLogLevel.error:
      return 1000; // SEVERE
  }
}

/// Result of [RelaxDB.debugCheckEncryption] — a direct answer to
/// "are my data really encrypted on disk?".
class EncryptionCheck {
  /// `true` if the file does **not** start with the plaintext SQLite header,
  /// `false` if it is plaintext. `null` when the check couldn't run (no file,
  /// in-memory database, or file doesn't exist yet).
  final bool? isEncrypted;

  /// Whether an encryption key was supplied when the database was opened.
  final bool keyRequested;

  /// Hex dump of the first bytes of the file (empty when not checked).
  final String headerHex;

  /// Human-readable explanation, also written to the log.
  final String message;

  const EncryptionCheck({
    required this.isEncrypted,
    required this.keyRequested,
    required this.headerHex,
    required this.message,
  });

  /// `true` when a key was requested but the file is still plaintext — i.e. the
  /// data is **not** actually encrypted despite the configuration.
  bool get isMisconfigured => keyRequested && isEncrypted == false;

  @override
  String toString() =>
      'EncryptionCheck(isEncrypted: $isEncrypted, keyRequested: $keyRequested, '
      'header: $headerHex, $message)';
}
