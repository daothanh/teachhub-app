import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:teacher/features/attendance/attendance_routes.dart';
import 'package:teacher/features/attendance/data/attendance_models.dart';
import 'package:teacher/features/attendance/data/attendance_repository.dart';
import 'package:teacher/features/billing/billing_routes.dart';
import 'package:teacher/features/classes/classes_routes.dart';
import 'package:teacher/features/onboarding/data/onboarding_models.dart';
import 'package:teacher/features/onboarding/data/onboarding_repository.dart';
import 'package:teacher/features/schedule/schedule_routes.dart';
import 'package:teacher/features/today/pages/today_page.dart';
import 'package:teacher/teacher.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../support/fakes.dart';
import '../../support/pump_app.dart';
import '../attendance/fake_attendance_repository.dart';

const morning = TodaySession(
  id: 's-1',
  className: 'Toán 6A',
  startTime: '08:00',
  cancelled: false,
  attended: false,
);
const done = TodaySession(
  id: 's-2',
  className: 'Lý 7B',
  startTime: '14:00',
  cancelled: false,
  attended: true,
);
const cancelled = TodaySession(
  id: 's-3',
  className: 'Hóa 8C',
  startTime: '16:00',
  cancelled: true,
  attended: false,
);

const makeupSession = TodaySession(
  id: 's-4',
  className: 'Anh 9D',
  startTime: '18:00',
  cancelled: false,
  attended: false,
  isMakeup: true,
);
const cancelledWithReason = TodaySession(
  id: 's-5',
  className: 'Sử 8A',
  startTime: '19:00',
  cancelled: true,
  attended: false,
  cancelReason: 'Cô bận việc đột xuất',
);

GoRouter routerFor(
  FakeAttendanceRepository repo, {
  OnboardingRepository? onboarding,
  Stream<bool>? online,
  List<String>? visited,
}) => GoRouter(
  initialLocation: TeachHubRoutes.teacher,
  routes: [
    GoRoute(
      path: TeachHubRoutes.teacher,
      builder: (_, _) => TodayPage(
        repository: repo,
        onboardingRepository: onboarding,
        online: online,
      ),
    ),
    GoRoute(
      path: '${TeachHubRoutes.teacher}/sessions/:id/attendance',
      builder: (_, s) {
        visited?.add(s.uri.toString());
        return const Text('attendance-page');
      },
    ),
    GoRoute(
      path: '${TeachHubRoutes.teacher}/onboarding',
      builder: (_, s) {
        visited?.add(s.uri.toString());
        return const Text('onboarding-page');
      },
    ),
    GoRoute(
      path: ScheduleRoutes.schedule,
      builder: (_, _) => const Text('schedule-page'),
    ),
    GoRoute(
      path: ClassesRoutes.list,
      builder: (_, _) => const Text('classes-page'),
    ),
    GoRoute(
      path: BillingRoutes.periods,
      builder: (_, _) => const Text('billing-page'),
    ),
    GoRoute(
      path: TeachHubRoutes.rolePicker,
      builder: (_, _) => const Text('role-picker'),
    ),
  ],
);

