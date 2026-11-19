import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:teacher/features/classes/classes_routes.dart';
import 'package:teacher/features/classes/data/class_models.dart';
import 'package:teacher/features/classes/data/classes_repository.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'fake_classes_repository.dart';
import 'pump.dart';

void main() {
  late FakeClassesRepository repo;
  setUp(() {
    repo = FakeClassesRepository()
      ..current = sampleClass(
        enrolled: 1,
        rules: const [
          ScheduleRule(
            weekday: 2,
            startTime: '18:00',
            durationMin: 90,
            id: 'r1',
          ),
          ScheduleRule(
            weekday: 4,
            startTime: '18:00',
            durationMin: 90,
            id: 'r2',
          ),
        ],
      )
      ..rosterItems = const [
        RosterEntry(
          enrollmentId: 'e1',
          studentId: 's1',
          fullName: 'Nguyễn Văn An',
          studentStatus: 'active',
          joinedOn: '2026-12-14',
        ),
      ]
      ..sessionItems = [
        ClassSession(
          id: 'x1',
          classId: 'c1',
          className: 'Toán 9A',
          sessionDate: '2026-12-15',
          startsAt: DateTime.utc(2026, 12, 15, 11),
          endsAt: DateTime.utc(2026, 12, 15, 12, 30),
          status: SessionStatus.planned,
          isMakeup: false,
        ),
      ];
    GetIt.I.registerSingleton<ClassesRepository>(repo);
  });
  tearDown(GetIt.I.reset);

  Future<void> open(WidgetTester tester) async {
    final router = await pumpRoutes(
      tester,
      classesRoutes('teacher'),
      initial: ClassesRoutes.detail('c1'),
    );
    addTearDown(router.dispose);
  }

  testWidgets('hiện thông tin, quy tắc lặp, buổi dự kiến và học viên', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Toán 9A'), findsWidgets);
    expect(find.text('Thứ Ba · 18:00 · 90 phút'), findsOneWidget);
    expect(find.text('Thứ Năm · 18:00 · 90 phút'), findsOneWidget);
    expect(find.text('Dự kiến'), findsOneWidget);
    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    // Cửa sổ buổi học đúng 62 ngày, theo lớp này.
    final r = repo.lastSessionRange!;
    expect(r.classId, 'c1');
    final days = DateTime.parse(r.to).difference(DateTime.parse(r.from)).inDays;
    expect(days, 61);
  });

  testWidgets('lưu trữ lớp: xác nhận rồi hiện lớp đã lưu trữ', (tester) async {
    await open(tester);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu trữ lớp'));
    await tester.pumpAndSettle();
    expect(find.text('Lưu trữ lớp này?'), findsOneWidget);
    await tester.tap(find.text('Lưu trữ lớp').last);
    await tester.pumpAndSettle();

    expect(repo.calls, contains('archive:c1'));
    expect(find.text('Lớp đã lưu trữ.'), findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
    expect(find.text('Thêm học viên'), findsNothing);
  });

  testWidgets('lưu trữ gặp 409: báo dữ liệu đã đổi, lớp giữ nguyên', (
    tester,
  ) async {
    repo.archiveError = apiError(ApiErrorCode.conflictStale);
    await open(tester);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu trữ lớp'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu trữ lớp').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Dữ liệu vừa thay đổi'), findsOneWidget);
    expect(find.text('Lớp đã lưu trữ.'), findsNothing);
  });

  testWidgets('lớp không tồn tại (404): báo lỗi, thử lại', (tester) async {
    repo.getError = apiError(ApiErrorCode.notFound);
    await open(tester);
    expect(find.text('Không tìm thấy lớp này.'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('tải buổi lỗi: vẫn xem được lớp và học viên', (tester) async {
    repo.sessionsError = const ApiException.network();
    await open(tester);
    expect(find.text('Không tải được danh sách buổi.'), findsOneWidget);
    expect(find.text('Nguyễn Văn An'), findsOneWidget);
  });
}
