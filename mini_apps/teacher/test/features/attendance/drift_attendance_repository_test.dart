import 'dart:async';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/data/local_db/teacher_database.dart';
import 'package:teacher/data/remote/teacher_api.dart';
import 'package:teacher/data/sync/clock_skew.dart';
import 'package:teacher/data/sync/sync_engine.dart';
import 'package:teacher/features/attendance/data/attendance_models.dart';
import 'package:teacher/features/attendance/data/attendance_repository.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../support/fake_teachhub_server.dart';

const s1 = '00000000-0000-4000-8000-000000000001';
const s2 = '00000000-0000-4000-8000-000000000002';
String stId(int n) =>
    '10000000-0000-4000-8000-${n.toString().padLeft(12, '0')}';

Map<String, Object?> session(
  String id, {
  String date = '2026-11-18',
  String start = '08:00:00+07:00',
  String status = 'planned',
}) => {
  'id': id,
  'classId': '30000000-0000-4000-8000-000000000001',
  'className': id == s1 ? 'Toán 6A' : 'Lý 7B',
  'sessionDate': date,
  'startsAt': '${date}T$start',
  'endsAt': '${date}T09:30:00+07:00',
  'status': status,
  'isMakeup': false,
};

Map<String, Object?> roster(
  String id,
  int n, {
  String? recordedStatus,
  String sessionStatus = 'planned',
}) => {
  'sessionId': id,
  'classId': '30000000-0000-4000-8000-000000000001',
  'className': 'Toán 6A',
  'sessionDate': '2026-11-18',
  'startsAt': '2026-11-18T08:00:00+07:00',
  'sessionStatus': sessionStatus,
  'canEdit': true,
  'editableUntil': '2026-11-25T23:59:59+07:00',
  'serverTime': '2026-11-18T03:00:00.000Z',
  'items': [
    for (var i = 1; i <= n; i++)
      {
        'studentId': stId(i),
        'fullName': 'Em $i',
        'status': recordedStatus,
        'note': null,
        'clientUpdatedAt': recordedStatus == null
            ? null
            : '2026-11-18T02:00:00.000Z',
        'syncedAt': null,
      },
  ],
  'summary': {'present': 0, 'late': 0, 'excused': 0, 'unexcused': 0},
};

