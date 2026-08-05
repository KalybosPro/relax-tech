import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:relax_orm/relax_orm.dart';

/// Schema changes across two openings of the same file.
///
/// The database has to be a real file: everything under test happens *between*
/// two runs of the app, and an in-memory database has no second run.
///
/// The rows are plain maps rather than a model class, so a test can change the
/// shape of a table without a matching Dart class to change alongside it.
void main() {
  late Directory directory;
  late File file;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('relax_orm_migration_');
    file = File('${directory.path}/notes.sqlite');
  });

  tearDown(() {
    // Windows keeps a just-closed SQLite file locked for a moment, and a
    // temporary directory the OS will reclaim anyway is not worth failing a
    // test over.
    try {
      directory.deleteSync(recursive: true);
    } on FileSystemException {
      // Nothing to do: the OS reclaims its own temporary directory.
    }
  });

  /// A `notes` table, in as many shapes as the tests need.
  TableSchema<Map<String, Object?>> notes({
    List<ColumnDef> extra = const [],
    String body = 'body',
  }) => TableSchema<Map<String, Object?>>(
    tableName: 'notes',
    columns: [
      const ColumnDef.text('id', isPrimaryKey: true),
      ColumnDef.text(body),
      ...extra,
    ],
    fromMap: (map) => map,
    toMap: (note) => note,
  );

  Future<RelaxDB> open(
    TableSchema<Map<String, Object?>> schema, {
    int version = 1,
    RelaxMigration? onUpgrade,
  }) => RelaxDB.openFile(
    file: file,
    schemas: [schema],
    version: version,
    onUpgrade: onUpgrade,
  );

  Future<List<Map<String, Object?>>> rows(RelaxDB db) =>
      db.select('SELECT * FROM notes ORDER BY id');

  Future<int?> versionOf(RelaxDB db) async {
    final rows = await db.select('SELECT version FROM _relax_schema');
    return rows.isEmpty ? null : rows.first['version'] as int?;
  }

  group('version', () {
    test('a database created now is already at the current version', () async {
      final db = await open(notes(), version: 3);
      addTearDown(db.close);

      expect(await versionOf(db), 3);
    });

    test('a first launch does not run onUpgrade', () async {
      var ran = false;
      final db = await open(
        notes(),
        version: 2,
        onUpgrade: (_, _, _) async => ran = true,
      );
      addTearDown(db.close);

      expect(ran, isFalse);
    });

    test('reopening at the same version does not run onUpgrade', () async {
      await (await open(notes(), version: 2)).close();

      var ran = false;
      final db = await open(
        notes(),
        version: 2,
        onUpgrade: (_, _, _) async => ran = true,
      );
      addTearDown(db.close);

      expect(ran, isFalse);
    });

    test('onUpgrade is told where the database is and where to go', () async {
      await (await open(notes(), version: 1)).close();

      int? from;
      int? to;
      final db = await open(
        notes(),
        version: 4,
        onUpgrade: (_, f, t) async {
          from = f;
          to = t;
        },
      );
      addTearDown(db.close);

      expect(from, 1);
      expect(to, 4);
      expect(await versionOf(db), 4);
    });

    test('a database written by a newer build refuses to open', () async {
      await (await open(notes(), version: 5)).close();

      // Reading rows with a schema that no longer describes them is worse than
      // not opening at all.
      await expectLater(
        open(notes(), version: 2),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('version 5'), contains('2')),
          ),
        ),
      );
    });

    test('a database from before versioning reports version 0', () async {
      // What every database opened by relax_orm 1.1.1 and earlier looks like:
      // the tables are there, and nothing recorded what shape they are in.
      final legacy = await open(notes(), version: 1);
      await legacy.execute('DROP TABLE _relax_schema');
      await legacy.close();

      int? from;
      final db = await open(
        notes(),
        version: 2,
        onUpgrade: (_, f, _) async => from = f,
      );
      addTearDown(db.close);

      expect(from, 0);
    });
  });

  group('additive reconciliation', () {
    test('a nullable column appears without any migration', () async {
      final before = await open(notes());
      await before.collection<Map<String, Object?>>().add({
        'id': '1',
        'body': 'kept',
      });
      await before.close();

      // No version bump, no onUpgrade — this is the case that should cost the
      // author nothing.
      final after = await open(
        notes(extra: [const ColumnDef.text('title', isNullable: true)]),
      );
      addTearDown(after.close);

      // The column is there, and writing it works — the failure this fixes was
      // an INSERT naming a column the table did not have.
      await after.collection<Map<String, Object?>>().add({
        'id': '2',
        'body': 'new',
        'title': 'Titre',
      });

      final all = await rows(after);
      expect(all, hasLength(2));
      expect(all.first['title'], isNull, reason: 'la ligne d’avant');
      expect(all.last['title'], 'Titre');
    });

    test('a NOT NULL column with a default appears too', () async {
      final before = await open(notes());
      await before.collection<Map<String, Object?>>().add({
        'id': '1',
        'body': 'kept',
      });
      await before.close();

      final after = await open(
        notes(
          extra: [const ColumnDef.integer('reads', defaultValue: '0')],
        ),
      );
      addTearDown(after.close);

      expect((await rows(after)).single['reads'], 0);
    });

    test('a NOT NULL column without a default fails loudly', () async {
      await (await open(notes())).close();

      // Skipping it silently is what produced the original bug: the column
      // stayed missing, and the failure surfaced later at the first write.
      await expectLater(
        open(notes(extra: [const ColumnDef.integer('reads')])),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('reads'), contains('defaultValue')),
          ),
        ),
      );
    });
  });

  group('renameColumn', () {
    test('the rows follow the new name', () async {
      final before = await open(notes());
      await before.collection<Map<String, Object?>>().add({
        'id': '1',
        'body': 'à garder',
      });
      await before.close();

      final after = await open(
        notes(body: 'text'),
        version: 2,
        onUpgrade: (m, _, _) async =>
            m.renameColumn('notes', from: 'body', to: 'text'),
      );
      addTearDown(after.close);

      final all = await rows(after);
      expect(all.single['text'], 'à garder');
      expect(all.single.containsKey('body'), isFalse);
    });

    test('renaming happens before the column would be added back', () async {
      // Ordering is the whole point: reconcile first and `text` would be
      // created empty, then the rename would collide with it.
      final before = await open(notes());
      await before.collection<Map<String, Object?>>().add({
        'id': '1',
        'body': 'à garder',
      });
      await before.close();

      final after = await open(
        notes(body: 'text'),
        version: 2,
        onUpgrade: (m, _, _) async =>
            m.renameColumn('notes', from: 'body', to: 'text'),
      );
      addTearDown(after.close);

      final columns = await after.select('PRAGMA table_info(notes)');
      expect(
        columns.map((c) => c['name']),
        unorderedEquals(['id', 'text']),
        reason: 'aucune colonne fantôme',
      );
    });
  });

  group('rebuildTable', () {
    test('a dropped column goes, and the rest stays', () async {
      final before = await open(
        notes(extra: [const ColumnDef.text('scratch', isNullable: true)]),
      );
      await before.collection<Map<String, Object?>>().add({
        'id': '1',
        'body': 'à garder',
        'scratch': 'à jeter',
      });
      await before.close();

      final schema = notes();
      final after = await open(
        schema,
        version: 2,
        onUpgrade: (m, _, _) async => m.rebuildTable(schema),
      );
      addTearDown(after.close);

      final all = await rows(after);
      expect(all.single['body'], 'à garder');
      expect(all.single.containsKey('scratch'), isFalse);
    });

    test('a column can be filled from an expression over the old table', () async {
      final before = await open(notes());
      await before.collection<Map<String, Object?>>().add({
        'id': '1',
        'body': 'quatre',
      });
      await before.close();

      final schema = notes(
        extra: [const ColumnDef.integer('length', isNullable: true)],
      );
      final after = await open(
        schema,
        version: 2,
        onUpgrade: (m, _, _) async =>
            m.rebuildTable(schema, from: {'length': 'LENGTH(body)'}),
      );
      addTearDown(after.close);

      expect((await rows(after)).single['length'], 6);
    });

    test('a NOT NULL column with nothing to fill it fails before any '
        'statement runs', () async {
      final before = await open(notes());
      await before.collection<Map<String, Object?>>().add({
        'id': '1',
        'body': 'à garder',
      });
      await before.close();

      final schema = notes(extra: [const ColumnDef.integer('reads')]);
      await expectLater(
        open(
          schema,
          version: 2,
          onUpgrade: (m, _, _) async => m.rebuildTable(schema),
        ),
        throwsA(isA<StateError>()),
      );

      // The old table is untouched: nothing was dropped on the way to failing.
      final after = await open(notes());
      addTearDown(after.close);
      expect((await rows(after)).single['body'], 'à garder');
    });
  });
}
