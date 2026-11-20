import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' show Database;
import 'package:tasco_storage/tasco_storage.dart';
import 'package:teacher/data/local_db/teacher_database.dart';
import 'package:teacher/data/local_db/teacher_local_data.dart';
import 'package:teacher/data/sync/background_flags.dart';
import 'package:teacher/data/sync/background_sync.dart';
import 'package:teacher/data/sync/enqueue_attendance.dart';

import '../support/fake_teachhub_server.dart';

const _s1 = '10000000-0000-4000-8000-000000000001';
const _stu = '20000000-0000-4000-8000-000000000001';
const _user = 'user-1';

void main() {
  late Directory dir;
  late InMemoryKeyValueStore keys;
  late FakeTeachHubServer server;
  late int opens;
  String? user;

  TeacherDatabase open(String key) {
    opens++;
    return TeacherDatabase(
      NativeDatabase(
        File('${dir.path}/$teacherDatabaseFile'),
        setup: (Database d) => encryptionSetup(key)(d),
      ),
    );
  }

  Future<BackgroundSyncOutcome> run({Dio? dio}) => runOutboxSyncOnce(
    dio: dio ?? server.dio(),
    keys: keys,
    directory: dir,
    currentUserId: () async => user,
    recheckEvery: const Duration(milliseconds: 10),
    open: open,
  );

  /// CSDL có khóa, chủ và một mutation chờ.
  Future<void> seed({int rows = 1}) async {
    final db = open(await databaseKey(keys));
    for (var i = 0; i < rows; i++) {
      await enqueueAttendance(
        db,
        sessionId: _s1,
        studentId: _stu.replaceFirst('0001', '000${i + 1}'),
        status: 'absent',
        clientUpdatedAt: DateTime.utc(2026, 11, 18, 9),
        clientMutationId: '30000000-0000-4000-8000-00000000000${i + 1}',
      );
    }
    await db.close();
    await keys.write(TeacherLocalData.ownerKey, _user);
    opens = 0;
  }

  Future<int> pending() async {
    final db = open((await readDatabaseKey(keys))!);
    final n = await pendingOutboxCount(db);
    await db.close();
    return n;
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bgsync');
    keys = InMemoryKeyValueStore();
    server = FakeTeachHubServer();
    opens = 0;
    user = _user;
  });
  tearDown(() => dir.delete(recursive: true));

  test('chưa có file CSDL: không mở, không tạo file', () async {
    expect(await run(), BackgroundSyncOutcome.done);
    expect(opens, 0);
    expect(File('${dir.path}/$teacherDatabaseFile').existsSync(), isFalse);
  });

  test('thiếu khóa: không đồng bộ và tuyệt đối không sinh khóa mới', () async {
    File('${dir.path}/$teacherDatabaseFile').writeAsBytesSync([1, 2, 3]);
    expect(await run(), BackgroundSyncOutcome.done);
    expect(opens, 0);
    expect(await keys.contains('teacher.db_key'), isFalse);
  });

  test('có mutation chờ: đẩy một lượt rồi đóng, xóa cờ chạy nền', () async {
    await seed();
    expect(await run(), BackgroundSyncOutcome.done);
    expect(server.syncRequests, hasLength(1));
    expect(await pending(), 0);
    expect(await isBackgroundRunning(keys), isFalse);
  });

  test('mất mạng: giữ outbox, báo retry', () async {
    await seed();
    server.offline = true;
    expect(await run(), BackgroundSyncOutcome.retry);
    expect(await pending(), 1);
  });

  for (final status in [403, 401]) {
    test(
      '$status: dòng kẹt không tự hết, báo done (không retry vô hạn)',
      () async {
        await seed();
        server.failSession[_s1] = (status, 'FORBIDDEN');
        expect(await run(), BackgroundSyncOutcome.done);
        expect(await pending(), 1);
      },
    );
  }

  test('chủ CSDL khác người đăng nhập: không đồng bộ', () async {
    await seed();
    user = 'user-2';
    expect(await run(), BackgroundSyncOutcome.notAllowed);
    expect(server.syncRequests, isEmpty);
    expect(opens, 0);
  });

  test('mất phiên: không đồng bộ', () async {
    await seed();
    user = null;
    expect(await run(), BackgroundSyncOutcome.notAllowed);
    expect(server.syncRequests, isEmpty);
  });

  test('đang xóa dở (wipePending): không đồng bộ', () async {
    await seed();
    await keys.write(TeacherLocalData.wipePendingKey, '1');
    expect(await run(), BackgroundSyncOutcome.notAllowed);
    expect(server.syncRequests, isEmpty);
    expect(opens, 0);
  });

  test('app đang foreground: bỏ lượt; cờ quá hạn thì chạy', () async {
    await seed();
    await markForeground(keys, true);
    expect(await run(), BackgroundSyncOutcome.done);
    expect(server.syncRequests, isEmpty);
    await keys.write(
      foregroundKey,
      '${DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch}',
    );
    expect(await run(), BackgroundSyncOutcome.done);
    expect(server.syncRequests, hasLength(1));
  });

  test('wipe bắt đầu giữa lúc gửi: dừng engine, báo notAllowed', () async {
    await seed();
    final dio = server.dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) async {
            await Future<void>.delayed(const Duration(milliseconds: 400));
            h.next(o);
          },
        ),
      );
    final result = run(dio: dio);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await keys.write(TeacherLocalData.wipePendingKey, '1');
    expect(await result, BackgroundSyncOutcome.notAllowed);
    expect(await isBackgroundRunning(keys), isFalse);
  });

  test('wipe chờ nền đóng CSDL rồi mới xóa', () async {
    await seed();
    await markBackgroundRunning(keys, true);
    var closed = false;
    final data = TeacherLocalData(
      keyStore: keys,
      directory: () async => dir,
      database: () async => open((await readDatabaseKey(keys))!),
      close: () async => closed = true,
      reopen: () async {},
    )..waitStep = const Duration(milliseconds: 10);
    final wipe = data.wipe();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(closed, isFalse); // còn đợi nền
    await markBackgroundRunning(keys, false);
    await wipe;
    expect(closed, isTrue);
    expect(File('${dir.path}/$teacherDatabaseFile').existsSync(), isFalse);
  });

  test(
    'hai kết nối cùng drain: không lỗi, mỗi mutation áp dụng một lần',
    () async {
      await seed(rows: 3);
      final results = await Future.wait([run(), run()]);
      expect(results, everyElement(BackgroundSyncOutcome.done));
      expect(server.appliedCount.values, everyElement(lessThanOrEqualTo(1)));
      expect(await pending(), 0);
    },
  );
}
