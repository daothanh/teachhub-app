import 'dart:async';
import 'dart:developer';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tasco_core/tasco_core.dart';
import 'package:tasco_module/tasco_module.dart';
import 'package:tasco_notifications/tasco_notifications.dart';
import 'package:tasco_observability/tasco_observability.dart';
import 'package:tasco_ota/tasco_ota.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:tasco_utils/tasco_utils.dart';
import 'package:teachhub_shared/teachhub_shared.dart';
import 'package:teacher/teacher.dart';
import 'package:parent/parent.dart';
import 'package:student/student.dart';
// tasco:miniapp-imports

import 'app/app.dart';
import 'core/config/app_env.dart';
import 'core/deep_link/deep_link_handler.dart';
import 'core/deep_link/teachhub_deep_link_resolver.dart';
import 'core/module_health_report.dart';
import 'core/routing/app_router.dart';
import 'core/theme/teachhub_theme.dart';
import 'core/theme/theme_controller.dart';
import 'di/api_module.dart';
import 'di/di.dart';
import 'features/app_version/app_version_gate.dart';
import 'features/auth/auth_cubit.dart';
import 'features/auth/email_otp_sender.dart';
import 'features/auth/logout_service.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/sso/apple_sso_provider.dart';
import 'features/auth/sso/google_sso_provider.dart';
import 'features/invite/invite_cubit.dart';
import 'features/role_picker/membership_cubit.dart';

