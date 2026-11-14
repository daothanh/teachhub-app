import 'dart:async';
import 'dart:developer';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:tasco_core/tasco_core.dart';
import 'package:tasco_observability/tasco_observability.dart';
import 'package:tasco_ota/tasco_ota.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'app/app.dart';
import 'core/module_health_report.dart';
import 'core/theme/theme_controller.dart';
import 'package:tasco_module/tasco_module.dart';
// tasco:miniapp-imports

import 'package:tasco_notifications/tasco_notifications.dart';

import 'core/config/app_env.dart';
import 'core/config/client_identity.dart';
import 'core/routing/app_router.dart';
import 'core/routing/app_routes.dart';
import 'core/deep_link/deep_link_handler.dart';
import 'data/model/request/login_request.dart';
import 'features/auth/auth_cubit.dart';
import 'di/api_module.dart';
import 'di/di.dart';

Future<void> bootstrap({required Env env}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final isDev = env == Env.development;

  // 1. Firebase + Crashlytics — guarded so a missing config never blocks startup.
  //    Crashlytics collection is off in development to keep dashboards clean.
  final firebaseReady = await FirebaseInitializer.ensureInitialized(
    enableCrashlytics: !isDev,
  );

  // 2. DI - local module
  await setupDi(env: env);

  // 3. Remote Config — feature flags; only when Firebase came up.
  if (firebaseReady) {
    try {
      final remoteConfig = await RemoteConfigService.init();
      GetIt.I.registerSingleton<RemoteConfigService>(remoteConfig);
    } catch (e, st) {
      log('Remote Config fetch skipped: $e', name: 'bootstrap', stackTrace: st);
    }
  }

  // 4. DI - cubits & services
  await setUpCubit();

  // 5. EasyLoading config
  configLoading();

  // 6. Module Manager — register mini-apps
  // ModuleManager no longer takes env or a host interceptor: neither was ever
  // read, and each slot's init already receives the interceptor it needs
  // (ADR-0029).
  final moduleManager = ModuleManager();

  // tasco:miniapp-register


  await moduleManager.initAll();
  // ModuleManager contains both a mini-app that failed to mount and any
  // authority a mini-app claimed outside its own routePrefix. Containment is
  // right; staying quiet about it is not — without this the module simply
  // vanishes from the home menu with nothing to debug from.
  await reportModuleHealth(
    moduleManager,
    sink: firebaseReady ? _recordModuleIssue : null,
  );
  // Register after initAll so only healthy slots are accessible to the UI.
  GetIt.I.registerSingleton<ModuleManager>(moduleManager);

  // 7. Auth — khôi phục phiên (guard ở router phụ thuộc state này)
  final authCubit = GetIt.I<AppAuthCubit>()..initSession();
  // Body đăng nhập ghép thêm client id và installation này (LoginRequest).
  final appEnv = GetIt.I<AppEnv>();
  final clientIdentity = GetIt.I<ClientIdentity>();

  // 8. Router — gộp routes từ host + mini-apps, có auth guard.
  //    AuthPolicy là cấu hình của TỪNG app — sửa ở đây theo nhu cầu:
  //    - Bắt buộc đăng nhập toàn bộ: const AuthPolicy()
  //    - Public-first: AuthPolicy(mode: AuthMode.publicByDefault, exceptions: {...})
  //    App demo này để home công khai:
  final router = buildAppRouter(
    moduleManager: moduleManager,
    authCubit: authCubit,
    loginCredentials: ({required username, required password}) => LoginRequest(
      username: username,
      password: password,
      clientId: appEnv.authClientId,
      client: clientIdentity,
    ).toJson(),
    navigatorKey: alice?.getNavigatorKey(),
    authPolicy: const AuthPolicy(
      exceptions: {
        AppRoutes.home,
        AppRoutes.explore,
        AppRoutes.notification,
        AppRoutes.profile,
      },
    ),
  );

  // 9. Notification Director — FCM routing to mini-apps; needs Firebase.
  //    Not awaited: start() attaches its listeners and routes a launch
  //    notification, then asks for permission and registers the token in the
  //    background. Awaited, the first frame waited for the iOS permission
  //    prompt. start() logs its own failures and never completes with an
  //    error; the catch below covers a missing DI registration.
  if (firebaseReady) {
    try {
      unawaited(
        NotificationDirector(
          manager: moduleManager,
          router: router,
          pushRepository: GetIt.I<PushRepository>(),
          authEventBus: GetIt.I<AuthEventBus>(),
        ).start(),
      );
    } catch (e, st) {
      log(
        'NotificationDirector start skipped: $e',
        name: 'bootstrap',
        stackTrace: st,
      );
    }
  }

  // 10. Deep-Link Handler — resolves tasco:// URIs + auth-resume flow.
  final deepLinkService = DeepLinkService(
    moduleResolver: (path) {
      final match = moduleManager.resolveDeepLink(path);
      if (match == null) return null;
      // Qua ModuleManager, không đọc thẳng `slot.publicRoutePrefixes`: chỉ ở
      // đó tiền tố mới được lọc theo `routePrefix` của slot, và mới dùng đúng
      // luật khớp mà router áp dụng.
      final isPublic = moduleManager.isPublicPath(match.slot, path);
      return (path: path, params: match.params, requiresAuth: !isPublic);
    },
  );
  final deepLinkHandler = DeepLinkHandler(
    router: router,
    service: deepLinkService,
    authReader: _AuthReaderAdapter(GetIt.I<AppAuthCubit>()),
  );
  await deepLinkHandler.handleInitialLink();
  deepLinkHandler.startListening();

  // 11. OTA — Shorebird patch check on staging/prod only (ADR-0017). Safe even
  // without a Shorebird account: a plain `flutter build` leaves the engine
  // unavailable, so the updater reports unsupportedPlatform and this is a no-op.
  // Real patching needs `shorebird release/patch` + the app id in shorebird.yaml.
  // Time-boxed so a slow/flaky network never blocks the first frame.
  if (!isDev) {
    final otaUpdater = ShorebirdOtaUpdater(
      track: env == Env.staging ? UpdateTrack.staging : UpdateTrack.stable,
    );
    // Telemetry → Crashlytics (only when Firebase came up).
    if (firebaseReady) {
      otaUpdater.events.listen(_reportOtaEvent);
      final patch = await otaUpdater.currentPatch();
      if (patch != null) {
        await FirebaseCrashlytics.instance.setCustomKey(
          'ota_patch',
          patch.number,
        );
      }
    }
    try {
      final result = await otaUpdater
          .checkAndDownloadPatch(policy: OtaNetworkPolicy.wifiOnly)
          .timeout(const Duration(seconds: 3));
      if (result.hasUpdateReady) {
        log(
          'OTA: patch ${result.nextPatch} staged, applies on next restart',
          name: 'bootstrap',
        );
      } else if (result.status == OtaUpdateStatus.error) {
        log('OTA check failed: ${result.error}', name: 'bootstrap');
      }
    } catch (e, st) {
      log('OTA check skipped: $e', name: 'bootstrap', stackTrace: st);
    }
  }

  // 11. Run app
  runApp(
    App(
      router: router,
      authCubit: authCubit,
      localeController: GetIt.I<LocaleController>(),
      themeController: GetIt.I<ThemeController>(),
    ),
  );
}

