import 'dart:async';

import 'package:drift/drift.dart';
import 'package:get_it/get_it.dart';

import '../../../data/cache/session_cache.dart';
import '../../../data/cache/wall_time.dart';
import '../../../data/local_db/teacher_database.dart';
import '../../../data/remote/teacher_api.dart';
import '../../../data/sync/clock_skew.dart';
import '../../../data/sync/enqueue_attendance.dart';
import '../../../data/sync/sync_engine.dart';
import 'attendance_models.dart';

/// Nguồn dữ liệu của "Hôm nay" (T03) và điểm danh (T04): đọc cache Drift, làm
/// mới từ API, ghi qua outbox. Màn không đụng tới Drift hay Dio.
abstract class AttendanceRepository {
  /// Bật SyncEngine (vào màn chính của giáo viên).
  Future<void> startSync();

  /// Giờ server ước lượng (giờ máy cộng lệch đã đo): dùng để xét hạn sửa.
  DateTime serverNow();

  /// Số mutation chờ gửi (chip "Chờ đồng bộ").
  Stream<int> watchPending();

  Stream<List<TodaySession>> watchSessions(String date);

  /// `GET /sessions` của ngày và danh sách học viên từng buổi (để mở T04 được
  /// khi mất mạng). Lỗi danh sách buổi ném [ApiException]; lỗi từng danh sách
  /// học viên được bỏ qua.
  Future<void> refreshToday(String date);

  Stream<SessionSheet?> watchSheet(String sessionId);
  Future<void> refreshSheet(String sessionId);

  /// Ghi cục bộ rồi đẩy lên nền; không chờ mạng.
  Future<void> save(String sessionId, List<AttendanceEntry> entries);

  /// Bỏ các bản ghi bị từ chối/lô lỗi của buổi, trả bản cục bộ về bản server.
  Future<void> discardFailed(String sessionId);

  Future<HistoryChunk> history(String sessionId, {String? cursor});
}

/// Bản dùng thật; [TeacherController] đăng ký vào GetIt.
AttendanceRepository attendanceRepository() => GetIt.I<AttendanceRepository>();

class DriftAttendanceRepository implements AttendanceRepository {
  DriftAttendanceRepository({
    required Future<TeacherDatabase> Function() database,
    required Future<TeacherApi> Function() api,
    required Future<SyncEngine?> Function() engine,
    required Future<void> Function() startSync,
    required this.clock,
  }) : _db = database,
       _api = api,
       _engine = engine,
       _startSync = startSync;

  // Lấy CSDL qua hàm mỗi lần (không giữ instance): đăng xuất xóa rồi mở lại.
  final Future<TeacherDatabase> Function() _db;
  final Future<TeacherApi> Function() _api;

  /// Engine đang chạy, null khi chưa bật hoặc đã dừng (đăng xuất). Không tự
  /// bật lại: chỉ màn chính gọi [startSync].
  final Future<SyncEngine?> Function() _engine;
  final Future<void> Function() _startSync;
  final ClockSkew clock;

  Future<SessionCache> _cache() async =>
      SessionCache(await _db(), await _api(), clock: clock);

  @override
  Future<void> startSync() => _startSync();

  @override
  DateTime serverNow() => clock.now();

  @override
  Stream<int> watchPending() async* {
    final engine = await _engine();
    yield* engine?.watchPending() ?? Stream.value(0);
  }

  /// Chạy [load] lúc nghe và mỗi khi một trong [tables] đổi; lượt chồng nhau
  /// gộp thành một lượt đọc lại.
  Stream<T> _watch<T>(
    List<TableInfo> Function(TeacherDatabase) tables,
    Future<T> Function(TeacherDatabase) load,
  ) {
    late final StreamController<T> out;
    StreamSubscription<void>? sub;
    var busy = false, dirty = false;
    Future<void> run(TeacherDatabase db) async {
      if (busy) {
        dirty = true;
        return;
      }
      busy = true;
      try {
        do {
          dirty = false;
          final v = await load(db);
          if (!out.isClosed) out.add(v);
        } while (dirty);
      } catch (e, st) {
        if (!out.isClosed) out.addError(e, st);
      } finally {
        busy = false;
      }
    }

    out = StreamController<T>(
      onListen: () async {
        final db = await _db();
        if (out.isClosed || !out.hasListener) return; // đã hủy trong lúc chờ
        sub = db
            .tableUpdates(TableUpdateQuery.onAllTables(tables(db)))
            .listen((_) => run(db));
        await run(db);
      },
      onCancel: () => sub?.cancel(),
    );
    return out.stream;
  }

  @override
  Stream<List<TodaySession>> watchSessions(String date) =>
      _watch((db) => [db.cachedSessions, db.cachedAttendances], (db) async {
        final sessions =
            await (db.select(db.cachedSessions)
                  ..where((s) => s.sessionDate.equals(date))
                  ..orderBy([(s) => OrderingTerm(expression: s.startsAt)]))
                .get();
        final a = db.cachedAttendances;
        final recorded =
            (await (db.selectOnly(a, distinct: true)
                      ..addColumns([a.sessionId])
                      ..where(
                        a.status.isNotNull() &
                            a.sessionId.isIn(sessions.map((s) => s.id)),
                      ))
                    .map((r) => r.read(a.sessionId))
                    .get())
                .toSet();
        return [
          for (final s in sessions)
            TodaySession(
              id: s.id,
              className: s.className,
              startTime: wallTime(s.startsAt, s.tzOffsetMinutes),
              cancelled: s.status == 'cancelled',
              attended: s.status == 'taught' || recorded.contains(s.id),
            ),
        ];
      });

