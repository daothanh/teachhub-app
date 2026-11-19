import 'package:drift/drift.dart';

import '../local_db/teacher_database.dart';
import '../remote/teacher_api.dart';
import '../sync/clock_skew.dart';

/// Cache ngoại tuyến của buổi học và danh sách học viên của buổi (spec §6.4,
/// S3-FL-10). Màn hình đọc từ đây; [refreshSessions]/[refreshAttendance] làm
/// mới từ API khi mở lại hoặc kéo xuống.
///
/// Bản cục bộ mới hơn thắng: dòng điểm danh đang chờ gửi, hoặc có
/// `clientUpdatedAt` không cũ hơn của server, không bị ghi đè bởi dữ liệu tải về.
class SessionCache {
  SessionCache(
    this._db,
    this._api, {
    ClockSkew? clock,
    DateTime Function()? now,
  }) : _clock = clock,
       _now = now ?? DateTime.now;

  final TeacherDatabase _db;
  final TeacherApi _api;
  final ClockSkew? _clock;
  final DateTime Function() _now;

  /// Buổi trong khoảng ngày `yyyy-MM-dd` (gồm hai đầu), theo giờ bắt đầu.
  Stream<List<CachedSession>> watchSessions(String from, String to) =>
      (_db.select(_db.cachedSessions)
            ..where((s) => s.sessionDate.isBetweenValues(from, to))
            ..orderBy([(s) => OrderingTerm(expression: s.startsAt)]))
          .watch();

  Stream<List<CachedAttendance>> watchRoster(String sessionId) =>
      (_db.select(_db.cachedAttendances)
            ..where((a) => a.sessionId.equals(sessionId))
            ..orderBy([(a) => OrderingTerm(expression: a.fullName)]))
          .watch();

  /// `GET /sessions?from&to`: thay toàn bộ buổi của khoảng ngày bằng kết quả
  /// của server. Buổi biến mất khỏi server (lớp lưu trữ, xóa) bị bỏ, trừ buổi
  /// còn mutation chưa đồng bộ.
  Future<void> refreshSessions(String from, String to) async {
    final sessions = await _api.sessions(from, to);
    final s = _db.cachedSessions;
    final withOutbox = _db.selectOnly(_db.outboxMutations)
      ..addColumns([_db.outboxMutations.sessionId])
      ..where(_db.outboxMutations.sessionId.isNotNull());
    await _db.transaction(() async {
      final gone = _db.select(s)
        ..where(
          (r) =>
              r.sessionDate.isBetweenValues(from, to) &
              r.id.isNotIn(sessions.map((x) => x.id)) &
              r.id.isNotInQuery(withOutbox),
        );
      final goneIds = (await gone.get()).map((r) => r.id).toList();
      await (_db.delete(
        _db.cachedAttendances,
      )..where((a) => a.sessionId.isIn(goneIds))).go();
      await (_db.delete(s)..where((r) => r.id.isIn(goneIds))).go();
      for (final x in sessions) {
        // Companion không có canEdit/editableUntil: upsert giữ nguyên các cột đó.
        await _db
            .into(s)
            .insertOnConflictUpdate(
              CachedSessionsCompanion.insert(
                id: x.id,
                classId: x.classId,
                className: x.className,
                sessionDate: x.sessionDate,
                startsAt: x.startsAt,
                endsAt: x.endsAt,
                status: x.status,
                isMakeup: x.isMakeup,
                tzOffsetMinutes: Value(x.tzOffsetMinutes),
              ),
            );
      }
    });
  }

  /// `GET /sessions/{id}/attendance`: làm mới danh sách học viên và quyền sửa
  /// của buổi. Gọi [refreshSessions] trước để buổi có trong cache (không có thì
  /// chỉ lưu danh sách học viên, chưa có `canEdit`).
  Future<void> refreshAttendance(String sessionId) async {
    final sentAt = _now();
    final data = await _api.attendance(sessionId);
    _clock?.observe(data.serverTime, sentAt: sentAt, receivedAt: _now());

    final a = _db.cachedAttendances;
    await _db.transaction(() async {
      await (_db.update(
        _db.cachedSessions,
      )..where((r) => r.id.equals(sessionId))).write(
        CachedSessionsCompanion(
          status: Value(data.sessionStatus),
          canEdit: Value(data.canEdit),
          editableUntil: Value(data.editableUntil),
          rosterFetchedAt: Value(data.serverTime),
        ),
      );
      final o = _db.outboxMutations;
      final pending =
          (await (_db.selectOnly(o)
                    ..addColumns([o.studentId])
                    ..where(o.sessionId.equals(sessionId) & outboxPending(o)))
                  .map((r) => r.read(o.studentId))
                  .get())
              .whereType<String>()
              .toSet();
      await (_db.delete(a)..where(
            (r) =>
                r.sessionId.equals(sessionId) &
                r.studentId.isNotIn(data.items.map((i) => i.studentId)) &
                r.studentId.isNotIn(pending),
          ))
          .go();
      final local = {
        for (final r in await (_db.select(
          a,
        )..where((r) => r.sessionId.equals(sessionId))).get())
          r.studentId: r,
      };
      for (final i in data.items) {
        final mine = local[i.studentId]?.clientUpdatedAt;
        // Bản cục bộ đang chờ gửi, hoặc không cũ hơn bản server: giữ, chỉ cập
        // nhật tên.
        final keep =
            pending.contains(i.studentId) ||
            (mine != null &&
                (i.clientUpdatedAt == null ||
                    !mine.isBefore(i.clientUpdatedAt!)));
        if (keep && local.containsKey(i.studentId)) {
          await (_db.update(a)..where(
                (r) =>
                    r.sessionId.equals(sessionId) &
                    r.studentId.equals(i.studentId),
              ))
              .write(CachedAttendancesCompanion(fullName: Value(i.fullName)));
          continue;
        }
        await _db
            .into(a)
            .insertOnConflictUpdate(
              CachedAttendancesCompanion.insert(
                sessionId: sessionId,
                studentId: i.studentId,
                fullName: i.fullName,
                status: Value(i.status),
                note: Value(i.note),
                clientUpdatedAt: Value(i.clientUpdatedAt),
              ),
            );
      }
    });
  }
}
