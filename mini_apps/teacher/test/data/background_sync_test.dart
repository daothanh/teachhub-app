import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' show Database;
import 'package:tasco_storage/tasco_storage.dart';
import 'package:teacher/data/local_db/teacher_database.dart';
import 'package:teacher/data/sync/background_sync.dart';
import 'package:teacher/data/sync/enqueue_attendance.dart';

import '../support/fake_teachhub_server.dart';

const _s1 = '10000000-0000-4000-8000-000000000001';
const _stu = '20000000-0000-4000-8000-000000000001';

void main() {
  late Directory dir;
  late InMemoryKeyValueStore keys;
  late FakeTeachHubServer server;
  late int opens;

  Future<TeacherDatabase> open() async {
    opens++;
    final key = await databaseKey(keys);
    return TeacherDatabase(
      NativeDatabase(
        File('${dir.path}/$teacherDatabaseFile'),
        setup: (Database d) => encryptionSetup(key)(d),
      ),
    );
  }

  Future<bool> run() => runOutboxSyncOnce(
    dio: server.dio(),
    keys: keys,
    directory: dir,
    open: open,
  );

  Future<void> seed() async {
    final db = await open();
    await enqueueAttendance(
      db,
      sessionId: _s1,
      studentId: _stu,
      status: 'absent',
      clientUpdatedAt: DateTime.utc(2026, 11, 18, 9),
      clientMutationId: '30000000-0000-4000-8000-000000000001',
    );
    await db.close();
    opens = 0;
  }

  Future<int> pending() async {
    final db = await open();
    final n = await pendingOutboxCount(db);
    await db.close();
    return n;
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bgsync');
    keys = InMemoryKeyValueStore();
    server = FakeTeachHubServer();
    opens = 0;
  });
  tearDown(() => dir.delete(recursive: true));

  test(
    'chưa có file CSDL: không mở, không tạo file, không xin thử lại',
    () async {
      expect(await run(), isTrue);
      expect(opens, 0);
      expect(File('${dir.path}/$teacherDatabaseFile').existsSync(), isFalse);
    },
  );

  test('có mutation chờ: đẩy một lượt qua SyncEngine rồi đóng', () async {
    await seed();
    expect(await run(), isTrue);
    expect(server.syncRequests, hasLength(1));
    expect(await pending(), 0);
  });

  test('mất mạng: giữ outbox và trả false để hệ điều hành thử lại', () async {
    await seed();
    server.offline = true;
    expect(await run(), isFalse);
    expect(await pending(), 1);
  });
}
