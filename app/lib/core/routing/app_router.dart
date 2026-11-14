import 'package:flutter/widgets.dart';
import 'package:tasco_core/tasco_core.dart';
import 'package:tasco_utils/tasco_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_module/tasco_module.dart';

import '../../features/auth/auth_cubit.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/main_shell/main_shell_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/splash/splash_page.dart';
import 'app_routes.dart';

GoRouter buildAppRouter({
  required ModuleManager moduleManager,
  required AppAuthCubit authCubit,
  // Sign-in body builder for the login route; composed in bootstrap.
  required LoginCredentials loginCredentials,
  GlobalKey<NavigatorState>? navigatorKey,
  // Policy do từng app cấu hình. Mặc định framework: khoá hết (auth-by-default).
  AuthPolicy authPolicy = const AuthPolicy(),
  // Điểm mở rộng cho permission/role guard sau này (P1-7).
  List<RouteGuard> extraGuards = const [],
}) {
  // Mini-app tự khai báo route public → merge vào policy của app.
  final effectivePolicy = authPolicy.withAlwaysPublic(
    moduleManager.collectPublicRoutePrefixes(),
  );

  final guards = <RouteGuard>[
    AuthGuard(effectivePolicy, loginPath: AppRoutes.login),
    ...extraGuards,
  ];

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.splash,
    // Mỗi lần AuthCubit đổi state → đánh giá lại redirect (guard).
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    // Fallback: route không tồn tại → về home, không crash.
    onException: (_, state, router) => router.go(AppRoutes.home),
    redirect: (context, state) {
      final authState = authCubit.state;
      final location = state.matchedLocation;
      final atLogin = location == AppRoutes.login;
      final atSplash = location == AppRoutes.splash;

      // Đang kiểm tra phiên (mở app) → giữ ở splash cho tới khi xong.
      final checking =
          authState.statusCheckToken == LoadingStatus.initial ||
          authState.statusCheckToken == LoadingStatus.loading;
      if (checking) {
        return atSplash ? null : AppRoutes.splash;
      }

      // Kiểm tra phiên xong → rời splash về landing mặc định.
      if (atSplash) {
        // Peek trước, chỉ consume khi thật sự điều hướng. Trước đây chỗ này
        // `consume()` rồi mới xét `isAuthenticated`, mà `consume()` xoá store
        // ngay khi đọc — nên cold-start từ deep-link lúc chưa đăng nhập bị
        // rỗng store ở đây, và nhánh `loggedIn && atLogin` bên dưới nhận null
        // sau khi user đăng nhập xong: mất màn hình đích.
        if (authState.isAuthenticated && PendingDeepLink.current != null) {
          return PendingDeepLink.consume()!.path;
        }
        return AppRoutes.home;
      }

      final loggedIn = authState.isAuthenticated;

      // Đã đăng nhập mà còn ở login → resume pending deep-link hoặc về home.
      if (loggedIn && atLogin) {
        final pending = PendingDeepLink.consume();
        return pending?.path ?? AppRoutes.home;
      }

      // Trang login luôn cho qua khi chưa đăng nhập.
      if (atLogin) {
        return null;
      }

      // Chạy pipeline guard (auth + sau này RBAC).
      final guardContext = GuardContext(
        location: location,
        isAuthenticated: loggedIn,
      );
      for (final guard in guards) {
        final redirect = guard.evaluate(guardContext);
        if (redirect != null && redirect != location) {
          return redirect;
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => LoginPage(credentials: loginCredentials),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const MainShellPage(initialTab: 0),
      ),
      GoRoute(
        path: AppRoutes.explore,
        builder: (context, state) => const MainShellPage(initialTab: 1),
      ),
      GoRoute(
        path: AppRoutes.notification,
        builder: (context, state) => const MainShellPage(initialTab: 2),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const MainShellPage(initialTab: 3),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      ...moduleManager.collectRoutes(),
    ],
  );
}
