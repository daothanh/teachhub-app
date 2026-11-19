import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/features/attendance/data/attendance_models.dart';
import 'package:teacher/features/today/cubit/today_cubit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../attendance/fake_attendance_repository.dart';

const s = TodaySession(
  id: 's-1',
  className: 'Toán 6A',
  startTime: '08:00',
  cancelled: false,
  attended: false,
);

void main() {
  Future<TodayCubit> open(
    FakeAttendanceRepository repo, {
    DateTime Function()? now,
  }) async {
    final cubit = TodayCubit(repo, null, now: now);
    await cubit.start();
    await Future<void>.delayed(Duration.zero);
    return cubit;
  }

  test('start: bật đồng bộ, đọc cache rồi làm mới', () async {
    final repo = FakeAttendanceRepository(sessions: [s]);
    final cubit = await open(repo);
    addTearDown(cubit.close);
    expect(repo.startSyncCalls, 1);
    expect(repo.refreshTodayCalls, 1);
    expect(cubit.state.loaded, isTrue);
    expect(cubit.state.sessions, [s]);
    expect(cubit.state.offline, isFalse);
  });

  test(
    'mất mạng: giữ buổi từ cache, offline=true; có mạng lại thì tắt',
    () async {
      final repo = FakeAttendanceRepository(sessions: [s])
        ..refreshError = const ApiException.network();
      final cubit = await open(repo);
      addTearDown(cubit.close);
      expect(cubit.state.offline, isTrue);
      expect(cubit.state.sessions, [s]);
      expect(cubit.state.error, isNull);

      repo.refreshError = null;
      await cubit.refresh();
      expect(cubit.state.offline, isFalse);
    },
  );

  test('lỗi khác mạng: có error, không phải offline', () async {
    final repo = FakeAttendanceRepository(sessions: [s])
      ..refreshError = const ApiException.unexpected();
    final cubit = await open(repo);
    addTearDown(cubit.close);
    expect(cubit.state.offline, isFalse);
    expect(cubit.state.error, isNotNull);
  });

  test('chip: số chờ đồng bộ theo watchPending', () async {
    final repo = FakeAttendanceRepository(sessions: [s])..pending = 2;
    final cubit = await open(repo);
    addTearDown(cubit.close);
    expect(cubit.state.pending, 2);
    repo.setPending(0);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.pending, 0);
  });

  test('qua nửa đêm: làm mới đọc theo ngày mới', () async {
    var now = DateTime(2026, 11, 18, 23, 59);
    final dates = <String>[];
    final repo = _DateRepo(dates);
    final cubit = TodayCubit(repo, null, now: () => now);
    addTearDown(cubit.close);
    await cubit.start();
    now = DateTime(2026, 11, 19, 0, 1);
    await cubit.refresh();
    expect(dates, ['2026-11-18', '2026-11-19']);
  });

  test('đóng giữa lúc làm mới: không emit sau close', () async {
    final repo = FakeAttendanceRepository(sessions: [s]);
    final cubit = TodayCubit(repo, null);
    final starting = cubit.start();
    await cubit.close();
    await starting;
    expect(cubit.isClosed, isTrue);
  });
}

class _DateRepo extends FakeAttendanceRepository {
  _DateRepo(this.dates);
  final List<String> dates;
  @override
  Future<void> refreshToday(String date) async => dates.add(date);
}
