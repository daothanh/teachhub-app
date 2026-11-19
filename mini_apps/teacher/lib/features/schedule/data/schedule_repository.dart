import 'package:get_it/get_it.dart';

import '../../../data/cache/session_cache.dart';
import '../../../data/local_db/teacher_database.dart';
import '../../classes/data/class_models.dart' show SessionStatus;
import 'schedule_models.dart';

/// Nguồn dữ liệu của lịch (T05): đọc cache Drift, làm mới bằng `GET /sessions`.
abstract class ScheduleRepository {
  /// Buổi của mọi lớp trong khoảng ngày `yyyy-MM-dd` (gồm hai đầu), sắp theo giờ.
  Stream<List<ScheduleSession>> watch(String from, String to);

  /// `GET /sessions?from&to` (tối đa 62 ngày, không phân trang) rồi ghi cache.
  /// Lỗi ném `ApiException`; mất mạng là `ApiException.network()`.
  Future<void> refresh(String from, String to);
}

/// Bản dùng thật; [TeacherController] đăng ký vào GetIt.
ScheduleRepository scheduleRepository() => GetIt.I<ScheduleRepository>();

class DriftScheduleRepository implements ScheduleRepository {
  DriftScheduleRepository({required Future<SessionCache> Function() cache})
    : _cache = cache;

  final Future<SessionCache> Function() _cache;

  @override
  Stream<List<ScheduleSession>> watch(String from, String to) async* {
    final cache = await _cache();
    yield* cache
        .watchSessions(from, to)
        .map((rows) => [for (final r in rows) _toSession(r)]);
  }

  @override
  Future<void> refresh(String from, String to) async =>
      (await _cache()).refreshSessions(from, to);
}

ScheduleSession _toSession(CachedSession s) => ScheduleSession(
  id: s.id,
  className: s.className,
  sessionDate: s.sessionDate,
  startTime: _wallTime(s),
  status: SessionStatus.fromWire(s.status),
  isMakeup: s.isMakeup,
  cancelReason: s.cancelReason,
);

/// Giờ tường `HH:mm` theo offset của tenant; dòng cũ chưa có offset thì giờ máy.
String _wallTime(CachedSession s) {
  final t = s.tzOffsetMinutes == null
      ? s.startsAt.toLocal()
      : s.startsAt.toUtc().add(Duration(minutes: s.tzOffsetMinutes!));
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.hour)}:${two(t.minute)}';
}
