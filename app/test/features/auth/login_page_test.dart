import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/data/model/user_model.dart';
import 'package:app/features/auth/auth_cubit.dart';
import 'package:app/features/auth/pages/login_page.dart';
import 'package:app/l10n/l10n.dart';
import 'package:tasco_auth/tasco_auth.dart';
import 'package:tasco_core/tasco_core.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

class FakeAuthRepository implements AuthRepository<UserModel> {
  bool loginCalled = false;
  Map<String, dynamic>? lastCredentials;
  bool ssoCalled = false;
  bool setBiometricEnabledCalled = false;
  bool isBiometricEnabledValue = false;
  UserModel? returnUser;
  Object? throwError;

  /// When set, login waits for it, so a test can look at the page mid-request.
  Completer<void>? loginGate;

  @override
  Future<AuthResult<UserModel>> login(Map<String, dynamic> credentials) async {
    loginCalled = true;
    lastCredentials = credentials;
    await loginGate?.future;
    if (throwError != null) throw throwError!;
    return AuthSuccess(
      returnUser ?? const UserModel(id: '1', name: 'Test User'),
    );
  }

  @override
  Future<UserModel> loginWithSso({
    required String providerId,
    required SsoResult ssoResult,
  }) async {
    ssoCalled = true;
    if (throwError != null) throw throwError!;
    return returnUser ??
        UserModel(id: '1', name: ssoResult.extra['name'] ?? 'SSO User');
  }

  @override
  Future<bool> isBiometricEnabled() async => isBiometricEnabledValue;

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    setBiometricEnabledCalled = true;
    isBiometricEnabledValue = enabled;
  }

  @override
  Future<UserModel?> cachedUser() async => null;

  @override
  Future<UserModel> getUserInfo() async =>
      returnUser ?? const UserModel(id: '1', name: 'Test User');

  @override
  Future<bool> hasValidToken() async => false;

  @override
  Future<String?> refreshToken() async => null;

  @override
  Future<void> clearSession() async {}

  @override
  Future<void> logout() async {}
}

class FakeBiometricService implements BiometricService {
  bool authenticateCalled = false;
  bool isSupportedValue = true;
  bool canCheckValue = true;
  bool authResult = true;

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
  }) async {
    authenticateCalled = true;
    return authResult;
  }

  @override
  Future<bool> stopAuthentication() async => true;
}

