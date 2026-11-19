import 'package:equatable/equatable.dart';

/// Quan hệ của phụ huynh với học viên (schema `students_create.guardians[].relation`).
enum GuardianRelation {
  father,
  mother,
  guardian;

  static GuardianRelation fromWire(String? v) => values.firstWhere(
    (r) => r.name == v,
    orElse: () => GuardianRelation.guardian,
  );
}

/// Phụ huynh nhập ở form (schema `guardians[]` của `POST`/`PATCH /students`).
/// Có [id] = cập nhật phụ huynh đó; không có = tạo mới. `PATCH` thay cả danh
/// sách nên khi sửa, phụ huynh có sẵn phải gửi lại đủ (kể cả [email] app không
/// cho sửa) kẻo bị xóa mất.
class GuardianDraft extends Equatable {
  const GuardianDraft({
    required this.fullName,
    this.phone,
    this.relation = GuardianRelation.guardian,
    this.id,
    this.email,
  });

  factory GuardianDraft.fromJson(Map<String, dynamic> json) => GuardianDraft(
    id: json['id'] as String?,
    fullName: json['fullName'] as String,
    relation: GuardianRelation.fromWire(json['relation'] as String?),
    phone: json['phone'] as String?,
    email: json['email'] as String?,
  );

  final String? id;
  final String fullName;
  final GuardianRelation relation;
  final String? phone;
  final String? email;

  /// Phụ huynh có sẵn gửi `phone`/`email` rõ ràng (kể cả null) để xóa được số.
  Map<String, dynamic> toJson() => {
    'id': ?id,
    'fullName': fullName,
    'relation': relation.name,
    if (id != null || phone != null) 'phone': phone,
    if (id != null || email != null) 'email': email,
  };

  @override
  List<Object?> get props => [id, fullName, relation, phone, email];
}

/// Thân request `POST /students`; chỉ [fullName] bắt buộc.
class StudentDraft extends Equatable {
  const StudentDraft({
    required this.fullName,
    this.dob,
    this.school,
    this.note,
    this.guardians = const [],
  });

  final String fullName;
  final DateTime? dob;
  final String? school;
  final String? note;
  final List<GuardianDraft> guardians;

  Map<String, dynamic> toJson({bool confirmNew = false}) => {
    'fullName': fullName,
    if (dob != null) 'dob': _date(dob!),
    if (school != null) 'school': school,
    if (note != null) 'note': note,
    if (guardians.isNotEmpty)
      'guardians': [for (final g in guardians) g.toJson()],
    if (confirmNew) 'confirmNew': true,
  };

  /// Thân `PATCH /students/{id}`: gửi đủ mọi trường (ô trống = xóa) và cả danh
  /// sách phụ huynh, vì server thay toàn bộ danh sách.
  Map<String, dynamic> toPatchJson() => {
    'fullName': fullName,
    'dob': dob == null ? null : _date(dob!),
    'school': school,
    'note': note,
    'guardians': [for (final g in guardians) g.toJson()],
  };

  @override
  List<Object?> get props => [fullName, dob, school, note, guardians];
}

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Hồ sơ trùng khả nghi (schema `StudentCandidate`).
class StudentCandidate extends Equatable {
  const StudentCandidate({
    required this.id,
    required this.fullName,
    this.dob,
    this.school,
  });

  factory StudentCandidate.fromJson(Map<String, dynamic> json) =>
      StudentCandidate(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        dob: json['dob'] as String?,
        school: json['school'] as String?,
      );

  final String id;
  final String fullName;
  final String? dob;
  final String? school;

  @override
  List<Object?> get props => [id, fullName, dob, school];
}

/// Học viên server trả về (schema `Student`); form sửa đọc đủ các trường.
class Student extends Equatable {
  const Student({
    required this.id,
    required this.fullName,
    this.dob,
    this.school,
    this.note,
    this.guardians = const [],
  });

  factory Student.fromJson(Map<String, dynamic> json) => Student(
    id: json['id'] as String,
    fullName: json['fullName'] as String,
    dob: json['dob'] as String?,
    school: json['school'] as String?,
    note: json['note'] as String?,
    guardians: [
      for (final g in json['guardians'] as List? ?? const [])
        GuardianDraft.fromJson((g as Map).cast<String, dynamic>()),
    ],
  );

  final String id;
  final String fullName;

  /// `yyyy-MM-dd`.
  final String? dob;
  final String? school;
  final String? note;
  final List<GuardianDraft> guardians;

  @override
  List<Object?> get props => [id, fullName, dob, school, note, guardians];
}