  @override
  Future<void> refreshToday(String date) async {
    final cache = await _cache();
    await cache.refreshSessions(date, date);
    final db = await _db();
    final ids =
        await (db.selectOnly(db.cachedSessions)
              ..addColumns([db.cachedSessions.id])
              ..where(
                db.cachedSessions.sessionDate.equals(date) &
                    db.cachedSessions.status.equals('cancelled').not(),
              ))
            .map((r) => r.read(db.cachedSessions.id)!)
            .get();
    await Future.wait([
      for (final id in ids)
        cache.refreshAttendance(id).then((_) {}, onError: (Object _) {}),
    ]);
  }

  @override
  Stream<SessionSheet?> watchSheet(String sessionId) => _watch(
    (db) => [db.cachedSessions, db.cachedAttendances, db.outboxMutations],
    (db) => _loadSheet(db, sessionId),
  );

  Future<SessionSheet?> _loadSheet(TeacherDatabase db, String id) async {
    final s = await (db.select(
      db.cachedSessions,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (s == null) return null;
    final rows =
        await (db.select(db.cachedAttendances)
              ..where((r) => r.sessionId.equals(id))
              ..orderBy([(r) => OrderingTerm(expression: r.fullName)]))
            .get();
    final rejected = <String, String>{};
    String? batchError;
    for (final m in await _failed(db, id)) {
      final err = m.lastError!;
      if (err.startsWith(batchFailedPrefix)) {
        batchError = err.substring(batchFailedPrefix.length);
      } else if (m.studentId != null) {
        rejected[m.studentId!] = err.substring(rejectedPrefix.length);
      }
    }
    return SessionSheet(
      sessionId: id,
      className: s.className,
      sessionDate: s.sessionDate,
      startTime: wallTime(s.startsAt, s.tzOffsetMinutes),
      cancelled: s.status == 'cancelled',
      canEdit: s.canEdit,
      editableUntil: s.editableUntil,
      batchErrorCode: batchError,
      students: [
        for (final r in rows)
          SheetStudent(
            studentId: r.studentId,
            fullName: r.fullName,
            status: AttendanceStatus.fromWire(r.status),
            note: r.note,
            rejectedCode: rejected[r.studentId],
          ),
      ],
    );
  }

  Future<List<OutboxMutation>> _failed(TeacherDatabase db, String sessionId) =>
      (db.select(db.outboxMutations)..where(
            (r) => r.sessionId.equals(sessionId) & outboxPending(r).not(),
          ))
          .get();

  @override
  Future<void> refreshSheet(String sessionId) async =>
      (await _cache()).refreshAttendance(sessionId);

  @override
  Future<void> save(String sessionId, List<AttendanceEntry> entries) async {
    final db = await _db();
    await enqueueAttendanceBatch(
      db,
      sessionId: sessionId,
      writes: [
        for (final e in entries)
          (studentId: e.studentId, status: e.status.name, note: e.note),
      ],
      clientUpdatedAt: clock.now(),
    );
    unawaited(_pushNow());
  }

  /// Đẩy ngay sau khi lưu; engine tự thử lại khi lỗi nên bỏ qua kết quả.
  Future<void> _pushNow() async {
    try {
      await (await _engine())?.drain();
    } catch (_) {}
  }

  @override
  Future<void> discardFailed(String sessionId) async {
    final db = await _db();
    await db.transaction(() async {
      final failed = await _failed(db, sessionId);
      // Bản cục bộ bị từ chối không còn chờ gửi: bỏ mốc LWW để lần tải sau lấy
      // bản của server.
      await (db.update(db.cachedAttendances)..where(
            (r) =>
                r.sessionId.equals(sessionId) &
                r.studentId.isIn(failed.map((m) => m.studentId ?? '')),
          ))
          .write(
            const CachedAttendancesCompanion(clientUpdatedAt: Value(null)),
          );
      await (db.delete(
        db.outboxMutations,
      )..where((r) => r.id.isIn(failed.map((m) => m.id)))).go();
    });
    try {
      await refreshSheet(sessionId);
    } catch (_) {} // ngoại tuyến: tải lại khi có mạng
  }

  @override
  Future<HistoryChunk> history(String sessionId, {String? cursor}) async {
    final page = await (await _api()).history(sessionId, cursor: cursor);
    HistorySnapshot? snap(HistorySnapshotDto? d) => d == null
        ? null
        : HistorySnapshot(
            status: AttendanceStatus.fromWire(d.status),
            note: d.note,
          );
    return HistoryChunk([
      for (final i in page.items)
        HistoryItem(
          id: i.id,
          studentName: i.studentName,
          changedByName: i.changedByName,
          changedAt: i.changedAt,
          before: snap(i.before),
          after: snap(i.after),
        ),
    ], page.nextCursor);
  }
}
