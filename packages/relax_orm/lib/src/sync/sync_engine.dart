import 'dart:async';

import '../database/relax_database.dart';
import '../logging/relax_logger.dart';
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

  /// Resolves local↔remote conflicts when applying a **pull** (`applyPull`).
  ///
  /// Note the deliberate asymmetry: this resolver runs only for entities
  /// arriving from a pull. Entities written back after a successful **push**
  /// (the server-confirmed versions returned by [SyncAdapter.push]) are treated
  /// as authoritative and overwrite the local row *without* consulting the
  /// resolver — a confirmed push already reflects the server's accepted state.
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
    int schemaVersion = 0,
  }) async {
    final op = SyncOperation(
      id: '${tableName}_${entityId}_${DateTime.now().microsecondsSinceEpoch}_${_opSeq++}',
      tableName: tableName,
      type: type,
      entityId: entityId,
      data: data,
      createdAt: DateTime.now(),
      schemaVersion: schemaVersion,
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
      _db.logger.log(
        RelaxLogCategory.sync,
        'syncTable $tableName failed',
        level: RelaxLogLevel.error,
        details: e,
      );
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
    _db.logger.log(RelaxLogCategory.sync, 'status: ${s.name}');
  }

  // -- Internal --

  Future<void> _pushChanges(String tableName, _SyncRegistration reg) async {
    final pending = await _queue.getPending(tableName);
    if (pending.isEmpty) return;

    // Drop operations whose recorded schema version no longer matches the
    // current schema: their SQL-encoded payload can't be safely decoded with
    // today's column types. Version 0 means "unspecified" (legacy/delete) and
    // is always kept.
    final currentVersion = reg.schemaVersion;
    final stale = pending
        .where((op) =>
            op.schemaVersion != 0 && op.schemaVersion != currentVersion)
        .toList();
    if (stale.isNotEmpty) {
      _db.logger.log(
        RelaxLogCategory.sync,
        'discarding ${stale.length} stale-schema op(s) on $tableName '
        '(schema v$currentVersion)',
        level: RelaxLogLevel.warning,
      );
      await _queue.completeAll(stale.map((op) => op.id).toList());
    }
    final live = pending.where((op) => !stale.contains(op)).toList();
    if (live.isEmpty) return;

    _db.logger.log(
      RelaxLogCategory.sync,
      'push $tableName (${live.length} pending op(s))',
    );
    try {
      // Only operations whose entity was explicitly confirmed by the adapter
      // are removed from the queue. Anything unconfirmed stays pending and is
      // retried on the next sync, so a partial server-side success never
      // silently drops an unsynced change.
      final confirmedIds = await reg.pushOperations(_db, tableName, live);
      await _queue.completeAll(confirmedIds.toList());

      final unconfirmed =
          live.where((op) => !confirmedIds.contains(op.id)).length;
      if (unconfirmed > 0) {
        _db.logger.log(
          RelaxLogCategory.sync,
          'push $tableName: $unconfirmed op(s) left pending (unconfirmed by '
          'server) — will retry next sync',
          level: RelaxLogLevel.warning,
        );
      }
    } catch (e) {
      _db.logger.log(
        RelaxLogCategory.sync,
        'push $tableName failed — marking ${live.length} op(s) failed',
        level: RelaxLogLevel.warning,
        details: e,
      );
      for (final op in live) {
        await _queue.markFailed(op.id);
      }
      rethrow;
    }
  }

  /// Pulls remote changes and returns the server watermark for the next sync
  /// (null if the adapter doesn't provide one).
  Future<DateTime?> _pullChanges(
    String tableName,
    _SyncRegistration reg,
  ) async {
    final since = _lastSyncTimes[tableName];
    _db.logger.log(RelaxLogCategory.sync, 'pull $tableName (since: $since)');
    return reg.applyPull(_db, tableName, since);
  }

  void _onConnectivityChanged(bool online) {
    final wasOffline = !_isOnline;
    _isOnline = online;
    _db.logger.log(
      RelaxLogCategory.sync,
      'connectivity: ${online ? 'online' : 'offline'}',
    );

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

  /// Current schema version for this registration's table.
  int get schemaVersion => config.schema.version;

  /// Pushes pending operations to the remote server (typed) and returns the ids
  /// of the [pending] operations whose entity the server confirmed.
  ///
  /// Confirmation is matched by primary key: every queued operation for an
  /// entity the adapter returns from [SyncAdapter.push] / [SyncAdapter.pushDeletes]
  /// is reported as confirmed. Operations that coalesced away (e.g. an offline
  /// add-then-delete that never reached the server) are confirmed too, since
  /// there is nothing left to send. Anything else is left for the caller to
  /// retry. Server-confirmed upsert versions (which may carry server-assigned
  /// ids/timestamps) are written back into the local database.
  Future<Set<String>> pushOperations(
    RelaxDatabase db,
    String tableName,
    List<SyncOperation> pending,
  ) async {
    // Collapse repeated edits to the same entity into one effective op, so the
    // server gets a single write per entity instead of every offline change.
    final coalesced = SyncOperation.coalesce(pending);

    // Map each entity to all of its queued operation ids (coalescing folded
    // several rows into one effective op, but every original row must be cleared
    // once the entity is confirmed).
    final opIdsByEntity = <String, List<String>>{};
    for (final op in pending) {
      opIdsByEntity.putIfAbsent(op.entityId, () => []).add(op.id);
    }

    final confirmed = <String>{};

    // Entities with no effective op left (add→delete) have nothing to push.
    final liveEntityIds = <String>{
      ...coalesced.upserts.map((op) => op.entityId),
      ...coalesced.deletes.map((op) => op.entityId),
    };
    for (final entry in opIdsByEntity.entries) {
      if (!liveEntityIds.contains(entry.key)) confirmed.addAll(entry.value);
    }

    if (coalesced.upserts.isNotEmpty) {
      final entities = coalesced.upserts
          .where((op) => op.data != null)
          .map((op) => config.schema.rowToEntity(op.data!))
          .toList();
      if (entities.isNotEmpty) {
        final serverConfirmed = await config.adapter.push(entities);
        if (serverConfirmed.isNotEmpty) {
          await db.transaction(() async {
            for (final entity in serverConfirmed) {
              await _writeLocal(db, tableName, entity);
            }
          });
          for (final entity in serverConfirmed) {
            final entityId = config.schema.getPrimaryKeyValue(entity).toString();
            final ids = opIdsByEntity[entityId];
            if (ids != null) confirmed.addAll(ids);
          }
        }
      }
    }

    if (coalesced.deletes.isNotEmpty) {
      final ids = coalesced.deletes.map((op) => op.entityId).toList();
      final confirmedDeletes = await config.adapter.pushDeletes(ids);
      for (final id in confirmedDeletes) {
        final ids = opIdsByEntity[id.toString()];
        if (ids != null) confirmed.addAll(ids);
      }
    }

    return confirmed;
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

    db.logger.log(
      RelaxLogCategory.sync,
      'pull $tableName applied: ${result.upserts.length} upsert(s), '
      '${result.deletedIds.length} delete(s)',
    );
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
      if (resolver != null) {
        db.logger.log(
          RelaxLogCategory.sync,
          'conflict resolved on $tableName (id: $id)',
        );
      }
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
