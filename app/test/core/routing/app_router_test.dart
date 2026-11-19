import 'package:app/core/routing/app_router.dart';
import 'package:app/core/routing/app_routes.dart';
import 'package:app/features/auth/auth_cubit.dart';
import 'package:app/features/auth/teachhub_user.dart';
import 'package:app/features/role_picker/membership_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasco_core/tasco_core.dart';
import 'package:tasco_utils/tasco_utils.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

const _user = TeachHubUser(id: 'u1', email: 'a@b.vn');
const _teacher = Membership(
  id: 'm1',
  role: MembershipRole.tenantOwner,
  label: '',
);
const _parent = Membership(id: 'm2', role: MembershipRole.parent, label: '');

AppAuthState _auth({required LoadingStatus check, bool signedIn = false}) =>
    AppAuthState.initial().copyWith(
      statusCheckToken: check,
      user: signedIn ? _user : null,
    );

final _signedIn = _auth(check: LoadingStatus.success, signedIn: true);
final _signedOut = _auth(check: LoadingStatus.failure);

MembershipState _loaded(List<Membership> items, {Membership? active}) =>
    MembershipState(
      statusLoad: LoadingStatus.success,
      memberships: items,
      active: active,
    );

String? _redirect(String location, AppAuthState auth, MembershipState m) =>
    resolveRedirect(
      location: location,
      auth: auth,
      memberships: m,
      authGuard: AuthGuard(const AuthPolicy(), loginPath: AppRoutes.login),
      permissionGuard: PermissionGuard(
        permissions: () => m.permissions,
        routePermissions: roleRoutePermissions,
        deniedPath: AppRoutes.rolePicker,
      ),
    );

void main() {
  tearDown(PendingDeepLink.clear);

  test('stays on splash while the session is being checked', () {
    final checking = _auth(check: LoadingStatus.loading);
    expect(
      _redirect(AppRoutes.splash, checking, const MembershipState()),
      isNull,
    );
    expect(
      _redirect('/t', checking, const MembershipState()),
      AppRoutes.splash,
    );
  });

  test('signed out: every route except login needs sign-in', () {
    const none = MembershipState();
    expect(_redirect(AppRoutes.splash, _signedOut, none), AppRoutes.login);
    expect(_redirect(AppRoutes.login, _signedOut, none), isNull);
    for (final route in [
      '/t',
      '/p',
      AppRoutes.rolePicker,
      AppRoutes.settings,
    ]) {
      expect(
        _redirect(route, _signedOut, none),
        AppRoutes.login,
        reason: route,
      );
    }
  });

  test('signed in: waits on splash until roles are loaded', () {
    const loading = MembershipState(statusLoad: LoadingStatus.loading);
    expect(_redirect(AppRoutes.login, _signedIn, loading), AppRoutes.splash);
    expect(_redirect(AppRoutes.splash, _signedIn, loading), isNull);
    const failed = MembershipState(statusLoad: LoadingStatus.failure);
    expect(_redirect(AppRoutes.splash, _signedIn, failed), isNull);
  });

  test('after roles load: active role root, else the role picker', () {
    expect(
      _redirect(
        AppRoutes.splash,
        _signedIn,
        _loaded([_teacher], active: _teacher),
      ),
      '/t',
    );
    expect(
      _redirect(AppRoutes.login, _signedIn, _loaded([_teacher, _parent])),
      AppRoutes.rolePicker,
    );
    expect(
      _redirect(AppRoutes.splash, _signedIn, _loaded([])),
      AppRoutes.rolePicker,
    );
  });

  test('a pending deep link wins after sign-in', () {
    PendingDeepLink.save(const DeepLinkTarget(path: '/invite/abc'));
    expect(
      _redirect(
        AppRoutes.splash,
        _signedIn,
        _loaded([_parent], active: _parent),
      ),
      '/invite/abc',
    );
  });

  test('a role space needs that role', () {
    final parentOnly = _loaded([_parent], active: _parent);
    expect(_redirect('/p', _signedIn, parentOnly), isNull);
    expect(_redirect('/t', _signedIn, parentOnly), AppRoutes.rolePicker);
    expect(_redirect('/t/today', _signedIn, parentOnly), AppRoutes.rolePicker);
    expect(_redirect(AppRoutes.rolePicker, _signedIn, parentOnly), isNull);
  });

  test(
    'bản quá cũ: mọi route chuyển sang Cần cập nhật, kể cả khi chưa đăng nhập',
    () {
      String? r(String location, {required bool required}) => resolveRedirect(
        location: location,
        auth: _signedOut,
        memberships: const MembershipState(),
        authGuard: AuthGuard(const AuthPolicy(), loginPath: AppRoutes.login),
        permissionGuard: PermissionGuard(
          permissions: () => const {},
          routePermissions: roleRoutePermissions,
          deniedPath: AppRoutes.rolePicker,
        ),
        updateRequired: required,
      );
      expect(r(AppRoutes.login, required: true), AppRoutes.updateRequired);
      expect(r(AppRoutes.updateRequired, required: true), isNull);
      // Hết bắt buộc (vd. server hạ mức) → rời màn cập nhật.
      expect(r(AppRoutes.updateRequired, required: false), AppRoutes.splash);
    },
  );

  test('/center-waitlist: đã đăng nhập, chưa có vai trò vẫn vào được', () {
    expect(
      _redirect(AppRoutes.centerWaitlist, _signedIn, _loaded(const [])),
      isNull,
    );
    expect(
      _redirect(AppRoutes.centerWaitlist, _signedOut, const MembershipState()),
      AppRoutes.login,
    );
  });

  test('/t/onboarding và /t/students/new cần quyền Giáo viên', () {
    final parentOnly = _loaded(const [_parent], active: _parent);
    for (final route in ['/t/onboarding', '/t/students/new']) {
      expect(
        _redirect(route, _signedIn, parentOnly),
        AppRoutes.rolePicker,
        reason: route,
      );
      expect(
        _redirect(
          route,
          _signedIn,
          _loaded(const [_teacher], active: _teacher),
        ),
        isNull,
        reason: route,
      );
    }
  });
}
