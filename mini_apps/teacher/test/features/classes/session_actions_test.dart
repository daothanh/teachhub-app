import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:teacher/features/attendance/attendance_routes.dart';
import 'package:teacher/features/classes/classes_routes.dart';
import 'package:teacher/features/classes/data/class_models.dart';
import 'package:teacher/features/classes/data/classes_repository.dart';
import 'package:teacher/features/classes/widgets/session_actions.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'fake_classes_repository.dart';
import 'pump.dart';

void main() {
  late FakeClassesRepository repo;
  setUp(() {
    repo = FakeClassesRepository()
      ..current = sampleClass()
      ..sessionItems = [
        sampleSession(id: 'p1', date: '2099-12-15'),
        sampleSession(
          id: 'c1',
          date: '2099-12-16',
          status: SessionStatus.cancelled,
          cancelReason: 'Cô bận',
        ),
        sampleSession(
          id: 'c2',
          date: '2099-12-17',
          status: SessionStatus.cancelled,
        ),
        sampleSession(
          id: 'm2',
          date: '2099-12-20',
          isMakeup: true,
          makeupOf: 'c2',
        ),
      ];
    GetIt.I.registerSingleton<ClassesRepository>(repo);
  });
  tearDown(GetIt.I.reset);

  Future<List<String>> open(WidgetTester tester, {double scale = 1}) async {
    final visited = <String>[];
    final router = await pumpRoutes(
      tester,
      [
        ...classesRoutes('teacher'),
        GoRoute(
          path: '${TeachHubRoutes.teacher}/sessions/:id/attendance',
          builder: (_, s) {
            visited.add(s.uri.toString());
            return const Text('attendance-page');
          },
        ),
      ],
      initial: ClassesRoutes.detail('c1'),
      textScale: scale,
    );
    addTearDown(router.dispose);
    return visited;
  }

  Future<void> scrollTo(WidgetTester tester, Finder f) => tester
      .scrollUntilVisible(f, 300, scrollable: find.byType(Scrollable).first);

  test(
    'sessionActionsFor: đổi/hủy cho buổi dự kiến, bù cho buổi hủy chưa có bù',
    () {
      final all = repo.sessionItems;
      expect(sessionActionsFor(all[0], all), [
        SessionAction.reschedule,
        SessionAction.cancel,
      ]);
      expect(sessionActionsFor(all[1], all), [SessionAction.makeup]);
      expect(sessionActionsFor(all[2], all), isEmpty); // đã có buổi bù m2
      expect(
        sessionActionsFor(sampleSession(status: SessionStatus.taught), all),
        isEmpty,
      );
    },
  );

  test('sessionStartsAt dùng offset của buổi gốc', () {
    expect(
      sessionStartsAt(
        DateTime(2099, 1, 2),
        const TimeOfDay(hour: 8, minute: 5),
        '2099-01-01T18:00:00+07:00',
      ),
      '2099-01-02T08:05:00+07:00',
    );
  });

  testWidgets('hiện lý do hủy; buổi hủy chưa có bù có nút Tạo buổi bù', (
    tester,
  ) async {
    await open(tester);
    await scrollTo(tester, find.textContaining('Lý do hủy: Cô bận'));
    expect(find.textContaining('Lý do hủy: Cô bận'), findsOneWidget);
    expect(find.text('Tạo buổi bù'), findsOneWidget);
  });

  testWidgets('hủy buổi kèm lý do: gọi API một lần, báo đã hủy', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Hủy buổi').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Cô ốm');
    await tester.tap(find.text('Hủy buổi').last);
    await tester.pumpAndSettle();

    expect(repo.calls.where((c) => c.startsWith('cancel')), [
      'cancel:p1:Cô ốm',
    ]);
    expect(find.text('Đã hủy buổi học.'), findsOneWidget);
  });

  testWidgets('hủy buổi đã có điểm danh: 409 hướng dẫn mở bảng điểm danh', (
    tester,
  ) async {
    repo.sessionActionError = apiError(ApiErrorCode.sessionHasAttendance);
    final visited = await open(tester);
    await tester.tap(find.text('Hủy buổi').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hủy buổi').last);
    await tester.pumpAndSettle();

    expect(find.text('Buổi đã có điểm danh'), findsOneWidget);
    await tester.tap(find.text('Mở điểm danh'));
    await tester.pumpAndSettle();
    expect(visited, [AttendanceRoutes.sheet('p1')]);
  });

  testWidgets('đổi giờ: giờ quá khứ bị chặn ở máy, không gọi API', (
    tester,
  ) async {
    repo.sessionItems = [sampleSession(id: 'p1', date: '2020-01-01')];
    await open(tester);
    await tester.tap(find.text('Đổi giờ').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đổi giờ').last);
    await tester.pumpAndSettle();
    expect(find.text('Giờ mới phải ở tương lai.'), findsOneWidget);
    expect(repo.calls.where((c) => c.startsWith('reschedule')), isEmpty);
  });

  testWidgets(
    'đổi giờ buổi đã hủy (409 SESSION_CANCELLED): báo lỗi, giữ hộp thoại',
    (tester) async {
      repo.sessionActionError = apiError(ApiErrorCode.sessionCancelled);
      await open(tester);
      await tester.tap(find.text('Đổi giờ').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đổi giờ').last);
      await tester.pumpAndSettle();
      expect(
        find.text('Buổi này đã hủy nên không đổi giờ được.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('lỗi mạng giữ Idempotency-Key khi thử lại', (tester) async {
    repo.sessionActionError = const ApiException.network();
    await open(tester);
    await tester.tap(find.text('Hủy buổi').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hủy buổi').last);
    await tester.pumpAndSettle();
    repo.sessionActionError = null;
    await tester.tap(find.text('Hủy buổi').last);
    await tester.pumpAndSettle();
    expect(repo.keys, hasLength(2));
    expect(repo.keys[0], isNotNull);
    expect(repo.keys[1], repo.keys[0]);
  });

  testWidgets('tạo buổi bù: gọi makeup với giờ tương lai', (tester) async {
    await open(tester);
    await scrollTo(tester, find.text('Tạo buổi bù'));
    await tester.tap(find.text('Tạo buổi bù'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạo buổi bù').last);
    await tester.pumpAndSettle();
    expect(repo.calls.where((c) => c.startsWith('makeup')), [
      'makeup:c1:2099-12-16T18:00:00+07:00',
    ]);
    expect(find.text('Đã tạo buổi bù.'), findsOneWidget);
  });

  testWidgets('chữ 200%: danh sách buổi và hộp thoại không vỡ bố cục', (
    tester,
  ) async {
    await open(tester, scale: 2);
    await tester.tap(find.text('Đổi giờ').first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
