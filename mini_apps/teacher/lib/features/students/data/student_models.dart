import 'package:equatable/equatable.dart';

/// Phụ huynh nhập ở form (schema `students_create.guardians[]`).
class GuardianDraft extends Equatable {
  const GuardianDraft({required this.fullName, this.phone});

  final String fullName;
  final String? phone;

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    if (phone != null) 'phone': phone,
  };

  @override
  List<Object?> get props => [fullName, phone];
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

/// Học viên server trả về (schema `Student`, phần app dùng).
class Student extends Equatable {
  const Student({required this.id, required this.fullName});

  factory Student.fromJson(Map<String, dynamic> json) =>
      Student(id: json['id'] as String, fullName: json['fullName'] as String);

  final String id;
  final String fullName;

  @override
  List<Object?> get props => [id, fullName];
}
