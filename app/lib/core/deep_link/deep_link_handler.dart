import 'dart:async';
import 'dart:developer';

import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_core/tasco_core.dart';

import '../routing/app_routes.dart';

/// Nghe deep link qua `app_links` và điều hướng.
///
/// - Đã đăng nhập: đi thẳng tới route.
/// - Chưa đăng nhập: lưu [PendingDeepLink], về màn đăng nhập; router mở lại
///   link sau khi đăng nhập xong.
/// - Link lạ: bỏ qua.
class DeepLinkHandler {
  DeepLinkHandler({
    required GoRouter router,
    required DeepLinkTarget? Function(Uri uri) resolve,
    required bool Function() isAuthenticated,
    AppLinks? appLinks,
  }) : _router = router,
       _resolve = resolve,
       _isAuthenticated = isAuthenticated,
       _appLinks = appLinks ?? AppLinks();

  final GoRouter _router;
  final DeepLinkTarget? Function(Uri uri) _resolve;
  final bool Function() _isAuthenticated;
  final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  /// Gọi một lần ở bootstrap cho link đã mở app (cold start).
  Future<void> handleInitialLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) handle(uri);
    } catch (e, st) {
      log('initial link failed: $e', name: 'deep_link', stackTrace: st);
    }
  }

  /// Nghe link đến khi app đang chạy.
  void startListening() {
    _sub ??= _appLinks.uriLinkStream.listen(
      handle,
      onError: (Object e, StackTrace st) =>
          log('link stream error: $e', name: 'deep_link', stackTrace: st),
    );
  }

  void handle(Uri uri) {
    final target = _resolve(uri);
    if (target == null) {
      log('no route for $uri', name: 'deep_link');
      return;
    }
    if (target.requiresAuth && !_isAuthenticated()) {
      PendingDeepLink.save(target);
      _router.go(AppRoutes.login);
      return;
    }
    _router.go(target.path, extra: target.queryParams);
  }
}
