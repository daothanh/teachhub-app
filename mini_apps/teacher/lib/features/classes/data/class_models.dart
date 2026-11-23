import 'package:equatable/equatable.dart';

import '../../../data/cache/wall_time.dart';
import '../../fees/data/fee_models.dart';

/// Mô hình lớp học khớp `contracts/openapi.json` (schema Class, ScheduleRule,
/// Roster, Enrollment, Student, Session). Ngày là chuỗi `yyyy-MM-dd`, giờ là
/// `HH:mm` đúng như hợp đồng, không đổi qua `DateTime` để khỏi lệch múi giờ.

enum ClassMode {
  offline,
  online;

  static ClassMode fromWire(String v) =>
      values.firstWhere((m) => m.name == v, orElse: () => ClassMode.offline);
}

enum ClassStatus {
  active,
  archived;

  /// `status` lạ làm hỏng cả lớp (dễ hiện nhầm lớp lưu trữ là đang dạy):
  /// ném [FormatException], repository đổi thành lỗi chung.
  static ClassStatus fromWire(String v) => values.firstWhere(
    (m) => m.name == v,
    orElse: () => throw FormatException('status lạ: $v'),
  );
}

/// Quy tắc lặp. `weekday` theo ISO 8601: 1 = Thứ Hai … 7 = Chủ nhật.
class ScheduleRule extends Equatable {
  const ScheduleRule({
    required this.weekday,
    required this.startTime,
    required this.durationMin,
    this.id,
  });

  factory ScheduleRule.fromJson(Map<String, dynamic> json) => ScheduleRule(
    id: json['id'] as String,
    weekday: json['weekday'] as int,
    startTime: json['startTime'] as String,
    durationMin: json['durationMin'] as int,
  );

  final String? id;
  final int weekday;
  final String startTime;
  final int durationMin;

  Map<String, dynamic> toJson() => {
    'weekday': weekday,
    'startTime': startTime,
    'durationMin': durationMin,
  };

  /// So sánh theo nội dung, bỏ `id` (server sinh lại id khi thay bộ quy tắc).
  String get signature => '$weekday|$startTime|$durationMin';

  @override
  List<Object?> get props => [id, weekday, startTime, durationMin];
}

class TeachClass extends Equatable {
  const TeachClass({
    required this.id,
    required this.name,
    required this.subject,
    required this.grade,
    required this.mode,
    required this.location,
    required this.capacity,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.enrolledCount,
    required this.scheduleRules,
    required this.createdAt,
    this.feeType,
    this.feeAmount,
    this.feeRules,
  });

  factory TeachClass.fromJson(Map<String, dynamic> json) => TeachClass(
    id: json['id'] as String,
    name: json['name'] as String,
    subject: json['subject'] as String,
    grade: json['grade'] as int,
    mode: ClassMode.fromWire(json['mode'] as String),
    location: json['location'] as String?,
    capacity: json['capacity'] as int?,
    startDate: json['startDate'] as String,
    endDate: json['endDate'] as String?,
    status: ClassStatus.fromWire(json['status'] as String),
    enrolledCount: json['enrolledCount'] as int,
    scheduleRules: [
      for (final r in json['scheduleRules'] as List)
        ScheduleRule.fromJson(r as Map<String, dynamic>),
    ],
    createdAt: json['createdAt'] as String,
    feeType: FeeType.fromWire(json['feeType'] as String?),
    feeAmount: json['feeAmount'] as int?,
    feeRules: switch (json['feeRules']) {
      final Map<String, dynamic> m => FeeRules.fromJson(m),
      _ => null,
    },
  );

  final String id;
  final String name;
  final String subject;
  final int grade;
  final ClassMode mode;
  final String? location;
  final int? capacity;
  final String startDate;
  final String? endDate;
  final ClassStatus status;
  final int enrolledCount;
  final List<ScheduleRule> scheduleRules;
  final String createdAt;

  /// Học phí của lớp; `null` = lớp chưa cấu hình (không sinh hóa đơn).
  final FeeType? feeType;
  final int? feeAmount;
  final FeeRules? feeRules;

