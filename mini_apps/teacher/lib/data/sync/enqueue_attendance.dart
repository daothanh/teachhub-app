import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../local_db/teacher_database.dart';
import 'uuid.dart';

/// Một dòng điểm danh cần ghi.
typedef AttendanceWrite = ({String studentId, String status, String? note});

/// Lưu một điểm danh ngoại tuyến (spec §6.4): xem [enqueueAttendanceBatch].
/// Trả `clientMutationId`.
Future<String> enqueueAttendance(
  TeacherDatabase db, {
  required String sessionId,
  required String studentId,
  required String status,
  String? note,
  required DateTime clientUpdatedAt,
  String? clientMutationId,
}) async => (await enqueueAttendanceBatch(
  db,
  sessionId: sessionId,
  writes: [(studentId: studentId, status: status, note: note)],
  clientUpdatedAt: clientUpdatedAt,
  clientMutationIds: clientMutationId == null ? null : [clientMutationId],
)).single;

/// Lưu nhiều điểm danh của một buổi: cập nhật bản cục bộ và thêm vào outbox
/// trong cùng một giao dịch, bằng `batch` (mỗi lệnh riêng là một lượt qua
/// isolate của drift, 20 lệnh đã vượt 100 ms trên máy thật, ADR-0001).
/// [clientUpdatedAt] lấy từ `SyncEngine.clock.now()` để LWW so sánh trên đồng
/// hồ đã hiệu chỉnh. Trả `clientMutationId` theo thứ tự [writes].
///
/// `payload` của outbox là `{"status","note"}`; buổi và học viên nằm ở cột riêng.
Future<List<String>> enqueueAttendanceBatch(
  TeacherDatabase db, {
  required String sessionId,
  required List<AttendanceWrite> writes,
  required DateTime clientUpdatedAt,
  List<String>? clientMutationIds,
}) {
  final ids = clientMutationIds ?? [for (final _ in writes) newUuid()];
  return db.transaction(() async {
    // Drift lưu DateTime theo giây và server coi bằng nhau là stale, nên mỗi lần
    // sửa của một học viên phải mới hơn bản đã biết (cache hoặc outbox) ≥ 1 giây.
    final latest = <String, int>{};
    void note(String? student, DateTime? at) {
      if (student == null || at == null) return;
      final secs = at.millisecondsSinceEpoch ~/ 1000;
      latest[student] = max(latest[student] ?? secs, secs);
    }

    for (final r in await (db.select(
      db.cachedAttendances,
    )..where((r) => r.sessionId.equals(sessionId))).get()) {
      note(r.studentId, r.clientUpdatedAt);
    }
    for (final m in await (db.select(
      db.outboxMutations,
    )..where((r) => r.sessionId.equals(sessionId))).get()) {
      note(m.studentId, m.clientUpdatedAt);
    }
    final base = clientUpdatedAt.millisecondsSinceEpoch ~/ 1000;
    final at = <DateTime>[
      for (final w in writes)
        DateTime.fromMillisecondsSinceEpoch(
          max(base, (latest[w.studentId] ?? base - 1) + 1) * 1000,
          isUtc: true,
        ),
    ];
    await db.batch((b) {
      for (var i = 0; i < writes.length; i++) {
        final w = writes[i];
        b.update(
          db.cachedAttendances,
          CachedAttendancesCompanion(
            status: Value(w.status),
            note: Value(w.note),
            clientUpdatedAt: Value(at[i]),
          ),
          where: (r) =>
              r.sessionId.equals(sessionId) & r.studentId.equals(w.studentId),
        );
        b.insert(
          db.outboxMutations,
          OutboxMutationsCompanion.insert(
            clientMutationId: ids[i],
            entity: 'attendance',
            payload: jsonEncode({'status': w.status, 'note': w.note}),
            clientUpdatedAt: at[i],
            sessionId: Value(sessionId),
            studentId: Value(w.studentId),
          ),
        );
      }
    });
    return ids;
  });
}
