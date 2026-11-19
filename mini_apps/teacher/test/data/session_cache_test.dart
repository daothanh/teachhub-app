import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/data/cache/session_cache.dart';
import 'package:teacher/data/local_db/teacher_database.dart';
import 'package:teacher/data/remote/teacher_api.dart';
import 'package:teacher/data/sync/clock_skew.dart';
import 'package:teacher/data/sync/enqueue_attendance.dart';

import '../support/fake_teachhub_server.dart';

const s1 = '00000000-0000-4000-8000-000000000001';
const s2 = '00000000-0000-4000-8000-000000000002';
const a = '10000000-0000-4000-8000-00000000000a';
const b = '10000000-0000-4000-8000-00000000000b';

Map<String, Object?> session(
  String id,
  String date, {
  String status = 'planned',
}) => {
  'id': id,
  'classId': '30000000-0000-4000-8000-000000000001',
  'className': 'Toán 6A',
  'sessionDate': date,
  'startsAt': '${date}T01:00:00.000Z',
  'endsAt': '${date}T02:30:00.000Z',
  'status': status,
  'isMakeup': false,
};

Map<String, Object?> roster(
  String sessionId,
  List<Map<String, Object?>> items,
) => {
  'sessionId': sessionId,
  'classId': '30000000-0000-4000-8000-000000000001',
  'className': 'Toán 6A',
  'sessionDate': '2026-11-18',
  'startsAt': '2026-11-18T01:00:00.000Z',
  'sessionStatus': 'planned',
  'canEdit': true,
  'editableUntil': '2026-11-25T16:59:59.000Z',
  'serverTime': '2026-11-18T10:00:00.000Z',
  'items': items,
  'summary': {'present': 0, 'late': 0, 'excused': 0, 'unexcused': 0},
};

Map<String, Object?> item(
  String id,
  String name, {
  String? status,
  String? note,
}) => {
  'studentId': id,
  'fullName': name,
  'status': status,
  'note': note,
  'clientUpdatedAt': status == null ? null : '2026-11-18T09:00:00.000Z',
  'syncedAt': null,
};

void main() {
  late TeacherDatabase db;
  late FakeTeachHubServer server;
  late SessionCache cache;
  late ClockSkew clock;

  setUp(() {
    db = TeacherDatabase(NativeDatabase.memory());
    server = FakeTeachHubServer();
    clock = ClockSkew(now: () => DateTime.utc(2026, 11, 18, 9, 59));
    cache = SessionCache(
      db,
      TeacherApi(server.dio(), deviceId: 'd'),
      clock: clock,
      now: () => DateTime.utc(2026, 11, 18, 9, 59),
    );
  });
  tearDown(() => db.close());

  test('refreshSessions lưu buổi; mở lại vẫn đọc được khi mất mạng', () async {
    server.sessions = [session(s1, '2026-11-18'), session(s2, '2026-11-19')];
    await cache.refreshSessions('2026-11-18', '2026-11-20');

    server.offline = true;
    await expectLater(
      cache.refreshSessions('2026-11-18', '2026-11-20'),
      throwsA(isA<Object>()),
    );
    final rows = await cache.watchSessions('2026-11-18', '2026-11-20').first;
    expect(rows.map((r) => (r.id, r.className, r.canEdit)), [
      (s1, 'Toán 6A', null),
      (s2, 'Toán 6A', null),
    ]);
  });

  test(
    'buổi biến mất khỏi server bị bỏ, trừ buổi còn mutation chưa gửi',
    () async {
      server.sessions = [session(s1, '2026-11-18'), session(s2, '2026-11-19')];
      await cache.refreshSessions('2026-11-18', '2026-11-20');
      await enqueueAttendance(
        db,
        sessionId: s2,
        studentId: a,
        status: 'present',
        clientUpdatedAt: DateTime.utc(2026, 11, 19),
      );

      server.sessions = [];
      await cache.refreshSessions('2026-11-18', '2026-11-20');
      expect((await db.select(db.cachedSessions).get()).map((r) => r.id), [s2]);
    },
  );

  test(
    'refreshAttendance lưu danh sách học viên, quyền sửa và đo lệch đồng hồ',
    () async {
      server.sessions = [session(s1, '2026-11-18')];
      await cache.refreshSessions('2026-11-18', '2026-11-18');
      server.attendance[s1] = roster(s1, [
        item(b, 'Bình'),
        item(a, 'An', status: 'late', note: 'kẹt xe'),
      ]);
      await cache.refreshAttendance(s1);

      final r = await cache.watchRoster(s1).first;
      expect(r.map((x) => (x.fullName, x.status, x.note)), [
        ('An', 'late', 'kẹt xe'),
        ('Bình', null, null),
      ]);
      final s = await db.select(db.cachedSessions).getSingle();
      expect(
        (s.canEdit, s.editableUntil?.toUtc()),
        (true, DateTime.utc(2026, 11, 25, 16, 59, 59)),
      );
      expect(clock.offset, const Duration(minutes: 1));
    },
  );

  test(
    'làm mới không ghi đè điểm danh còn chờ đồng bộ; học viên rời lớp bị bỏ',
    () async {
      server.sessions = [session(s1, '2026-11-18')];
      await cache.refreshSessions('2026-11-18', '2026-11-18');
      server.attendance[s1] = roster(s1, [item(a, 'An'), item(b, 'Bình')]);
      await cache.refreshAttendance(s1);
      await enqueueAttendance(
        db,
        sessionId: s1,
        studentId: a,
        status: 'excused',
        clientUpdatedAt: DateTime.utc(2026, 11, 18, 9),
      );

      server.attendance[s1] = roster(s1, [item(a, 'An', status: 'present')]);
      await cache.refreshAttendance(s1);

      final rows = await db.select(db.cachedAttendances).get();
      expect(rows.map((x) => (x.studentId, x.status)), [(a, 'excused')]);
    },
  );

  test('buổi bị xóa kéo theo danh sách học viên của nó', () async {
    server.sessions = [session(s1, '2026-11-18')];
    await cache.refreshSessions('2026-11-18', '2026-11-18');
    server.attendance[s1] = roster(s1, [item(a, 'An')]);
    await cache.refreshAttendance(s1);

    server.sessions = [];
    await cache.refreshSessions('2026-11-18', '2026-11-18');
    expect(await db.select(db.cachedAttendances).get(), isEmpty);
  });
}
