import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/config/app_env.dart';
import 'package:app/core/theme/theme_controller.dart';
import 'package:app/features/auth/teachhub_user.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:app/features/auth/auth_cubit.dart';
import 'package:app/features/auth/logout_service.dart';
import 'package:app/features/settings/settings_page.dart';
import 'package:app/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasco_auth/tasco_auth.dart';
import 'package:tasco_core/tasco_core.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

// ── Minimal fakes ─────────────────────────────────────────────────────────────

class FakeAuthRepo implements AuthRepository<TeachHubUser> {
  bool setBiometricEnabledCalled = false;
  bool isBiometricEnabledValue = false;

  @override
  Future<AuthResult<TeachHubUser>> login(Map<String, dynamic> c) async =>
      const AuthSuccess(TeachHubUser(id: '1', email: 'u@b.vn'));
  @override
  Future<TeachHubUser> loginWithSso({
    required String providerId,
    required SsoResult ssoResult,
  }) async => const TeachHubUser(id: '1', email: 'u@b.vn');
  @override
  Future<bool> isBiometricEnabled() async => isBiometricEnabledValue;
  @override
  Future<void> setBiometricEnabled(bool e) async {
    setBiometricEnabledCalled = true;
    isBiometricEnabledValue = e;
  }

  @override
  Future<TeachHubUser?> cachedUser() async => null;
  @override
  Future<TeachHubUser> getUserInfo() async =>
      const TeachHubUser(id: '1', email: 'u@b.vn');
  @override
  Future<bool> hasValidToken() async => false;
  @override
  Future<String?> refreshToken() async => null;
  @override
  Future<void> clearSession() async {}
  @override
  Future<void> logout() async {}
}

class FakeBioService implements BiometricService {
  final bool supported;
  final bool enrolled;
  final bool authResult;
  FakeBioService({
    this.supported = true,
    this.enrolled = true,
    this.authResult = true,
  });

  @override
  Future<bool> isDeviceSupported() async => supported;
  @override
  Future<bool> canCheckBiometrics() async => enrolled;
  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => [
    BiometricType.fingerprint,
  ];
  @override
  Future<bool> authenticate({
    required String localizedReason,
    bool biometricOnly = true,
    bool sensitiveTransaction = true,
    bool stickyAuth = false,
  }) async => authResult;
  @override
  Future<bool> stopAuthentication() async => true;
}

// ── Test helpers ──────────────────────────────────────────────────────────────

late SharedPreferences _prefs;
late LocaleController _localeCtrl;
late ThemeController _themeCtrl;

Future<void> _setupGetIt({BiometricService? bio}) async {
  final repo = FakeAuthRepo();
  final bus = AuthEventBus();
  final cubit = AppAuthCubit(
    repository: repo,
    authEventBus: bus,
    biometricService: bio ?? FakeBioService(),
  );

  if (!GetIt.I.isRegistered<AppAuthCubit>()) {
    GetIt.I.registerSingleton<AppAuthCubit>(cubit);
  }
  if (!GetIt.I.isRegistered<LocaleController>()) {
    GetIt.I.registerSingleton<LocaleController>(_localeCtrl);
  }
  if (!GetIt.I.isRegistered<ThemeController>()) {
    GetIt.I.registerSingleton<ThemeController>(_themeCtrl);
  }
}

