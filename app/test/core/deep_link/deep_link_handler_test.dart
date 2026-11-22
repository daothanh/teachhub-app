import 'package:app/core/deep_link/deep_link_handler.dart';
import 'package:app/core/routing/app_routes.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_core/tasco_core.dart';

class _FakeAppLinks extends Fake implements AppLinks {}

void main() {
  late GoRouter router;
  var authenticated = false;
  var rolesLoaded = false;

  setUp(() {
    PendingDeepLink.clear();
    authenticated = false;
    rolesLoaded = false;
    router = GoRouter(
      initialLocation: AppRoutes.splash,
      routes: [
        for (final path in [
          AppRoutes.splash,
          AppRoutes.login,
          '/invite/:token',
        ])
          GoRoute(path: path, builder: (_, _) => const SizedBox()),
      ],
    );
  });
  tearDown(() => router.dispose());

  DeepLinkHandler handler() => DeepLinkHandler(
    router: router,
    resolve: (uri) => DeepLinkTarget(path: uri.path),
    isAuthenticated: () => authenticated,
    rolesLoaded: () => rolesLoaded,
    appLinks: _FakeAppLinks(),
  );

  String location() => router.routeInformationProvider.value.uri.path;

  test('chưa đăng nhập: lưu link chờ, về đăng nhập', () {
    handler().handle(Uri.parse('https://dayhoc.app/invite/abc'));
    expect(PendingDeepLink.current?.path, '/invite/abc');
    expect(location(), AppRoutes.login);
  });

  test(
    'mở app nguội đã đăng nhập nhưng vai trò chưa tải: lưu link chờ ở splash',
    () {
      authenticated = true;
      handler().handle(Uri.parse('https://dayhoc.app/invite/abc'));
      expect(PendingDeepLink.current?.path, '/invite/abc');
      expect(location(), AppRoutes.splash);
    },
  );

  test('đã đăng nhập và tải xong vai trò: đi thẳng, không lưu', () {
    authenticated = true;
    rolesLoaded = true;
    handler().handle(Uri.parse('https://dayhoc.app/invite/abc'));
    expect(PendingDeepLink.current, isNull);
    expect(location(), '/invite/abc');
  });
}
