import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../classes/data/class_models.dart' show isoDate;
import '../data/schedule_models.dart';
import '../data/schedule_repository.dart';

enum ScheduleMode { day, week }

class ScheduleState extends Equatable {
  const ScheduleState({
    required this.mode,
    required this.anchor,
    this.sessions = const [],
    this.refreshed = false,
    this.offline = false,
    this.error,
  });

  final ScheduleMode mode;

  /// Ngày đang xem (chỉ ngày, không giờ); chế độ tuần lấy tuần chứa ngày này.
  final DateTime anchor;
  final List<ScheduleSession> sessions;

  /// Lượt làm mới của khoảng đang xem đã xong (thành công hay lỗi).
  final bool refreshed;

  /// Lượt làm mới gần nhất không có mạng: đang hiện bản đã lưu.
  final bool offline;
  final ApiException? error;

  /// Đang tải: chưa có gì để hiện và lượt làm mới chưa xong.
  bool get loading => !refreshed && sessions.isEmpty;

  /// Đầu khoảng đang xem: ngày đang xem, hoặc Thứ Hai của tuần chứa nó.
  DateTime get from => mode == ScheduleMode.day
      ? anchor
      : DateTime(anchor.year, anchor.month, anchor.day - (anchor.weekday - 1));

  DateTime get to => mode == ScheduleMode.day
      ? anchor
      : DateTime(from.year, from.month, from.day + 6);

  @override
  List<Object?> get props => [
    mode,
    anchor,
    sessions,
    refreshed,
    offline,
    error,
  ];
}

/// T05 lịch ngày/tuần: buổi của mọi lớp trong khoảng đang xem. Đọc cache trước,
/// làm mới từ API sau; đổi khoảng nhanh thì lượt trả muộn của khoảng cũ bị bỏ.
class ScheduleCubit extends Cubit<ScheduleState> {
  ScheduleCubit(this._repo, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(
        ScheduleState(
          mode: ScheduleMode.day,
          anchor: _dateOnly((now ?? DateTime.now)()),
        ),
      );

  final ScheduleRepository _repo;
  final DateTime Function() _now;
  StreamSubscription<List<ScheduleSession>>? _sub;
  int _gen = 0;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// shortcut: "hôm nay" theo ngày của máy, chưa theo múi giờ tenant; đủ cho
  /// tenant cùng múi giờ với giáo viên.
  Future<void> start() => _load();

  Future<void> setMode(ScheduleMode mode) =>
      _move(ScheduleState(mode: mode, anchor: state.anchor));

  /// Sang ngày/tuần liền kề: [steps] là +1/-1 theo chế độ đang xem.
  Future<void> shift(int steps) {
    final a = state.anchor;
    final days = steps * (state.mode == ScheduleMode.week ? 7 : 1);
    return _move(
      ScheduleState(
        mode: state.mode,
        anchor: DateTime(a.year, a.month, a.day + days),
      ),
    );
  }

  Future<void> goToday() =>
      _move(ScheduleState(mode: state.mode, anchor: _dateOnly(_now())));

  /// Kéo xuống / nút Thử lại: giữ danh sách đang hiện, tải lại khoảng này.
  Future<void> refresh() => _refresh();

  Future<void> _move(ScheduleState next) {
    if (isClosed) return Future.value();
    _gen++; // lượt làm mới của khoảng cũ trả muộn sẽ bị bỏ ngay từ giờ
    emit(next);
    return _load();
  }

  Future<void> _load() async {
    if (isClosed) return;
    final from = isoDate(state.from), to = isoDate(state.to);
    String key() => '${isoDate(state.from)}|${isoDate(state.to)}';
    final range = key();
    // Không await: hai lần chuyển khoảng sát nhau không được để lọt một sub.
    unawaited(_sub?.cancel());
    _sub = _repo
        .watch(from, to)
        .listen(
          (list) {
            // Bỏ kết quả của khoảng cũ nếu người dùng đã chuyển đi.
            if (isClosed || key() != range) return;
            emit(_copy(sessions: list));
          },
          onError: (Object _) {
            if (isClosed) return;
            emit(
              _copy(error: const ApiException.unexpected(), refreshed: true),
            );
          },
        );
    await _refresh();
  }

  Future<void> _refresh() async {
    if (isClosed) return;
    final gen = ++_gen;
    final from = isoDate(state.from), to = isoDate(state.to);
    try {
      await _repo.refresh(from, to);
      if (isClosed || gen != _gen) return;
      emit(_copy(refreshed: true, offline: false, clearError: true));
    } on ApiException catch (e) {
      if (isClosed || gen != _gen) return;
      final network = e.kind == ApiErrorKind.network;
      emit(
        _copy(
          refreshed: true,
          offline: network,
          error: network ? null : e,
          clearError: network,
        ),
      );
    } catch (_) {
      // Lỗi ngoài dự kiến (vd. CSDL đóng): báo lỗi chung, có nút Thử lại.
      if (isClosed || gen != _gen) return;
      emit(_copy(refreshed: true, error: const ApiException.unexpected()));
    }
  }

  ScheduleState _copy({
    List<ScheduleSession>? sessions,
    bool? refreshed,
    bool? offline,
    ApiException? error,
    bool clearError = false,
  }) => ScheduleState(
    mode: state.mode,
    anchor: state.anchor,
    sessions: sessions ?? state.sessions,
    refreshed: refreshed ?? state.refreshed,
    offline: offline ?? state.offline,
    error: clearError ? null : error ?? state.error,
  );

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
