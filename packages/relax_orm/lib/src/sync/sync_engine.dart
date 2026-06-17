import 'dart:async';

import '../database/relax_database.dart';
import '../schema/table_schema.dart';
import 'conflict_resolver.dart';
import 'offline_queue.dart';
import 'sync_adapter.dart';
import 'sync_operation.dart';
import 'sync_status.dart';

/// Configuration for syncing a specific collection.
class SyncConfig<T> {
  final TableSchema<T> schema;
  final SyncAdapter<T> adapter;
  final ConflictResolver<T> conflictResolver;

  /// How often to auto-sync when online (null = manual only).
  final Duration? autoSyncInterval;

  /// Max retry attempts for failed operations.
  final int maxRetries;

  SyncConfig({
    required this.schema,
    required this.adapter,
    ConflictResolver<T>? conflictResolver,
    this.autoSyncInterval,
    this.maxRetries = 5,
  }) : conflictResolver = conflictResolver ?? ConflictResolver.remoteWins<T>();
}

/// Orchestrates offline queue processing, push/pull sync, and conflict resolution.
///
/// ```dart
/// final engine = SyncEngine(database, queue);
///
/// engine.register(SyncConfig(
///   schema: userSchema,
///   adapter: UserSyncAdapter(api),
///   autoSyncInterval: Duration(minutes: 5),
/// ));
///
/// engine.connectivityStream = myConnectivityStream;
/// engine.start();
///
/// engine.status.listen((s) => print('Sync: $s'));
/// ```
class SyncEngine {
  final RelaxDatabase _db;
  final OfflineQueue _queue;
  final Map<String, _SyncRegistration> _registrations = {};

  final _statusController = StreamController<SyncStatus>.broadcast();
  final _lastSyncTimes = <String, DateTime>{};
  final _autoSyncTimers = <String, Timer>{};

  StreamSubscription<bool>? _connectivitySub;
  bool _isOnline = true;
  final _syncingTables = <String>{};

  /// Monotonic counter guaranteeing unique operation ids even when several
  /// operations are queued within the same clock tick (the system clock can
  /// have a coarse resolution, e.g. on Windows).
  int _opSeq = 0;

  SyncEngine(this._db, this._queue);

  /// Stream of sync status changes.
  Stream<SyncStatus> get status => _statusController.stream;

  /// Whether the device is currently online.
  bool get isOnline => _isOnline;

  /// Whether a sync is currently in progress for any table.
  bool get isSyncing => _syncingTables.isNotEmpty;

  /// Sets the connectivity stream. Emits `true` when online, `false` when offline.
  ///
  /// When transitioning from offline → online, pending operations are automatically synced.
  set connectivityStream(Stream<bool> stream) {
    _connectivitySub?.cancel();
    _connectivitySub = stream.listen(_onConnectivityChanged);
  }

  /// Registers a collection for sync.
  void register<T>(SyncConfig<T> config) {
    _registrations[config.schema.tableName] = _SyncRegistration<T>(config);

    // Set up auto-sync timer if configured.
    if (config.autoSyncInterval != null) {
      _autoSyncTimers[config.schema.tableName]?.cancel();
      _autoSyncTimers[config.schema.tableName] = Timer.periodic(
        config.autoSyncInterval!,
        (_) => syncTable(config.schema.tableName),
      );
    }
  }

  /// Queues a CRUD operation for later sync.
  ///
  /// Called internally by [Collection] when sync is enabled.
  Future<void> queueOperation({
    required String tableName,
    required SyncOperationType type,
    required String entityId,
    Map<String, dynamic>? data,
  }) async {
    final op = SyncOperation(
      id: '${tableName}_${entityId}_${DateTime.now().microsecondsSinceEpoch}_${_opSeq++}',
      tableName: tableName,
      type: type,
      entityId: entityId,
      data: data,
      createdAt: DateTime.now(),
    );
    await _queue.enqueue(op);
  }

  /// Syncs a single table: pushes local changes, then pulls remote changes.
  Future<void> syncTable(String tableName) async {
    final reg = _registrations[tableName];
    if (reg == null || !_isOnline || _syncingTables.contains(tableName)) return;

    _syncingTables.add(tableName);
    _emitStatus(SyncStatus.syncing);

    // Captured before the network round-trip so changes happening on the
    // server *during* the sync aren't missed on the next pull. Used only when
    // the adapter doesn't return an authoritative [SyncPullResult.serverTime].
    final startedAt = DateTime.now();

    try {
      // Re-queue operations that previously failed but haven't exhausted their
      // retry budget, so a transient error doesn't strand them until a restart.
      await _queue.resetFailed(
        tableName: tableName,
        maxRetries: reg.config.maxRetries,
      );

      await _pushChanges(tableName, reg);
      final serverTime = await _pullChanges(tableName, reg);

      _lastSyncTimes[tableName] = serverTime ?? startedAt;
      _emitStatus(SyncStatus.synced);
    } catch (e) {
      _emitStatus(SyncStatus.error);
    } finally {
      _syncingTables.remove(tableName);
    }
  }

  /// Syncs all registered tables.
  Future<void> syncAll() async {
    for (final tableName in _registrations.keys) {
      await syncTable(tableName);
    }
  }

