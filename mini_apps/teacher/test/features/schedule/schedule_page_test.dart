import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:teacher/features/classes/data/class_models.dart'
    show SessionStatus;
import 'package:teacher/features/schedule/pages/schedule_page.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teacher/l10n/l10n.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../support/pump_app.dart';
import 'fake_schedule_repository.dart';

// Thứ Tư 18/11/2026.
DateTime now() => DateTime(2026, 11, 18, 9);

GoRouter routerFor(
  FakeScheduleRepository repo, {
  Stream<bool>? online,
  List<String>? visited,
}) => GoRouter(
  initialLocation: '/schedule',
  routes: [
    GoRoute(
      path: '/schedule',
      builder: (_, _) =>
          SchedulePage(repository: repo, online: online, now: now),
    ),
    GoRoute(
      path: '${TeachHubRoutes.teacher}/sessions/:id/attendance',
      builder: (_, s) {
        visited?.add(s.uri.toString());
        return const Text('attendance-page');
      },
    ),
  ],
);

void main() {
  testWidgets('AC-1/2: ngày: giờ, tên lớp, trạng thái, sắp theo giờ', (
    tester,
  ) async {
    final repo = FakeScheduleRepository([
      sess('a', '2026-11-18', '08:00'),
      sess(
        'b',
        '2026-11-18',
        '14:00',
        className: 'Lý 7B',
        status: SessionStatus.taught,
      ),
    ]);
    await pumpRouter(tester, routerFor(repo));
    expect(find.text('Thứ Tư, 18/11/2026'), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('Toán 6A'), findsOneWidget);
    expect(find.text('Dự kiến'), findsOneWidget);
    expect(find.text('Đã dạy'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Toán 6A')).dy,
      lessThan(tester.getTopLeft(find.text('Lý 7B')).dy),
    );
  });

  testWidgets(
    'AC-1: chuyển sang Tuần: gom theo ngày, bắt đầu Thứ Hai; gọi lại theo khoảng',
    (tester) async {
      final repo = FakeScheduleRepository([
        sess('a', '2026-11-16', '08:00'),
        sess('b', '2026-11-19', '09:00', className: 'Lý 7B'),
      ]);
      await pumpRouter(tester, routerFor(repo));
      await tester.tap(find.text('Tuần'));
      await tester.pumpAndSettle();
      expect(find.text('16/11 – 22/11/2026'), findsOneWidget);
      expect(find.text('Thứ Hai, 16/11'), findsOneWidget);
      expect(find.text('Thứ Năm, 19/11'), findsOneWidget);
      expect(repo.refreshed.last, ('2026-11-16', '2026-11-22'));

      await tester.tap(find.byTooltip('Sau'));
      await tester.pumpAndSettle();
      expect(repo.refreshed.last, ('2026-11-23', '2026-11-29'));
      expect(find.text('Toán 6A'), findsNothing);

      await tester.tap(find.text('Ngày'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hôm nay'));
      await tester.pumpAndSettle();
      expect(repo.refreshed.last, ('2026-11-18', '2026-11-18'));
    },
  );

  testWidgets('AC-3: buổi hủy có nhãn chữ, gạch, lý do; buổi bù có nhãn', (
    tester,
  ) async {
    final repo = FakeScheduleRepository([
      sess(
        'a',
        '2026-11-18',
        '08:00',
        status: SessionStatus.cancelled,
        reason: 'Nghỉ lễ',
      ),
      sess('b', '2026-11-18', '10:00', className: 'Lý 7B', makeup: true),
    ]);
    await pumpRouter(tester, routerFor(repo));
    expect(find.text('Đã hủy'), findsOneWidget);
    expect(find.text('Lý do: Nghỉ lễ'), findsOneWidget);
    expect(find.text('Buổi bù'), findsOneWidget);
    final struck = tester.widget<Text>(find.text('Toán 6A'));
    expect(struck.style?.decoration, TextDecoration.lineThrough);
    final plain = tester.widget<Text>(find.text('Lý 7B'));
    expect(plain.style?.decoration, isNot(TextDecoration.lineThrough));
  });

  testWidgets('AC-3: buổi hủy không có lý do thì không hiện dòng lý do', (
    tester,
  ) async {
    final repo = FakeScheduleRepository([
      sess('a', '2026-11-18', '08:00', status: SessionStatus.cancelled),
    ]);
    await pumpRouter(tester, routerFor(repo));
    expect(find.text('Đã hủy'), findsOneWidget);
    expect(find.textContaining('Lý do'), findsNothing);
  });

  testWidgets('AC-4: mất mạng: hiện buổi đã lưu kèm banner ngoại tuyến', (
    tester,
  ) async {
    final repo = FakeScheduleRepository([sess('a', '2026-11-18', '08:00')])
      ..refreshError = const ApiException.network();
    await pumpRouter(tester, routerFor(repo));
    expect(find.text('Toán 6A'), findsOneWidget);
    expect(find.textContaining('ngoại tuyến'), findsOneWidget);
  });

  testWidgets('AC-4: kéo xuống làm mới', (tester) async {
    final repo = FakeScheduleRepository([sess('a', '2026-11-18', '08:00')]);
    await pumpRouter(tester, routerFor(repo));
    expect(repo.refreshed, hasLength(1));
    await tester.fling(find.text('Toán 6A'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(repo.refreshed, hasLength(2));
  });

  testWidgets('AC-5: chạm buổi chưa hủy mở điểm danh; buổi hủy thì không', (
    tester,
  ) async {
    final visited = <String>[];
    final repo = FakeScheduleRepository([
      sess(
        'c',
        '2026-11-18',
        '07:00',
        className: 'Hóa 8C',
        status: SessionStatus.cancelled,
      ),
      sess('a', '2026-11-18', '08:00'),
    ]);
    await pumpRouter(tester, routerFor(repo, visited: visited));
    await tester.tap(find.text('Hóa 8C'));
    await tester.pumpAndSettle();
    expect(visited, isEmpty);
    await tester.tap(find.text('Toán 6A'));
    await tester.pumpAndSettle();
    expect(visited, ['/t/sessions/a/attendance']);
    expect(find.text('attendance-page'), findsOneWidget);
  });

  testWidgets('AC-6: rỗng có nút Thử lại gọi lại API', (tester) async {
    final repo = FakeScheduleRepository();
    await pumpRouter(tester, routerFor(repo));
    expect(find.text('Không có buổi nào trong khoảng này'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(repo.refreshed, hasLength(2));
  });

  testWidgets(
    'AC-6: lỗi có thông báo và nút Thử lại; thử lại được thì hết lỗi',
    (tester) async {
      final repo = FakeScheduleRepository()
        ..refreshError = const ApiException.unexpected();
      await pumpRouter(tester, routerFor(repo));
      expect(find.text('Chưa tải được lịch.'), findsOneWidget);
      expect(find.text('Không có buổi nào trong khoảng này'), findsNothing);
      repo.refreshError = null;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa tải được lịch.'), findsNothing);
      expect(find.text('Không có buổi nào trong khoảng này'), findsOneWidget);
    },
  );

  testWidgets('AC-6: đang tải hiện vòng quay, chưa hiện rỗng', (tester) async {
    final gate = Completer<void>();
    final repo = FakeScheduleRepository()..gates.add(gate);
    // Không pumpAndSettle: vòng quay chạy mãi.
    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('vi'),
        localizationsDelegates: const [
          ...MiniAppLocalizations.localizationsDelegates,
          TascoUiKitLocalizations.delegate,
        ],
        supportedLocales: MiniAppLocalizations.supportedLocales,
        theme: AppTheme.v1,
        routerConfig: routerFor(repo),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Không có buổi nào trong khoảng này'), findsNothing);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Semantics: một nhãn cho thẻ; chưa hủy là nút, hủy thì không', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final repo = FakeScheduleRepository([
      sess(
        'c',
        '2026-11-18',
        '07:00',
        className: 'Hóa 8C',
        status: SessionStatus.cancelled,
        reason: 'Nghỉ lễ',
      ),
      sess('a', '2026-11-18', '08:00', makeup: true),
    ]);
    await pumpRouter(tester, routerFor(repo));
    final cancelled = tester.getSemantics(find.text('Hóa 8C'));
    expect(cancelled.label, contains('Đã hủy'));
    expect(cancelled.label, contains('Lý do: Nghỉ lễ'));
    expect(cancelled.flagsCollection.isButton, isFalse);
    final makeup = tester.getSemantics(find.text('Toán 6A'));
    expect(makeup.label, contains('Buổi bù'));
    expect(makeup.flagsCollection.isButton, isTrue);
    handle.dispose();
  });

  testWidgets('chữ phóng to 2.0: thanh công cụ không tràn', (tester) async {
    final repo = FakeScheduleRepository([sess('a', '2026-11-18', '08:00')]);
    await pumpRouter(tester, routerFor(repo), textScale: 2);
    await tester.tap(find.text('Tuần'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