/// The production sink for [reportModuleHealth]: a non-fatal Crashlytics
/// record, so a broken mini-app shows up in the dashboard without being
/// reported as an app crash. Binding the abstract sink to the concrete backend
/// is composition-root work, which is why it lives here and not in the reporter.
Future<void> _recordModuleIssue(
  Object error,
  StackTrace stackTrace,
  String reason,
) => FirebaseCrashlytics.instance.recordError(
  error,
  stackTrace,
  reason: reason,
  fatal: false,
);

/// Routes OTA lifecycle events to Crashlytics for adoption + failure telemetry.
void _reportOtaEvent(OtaEvent event) {
  final crashlytics = FirebaseCrashlytics.instance;
  switch (event) {
    case OtaCheckStarted():
    case OtaDownloadProgress():
      break;
    case OtaPatchFound(:final patchNumber):
      unawaited(crashlytics.log('OTA patch found: $patchNumber'));
    case OtaPatchReady(:final patchNumber):
      unawaited(crashlytics.setCustomKey('ota_next_patch', patchNumber));
      unawaited(crashlytics.log('OTA patch ready: $patchNumber'));
    case OtaUpdateFailed(:final error):
      unawaited(
        crashlytics.recordError(
          error.cause ?? error,
          StackTrace.current,
          reason: 'OTA ${error.kind.name}: ${error.message}',
          fatal: false,
        ),
      );
  }
}

/// Thin adapter so [DeepLinkHandler] can read auth state without depending on
/// the shell's specific cubit type.
class _AuthReaderAdapter implements AppAuthStateReader {
  final AppAuthCubit _cubit;
  const _AuthReaderAdapter(this._cubit);

  @override
  bool get isAuthenticated => _cubit.isAuthenticated;
}
