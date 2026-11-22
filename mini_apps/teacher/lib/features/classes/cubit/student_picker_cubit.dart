import 'dart:async';

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
    bool clearError = false,
    ApiException? error,
    ({StudentSummary student, EnrollResult result})? done,
  }) => StudentPickerState(
    query: query ?? this.query,
    searching: searching ?? this.searching,
    results: results ?? this.results,
    enrollingId: clearEnrolling ? null : (enrollingId ?? this.enrollingId),
    error: clearError ? null : (error ?? this.error),
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
  StudentPickerCubit(this._repo, this.classId, {DraftKeys? keys})
    : _keys = keys ?? DraftKeys(),
      super(const StudentPickerState());
  final ClassesRepository _repo;
  final String classId;
  final DraftKeys _keys;

  Timer? _debounce;

  /// Thế hệ tìm kiếm: gõ tiếp thì kết quả của lần trước bị bỏ.
  int _gen = 0;

  static const debounceDuration = Duration(milliseconds: 300);

  /// Gõ liên tục chỉ gọi API sau khi dừng [debounceDuration]. Không đụng tới
  /// `enrollingId` của yêu cầu ghi danh đang bay.
  void search(String raw) {
    _debounce?.cancel();
    final gen = ++_gen;
    final q = raw.trim();
    if (q.length < StudentPickerState.minQuery) {
      emit(
        state.copyWith(
          query: raw,
          searching: false,
          results: const [],
          clearError: true,
        ),
      );
      return;
    }
    emit(state.copyWith(query: raw, searching: true, clearError: true));
    _debounce = Timer(debounceDuration, () => _run(q, gen));
  }

  Future<void> _run(String q, int gen) async {
    try {
      final p = await _repo.searchStudents(q);
      if (isClosed || gen != _gen) return;
      emit(state.copyWith(searching: false, results: p.items));
    } on ApiException catch (e) {
      if (isClosed || gen != _gen) return;
      emit(state.copyWith(searching: false, results: const [], error: e));
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  Future<void> enroll(StudentSummary s) async {
    if (state.enrollingId != null) return;
    emit(state.copyWith(enrollingId: s.id, clearError: true));
    final op = 'enroll:${s.id}';
    try {
      final r = await _repo.enroll(
        classId,
        s.id,
        idempotencyKey: _keys.of(op, '$classId|${s.id}'),
      );
      _keys.done(op);
      if (isClosed) return;
      emit(
        state.copyWith(
          clearEnrolling: true,
          clearError: true,
          done: (student: s, result: r),
        ),
      );
    } on ApiException catch (e) {
      if (!e.retryable) _keys.done(op);
      if (isClosed) return;
      emit(state.copyWith(clearEnrolling: true, error: e));
    }
  }
}
