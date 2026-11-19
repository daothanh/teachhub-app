import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../data/class_models.dart';
import '../data/classes_repository.dart';

class ClassFormState extends Equatable {
  const ClassFormState({
    this.loading = false,
    this.saving = false,
    this.initial,
    this.saved,
    this.clientErrors = const {},
    this.serverErrors = const {},
    this.error,
    this.sessionsGenerated,
  });

  /// Đang tải lớp để sửa.
  final bool loading;
  final bool saving;

  /// Lớp đã có (sửa, hoặc lớp vừa tạo mà bước đặt lịch lỗi).
  final TeachClass? initial;

  /// Lưu xong: màn đóng và trả lớp này.
  final TeachClass? saved;
  final Map<String, ClassFieldError> clientErrors;

  /// 422 theo trường từ server: `{ "endDate": ["…"] }`.
  final Map<String, List<String>> serverErrors;

  /// Lỗi chung (402, 409, mạng…) hoặc 422 không gắn được vào trường.
  final ApiException? error;
  final int? sessionsGenerated;

  ClassFormState copyWith({
    bool? loading,
    bool? saving,
    TeachClass? initial,
    TeachClass? saved,
    Map<String, ClassFieldError>? clientErrors,
    Map<String, List<String>>? serverErrors,
    ApiException? error,
    int? sessionsGenerated,
  }) => ClassFormState(
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    initial: initial ?? this.initial,
    saved: saved ?? this.saved,
    clientErrors: clientErrors ?? this.clientErrors,
    serverErrors: serverErrors ?? this.serverErrors,
    error: error,
    sessionsGenerated: sessionsGenerated ?? this.sessionsGenerated,
  );

  @override
  List<Object?> get props => [
    loading, saving, initial, saved, clientErrors, serverErrors, error,
    sessionsGenerated, //
  ];
}

/// Form tạo/sửa lớp kèm quy tắc lặp (T06b).
///
/// Tạo mới là hai lệnh: `POST /classes` rồi `PUT /classes/{id}/schedule-rules`.
/// Nếu lệnh thứ hai lỗi, lớp đã tồn tại: [ClassFormState.initial] được gán
/// để lần bấm Lưu sau chuyển sang `PATCH`, không tạo lớp thứ hai.
class ClassFormCubit extends Cubit<ClassFormState> {
  ClassFormCubit(this._repo, {TeachClass? initial, this.classId})
    : super(
        ClassFormState(
          initial: initial,
          loading: initial == null && classId != null,
        ),
      );
  final ClassesRepository _repo;
  final String? classId;

  Future<void> load() async {
    if (!state.loading) return;
    try {
      emit(ClassFormState(initial: await _repo.get(classId!)));
    } on ApiException catch (e) {
      emit(ClassFormState(loading: true, error: e));
    }
  }

  Future<void> save(ClassInput input, List<ScheduleRule> rules) async {
    if (state.saving) return;
    final local = validateClass(input, rules);
    if (local.isNotEmpty) {
      emit(state.copyWith(clientErrors: local, serverErrors: const {}));
      return;
    }
    emit(
      state.copyWith(
        saving: true,
        clientErrors: const {},
        serverErrors: const {},
      ),
    );
    var existing = state.initial;
    try {
      int? generated;
      if (existing == null) {
        existing = (await _repo.create(input)).value;
        emit(state.copyWith(initial: existing));
      } else {
        existing = await _repo.update(existing.id, input);
        emit(state.copyWith(initial: existing));
      }
      if (_rulesChanged(existing, rules)) {
        generated = (await _repo.putRules(
          existing.id,
          rules,
        )).sessionsGenerated;
      }
      emit(
        state.copyWith(
          saving: false,
          saved: existing,
          sessionsGenerated: generated,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          saving: false,
          serverErrors: e.fieldErrors,
          error: e.fieldErrors.isEmpty ? e : null,
        ),
      );
    }
  }

  /// Lớp mới chưa có quy tắc và form cũng trống thì khỏi gọi `PUT`.
  static bool _rulesChanged(TeachClass c, List<ScheduleRule> rules) =>
      c.scheduleRules
          .map((r) => r.signature)
          .toSet()
          .difference(rules.map((r) => r.signature).toSet())
          .isNotEmpty ||
      rules
          .map((r) => r.signature)
          .toSet()
          .difference(c.scheduleRules.map((r) => r.signature).toSet())
          .isNotEmpty;
}
