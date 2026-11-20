import 'package:equatable/equatable.dart';

enum AttendanceMark {
  present,
  late,
  excused,
  unexcused;

  static AttendanceMark? fromWire(Object? v) {
    for (final m in values) {
      if (m.name == v) return m;
    }
    return null;
  }
}

class FamilyClass extends Equatable {
  const FamilyClass({
    required this.id,
    required this.name,
    required this.teacherName,
  });

  factory FamilyClass.fromJson(Map<String, dynamic> j) => FamilyClass(
    id: j['id'] as String,
    name: j['name'] as String,
    teacherName: j['teacherName'] as String,
  );

  final String id;
  final String name;
  final String teacherName;

  @override
  List<Object?> get props => [id, name, teacherName];
}

/// Con của phụ huynh (`GET /family/students`).
class FamilyStudent extends Equatable {
  const FamilyStudent({
    required this.id,
    required this.fullName,
    required this.classes,
  });

  factory FamilyStudent.fromJson(Map<String, dynamic> j) => FamilyStudent(
    id: j['id'] as String,
    fullName: j['fullName'] as String,
    classes: [
      for (final c in j['classes'] as List)
        FamilyClass.fromJson(c as Map<String, dynamic>),
    ],
  );

  final String id;
  final String fullName;
  final List<FamilyClass> classes;

  @override
  List<Object?> get props => [id, fullName, classes];
}

class AttendanceSummary extends Equatable {
  const AttendanceSummary({
    required this.present,
    required this.late,
    required this.excused,
    required this.unexcused,
    required this.notRecorded,
    required this.upcoming,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> j) =>
      AttendanceSummary(
        present: j['present'] as int,
        late: j['late'] as int,
        excused: j['excused'] as int,
        unexcused: j['unexcused'] as int,
        notRecorded: j['notRecorded'] as int,
        // Hợp đồng cũ chưa có `upcoming`.
        upcoming: (j['upcoming'] as int?) ?? 0,
      );

  final int present;
  final int late;
  final int excused;
  final int unexcused;
  final int notRecorded;
  final int upcoming;

  @override
  List<Object?> get props => [
    present,
    late,
    excused,
    unexcused,
    notRecorded,
    upcoming,
  ];
}

class AttendanceSession extends Equatable {
  const AttendanceSession({
    required this.sessionId,
    required this.className,
    required this.startsAt,
    required this.cancelled,
    required this.isMakeup,
    required this.mark,
  });

  factory AttendanceSession.fromJson(Map<String, dynamic> j) =>
      AttendanceSession(
        sessionId: j['sessionId'] as String,
        className: j['className'] as String,
        startsAt: DateTime.parse(j['startsAt'] as String),
        cancelled: j['sessionStatus'] == 'cancelled',
        isMakeup: j['isMakeup'] as bool,
        mark: AttendanceMark.fromWire(j['attendanceStatus']),
      );

  final String sessionId;
  final String className;

  /// Giờ bắt đầu theo múi giờ trong phản hồi (không đổi sang giờ máy).
  final DateTime startsAt;
  final bool cancelled;
  final bool isMakeup;

  /// `null` = chưa điểm danh hoặc buổi đã hủy.
  final AttendanceMark? mark;

  @override
  List<Object?> get props => [
    sessionId,
    className,
    startsAt,
    cancelled,
    isMakeup,
    mark,
  ];
}

/// Chuyên cần một tuần của một con (`GET /family/students/{id}/attendance`).
class AttendanceWeek extends Equatable {
  const AttendanceWeek({
    required this.studentId,
    required this.weekStart,
    required this.weekEnd,
    required this.summary,
    required this.sessions,
  });

  factory AttendanceWeek.fromJson(Map<String, dynamic> j) => AttendanceWeek(
    studentId: j['studentId'] as String,
    weekStart: DateTime.parse(j['weekStart'] as String),
    weekEnd: DateTime.parse(j['weekEnd'] as String),
    summary: AttendanceSummary.fromJson(j['summary'] as Map<String, dynamic>),
    sessions: [
      for (final s in j['sessions'] as List)
        AttendanceSession.fromJson(s as Map<String, dynamic>),
    ],
  );

  final String studentId;
  final DateTime weekStart;
  final DateTime weekEnd;
  final AttendanceSummary summary;
  final List<AttendanceSession> sessions;

  @override
  List<Object?> get props => [studentId, weekStart, weekEnd, summary, sessions];
}
