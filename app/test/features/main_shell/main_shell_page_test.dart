import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/data/model/user_model.dart';
import 'package:app/features/auth/auth_cubit.dart';
import 'package:app/features/main_shell/main_shell_page.dart';
import 'package:app/features/profile/pages/profile_page.dart';
import 'package:app/l10n/l10n.dart';
import 'package:tasco_auth/tasco_auth.dart';
import 'package:tasco_core/tasco_core.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

class FakeAuthRepository implements AuthRepository<UserModel> {
  @override
  Future<AuthResult<UserModel>> login(Map<String, dynamic> credentials) async =>
      const AuthSuccess(UserModel(id: '1', name: 'User'));

  @override
  Future<UserModel> loginWithSso({
    required String providerId,
    required SsoResult ssoResult,
  }) async => const UserModel(id: '1', name: 'User');

  @override
  Future<bool> isBiometricEnabled() async => false;

  @override
  Future<void> setBiometricEnabled(bool enabled) async {}

  @override
  Future<UserModel?> cachedUser() async => null;

  @override
  Future<UserModel> getUserInfo() async =>
      const UserModel(id: '1', name: 'User');

  @override
  Future<bool> hasValidToken() async => true;

  @override
  Future<String?> refreshToken() async => null;

  @override
  Future<void> clearSession() async {}

  @override
  Future<void> logout() async {}
}

Widget _wrap(Widget child, AppAuthCubit cubit) {
  return ScreenUtilPlusInit(
    designSize: const Size(393, 852),
    builder: (context, _) => MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.v1,
      home: BlocProvider<AppAuthCubit>.value(value: cubit, child: child),
    ),
  );
}

void main() {
  late FakeAuthRepository fakeRepo;
  late AuthEventBus eventBus;
  late AppAuthCubit authCubit;

  setUp(() {
    fakeRepo = FakeAuthRepository();
    eventBus = AuthEventBus();
    authCubit = AppAuthCubit(repository: fakeRepo, authEventBus: eventBus);
  });

  tearDown(() {
    authCubit.close();
    eventBus.dispose();
  });

  group('MainShellPage Widget Tests', () {
    testWidgets(
      'renders AppMainShell with tabs and can navigate to Profile tab',
      (tester) async {
        tester.view.physicalSize = const Size(393, 852);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await authCubit.initSession();

        await tester.pumpWidget(_wrap(const MainShellPage(), authCubit));
        await tester.pumpAndSettle();

        expect(find.text('Trang chủ'), findsOneWidget);
        expect(find.text('Khám phá'), findsOneWidget);
        expect(find.text('Thông báo'), findsOneWidget);
        expect(find.text('Cá nhân'), findsOneWidget);

        await tester.tap(find.text('Cá nhân'));
        await tester.pumpAndSettle();

        expect(find.byType(ProfilePage), findsOneWidget);
      },
    );
    testWidgets(
      'didUpdateWidget switches tab when initialTab changes',
      (tester) async {
        tester.view.physicalSize = const Size(393, 852);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await authCubit.initSession();

        int tab = 0;
        late StateSetter outerSetState;

        await tester.pumpWidget(
          ScreenUtilPlusInit(
            designSize: const Size(393, 852),
            builder: (context, _) => MaterialApp(
              locale: const Locale('vi'),
              localizationsDelegates:
                  AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: AppTheme.v1,
              home: BlocProvider<AppAuthCubit>.value(
                value: authCubit,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    outerSetState = setState;
                    return MainShellPage(initialTab: tab);
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Starts on tab 0 (Home)
        expect(find.text('Trang chủ'), findsOneWidget);

        // Change to Profile tab externally
        outerSetState(() => tab = 3);
        await tester.pumpAndSettle();

        expect(find.byType(ProfilePage), findsOneWidget);
      },
    );
  });
}
