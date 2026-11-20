import 'package:app/core/theme/teachhub_theme.dart';
import 'package:app/features/auth/auth_cubit.dart';
import 'package:app/features/auth/pages/login_page.dart';
import 'package:app/features/auth/teachhub_user.dart';
import 'package:app/l10n/l10n.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasco_auth/tasco_auth.dart';
import 'package:tasco_core/tasco_core.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

/// Repository giả: `login` ném lỗi API dạng `{ code, details }` (spec §5.6).
class _Repo implements AuthRepository<TeachHubUser> {
  _Repo(this.loginError);
  final Map<String, Object?> loginError;

  @override
  Future<AuthResult<TeachHubUser>> login(Map<String, dynamic> c) async {
    final o = RequestOptions(path: '/auth/login');
    throw DioException(
      requestOptions: o,
      response: Response(requestOptions: o, statusCode: 401, data: loginError),
    );
  }

  @override
  Future<TeachHubUser> loginWithSso({
    required String providerId,
    required SsoResult ssoResult,
  }) async {
    final o = RequestOptions(path: '/auth/sso/$providerId');
    throw DioException(
      requestOptions: o,
      response: Response(
        requestOptions: o,
        statusCode: loginError['code'] == 'SERVICE_UNAVAILABLE' ? 503 : 401,
        data: loginError,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Future<List<String>> _pump(
  WidgetTester tester, {
  Map<String, Object?> loginError = const {'code': 'OTP_INVALID'},
}) async {
  final sent = <String>[];
  final themes = await tester.runAsync(TeachHubTheme.load);
  final cubit = AppAuthCubit(
    repository: _Repo(loginError),
    authEventBus: AuthEventBus(),
  );
  addTearDown(cubit.close);
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ScreenUtilPlusInit(
      designSize: const Size(393, 852),
      builder: (_, _) => MaterialApp(
        locale: const Locale('vi'),
        theme: themes!.light,
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          TascoUiKitLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AppAuthCubit>.value(
          value: cubit,
          child: LoginPage(
            sendOtp: (email) async => sent.add(email),
            google: _NoSso(),
            apple: const GenericSsoProvider(
              providerId: 'apple',
              onAuthenticate: _fakeSso,
            ),
            isIOS: true,
          ),
        ),
      ),
    ),
  );
  return sent;
}

Future<SsoResult> _fakeSso() async => const SsoResult(idToken: 't');

class _NoSso implements SsoProvider {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Finder _button(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(AppButton));

Future<void> _toOtp(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).first, 'co.lan@example.com');
  await tester.pump();
  await tester.tap(find.text('Gửi mã đăng nhập'));
  await tester.pumpAndSettle();
}

Future<void> _dispose(WidgetTester tester) =>
    tester.pumpWidget(const SizedBox()); // hủy timer đếm ngược

void main() {
  for (final (code, extra, message) in [
    ('SERVICE_UNAVAILABLE', <String, Object?>{}, 'Hệ thống đang bận'),
    (
      'UNAUTHENTICATED',
      {
        'details': {'reason': 'EMAIL_REQUIRES_OTP'},
      },
      'cần đăng nhập bằng mã OTP',
    ),
    ('UNAUTHENTICATED', <String, Object?>{}, 'Đăng nhập không thành công'),
  ]) {
    testWidgets(
      'Apple SSO lỗi $code ${extra.isEmpty ? '' : 'OTP'} → thông báo',
      (tester) async {
        await _pump(tester, loginError: {'code': code, ...extra});
        await tester.tap(find.text('Tiếp tục với Apple'));
        await tester.pumpAndSettle();
        expect(find.textContaining(message), findsOneWidget);
      },
    );
  }

  testWidgets(
    'T01 (B01): Apple, Google trước email; gửi mã tắt tới khi email hợp lệ',
    (tester) async {
      await _pump(tester);
      expect(find.text('Kết nối thầy, trò và gia đình.'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Tiếp tục với Apple')).dy,
        lessThan(tester.getTopLeft(find.text('Tiếp tục với Google')).dy),
      );
      expect(find.text('hoặc dùng email'), findsOneWidget);
      expect(
        tester.widget<AppButton>(_button('Gửi mã đăng nhập')).disabled,
        isTrue,
      );

      await tester.enterText(find.byType(TextField).first, 'ten@email');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      expect(
        find.text('Email chưa đúng định dạng, ví dụ: ten@gmail.com'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField).first, 'ten@email.com');
      await tester.pump();
      expect(
        tester.widget<AppButton>(_button('Gửi mã đăng nhập')).disabled,
        isFalse,
      );
    },
  );

  testWidgets('T01a (B02, B23): sai mã → ô đỏ và số lần còn lại', (
    tester,
  ) async {
    final sent = await _pump(
      tester,
      loginError: const {
        'code': 'OTP_INVALID',
        'details': {'attemptsLeft': 3},
      },
    );
    await _toOtp(tester);
    expect(sent, ['co.lan@example.com']);
    expect(find.text('Xác thực email'), findsOneWidget);
    expect(find.text('Mã 6 số đã gửi tới co.lan@example.com'), findsOneWidget);
    expect(find.text('Gửi lại mã sau 1:00'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '482918');
    await tester.pumpAndSettle();
    expect(find.text('Mã chưa đúng. Còn 3 lần thử.'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('T01a (B24): OTP_LOCKED → banner, đếm ngược, nút Tạm khóa', (
    tester,
  ) async {
    await _pump(
      tester,
      loginError: const {
        'code': 'OTP_LOCKED',
        'details': {'retryAfterSec': 900},
      },
    );
    await _toOtp(tester);
    await tester.enterText(find.byType(TextField).first, '111111');
    await tester.pumpAndSettle();
    expect(find.text('Nhập sai 5 lần'), findsOneWidget);
    expect(find.text('Thử lại sau 15:00'), findsOneWidget);
    expect(tester.widget<AppButton>(_button('Tạm khóa')).disabled, isTrue);
    expect(find.text('•'), findsNWidgets(6));
    await _dispose(tester);
  });
}
