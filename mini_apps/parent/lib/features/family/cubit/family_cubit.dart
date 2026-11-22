import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../notification_permission_gate.dart';
import '../data/family_models.dart';
import '../data/family_repository.dart';

enum FamilyStatus { loading, ready, failure }

class FamilyState extends Equatable {
  const FamilyState({
    this.status = FamilyStatus.loading,
    this.students = const [],
    this.selectedId,
    this.week,
    this.weekLoading = false,
    this.weekFailed = false,
    this.notificationsOff = false,
    this.refreshFailed = false,
  });

  final FamilyStatus status;
  final List<FamilyStudent> students;
  final String? selectedId;

  /// Chuyên cần tuần của [selectedId]; `null` khi đang tải hoặc lỗi.
  final AttendanceWeek? week;
  final bool weekLoading;
  final bool weekFailed;
  final bool notificationsOff;

  /// Làm mới (đã có dữ liệu) bị lỗi: page báo SnackBar một lần, giữ màn cũ.
  final bool refreshFailed;

  FamilyStudent? get selected =>
      students.where((s) => s.id == selectedId).firstOrNull;

  FamilyState copyWith({
    FamilyStatus? status,
    List<FamilyStudent>? students,
    String? selectedId,
    bool clearSelected = false,
    AttendanceWeek? week,
    bool clearWeek = false,
    bool? weekLoading,
    bool? weekFailed,
    bool? notificationsOff,
    bool refreshFailed = false,
  }) => FamilyState(
    status: status ?? this.status,
    students: students ?? this.students,
    selectedId: clearSelected ? null : (selectedId ?? this.selectedId),
    week: clearWeek ? null : (week ?? this.week),
    weekLoading: weekLoading ?? this.weekLoading,
    weekFailed: weekFailed ?? this.weekFailed,
    notificationsOff: notificationsOff ?? this.notificationsOff,
    refreshFailed: refreshFailed,
  );

  @override
  List<Object?> get props => [
    status,
    students,
    selectedId,
    week,
    weekLoading,
    weekFailed,
    notificationsOff,
    refreshFailed,
  ];
}

/// P02: các con của phụ huynh, chọn con, chuyên cần tuần (US-0.3, US-0.4 AC2).
class FamilyCubit extends Cubit<FamilyState> {
  FamilyCubit(this._repo, {NotificationPermissionGate? notifications})
    : _notifications = notifications,
      super(const FamilyState());

  final FamilyRepository _repo;
  final NotificationPermissionGate? _notifications;

  Future<void> load() async {
    // Làm mới khi đã có dữ liệu thì giữ nguyên màn, không nháy vòng tải.
    final first = state.status != FamilyStatus.ready;
    // copyWith luôn xóa refreshFailed: lỗi làm mới lặp lại vẫn báo lại.
    emit(state.copyWith(status: first ? FamilyStatus.loading : null));
    try {
      final students = await _repo.students();
      if (isClosed) return;
      final keep = students.any((s) => s.id == state.selectedId);
      final selected = keep ? state.selectedId : students.firstOrNull?.id;
      emit(
        state.copyWith(
          status: FamilyStatus.ready,
          students: students,
          selectedId: selected,
          // Hết con (bị gỡ liên kết): bỏ id cũ để _loadWeek không gọi lại.
          clearSelected: selected == null,
          clearWeek: selected != state.selectedId,
        ),
      );
      await Future.wait([_loadWeek(), refreshNotifications()]);
    } catch (_) {
      if (isClosed) return;
      emit(
        first
            ? state.copyWith(status: FamilyStatus.failure)
            : state.copyWith(refreshFailed: true),
      );
    }
  }

  /// Chuyển con (phụ huynh nhiều con, US-0.4 AC2).
  Future<void> select(String studentId) async {
    if (studentId == state.selectedId) return;
    emit(state.copyWith(selectedId: studentId, clearWeek: true));
    await _loadWeek();
  }

  Future<void> retryWeek() => _loadWeek();

  Future<void> _loadWeek() async {
    final id = state.selectedId;
    if (id == null) return;
    emit(state.copyWith(weekLoading: true, weekFailed: false));
    try {
      final week = await _repo.attendance(id);
      // Đã chuyển sang con khác trong lúc chờ: bỏ kết quả cũ.
      if (isClosed || state.selectedId != id) return;
      emit(state.copyWith(week: week, weekLoading: false));
    } catch (_) {
      if (isClosed || state.selectedId != id) return;
      emit(state.copyWith(weekLoading: false, weekFailed: true));
    }
  }

  Future<void> refreshNotifications() async {
    final gate = _notifications;
    if (gate == null) return;
    try {
      final enabled = await gate.isEnabled();
      if (!isClosed) emit(state.copyWith(notificationsOff: !enabled));
    } catch (_) {}
  }

  Future<void> enableNotifications() async {
    final gate = _notifications;
    if (gate == null) return;
    try {
      final enabled = await gate.request();
      if (!isClosed) emit(state.copyWith(notificationsOff: !enabled));
    } catch (_) {}
  }
}
