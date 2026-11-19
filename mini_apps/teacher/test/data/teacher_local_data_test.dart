import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' show Database;
import 'package:tasco_storage/tasco_storage.dart';
import 'package:teacher/data/local_db/teacher_database.dart';
import 'package:teacher/data/local_db/teacher_local_data.dart';
import 'package:teacher/data/sync/enqueue_attendance.dart';
import 'package:teacher/data/sync/sync_engine.dart';

/// Key store ném lỗi khi xóa khóa nhất định (giả lập xóa dở dang).
class _FlakyStore extends InMemoryKeyValueStore {
  bool failDelete = false;
  @override
  Future<void> delete(String key) async {
    if (failDelete && key == 'teacher.db_key') throw StateError('disk');
    return super.delete(key);
  }
}

void main() {
  late Directory dir;
  late _FlakyStore keys;
  late TeacherDatabase? db;
  late int opens;
  late TeacherLocalData data;

  Future<TeacherDatabase> open() async {
    opens++;
    final key = await databaseKey(keys);
    return db = TeacherDatabase(
      NativeDatabase(
        File('${dir.path}/$teacherDatabaseFile'),
        setup: (Database d) => encryptionSetup(key)(d),
      ),
    );
  }

  Future<void> addMutation(String id) async {
    final d = db ?? await open();
    await d
        .into(d.outboxMutations)
        .insert(
          OutboxMutationsCompanion.insert(
            clientMutationId: id,
            entity: 'attendance',
            payload: '{}',
            clientUpdatedAt: DateTime.utc(2026, 11, 14),
          ),
        );
  }

  setUp(() {
    dir = Directory.systemTemp.createTempSync('teacher_local');
    keys = _FlakyStore();
    db = null;
    opens = 0;
    data = TeacherLocalData(
      keyStore: keys,
      directory: () async => dir,
      database: () async => db ?? await open(),
      close: () async {
        await db?.close();
        db = null;
      },
      reopen: () async {},
    );
  });
  tearDown(() async {
    await db?.close();
    dir.deleteSync(recursive: true);
  });

  test('chưa có file CSDL: đếm 0 và không tạo file', () async {
    expect(await data.pendingSyncCount(), 0);
    expect(opens, 0);
    expect(dir.listSync(), isEmpty);
  });

  test('đếm đúng số mutation, xóa dọn file và khóa', () async {
    await addMutation('m-1');
    await addMutation('m-2');
    expect(await data.pendingSyncCount(), 2);

    await data.wipe();
    expect(dir.listSync(), isEmpty);
    expect(await keys.contains('teacher.db_key'), isFalse);
    expect(await keys.contains(TeacherLocalData.wipePendingKey), isFalse);
    expect(await data.pendingSyncCount(), 0);
  });

  test(
    'markWipePending đặt cờ, retryPendingWipe xóa; clearWipePending bỏ cờ',
    () async {
      await addMutation('m-1');
      await data.markWipePending();
      expect(await keys.contains(TeacherLocalData.wipePendingKey), isTrue);
      await data.clearWipePending();
      expect(await keys.contains(TeacherLocalData.wipePendingKey), isFalse);
      expect(dir.listSync(), isNotEmpty);

      await data.markWipePending();
      await data.retryPendingWipe();
      expect(await keys.contains(TeacherLocalData.wipePendingKey), isFalse);
      expect(dir.listSync(), isEmpty);
    },
  );

  test('xóa lỗi: cờ còn lại, retryPendingWipe xóa nốt', () async {
    await addMutation('m-1');
    keys.failDelete = true;
    await expectLater(data.wipe(), throwsStateError);
    expect(await keys.contains(TeacherLocalData.wipePendingKey), isTrue);

    keys.failDelete = false;
    await data.retryPendingWipe();
    expect(await keys.contains(TeacherLocalData.wipePendingKey), isFalse);
    expect(dir.listSync(), isEmpty);
  });

  test(
    'failedSyncCount/discardFailed: đếm và bỏ dòng bị từ chối, giữ dòng chờ gửi',
    () async {
      await addMutation('m-1');
      final d = db!;
      await d
          .into(d.outboxMutations)
          .insert(
            OutboxMutationsCompanion.insert(
              clientMutationId: 'm-2',
              entity: 'attendance',
              payload: '{}',
              clientUpdatedAt: DateTime.utc(2026, 11, 14),
              lastError: const Value('rejected:NOT_FOUND'),
            ),
          );
      expect(await data.pendingSyncCount(), 1);
      expect(await data.failedSyncCount(), 1);
      await data.discardFailed();
      expect(await data.failedSyncCount(), 0);
      expect(await data.pendingSyncCount(), 1);
    },
  );

  test('nhiều lần xóa chồng nhau chạy lần lượt, không lỗi', () async {
    await addMutation('m-1');
    await Future.wait([data.wipe(), data.wipe(), data.wipe()]);
    expect(dir.listSync(), isEmpty);
  });

  test('cùng người dùng đăng nhập lại: giữ dữ liệu', () async {
    await data.claimFor('u1');
    await addMutation('m-1');
    await data.claimFor('u1');
    expect(await data.pendingSyncCount(), 1);
  });

  test('người dùng khác đăng nhập: xóa dữ liệu người trước', () async {
    await data.claimFor('u1');
    await addMutation('m-1');
    await data.claimFor('u2');
    expect(await data.pendingSyncCount(), 0);
    expect(await keys.read(TeacherLocalData.ownerKey), 'u2');
  });

  test(
    'xóa dừng SyncEngine (bỏ chờ lượt gửi đang bay) trước khi đóng CSDL; sau đó bật lại',
    () async {
      final d = db ?? await open();
      await enqueueAttendance(
        d,
        sessionId: 's1',
        studentId: 'a',
        status: 'present',
        clientUpdatedAt: DateTime.utc(2026, 11, 18),
      );
      final release = Completer<void>();
      final log = <String>[];
      final engine = SyncEngine(d, (req) async {
        log.add('send');
        await release.future;
        log.add('sent');
        return SyncResponse(
          serverTime: DateTime.utc(2026, 11, 18),
          results: {
            for (final m in req.mutations)
              m.clientMutationId: const MutationResult(SyncResult.applied),
          },
        );
      });
      final wiping = TeacherLocalData(
        keyStore: keys,
        directory: () async => dir,
        database: () async => db ?? await open(),
        close: () async {
          log.add('close');
          await db?.close();
          db = null;
        },
        reopen: () async => log.add('reopen'),
        pauseSync: () => engine.stop(),
        resumeSync: () async => log.add('resume'),
      );

      final running = engine.drain();
      await pumpEventQueue();
      final wipe = wiping.wipe();
      await pumpEventQueue();
      await wipe; // không bị transport chậm giữ lại
      expect(log, ['send', 'close', 'reopen', 'resume']);
      expect(await running, (
        sent: 0,
        rejected: 0,
        failed: 0,
        blocked: 0,
        retryIn: null,
      ));

      release.complete(); // phản hồi muộn không được ghi vào CSDL đã xóa
      await pumpEventQueue();
      expect(log, ['send', 'close', 'reopen', 'resume', 'sent']);
    },
  );
}
