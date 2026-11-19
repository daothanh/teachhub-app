import 'dart:async';

import 'package:teacher/features/classes/data/class_models.dart'
    show SessionStatus;
import 'package:teacher/features/schedule/data/schedule_models.dart';
import 'package:teacher/features/schedule/data/schedule_repository.dart';

/// Repository giả: lọc buổi trong bộ nhớ theo khoảng ngày, ghi lại lượt gọi.
class FakeScheduleRepository implements ScheduleRepository {
  FakeScheduleRepository([this.all = const []]);

  List<ScheduleSession> all;
  final watched = <(String, String)>[];
  final refreshed = <(String, String)>[];

  /// Ném khi refresh (`ApiException.network()` để giả mất mạng).
  Object? refreshError;

  /// Nếu đặt, refresh chờ completer này (test lượt trả muộn). Mỗi lượt lấy một
  /// completer đầu hàng.
  final gates = <Completer<void>>[];

  @override
  Stream<List<ScheduleSession>> watch(String from, String to) async* {
    watched.add((from, to));
    yield [
      for (final s in all)
        if (s.sessionDate.compareTo(from) >= 0 &&
            s.sessionDate.compareTo(to) <= 0)
          s,
    ];
  }

  @override
  Future<void> refresh(String from, String to) async {
    refreshed.add((from, to));
    if (gates.isNotEmpty) await gates.removeAt(0).future;
    if (refreshError != null) throw refreshError!;
  }
}

ScheduleSession sess(
  String id,
  String date,
  String time, {
  String className = 'Toán 6A',
  SessionStatus status = SessionStatus.planned,
  bool makeup = false,
  String? reason,
}) => ScheduleSession(
  id: id,
  className: className,
  sessionDate: date,
  startTime: time,
  status: status,
  isMakeup: makeup,
  cancelReason: reason,
);
