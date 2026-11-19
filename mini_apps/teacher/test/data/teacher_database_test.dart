import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' show Database;
import 'package:flutter_test/flutter_test.dart';
import 'package:tasco_storage/tasco_storage.dart';
import 'package:teacher/data/local_db/teacher_database.dart';

void main() {
  late Directory dir;
  final key = 'ab' * 32;

  setUp(() => dir = Directory.systemTemp.createTempSync('teacher_db'));
  tearDown(() => dir.deleteSync(recursive: true));

  TeacherDatabase open(File file, String hexKey) => TeacherDatabase(
    NativeDatabase(file, setup: (Database db) => encryptionSetup(hexKey)(db)),
  );

  test('outbox keeps one row per client mutation id', () async {
    final db = open(File('${dir.path}/a.sqlite'), key);
    addTearDown(db.close);
    final row = OutboxMutationsCompanion.insert(
      clientMutationId: 'm-1',
      entity: 'attendance',
      payload: '{}',
      clientUpdatedAt: DateTime.utc(2026, 11, 14),
    );
    await db.into(db.outboxMutations).insert(row);
    expect(
      () => db.into(db.outboxMutations).insert(row),
      throwsA(isA<SqliteException>()),
    );
    expect(await db.select(db.outboxMutations).get(), hasLength(1));
  });

  test('the file is unreadable without the key', () async {
    final file = File('${dir.path}/b.sqlite');
    final db = open(file, key);
    await db
        .into(db.outboxMutations)
        .insert(
          OutboxMutationsCompanion.insert(
            clientMutationId: 'm-1',
            entity: 'attendance',
            payload: '{"student":"Lê Chi"}',
            clientUpdatedAt: DateTime.utc(2026, 11, 14),
          ),
        );
    await db.close();

    expect(file.readAsStringSync(encoding: latin1), isNot(contains('Lê Chi')));
    expect(
      file.readAsBytesSync().take(15),
      isNot(equals('SQLite format 3'.codeUnits)),
    );

    final wrongKey = open(file, 'cd' * 32);
    addTearDown(wrongKey.close);
    await expectLater(
      wrongKey.select(wrongKey.outboxMutations).get(),
      throwsA(anything),
    );
  });

  test('the key is created once and reused', () async {
    final store = InMemoryKeyValueStore();
    final first = await databaseKey(store);
    expect(first, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(await databaseKey(store), first);
  });

  test('pendingOutboxCount đếm mọi mutation còn trong outbox', () async {
    final db = open(File('${dir.path}/c.sqlite'), key);
    addTearDown(db.close);
    expect(await pendingOutboxCount(db), 0);
    for (final id in ['m-1', 'm-2']) {
      await db
          .into(db.outboxMutations)
          .insert(
            OutboxMutationsCompanion.insert(
              clientMutationId: id,
              entity: 'attendance',
              payload: '{}',
              clientUpdatedAt: DateTime.utc(2026, 11, 14),
            ),
          );
    }
    expect(await pendingOutboxCount(db), 2);
  });
}
