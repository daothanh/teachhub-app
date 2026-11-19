import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../data/class_models.dart';
import '../data/classes_repository.dart';
import '../data/draft_keys.dart';

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
  ClassFormCubit(
    this._repo, {
    TeachClass? initial,
    this.classId,
    DraftKeys? keys,
  }) : _keys = keys ?? DraftKeys(),
       super(
         ClassFormState(
           initial: initial,
           loading: initial == null && classId != null,
         ),
       );
  final ClassesRepository _repo;
  final String? classId;
  final DraftKeys _keys;

  Future<void> load() async {
    if (!state.loading) return;
    try {
      final c = await _repo.get(classId!);
      if (isClosed) return;
      emit(ClassFormState(initial: c));
    } on ApiException catch (e) {
      if (isClosed) return;
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
    // Mỗi lệnh ghi một khóa theo draft: bấm Lưu lại sau lỗi mạng dùng lại khóa.
    final body = input.toJson().toString();
    var op = 'create';
    try {
      int? generated;
      if (existing == null) {
        existing = (await _repo.create(
          input,
          idempotencyKey: _keys.of('create', body),
        )).value;
        _keys.done('create');
        if (isClosed) return;
        emit(state.copyWith(initial: existing));
      } else {
        op = 'update';
        existing = await _repo.update(
          existing.id,
          input,
          idempotencyKey: _keys.of('update', '${existing.id}|$body'),
        );
        _keys.done('update');
        if (isClosed) return;
        emit(state.copyWith(initial: existing));
      }
      if (_rulesChanged(existing, rules)) {
        op = 'rules';
        generated = (await _repo.putRules(
          existing.id,
          rules,
          idempotencyKey: _keys.of(
            'rules',
            '${existing.id}|${rules.map((r) => r.signature).join(',')}',
          ),
        )).sessionsGenerated;
        _keys.done('rules');
      }
      if (isClosed) return;
      emit(
        state.copyWith(
          saving: false,
          saved: existing,
          sessionsGenerated: generated,
        ),
      );
    } on ApiException catch (e) {
      // `op` là lệnh đang dở khi lỗi; lỗi chắc chắn thì lần sau là lệnh mới.
      if (!e.retryable) _keys.done(op);
      if (isClosed) return;
      final (fields, unknown) = _splitFieldErrors(e.fieldErrors);
      emit(
        state.copyWith(
          saving: false,
          serverErrors: fields,
          // Không có trường nào nhận được lỗi thì báo chung, kẻo người dùng
          // bấm Lưu mà không thấy gì.
          error: fields.isEmpty || unknown ? e : null,
        ),
      );
    }
  }

  static const _knownFields = {
    'name', 'subject', 'grade', 'mode', 'location', 'capacity', //
    'startDate', 'endDate', 'rules', //
  };

  /// Gộp mọi khóa `rules*` (vd. `rules.0.startTime`) vào `rules`; khóa không
  /// thuộc form đánh dấu `unknown` để hiện lỗi chung.
  static (Map<String, List<String>>, bool) _splitFieldErrors(
    Map<String, List<String>> raw,
  ) {
    final out = <String, List<String>>{};
    var unknown = false;
    for (final MapEntry(:key, :value) in raw.entries) {
      final k = key.startsWith('rules') ? 'rules' : key;
      if (_knownFields.contains(k)) {
        out[k] = [...?out[k], ...value];
      } else {
        unknown = true;
      }
    }
    return (out, unknown);
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
