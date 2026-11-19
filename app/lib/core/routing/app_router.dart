import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_core/tasco_core.dart';
import 'package:tasco_module/tasco_module.dart';
import 'package:tasco_utils/tasco_utils.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../features/app_version/update_required_page.dart';
import '../../features/center_waitlist/center_waitlist_page.dart';
import '../../features/center_waitlist/center_waitlist_cubit.dart';
import '../../features/auth/auth_cubit.dart';
import '../../features/consent/consent_cubit.dart';
import '../../features/consent/consent_page.dart';
import '../../features/invite/invite_cubit.dart';
import '../../features/invite/invite_entry_view.dart';
import '../../features/invite/invite_page.dart';
import '../../features/invite/invite_scan_page.dart';
import '../../features/role_picker/membership_cubit.dart';
import '../../features/role_picker/role_picker_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/splash/splash_page.dart';
import 'app_routes.dart';

/// Quyền vai trò cần cho route gốc của từng mini-app (spec §8.7).
final Map<String, Set<String>> roleRoutePermissions = {
  for (final role in MembershipRole.values) role.rootRoute: {role.permission},
};

/// Router của shell: route host + route mini-app (`collectRoutes`).
///
/// Thứ tự kiểm tra (spec §8.7): phiên bản tối thiểu → kiểm phiên → đăng nhập (mặc định mọi route
/// cần đăng nhập) → tải vai trò → chưa có vai trò thì chọn vai trò →
/// đã đồng ý xử lý dữ liệu (`/p/**`, vai trò Phụ huynh) →
/// `PermissionGuard` theo vai trò cho `/t`, `/p`, `/s`.
GoRouter buildAppRouter({
  required ModuleManager moduleManager,
  required AppAuthCubit authCubit,
  required MembershipCubit membershipCubit,
  required ConsentCubit consentCubit,
  required Widget Function() loginPage,
  required InviteCubit Function(String token) inviteCubit,
  ValueListenable<bool>? updateRequired,
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  final authGuard = AuthGuard(
    const AuthPolicy().withAlwaysPublic(
      moduleManager.collectPublicRoutePrefixes(),
    ),
    loginPath: AppRoutes.login,
  );
  final permissionGuard = PermissionGuard(
    permissions: () => membershipCubit.state.permissions,
    routePermissions: roleRoutePermissions,
    deniedPath: AppRoutes.rolePicker,
  );

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: Listenable.merge([
      GoRouterRefreshStream(authCubit.stream),
      GoRouterRefreshStream(membershipCubit.stream),
      GoRouterRefreshStream(consentCubit.stream),
      ?updateRequired,
    ]),
    onException: (_, _, router) => router.go(AppRoutes.splash),
    redirect: (context, state) => resolveRedirect(
      location: state.matchedLocation,
      auth: authCubit.state,
      memberships: membershipCubit.state,
      consent: consentCubit.state,
      authGuard: authGuard,
      permissionGuard: permissionGuard,
      updateRequired: updateRequired?.value ?? false,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.updateRequired,
        builder: (_, _) => const UpdateRequiredPage(),
      ),
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => loginPage()),
      GoRoute(
        path: AppRoutes.rolePicker,
        builder: (_, _) => const RolePickerPage(),
      ),
      GoRoute(
        path: AppRoutes.centerWaitlist,
        builder: (_, _) => BlocProvider(
          create: (_) => GetIt.I<CenterWaitlistCubit>(),
          child: const CenterWaitlistPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.consent,
        builder: (_, _) =>
            BlocProvider.value(value: consentCubit, child: const ConsentPage()),
      ),
      GoRoute(
        path: AppRoutes.inviteEntry,
        builder: (_, _) => const InviteEntryPage(),
      ),
      // Phải đứng trước `invitePattern`, nếu không `scan` bị hiểu là token.
      GoRoute(
        path: AppRoutes.inviteScan,
        builder: (_, _) => const InviteScanPage(),
      ),
      GoRoute(
        path: AppRoutes.invitePattern,
        builder: (_, state) => BlocProvider(
          create: (_) => inviteCubit(state.pathParameters['token']!),
          child: const InvitePage(),
        ),
      ),
      ...moduleManager.collectRoutes(),
    ],
  );
}

/// Quyết định redirect, tách khỏi GoRouter để test được.
@visibleForTesting
String? resolveRedirect({
  required String location,
  required AppAuthState auth,
  required MembershipState memberships,
  required ConsentState consent,
  required RouteGuard authGuard,
  required RouteGuard permissionGuard,
  bool updateRequired = false,
}) {
  // Bản quá cũ: chặn mọi màn, kể cả khi chưa đăng nhập (spec §5.1).
  final atUpdate = location == AppRoutes.updateRequired;
  if (updateRequired) return atUpdate ? null : AppRoutes.updateRequired;
  if (atUpdate) return AppRoutes.splash;

  final atSplash = location == AppRoutes.splash;
  final atLogin = location == AppRoutes.login;

  final checkingSession =
      auth.statusCheckToken == LoadingStatus.initial ||
      auth.statusCheckToken == LoadingStatus.loading;
  if (checkingSession) return atSplash ? null : AppRoutes.splash;

  if (!auth.isAuthenticated) {
    if (atLogin) return null;
    if (atSplash) return AppRoutes.login;
    return authGuard.evaluate(
      GuardContext(location: location, isAuthenticated: false),
    );
  }

  // Đã đăng nhập: chờ danh sách vai trò ở splash (splash hiện nút thử lại).
  if (memberships.statusLoad != LoadingStatus.success) {
    return atSplash ? null : AppRoutes.splash;
  }

  if (atSplash || atLogin) {
    final pending = PendingDeepLink.consume();
    if (pending != null) return pending.path;
    return memberships.active?.role.rootRoute ?? AppRoutes.rolePicker;
  }

  // Phụ huynh chưa đồng ý điều khoản hiện hành thì không vào trang của con
  // (US-0.3 AC2). Trạng thái chưa biết cũng về màn đồng ý: màn đó tự tải.
  final inParentSpace =
      location == TeachHubRoutes.parent ||
      location.startsWith('${TeachHubRoutes.parent}/');
  if (inParentSpace &&
      memberships.permissions.contains(MembershipRole.parent.permission) &&
      !consent.accepted) {
    return AppRoutes.consent;
  }

  final denied = permissionGuard.evaluate(
    GuardContext(location: location, isAuthenticated: true),
  );
  return denied == location ? null : denied;
}