void main() {
  late TeacherDatabase db;
  late FakeTeachHubServer server;
  late DriftAttendanceRepository repo;
  late SyncEngine engine;
  var now = DateTime.utc(2026, 11, 18, 3, 5);

  setUp(() {
    now = DateTime.utc(2026, 11, 18, 3, 5);
    db = TeacherDatabase(NativeDatabase.memory());
    server = FakeTeachHubServer()
      ..serverTime = DateTime.utc(2026, 11, 18, 3, 5);
    final api = TeacherApi(
      server.dio(),
      deviceId: '20000000-0000-4000-8000-000000000001',
    );
    final clock = ClockSkew(now: () => now);
    engine = SyncEngine(db, api.sync, clock: clock, now: () => now);
    repo = DriftAttendanceRepository(
      database: () async => db,
      api: () async => api,
      engine: () async => engine,
      startSync: () async {},
      clock: clock,
    );
  });
  tearDown(() async {
    await engine.dispose();
    await db.close();
  });

  Future<void> seed({int students = 3}) async {
    server.sessions = [session(s2, start: '14:00:00+07:00'), session(s1)];
    server.attendance[s1] = roster(s1, students);
    server.attendance[s2] = roster(s2, students);
    await repo.refreshToday('2026-11-18');
  }

  test(
    'AC-1: buổi hôm nay sắp theo giờ, giờ tường theo offset +07:00',
    () async {
      await seed();
      final list = await repo.watchSessions('2026-11-18').first;
      expect(list.map((s) => (s.className, s.startTime, s.attended)), [
        ('Toán 6A', '08:00', false),
        ('Lý 7B', '14:00', false),
      ]);
    },
  );

  test('AC-2: đọc cache khi mất mạng; refresh lỗi ném network', () async {
    await seed();
    server.offline = true;
    await expectLater(
      repo.refreshToday('2026-11-18'),
      throwsA(
        isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.network),
      ),
    );
    expect((await repo.watchSessions('2026-11-18').first), hasLength(2));
    // Danh sách học viên cũng đã được tải sẵn để mở T04 ngoại tuyến.
    expect((await repo.watchSheet(s1).first)!.students, hasLength(3));
  });

  test('buổi cancelled không tải danh sách học viên', () async {
    server.sessions = [session(s1, status: 'cancelled')];
    await repo.refreshToday('2026-11-18');
    expect(
      (await repo.watchSessions('2026-11-18').first).single.cancelled,
      isTrue,
    );
    expect((await repo.watchSheet(s1).first)!.students, isEmpty);
  });

  test(
    'AC-7: Lưu 20 em < 100 ms, không đụng mạng, ghi cache và outbox',
    () async {
      await seed(students: 20);
      server.offline = true; // nếu Lưu chờ mạng thì sẽ ném/chậm
      final entries = <AttendanceEntry>[
        for (var i = 1; i <= 20; i++)
          (studentId: stId(i), status: AttendanceStatus.present, note: null),
      ];
      final repoNoPush = DriftAttendanceRepository(
        database: () async => db,
        api: () async => TeacherApi(server.dio(), deviceId: 'd'),
        engine: () async => null, // không đẩy: chỉ đo đường ghi cục bộ
        startSync: () async {},
        clock: ClockSkew(now: () => now),
      );

      final sw = Stopwatch()..start();
      await repoNoPush.save(s1, entries);
      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(100));
      expect(await pendingOutboxCount(db), 20);
      final sheet = await repo.watchSheet(s1).first;
      expect(
        sheet!.students.every((s) => s.status == AttendanceStatus.present),
        isTrue,
      );
      // Buổi đã có dòng ghi: hiện "đã điểm danh" ngay, trước khi sync xong.
      expect(
        (await repo.watchSessions('2026-11-18').first).first.attended,
        isTrue,
      );
    },
  );

  test(
    'Lưu rồi SyncEngine đẩy lên: outbox hết, server nhận đúng một lần',
    () async {
      await seed();
      await repo.save(s1, [
        (studentId: stId(1), status: AttendanceStatus.unexcused, note: 'ốm'),
        (studentId: stId(2), status: AttendanceStatus.present, note: null),
      ]);
      await engine.drain(); // chờ lượt đẩy đã chạy nền
      expect(await pendingOutboxCount(db), 0);
      expect(server.syncRequests, hasLength(1));
      final req = server.syncRequests.single.body;
      expect(req['markSessionTaught'], isTrue);
      expect((req['mutations'] as List), hasLength(2));
    },
  );

  test(
    'lưu hai lần liên tiếp cùng giây: mốc LWW của mỗi em vẫn tăng',
    () async {
      await seed();
      await repo.save(s1, [
        (studentId: stId(1), status: AttendanceStatus.late, note: null),
      ]);
      await repo.save(s1, [
        (studentId: stId(1), status: AttendanceStatus.present, note: null),
      ]);
      final rows = await (db.select(
        db.outboxMutations,
      )..orderBy([(r) => OrderingTerm(expression: r.id)])).get();
      expect(rows[1].clientUpdatedAt.isAfter(rows[0].clientUpdatedAt), isTrue);
    },
  );

  test(
    'AC-11: server từ chối → hiện trên em đó; discardFailed trả về bản server',
    () async {
      await seed();
      server.seedCurrent(
        s1,
        stId(1),
        status: 'present',
        clientUpdatedAt: DateTime.utc(2026, 11, 18, 1),
      );
      await repo.save(s1, [
        (studentId: stId(1), status: AttendanceStatus.unexcused, note: null),
      ]);
      final id =
          (await db.select(db.outboxMutations).getSingle()).clientMutationId;
      server.rejectIds[id] = 'ATTENDANCE_EDIT_WINDOW_CLOSED';
      await engine.drain();

      var sheet = (await repo.watchSheet(s1).first)!;
      expect(
        sheet.students.first.rejectedCode,
        'ATTENDANCE_EDIT_WINDOW_CLOSED',
      );
      expect(sheet.hasFailure, isTrue);
      expect(await pendingOutboxCount(db), 0); // không tính dòng bị từ chối

      server.attendance[s1] = roster(s1, 3, recordedStatus: 'present');
      await repo.discardFailed(s1);
      sheet = (await repo.watchSheet(s1).first)!;
      expect(sheet.hasFailure, isFalse);
      expect(sheet.students.first.status, AttendanceStatus.present);
      expect(await failedOutboxCount(db), 0);
    },
  );

  test('AC-11: lô lỗi cả buổi hiện batchErrorCode', () async {
    await seed();
    server.failSession[s1] = (409, 'SESSION_CANCELLED');
    await repo.save(s1, [
      (studentId: stId(1), status: AttendanceStatus.late, note: null),
    ]);
    await engine.drain();
    expect(
      (await repo.watchSheet(s1).first)!.batchErrorCode,
      'SESSION_CANCELLED',
    );
  });

  test('watchPending đếm outbox qua SyncEngine', () async {
    await seed();
    final counts = <int>[];
    final sub = repo.watchPending().listen(counts.add);
    addTearDown(sub.cancel);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    server.offline = true;
    await repo.save(s1, [
      (studentId: stId(1), status: AttendanceStatus.late, note: null),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(counts.last, 1);
  });

  test('AC-13: nhật ký sửa đọc theo trang, chỉ tên người sửa', () async {
    server.histories[s1] = [
      [
        {
          'id': 'h1',
          'studentId': stId(1),
          'studentName': 'Em 1',
          'changedByName': 'Cô Lan',
          'changedAt': '2026-11-18T19:50:00+07:00',
          'before': {'status': 'unexcused', 'note': null},
          'after': {'status': 'present', 'note': 'nhầm'},
        },
      ],
      [
        {
          'id': 'h2',
          'studentId': stId(1),
          'studentName': 'Em 1',
          'changedByName': null,
          'changedAt': '2026-11-18T09:00:00+07:00',
          'before': null,
          'after': {'status': 'unexcused', 'note': null},
        },
      ],
    ];
    final p1 = await repo.history(s1);
    expect(p1.items.single.changedByName, 'Cô Lan');
    expect(p1.items.single.before!.status, AttendanceStatus.unexcused);
    expect(p1.items.single.after!.note, 'nhầm');
    final p2 = await repo.history(s1, cursor: p1.nextCursor);
    expect(p2.items.single.before, isNull);
    expect(p2.nextCursor, isNull);
  });

  test('TeacherApi.offsetMinutes đọc offset từ chuỗi ISO', () {
    expect(TeacherApi.offsetMinutes('2026-11-18T08:00:00+07:00'), 420);
    expect(TeacherApi.offsetMinutes('2026-11-18T08:00:00-03:30'), -210);
    expect(TeacherApi.offsetMinutes('2026-11-18T01:00:00.000Z'), 0);
    expect(TeacherApi.offsetMinutes('2026-11-18T08:00:00'), isNull);
  });

  test(
    'hủy nghe trước khi CSDL sẵn sàng: không đăng ký tableUpdates',
    () async {
      final ready = Completer<TeacherDatabase>();
      final lazyRepo = DriftAttendanceRepository(
        database: () => ready.future,
        api: () async => TeacherApi(server.dio(), deviceId: 'd'),
        engine: () async => null,
        startSync: () async {},
        clock: ClockSkew(now: () => now),
      );
      var emitted = 0;
      final sub = lazyRepo.watchSessions('2026-11-18').listen((_) => emitted++);
      await sub.cancel();
      ready.complete(db);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(emitted, 0);
    },
  );
}
