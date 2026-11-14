import 'dart:developer';

import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_core/tasco_core.dart';

import '../routing/app_routes.dart';

/// Listens for incoming deep-links (custom scheme `tasco://`) via the
/// `app_links` package and navigates the app accordingly.
///
/// Behaviour:
/// - **Authenticated**: navigate immediately to the resolved path.
/// - **Not authenticated**: save [PendingDeepLink] and redirect to login;
///   [AppRouter] resumes navigation after a successful login.
/// - **Unknown link**: silently fall back to [AppRoutes.home].
///
/// Cold-start handling: [getInitialUri] should be called once by the router
/// before the first route is resolved.
class DeepLinkHandler {
  final GoRouter _router;
  final DeepLinkService _service;
  final AppAuthStateReader _authReader;

  DeepLinkHandler({
    required GoRouter router,
    required DeepLinkService service,
    required AppAuthStateReader authReader,
  }) : _router = router,
       _service = service,
       _authReader = authReader;

  final _appLinks = AppLinks();

  /// Call once during bootstrap to handle the link that cold-started the app.
  Future<void> handleInitialLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) _handleUri(uri);
    } catch (e, st) {
      log('DeepLinkHandler.handleInitialLink error: $e',
          name: 'deep_link', stackTrace: st);
    }
  }

  /// Subscribe to deep-links arriving while the app is already running.
  /// Call once and keep the subscription alive.
  void startListening() {
    _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (Object e, StackTrace st) {
        log('DeepLinkHandler stream error: $e',
            name: 'deep_link', stackTrace: st);
      },
    );
  }

  void _handleUri(Uri uri) {
    final target = _service.resolve(uri);
    if (target == null) {
      log('DeepLinkHandler: no route for $uri — falling back to home',
          name: 'deep_link');
      // Silently fall back — only navigate if app is not on home already.
      if (_router.routerDelegate.currentConfiguration.last.matchedLocation !=
          AppRoutes.home) {
        _router.go(AppRoutes.home);
      }
      return;
    }

    if (target.requiresAuth && !_authReader.isAuthenticated) {
      log('DeepLinkHandler: pending link saved (not authenticated): ${target.path}',
          name: 'deep_link');
      PendingDeepLink.save(target);
      _router.go(AppRoutes.login);
      return;
    }

    log('DeepLinkHandler: navigating to ${target.path}', name: 'deep_link');
    _router.go(target.path, extra: target.queryParams);
  }
}

/// Thin read-only interface over [AppAuthCubit] that [DeepLinkHandler] needs.
/// Kept separate to avoid hard-coupling to the auth package.
abstract interface class AppAuthStateReader {
  bool get isAuthenticated;
}
