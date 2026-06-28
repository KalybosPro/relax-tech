import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relax_orm/relax_orm.dart';
import 'package:relax_orm/src/database/relax_database.dart';
import 'package:relax_orm/src/sync/offline_queue.dart';

// -- Test model --

class Task {
  final String id;
  final String title;
  final bool done;

  Task({required this.id, required this.title, this.done = false});

  Task copyWith({String? title, bool? done}) =>
      Task(id: id, title: title ?? this.title, done: done ?? this.done);
}

final taskSchema = TableSchema<Task>(
  tableName: 'tasks',
  columns: [
    ColumnDef.text('id', isPrimaryKey: true),
    ColumnDef.text('title'),
    ColumnDef.boolean('done'),
  ],
  fromMap: (m) => Task(
    id: m['id'] as String,
    title: m['title'] as String,
    done: m['done'] as bool,
  ),
  toMap: (t) => {'id': t.id, 'title': t.title, 'done': t.done},
);

// -- Mock SyncAdapter --

class MockSyncAdapter implements SyncAdapter<Task> {
  final List<Task> pushedEntities = [];
  final List<Object> pushedDeletes = [];
  int pushCallCount = 0;
  int pullCallCount = 0;

  SyncPullResult<Task> nextPullResult =
      SyncPullResult<Task>(upserts: [], deletedIds: []);

  Object? pushError;

  /// Overrides what [push] returns (server-confirmed versions). Defaults to
  /// echoing the pushed entities.
  List<Task>? pushReturns;

  /// Overrides what [pushDeletes] returns (server-confirmed ids). Defaults to
  /// echoing the requested ids.
  List<Object>? pushDeletesReturns;

  /// The `since` watermark received on the most recent [pull].
  DateTime? lastSince;

  @override
  Future<List<Task>> push(List<Task> entities) async {
    pushCallCount++;
    if (pushError != null) throw pushError!;
    pushedEntities.addAll(entities);
    return pushReturns ?? entities;
  }

  @override
  Future<List<Object>> pushDeletes(List<Object> ids) async {
    pushCallCount++;
    if (pushError != null) throw pushError!;
    pushedDeletes.addAll(ids);
    return pushDeletesReturns ?? ids;
  }

  @override
  Future<SyncPullResult<Task>> pull({DateTime? since}) async {
    pullCallCount++;
    lastSince = since;
    return nextPullResult;
  }
}

// -- Regression model with a DateTime field (offline-queue JSON safety) --

class Event {
  final String id;
  final String name;
  final DateTime at;

  Event({required this.id, required this.name, required this.at});
}

final eventSchema = TableSchema<Event>(
  tableName: 'events',
  columns: [
    ColumnDef.text('id', isPrimaryKey: true),
    ColumnDef.text('name'),
    ColumnDef.dateTime('at'),
  ],
  fromMap: (m) => Event(
    id: m['id'] as String,
    name: m['name'] as String,
    at: m['at'] as DateTime,
  ),
  toMap: (e) => {'id': e.id, 'name': e.name, 'at': e.at},
);

class MockEventAdapter implements SyncAdapter<Event> {
  final List<Event> pushed = [];

  @override
  Future<List<Event>> push(List<Event> entities) async {
    pushed.addAll(entities);
    return entities;
  }

  @override
  Future<List<Object>> pushDeletes(List<Object> ids) async => ids;

  @override
  Future<SyncPullResult<Event>> pull({DateTime? since}) async =>
      SyncPullResult<Event>();
}

// -- Tests --