  bool get archived => status == ClassStatus.archived;

  @override
  List<Object?> get props => [
    id, name, subject, grade, mode, location, capacity, startDate, endDate,
    status, enrolledCount, scheduleRules, createdAt, feeType, feeAmount, //
    feeRules,
  ];
}

/// Cảnh báo không chặn khi tạo lớp (`ClassCreated.warnings`).
class ClassWarning extends Equatable {
  const ClassWarning({required this.code, required this.message});

  factory ClassWarning.fromJson(Map<String, dynamic> json) => ClassWarning(
    code: json['code'] as String,
    message: json['message'] as String,
  );

  final String code;
  final String message;

  @override
  List<Object?> get props => [code, message];
}

class ClassCreated {
  const ClassCreated(this.value, this.warnings);

  factory ClassCreated.fromJson(Map<String, dynamic> json) =>
      ClassCreated(TeachClass.fromJson(json), [
        for (final w in json['warnings'] as List)
          ClassWarning.fromJson(w as Map<String, dynamic>),
      ]);

  final TeachClass value;
  final List<ClassWarning> warnings;
}

/// Dữ liệu form lớp, cũng là body của `POST`/`PATCH /classes`.
class ClassInput extends Equatable {
  const ClassInput({
    this.name = '',
    this.subject = '',
    this.grade,
    this.mode = ClassMode.offline,
    this.location,
    this.capacity,
    this.startDate,
    this.endDate,
    this.feeType,
    this.feeAmount,
    this.feeRules,
  });

  factory ClassInput.from(TeachClass c) => ClassInput(
    name: c.name,
    subject: c.subject,
    grade: c.grade,
    mode: c.mode,
    location: c.location,
    capacity: c.capacity,
    startDate: c.startDate,
    endDate: c.endDate,
    feeType: c.feeType,
    feeAmount: c.feeAmount,
    feeRules: c.feeRules,
  );

  final String name;
  final String subject;
  final int? grade;
  final ClassMode mode;
  final String? location;
  final int? capacity;
  final String? startDate;
  final String? endDate;

  /// Học phí: `feeType` null = không thu; `feeAmount` null khi chưa nhập.
  final FeeType? feeType;
  final int? feeAmount;
  final FeeRules? feeRules;

  /// Học phí giống lớp đã lưu (để khỏi gửi lại khi không đổi).
  bool sameFeeAs(TeachClass c) =>
      feeType == c.feeType &&
      feeAmount == c.feeAmount &&
      feeRules == c.feeRules;

  /// Body `PATCH /classes/{id}`. Học phí chỉ gửi khi [withFee] (xóa học phí =
  /// `feeType` và `feeAmount` cùng `null`); `POST` chưa nhận học phí nên dùng
  /// [toJson].
  Map<String, dynamic> toPatchJson({bool withFee = false}) => {
    ...toJson(),
    if (withFee) ...{
      'feeType': feeType?.wire,
      'feeAmount': feeType == null ? null : feeAmount,
      if (feeType != null) 'feeRules': (feeRules ?? const FeeRules()).toJson(),
    },
  };

  /// Lớp trực tuyến không gửi địa điểm.
  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'subject': subject.trim(),
    'grade': grade,
    'mode': mode.name,
    // Địa điểm không bắt buộc (kể cả tại chỗ): ô trống gửi null, không gửi "".
    'location': mode == ClassMode.offline && (location ?? '').trim().isNotEmpty
        ? location!.trim()
        : null,
    'capacity': capacity,
    'startDate': startDate,
    'endDate': endDate,
  };

  @override
  List<Object?> get props => [
    name, subject, grade, mode, location, capacity, startDate, endDate, //
    feeType, feeAmount, feeRules,
  ];
}

/// Lỗi kiểm tra ở máy, theo cùng khóa trường với `errors` của server.
enum ClassFieldError {
  required,
  gradeRange,
  capacityRange,
  endBeforeStart,
  rulesDuplicate,
  rulesOverflow,
  rulesDuration,
  rulesTooMany,
  feeAmountRequired,
  feeAmountRange,
  feeInstallments,
  feeCourseNeedsSchedule,
}

