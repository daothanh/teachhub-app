// S1-FL-05: đăng nhập → đăng xuất về T01, và refresh token bị thu hồi → app tự
// về T01 và xóa phiên. Chạy trên GoRouter thật của shell, `AuthCubit` thật,
// `DioAuthRepository` + `AuthInterceptor` + `TokenRefresher` thật, nói chuyện
// với một API giả có trạng thái (token, thu hồi refresh) qua `HttpClientAdapter`.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:app/core/routing/app_router.dart';
import 'package:app/core/routing/app_routes.dart';
import 'package:app/features/auth/auth_config.dart';
import 'package:app/features/auth/auth_cubit.dart';
import 'package:app/features/auth/logout_service.dart';
import 'package:app/features/auth/teachhub_user.dart';
import 'package:app/features/consent/consent_cubit.dart';
import 'package:app/features/role_picker/membership_cubit.dart';
import 'package:app/l10n/l10n.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasco_auth/tasco_auth.dart';
import 'package:tasco_core/tasco_core.dart';
import 'package:tasco_module/tasco_module.dart';
import 'package:tasco_storage/tasco_storage.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:tasco_utils/tasco_utils.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

const _teacher = Membership(
  id: 'm-t',
  role: MembershipRole.tenantOwner,
  label: 'Giáo viên',
);

/// API giả: cấp token khi đăng nhập, xoay refresh token, và cho thu hồi.
class _Api implements HttpClientAdapter {
  int _n = 0;
  String? access;
  String? refresh;
  final requests = <String>[];