  /// Starts the sync engine.
  ///
  /// If online, immediately syncs all registered tables.
  Future<void> start() async {
    if (_isOnline) {
      // Each table's failed operations are reset inside syncTable using that
      // table's own maxRetries, so no global reset is needed here.
      await syncAll();
    }
  }

  /// Stops the sync engine and cancels all timers.
  void stop() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
    for (final timer in _autoSyncTimers.values) {
      timer.cancel();
    }
    _autoSyncTimers.clear();
    _emitStatus(SyncStatus.idle);
  }

  /// Disposes the engine and closes all streams.
  Future<void> dispose() async {
    stop();
    await _statusController.close();
  }

  /// Returns the number of pending operations in the queue.
  Future<int> pendingCount() => _queue.pendingCount();

  void _emitStatus(SyncStatus s) {
    if (!_statusController.isClosed) _statusController.add(s);
  }

  // -- Internal --

  Future<void> _pushChanges(String tableName, _SyncRegistration reg) async {
    final pending = await _queue.getPending(tableName);
    if (pending.isEmpty) return;

    try {
      await reg.pushOperations(_db, tableName, pending);
      await _queue.completeAll(pending.map((op) => op.id).toList());
    } catch (e) {
      for (final op in pending) {
        await _queue.markFailed(op.id);
      }
      rethrow;
    }
  }

  /// Pulls remote changes and returns the server watermark for the next sync
  /// (null if the adapter doesn't provide one).
  Future<DateTime?> _pullChanges(String tableName, _SyncRegistration reg) async {
    final since = _lastSyncTimes[tableName];
    return reg.applyPull(_db, tableName, since);
  }

  void _onConnectivityChanged(bool online) {
    final wasOffline = !_isOnline;
    _isOnline = online;

    if (online) {
      if (wasOffline) {
        // Back online — sync all pending operations. syncTable resets each
        // table's failed operations before pushing.
        _emitStatus(SyncStatus.syncing);
        syncAll();
      }
    } else {
      _emitStatus(SyncStatus.offline);
    }
  }
}

/// Internal wrapper that preserves the type parameter [T] for push/pull operations.
class _SyncRegistration<T> {
  final SyncConfig<T> config;
  _SyncRegistration(this.config);

  /// Pushes pending operations to the remote server (typed).
  ///
  /// Server-confirmed versions returned by [SyncAdapter.push] (which may carry
  /// server-assigned ids/timestamps) are written back into the local database.
  Future<void> pushOperations(
    RelaxDatabase db,
    String tableName,
    List<SyncOperation> pending,
  ) async {
    // Collapse repeated edits to the same entity into one effective op, so the
    // server gets a single write per entity instead of every offline change.
    final coalesced = SyncOperation.coalesce(pending);

    if (coalesced.upserts.isNotEmpty) {
      final entities = coalesced.upserts
          .where((op) => op.data != null)
          .map((op) => config.schema.rowToEntity(op.data!))
          .toList();
      if (entities.isNotEmpty) {
        final confirmed = await config.adapter.push(entities);
        if (confirmed.isNotEmpty) {
          await db.transaction(() async {
            for (final entity in confirmed) {
              await _writeLocal(db, tableName, entity);
            }
          });
        }
      }
    }

    if (coalesced.deletes.isNotEmpty) {
      final ids = coalesced.deletes.map((op) => op.entityId).toList();
      await config.adapter.pushDeletes(ids);
    }
  }

  /// Pulls remote changes and applies them locally with conflict resolution.
  ///
  /// All local writes run in a single transaction so a mid-pull failure can't
  /// leave the database in a partially-synced state. Returns the server
  /// watermark to use for the next pull, if the adapter provides one.
  Future<DateTime?> applyPull(
    RelaxDatabase db,
    String tableName,
    DateTime? since,
  ) async {
    final result = await config.adapter.pull(since: since);
    final pk = config.schema.primaryKey;

    await db.transaction(() async {
      for (final T remoteEntity in result.upserts) {
        await _writeLocal(
          db,
          tableName,
          remoteEntity,
          resolver: config.conflictResolver,
        );
      }

      for (final deletedId in result.deletedIds) {
        await db.rawDelete(
          tableName,
          where: '${pk.name} = ?',
          whereArgs: [pk.toSql(deletedId)],
        );
      }
    });

    return result.serverTime;
  }

  /// Upserts [remote] into the local table.
  ///
  /// When a [resolver] is given and a local row already exists, the conflict is
  /// resolved before writing. Without a resolver the remote value is treated as
  /// authoritative (used for server-confirmed pushes).
  Future<void> _writeLocal(
    RelaxDatabase db,
    String tableName,
    T remote, {
    ConflictResolver<T>? resolver,
  }) async {
    final schema = config.schema;
    final pk = schema.primaryKey;
    final id = schema.getPrimaryKeyValue(remote);

    final localRow = await db.rawSelectOne(
      tableName,
      where: '${pk.name} = ?',
      whereArgs: [pk.toSql(id)],
    );

    if (localRow != null) {
      final T toWrite = resolver != null
          ? resolver.resolve(schema.rowToEntity(localRow), remote)
          : remote;
      final row = schema.entityToRow(toWrite);
      row.remove(pk.name);
      await db.rawUpdate(
        tableName,
        row,
        where: '${pk.name} = ?',
        whereArgs: [pk.toSql(id)],
      );
    } else {
      await db.rawInsert(tableName, schema.entityToRow(remote));
    }
  }
}

