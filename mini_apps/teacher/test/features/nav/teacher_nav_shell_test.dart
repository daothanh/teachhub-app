import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:teacher/features/more/more_page.dart';
import 'package:teacher/features/nav/teacher_nav_shell.dart';

import '../../support/pump_app.dart';

GoRouter _router(String initial) => GoRouter(
  initialLocation: initial,
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          TeacherNavShell(path: state.uri.path, child: child),
      routes: [
        for (final tab in teacherTabs)
          GoRoute(
            path: tab.path,
            builder: (_, _) => Scaffold(body: Text('page ${tab.path}')),
          ),
        GoRoute(
          path: '/t/classes/c1',
          builder: (_, _) => const Scaffold(body: Text('detail')),
        ),
      ],
    ),
  ],
);

bool _selected(WidgetTester tester, String label) =>
    tester
        .getSemantics(find.bySemanticsLabel(label))
        .flagsCollection
        .isSelected ==
    Tristate.isTrue;

void main() {
  testWidgets('màn gốc của tab có thanh 5 tab, tab hiện tại được chọn', (
    tester,
  ) async {
    await pumpRouter(tester, _router('/t'));
    for (final label in ['Hôm nay', 'Lịch', 'Lớp', 'Học phí', 'Thêm']) {
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }
    expect(_selected(tester, 'Hôm nay'), isTrue);
    expect(_selected(tester, 'Lớp'), isFalse);
  });

  testWidgets('bấm tab: chuyển màn và đổi tab được chọn', (tester) async {
    await pumpRouter(tester, _router('/t'));
    await tester.tap(find.bySemanticsLabel('Lớp'));
    await tester.pumpAndSettle();
    expect(find.text('page /t/classes'), findsOneWidget);
    expect(_selected(tester, 'Lớp'), isTrue);

    await tester.tap(find.bySemanticsLabel('Thêm'));
    await tester.pumpAndSettle();
    expect(find.text('page ${MoreRoutes.more}'), findsOneWidget);
  });

  testWidgets('màn con (chi tiết lớp) không có thanh', (tester) async {
    await pumpRouter(tester, _router('/t/classes/c1'));
    expect(find.text('detail'), findsOneWidget);
    expect(find.byType(TeacherBottomNav), findsNothing);
  });

  testWidgets('trang Thêm: các mục và ghi công icon Solar', (tester) async {
    await pumpRouter(
      tester,
      GoRouter(
        routes: [GoRoute(path: '/', builder: (_, _) => const MorePage())],
      ),
    );
    for (final label in [
      'Công nợ',
      'Báo cáo',
      'Gói Pro',
      'Tài khoản nhận tiền',
      'Cài đặt và tài khoản',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.textContaining('480 Design'), findsOneWidget);
  });
}