/// Kiểm tra trước khi gọi API (US-1.1 AC1–AC2, US-2.1). Server vẫn là nguồn
/// cuối: lỗi 422 của server hiển thị cùng chỗ.
Map<String, ClassFieldError> validateClass(
  ClassInput i,
  List<ScheduleRule> rules,
) {
  final e = <String, ClassFieldError>{};
  if (i.name.trim().isEmpty) e['name'] = ClassFieldError.required;
  if (i.subject.trim().isEmpty) e['subject'] = ClassFieldError.required;
  final g = i.grade;
  if (g == null) {
    e['grade'] = ClassFieldError.required;
  } else if (g < 1 || g > 12) {
    e['grade'] = ClassFieldError.gradeRange;
  }
  final c = i.capacity;
  if (c != null && (c < 1 || c > 500)) {
    e['capacity'] = ClassFieldError.capacityRange;
  }
  if (i.startDate == null) e['startDate'] = ClassFieldError.required;
  // `yyyy-MM-dd` so sánh theo chuỗi đúng thứ tự thời gian.
  if (i.startDate != null &&
      i.endDate != null &&
      i.endDate!.compareTo(i.startDate!) < 0) {
    e['endDate'] = ClassFieldError.endBeforeStart;
  }
  if (rules.length > 14) {
    e['rules'] = ClassFieldError.rulesTooMany;
  } else if (rules.any((r) => r.durationMin < 15 || r.durationMin > 480)) {
    e['rules'] = ClassFieldError.rulesDuration;
  } else if (_hasOverlap(rules)) {
    e['rules'] = ClassFieldError.rulesDuplicate;
  } else if (rules.any((r) => minutesOf(r.startTime) + r.durationMin > 1440)) {
    e['rules'] = ClassFieldError.rulesOverflow;
  }
  final t = i.feeType;
  if (t != null) {
    final a = i.feeAmount;
    if (a == null) {
      e['feeAmount'] = ClassFieldError.feeAmountRequired;
    } else if (a < 1 || a > feeAmountMax) {
      e['feeAmount'] = ClassFieldError.feeAmountRange;
    }
    // Trọn khóa cần ngày kết thúc và lịch học (server từ chối nếu thiếu).
    if (t == FeeType.course && (i.endDate == null || rules.isEmpty)) {
      e['feeType'] = ClassFieldError.feeCourseNeedsSchedule;
    }
    final n = i.feeRules?.installments ?? 1;
    if (n < 1 || n > feeInstallmentsMax || (t != FeeType.course && n != 1)) {
      e['feeRules'] = ClassFieldError.feeInstallments;
    }
  }
  return e;
}

/// Hai buổi cùng thứ chồng giờ (US-0.2 AC6); cùng thứ mà không chồng thì hợp lệ.
bool _hasOverlap(List<ScheduleRule> rules) {
  for (var i = 0; i < rules.length; i++) {
    for (var j = i + 1; j < rules.length; j++) {
      final a = rules[i], b = rules[j];
      if (a.weekday != b.weekday) continue;
      final aStart = minutesOf(a.startTime), bStart = minutesOf(b.startTime);
      if (aStart < bStart + b.durationMin && bStart < aStart + a.durationMin) {
        return true;
      }
    }
  }
  return false;
}

