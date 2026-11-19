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
import '../generated_migrations/schema_v3.dart' as v3;

void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test(
    'v2 → v4: cấu trúc khớp schema v4, dòng outbox spike (không buổi) bị bỏ',
    () async {
      final schema = await verifier.schemaAt(2);
      final old = v2.DatabaseAtV2(schema.newConnection());
      await old.customStatement(
        "INSERT INTO outbox_mutations (client_mutation_id, entity, payload, client_updated_at, attempt_count) "
        "VALUES ('m-1', 'attendance', '{}', 1794960000, 3)",
      );
      await old.close();

      final db = TeacherDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 4);
      expect(await db.select(db.outboxMutations).get(), isEmpty);
    },
  );

  test('v3 → v4: buổi cũ giữ nguyên, cột offset mới là null', () async {
    final schema = await verifier.schemaAt(3);
    final old = v3.DatabaseAtV3(schema.newConnection());
    await old.customStatement(
      "INSERT INTO cached_sessions (id, class_id, class_name, session_date, starts_at, ends_at, status, is_makeup) "
      "VALUES ('s-1', 'c-1', 'Toán 9', '2026-11-19', 1794960000, 1794963600, 'planned', 0)",
    );
    await old.close();

    final db = TeacherDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 4);
    final rows = await db.select(db.cachedSessions).get();
    expect(rows.single.className, 'Toán 9');
    expect(rows.single.tzOffsetMinutes, isNull);
  });

  test('v1 → v4 một mạch', () async {
    final connection = await verifier.startAt(1);
    final db = TeacherDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 4);
  });

  test(
    'v1 → v4 trên file mã hóa: mở được, bảng mới có mặt, dòng không buổi bị bỏ',
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
      // Dòng v1 không có buổi/học viên: migration v3 bỏ, nhưng file mã hóa vẫn mở được.
      expect(rows, isEmpty);
      expect(await db.select(db.cachedSessions).get(), isEmpty);
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
