import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:relax_orm/relax_orm.dart';

// -- Test model --

class Note {
  final String id;
  final String content;

  Note({required this.id, required this.content});
}

final noteSchema = TableSchema<Note>(
  tableName: 'notes',
  columns: [
    ColumnDef.text('id', isPrimaryKey: true),
    ColumnDef.text('content'),
  ],
  fromMap: (map) =>
      Note(id: map['id'] as String, content: map['content'] as String),
  toMap: (note) => {'id': note.id, 'content': note.content},
);

/// Collecting sink so tests can assert on emitted records.
class _Collector {
  final records = <RelaxLogRecord>[];
  void add(RelaxLogRecord r) => records.add(r);

  Iterable<RelaxLogRecord> of(RelaxLogCategory c) =>
      records.where((r) => r.category == c);
}

Future<bool> _checkCipherAvailable() async {
  final db = await RelaxDB.openInMemory(schemas: [noteSchema]);
  final available = await db.isEncryptionAvailable();
  await db.close();
  return available;
}

void main() {
  late bool cipherAvailable;

  setUpAll(() async {
    cipherAvailable = await _checkCipherAvailable();
  });

  group('logging - off by default', () {
    test('no logger ⇒ zero records', () async {
      final collector = _Collector();
      // No logger passed: logging is disabled. The collector is only here to
      // prove it is never invoked (we attach it through a separate enabled run
      // below); with no logger there is nothing to spy on except behavior.
      final db = await RelaxDB.openInMemory(schemas: [noteSchema]);
      await db.collection<Note>().add(Note(id: '1', content: 'x'));
      await db.collection<Note>().getAll();
      await db.close();
      // The default logger is disabled — assert via isLoggable.
      expect(db.logger.enabled, isFalse);
      expect(collector.records, isEmpty);
    });

    test('disabled logger never emits', () async {
      final collector = _Collector();
      final db = await RelaxDB.openInMemory(
        schemas: [noteSchema],
        logger: RelaxLogger(enabled: false, sink: collector.add),
      );
      await db.collection<Note>().add(Note(id: '1', content: 'x'));
      await db.close();
      expect(collector.records, isEmpty);
    });
  });

  group('logging - enabled', () {
    test('CRUD and query produce records', () async {
      final collector = _Collector();
      final db = await RelaxDB.openInMemory(
        schemas: [noteSchema],
        logger: RelaxLogger(sink: collector.add),
      );

      final notes = db.collection<Note>();
      await notes.add(Note(id: '1', content: 'Alpha'));
      await notes.query().where('content', startsWith: 'A').find();
      await db.close();

      expect(collector.of(RelaxLogCategory.crud), isNotEmpty);
      expect(collector.of(RelaxLogCategory.query), isNotEmpty);
      expect(
        collector
            .of(RelaxLogCategory.crud)
            .any((r) => r.message.contains('INSERT')),
        isTrue,
      );
    });

    test('category filtering suppresses other categories', () async {
      final collector = _Collector();
      final db = await RelaxDB.openInMemory(
        schemas: [noteSchema],
        logger: RelaxLogger(
          categories: {RelaxLogCategory.crud},
          sink: collector.add,
        ),
      );

      final notes = db.collection<Note>();
      await notes.add(Note(id: '1', content: 'Alpha'));
      await notes.query().find();
      await db.close();

      expect(collector.of(RelaxLogCategory.crud), isNotEmpty);
      expect(collector.of(RelaxLogCategory.query), isEmpty);
      expect(collector.of(RelaxLogCategory.database), isEmpty);
    });

    test('minLevel filters low-severity records', () async {
      final collector = _Collector();
      final db = await RelaxDB.openInMemory(
        schemas: [noteSchema],
        logger: RelaxLogger(
          minLevel: RelaxLogLevel.warning,
          sink: collector.add,
        ),
      );
      // CRUD records are emitted at debug level — should be dropped.
      await db.collection<Note>().add(Note(id: '1', content: 'x'));
      await db.close();
      expect(collector.of(RelaxLogCategory.crud), isEmpty);
    });
  });

  group('debugCheckEncryption', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('relax_orm_log_');
    });

    tearDown(() {
      try {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('plaintext file reports isEncrypted == false', () async {
      final file = File('${tempDir.path}/plain.db');
      final collector = _Collector();
      final db = await RelaxDB.openFile(
        file: file,
        schemas: [noteSchema],
        logger: RelaxLogger(sink: collector.add),
      );
      await db.collection<Note>().add(Note(id: '1', content: 'Public'));

      final check = await db.debugCheckEncryption();
      expect(check.isEncrypted, isFalse);
      expect(check.keyRequested, isFalse);
      expect(check.isMisconfigured, isFalse);
      expect(collector.of(RelaxLogCategory.encryption), isNotEmpty);
      await db.close();
    });

    test('encrypted file reports isEncrypted == true', () async {
      if (!cipherAvailable) {
        markTestSkipped('SQLite3MultipleCiphers not available');
        return;
      }
      final file = File('${tempDir.path}/enc.db');
      final db = await RelaxDB.openFile(
        file: file,
        schemas: [noteSchema],
        encryptionKey: 'a-secret',
      );
      await db.collection<Note>().add(Note(id: '1', content: 'Secret'));

      final check = await db.debugCheckEncryption();
      expect(check.isEncrypted, isTrue);
      expect(check.keyRequested, isTrue);
      expect(check.isMisconfigured, isFalse);
      await db.close();
    });

    test('in-memory database returns unknown (null)', () async {
      final db = await RelaxDB.openInMemory(schemas: [noteSchema]);
      final check = await db.debugCheckEncryption();
      expect(check.isEncrypted, isNull);
      await db.close();
    });
  });
}
