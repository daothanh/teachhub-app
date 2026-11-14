import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/routing/app_router.dart';
import 'package:app/core/routing/app_routes.dart';
import 'package:app/data/model/user_model.dart';
import 'package:app/features/auth/auth_cubit.dart';
import 'package:app/l10n/l10n.dart';
import 'package:tasco_core/tasco_core.dart';
import 'package:tasco_module/tasco_module.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:tasco_utils/tasco_utils.dart';

import '../../helpers/auth_cubit_mock.dart';

/// Session check finished, nobody logged in — the state the splash redirect
/// runs in when a deep link arrives on a cold start.
MockAppAuthCubit _checkedOutCubit() => MockAppAuthCubit(
  const AppAuthState(statusCheckToken: LoadingStatus.success),
);

MockAppAuthCubit _authedCubit() => MockAppAuthCubit(
  const AppAuthState(
    user: UserModel(id: '1', name: 'Test'),
    statusCheckToken: LoadingStatus.success,
  ),
);

/// Mounts the real router. `redirect` only runs once the `Router` widget is
/// attached — building a `GoRouter` and calling `go` on it evaluates nothing,
/// so a test that skips this passes against the very bug it exists to catch.
Future<GoRouter> _mount(WidgetTester tester, AppAuthCubit cubit) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = buildAppRouter(
    moduleManager: ModuleManager(),
    authCubit: cubit,
    loginCredentials: ({required username, required password}) => const {},
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    BlocProvider<AppAuthCubit>.value(
      value: cubit,
      child: ScreenUtilPlusInit(
        designSize: const Size(393, 852),
        builder: (context, _) => MaterialApp.router(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.v1,
          routerConfig: router,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

String _location(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.toString();

void main() {
  setUp(PendingDeepLink.clear);
  tearDown(PendingDeepLink.clear);

  group('pending deep link', () {
    testWidgets('survives the splash pass when nobody is logged in', (
      tester,
    ) async {
      // The regression: the splash branch consumed the link before testing
      // `isAuthenticated`, so it was already gone by the time the user finished
      // logging in, and the target screen was lost.
      PendingDeepLink.save(const DeepLinkTarget(path: AppRoutes.notification));

      final router = await _mount(tester, _checkedOutCubit());

      expect(_location(router), AppRoutes.login);
      expect(
        PendingDeepLink.current?.path,
        AppRoutes.notification,
        reason: 'an unauthenticated splash pass must not drain the link',
      );
    });

    testWidgets('is followed and cleared once the user is authenticated', (
      tester,
    ) async {
      PendingDeepLink.save(const DeepLinkTarget(path: AppRoutes.notification));

      final router = await _mount(tester, _authedCubit());

      expect(_location(router), AppRoutes.notification);
      expect(
        PendingDeepLink.current,
        isNull,
        reason: 'following the link must clear it, or it fires again',
      );
    });

    testWidgets('lands on home when nothing is pending', (tester) async {
      final router = await _mount(tester, _authedCubit());

      expect(_location(router), AppRoutes.home);
    });
  });
}
