import 'package:equatable/equatable.dart';

/// 4 trạng thái của `AttendanceStatus` trong hợp đồng. Thứ tự là thứ tự vòng
/// khi chạm một học viên.
enum AttendanceStatus {
  present,
  late,
  excused,
  unexcused;

  /// Giá trị lạ (server mới hơn app) coi như chưa điểm danh.
  static AttendanceStatus? fromWire(String? wire) =>
      values.where((s) => s.name == wire).firstOrNull;

  AttendanceStatus get next => values[(index + 1) % values.length];

  /// Vắng: báo phụ huynh.
  bool get absent => this == excused || this == unexcused;
}

/// Ghi chú tối đa theo hợp đồng (`note.maxLength`).
const attendanceNoteMax = 500;

/// Một buổi trong danh sách "Hôm nay".
class TodaySession extends Equatable {
  const TodaySession({
    required this.id,
    required this.className,
    required this.startTime,
    required this.cancelled,
    required this.attended,
    this.isMakeup = false,
    this.cancelReason,
  });

  final String id;
  final String className;

  /// Giờ tường `HH:mm` theo múi giờ tenant.
  final String startTime;
  final bool cancelled;

  /// Buổi dạy bù (US-2.2).
  final bool isMakeup;

  /// Lý do hủy; chỉ có khi [cancelled] và giáo viên có nhập.
  final String? cancelReason;

  /// Đã điểm danh: server đã đánh dấu "đã dạy" hoặc cache có dòng đã ghi.
  final bool attended;

  @override
  List<Object?> get props => [
    id, className, startTime, cancelled, attended, isMakeup, cancelReason, //
  ];
}

class SheetStudent extends Equatable {
  const SheetStudent({
    required this.studentId,
    required this.fullName,
    required this.status,
    required this.note,
    this.rejectedCode,
  });

  final String studentId;
  final String fullName;

  /// null = chưa điểm danh (màn hiểu là "Có mặt").
  final AttendanceStatus? status;
  final String? note;

  /// Mã lỗi nếu server từ chối bản ghi của em này (vd `ATTENDANCE_EDIT_WINDOW_CLOSED`).
  final String? rejectedCode;

  @override
  List<Object?> get props => [studentId, fullName, status, note, rejectedCode];
}

/// Dữ liệu của T04 đọc từ cache.
class SessionSheet extends Equatable {
  const SessionSheet({
    required this.sessionId,
    required this.className,
    required this.sessionDate,
    required this.startTime,
    required this.cancelled,
    required this.canEdit,
    required this.editableUntil,
    required this.students,
    this.batchErrorCode,
  });

  final String sessionId;
  final String className;
  final String sessionDate;
  final String startTime;
  final bool cancelled;

  /// Server cho sửa lúc tải gần nhất; `null` = chưa tải.
  final bool? canEdit;

  /// Hạn sửa (cuối ngày thứ 7 theo tenant), theo hợp đồng.
  final DateTime? editableUntil;
  final List<SheetStudent> students;

  /// Cả lô của buổi bị server từ chối (buổi không có / đã hủy).
  final String? batchErrorCode;

  bool get hasFailure =>
      batchErrorCode != null || students.any((s) => s.rejectedCode != null);

  @override
  List<Object?> get props => [
    sessionId,
    className,
    sessionDate,
    startTime,
    cancelled,
    canEdit,
    editableUntil,
    students,
    batchErrorCode,
  ];
}

class HistorySnapshot extends Equatable {
  const HistorySnapshot({required this.status, required this.note});
  final AttendanceStatus? status;
  final String? note;

  @override
  List<Object?> get props => [status, note];
}

/// Một dòng nhật ký sửa. Chỉ tên hiển thị của người sửa, không id hay email.
class HistoryItem extends Equatable {
  const HistoryItem({
    required this.id,
    required this.studentName,
    required this.changedByName,
    required this.changedAt,
    required this.before,
    required this.after,
  });

  final String id;
  final String studentName;
  final String? changedByName;
  final DateTime changedAt;

  /// null = lần điểm danh đầu.
  final HistorySnapshot? before;
  final HistorySnapshot? after;

  @override
  List<Object?> get props => [
    id,
    studentName,
    changedByName,
    changedAt,
    before,
    after,
  ];
}

class HistoryChunk {
  const HistoryChunk(this.items, this.nextCursor);
  final List<HistoryItem> items;
  final String? nextCursor;
}

/// Một học viên khi bấm Lưu.
typedef AttendanceEntry = ({
  String studentId,
  AttendanceStatus status,
  String? note,
});

/// Sự kiện analytics. shortcut: app chưa có analytics dùng chung cho mini-app
/// (`tasco_observability` chỉ ở shell); nối khi shell có cổng analytics.
abstract class AttendanceAnalytics {
  /// Không kèm tên học viên hay ghi chú: chỉ số lượng.
  void attendanceSaved({
    required int students,
    required int absent,
    required bool edit,
  });
}

class NoopAttendanceAnalytics implements AttendanceAnalytics {
  const NoopAttendanceAnalytics();
  @override
  void attendanceSaved({
    required int students,
    required int absent,
    required bool edit,
  }) {}
}