int minutesOf(String hhmm) {
  final p = hhmm.split(':');
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

/// Trạng thái lời mời của một phụ huynh (schema `GuardianInviteStatus`).
/// `expired` hiện nút "Gửi lại link"; `notInvited` gồm cả lời mời đã thu hồi.
enum GuardianInviteStatus {
  notInvited('not_invited'),
  invited('invited'),
  activated('activated'),
  expired('expired');

  const GuardianInviteStatus(this.wire);
  final String wire;

  /// Giá trị lạ (server mới hơn app) coi như chưa mời: vẫn cho tạo link mới.
  static GuardianInviteStatus fromWire(String? v) => values.firstWhere(
    (s) => s.wire == v,
    orElse: () => GuardianInviteStatus.notInvited,
  );
}

/// Lời mời mới nhất của phụ huynh (kể cả hết hạn); không có token hay mã.
class LatestInvite extends Equatable {
  const LatestInvite({required this.id, required this.expiresAt});

  factory LatestInvite.fromJson(Map<String, dynamic> json) => LatestInvite(
    id: json['id'] as String,
    expiresAt: json['expiresAt'] as String,
  );

  final String id;
  final String expiresAt;

  @override
  List<Object?> get props => [id, expiresAt];
}

/// Phụ huynh trong danh sách lớp (schema `RosterGuardian`).
class RosterGuardian extends Equatable {
  const RosterGuardian({
    required this.id,
    required this.fullName,
    required this.relation,
    required this.inviteStatus,
    this.latestInvite,
  });

  factory RosterGuardian.fromJson(Map<String, dynamic> json) => RosterGuardian(
    id: json['id'] as String,
    fullName: json['fullName'] as String,
    relation: json['relation'] as String,
    inviteStatus: GuardianInviteStatus.fromWire(
      json['inviteStatus'] as String?,
    ),
    latestInvite: switch (json['latestInvite']) {
      final Map<String, dynamic> m => LatestInvite.fromJson(m),
      _ => null,
    },
  );

  final String id;
  final String fullName;

  /// `father` | `mother` | `guardian`.
  final String relation;
  final GuardianInviteStatus inviteStatus;
  final LatestInvite? latestInvite;

  /// Chưa kích hoạt: còn việc mời (chưa mời, đang chờ hoặc hết hạn).
  bool get needsInvite => inviteStatus != GuardianInviteStatus.activated;

  @override
  List<Object?> get props => [
    id,
    fullName,
    relation,
    inviteStatus,
    latestInvite,
  ];
}

class RosterEntry extends Equatable {
  const RosterEntry({
    required this.enrollmentId,
    required this.studentId,
    required this.fullName,
    required this.studentStatus,
    required this.joinedOn,
    this.inviteStatus = GuardianInviteStatus.notInvited,
    this.guardians = const [],
    this.feeOverride,
  });

  factory RosterEntry.fromJson(Map<String, dynamic> json) => RosterEntry(
    enrollmentId: json['enrollmentId'] as String,
    studentId: json['studentId'] as String,
    fullName: json['fullName'] as String,
    studentStatus: json['studentStatus'] as String,
    joinedOn: json['joinedOn'] as String,
    inviteStatus: GuardianInviteStatus.fromWire(
      json['inviteStatus'] as String?,
    ),
    guardians: [
      for (final g in json['guardians'] as List)
        RosterGuardian.fromJson(g as Map<String, dynamic>),
    ],
    feeOverride: switch (json['feeOverride']) {
      final Map<String, dynamic> m => FeeOverride.lenient(m),
      _ => null,
    },
  );

  final String enrollmentId;
  final String studentId;
  final String fullName;

  /// `active` | `paused`.
  final String studentStatus;
  final String joinedOn;

  /// Gộp theo các phụ huynh của học viên (server tính).
  final GuardianInviteStatus inviteStatus;
  final List<RosterGuardian> guardians;

  /// Khác null: hiện nhãn "Giá riêng" (US-1.3 AC2).
  final FeeOverride? feeOverride;

  bool get hasFeeOverride => feeOverride != null;

  @override
  List<Object?> get props => [
    enrollmentId, studentId, fullName, studentStatus, joinedOn, //
    inviteStatus, guardians, feeOverride,
  ];
}

class Enrollment extends Equatable {
  const Enrollment({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.joinedOn,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) => Enrollment(
    id: json['id'] as String,
    classId: json['classId'] as String,
    studentId: json['studentId'] as String,
    joinedOn: json['joinedOn'] as String,
  );

  final String id;
  final String classId;
  final String studentId;
  final String joinedOn;

  @override
  List<Object?> get props => [id, classId, studentId, joinedOn];
}

/// 201 = ghi danh mới, 200 = học viên đã ở lớp này (không tạo bản trùng).
class EnrollResult {
  const EnrollResult(this.enrollment, {required this.alreadyEnrolled});
  final Enrollment enrollment;
  final bool alreadyEnrolled;
}

/// Hồ sơ học viên khi tìm để thêm vào lớp (chỉ đọc, không tạo hồ sơ ở đây).
class StudentSummary extends Equatable {
  const StudentSummary({
    required this.id,
    required this.fullName,
    required this.school,
    required this.schoolClass,
    required this.status,
  });

  factory StudentSummary.fromJson(Map<String, dynamic> json) => StudentSummary(
    id: json['id'] as String,
    fullName: json['fullName'] as String,
    school: json['school'] as String?,
    schoolClass: json['schoolClass'] as String?,
    status: json['status'] as String,
  );

  final String id;
  final String fullName;
  final String? school;
  final String? schoolClass;

  /// `active` | `paused` | `left`.
  final String status;

  @override
  List<Object?> get props => [id, fullName, school, schoolClass, status];
}

enum SessionStatus {
  planned,
  taught,
  cancelled;

  static SessionStatus fromWire(String v) => values.firstWhere(
    (s) => s.name == v,
    orElse: () => SessionStatus.planned,
  );
}

class ClassSession extends Equatable {
  const ClassSession({
    required this.id,
    required this.classId,
    required this.className,
    required this.sessionDate,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.isMakeup,
    this.cancelReason,
    this.makeupOf,
  });

  factory ClassSession.fromJson(Map<String, dynamic> json) => ClassSession(
    id: json['id'] as String,
    classId: json['classId'] as String,
    className: json['className'] as String,
    sessionDate: json['sessionDate'] as String,
    startsAt: json['startsAt'] as String,
    endsAt: json['endsAt'] as String,
    status: SessionStatus.fromWire(json['status'] as String),
    isMakeup: json['isMakeup'] as bool,
    cancelReason: json['cancelReason'] as String?,
    makeupOf: json['makeupOf'] as String?,
  );

  final String id;
  final String classId;
  final String className;

  /// Ngày theo múi giờ của tenant (`yyyy-MM-dd`).
  final String sessionDate;

  /// ISO 8601 kèm offset của tenant, giữ nguyên chuỗi.
  final String startsAt;
  final String endsAt;

  /// Giờ tường `HH:mm` đúng như server ghi (theo offset trong chuỗi), không đổi
  /// sang múi giờ máy để ngày và giờ luôn khớp nhau.
  String get startTime => wallTimeFromIso(startsAt);
  String get endTime => wallTimeFromIso(endsAt);

  final SessionStatus status;
  final bool isMakeup;

  /// Lý do hủy; null nếu buổi chưa hủy hoặc không nhập lý do.
  final String? cancelReason;

  /// Id buổi gốc nếu đây là buổi bù.
  final String? makeupOf;

  @override
  List<Object?> get props => [
    id, classId, className, sessionDate, startsAt, endsAt, status, isMakeup, //
    cancelReason, makeupOf,
  ];
}

class ScheduleRulesResult {
  const ScheduleRulesResult({
    required this.rules,
    required this.sessionsGenerated,
    required this.sessionsRemoved,
  });

  factory ScheduleRulesResult.fromJson(Map<String, dynamic> json) =>
      ScheduleRulesResult(
        rules: [
          for (final r in json['rules'] as List)
            ScheduleRule.fromJson(r as Map<String, dynamic>),
        ],
        sessionsGenerated: json['sessionsGenerated'] as int,
        sessionsRemoved: json['sessionsRemoved'] as int,
      );

  final List<ScheduleRule> rules;
  final int sessionsGenerated;
  final int sessionsRemoved;
}

/// `yyyy-MM-dd` từ [DateTime] (theo giờ máy).
String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// `dd/MM/yyyy` từ `yyyy-MM-dd`.
String displayDate(String iso) {
  final p = iso.split('-');
  return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : iso;
}
