import 'dart:convert';

import '../database/relax_database.dart';
import 'sync_operation.dart';
import 'sync_status.dart';

/// Persists pending sync operations in an internal SQLite table.
///
/// Operations are stored in `_relax_sync_queue` and replayed by the [SyncEngine]
/// when connectivity is restored.
class OfflineQueue {
  static const _table = '_relax_sync_queue';

  final RelaxDatabase _db;

  OfflineQueue(this._db);

  /// Creates the internal queue table if it doesn't exist.
  Future<void> init() async {
    await _db.createTable('''
      CREATE TABLE IF NOT EXISTS $_table (
        id TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        data TEXT,
        created_at INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        retry_count INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  /// Enqueues a new operation, coalescing it into the existing *pending*
  /// operation for the same entity when there is one.
  ///
  /// This keeps the on-disk queue at one row per entity instead of growing with
  /// every offline edit. The merge keeps the original row id and `created_at`
  /// (so cross-entity ordering stays stable) and applies the same folding rules
  /// as [SyncOperation.coalesce]:
  ///
  /// - `add` then `update*`  ⇒ a single `add` carrying the latest data
  /// - `update*`             ⇒ a single `update` carrying the latest data
  /// - `add` then `delete`   ⇒ the row is removed entirely (never sent)
  /// - `update` then `delete`⇒ `delete`
  /// - `delete` then `add`   ⇒ `update` (re-creation)
  ///
  /// Operations that are already `failed`/`syncing` are never merged into — a
  /// new row is inserted instead, and [SyncOperation.coalesce] folds them at
  /// push time once they are reset to `pending`.
  Future<void> enqueue(SyncOperation op) async {
    await _db.transaction(() async {
      final existing = await _pendingForEntity(op.tableName, op.entityId);
      if (existing == null) {
        await _db.rawInsert(_table, _toRow(op));
        return;
      }

      final merged = _merge(existing, op);
      // Always drop the old pending row; it's either replaced or cancelled out.
      await _db.rawDelete(_table, where: 'id = ?', whereArgs: [existing.id]);
      if (merged != null) {
        await _db.rawInsert(_table, _toRow(merged));
      }
    });
  }

  /// Returns the earliest pending operation for an entity, or null if none.
  Future<SyncOperation?> _pendingForEntity(
    String tableName,
    String entityId,
  ) async {
    final rows = await _db.rawSelect(
      _table,
      where: "table_name = ? AND entity_id = ? AND status = 'pending'",
      whereArgs: [tableName, entityId],
      orderBy: 'created_at ASC',
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  /// Folds [next] into the existing pending [prev], or returns null when the two
  /// cancel out (`add` then `delete`). The result reuses [prev]'s id and
  /// `created_at`.
  SyncOperation? _merge(SyncOperation prev, SyncOperation next) {
    switch (next.type) {
      case SyncOperationType.add:
        return _replace(
          prev,
          // delete → add re-creates an entity the server still has.
          type: prev.type == SyncOperationType.delete
              ? SyncOperationType.update
              : SyncOperationType.add,
          data: next.data,
        );
      case SyncOperationType.update:
        return _replace(
          prev,
          // Preserve `add` semantics if the entity was created while offline.
          type: prev.type == SyncOperationType.add
              ? SyncOperationType.add
              : SyncOperationType.update,
          data: next.data,
        );
      case SyncOperationType.delete:
        // add → delete: the server never knew about it; drop the row.
        if (prev.type == SyncOperationType.add) return null;
        return _replace(prev, type: SyncOperationType.delete, data: null);
    }
  }

  SyncOperation _replace(
    SyncOperation prev, {
    required SyncOperationType type,
    required Map<String, dynamic>? data,
  }) {
    return SyncOperation(
      id: prev.id,
      tableName: prev.tableName,
      type: type,
      entityId: prev.entityId,
      data: data,
      createdAt: prev.createdAt,
      // A freshly merged op should be retried cleanly.
      status: OperationStatus.pending,
      retryCount: 0,
    );
  }

  /// Returns all pending operations for a given table, ordered by creation time.
  Future<List<SyncOperation>> getPending(String tableName) async {
    final rows = await _db.rawSelect(
      _table,
      where: "table_name = ? AND status = 'pending'",
      whereArgs: [tableName],
      orderBy: 'created_at ASC',
    );
    return rows.map(_fromRow).toList();
  }

  /// Returns all pending operations across all tables.
  Future<List<SyncOperation>> getAllPending() async {
    final rows = await _db.rawSelect(
      _table,
      where: "status = 'pending'",
      whereArgs: [],
      orderBy: 'created_at ASC',
    );
    return rows.map(_fromRow).toList();
  }

  /// Marks an operation as completed and removes it from the queue.
  Future<void> complete(String operationId) async {
    await _db.rawDelete(
      _table,
      where: 'id = ?',
      whereArgs: [operationId],
    );
  }

  /// Marks multiple operations as completed.
  Future<void> completeAll(List<String> operationIds) async {
    for (final id in operationIds) {
      await complete(id);
    }
  }

  /// Marks an operation as failed and increments its retry count.
  Future<void> markFailed(String operationId) async {
    await _db.customStatement(
      'UPDATE $_table SET status = ?, retry_count = retry_count + 1 WHERE id = ?',
      ['failed', operationId],
    );
  }

  /// Resets failed operations back to pending so they'll be retried.
  ///
  /// Operations whose [retryCount] has reached [maxRetries] are left in the
  /// `failed` state (dead-letter) and not retried. If [tableName] is provided,
  /// only that table's operations are reset.
  Future<void> resetFailed({String? tableName, int maxRetries = 5}) async {
    final where = StringBuffer("status = 'failed' AND retry_count < ?");
    final args = <Object?>[maxRetries];
    if (tableName != null) {
      where.write(' AND table_name = ?');
      args.add(tableName);
    }
    await _db.customStatement(
      "UPDATE $_table SET status = 'pending' WHERE $where",
      args,
    );
  }

  /// Returns the number of pending operations.
  Future<int> pendingCount() async {
    return _db.rawCount("$_table WHERE status = 'pending'");
  }

  /// Clears all operations from the queue.
  Future<void> clear() async {
    await _db.rawDelete(_table, where: '1 = 1', whereArgs: []);
  }

  // -- Serialization --

  Map<String, Object?> _toRow(SyncOperation op) {
    return {
      'id': op.id,
      'table_name': op.tableName,
      'type': op.type.name,
      'entity_id': op.entityId,
      'data': op.data != null ? jsonEncode(op.data) : null,
      'created_at': op.createdAt.millisecondsSinceEpoch,
      'status': op.status.name,
      'retry_count': op.retryCount,
    };
  }

  SyncOperation _fromRow(Map<String, dynamic> row) {
    return SyncOperation(
      id: row['id'] as String,
      tableName: row['table_name'] as String,
      type: SyncOperationType.values.byName(row['type'] as String),
      entityId: row['entity_id'] as String,
      data: row['data'] != null
          ? jsonDecode(row['data'] as String) as Map<String, dynamic>
          : null,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      status: OperationStatus.values.byName(row['status'] as String),
      retryCount: row['retry_count'] as int,
    );
  }
}
