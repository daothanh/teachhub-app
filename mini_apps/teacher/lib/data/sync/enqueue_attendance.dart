import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../local_db/teacher_database.dart';
import 'uuid.dart';

/// Lưu một điểm danh ngoại tuyến (spec §6.4): cập nhật bản cục bộ và thêm vào
/// outbox trong cùng một giao dịch. [clientUpdatedAt] lấy từ `SyncEngine.clock.now()`
/// để LWW so sánh trên đồng hồ đã hiệu chỉnh. Trả `clientMutationId`.
///
/// `payload` của outbox là `{"status","note"}`; buổi và học viên nằm ở cột riêng.
Future<String> enqueueAttendance(
  TeacherDatabase db, {
  required String sessionId,
  required String studentId,
  required String status,
  String? note,
  required DateTime clientUpdatedAt,
  String? clientMutationId,
}) {
  final id = clientMutationId ?? newUuid();
  return db.transaction(() async {
    // Drift lưu DateTime theo giây và server coi bằng nhau là stale, nên mỗi lần
    // sửa của một học viên phải mới hơn bản đã biết (cache hoặc outbox) ≥ 1 giây.
    final known = <int>[
      ?(await (db.select(db.cachedAttendances)..where(
                (r) =>
                    r.sessionId.equals(sessionId) &
                    r.studentId.equals(studentId),
              ))
              .getSingleOrNull())
          ?.clientUpdatedAt
          ?.millisecondsSinceEpoch,
      for (final m
          in await (db.select(db.outboxMutations)..where(
                (r) =>
                    r.sessionId.equals(sessionId) &
                    r.studentId.equals(studentId),
              ))
              .get())
        m.clientUpdatedAt.millisecondsSinceEpoch,
    ];
    var secs = clientUpdatedAt.millisecondsSinceEpoch ~/ 1000;
    final latest = known.isEmpty ? null : known.reduce(max) ~/ 1000;
    if (latest != null && secs <= latest) secs = latest + 1;
    clientUpdatedAt = DateTime.fromMillisecondsSinceEpoch(
      secs * 1000,
      isUtc: true,
    );
    await (db.update(db.cachedAttendances)..where(
          (r) => r.sessionId.equals(sessionId) & r.studentId.equals(studentId),
        ))
        .write(
          CachedAttendancesCompanion(
            status: Value(status),
            note: Value(note),
            clientUpdatedAt: Value(clientUpdatedAt),
          ),
        );
    await db
        .into(db.outboxMutations)
        .insert(
          OutboxMutationsCompanion.insert(
            clientMutationId: id,
            entity: 'attendance',
            payload: jsonEncode({'status': status, 'note': note}),
            clientUpdatedAt: clientUpdatedAt,
            sessionId: Value(sessionId),
            studentId: Value(studentId),
          ),
        );
    return id;
  });
}