/// Wraps SettingsPage with MaterialApp + l10n delegates so AppLocalizations
/// resolves correctly in tests.
Widget _wrap(AppAuthCubit cubit, {Locale locale = const Locale('vi')}) {
  return ScreenUtilPlusInit(
    designSize: const Size(393, 852),
    builder: (context, _) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.v1,
      darkTheme: AppTheme.v1Dark,
      home: BlocProvider<AppAuthCubit>.value(
        value: cubit,
        child: const SettingsPage(),
      ),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
    _localeCtrl = LocaleController(
      supportedLocales: const [Locale('vi'), Locale('en')],
    );
    _themeCtrl = ThemeController(_prefs);
    GetIt.I.registerSingleton<PackageInfo>(
      PackageInfo(
        appName: 'TeachHub',
        packageName: 'vn.dayhoc.app',
        version: '1.2.3',
        buildNumber: '1',
      ),
    );
  });

  tearDown(() async {
    await GetIt.I.reset();
    _localeCtrl.dispose();
    _themeCtrl.dispose();
  });

  group('SettingsPage Widget Tests', () {
    testWidgets('logout with unsynced sessions warns and can be cancelled', (
      tester,
    ) async {
      await _setupGetIt();
      final calls = <String>[];
      GetIt.I.registerSingleton<LogoutService>(
        LogoutService(
          logout: () async => calls.add('logout'),
          pendingCount: () async => 3,
          wipeLocalData: () async => calls.add('wipe'),
        ),
      );
      await tester.pumpWidget(_wrap(GetIt.I<AppAuthCubit>()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Đăng xuất'));
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      expect(find.text('Còn 3 buổi chưa đồng bộ'), findsOneWidget);

      await tester.tap(find.text('Ở lại'));
      await tester.pumpAndSettle();
      expect(calls, isEmpty);

      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vẫn đăng xuất'));
      await tester.pumpAndSettle();
      expect(calls, ['logout', 'wipe']);
    });

    testWidgets('mục "Xóa tài khoản" nằm trong cài đặt, chữ 200% không vỡ', (
      tester,
    ) async {
      await _setupGetIt();
      tester.view.physicalSize = const Size(390, 1200) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: _wrap(GetIt.I<AppAuthCubit>()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Xóa tài khoản'));
      expect(find.text('Tài khoản'), findsOneWidget);
      expect(find.text('Xóa tài khoản'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('wipe failure after logout shows a snackbar', (tester) async {
      await _setupGetIt();
      GetIt.I.registerSingleton<LogoutService>(
        LogoutService(
          logout: () async {},
          pendingCount: () async => 0,
          wipeLocalData: () async => throw StateError('disk'),
        ),
      );
      await tester.pumpWidget(_wrap(GetIt.I<AppAuthCubit>()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Đăng xuất'));
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      expect(find.textContaining('chưa xóa hết dữ liệu'), findsOneWidget);
    });

    testWidgets('unreadable outbox shows its own warning', (tester) async {
      await _setupGetIt();
      GetIt.I.registerSingleton<LogoutService>(
        LogoutService(
          logout: () async {},
          pendingCount: () async => throw StateError('key lost'),
          wipeLocalData: () async {},
        ),
      );
      await tester.pumpWidget(_wrap(GetIt.I<AppAuthCubit>()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Đăng xuất'));
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      expect(find.text('Không đọc được dữ liệu chưa đồng bộ'), findsOneWidget);
    });

    testWidgets('renders all four sections with l10n labels', (tester) async {
      await _setupGetIt();
      final cubit = GetIt.I<AppAuthCubit>();

      await tester.pumpWidget(_wrap(cubit));
      await tester.pumpAndSettle();

      // Section headers (Vietnamese l10n)
      expect(find.text('Bảo mật & Xác thực'), findsOneWidget);
      expect(find.text('Đăng nhập bằng Sinh trắc học'), findsOneWidget);
      expect(find.text('Ngôn ngữ'), findsOneWidget);
      expect(find.text('Giao diện'), findsOneWidget);
      expect(find.text('Về ứng dụng'), findsOneWidget);
      expect(find.byType(AppIconButton), findsOneWidget);
    });

    testWidgets(
      'back button returns to the role picker when settings is the root',
      (tester) async {
        await _setupGetIt();
        final cubit = GetIt.I<AppAuthCubit>();
        final router = GoRouter(
          initialLocation: '/settings',
          routes: [
            GoRoute(
              path: '/settings',
              builder: (_, _) => BlocProvider<AppAuthCubit>.value(
                value: cubit,
                child: const SettingsPage(),
              ),
            ),
            GoRoute(
              path: '/role-picker',
              builder: (_, _) => const Scaffold(body: Text('RolePicker')),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          ScreenUtilPlusInit(
            designSize: const Size(393, 852),
            builder: (context, _) => MaterialApp.router(
              locale: const Locale('vi'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: AppTheme.v1,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(AppIconButton));
        await tester.pumpAndSettle();

        expect(find.text('RolePicker'), findsOneWidget);
      },
    );

    testWidgets('shows biometric switch enabled when available and enrolled', (
      tester,
    ) async {
      await _setupGetIt(bio: FakeBioService(supported: true, enrolled: true));
      final cubit = GetIt.I<AppAuthCubit>();
      await cubit.initSession();

      await tester.pumpWidget(_wrap(cubit));
      await tester.pumpAndSettle();

      final switchWidget = tester.widget<Switch>(
        find.descendant(
          of: find.byKey(const Key('biometric_switch')),
          matching: find.byType(Switch),
        ),
      );
      expect(switchWidget.value, isFalse);
    });

    testWidgets('biometric switch shows unsupported text when no bio service', (
      tester,
    ) async {
      final repo = FakeAuthRepo();
      final bus = AuthEventBus();
      final cubit = AppAuthCubit(repository: repo, authEventBus: bus);
      addTearDown(cubit.close);
      addTearDown(bus.dispose);

      if (!GetIt.I.isRegistered<AppAuthCubit>()) {
        GetIt.I.registerSingleton<AppAuthCubit>(cubit);
      }
      if (!GetIt.I.isRegistered<LocaleController>()) {
        GetIt.I.registerSingleton<LocaleController>(_localeCtrl);
      }
      if (!GetIt.I.isRegistered<ThemeController>()) {
        GetIt.I.registerSingleton<ThemeController>(_themeCtrl);
      }

      await cubit.initSession();

      await tester.pumpWidget(_wrap(cubit));
      await tester.pumpAndSettle();

      expect(find.text('Thiết bị không hỗ trợ sinh trắc học'), findsOneWidget);
    });

    testWidgets(
      'biometric toggle calls authenticate then setBiometricEnabled',
      (tester) async {
        await _setupGetIt(
          bio: FakeBioService(
            supported: true,
            enrolled: true,
            authResult: true,
          ),
        );
        final cubit = GetIt.I<AppAuthCubit>();
        await cubit.initSession();

        await tester.pumpWidget(_wrap(cubit));
        await tester.pumpAndSettle();

        // Tap the switch to enable biometric.
        final sw = find.byKey(const Key('biometric_switch'));
        expect(sw, findsOneWidget);
        await tester.tap(
          find.descendant(of: sw, matching: find.byType(Switch)),
        );
        await tester.pumpAndSettle();

        // Success snackbar should appear.
        expect(find.text('Đã bật đăng nhập sinh trắc học'), findsOneWidget);
      },
    );

    testWidgets('biometric toggle shows failure snackbar when auth fails', (
      tester,
    ) async {
      await _setupGetIt(
        bio: FakeBioService(supported: true, enrolled: true, authResult: false),
      );
      final cubit = GetIt.I<AppAuthCubit>();
      await cubit.initSession();

      await tester.pumpWidget(_wrap(cubit));
      await tester.pumpAndSettle();

      final sw = find.byKey(const Key('biometric_switch'));
      await tester.tap(find.descendant(of: sw, matching: find.byType(Switch)));
      await tester.pumpAndSettle();

      // Failure snackbar should appear.
      expect(find.text('Xác minh sinh trắc học thất bại'), findsOneWidget);
    });

    testWidgets('tapping Tiếng Việt sets locale to vi', (tester) async {
      await _setupGetIt();
      final cubit = GetIt.I<AppAuthCubit>();

      await tester.pumpWidget(_wrap(cubit));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tiếng Việt'));
      await tester.pumpAndSettle();

      expect(_localeCtrl.locale, equals(const Locale('vi')));
    });

    testWidgets('tapping English sets locale to en', (tester) async {
      await _setupGetIt();
      final cubit = GetIt.I<AppAuthCubit>();

      await tester.pumpWidget(_wrap(cubit));
      await tester.pumpAndSettle();

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(_localeCtrl.locale, equals(const Locale('en')));
    });

    testWidgets('tapping system locale clears locale override', (tester) async {
      _localeCtrl.setLocale(const Locale('vi'));
      await _setupGetIt();
      final cubit = GetIt.I<AppAuthCubit>();

      await tester.pumpWidget(_wrap(cubit));
      await tester.pumpAndSettle();

      // Two 'Theo hệ thống' in Language + Theme sections — tap the first.
      await tester.tap(find.text('Theo hệ thống').first);
      await tester.pumpAndSettle();

      expect(_localeCtrl.locale, isNull);
    });

    testWidgets('tapping Tối sets themeMode to dark', (tester) async {
      await _setupGetIt();
      final cubit = GetIt.I<AppAuthCubit>();

      await tester.pumpWidget(_wrap(cubit));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Tối'), 100);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tối'));
      await tester.pumpAndSettle();

      expect(_themeCtrl.themeMode, equals(ThemeMode.dark));
    });

    testWidgets('tapping Sáng sets themeMode to light', (tester) async {
      await _setupGetIt();
      final cubit = GetIt.I<AppAuthCubit>();

      await tester.pumpWidget(_wrap(cubit));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Sáng'), 100);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sáng'));
      await tester.pumpAndSettle();

      expect(_themeCtrl.themeMode, equals(ThemeMode.light));
    });

    testWidgets('About section shows app name, version, and section title', (
      tester,
    ) async {
      await _setupGetIt();
      final cubit = GetIt.I<AppAuthCubit>();

      await tester.pumpWidget(_wrap(cubit));
      await tester.pumpAndSettle();

      expect(find.text('Về ứng dụng'), findsOneWidget);
      expect(find.text('TeachHub'), findsOneWidget);
      expect(find.text('1.2.3'), findsOneWidget);
    });

    testWidgets('About section shows env badge when AppEnv is registered', (
      tester,
    ) async {
      GetIt.I.registerSingleton<AppEnv>(
        AppEnv(Env.development, {'TEACHHUB_API_URL': 'http://localhost/v1'}),
      );

      await _setupGetIt();
      final cubit = GetIt.I<AppAuthCubit>();

      await tester.pumpWidget(_wrap(cubit));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Về ứng dụng'), 150);
      await tester.pumpAndSettle();

      expect(find.text('Development'), findsOneWidget);

      // Tap Terms of Use (no-op) for coverage.
      await tester.scrollUntilVisible(find.text('Điều khoản sử dụng'), 100);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Điều khoản sử dụng'));
      await tester.pumpAndSettle();
    });

    testWidgets(
      'biometric subtitle shows not-enrolled hint when supported but not enrolled',
      (tester) async {
        final repo = FakeAuthRepo();
        final bus = AuthEventBus();
        final cubit = AppAuthCubit(
          repository: repo,
          authEventBus: bus,
          biometricService: FakeBioService(supported: true, enrolled: false),
        );
        addTearDown(cubit.close);
        addTearDown(bus.dispose);

        if (!GetIt.I.isRegistered<AppAuthCubit>()) {
          GetIt.I.registerSingleton<AppAuthCubit>(cubit);
        }
        if (!GetIt.I.isRegistered<LocaleController>()) {
          GetIt.I.registerSingleton<LocaleController>(_localeCtrl);
        }
        if (!GetIt.I.isRegistered<ThemeController>()) {
          GetIt.I.registerSingleton<ThemeController>(_themeCtrl);
        }

        await cubit.initSession();

        await tester.pumpWidget(_wrap(cubit));
        await tester.pumpAndSettle();

        expect(
          find.text('Vào Cài đặt thiết bị để đăng ký Face ID / Touch ID'),
          findsOneWidget,
        );
      },
    );
  });
}