  static ResponseBody _json(int status, [Object? body]) =>
      ResponseBody.fromString(
        jsonEncode(body ?? {}),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  Map<String, Object?> _tokens() {
    _n++;
    access = 'access-$_n';
    refresh = 'refresh-$_n';
    return {
      'access_token': access,
      'refresh_token': refresh,
      'expires_in': 900,
    };
  }

  /// Server thu hồi mọi phiên của người dùng (đổi mật khẩu, quản trị khóa).
  void revokeAll() {
    access = null;
    refresh = null;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? body,
    Future<void>? cancel,
  ) async {
    requests.add('${o.method} ${o.path}');
    final bearer = o.headers['Authorization'];
    final authed = access != null && bearer == 'Bearer $access';
    switch ('${o.method} ${o.path}') {
      case 'POST /auth/login':
        return _json(200, {
          ..._tokens(),
          'user': {
            'id': 'u1',
            'email': 'co.lan@example.com',
            'permissions': ['role:tenant_owner'],
          },
        });
      case 'POST /auth/refresh':
        final sent = (o.data as Map)['refresh_token'];
        if (refresh == null || sent != refresh) return _json(401);
        return _json(200, _tokens());
      case 'POST /auth/logout':
        if (!authed) return _json(401);
        revokeAll();
        return _json(204);
      case 'GET /auth/me':
        return authed
            ? _json(200, {
                'id': 'u1',
                'email': 'co.lan@example.com',
                'permissions': ['role:tenant_owner'],
              })
            : _json(401);
      case 'GET /me/ping':
        return authed ? _json(200) : _json(401);
    }
    return _json(404);
  }

  @override
  void close({bool force = false}) {}
}

class _Memberships extends MembershipCubit {
  _Memberships(SharedPreferences prefs)
    : super(api: Dio(), prefs: prefs, activeMembership: ActiveMembership(null));
  void set(MembershipState s) => emit(s);
  @override
  Future<void> load({bool silent = false}) async {}
}

ModuleSlot _teacherSlot() => ModuleSlot(
  moduleId: 'teacher',
  routePrefix: TeachHubRoutes.teacher,
  notificationTypes: const {},
  init: () async {},
  routes: () => [
    GoRoute(
      path: TeachHubRoutes.teacher,
      builder: (_, _) => const Text('mini-app teacher'),
    ),
  ],
  onNotification: (_, _) async {},
  dispose: () async {},
);

void main() {
  late _Api api;
  late Dio dio;
  late TokenStore tokens;
  late AuthEventBus bus;
  late AppAuthCubit auth;
  late DioAuthRepository<TeachHubUser> repo;
  late _Memberships memberships;
  late LogoutService logoutService;
  late GoRouter router;
  var wipes = 0;

  String path() => router.routeInformationProvider.value.uri.path;

  /// Dựng đúng chuỗi của `bootstrap`: repository thật, interceptor làm mới
  /// token, `LogoutService` nghe `sessionExpired`; kết thúc ở T01 (chưa phiên).
  Future<void> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    wipes = 0;
    api = _Api();
    bus = AuthEventBus();
    tokens = TokenStore(InMemoryKeyValueStore());
    final refresher = TokenRefresher(
      refresh: () => repo.refreshToken(),
      authEventBus: bus,
    );
    final interceptor = AuthInterceptor(
      tokens.getAccessToken,
      () => refresher,
      retryClient: AuthInterceptor.buildRetryClient(adapter: api),
      authEventBus: bus,
    );
    dio = Dio(BaseOptions(baseUrl: 'https://api.test/v1'))
      ..httpClientAdapter = api
      ..interceptors.add(interceptor);
    repo = DioAuthRepository<TeachHubUser>(
      dio: dio,
      tokenStore: tokens,
      config: teachHubAuthConfig,
    );
    auth = AppAuthCubit(repository: repo, authEventBus: bus);
    logoutService = LogoutService(
      logout: auth.logout,
      pendingCount: () async => 0,
      wipeLocalData: () async => wipes++,
    );
    final sub = bus.stream
        .where((e) => e == AuthEvent.sessionExpired)
        .listen((_) => unawaited(logoutService.onSessionExpired()));
    memberships = _Memberships(await SharedPreferences.getInstance());
    final consent = ConsentCubit(Dio())..markAccepted();
    addTearDown(() async {
      await sub.cancel();
      await auth.close();
      await memberships.close();
      await consent.close();
      bus.dispose();
    });
    final manager = ModuleManager()..register(_teacherSlot());
    await manager.initAll();
    router = buildAppRouter(
      moduleManager: manager,
      authCubit: auth,
      membershipCubit: memberships,
      consentCubit: consent,
      loginPage: () => const Text('T01'),
      inviteCubit: (_) => throw UnimplementedError(),
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<MembershipCubit>.value(value: memberships),
          BlocProvider<AppAuthCubit>.value(value: auth),
        ],
        child: ScreenUtilPlusInit(
          designSize: const Size(393, 852),
          builder: (_, _) => MaterialApp.router(
            locale: const Locale('vi'),
            theme: AppTheme.v1,
            localizationsDelegates: const [
              ...AppLocalizations.localizationsDelegates,
              TascoUiKitLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.runAsync(auth.initSession); // không có token → T01
    await tester.pumpAndSettle();
    expect(find.text('T01'), findsOneWidget);
  }

  /// OTP đúng → vào mini-app của vai trò đang mở.
  Future<void> signIn(WidgetTester tester) async {
    await tester.runAsync(
      () => auth.login(
        emailOtpCredentials(email: 'co.lan@example.com', code: '482918'),
      ),
    );
    memberships.set(
      const MembershipState(
        statusLoad: LoadingStatus.success,
        memberships: [_teacher],
        active: _teacher,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('mini-app teacher'), findsOneWidget);
    expect(await tester.runAsync(tokens.getAccessToken), api.access);
  }

  testWidgets('đăng nhập → đăng xuất: về T01, token bị xóa, server thu hồi, '
      'CSDL cục bộ được xóa', (tester) async {
    await pump(tester);
    await signIn(tester);

    final result = await tester.runAsync(
      () => logoutService.logout(confirmDiscard: (_) async => true),
    );
    await tester.pumpAndSettle();

    expect(result, LogoutResult.done);
    expect(api.requests, contains('POST /auth/logout'));
    expect(api.refresh, isNull, reason: 'server đã thu hồi phiên');
    expect(find.text('T01'), findsOneWidget);
    expect(path(), AppRoutes.login);
    expect(auth.state.user, isNull);
    expect(await tester.runAsync(tokens.getAccessToken), isNull);
    expect(await tester.runAsync(tokens.getRefreshToken), isNull);
    expect(wipes, 1);
  });

  testWidgets(
    'refresh token bị thu hồi: lần gọi API kế tiếp (401, refresh 401) '
    'tự về T01, xóa phiên',
    (tester) async {
      await pump(tester);
      await signIn(tester);

      api.revokeAll();
      final status = await tester.runAsync(
        () => dio
            .get<void>('/me/ping')
            .then<int?>(
              (_) => null,
              onError: (Object e) => (e as DioException).response?.statusCode,
            ),
      );
      expect(status, 401);
      await tester.pumpAndSettle();

      expect(
        api.requests,
        containsAllInOrder(['GET /me/ping', 'POST /auth/refresh']),
      );
      expect(find.text('T01'), findsOneWidget);
      expect(path(), AppRoutes.login);
      expect(auth.state.user, isNull);
      expect(auth.state.statusRefreshToken, LoadingStatus.failure);
      expect(await tester.runAsync(tokens.getAccessToken), isNull);
      expect(await tester.runAsync(tokens.getRefreshToken), isNull);
      expect(wipes, 1, reason: 'outbox trống: xóa CSDL cục bộ như đăng xuất');
    },
  );

  testWidgets('access token hết hạn nhưng refresh còn: làm mới và ở lại', (
    tester,
  ) async {
    await pump(tester);
    await signIn(tester);

    // Access cũ không còn hợp lệ, refresh vẫn đúng.
    final old = api.access;
    api.access = 'het-han';
    api.refresh = 'refresh-1';
    await tester.runAsync(() => dio.get<void>('/me/ping'));
    await tester.pumpAndSettle();

    expect(api.access, isNot(old));
    expect(find.text('mini-app teacher'), findsOneWidget);
    expect(auth.state.user, isNotNull);
  });
}
