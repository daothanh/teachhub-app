import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:app/features/notification/pages/notification_page.dart';
import 'package:app/l10n/l10n.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

Widget _wrap(Widget child) {
  final router = GoRouter(
    initialLocation: '/notification',
    routes: [
      GoRoute(path: '/notification', builder: (context, state) => child),
      GoRoute(
        path: '/vue_mini_app',
        builder: (context, state) => const Scaffold(body: Text('Vue Mini App')),
      ),
    ],
  );

  return ScreenUtilPlusInit(
    designSize: const Size(393, 852),
    builder: (context, _) => MaterialApp.router(
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.v1,
      routerConfig: router,
    ),
  );
}

void main() {
  group('NotificationPage Widget Tests', () {
    void setViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('renders AppMainAppBar with title, filter tags, and items', (
      tester,
    ) async {
      setViewport(tester);

      await tester.pumpWidget(_wrap(const NotificationPage()));
      await tester.pumpAndSettle();

      expect(find.text('Thông báo'), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Hệ thống'), findsOneWidget);
      expect(find.text('Giao dịch'), findsOneWidget);
      expect(find.text('Mini Apps'), findsOneWidget);
      expect(find.text('Đã đọc tất cả'), findsOneWidget);

      expect(find.text('Chào mừng bạn đến với Tasco SuperApp'), findsOneWidget);
      expect(find.text('Trải nghiệm VueJS Mini App mới'), findsOneWidget);
    });

    testWidgets('filter tabs filter notifications correctly', (tester) async {
      setViewport(tester);

      await tester.pumpWidget(_wrap(const NotificationPage()));
      await tester.pumpAndSettle();

      // Tap 'Hệ thống' tab
      await tester.tap(find.text('Hệ thống'));
      await tester.pumpAndSettle();

      expect(find.text('Chào mừng bạn đến với Tasco SuperApp'), findsOneWidget);
      expect(find.text('Trải nghiệm VueJS Mini App mới'), findsNothing);

      // Scroll into view & tap 'Mini Apps' tab
      await tester.ensureVisible(find.text('Mini Apps'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mini Apps'));
      await tester.pumpAndSettle();

      expect(find.text('Trải nghiệm VueJS Mini App mới'), findsOneWidget);
      expect(find.text('Chào mừng bạn đến với Tasco SuperApp'), findsNothing);
    });

    testWidgets('tapping Đã đọc tất cả marks all items as read', (
      tester,
    ) async {
      setViewport(tester);

      await tester.pumpWidget(_wrap(const NotificationPage()));
      await tester.pumpAndSettle();

      expect(find.text('Đã đọc tất cả'), findsOneWidget);

      await tester.tap(find.text('Đã đọc tất cả'));
      await tester.pumpAndSettle();

      expect(find.text('Đã đọc tất cả'), findsNothing);
    });

    testWidgets('tapping mini app notification card navigates to mini app', (
      tester,
    ) async {
      setViewport(tester);

      await tester.pumpWidget(_wrap(const NotificationPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Trải nghiệm VueJS Mini App mới'));
      await tester.pumpAndSettle();

      expect(find.text('Vue Mini App'), findsOneWidget);
    });
  });
}