Future<void> bootstrap({required Env env}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final isDev = env == Env.development;

  // 1. Firebase + Crashlytics. Ngoài development, thiếu Firebase là lỗi cấu
  //    hình: không có push báo vắng, không có crash report — dừng ngay thay vì
  //    chạy tiếp mà không ai biết.
  final firebaseReady = await FirebaseInitializer.ensureInitialized(
    enableCrashlytics: !isDev,
  );
  if (!firebaseReady && !isDev) {
    throw StateError(
      'Firebase is not configured for ${env.name}: add google-services.json / '
      'GoogleService-Info.plist for this flavor (docs/native-setup.md).',
    );
  }

  // 2. DI: local → api → remote → repository → cubit.
  await setupDi(env: env);

  // 3. Remote Config — chỉ bật/tắt giao diện; giới hạn gói chặn ở backend.
  if (firebaseReady) {
    try {
      GetIt.I.registerSingleton<RemoteConfigService>(
        await RemoteConfigService.init(),
      );
    } catch (e, st) {
      log('Remote Config fetch skipped: $e', name: 'bootstrap', stackTrace: st);
    }
  }

  configLoading();

  // 4. Mini-app theo vai trò (spec §3.7).
  final moduleManager = ModuleManager()
    ..register(TeacherController.instance.toModuleSlot())
    ..register(ParentController.instance.toModuleSlot())
    ..register(StudentController.instance.toModuleSlot());
  // tasco:miniapp-register
  await moduleManager.initAll();
  await reportModuleHealth(
    moduleManager,
    sink: firebaseReady ? _recordModuleIssue : null,
  );
  GetIt.I.registerSingleton<ModuleManager>(moduleManager);

  // 5. Phiên + vai trò. Nghe trước initSession để không lỡ lần khôi phục phiên.
  final authCubit = GetIt.I<AppAuthCubit>();
  final membershipCubit = GetIt.I<MembershipCubit>();
  String? claimedUser;
  authCubit.stream.listen((state) async {
    if (state.isAuthenticated) {
      // Người khác đăng nhập trên máy còn CSDL của người trước thì xóa trước
      // khi vào mini-app (chặn tải vai trò tới khi xong).
      final userId = state.user?.id;
      if (userId != null && userId != claimedUser) {
        claimedUser = userId;
        try {
          await TeacherController.instance.claimDatabaseFor(userId);
        } catch (e, st) {
          log(
            'Teacher DB claim failed',
            name: 'bootstrap',
            error: e,
            stackTrace: st,
          );
        }
      }
      if (membershipCubit.state.statusLoad == LoadingStatus.initial) {
        membershipCubit.load();
      }
    } else {
      claimedUser = null;
      if (membershipCubit.state.statusLoad != LoadingStatus.initial) {
        membershipCubit.clear();
      }
    }
  });
  // Đăng xuất xóa CSDL teacher khi outbox trống; phiên hết hạn đi cùng đường đó.
  final logoutService = LogoutService(
    logout: authCubit.logout,
    pendingCount: TeacherController.instance.pendingSyncCount,
    wipeLocalData: TeacherController.instance.wipeLocalData,
  );
  GetIt.I.registerSingleton<LogoutService>(logoutService);
  GetIt.I<AuthEventBus>().stream
      .where((e) => e == AuthEvent.sessionExpired)
      .listen((_) => unawaited(logoutService.onSessionExpired()));
  // Lần xóa trước dở dang (lỗi đĩa, app bị tắt) thì xóa nốt.
  unawaited(
    TeacherController.instance.retryPendingWipe().catchError((
      Object e,
      StackTrace st,
    ) {
      log('Retry wipe failed', name: 'bootstrap', error: e, stackTrace: st);
    }),
  );
  unawaited(authCubit.initSession());

  // 6. Router.
  final api = GetIt.I<Dio>(instanceName: TeachHubDiKey.api);
  final appEnv = GetIt.I<AppEnv>();
  // Ép cập nhật: kiểm song song, không làm chậm khởi động (spec §5.1).
  final versionGate = AppVersionGate(
    api: api,
    currentVersion: (await PackageInfo.fromPlatform()).version,
    platform: Platform.isIOS ? 'ios' : 'android',
  );
  unawaited(versionGate.check());
  final router = buildAppRouter(
    moduleManager: moduleManager,
    authCubit: authCubit,
    membershipCubit: membershipCubit,
    loginPage: () => LoginPage(
      sendOtp: emailOtpSender(api),
      google: GoogleSsoProvider(serverClientId: appEnv.googleServerClientId),
      apple: AppleSsoProvider(),
      isIOS: Platform.isIOS,
    ),
    inviteCubit: (token) =>
        InviteCubit(api: api, memberships: membershipCubit, token: token),
    updateRequired: versionGate,
    navigatorKey: alice?.getNavigatorKey(),
  );

  // 7. Push FCM → mini-app. Không chờ: xin quyền iOS chạy nền.
  if (firebaseReady) {
    unawaited(
      NotificationDirector(
        manager: moduleManager,
        router: router,
        pushRepository: GetIt.I<PushRepository>(),
        authEventBus: GetIt.I<AuthEventBus>(),
      ).start(),
    );
  }

  // 8. Deep link dayhoc.app / teachhub:// (spec §2.11 G3).
  final resolver = TeachHubDeepLinkResolver(
    moduleResolver: (path) {
      final match = moduleManager.resolveDeepLink(path);
      if (match == null) return null;
      return (
        path: path,
        params: match.params,
        requiresAuth: !moduleManager.isPublicPath(match.slot, path),
      );
    },
  );
  final deepLinks = DeepLinkHandler(
    router: router,
    resolve: resolver.resolve,
    isAuthenticated: () => authCubit.isAuthenticated,
  );
  await deepLinks.handleInitialLink();
  deepLinks.startListening();

  final theme = await TeachHubTheme.load();
  runApp(
    App(
      router: router,
      authCubit: authCubit,
      membershipCubit: membershipCubit,
      localeController: GetIt.I<LocaleController>(),
      themeController: GetIt.I<ThemeController>(),
      theme: theme.light,
      darkTheme: theme.dark,
      miniAppDelegates: [
        ...TeacherController.instance.localizationsDelegates,
        ...ParentController.instance.localizationsDelegates,
        ...StudentController.instance.localizationsDelegates,
      ],
    ),
  );

  // 9. OTA Shorebird (staging/prod) sau khung hình đầu, để mạng chậm không làm
  //    chậm khởi động nguội (mục tiêu ≤ 3 s).
  if (!isDev) unawaited(_checkOta(env, firebaseReady));
}

Future<void> _checkOta(Env env, bool firebaseReady) async {
  final otaUpdater = ShorebirdOtaUpdater(
    track: env == Env.staging ? UpdateTrack.staging : UpdateTrack.stable,
  );
  try {
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
    final result = await otaUpdater.checkAndDownloadPatch(
      policy: OtaNetworkPolicy.wifiOnly,
    );
    if (result.hasUpdateReady) {
      log('OTA: patch ${result.nextPatch} staged', name: 'bootstrap');
    } else if (result.status == OtaUpdateStatus.error) {
      log('OTA check failed: ${result.error}', name: 'bootstrap');
    }
  } catch (e, st) {
    log('OTA check skipped: $e', name: 'bootstrap', stackTrace: st);
  }
}

/// Mini-app lỗi khi init → non-fatal Crashlytics thay vì biến mất lặng lẽ.
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
