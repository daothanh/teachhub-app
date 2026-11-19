import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/features/attendance/cubit/history_cubit.dart';
import 'package:teacher/features/attendance/data/attendance_models.dart';
import 'package:teacher/features/attendance/pages/history_page.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../support/pump_app.dart';
import 'fake_attendance_repository.dart';

HistoryItem item(
  String id, {
  String? by = 'Cô Lan',
  HistorySnapshot? before,
  HistorySnapshot? after,
}) => HistoryItem(
  id: id,
  studentName: 'Em 1',
  changedByName: by,
  changedAt: DateTime.utc(2026, 11, 18, 12, 50),
  before: before,
  after:
      after ??
      const HistorySnapshot(status: AttendanceStatus.present, note: null),
);

void main() {
  test('load rồi loadMore nối trang theo con trỏ', () async {
    final repo = FakeAttendanceRepository()
      ..histories.addAll([
        HistoryChunk([item('1')], '1'),
        HistoryChunk([item('2')], null),
      ]);
    final cubit = HistoryCubit(repo, sessionId);
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state.items.map((i) => i.id), ['1']);
    await cubit.loadMore();
    expect(cubit.state.items.map((i) => i.id), ['1', '2']);
    expect(cubit.state.nextCursor, isNull);
    await cubit.loadMore(); // hết trang: không gọi thêm
    expect(repo.historyCalls, 2);
  });

  test(
    'lỗi trang đầu → failure; lỗi trang sau giữ danh sách và cho thử lại',
    () async {
      final repo = FakeAttendanceRepository()
        ..histories.add(HistoryChunk([item('1')], '1'))
        ..historyError = const ApiException.network();
      final cubit = HistoryCubit(repo, sessionId);
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.load, HistoryLoad.failure);

      repo.historyError = null;
      await cubit.load();
      repo.historyError = const ApiException.network();
      await cubit.loadMore();
      expect(cubit.state.items, hasLength(1));
      expect(cubit.state.loadMoreFailed, isTrue);
      expect(cubit.state.nextCursor, '1');
    },
  );

  testWidgets(
    'AC-13: hiện tên người sửa, thời điểm, trước/sau; không có id hay email',
    (tester) async {
      final repo = FakeAttendanceRepository()
        ..histories.add(
          HistoryChunk([
            item(
              '1',
              before: const HistorySnapshot(
                status: AttendanceStatus.unexcused,
                note: null,
              ),
              after: const HistorySnapshot(
                status: AttendanceStatus.present,
                note: 'nhầm',
              ),
            ),
            item('2', by: null),
          ], null),
        );
      await pumpApp(
        tester,
        HistoryPage(sessionId: sessionId, repository: repo),
      );

      expect(find.textContaining('Cô Lan'), findsOneWidget);
      expect(find.textContaining('Không rõ người sửa'), findsOneWidget);
      expect(find.text('Vắng không phép'), findsOneWidget);
      expect(find.text('Có mặt'), findsNWidgets(2));
      expect(find.text('Điểm danh lần đầu'), findsOneWidget);
      expect(find.textContaining('nhầm'), findsOneWidget);
    },
  );

  testWidgets('buổi chưa có lần sửa nào → trạng thái rỗng', (tester) async {
    final repo = FakeAttendanceRepository()
      ..histories.add(HistoryChunk([], null));
    await pumpApp(tester, HistoryPage(sessionId: sessionId, repository: repo));
    expect(find.text('Buổi này chưa có lần sửa nào.'), findsOneWidget);
  });
}
