import 'package:equatable/equatable.dart';

import '../../classes/data/class_models.dart' show SessionStatus;

/// Một buổi trong lịch ngày/tuần (T05).
class ScheduleSession extends Equatable {
  const ScheduleSession({
    required this.id,
    required this.className,
    required this.sessionDate,
    required this.startTime,
    required this.status,
    required this.isMakeup,
    this.cancelReason,
  });

  final String id;
  final String className;

  /// Ngày theo múi giờ tenant, `yyyy-MM-dd`.
  final String sessionDate;

  /// Giờ tường `HH:mm` theo offset của tenant.
  final String startTime;
  final SessionStatus status;
  final bool isMakeup;
  final String? cancelReason;

  bool get cancelled => status == SessionStatus.cancelled;

  @override
  List<Object?> get props => [
    id,
    className,
    sessionDate,
    startTime,
    status,
    isMakeup,
    cancelReason,
  ];
}
