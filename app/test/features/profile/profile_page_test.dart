import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/routing/app_routes.dart';
import 'package:app/data/model/user_model.dart';
import 'package:app/features/auth/auth_cubit.dart';
import 'package:app/features/profile/pages/profile_page.dart';
import 'package:app/l10n/l10n.dart';
import 'package:tasco_auth/tasco_auth.dart';
import 'package:tasco_core/tasco_core.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

class FakeAuthRepository implements AuthRepository<UserModel> {
  bool logoutCalled = false;
  bool setBiometricEnabledCalled = false;
  bool isBiometricEnabledValue = true;
  UserModel? user;

  @override
  Future<AuthResult<UserModel>> login(Map<String, dynamic> credentials) async =>
      AuthSuccess(user ?? const UserModel(id: '1', name: 'User'));

  @override
  Future<UserModel> loginWithSso({
    required String providerId,
    required SsoResult ssoResult,
  }) async => user ?? const UserModel(id: '1', name: 'User');

  @override
  Future<bool> isBiometricEnabled() async => isBiometricEnabledValue;

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    setBiometricEnabledCalled = true;
    isBiometricEnabledValue = enabled;
  }

  @override
  Future<UserModel?> cachedUser() async => user;

  @override
  Future<UserModel> getUserInfo() async =>
      user ?? const UserModel(id: '1', name: 'User');

  @override
  Future<bool> hasValidToken() async => user != null;

  @override
  Future<String?> refreshToken() async => null;

  @override
  Future<void> clearSession() async {}

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }
}

class FakeBiometricService implements BiometricService {
  bool isSupportedValue = true;
  bool canCheckValue = true;

  @override
  Future<bool> isDeviceSupported() async => isSupportedValue;

  @override
  Future<bool> canCheckBiometrics() async => canCheckValue;

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
  }) async => true;

  @override
  Future<bool> stopAuthentication() async => true;
}

Widget _wrap(Widget child, AppAuthCubit cubit, {GoRouter? router}) {
  final effectiveRouter =
      router ??
      GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(
            path: '/profile',
            builder: (ctx, s) =>
                BlocProvider<AppAuthCubit>.value(value: cubit, child: child),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (ctx, s) => const Scaffold(body: Text('Settings Page')),
          ),
        ],
      );
  return ScreenUtilPlusInit(
    designSize: const Size(393, 852),
    builder: (context, _) => MaterialApp.router(
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.v1,
      routerConfig: effectiveRouter,
    ),
  );
}

void main() {
  late FakeAuthRepository fakeRepo;
  late FakeBiometricService fakeBio;
  late AuthEventBus eventBus;
  late AppAuthCubit authCubit;

  setUp(() {
    fakeRepo = FakeAuthRepository();
    fakeBio = FakeBiometricService();
    eventBus = AuthEventBus();
    authCubit = AppAuthCubit(
      repository: fakeRepo,
      authEventBus: eventBus,
      biometricService: fakeBio,
    );
  });

  tearDown(() {
    authCubit.close();
    eventBus.dispose();
  });

  group('ProfilePage Widget Tests', () {
    testWidgets('renders user information, username and permissions', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeRepo.user = UserModel(
        id: 'u100',
        username: 'thanhdx',
        name: 'Đào Xuân Thanh',
        role: 'Admin Manager',
        permissionItems: [
          const PermissionItem(
            name: 'Quản lý đơn',
            uri: '/cop/crm/order',
            type: 'MENU',
          ),
          const PermissionItem(name: 'users.manage'),
        ],
      );
      await authCubit.initSession();

      await tester.pumpWidget(_wrap(const ProfilePage(), authCubit));
      await tester.pumpAndSettle();

      expect(find.text('Đào Xuân Thanh'), findsOneWidget);
      expect(find.text('Tên đăng nhập: thanhdx'), findsOneWidget);
      expect(find.text('Vai trò: Admin Manager'), findsOneWidget);
      expect(find.text('2 quyền'), findsOneWidget);
      expect(find.text('Quản lý đơn'), findsOneWidget);
      expect(find.text('MENU'), findsOneWidget);
      expect(find.text('/cop/crm/order'), findsOneWidget);
      expect(find.text('USERS.MANAGE'), findsOneWidget);
      // Biometric moved to SettingsPage — not rendered in ProfilePage.
      expect(find.text('Bảo mật & Xác thực'), findsNothing);
      // Settings tile present.
      expect(find.text('Cài đặt'), findsOneWidget);
    });

    testWidgets('expands and collapses permissions when exceeding 8 items', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final perms = List.generate(12, (i) => 'perm_$i');
      fakeRepo.user = UserModel.withPermissions(
        id: 'u100',
        username: 'thanhdx',
        name: 'Đào Xuân Thanh',
        permissions: perms,
      );
      await authCubit.initSession();

      await tester.pumpWidget(_wrap(const ProfilePage(), authCubit));
      await tester.pumpAndSettle();

      expect(find.text('12 quyền'), findsOneWidget);
      expect(find.text('Xem thêm (4 quyền) ▼'), findsOneWidget);
      expect(find.text('PERM_0'), findsOneWidget);
      expect(find.text('PERM_11'), findsNothing);

      await tester.tap(find.text('Xem thêm (4 quyền) ▼'));
      await tester.pumpAndSettle();

      expect(find.text('PERM_11'), findsOneWidget);
      expect(find.text('Thu gọn ▲'), findsOneWidget);

      await tester.tap(find.text('Thu gọn ▲'));
      await tester.pumpAndSettle();

      expect(find.text('Xem thêm (4 quyền) ▼'), findsOneWidget);
    });

    testWidgets('renders standard user badge when permissions is empty', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeRepo.user = const UserModel(id: 'u100', name: 'User');
      await authCubit.initSession();

      await tester.pumpWidget(_wrap(const ProfilePage(), authCubit));
      await tester.pumpAndSettle();

      expect(find.text('QUYỀN NGƯỜI DÙNG TIÊU CHUẨN'), findsOneWidget);
    });

    testWidgets('tapping logout button calls authCubit.logout', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeRepo.user = const UserModel(id: 'u100', name: 'User');
      await authCubit.initSession();

      await tester.pumpWidget(_wrap(const ProfilePage(), authCubit));
      await tester.pumpAndSettle();

      final logoutBtn = find.widgetWithText(AppButton, 'Đăng xuất');
      expect(logoutBtn, findsOneWidget);

      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      expect(fakeRepo.logoutCalled, isTrue);
    });

    testWidgets('tapping Settings tile navigates to /settings', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeRepo.user = const UserModel(id: 'u100', name: 'User');
      await authCubit.initSession();

      await tester.pumpWidget(_wrap(const ProfilePage(), authCubit));
      await tester.pumpAndSettle();

      final settingsTile = find.text('Cài đặt');
      expect(settingsTile, findsOneWidget);

      await tester.tap(settingsTile);
      await tester.pumpAndSettle();

      // GoRouter pushed /settings — SettingsPage stub renders.
      expect(find.text('Settings Page'), findsOneWidget);
    });
  });
}
