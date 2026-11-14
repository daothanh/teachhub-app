import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:app/features/auth/auth_cubit.dart';
import 'package:app/features/home/home_dashboard_page.dart';
import 'package:tasco_module/tasco_module.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../helpers/auth_cubit_mock.dart';
import 'package:app/l10n/l10n.dart';

Widget _wrap(Widget child, {AppAuthCubit? authCubit}) {
  final cubit = authCubit ?? buildAuthCubit();
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => child),
      GoRoute(
        path: '/notification',
        builder: (context, state) =>
            const Scaffold(body: Text('Notification Page')),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const Scaffold(body: Text('Profile Page')),
      ),
      GoRoute(
        path: '/vue_mini_app',
        builder: (context, state) => const Scaffold(body: Text('Vue Mini App')),
      ),
    ],
  );

  return ScreenUtilPlusInit(
    designSize: const Size(393, 852),
    builder: (context, _) => BlocProvider<AppAuthCubit>.value(
      value: cubit,
      child: MaterialApp.router(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.v1,
        routerConfig: router,
      ),
    ),
  );
}

void main() {
  group('HomeDashboardPage Widget Tests', () {
    void setViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('renders header, quick actions and stat cards', (tester) async {
      setViewport(tester);

      await tester.pumpWidget(_wrap(const HomeDashboardPage()));
      await tester.pumpAndSettle();

      // Section headers
      expect(find.text('Truy cập nhanh'), findsOneWidget);
      expect(find.text('Tổng quan'), findsOneWidget);

      // Fallback menu item
      expect(find.text('Hồ sơ\nnhân sự'), findsOneWidget);

      // Stat overview cards
      expect(find.text('Đơn bảo hiểm'), findsOneWidget);
      expect(find.text('Chờ xử lý'), findsOneWidget);
      expect(find.text('Công việc hôm nay'), findsOneWidget);
      expect(find.text('Thông báo mới'), findsOneWidget);

      // Demo module card
      expect(find.text('Mini App VueJS'), findsOneWidget);
    });

    testWidgets('shows user name from AuthCubit state', (tester) async {
      setViewport(tester);
      final cubit = buildAuthCubit(name: 'Trần Thị Bích');

      await tester.pumpWidget(
        _wrap(const HomeDashboardPage(), authCubit: cubit),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trần Thị Bích'), findsOneWidget);
    });

    testWidgets('falls back to username when name is empty', (tester) async {
      setViewport(tester);
      final cubit = buildAuthCubit(name: '', username: 'tranthib');

      await tester.pumpWidget(
        _wrap(const HomeDashboardPage(), authCubit: cubit),
      );
      await tester.pumpAndSettle();

      expect(find.text('tranthib'), findsOneWidget);
    });

    testWidgets('tapping a menu card shows under-construction modal', (
      tester,
    ) async {
      setViewport(tester);

      await tester.pumpWidget(_wrap(const HomeDashboardPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hồ sơ\nnhân sự'));
      await tester.pumpAndSettle();

      expect(find.text('Tính năng đang phát triển'), findsOneWidget);

      await tester.tap(find.text('Đã hiểu'));
      await tester.pumpAndSettle();

      expect(find.text('Tính năng đang phát triển'), findsNothing);
    });

    testWidgets('tapping Demo Module Card navigates to vue_mini_app', (
      tester,
    ) async {
      setViewport(tester);

      await tester.pumpWidget(_wrap(const HomeDashboardPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mini App VueJS'));
      await tester.pumpAndSettle();

      expect(find.text('Vue Mini App'), findsOneWidget);
    });

    testWidgets('tapping notification bell navigates to /notification', (
      tester,
    ) async {
      setViewport(tester);

      await tester.pumpWidget(_wrap(const HomeDashboardPage()));
      await tester.pumpAndSettle();

      final notifBell = find
          .byWidgetPredicate(
            (w) => w is AppSvgIcon && w.assetPath == AppIcons.notification,
          )
          .first;
      await tester.tap(notifBell);
      await tester.pumpAndSettle();

      expect(find.text('Notification Page'), findsOneWidget);
    });

    testWidgets('tapping Công việc hôm nay stat opens under-construction', (
      tester,
    ) async {
      setViewport(tester);

      await tester.pumpWidget(_wrap(const HomeDashboardPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Công việc hôm nay'));
      await tester.pumpAndSettle();

      expect(find.text('Tính năng đang phát triển'), findsOneWidget);
      await tester.tap(find.text('Đã hiểu'));
      await tester.pumpAndSettle();
    });

    testWidgets('tapping Thông báo mới stat navigates to /notification', (
      tester,
    ) async {
      setViewport(tester);

      await tester.pumpWidget(_wrap(const HomeDashboardPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Thông báo mới'));
      await tester.pumpAndSettle();

      expect(find.text('Notification Page'), findsOneWidget);
    });

    testWidgets(
      'shows Tasco as fallback when both name and username are empty',
      (tester) async {
        setViewport(tester);
        final cubit = buildAuthCubit(name: '', username: '');

        await tester.pumpWidget(
          _wrap(const HomeDashboardPage(), authCubit: cubit),
        );
        await tester.pumpAndSettle();

        expect(find.text('Tasco'), findsOneWidget);
      },
    );

    testWidgets('shows Tasco as fallback when user is null', (tester) async {
      setViewport(tester);
      final cubit = buildUnauthCubit();

      await tester.pumpWidget(
        _wrap(const HomeDashboardPage(), authCubit: cubit),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tasco'), findsOneWidget);
    });

    testWidgets('tapping Đơn bảo hiểm stat opens under-construction', (
      tester,
    ) async {
      setViewport(tester);

      await tester.pumpWidget(_wrap(const HomeDashboardPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Đơn bảo hiểm'));
      await tester.pumpAndSettle();

      expect(find.text('Tính năng đang phát triển'), findsOneWidget);
      await tester.tap(find.text('Đã hiểu'));
      await tester.pumpAndSettle();
    });

    testWidgets('tapping Chờ xử lý stat opens under-construction', (
      tester,
    ) async {
      setViewport(tester);

      await tester.pumpWidget(_wrap(const HomeDashboardPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chờ xử lý'));
      await tester.pumpAndSettle();

      expect(find.text('Tính năng đang phát triển'), findsOneWidget);
      await tester.tap(find.text('Đã hiểu'));
      await tester.pumpAndSettle();
    });

    testWidgets(
      'renders dynamic slot from registered ModuleManager and navigates on tap',
      (tester) async {
        setViewport(tester);

        // Register a ModuleManager with one slot that declares presentation.
        final manager = ModuleManager()
          ..register(
            ModuleSlot(
              moduleId: 'test_module',
              routePrefix: '/test_module',
              notificationTypes: const {},
              init: () async {},
              routes: () => [],
              onNotification: (_, n) async {},
              dispose: () async {},
              presentation: const ModulePresentation(
                displayName: 'Test\nModule',
                iconName: 'orders',
              ),
            ),
          );
        GetIt.I.registerSingleton<ModuleManager>(manager);
        addTearDown(() => GetIt.I.unregister<ModuleManager>());

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (ctx, s) => BlocProvider<AppAuthCubit>.value(
                value: buildAuthCubit(),
                child: const HomeDashboardPage(),
              ),
            ),
            GoRoute(
              path: '/test_module',
              builder: (ctx, s) =>
                  const Scaffold(body: Text('Test Module Page')),
            ),
            GoRoute(
              path: '/notification',
              builder: (ctx, s) =>
                  const Scaffold(body: Text('Notification Page')),
            ),
            GoRoute(
              path: '/vue_mini_app',
              builder: (ctx, s) => const Scaffold(body: Text('Vue Mini App')),
            ),
          ],
        );

        await tester.pumpWidget(
          ScreenUtilPlusInit(
            designSize: const Size(393, 852),
            builder: (ctx, child) => MaterialApp.router(
              locale: const Locale('vi'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: AppTheme.v1,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Dynamic slot appears in grid.
        expect(find.text('Test\nModule'), findsOneWidget);

        // Tapping navigates to /test_module.
        await tester.tap(find.text('Test\nModule'));
        await tester.pumpAndSettle();
        expect(find.text('Test Module Page'), findsOneWidget);
      },
    );

    testWidgets('tapping avatar navigates to /profile', (tester) async {
      setViewport(tester);

      await tester.pumpWidget(_wrap(const HomeDashboardPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AppCircleAvatar));
      await tester.pumpAndSettle();

      expect(find.text('Profile Page'), findsOneWidget);
    });
  });
}
