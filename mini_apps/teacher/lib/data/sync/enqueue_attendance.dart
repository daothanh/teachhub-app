import 'dart:convert';

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
