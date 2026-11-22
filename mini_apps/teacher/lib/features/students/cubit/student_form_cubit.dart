import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:teachhub_shared/teachhub_shared.dart';

import '../data/student_models.dart';
import '../data/student_repository.dart';

enum StudentFormStatus { idle, submitting, duplicate, success, failure }

class StudentFormState extends Equatable {
  const StudentFormState({
    this.status = StudentFormStatus.idle,
    this.candidates = const [],
    this.savedId,
    this.error,
  });

  final StudentFormStatus status;

  /// Có giá trị khi [status] là `duplicate` (tối đa 5).
  final List<StudentCandidate> candidates;

  /// Học viên vừa tạo, hoặc hồ sơ có sẵn người dùng chọn.
  final String? savedId;
  final ApiException? error;

  @override
  List<Object?> get props => [status, candidates, savedId, error];
}

class StudentFormCubit extends Cubit<StudentFormState> {
  /// [studentId] có giá trị = sửa hồ sơ có sẵn (`PATCH`), không thì thêm mới.
  StudentFormCubit(this._repo, {this.studentId, DraftKeys? keys})
    : _keys = keys ?? DraftKeys(),
      super(const StudentFormState());

  final StudentRepository _repo;
  final String? studentId;
  final DraftKeys _keys;
  StudentDraft? _draft;

  Future<void> submit(StudentDraft draft, {bool confirmNew = false}) async {
    if (state.status == StudentFormStatus.submitting) return;
    // Cùng nội dung thì giữ khóa để thử lại không tạo trùng; đổi nội dung hoặc
    // xác nhận em mới thì khóa mới.
    final key = _keys.of(
      'student',
      '$studentId|$confirmNew|${draft.toJson(confirmNew: confirmNew)}',
    );
    _draft = draft;
    emit(const StudentFormState(status: StudentFormStatus.submitting));
    try {
      final id = studentId;
      final student = id == null
          ? await _repo.create(
              draft,
              idempotencyKey: key,
              confirmNew: confirmNew,
            )
          : await _repo.update(id, draft, idempotencyKey: key);
      _keys.done('student');
      if (isClosed) return;
      emit(
        StudentFormState(
          status: StudentFormStatus.success,
          savedId: student.id,
        ),
      );
    } on StudentDuplicateException catch (e) {
      if (isClosed) return;
      emit(
        StudentFormState(
          status: StudentFormStatus.duplicate,
          candidates: e.candidates,
        ),
      );
    } on ApiException catch (e) {
      // Lỗi chắc chắn không ghi (4xx): lần lưu sau dùng khóa mới.
      if (!e.retryable) _keys.done('student');
      if (isClosed) return;
      emit(StudentFormState(status: StudentFormStatus.failure, error: e));
    }
  }

  /// "Không phải em này": gửi lại cùng dữ liệu kèm `confirmNew`.
  Future<void> confirmNew() async {
    final draft = _draft;
    if (draft != null) await submit(draft, confirmNew: true);
  }

  /// "Đúng là em này": dùng hồ sơ có sẵn, không tạo mới.
  void pickExisting(StudentCandidate candidate) => emit(
    StudentFormState(status: StudentFormStatus.success, savedId: candidate.id),
  );

  /// Đóng hộp thoại, giữ nguyên form.
  void dismissDuplicate() => emit(const StudentFormState());
}
