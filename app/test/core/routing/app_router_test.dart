import 'package:app/core/routing/app_router.dart';
import 'package:app/core/routing/app_routes.dart';
import 'package:app/features/auth/auth_cubit.dart';
import 'package:app/features/auth/teachhub_user.dart';
import 'package:app/features/consent/consent_cubit.dart';
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

String? _redirect(
  String location,
  AppAuthState auth,
  MembershipState m, {
  ConsentState consent = const ConsentState.accepted(),
}) => resolveRedirect(
  location: location,
  auth: auth,
  memberships: m,
  consent: consent,
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

  group('guard đã đồng ý (US-0.3 AC2)', () {
    final parentOnly = _loaded([_parent], active: _parent);
    const required = ConsentState(
      phase: ConsentPhase.required,
      termsVersion: '2026-12-01',
    );

    const failed = ConsentState(phase: ConsentPhase.failed);

    test('Phụ huynh chưa đồng ý hoặc không đọc được: /p/** về màn đồng ý', () {
      for (final consent in [required, failed]) {
        for (final route in ['/p', '/p/child/1']) {
          expect(
            _redirect(route, _signedIn, parentOnly, consent: consent),
            AppRoutes.consent,
            reason: '$route ${consent.phase}',
          );
        }
      }
    });

    test(
      'chưa biết trạng thái (đang tải): giữ ở splash, không qua /consent',
      () {
        for (final consent in [
          const ConsentState(),
          const ConsentState(phase: ConsentPhase.loading),
        ]) {
          expect(
            _redirect('/p/child/1', _signedIn, parentOnly, consent: consent),
            AppRoutes.splash,
          );
          expect(
            _redirect(
              AppRoutes.splash,
              _signedIn,
              parentOnly,
              consent: consent,
            ),
            isNull,
          );
        }
      },
    );

    test('mở nguội, đã đồng ý: splash → /p thẳng, không qua /consent', () {
      expect(_redirect(AppRoutes.splash, _signedIn, parentOnly), '/p');
    });

    test(
      'deep link /p/x chờ: giữ link qua lúc tải; đã đồng ý thì tới /p/x',
      () {
        PendingDeepLink.save(const DeepLinkTarget(path: '/p/x'));
        const loading = ConsentState(phase: ConsentPhase.loading);
        expect(
          _redirect(AppRoutes.splash, _signedIn, parentOnly, consent: loading),
          isNull,
        );
        expect(PendingDeepLink.current?.path, '/p/x');
        expect(_redirect(AppRoutes.splash, _signedIn, parentOnly), '/p/x');
        expect(PendingDeepLink.current, isNull);
      },
    );

    test('deep link /p/x chờ, chưa đồng ý: về /consent mà vẫn giữ link', () {
      PendingDeepLink.save(const DeepLinkTarget(path: '/p/x'));
      expect(
        _redirect(AppRoutes.splash, _signedIn, parentOnly, consent: required),
        AppRoutes.consent,
      );
      expect(PendingDeepLink.current?.path, '/p/x');
    });

    test('đã đồng ý thì vào được; màn đồng ý không bị chặn', () {
      expect(_redirect('/p', _signedIn, parentOnly), isNull);
      expect(
        _redirect(AppRoutes.consent, _signedIn, parentOnly, consent: required),
        isNull,
      );
    });

    test('không chặn không gian khác, và /p chỉ cần đồng ý khi có vai trò', () {
      final both = _loaded([_teacher, _parent], active: _teacher);
      expect(_redirect('/t', _signedIn, both, consent: required), isNull);
      // Không có vai trò Phụ huynh thì PermissionGuard xử lý như cũ.
      final teacherOnly = _loaded([_teacher], active: _teacher);
      expect(
        _redirect('/p', _signedIn, teacherOnly, consent: required),
        AppRoutes.rolePicker,
      );
      expect(_redirect('/pay', _signedIn, both, consent: required), isNull);
    });

    test('mở app vào /p khi chưa đồng ý: splash → màn đồng ý', () {
      expect(
        _redirect(AppRoutes.splash, _signedIn, parentOnly, consent: required),
        AppRoutes.consent,
      );
    });
  });

  test(
    'bản quá cũ: mọi route chuyển sang Cần cập nhật, kể cả khi chưa đăng nhập',
    () {
      String? r(String location, {required bool required}) => resolveRedirect(
        location: location,
        auth: _signedOut,
        memberships: const MembershipState(),
        consent: const ConsentState(),
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
