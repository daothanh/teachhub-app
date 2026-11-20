import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../attendance/data/attendance_models.dart';
import '../../attendance/data/attendance_repository.dart';
import '../../classes/data/class_models.dart' show isoDate;
import '../../onboarding/data/onboarding_models.dart';
import '../../onboarding/data/onboarding_repository.dart';

class TodayState extends Equatable {
  const TodayState({
    this.loaded = false,
    this.sessions = const [],
    this.pending = 0,
    this.offline = false,
    this.error,
    this.skippedSteps = const [],
  });

  /// Cache đã đọc xong lần đầu.
  final bool loaded;
  final List<TodaySession> sessions;

  /// Số mutation chờ đồng bộ (chip "Chờ đồng bộ").
  final int pending;

  /// Lần làm mới gần nhất không có mạng: đang hiện bản đã lưu.
  final bool offline;
  final ApiException? error;

  /// Bước onboarding đã bỏ qua (US-0.2 AC2), theo thứ tự bước.
  final List<OnboardingStep> skippedSteps;

  @override
  List<Object?> get props => [
    loaded,
    sessions,
    pending,
    offline,
    error,
    skippedSteps,
  ];
}

/// T03 "Hôm nay": buổi hôm nay của mọi lớp. Đọc cache trước, làm mới từ API sau.
class TodayCubit extends Cubit<TodayState> {
  TodayCubit(this._repo, this._onboarding, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(const TodayState());

  final AttendanceRepository _repo;
  final OnboardingRepository? _onboarding;
  final DateTime Function() _now;
  StreamSubscription<List<TodaySession>>? _sessions;
  StreamSubscription<int>? _pending;
  String? _date;
  bool _refreshing = false;

  /// Mở màn: bật đồng bộ, đọc cache, làm mới.
  /// shortcut: "hôm nay" theo ngày của máy, chưa theo múi giờ tenant (app chưa
  /// biết múi giờ tenant); đủ cho tenant cùng múi giờ với giáo viên.
  Future<void> start() async {
    if (isClosed) return;
    // Bật engine trước để watchPending thấy engine đang chạy.
    try {
      await _repo.startSync();
    } catch (_) {}
    if (isClosed) return;
    _pending = _repo.watchPending().listen((n) {
      if (!isClosed) emit(_copy(pending: n));
    }, onError: _onStreamError);
    _watchToday();
    unawaited(_loadOnboarding());
    await refresh();
  }

  void _onStreamError(Object _) {
    if (!isClosed) emit(_copy(error: const ApiException.unexpected()));
  }

  void _watchToday() {
    if (isClosed) return;
    final date = isoDate(_now());
    if (date == _date) return;
    _date = date;
    _sessions?.cancel();
    _sessions = _repo.watchSessions(date).listen((list) {
      if (!isClosed) emit(_copy(loaded: true, sessions: list));
    }, onError: _onStreamError);
  }

  Future<void> refresh() async {
    if (isClosed || _refreshing) return;
    _refreshing = true;
    _watchToday(); // qua nửa đêm thì đổi sang ngày mới
    try {
      await _repo.refreshToday(_date!);
      if (isClosed) return;
      emit(_copy(offline: false, clearError: true));
    } on ApiException catch (e) {
      if (isClosed) return;
      final network = e.kind == ApiErrorKind.network;
      emit(
        _copy(offline: network, error: network ? null : e, clearError: network),
      );
    } catch (_) {
      // Lỗi ngoài dự kiến (vd. CSDL đóng): báo lỗi chung, kéo xuống để thử lại.
      if (isClosed) return;
      emit(_copy(error: const ApiException.unexpected()));
    } finally {
      _refreshing = false;
    }
    unawaited(_loadOnboarding());
  }

  /// Thẻ nhắc là phụ: lỗi (mất mạng) thì không hiện thẻ, không báo lỗi.
  Future<void> _loadOnboarding() async {
    final repo = _onboarding;
    if (repo == null) return;
    try {
      final data = await repo.get();
      if (isClosed) return;
      emit(
        _copy(
          skippedSteps: [
            for (final e in data.steps.entries)
              if (e.value == OnboardingStatus.skipped) e.key,
          ],
        ),
      );
    } on ApiException {
      // giữ thẻ cũ
    }
  }

  TodayState _copy({
    bool? loaded,
    List<TodaySession>? sessions,
    int? pending,
    bool? offline,
    ApiException? error,
    bool clearError = false,
    List<OnboardingStep>? skippedSteps,
  }) => TodayState(
    loaded: loaded ?? state.loaded,
    sessions: sessions ?? state.sessions,
    pending: pending ?? state.pending,
    offline: offline ?? state.offline,
    error: clearError ? null : error ?? state.error,
    skippedSteps: skippedSteps ?? state.skippedSteps,
  );

  @override
  Future<void> close() async {
    await _sessions?.cancel();
    await _pending?.cancel();
    return super.close();
  }
}