/// The page with a body builder that marks its own output, so a test can tell
/// the page sent what the router's builder produced and nothing of its own.
LoginPage _loginPage() => LoginPage(
  credentials: ({required username, required password}) => {
    'user': username,
    'secret': password,
    'builtBy': 'router',
  },
);

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

  group('LoginPage Widget Tests', () {
    testWidgets('renders login form with username, password and SSO buttons', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(_loginPage(), authCubit));
      await tester.pumpAndSettle();

      expect(find.text('Chào mừng trở lại! 👋'), findsOneWidget);
      expect(find.byType(AppSvgIcon), findsWidgets);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.widgetWithText(AppButton, 'Đăng nhập'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Google'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Apple'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Corporate SSO'), findsOneWidget);
    });

    testWidgets('submits username and password when login pressed', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(_loginPage(), authCubit));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'testuser');
      await tester.enterText(textFields.at(1), 'password123');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(AppButton, 'Đăng nhập'));
      await tester.pumpAndSettle();

      expect(fakeRepo.loginCalled, isTrue);
    });

    Future<void> pumpLoginPage(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(_loginPage(), authCubit));
      await tester.pumpAndSettle();
    }

    testWidgets('does not sign in with empty fields and says which are '
        'missing', (tester) async {
      await pumpLoginPage(tester);

      await tester.tap(find.widgetWithText(AppButton, 'Đăng nhập'));
      await tester.pumpAndSettle();

      final l10n = lookupAppLocalizations(const Locale('vi'));
      expect(fakeRepo.loginCalled, isFalse);
      expect(find.text(l10n.loginUsernameRequired), findsOneWidget);
      expect(find.text(l10n.loginPasswordRequired), findsOneWidget);
    });

    testWidgets('does not sign in with a blank username', (tester) async {
      await pumpLoginPage(tester);

      // The page trims the username it sends, so blank is empty.
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '   ');
      await tester.enterText(textFields.at(1), 'password123');
      await tester.tap(find.widgetWithText(AppButton, 'Đăng nhập'));
      await tester.pumpAndSettle();

      final l10n = lookupAppLocalizations(const Locale('vi'));
      expect(fakeRepo.loginCalled, isFalse);
      expect(find.text(l10n.loginUsernameRequired), findsOneWidget);
      expect(find.text(l10n.loginPasswordRequired), findsNothing);
    });

    testWidgets('clears each error as its field is filled in, then signs in', (
      tester,
    ) async {
      await pumpLoginPage(tester);
      await tester.tap(find.widgetWithText(AppButton, 'Đăng nhập'));
      await tester.pumpAndSettle();

      final l10n = lookupAppLocalizations(const Locale('vi'));
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'testuser');
      await tester.pump();
      expect(find.text(l10n.loginUsernameRequired), findsNothing);
      expect(find.text(l10n.loginPasswordRequired), findsOneWidget);

      await tester.enterText(textFields.at(1), 'password123');
      await tester.pump();
      expect(find.text(l10n.loginPasswordRequired), findsNothing);

      await tester.tap(find.widgetWithText(AppButton, 'Đăng nhập'));
      await tester.pumpAndSettle();
      expect(fakeRepo.loginCalled, isTrue);
    });

    testWidgets('signs in with the body the injected builder makes from the '
        'typed credentials', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(_loginPage(), authCubit));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '  testuser  ');
      await tester.enterText(textFields.at(1), ' password123 ');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(AppButton, 'Đăng nhập'));
      await tester.pumpAndSettle();

      // Device and client fields are the builder's business; the page adds
      // none of its own. The username is trimmed, the password is not.
      expect(fakeRepo.lastCredentials, {
        'user': 'testuser',
        'secret': ' password123 ',
        'builtBy': 'router',
      });
    });

    testWidgets('disables both fields while signing in, and enables them '
        'again after', (tester) async {
      await pumpLoginPage(tester);
      fakeRepo.loginGate = Completer<void>();
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'testuser');
      await tester.enterText(textFields.at(1), 'password123');

      await tester.tap(find.widgetWithText(AppButton, 'Đăng nhập'));
      await tester.pump();

      expect(tester.widget<TextField>(textFields.at(0)).enabled, isFalse);
      expect(tester.widget<TextField>(textFields.at(1)).enabled, isFalse);

      fakeRepo.throwError = Exception('rejected');
      fakeRepo.loginGate!.complete();
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(textFields.at(0)).enabled, isTrue);
      expect(tester.widget<TextField>(textFields.at(1)).enabled, isTrue);
    });

    testWidgets('the keyboard moves from username to password, and Done signs '
        'in', (tester) async {
      await pumpLoginPage(tester);
      final textFields = find.byType(TextField);

      await tester.enterText(textFields.at(0), 'testuser');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(
        tester.widget<TextField>(textFields.at(1)).focusNode!.hasFocus,
        isTrue,
      );

      await tester.enterText(textFields.at(1), 'password123');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(fakeRepo.loginCalled, isTrue);
    });

    testWidgets('offers the pair to autofill and password managers', (
      tester,
    ) async {
      await pumpLoginPage(tester);
      final textFields = find.byType(TextField);

      expect(tester.widget<TextField>(textFields.at(0)).autofillHints, [
        AutofillHints.username,
      ]);
      expect(tester.widget<TextField>(textFields.at(1)).autofillHints, [
        AutofillHints.password,
      ]);
      expect(
        find.ancestor(
          of: textFields.at(0),
          matching: find.byType(AutofillGroup),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'shows Biometric button when enabled and triggers biometric unlock',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        fakeRepo.isBiometricEnabledValue = true;
        await authCubit.initSession();

        await tester.pumpWidget(_wrap(_loginPage(), authCubit));
        await tester.pumpAndSettle();

        final bioBtn = find.widgetWithText(
          AppButton,
          'Đăng nhập bằng Sinh trắc học',
        );
        expect(bioBtn, findsOneWidget);

        await tester.tap(bioBtn);
        await tester.pumpAndSettle();

        expect(fakeBio.authenticateCalled, isTrue);
      },
    );

    testWidgets(
      'triggers SSO login when Google, Apple, and Corporate SSO buttons are tapped',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_wrap(_loginPage(), authCubit));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(AppButton, 'Google'));
        await tester.pumpAndSettle();
        expect(fakeRepo.ssoCalled, isTrue);

        fakeRepo.ssoCalled = false;
        await tester.tap(find.widgetWithText(AppButton, 'Apple'));
        await tester.pumpAndSettle();
        expect(fakeRepo.ssoCalled, isTrue);

        fakeRepo.ssoCalled = false;
        await tester.tap(find.widgetWithText(AppButton, 'Corporate SSO'));
        await tester.pumpAndSettle();
        expect(fakeRepo.ssoCalled, isTrue);
      },
    );

    testWidgets('pops when leading back button is tapped', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ScreenUtilPlusInit(
          designSize: const Size(393, 852),
          builder: (context, _) => MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.v1,
            home: Navigator(
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                BlocProvider<AppAuthCubit>.value(
                                  value: authCubit,
                                  child: _loginPage(),
                                ),
                          ),
                        );
                      },
                      child: const Text('Open Login'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Login'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);

      final backBtn = find.byWidgetPredicate(
        (w) => w is AppSvgIcon && w.assetPath == AppIcons.arrowLeft,
      );
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsNothing);
    });

    testWidgets('toggles password visibility icon', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(_loginPage(), authCubit));
      await tester.pumpAndSettle();

      final visibilityBtn = find.byWidgetPredicate(
        (w) => w is AppSvgIcon && w.assetPath == AppIcons.eyeSlash,
      );
      expect(visibilityBtn, findsOneWidget);

      await tester.tap(visibilityBtn);
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => w is AppSvgIcon && w.assetPath == AppIcons.eye,
        ),
        findsOneWidget,
      );
    });

    Future<void> submitFailingLogin(WidgetTester tester, Object error) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeRepo.throwError = error;

      await tester.pumpWidget(_wrap(_loginPage(), authCubit));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'testuser');
      await tester.enterText(textFields.at(1), 'wrongpassword');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(AppButton, 'Đăng nhập'));
      await tester.pumpAndSettle();
    }

    testWidgets('displays localized error SnackBar when login fails', (
      tester,
    ) async {
      await submitFailingLogin(tester, Exception('Invalid credentials'));

      final l10n = lookupAppLocalizations(const Locale('vi'));
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text(l10n.loginFailed), findsOneWidget);
      expect(find.textContaining('Invalid credentials'), findsNothing);
    });

    testWidgets('tells the user to check the connection when the server '
        'cannot be reached', (tester) async {
      await submitFailingLogin(
        tester,
        DioException.connectionError(
          requestOptions: RequestOptions(path: '/auth/login'),
          reason: 'Connection refused',
        ),
      );

      final l10n = lookupAppLocalizations(const Locale('vi'));
      expect(find.text(l10n.loginNetworkError), findsOneWidget);
      expect(find.textContaining('DioException'), findsNothing);
      expect(find.textContaining('Connection refused'), findsNothing);
    });
  });
}