void main() {
  // -- OfflineQueue tests (uses raw RelaxDatabase) --

  group('OfflineQueue', () {
    late RelaxDatabase rawDb;
    late OfflineQueue queue;

    setUp(() async {
      rawDb = RelaxDatabase(NativeDatabase.memory());
      queue = OfflineQueue(rawDb);
      await queue.init();
    });

    tearDown(() async {
      await rawDb.close();
    });

    test('enqueue and retrieve pending operations', () async {
      await queue.enqueue(SyncOperation(
        id: 'op1',
        tableName: 'tasks',
        type: SyncOperationType.add,
        entityId: '1',
        data: {'id': '1', 'title': 'Test', 'done': false},
        createdAt: DateTime.now(),
      ));

      final pending = await queue.getPending('tasks');
      expect(pending.length, 1);
      expect(pending.first.entityId, '1');
      expect(pending.first.type, SyncOperationType.add);
    });

    test('complete removes operation', () async {
      await queue.enqueue(SyncOperation(
        id: 'op1',
        tableName: 'tasks',
        type: SyncOperationType.add,
        entityId: '1',
        createdAt: DateTime.now(),
      ));

      await queue.complete('op1');
      final pending = await queue.getPending('tasks');
      expect(pending, isEmpty);
    });

    test('getAllPending returns ops across tables', () async {
      await queue.enqueue(SyncOperation(
        id: 'op1',
        tableName: 'tasks',
        type: SyncOperationType.add,
        entityId: '1',
        createdAt: DateTime.now(),
      ));
      await queue.enqueue(SyncOperation(
        id: 'op2',
        tableName: 'other',
        type: SyncOperationType.update,
        entityId: '2',
        createdAt: DateTime.now(),
      ));

      final all = await queue.getAllPending();
      expect(all.length, 2);
    });

    test('clear removes all operations', () async {
      await queue.enqueue(SyncOperation(
        id: 'op1',
        tableName: 'tasks',
        type: SyncOperationType.add,
        entityId: '1',
        createdAt: DateTime.now(),
      ));
      await queue.clear();
      expect(await queue.getAllPending(), isEmpty);
    });

    test('clear(tableName) only purges the given table (SY-4)', () async {
      await queue.enqueue(SyncOperation(
        id: 'op1',
        tableName: 'tasks',
        type: SyncOperationType.add,
        entityId: '1',
        createdAt: DateTime.now(),
      ));
      await queue.enqueue(SyncOperation(
        id: 'op2',
        tableName: 'other',
        type: SyncOperationType.add,
        entityId: '2',
        createdAt: DateTime.now(),
      ));

      await queue.clear(tableName: 'tasks');

      expect(await queue.getPending('tasks'), isEmpty);
      expect(await queue.getPending('other'), hasLength(1));
    });

    test('data round-trips through JSON serialization', () async {
      final data = {'id': '1', 'title': 'JSON test', 'done': true};
      await queue.enqueue(SyncOperation(
        id: 'op1',
        tableName: 'tasks',
        type: SyncOperationType.add,
        entityId: '1',
        data: data,
        createdAt: DateTime(2024, 6, 15),
      ));

      final pending = await queue.getPending('tasks');
      expect(pending.first.data, data);
      expect(pending.first.createdAt, DateTime(2024, 6, 15));
    });

    // -- Storage coalescing (one row per entity) --

    SyncOperation op(
      SyncOperationType type,
      String entityId,
      int order, {
      Map<String, dynamic>? data,
    }) =>
        SyncOperation(
          id: 'op${entityId}_$order',
          tableName: 'tasks',
          type: type,
          entityId: entityId,
          data: data,
          createdAt: DateTime(2024).add(Duration(seconds: order)),
        );

    test('add then update collapses to one pending add row', () async {
      await queue.enqueue(op(SyncOperationType.add, '1', 0, data: {'v': 'a'}));
      await queue.enqueue(op(SyncOperationType.update, '1', 1, data: {'v': 'b'}));

      final pending = await queue.getPending('tasks');
      expect(pending.length, 1);
      expect(pending.single.type, SyncOperationType.add);
      expect(pending.single.data, {'v': 'b'});
    });

    test('add then delete removes the row entirely', () async {
      await queue.enqueue(op(SyncOperationType.add, '1', 0));
      await queue.enqueue(op(SyncOperationType.delete, '1', 1));

      expect(await queue.getPending('tasks'), isEmpty);
    });

    test('update then delete collapses to a delete', () async {
      await queue.enqueue(op(SyncOperationType.update, '1', 0));
      await queue.enqueue(op(SyncOperationType.delete, '1', 1));

      final pending = await queue.getPending('tasks');
      expect(pending.single.type, SyncOperationType.delete);
    });

    test('merge keeps the original row id and created_at', () async {
      await queue.enqueue(op(SyncOperationType.add, '1', 0, data: {'v': 'a'}));
      await queue.enqueue(op(SyncOperationType.update, '1', 5, data: {'v': 'b'}));

      final pending = await queue.getPending('tasks');
      expect(pending.single.id, 'op1_0');
      expect(pending.single.createdAt, DateTime(2024));
    });

    test('different entities are not merged', () async {
      await queue.enqueue(op(SyncOperationType.add, '1', 0));
      await queue.enqueue(op(SyncOperationType.add, '2', 1));
      await queue.enqueue(op(SyncOperationType.update, '1', 2));

      final pending = await queue.getPending('tasks');
      expect(pending.length, 2);
    });

    test('a failed op is not merged into; a new row is added instead', () async {
      await queue.enqueue(op(SyncOperationType.add, '1', 0));
      await queue.markFailed('op1_0');

      await queue.enqueue(op(SyncOperationType.update, '1', 1));

      // The failed row is untouched; the new pending op is separate.
      final pending = await queue.getPending('tasks');
      expect(pending.length, 1);
      expect(pending.single.type, SyncOperationType.update);
      expect(await queue.getAllPending(), hasLength(1));
    });
  });

  // -- SyncEngine tests --

  group('SyncEngine', () {
    late RelaxDB db;
    late SyncEngine engine;
    late MockSyncAdapter adapter;

    setUp(() async {
      db = await RelaxDB.openInMemory(schemas: [taskSchema]);
      engine = await db.sync;
      adapter = MockSyncAdapter();
      engine.register(SyncConfig<Task>(
        schema: taskSchema,
        adapter: adapter,
      ));
    });

    tearDown(() async {
      await db.close();
    });

    test('queueOperation stores operation in queue', () async {
      await engine.queueOperation(
        tableName: 'tasks',
        type: SyncOperationType.add,
        entityId: '1',
        data: {'id': '1', 'title': 'Test', 'done': false},
      );

      expect(await engine.pendingCount(), greaterThan(0));
    });

    test('syncTable pushes pending operations', () async {
      // Queue an operation directly on the engine (bypassing collection).
      await engine.queueOperation(
        tableName: 'tasks',
        type: SyncOperationType.add,
        entityId: '1',
        data: {'id': '1', 'title': 'Push me', 'done': false},
      );

      await engine.syncTable('tasks');

      expect(adapter.pushedEntities.length, 1);
      expect(adapter.pushedEntities.first.title, 'Push me');
      expect(await engine.pendingCount(), 0);
    });

    test('syncTable pushes delete operations', () async {
      await engine.queueOperation(
        tableName: 'tasks',
        type: SyncOperationType.delete,
        entityId: '42',
      );

      await engine.syncTable('tasks');

      expect(adapter.pushedDeletes, contains('42'));
    });

    test('syncTable pulls remote changes into local DB', () async {
      adapter.nextPullResult = SyncPullResult<Task>(
        upserts: [Task(id: 'remote1', title: 'From server')],
        deletedIds: [],
      );

      await engine.syncTable('tasks');

      final tasks = db.collection<Task>();
      final result = await tasks.get('remote1');
      expect(result, isNotNull);
      expect(result!.title, 'From server');
    });

    test('pull with conflict uses remoteWins by default', () async {
      // Use a separate DB without sync to add local data without queuing.
      final db2 = await RelaxDB.openInMemory(schemas: [taskSchema]);
      await db2.collection<Task>().add(Task(id: '1', title: 'Local version'));

      // Set up engine on db2.
      final engine2 = await db2.sync;
      final adapter2 = MockSyncAdapter();
      adapter2.nextPullResult = SyncPullResult<Task>(
        upserts: [Task(id: '1', title: 'Remote version')],
        deletedIds: [],
      );
      engine2.register(SyncConfig<Task>(
        schema: taskSchema,
        adapter: adapter2,
      ));

      await engine2.syncTable('tasks');

      final result = await db2.collection<Task>().get('1');
      expect(result!.title, 'Remote version');

      await db2.close();
    });

    test('pull with localWins resolver keeps local data', () async {
      final db2 = await RelaxDB.openInMemory(schemas: [taskSchema]);
      await db2.collection<Task>().add(Task(id: '1', title: 'Local version'));

      final engine2 = await db2.sync;
      final adapter2 = MockSyncAdapter();
      adapter2.nextPullResult = SyncPullResult<Task>(
        upserts: [Task(id: '1', title: 'Remote version')],
        deletedIds: [],
      );
      engine2.register(SyncConfig<Task>(
        schema: taskSchema,
        adapter: adapter2,
        conflictResolver: ConflictResolver.localWins<Task>(),
      ));

      await engine2.syncTable('tasks');

      final result = await db2.collection<Task>().get('1');
      expect(result!.title, 'Local version');

      await db2.close();
    });

    test('pull deletes remove local entities', () async {
      final db2 = await RelaxDB.openInMemory(schemas: [taskSchema]);
      await db2.collection<Task>().add(Task(id: '1', title: 'To be deleted'));

      final engine2 = await db2.sync;
      final adapter2 = MockSyncAdapter();
      adapter2.nextPullResult = SyncPullResult<Task>(
        upserts: [],
        deletedIds: ['1'],
      );
      engine2.register(SyncConfig<Task>(
        schema: taskSchema,
        adapter: adapter2,
      ));

      await engine2.syncTable('tasks');

      expect(await db2.collection<Task>().get('1'), isNull);

      await db2.close();
    });

    test('status stream emits syncing then synced', () async {
      final statuses = <SyncStatus>[];
      engine.status.listen(statuses.add);

      await engine.syncTable('tasks');
      await Future.delayed(Duration(milliseconds: 50));

      expect(statuses, contains(SyncStatus.syncing));
      expect(statuses, contains(SyncStatus.synced));
    });

    test('connectivity offline→online triggers sync', () async {
      final controller = StreamController<bool>.broadcast();
      engine.connectivityStream = controller.stream;

      // Go offline.
      controller.add(false);
      await Future.delayed(Duration(milliseconds: 20));

      // Queue while offline.
      await engine.queueOperation(
        tableName: 'tasks',
        type: SyncOperationType.add,
        entityId: '1',
        data: {'id': '1', 'title': 'Queued offline', 'done': false},
      );

      // Go online — should trigger sync.
      controller.add(true);
      await Future.delayed(Duration(milliseconds: 200));

      expect(adapter.pushCallCount, greaterThan(0));
      expect(adapter.pushedEntities.first.title, 'Queued offline');

      await controller.close();
    });

    test('collection.add queues sync operation', () async {
      final tasks = db.collection<Task>();
      await tasks.add(Task(id: '1', title: 'Auto queued'));

      expect(await engine.pendingCount(), greaterThan(0));

      // Sync to verify the queued operation is valid.
      await engine.syncTable('tasks');
      expect(adapter.pushedEntities.any((t) => t.title == 'Auto queued'), isTrue);
    });
  });

  // -- ConflictResolver tests --

  group('ConflictResolver', () {
    test('remoteWins returns remote', () {
      final resolver = ConflictResolver.remoteWins<Task>();
      final result = resolver.resolve(
        Task(id: '1', title: 'local'),
        Task(id: '1', title: 'remote'),
      );
      expect(result.title, 'remote');
    });

    test('localWins returns local', () {
      final resolver = ConflictResolver.localWins<Task>();
      final result = resolver.resolve(
        Task(id: '1', title: 'local'),
        Task(id: '1', title: 'remote'),
      );
      expect(result.title, 'local');
    });

    test('custom resolver applies custom logic', () {
      final resolver = ConflictResolver<Task>.custom((local, remote) {
        return Task(id: local.id, title: '${local.title}+${remote.title}');
      });
      final result = resolver.resolve(
        Task(id: '1', title: 'A'),
        Task(id: '1', title: 'B'),
      );
      expect(result.title, 'A+B');
    });
  });

  // -- Regression tests for the sync fixes --

  group('sync regressions', () {
    test('entities with DateTime fields survive the offline queue', () async {
      final db = await RelaxDB.openInMemory(schemas: [eventSchema]);
      final engine = await db.sync;
      final adapter = MockEventAdapter();
      engine.register(SyncConfig<Event>(schema: eventSchema, adapter: adapter));

      final at = DateTime(2026, 6, 17, 10, 30);
      // Previously threw JsonUnsupportedObjectError on enqueue (DateTime).
      await db.collection<Event>().add(Event(id: 'e1', name: 'Launch', at: at));
      expect(await engine.pendingCount(), 1);

      await engine.syncTable('events');
      expect(adapter.pushed.single.at, at);

      await db.close();
    });

    test('a failed push is retried on a later sync', () async {
      final db = await RelaxDB.openInMemory(schemas: [taskSchema]);
      final engine = await db.sync;
      final adapter = MockSyncAdapter();
      engine.register(SyncConfig<Task>(schema: taskSchema, adapter: adapter));

      adapter.pushError = Exception('transient network error');
      await db.collection<Task>().add(Task(id: '1', title: 'Retry me'));
      await engine.syncTable('tasks');

      // The op is parked as failed, not pending, and nothing was pushed.
      expect(await engine.pendingCount(), 0);
      expect(adapter.pushedEntities, isEmpty);

      // Recover: the next sync resets the failed op and pushes it.
      adapter.pushError = null;
      await engine.syncTable('tasks');
      expect(adapter.pushedEntities.any((t) => t.title == 'Retry me'), isTrue);

      await db.close();
    });

    test('server-confirmed push is written back to the local database',
        () async {
      final db = await RelaxDB.openInMemory(schemas: [taskSchema]);
      final engine = await db.sync;
      final adapter = MockSyncAdapter();
      engine.register(SyncConfig<Task>(schema: taskSchema, adapter: adapter));

      final tasks = db.collection<Task>();
      await tasks.add(Task(id: '1', title: 'Original'));

      // Server normalizes the entity and returns the canonical version.
      adapter.pushReturns = [Task(id: '1', title: 'Server normalized')];
      await engine.syncTable('tasks');

      final stored = await tasks.get('1');
      expect(stored!.title, 'Server normalized');

      await db.close();
    });

    test('serverTime from a pull is reused as the next since watermark',
        () async {
      final db = await RelaxDB.openInMemory(schemas: [taskSchema]);
      final engine = await db.sync;
      final adapter = MockSyncAdapter();
      engine.register(SyncConfig<Task>(schema: taskSchema, adapter: adapter));

      final firstWatermark = DateTime(2026, 1, 1);
      adapter.nextPullResult = SyncPullResult<Task>(serverTime: firstWatermark);
      await engine.syncTable('tasks');
      expect(adapter.lastSince, isNull); // initial pull has no watermark

      adapter.nextPullResult =
          SyncPullResult<Task>(serverTime: DateTime(2026, 2, 1));
      await engine.syncTable('tasks');
      expect(adapter.lastSince, firstWatermark);

      await db.close();
    });

    test('repeated edits to one entity are coalesced into a single push',
        () async {
      final db = await RelaxDB.openInMemory(schemas: [taskSchema]);
      final engine = await db.sync;
      final adapter = MockSyncAdapter();
      engine.register(SyncConfig<Task>(schema: taskSchema, adapter: adapter));

      final tasks = db.collection<Task>();
      await tasks.add(Task(id: '1', title: 'v1'));
      for (var i = 2; i <= 10; i++) {
        await tasks.update(Task(id: '1', title: 'v$i'));
      }

      // Storage coalescing keeps a single row for the entity, not 10.
      expect(await engine.pendingCount(), 1);

      await engine.syncTable('tasks');

      // Only the latest state is pushed, once; the queue is fully drained.
      expect(adapter.pushedEntities.length, 1);
      expect(adapter.pushedEntities.single.title, 'v10');
      expect(await engine.pendingCount(), 0);

      await db.close();
    });

    test('an unconfirmed push entity stays queued for retry (SY-1)', () async {
      final db = await RelaxDB.openInMemory(schemas: [taskSchema]);
      final engine = await db.sync;
      final adapter = MockSyncAdapter();
      engine.register(SyncConfig<Task>(schema: taskSchema, adapter: adapter));

      final tasks = db.collection<Task>();
      await tasks.add(Task(id: '1', title: 'accepted'));
      await tasks.add(Task(id: '2', title: 'rejected'));

      // Server accepts only entity '1'; '2' is omitted (silently rejected).
      adapter.pushReturns = [Task(id: '1', title: 'accepted')];
      await engine.syncTable('tasks');

      // The confirmed op is gone; the unconfirmed one is still pending.
      expect(await engine.pendingCount(), 1);

      // Once the server accepts it on a later sync, the queue drains.
      adapter.pushReturns = null;
      await engine.syncTable('tasks');
      expect(await engine.pendingCount(), 0);

      await db.close();
    });

    test('an unconfirmed delete stays queued for retry (SY-2)', () async {
      final db = await RelaxDB.openInMemory(schemas: [taskSchema]);
      final engine = await db.sync;
      final adapter = MockSyncAdapter();
      engine.register(SyncConfig<Task>(schema: taskSchema, adapter: adapter));

      final tasks = db.collection<Task>();
      await tasks.add(Task(id: '1', title: 'a'));
      await tasks.add(Task(id: '2', title: 'b'));
      await engine.syncTable('tasks'); // drain the adds
      adapter.pushedEntities.clear();

      await tasks.delete('1');
      await tasks.delete('2');

      // Server confirms only the deletion of '1'.
      adapter.pushDeletesReturns = ['1'];
      await engine.syncTable('tasks');

      // '2' is unconfirmed and remains queued.
      expect(await engine.pendingCount(), 1);

      adapter.pushDeletesReturns = null;
      await engine.syncTable('tasks');
      expect(await engine.pendingCount(), 0);

      await db.close();
    });

    test('a queued op from an older schema version is discarded (ORM-4)',
        () async {
      final db = await RelaxDB.openInMemory(schemas: [taskSchema]);
      final engine = await db.sync;
      final adapter = MockSyncAdapter();
      // Current schema is taskSchema (version 1).
      engine.register(SyncConfig<Task>(schema: taskSchema, adapter: adapter));

      // Simulate an operation queued by an older app build (schema v99 here,
      // i.e. a format the current schema can no longer decode).
      await engine.queueOperation(
        tableName: 'tasks',
        type: SyncOperationType.add,
        entityId: '1',
        data: {'id': '1', 'title': 'stale', 'done': false},
        schemaVersion: 99,
      );
      expect(await engine.pendingCount(), 1);

      await engine.syncTable('tasks');

      // The stale op is dropped (never pushed) and the queue is drained.
      expect(adapter.pushedEntities, isEmpty);
      expect(await engine.pendingCount(), 0);

      await db.close();
    });
  });

  // -- SyncOperation.coalesce unit tests --

  group('SyncOperation.coalesce', () {
    SyncOperation op(SyncOperationType type, String entityId, int order,
            {Map<String, dynamic>? data}) =>
        SyncOperation(
          id: 'op$order',
          tableName: 'tasks',
          type: type,
          entityId: entityId,
          data: data,
          createdAt: DateTime(2026).add(Duration(seconds: order)),
        );

    test('add + update keeps a single add with the latest data', () {
      final result = SyncOperation.coalesce([
        op(SyncOperationType.add, '1', 0, data: {'title': 'a'}),
        op(SyncOperationType.update, '1', 1, data: {'title': 'b'}),
      ]);
      expect(result.upserts.length, 1);
      expect(result.deletes, isEmpty);
      expect(result.upserts.single.type, SyncOperationType.add);
      expect(result.upserts.single.data, {'title': 'b'});
    });

    test('multiple updates collapse to the last update', () {
      final result = SyncOperation.coalesce([
        op(SyncOperationType.update, '1', 0, data: {'title': 'a'}),
        op(SyncOperationType.update, '1', 1, data: {'title': 'b'}),
        op(SyncOperationType.update, '1', 2, data: {'title': 'c'}),
      ]);
      expect(result.upserts.single.type, SyncOperationType.update);
      expect(result.upserts.single.data, {'title': 'c'});
    });

    test('add + delete cancels out entirely', () {
      final result = SyncOperation.coalesce([
        op(SyncOperationType.add, '1', 0),
        op(SyncOperationType.delete, '1', 1),
      ]);
      expect(result.upserts, isEmpty);
      expect(result.deletes, isEmpty);
    });

    test('update + delete becomes a delete', () {
      final result = SyncOperation.coalesce([
        op(SyncOperationType.update, '1', 0),
        op(SyncOperationType.delete, '1', 1),
      ]);
      expect(result.upserts, isEmpty);
      expect(result.deletes.single.type, SyncOperationType.delete);
    });

    test('delete + add becomes an update (re-creation)', () {
      final result = SyncOperation.coalesce([
        op(SyncOperationType.delete, '1', 0),
        op(SyncOperationType.add, '1', 1, data: {'title': 'reborn'}),
      ]);
      expect(result.deletes, isEmpty);
      expect(result.upserts.single.type, SyncOperationType.update);
      expect(result.upserts.single.data, {'title': 'reborn'});
    });

    test('independent entities are kept separate, in first-seen order', () {
      final result = SyncOperation.coalesce([
        op(SyncOperationType.add, 'a', 0),
        op(SyncOperationType.add, 'b', 1),
        op(SyncOperationType.update, 'a', 2),
        op(SyncOperationType.delete, 'c', 3),
      ]);
      expect(result.upserts.map((o) => o.entityId), ['a', 'b']);
      expect(result.deletes.map((o) => o.entityId), ['c']);
    });
  });
}
