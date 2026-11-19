import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../data/class_models.dart';
import '../data/classes_repository.dart';
import 'classes_list_cubit.dart' show ClassesLoad;

class ClassDetailState extends Equatable {
  const ClassDetailState({
    this.load = ClassesLoad.loading,
    this.cls,
    this.roster = const [],
    this.sessions = const [],
    this.sessionsError = false,
    this.archiving = false,
    this.error,
    this.actionError,
  });

  final ClassesLoad load;
  final TeachClass? cls;
  final List<RosterEntry> roster;
  final List<ClassSession> sessions;

  /// Tải buổi học lỗi thì vẫn xem được lớp và danh sách học viên.
  final bool sessionsError;
  final bool archiving;

  /// Lỗi tải màn.
  final ApiException? error;

  /// Lỗi của thao tác (lưu trữ…), hiện bằng thông báo.
  final ApiException? actionError;

  ClassDetailState copyWith({
    ClassesLoad? load,
    TeachClass? cls,
    List<RosterEntry>? roster,
    List<ClassSession>? sessions,
    bool? sessionsError,
    bool? archiving,
    ApiException? error,
    ApiException? actionError,
  }) => ClassDetailState(
    load: load ?? this.load,
    cls: cls ?? this.cls,
    roster: roster ?? this.roster,
    sessions: sessions ?? this.sessions,
    sessionsError: sessionsError ?? this.sessionsError,
    archiving: archiving ?? this.archiving,
    error: error,
    actionError: actionError,
  );

  @override
  List<Object?> get props => [
    load,
    cls,
    roster,
    sessions,
    sessionsError,
    archiving,
    error,
    actionError, //
  ];
}

/// Chi tiết lớp (T06a): thông tin, quy tắc lặp, buổi sắp tới, học viên.
class ClassDetailCubit extends Cubit<ClassDetailState> {
  ClassDetailCubit(this._repo, this.classId, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(const ClassDetailState());
  final ClassesRepository _repo;
  final String classId;
  final DateTime Function() _now;

  /// Cửa sổ buổi học: hôm nay + 61 ngày = đúng 62 ngày, trần của `GET /sessions`.
  static const sessionWindowDays = 61;

  Future<void> load() async {
    emit(const ClassDetailState());
    try {
      final today = _now();
      final results = await Future.wait([
        _repo.get(classId),
        _repo.roster(classId),
      ]);
      final cls = results[0] as TeachClass;
      var sessions = const <ClassSession>[];
      var sessionsError = false;
      try {
        sessions = cls.archived
            ? const []
            : await _repo.sessions(
                from: isoDate(today),
                to: isoDate(today.add(const Duration(days: sessionWindowDays))),
                classId: classId,
              );
      } on ApiException {
        sessionsError = true;
      }
      emit(
        ClassDetailState(
          load: ClassesLoad.ready,
          cls: cls,
          roster: results[1] as List<RosterEntry>,
          sessions: sessions,
          sessionsError: sessionsError,
        ),
      );
    } on ApiException catch (e) {
      emit(ClassDetailState(load: ClassesLoad.failure, error: e));
    }
  }

  /// Lưu trữ lớp (US-1.1 AC3). Lỗi → [ClassDetailState.actionError].
  Future<void> archive() async {
    if (state.archiving) return;
    emit(state.copyWith(archiving: true));
    try {
      final cls = await _repo.archive(classId);
      emit(state.copyWith(cls: cls, sessions: const [], archiving: false));
    } on ApiException catch (e) {
      emit(state.copyWith(archiving: false, actionError: e));
    }
  }
}
