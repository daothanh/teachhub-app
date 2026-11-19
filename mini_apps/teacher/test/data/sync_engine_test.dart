import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' show Database;
import 'package:teacher/data/local_db/teacher_database.dart';
import 'package:teacher/data/remote/teacher_api.dart';
import 'package:teacher/data/sync/enqueue_attendance.dart';
import 'package:teacher/data/sync/sync_engine.dart';

import '../support/fake_teachhub_server.dart';

/// `nextDouble()` cố định để kiểm [SyncEngine.backoff].
class _FixedRandom implements Random {
  _FixedRandom(this.value);
  final double value;
  @override
  double nextDouble() => value;
  @override
  bool nextBool() => false;
  @override
  int nextInt(int max) => 0;
}

const s1 = '00000000-0000-4000-8000-000000000001';
const s2 = '00000000-0000-4000-8000-000000000002';
const devId = '40000000-0000-4000-8000-000000000001';

String stu(int i) => '10000000-0000-4000-8000-${i.toString().padLeft(12, '0')}';
String mid(int i) => '20000000-0000-4000-8000-${i.toString().padLeft(12, '0')}';
DateTime at(int sec) => DateTime.utc(2026, 11, 18, 9, 0, sec);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late TeacherDatabase db;
  late FakeTeachHubServer server;
  late SyncEngine engine;
  var keyCounter = 0;

  SyncEngine makeEngine(
    TeacherDatabase d, {
    int batchSize = 500,
    Random? random,
  }) => SyncEngine(
    d,
    TeacherApi(server.dio(), deviceId: devId).sync,
    batchSize: batchSize,
    random: random ?? _FixedRandom(1),
    newKey: () =>
        '30000000-0000-4000-8000-${(++keyCounter).toString().padLeft(12, '0')}',
  );

  setUp(() {
    keyCounter = 0;
    db = TeacherDatabase(NativeDatabase.memory());
    server = FakeTeachHubServer();
    engine = makeEngine(db, batchSize: 2);
  });
  tearDown(() async {
    await engine.stop();
    await db.close();
  });

  Future<void> save(
    int i, {
    String session = s1,
    String status = 'present',
    int sec = 0,
    String? note,
  }) => enqueueAttendance(
    db,
    sessionId: session,
    studentId: stu(i),
    status: status,
    note: note,
    clientUpdatedAt: at(sec),
    clientMutationId: mid(i),
  );
  Future<List<OutboxMutation>> outbox() => db.select(db.outboxMutations).get();
  Future<void> seedRoster(int i, {String session = s1}) => db
      .into(db.cachedAttendances)
      .insert(
        CachedAttendancesCompanion.insert(
          sessionId: session,
          studentId: stu(i),
          fullName: 'HS $i',
        ),
      );

  test('một lô một buổi, ≤ batchSize, đúng thứ tự tạo; hết outbox', () async {
    await save(1);
    await save(2, session: s2);
    await save(3);
    await save(4);
    final report = await engine.drain();
    expect(report, (
      sent: 4,
      rejected: 0,
      failed: 0,
      blocked: 0,
      retryIn: null,
    ));
    expect(server.syncRequests.map((r) => r.body['sessionId']), [s1, s2, s1]);
    expect(
      [
        for (final r in server.syncRequests)
          [for (final m in r.body['mutations'] as List) m['clientMutationId']],
      ],
      [
        [mid(1), mid(3)],
        [mid(2)],
        [mid(4)],
      ],
    );
    expect(server.syncRequests.first.body['deviceId'], devId);
    expect(await outbox(), isEmpty);
  });

  test('lô lớn bị cắt ở 500 mutation', () async {
    final big = makeEngine(db);
    await db.batch(
      (b) => b.insertAll(db.outboxMutations, [
        for (var i = 0; i < 501; i++)
          OutboxMutationsCompanion.insert(
            clientMutationId: mid(i),
            entity: 'attendance',
            payload: '{"status":"present","note":null}',
            clientUpdatedAt: at(0),
            sessionId: const Value(s1),
            studentId: Value(stu(i)),
          ),
      ]),
    );
    await big.drain();
    expect(
      server.syncRequests.map((r) => (r.body['mutations'] as List).length),
      [500, 1],
    );
  });

  test('tắt mạng → lưu → bật mạng: lên đúng một lần', () async {
    server.offline = true;
    await save(1);
    await save(2);
    var report = await engine.drain();
    expect(report.retryIn, const Duration(seconds: 1));
    report = await engine.drain();
    expect(report.retryIn, const Duration(seconds: 2));
    expect((await outbox()).map((r) => (r.attemptCount, r.lastError)), [
      (2, 'network'),
      (2, 'network'),
    ]);

    server.offline = false;
    expect(await engine.drain(), (
      sent: 2,
      rejected: 0,
      failed: 0,
      blocked: 0,
      retryIn: null,
    ));
    expect(server.appliedCount, {mid(1): 1, mid(2): 1});
    expect(await outbox(), isEmpty);
  });

  test(
    'mất phản hồi giữa chừng: gửi lại cùng khóa, cùng thân, không trùng',
    () async {
      await save(1);
      server.dropNextResponse = true;
      expect((await engine.drain()).retryIn, isNotNull);
      expect(await outbox(), hasLength(1));

      expect((await engine.drain()).sent, 1);
      expect(server.appliedCount, {mid(1): 1});
      final [first, second] = server.syncRequests;
      expect(second.key, first.key);
      expect(second.body, first.body);
    },
  );

  test('lô mới (mutation thêm sau) dùng khóa mới', () async {
    server.offline = true;
    await save(1);
    await engine.drain();
    server.offline = false;
    await save(2, session: s1);
    await engine.drain();
    // Lô cũ giữ khóa cũ, mutation thêm sau đi lô riêng với khóa khác.
    expect(server.syncRequests.map((r) => r.key).toSet(), hasLength(2));
    expect(await outbox(), isEmpty);
  });

  test('gửi lặp cùng clientMutationId → duplicate, xóa khỏi outbox', () async {
    await save(1);
    await engine.drain();
    await save(1); // cùng clientMutationId, lô mới (khóa mới)
    final report = await engine.drain();
    expect(report.sent, 1);
    expect(server.syncRequests, hasLength(2));
    expect(server.appliedCount, {mid(1): 1});
    expect(await outbox(), isEmpty);
  });

  group('stale', () {
    test('ghi đè bản cục bộ bằng current và phát sự kiện', () async {
      await seedRoster(1);
      server.seedCurrent(
        s1,
        stu(1),
        status: 'excused',
        note: 'sốt',
        clientUpdatedAt: at(30),
      );
      await save(1, status: 'present', sec: 10);
      final events = <SyncEvent>[];
      engine.events.listen(events.add);

      expect((await engine.drain()).sent, 1);
      await pumpEventQueue();

      final row = await db.select(db.cachedAttendances).getSingle();
      expect(
        (row.status, row.note, row.clientUpdatedAt?.toUtc()),
        ('excused', 'sốt', at(30)),
      );
      expect(await outbox(), isEmpty);
      expect(events.single.kind, SyncEventKind.stale);
      expect(events.single.studentId, stu(1));
    });

    test('bằng nhau là stale: server thắng', () async {
      await seedRoster(1);
      server.seedCurrent(s1, stu(1), status: 'late', clientUpdatedAt: at(10));
      await save(1, status: 'present', sec: 10);
      await engine.drain();
      expect(
        (await db.select(db.cachedAttendances).getSingle()).status,
        'late',
      );
    });

    test('còn sửa mới chờ gửi thì không ghi đè bản cục bộ', () async {
      await seedRoster(1);
      server.seedCurrent(s1, stu(1), status: 'late', clientUpdatedAt: at(30));
      await save(1, status: 'present', sec: 10);
      // Người dùng sửa tiếp trong lúc chờ: mutation khác, cùng học viên.
      await enqueueAttendance(
        db,
        sessionId: s1,
        studentId: stu(1),
        status: 'unexcused',
        clientUpdatedAt: at(50),
        clientMutationId: mid(99),
      );
      final onlyFirst = makeEngine(db, batchSize: 1);
      await onlyFirst.drain();
      // mid(1) stale → xóa; mid(99) thắng LWW (50 > 30) → bản cục bộ là của người dùng.
      expect(
        (await db.select(db.cachedAttendances).getSingle()).status,
        'unexcused',
      );
    });
  });

  test('rejected: giữ kèm mã lỗi, phát banner, không gửi lại', () async {
    server.rejectIds[mid(1)] = 'ATTENDANCE_EDIT_WINDOW_CLOSED';
    await save(1);
    await save(2);
    final events = <SyncEvent>[];
    engine.events.listen(events.add);

    expect(await engine.drain(), (
      sent: 1,
      rejected: 1,
      failed: 0,
      blocked: 0,
      retryIn: null,
    ));
    await pumpEventQueue();
    expect(
      (await outbox()).single.lastError,
      'rejected:ATTENDANCE_EDIT_WINDOW_CLOSED',
    );
    expect(
      (events.single.kind, events.single.errorCode, events.single.studentId),
      (SyncEventKind.rejected, 'ATTENDANCE_EDIT_WINDOW_CLOSED', stu(1)),
    );
    expect(await engine.watchPending().first, 0);

    await engine.drain();
    expect(server.syncRequests, hasLength(1));
  });

  for (final (status, code) in [
    (409, 'SESSION_CANCELLED'),
    (404, 'NOT_FOUND'),
  ]) {
    test(
      '$status $code cả lô: đánh dấu lô lỗi, không retry, lô khác vẫn đi',
      () async {
        server.failSession[s1] = (status, code);
        await save(1);
        await save(2);
        await save(3, session: s2);
        final events = <SyncEvent>[];
        engine.events.listen(events.add);

        expect(await engine.drain(), (
          sent: 1,
          rejected: 0,
          failed: 2,
          blocked: 0,
          retryIn: null,
        ));
        await pumpEventQueue();
        expect((await outbox()).map((r) => r.lastError), [
          'batch:$code',
          'batch:$code',
        ]);
        expect(events.single.kind, SyncEventKind.batchFailed);
        expect(events.single.sessionId, s1);
        expect(events.single.errorCode, code);

        final before = server.syncRequests.length;
        await engine.drain();
        expect(
          server.syncRequests,
          hasLength(before),
          reason: 'không thử lại lô lỗi',
        );
        expect(await engine.watchPending().first, 0);
      },
    );
  }

  test(
    '409 IDEMPOTENCY_IN_PROGRESS là lỗi tạm: thử lại, không đánh dấu lô lỗi',
    () async {
      server.failSession[s1] = (409, 'IDEMPOTENCY_IN_PROGRESS');
      await save(1);
      final report = await engine.drain();
      expect(report.retryIn, isNotNull);
      expect((await outbox()).single.lastError, 'IDEMPOTENCY_IN_PROGRESS');
    },
  );

  test('5xx: backoff rồi thành công', () async {
    server.serverErrors = 1;
    await save(1);
    expect((await engine.drain()).retryIn, const Duration(seconds: 1));
    expect((await engine.drain()).sent, 1);
  });

  test(
    'kết quả thiếu trong phản hồi: thử lại sau với khóa mới, không lặp vô hạn',
    () async {
      server.skipIds.add(mid(2));
      await save(1);
      await save(2);
      final report = await engine.drain();
      expect(report.sent, 1);
      expect(report.retryIn, const Duration(seconds: 1));
      expect((await outbox()).single.lastError, 'MISSING_RESULT');

      server.skipIds.clear();
      expect((await engine.drain()).sent, 1);
      // Thân lô thứ hai chỉ còn một mutation nên phải là khóa khác (không bị 422).
      expect(server.syncRequests.map((r) => r.key).toSet(), hasLength(2));
    },
  );

  test('lỗi không tự hết (403) dừng, không đặt lịch thử lại', () async {
    server.failSession[s1] = (403, 'FORBIDDEN');
    await save(1);
    expect(await engine.drain(), (
      sent: 0,
      rejected: 0,
      failed: 0,
      blocked: 1,
      retryIn: null,
    ));
    expect((await outbox()).single.lastError, 'FORBIDDEN');
  });

  group('backoff', () {
    test('gấp đôi, có trần 1 giờ', () {
      final e = makeEngine(db, random: _FixedRandom(1));
      expect(e.backoff(1), const Duration(seconds: 1));
      expect(e.backoff(3), const Duration(seconds: 4));
      expect(e.backoff(50), const Duration(hours: 1));
    });

    test('jitter giảm tối đa một nửa, không vượt trần', () {
      final low = makeEngine(db, random: _FixedRandom(0));
      expect(low.backoff(3), const Duration(seconds: 2));
      expect(low.backoff(50), const Duration(minutes: 30));
      final rnd = makeEngine(db, random: Random(7));
      for (var n = 1; n < 40; n++) {
        final d = rnd.backoff(n);
        final base = min(1 << min(n - 1, 12), 3600);
        expect(d.inMilliseconds, inInclusiveRange(base * 500, base * 1000));
      }
    });
  });

  test('hiệu chỉnh lệch đồng hồ theo serverTime', () async {
    var device = DateTime.utc(2026, 11, 18, 9, 50);
    final e = SyncEngine(
      db,
      TeacherApi(server.dio(), deviceId: devId).sync,
      now: () => device,
    );
    await save(1);
    await e.drain(); // server 10:00, máy 09:50 (cả chuyến đi cùng một lúc)
    expect(e.clock.offset, const Duration(minutes: 10));
    device = DateTime.utc(2026, 11, 18, 9, 55);
    expect(e.clock.now(), DateTime.utc(2026, 11, 18, 10, 5));
  });

  test('chip: watchPending theo dõi số mutation chờ gửi', () async {
    final seen = <int>[];
    final sub = engine.watchPending().listen(seen.add);
    await pumpEventQueue();
    await save(1);
    await save(2);
    await pumpEventQueue();
    await engine.drain();
    await pumpEventQueue();
    await sub.cancel();
    expect(seen.first, 0);
    expect(seen, contains(2));
    expect(seen.last, 0);
  });

  test('dòng thiếu buổi/học viên không bao giờ được gửi', () async {
    await db
        .into(db.outboxMutations)
        .insert(
          OutboxMutationsCompanion.insert(
            clientMutationId: mid(1),
            entity: 'attendance',
            payload: '{}',
            clientUpdatedAt: at(0),
          ),
        );
    expect((await engine.drain()).sent, 0);
    expect(server.syncRequests, isEmpty);
  });

  group('lỗi một buổi không chặn buổi khác', () {
    for (final (status, code) in [
      (422, 'VALIDATION_FAILED'),
      (403, 'FORBIDDEN'),
    ]) {
      test('$status $code ở buổi A: buổi B vẫn gửi trong cùng lượt', () async {
        server.failSession[s1] = (status, code);
        await save(1);
        await save(2, session: s2);
        final report = await engine.drain();
        expect(report.sent, 1);
        expect(report.retryIn, isNull);
        expect(server.appliedCount, {mid(2): 1});
        final left = await outbox();
        expect(left.single.clientMutationId, mid(1));
        // 422 là lỗi lô (không gửi lại); 403 giữ chờ gửi.
        expect(left.single.lastError, status == 422 ? 'batch:$code' : code);
      });
    }

    test(
      '422 IDEMPOTENCY_KEY_REUSED: gom lại với khóa mới đúng một lần',
      () async {
        server.failSessionOnce[s1] = (422, 'IDEMPOTENCY_KEY_REUSED');
        await save(1);
        final report = await engine.drain();
        expect(report.sent, 1);
        // Lần đầu bị từ chối, lần hai gom lại với khóa mới.
        expect(server.syncRequests.map((r) => r.key).toSet(), hasLength(2));
        expect(await outbox(), isEmpty);
      },
    );

    test('422 IDEMPOTENCY_KEY_REUSED lặp lại: đánh dấu lô lỗi', () async {
      server.failSession[s1] = (422, 'IDEMPOTENCY_KEY_REUSED');
      await save(1);
      final report = await engine.drain();
      expect(report.failed, 1);
      expect((await outbox()).single.lastError, 'batch:IDEMPOTENCY_KEY_REUSED');
    });
  });

  test('enqueue lúc lô đang bay: dòng mới đi lô sau với khóa khác', () async {
    final gate = Completer<void>();
    final api = TeacherApi(server.dio(), deviceId: devId);
    final e = SyncEngine(
      db,
      (req) async {
        await gate.future;
        return api.sync(req);
      },
      newKey: () =>
          '30000000-0000-4000-8000-${(++keyCounter).toString().padLeft(12, '0')}',
    );
    await save(1);
    final running = e.drain();
    await pumpEventQueue();
    await save(2);
    gate.complete();
    final report = await running;
    expect(report.sent, 2);
    expect(server.syncRequests.map((r) => r.key).toSet(), hasLength(2));
    expect(await outbox(), isEmpty);
  });

  test('stop() khi transport chậm không phải chờ transport', () async {
    final never = Completer<SyncResponse>();
    final e = SyncEngine(db, (_) => never.future);
    await save(1);
    e.start(const Stream.empty());
    await pumpEventQueue();
    await e.stop().timeout(const Duration(seconds: 2));
    expect((await outbox()).single.batchKey, isNotNull);
  });

  test('transport quá hạn được coi như mất mạng', () async {
    final e = SyncEngine(
      db,
      (_) => Completer<SyncResponse>().future,
      sendTimeout: const Duration(milliseconds: 20),
      random: _FixedRandom(1),
    );
    await save(1);
    final report = await e.drain();
    expect(report.retryIn, const Duration(seconds: 1));
    expect((await outbox()).single.lastError, 'network');
  });

  test(
    'lỗi ngoài dự kiến trong lượt tự động: không văng, thử lại sau',
    () async {
      var calls = 0;
      final api = TeacherApi(server.dio(), deviceId: devId);
      final e = SyncEngine(db, (req) {
        if (++calls == 1) throw StateError('db');
        return api.sync(req);
      }, random: _FixedRandom(0));
      await save(1);
      e.start(Stream.value(false));
      await pumpEventQueue();
      expect(calls, 1);
      await Future<void>.delayed(
        const Duration(milliseconds: 700),
      ); // backoff(1) ≥ 0,5s
      expect(server.appliedCount, {mid(1): 1});
      await e.dispose();
    },
  );

  group('enqueueAttendance', () {
    test(
      'hai lần sửa trong cùng một giây: lần hai mới hơn, không bị stale',
      () async {
        await seedRoster(1);
        await save(1, status: 'present', sec: 10);
        await enqueueAttendance(
          db,
          sessionId: s1,
          studentId: stu(1),
          status: 'excused',
          clientUpdatedAt: at(10),
        );
        final times = (await outbox())
            .map((r) => r.clientUpdatedAt.toUtc())
            .toList();
        expect(times.first, at(10));
        expect(times.last.isAfter(times.first), isTrue);
        await engine.drain();
        final row = await db.select(db.cachedAttendances).getSingle();
        expect(row.status, 'excused');
      },
    );
  });

  test('stale: dòng đã bị từ chối không chặn ghi đè bản server', () async {
    await seedRoster(1);
    server.rejectIds[mid(98)] = 'ATTENDANCE_EDIT_WINDOW_CLOSED';
    await enqueueAttendance(
      db,
      sessionId: s1,
      studentId: stu(1),
      status: 'late',
      clientUpdatedAt: at(5),
      clientMutationId: mid(98),
    );
    await engine.drain(); // mid(98) rejected, giữ lại
    server.seedCurrent(s1, stu(1), status: 'excused', clientUpdatedAt: at(40));
    await save(1, status: 'present', sec: 20);
    await engine.drain();
    expect(
      (await db.select(db.cachedAttendances).getSingle()).status,
      'excused',
    );
  });

  test('gọi drain chồng nhau dùng chung một lượt', () async {
    await save(1);
    final a = engine.drain(), b = engine.drain();
    expect(identical(a, b), isTrue);
    await a;
    expect(server.syncRequests, hasLength(1));
  });

  test('stop() chờ lượt đang chạy và sau đó drain không làm gì', () async {
    await save(1);
    final running = engine.drain();
    await engine.stop();
    await running;
    await save(2);
    expect((await engine.drain()).sent, 0);
  });

  test('start() đẩy lại khi có mạng trở lại', () async {
    final online = StreamController<bool>();
    server.offline = true;
    await save(1);
    engine.start(online.stream);
    await pumpEventQueue();
    expect(server.appliedCount, isEmpty);

    server.offline = false;
    online.add(true);
    await pumpEventQueue();
    expect(server.appliedCount, {mid(1): 1});
    expect(await outbox(), isEmpty);
    await online.close();
  });

  test(
    'kill app rồi mở lại: outbox còn trên file, gửi lại đúng khóa, không trùng',
    () async {
      final dir = Directory.systemTemp.createTempSync('teacher_sync');
      addTearDown(() => dir.deleteSync(recursive: true));
      TeacherDatabase open() => TeacherDatabase(
        NativeDatabase(
          File('${dir.path}/teacher.sqlite'),
          setup: (Database d) => encryptionSetup('cd' * 32)(d),
        ),
      );

      // Phiên 1: lưu 2 điểm danh, server áp dụng nhưng phản hồi mất, rồi app bị kill.
      final first = open();
      await enqueueAttendance(
        first,
        sessionId: s1,
        studentId: stu(1),
        status: 'present',
        clientUpdatedAt: at(1),
        clientMutationId: mid(1),
      );
      await enqueueAttendance(
        first,
        sessionId: s1,
        studentId: stu(2),
        status: 'late',
        note: 'kẹt xe',
        clientUpdatedAt: at(2),
        clientMutationId: mid(2),
      );
      server.dropNextResponse = true;
      expect((await makeEngine(first).drain()).retryIn, isNotNull);
      await first.close();

      // Phiên 2: mở lại file, engine mới (khóa sinh mới cũng không được dùng).
      final second = open();
      addTearDown(second.close);
      expect(
        (await second.select(second.outboxMutations).get()).map(
          (r) => r.attemptCount,
        ),
        [1, 1],
      );
      final report = await makeEngine(second).drain();
      expect(report.sent, 2);
      expect(server.appliedCount, {mid(1): 1, mid(2): 1});
      final [a, b] = server.syncRequests;
      expect(b.key, a.key);
      expect(b.body, a.body);
      expect(await second.select(second.outboxMutations).get(), isEmpty);
    },
  );
}
