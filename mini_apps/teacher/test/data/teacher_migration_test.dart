import 'dart:io';

import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' show Database;
import 'package:tasco_storage/tasco_storage.dart';
import 'package:teacher/data/local_db/teacher_database.dart';

import '../generated_migrations/schema.dart';
import '../generated_migrations/schema_v1.dart' as v1;
import '../generated_migrations/schema_v2.dart' as v2;

void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('v2 → v3: cấu trúc khớp schema v3, dữ liệu outbox cũ còn', () async {
    final schema = await verifier.schemaAt(2);
    final old = v2.DatabaseAtV2(schema.newConnection());
    await old.customStatement(
      "INSERT INTO outbox_mutations (client_mutation_id, entity, payload, client_updated_at, attempt_count) "
      "VALUES ('m-1', 'attendance', '{}', 1794960000, 3)",
    );
    await old.close();

    final db = TeacherDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 3);
    final row = await db.select(db.outboxMutations).getSingle();
    expect(
      (row.clientMutationId, row.attemptCount, row.sessionId, row.batchKey),
      ('m-1', 3, null, null),
    );
  });

  test('v1 → v3 một mạch', () async {
    final connection = await verifier.startAt(1);
    final db = TeacherDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 3);
  });

  test(
    'v1 → v3 trên file mã hóa: dữ liệu outbox còn nguyên, cột mới có mặc định',
    () async {
      final dir = Directory.systemTemp.createTempSync('teacher_mig');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/teacher.sqlite');
      final key = 'ab' * 32;
      NativeDatabase open() =>
          NativeDatabase(file, setup: (Database d) => encryptionSetup(key)(d));

      final old = v1.DatabaseAtV1(open());
      await old.customStatement(
        "INSERT INTO outbox_mutations (client_mutation_id, entity, payload, client_updated_at) "
        "VALUES ('m-1', 'attendance', '{}', 1794960000)",
      );
      await old.close();

      final db = TeacherDatabase(open());
      addTearDown(db.close);
      final rows = await db.select(db.outboxMutations).get();
      expect(rows.single.clientMutationId, 'm-1');
      expect(rows.single.attemptCount, 0);
      expect(rows.single.lastError, isNull);
    },
  );

  test('deleteTeacherDatabase xóa file, WAL/SHM và khóa', () async {
    final dir = Directory.systemTemp.createTempSync('teacher_del');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = InMemoryKeyValueStore();
    await databaseKey(store);
    for (final s in ['', '-wal', '-shm']) {
      File('${dir.path}/teacher.sqlite$s').writeAsStringSync('x');
    }
    await deleteTeacherDatabase(store, dir);
    expect(dir.listSync(), isEmpty);
    expect(await store.contains('teacher.db_key'), isFalse);
  });
}
