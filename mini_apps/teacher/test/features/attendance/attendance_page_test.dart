import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:teacher/features/attendance/data/attendance_models.dart';
import 'package:teacher/features/attendance/pages/attendance_page.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../support/pump_app.dart';
import 'fake_attendance_repository.dart';

Future<GoRouter> open(
  WidgetTester tester,
  FakeAttendanceRepository repo, {
  double textScale = 1,
}) async {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/sheet'),
            child: const Text('mở'),
          ),
        ),
      ),
      GoRoute(
        path: '/sheet',
        builder: (_, _) =>
            AttendancePage(sessionId: sessionId, repository: repo),
      ),
      GoRoute(
        path: '/t/sessions/:id/attendance/history',
        builder: (_, _) => const Text('history-page'),
      ),
    ],
  );
  await pumpRouter(tester, router, textScale: textScale);
  await tester.tap(find.text('mở'));
  await tester.pumpAndSettle();
  return router;
}

Finder save() => find.widgetWithText(ElevatedButton, 'Lưu');

void main() {
  List<SheetStudent> roster(int n) => [for (var i = 1; i <= n; i++) student(i)];

  testWidgets(
    'AC-6: mặc định Có mặt; chạm đổi nhãn chữ theo vòng 4 trạng thái',
    (tester) async {
      await open(tester, FakeAttendanceRepository(sheet: sheetOf(roster(2))));
      expect(find.text('Có mặt'), findsNWidgets(2));

      final row = find.text('Em 1');
      for (final label in [
        'Vắng có phép',
        'Vắng không phép',
        'Đi muộn',
        'Có mặt',
      ]) {
        await tester.tap(row);
        await tester.pumpAndSettle();
        expect(find.text(label), findsWidgets);
      }
      // Chỉ Em 1 đổi: Em 2 vẫn Có mặt.
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.text('Có mặt'), findsOneWidget);
      expect(find.text('Vắng có phép'), findsOneWidget);
    },
  );

  testWidgets(
    'a11y: semantics label gồm tên và trạng thái, đổi theo trạng thái',
    (tester) async {
      final handle = tester.ensureSemantics();
      await open(tester, FakeAttendanceRepository(sheet: sheetOf(roster(1))));
      expect(
        find.bySemanticsLabel('Em 1, Có mặt. Chạm để đổi trạng thái'),
        findsOneWidget,
      );
      await tester.tap(find.text('Em 1'));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('Em 1, Vắng có phép. Chạm để đổi trạng thái'),
        findsOneWidget,
      );
      handle.dispose();
    },
  );

  testWidgets('a11y: chữ 130% với tên dài và trạng thái dài không tràn', (
    tester,
  ) async {
    final repo = FakeAttendanceRepository(
      sheet: sheetOf([
        SheetStudent(
          studentId: 'st-1',
          fullName: 'Nguyễn Hoàng Phương Anh Thư Khánh Vân',
          status: AttendanceStatus.unexcused,
          note: 'ghi chú dài ' * 20,
          rejectedCode: 'ATTENDANCE_EDIT_WINDOW_CLOSED',
        ),
      ], batchErrorCode: 'NOT_FOUND'),
    )..refreshError = const ApiException.network();
    await open(tester, repo, textScale: 1.3);
    expect(tester.takeException(), isNull);
    expect(find.text('Vắng không phép'), findsOneWidget);
  });

  testWidgets('AC-7/8: lớp đủ mặt: mở rồi Lưu; Lưu ghi đủ em và đóng màn', (
    tester,
  ) async {
    final repo = FakeAttendanceRepository(sheet: sheetOf(roster(20)));
    await open(tester, repo);
    await tester.tap(save());
    await tester.pumpAndSettle();

    expect(repo.saves.single.entries, hasLength(20));
    expect(find.text('mở'), findsOneWidget); // đã quay về màn trước
  });

  testWidgets('AC-9: ghi chú có bộ đếm 0/500 và được lưu cùng em đó', (
    tester,
  ) async {
    final repo = FakeAttendanceRepository(sheet: sheetOf(roster(2)));
    await open(tester, repo);

    await tester.tap(find.byTooltip('Ghi chú cho Em 1'));
    await tester.pumpAndSettle();
    expect(find.text('0/500'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'đi khám');
    await tester.pumpAndSettle();
    expect(find.text('7/500'), findsOneWidget);

    await tester.tap(save());
    await tester.pumpAndSettle();
    final byId = {for (final e in repo.saves.single.entries) e.studentId: e};
    expect(byId['st-1']!.note, 'đi khám');
    expect(byId['st-2']!.note, isNull);
  });

  testWidgets(
    'AC-11: lô lỗi và bản bị từ chối hiện thành banner / nhãn trên em',
    (tester) async {
      final repo = FakeAttendanceRepository(
        sheet: sheetOf([
          student(1, rejected: 'ATTENDANCE_EDIT_WINDOW_CLOSED'),
          student(2),
        ], batchErrorCode: 'SESSION_CANCELLED'),
      );
      await open(tester, repo);

      expect(find.textContaining('đã hủy nên chưa gửi được'), findsOneWidget);
      expect(
        find.textContaining(
          'quá hạn sửa 7 ngày nên thay đổi này không được nhận',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Bỏ thay đổi bị từ chối'));
      await tester.pumpAndSettle();
      expect(repo.discards, [sessionId]);
    },
  );

  testWidgets('AC-12: quá hạn sửa: chỉ xem, Lưu tắt, có giải thích', (
    tester,
  ) async {
    final repo = FakeAttendanceRepository(
      sheet: sheetOf([
        student(1, status: AttendanceStatus.late),
      ], editableUntil: DateTime.utc(2026, 11, 10)),
    );
    await open(tester, repo);

    expect(find.textContaining('quá 7 ngày'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(save()).onPressed, isNull);
    await tester.tap(find.text('Em 1'));
    await tester.pumpAndSettle();
    expect(find.text('Đi muộn'), findsOneWidget); // không đổi
    expect(find.text('Vắng có phép'), findsNothing);
  });

  testWidgets('AC-12: buổi đã hủy: chỉ xem kèm giải thích', (tester) async {
    await open(
      tester,
      FakeAttendanceRepository(sheet: sheetOf(roster(1), cancelled: true)),
    );
    expect(find.textContaining('đã hủy nên chỉ xem'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(save()).onPressed, isNull);
  });

  testWidgets('ngoại tuyến: vẫn điểm danh được từ cache, có nhãn ngoại tuyến', (
    tester,
  ) async {
    final repo = FakeAttendanceRepository(sheet: sheetOf(roster(2)))
      ..refreshError = const ApiException.network();
    await open(tester, repo);
    expect(find.textContaining('Đang ngoại tuyến'), findsOneWidget);
    await tester.tap(save());
    await tester.pumpAndSettle();
    expect(repo.saves, hasLength(1));
  });

  testWidgets('chưa có danh sách và lỗi: nút Thử lại gọi làm mới lại', (
    tester,
  ) async {
    final repo = FakeAttendanceRepository()
      ..refreshError = const ApiException.network();
    await open(tester, repo);
    expect(find.text('Không tải được danh sách học viên.'), findsOneWidget);
    final calls = repo.refreshSheetCalls;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(repo.refreshSheetCalls, calls + 1);
  });

  testWidgets('AC-13: nút nhật ký sửa mở màn nhật ký của buổi', (tester) async {
    await open(tester, FakeAttendanceRepository(sheet: sheetOf(roster(1))));
    await tester.tap(find.byTooltip('Nhật ký sửa'));
    await tester.pumpAndSettle();
    expect(find.text('history-page'), findsOneWidget);
  });

  testWidgets('ghi chú đồng bộ lại khi dữ liệu đổi và ô không đang focus', (
    tester,
  ) async {
    final repo = FakeAttendanceRepository(
      sheet: sheetOf([student(1, note: 'cũ')]),
    );
    await open(tester, repo);
    expect(find.text('cũ'), findsOneWidget);

    repo.setSheet(sheetOf([student(1, note: 'mới')]));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('mới'), findsOneWidget);
    expect(find.text('cũ'), findsNothing);
  });
}
