import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/features/schedule/cubit/schedule_cubit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'fake_schedule_repository.dart';

// Thứ Tư 18/11/2026.
final wed = DateTime(2026, 11, 18, 15);

void main() {
  Future<ScheduleCubit> open(FakeScheduleRepository repo) async {
    final cubit = ScheduleCubit(repo, now: () => wed);
    await cubit.start();
    await Future<void>.delayed(Duration.zero);
    return cubit;
  }

  test('AC-1/2: mở ở chế độ ngày hôm nay, đọc cache rồi làm mới', () async {
    final repo = FakeScheduleRepository([
      sess('a', '2026-11-18', '08:00'),
      sess('b', '2026-11-19', '08:00'),
    ]);
    final c = await open(repo);
    addTearDown(c.close);
    expect(c.state.mode, ScheduleMode.day);
    expect(repo.refreshed, [('2026-11-18', '2026-11-18')]);
    expect(c.state.sessions.map((s) => s.id), ['a']);
    expect(c.state.refreshed, isTrue);
    expect(c.state.loading, isFalse);
  });

  test(
    'AC-1: chế độ tuần là Thứ Hai đến Chủ nhật của tuần chứa ngày xem',
    () async {
      final repo = FakeScheduleRepository([
        sess('mon', '2026-11-16', '08:00'),
        sess('sun', '2026-11-22', '08:00'),
        sess('next', '2026-11-23', '08:00'),
      ]);
      final c = await open(repo);
      addTearDown(c.close);
      await c.setMode(ScheduleMode.week);
      await Future<void>.delayed(Duration.zero);
      expect(repo.refreshed.last, ('2026-11-16', '2026-11-22'));
      expect(c.state.sessions.map((s) => s.id), ['mon', 'sun']);

      await c.shift(1);
      await Future<void>.delayed(Duration.zero);
      expect(repo.refreshed.last, ('2026-11-23', '2026-11-29'));
      expect(c.state.sessions.map((s) => s.id), ['next']);
    },
  );

  test(
    'AC-1: Chủ nhật thuộc tuần của Thứ Hai trước đó; qua tháng/năm đúng',
    () async {
      final repo = FakeScheduleRepository();
      final c = ScheduleCubit(repo, now: () => DateTime(2026, 11, 22));
      addTearDown(c.close);
      await c.setMode(ScheduleMode.week);
      expect(repo.refreshed.last, ('2026-11-16', '2026-11-22'));
      await c.goToday();
      for (var i = 0; i < 6; i++) {
        await c.shift(1);
      }
      expect(repo.refreshed.last, ('2026-12-28', '2027-01-03'));
      await c.setMode(ScheduleMode.day);
      await c.shift(-1);
      expect(repo.refreshed.last, ('2027-01-02', '2027-01-02'));
    },
  );

  test('AC-4: mất mạng giữ buổi đã lưu, offline=true, không báo lỗi', () async {
    final repo = FakeScheduleRepository([sess('a', '2026-11-18', '08:00')])
      ..refreshError = const ApiException.network();
    final c = await open(repo);
    addTearDown(c.close);
    expect(c.state.offline, isTrue);
    expect(c.state.error, isNull);
    expect(c.state.sessions, hasLength(1));

    repo.refreshError = null;
    await c.refresh();
    expect(c.state.offline, isFalse);
  });

  test('AC-6: lỗi khác mạng báo error, Thử lại (refresh) xóa lỗi', () async {
    final repo = FakeScheduleRepository()
      ..refreshError = const ApiException.unexpected();
    final c = await open(repo);
    addTearDown(c.close);
    expect(c.state.error, isNotNull);
    expect(c.state.refreshed, isTrue);

    repo.refreshError = null;
    await c.refresh();
    expect(c.state.error, isNull);
  });

  test(
    'AC-6: lỗi ngoài ApiException cũng thành lỗi chung, không văng',
    () async {
      final repo = FakeScheduleRepository()
        ..refreshError = StateError('db đóng');
      final c = await open(repo);
      addTearDown(c.close);
      expect(c.state.error, isNotNull);
    },
  );

  test(
    'AC-6: lượt trả muộn của khoảng cũ bị bỏ khi đổi khoảng nhanh',
    () async {
      final repo = FakeScheduleRepository()
        ..gates.addAll([Completer<void>(), Completer<void>()])
        ..refreshError = const ApiException.network();
      final first = repo.gates.first;
      final second = repo.gates.last;
      final cubit = ScheduleCubit(repo, now: () => wed);
      addTearDown(cubit.close);

      unawaited(cubit.start()); // lượt 1: ngày 18, đang chờ
      await Future<void>.delayed(Duration.zero);
      final moved = cubit.shift(1); // lượt 2: ngày 19
      await Future<void>.delayed(Duration.zero);

      repo.refreshError = null;
      second.complete(); // lượt 2 xong thành công
      await moved;
      expect(cubit.state.offline, isFalse);

      repo.refreshError = const ApiException.network();
      first.complete(); // lượt 1 trả muộn (mất mạng) không được ghi đè
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.offline, isFalse);
      expect(cubit.state.anchor, DateTime(2026, 11, 19));
    },
  );

  test(
    'AC-6: đóng cubit khi đang chờ API rồi API trả lỗi: không ném',
    () async {
      final gate = Completer<void>();
      final repo = FakeScheduleRepository()
        ..gates.add(gate)
        ..refreshError = const ApiException.unexpected();
      final cubit = ScheduleCubit(repo, now: () => wed);
      final started = cubit.start();
      await Future<void>.delayed(Duration.zero);
      await cubit.close();
      gate.complete();
      await started; // emit sau close sẽ ném StateError nếu thiếu isClosed
    },
  );

  test(
    'goToday khi đang ở hôm nay: không tải lại, không xóa danh sách',
    () async {
      final repo = FakeScheduleRepository([sess('a', '2026-11-18', '08:00')]);
      final c = await open(repo);
      addTearDown(c.close);
      await c.goToday();
      await c.setMode(ScheduleMode.day);
      expect(repo.refreshed, hasLength(1));
      expect(c.state.sessions, hasLength(1));
    },
  );

  test('đổi sang tuần giữ buổi còn trong khoảng, không nháy rỗng', () async {
    final repo = FakeScheduleRepository([sess('a', '2026-11-18', '08:00')])
      ..manual = true;
    final c = ScheduleCubit(repo, now: () => wed);
    addTearDown(c.close);
    unawaited(c.start());
    await Future<void>.delayed(Duration.zero);
    repo.streams['2026-11-18|2026-11-18']!.add([
      sess('a', '2026-11-18', '08:00'),
    ]);
    await Future<void>.delayed(Duration.zero);

    final states = <ScheduleState>[];
    final sub = c.stream.listen(states.add);
    addTearDown(sub.cancel);
    await c.setMode(ScheduleMode.week);
    expect(states.first.sessions.map((s) => s.id), ['a']);
  });

  test('onError của stream cache: báo lỗi chung có thể Thử lại', () async {
    final repo = FakeScheduleRepository()..watchError = StateError('db đóng');
    final c = await open(repo);
    addTearDown(c.close);
    expect(c.state.error, isNotNull);
    expect(c.state.refreshed, isTrue);
  });

  test('stream của khoảng cũ phát muộn sau đổi khoảng bị bỏ', () async {
    final repo = FakeScheduleRepository()..manual = true;
    final c = ScheduleCubit(repo, now: () => wed);
    addTearDown(c.close);
    unawaited(c.start());
    await Future<void>.delayed(Duration.zero);
    final old = repo.streams['2026-11-18|2026-11-18']!;
    await c.shift(1);
    await Future<void>.delayed(Duration.zero);
    old.add([sess('stale', '2026-11-18', '08:00')]);
    await Future<void>.delayed(Duration.zero);
    expect(c.state.sessions, isEmpty);
    repo.streams['2026-11-19|2026-11-19']!.add([
      sess('new', '2026-11-19', '09:00'),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(c.state.sessions.map((s) => s.id), ['new']);
  });
}
