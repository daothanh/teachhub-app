import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';

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
  StudentFormCubit(this._repo) : super(const StudentFormState());

  final StudentRepository _repo;
  StudentDraft? _draft;
  bool _confirmNew = false;
  String? _key;

  Future<void> submit(StudentDraft draft, {bool confirmNew = false}) async {
    if (state.status == StudentFormStatus.submitting) return;
    // Cùng nội dung thì giữ khóa để thử lại không tạo trùng; đổi nội dung hoặc
    // xác nhận em mới thì khóa mới.
    if (_key == null || draft != _draft || confirmNew != _confirmNew) {
      _key = uuidV4(Random.secure());
    }
    _draft = draft;
    _confirmNew = confirmNew;
    emit(const StudentFormState(status: StudentFormStatus.submitting));
    try {
      final student = await _repo.create(
        draft,
        idempotencyKey: _key!,
        confirmNew: confirmNew,
      );
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