void main() {
  tearDown(() => GetIt.I.reset());

  testWidgets('T03: buổi bù có nhãn, buổi hủy hiện lý do (chữ 200% không vỡ)', (
    tester,
  ) async {
    final repo = FakeAttendanceRepository(
      sessions: [makeupSession, cancelledWithReason],
    );
    await pumpRouter(tester, routerFor(repo), textScale: 2);
    expect(find.text('Buổi bù'), findsOneWidget);
    expect(find.text('Lý do: Cô bận việc đột xuất'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'AC-1: liệt kê buổi hôm nay: giờ, tên lớp, trạng thái, nút Điểm danh',
    (tester) async {
      final repo = FakeAttendanceRepository(
        sessions: [morning, done, cancelled],
      );
      await pumpRouter(tester, routerFor(repo));

      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('Toán 6A'), findsOneWidget);
      expect(find.text('Chưa điểm danh'), findsOneWidget);
      expect(find.text('Đã điểm danh'), findsOneWidget);
      expect(find.text('Đã hủy'), findsOneWidget);
      // Buổi đã hủy không có nút.
      expect(find.text('Điểm danh'), findsNWidgets(2));
      // Đúng thứ tự giờ từ trên xuống.
      expect(
        tester.getTopLeft(find.text('Toán 6A')).dy,
        lessThan(tester.getTopLeft(find.text('Lý 7B')).dy),
      );
    },
  );

  testWidgets('AC-1: nút Điểm danh mở T04 của đúng buổi', (tester) async {
    final visited = <String>[];
    final repo = FakeAttendanceRepository(sessions: [morning]);
    await pumpRouter(tester, routerFor(repo, visited: visited));

    await tester.tap(find.text('Điểm danh'));
    await tester.pumpAndSettle();
    expect(find.text('attendance-page'), findsOneWidget);
    expect(visited.single, AttendanceRoutes.sheet('s-1'));
  });

  testWidgets('AC-1: hôm nay không có buổi → trạng thái rỗng', (tester) async {
    await pumpRouter(tester, routerFor(FakeAttendanceRepository()));
    expect(find.text('Hôm nay không có buổi học'), findsOneWidget);
  });

  testWidgets('AC-2: mất mạng khi làm mới vẫn hiện buổi từ cache kèm banner', (
    tester,
  ) async {
    final repo = FakeAttendanceRepository(sessions: [morning])
      ..refreshError = const ApiException.network();
    await pumpRouter(tester, routerFor(repo));

    expect(find.text('Toán 6A'), findsOneWidget);
    expect(find.textContaining('Ngoại tuyến'), findsOneWidget);
    expect(find.textContaining('Kéo xuống để thử lại'), findsNothing);
  });

  testWidgets('AC-2: banner ngoại tuyến theo luồng mạng của máy', (
    tester,
  ) async {
    final online = StreamController<bool>();
    addTearDown(online.close);
    await pumpRouter(
      tester,
      routerFor(FakeAttendanceRepository(), online: online.stream),
    );
    expect(find.textContaining('Ngoại tuyến'), findsNothing);
    online.add(false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Ngoại tuyến'), findsOneWidget);
    online.add(true);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Ngoại tuyến'), findsNothing);
  });

  testWidgets('lỗi khác mạng khi làm mới: báo ngắn, vẫn hiện cache', (
    tester,
  ) async {
    final repo = FakeAttendanceRepository(sessions: [morning])
      ..refreshError = const ApiException.unexpected();
    await pumpRouter(tester, routerFor(repo));
    expect(find.textContaining('Kéo xuống để thử lại'), findsOneWidget);
    expect(find.text('Toán 6A'), findsOneWidget);
  });

  testWidgets('AC-3: thẻ nhắc chỉ hiện bước đã bỏ qua, bấm mở đúng bước', (
    tester,
  ) async {
    final visited = <String>[];
    final onboarding = FakeOnboardingRepository(
      onboardingOf({
        OnboardingStep.createClass: OnboardingStatus.done,
        OnboardingStep.addStudents: OnboardingStatus.skipped,
        OnboardingStep.setSchedule: OnboardingStatus.skipped,
      }),
    );
    await pumpRouter(
      tester,
      routerFor(
        FakeAttendanceRepository(),
        onboarding: onboarding,
        visited: visited,
      ),
    );

    expect(find.text('Bước làm quen bạn đã để sau'), findsOneWidget);
    expect(find.text('Thêm học viên'), findsOneWidget);
    expect(find.text('Đặt lịch học'), findsOneWidget);
    expect(find.text('Tạo lớp đầu tiên'), findsNothing); // đã xong

    await tester.tap(find.text('Đặt lịch học'));
    await tester.pumpAndSettle();
    expect(find.text('onboarding-page'), findsOneWidget);
    expect(
      visited.single,
      '${TeachHubRoutes.teacher}/onboarding?step=set_schedule',
    );
  });

  testWidgets('AC-3: không bước nào bị bỏ qua → không có thẻ', (tester) async {
    final onboarding = FakeOnboardingRepository(onboardingOf({}));
    await pumpRouter(
      tester,
      routerFor(FakeAttendanceRepository(), onboarding: onboarding),
    );
    expect(find.text('Bước làm quen bạn đã để sau'), findsNothing);
  });

  testWidgets(
    'AC-3: không tải được onboarding (ngoại tuyến) → không có thẻ, không lỗi',
    (tester) async {
      final onboarding = FakeOnboardingRepository(
        onboardingOf({}),
        getError: const ApiException.network(),
      );
      await pumpRouter(
        tester,
        routerFor(FakeAttendanceRepository(), onboarding: onboarding),
      );
      expect(find.text('Bước làm quen bạn đã để sau'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('T05: có lối vào Lịch ngay trên màn Hôm nay', (tester) async {
    await pumpRouter(tester, routerFor(FakeAttendanceRepository()));
    await tester.tap(find.text('Lịch'));
    await tester.pumpAndSettle();
    expect(find.text('schedule-page'), findsOneWidget);
  });

  testWidgets(
    'AC-4: có lối vào danh sách lớp và nút đổi vai trò khi chạy riêng',
    (tester) async {
      await pumpRouter(tester, routerFor(FakeAttendanceRepository()));
      await tester.tap(find.text('Lớp học'));
      await tester.pumpAndSettle();
      expect(find.text('classes-page'), findsOneWidget);
    },
  );

  testWidgets('S5-FL-05: có lối vào Học phí kỳ thu ngay trên màn Hôm nay', (
    tester,
  ) async {
    await pumpRouter(tester, routerFor(FakeAttendanceRepository()));
    await tester.ensureVisible(find.text('Học phí kỳ thu'));
    await tester.tap(find.text('Học phí kỳ thu'));
    await tester.pumpAndSettle();
    expect(find.text('billing-page'), findsOneWidget);
  });

  testWidgets('AC-4: đổi vai trò khi chạy riêng mini-app', (tester) async {
    await pumpRouter(tester, routerFor(FakeAttendanceRepository()));
    await tester.tap(find.text('Đổi vai trò'));
    await tester.pumpAndSettle();
    expect(find.text('role-picker'), findsOneWidget);
  });

  testWidgets('AC-4: route gốc của mini-app là màn Hôm nay', (tester) async {
    GetIt.I.registerSingleton<AttendanceRepository>(
      FakeAttendanceRepository(sessions: [morning]),
    );
    final router = GoRouter(
      initialLocation: TeachHubRoutes.teacher,
      routes: TeacherController.instance.routes(),
    );
    await pumpRouter(tester, router);
    expect(find.byType(TodayPage), findsOneWidget);
    expect(find.text('Toán 6A'), findsOneWidget);
  });

  testWidgets(
    'AC-5: chip Chờ đồng bộ theo watchPending, ẩn khi 0; vào màn thì startSync',
    (tester) async {
      final repo = FakeAttendanceRepository(sessions: [morning]);
      await pumpRouter(tester, routerFor(repo));
      expect(repo.startSyncCalls, 1);
      expect(find.textContaining('Chờ đồng bộ'), findsNothing);

      repo.setPending(3);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Chờ đồng bộ (3)'), findsOneWidget);

      repo.setPending(0);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('Chờ đồng bộ'), findsNothing);
    },
  );

  testWidgets('a11y: mỗi buổi có semantics label, chữ 130% không tràn', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final repo = FakeAttendanceRepository(sessions: [morning, done]);
    await pumpRouter(tester, routerFor(repo), textScale: 1.3);

    expect(tester.takeException(), isNull);
    expect(
      find.bySemanticsLabel(RegExp('Toán 6A, 08:00, Chưa điểm danh')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('Lý 7B, 14:00, Đã điểm danh')),
      findsOneWidget,
    );
    handle.dispose();
  });
}
