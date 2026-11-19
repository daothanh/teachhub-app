import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../data/class_models.dart';
import '../data/classes_repository.dart';

class StudentPickerState extends Equatable {
  const StudentPickerState({
    this.query = '',
    this.searching = false,
    this.results = const [],
    this.enrollingId,
    this.error,
    this.done,
  });

  final String query;
  final bool searching;
  final List<StudentSummary> results;

  /// Hồ sơ đang gửi yêu cầu ghi danh.
  final String? enrollingId;
  final ApiException? error;

  /// Ghi danh xong (mới hoặc đã có từ trước): màn đóng và trả kết quả.
  final ({StudentSummary student, EnrollResult result})? done;

  /// API chỉ nhận `q` từ 2 ký tự trở lên.
  bool get queryTooShort => query.trim().length < minQuery;
  static const minQuery = 2;

  StudentPickerState copyWith({
    String? query,
    bool? searching,
    List<StudentSummary>? results,
    String? enrollingId,
    bool clearEnrolling = false,
    ApiException? error,
    ({StudentSummary student, EnrollResult result})? done,
  }) => StudentPickerState(
    query: query ?? this.query,
    searching: searching ?? this.searching,
    results: results ?? this.results,
    enrollingId: clearEnrolling ? null : (enrollingId ?? this.enrollingId),
    error: error,
    done: done ?? this.done,
  );

  @override
  List<Object?> get props => [
    query,
    searching,
    results,
    enrollingId,
    error,
    done,
  ];
}

/// Chọn hồ sơ học viên có sẵn để ghi danh vào lớp (S2-FL-11). Không tạo hồ sơ.
class StudentPickerCubit extends Cubit<StudentPickerState> {
  StudentPickerCubit(this._repo, this.classId)
    : super(const StudentPickerState());
  final ClassesRepository _repo;
  final String classId;

  Future<void> search(String raw) async {
    final q = raw.trim();
    if (q.length < StudentPickerState.minQuery) {
      emit(StudentPickerState(query: raw));
      return;
    }
    emit(StudentPickerState(query: raw, searching: true));
    try {
      final p = await _repo.searchStudents(q);
      // Bỏ kết quả cũ nếu người dùng đã gõ tiếp.
      if (state.query != raw) return;
      emit(StudentPickerState(query: raw, results: p.items));
    } on ApiException catch (e) {
      if (state.query != raw) return;
      emit(StudentPickerState(query: raw, error: e));
    }
  }

  Future<void> enroll(StudentSummary s) async {
    if (state.enrollingId != null) return;
    emit(state.copyWith(enrollingId: s.id));
    try {
      final r = await _repo.enroll(classId, s.id);
      emit(state.copyWith(clearEnrolling: true, done: (student: s, result: r)));
    } on ApiException catch (e) {
      emit(state.copyWith(clearEnrolling: true, error: e));
    }
  }
}
