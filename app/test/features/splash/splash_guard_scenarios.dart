// S1-FL-04: 3 nhánh của splash + guard, chạy trên GoRouter thật của shell
// (`buildAppRouter`) với Cubit giả. Dùng chung cho widget test
// (test/features/splash/splash_guard_test.dart) và integration test trên máy
// (integration_test/splash_guard_test.dart).
import 'package:app/core/routing/app_router.dart';
import 'package:app/core/routing/app_routes.dart';
import 'package:app/features/auth/auth_cubit.dart';
import 'package:app/features/auth/teachhub_user.dart';
import 'package:app/features/consent/consent_cubit.dart';
import 'package:app/features/consent/consent_page.dart';
import 'package:app/features/role_picker/membership_cubit.dart';
import 'package:app/features/role_picker/role_picker_page.dart';
import 'package:app/features/splash/splash_page.dart';
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
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:tasco_utils/tasco_utils.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

const _user = TeachHubUser(id: 'u1', email: 'a@b.vn');
const _teacher = Membership(
  id: 'm-t',
  role: MembershipRole.tenantOwner,
  label: 'Giáo viên',
);

const _parent = Membership(
  id: 'm-p',
  role: MembershipRole.parent,
  label: 'Phụ huynh',
);

class _NoRepo implements AuthRepository<TeachHubUser> {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Cubit phiên giả: chỉ phát trạng thái, không gọi repository.
class _Auth extends AppAuthCubit {
  _Auth() : super(repository: _NoRepo(), authEventBus: AuthEventBus());
  void set(AppAuthState s) => emit(s);
}

class _Memberships extends MembershipCubit {
  _Memberships(SharedPreferences prefs)
    : super(api: Dio(), prefs: prefs, activeMembership: ActiveMembership(null));
  void set(MembershipState s) => emit(s);
  @override
  Future<void> load({bool silent = false}) async {}
}

ModuleSlot _slot(String id, String prefix) => ModuleSlot(
  moduleId: id,
  routePrefix: prefix,
  notificationTypes: const {},
  init: () async {},
  routes: () => [
    GoRoute(path: prefix, builder: (_, _) => Text('mini-app $id')),
  ],
  onNotification: (_, _) async {},
  dispose: () async {},
);

void defineSplashGuardTests() {
  late _Auth auth;
  late _Memberships memberships;
  late ConsentCubit consent;
  final consentCalls = <String>[];

  Future<GoRouter> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    auth = _Auth();
    memberships = _Memberships(await SharedPreferences.getInstance());
    addTearDown(auth.close);
    addTearDown(memberships.close);
    // Các kịch bản splash không xét đồng ý: coi như đã đồng ý.
    consentCalls.clear();
    consent = ConsentCubit(
      Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (o, h) {
              consentCalls.add('${o.method} ${o.path}');
              h.resolve(Response(requestOptions: o, statusCode: 201));
            },
          ),
        ),
    )..markAccepted();
    addTearDown(consent.close);
    final manager = ModuleManager()
      ..register(_slot('teacher', TeachHubRoutes.teacher))
      ..register(_slot('parent', TeachHubRoutes.parent))
      ..register(_slot('student', TeachHubRoutes.student));
    await manager.initAll();
    final router = buildAppRouter(
      moduleManager: manager,
      authCubit: auth,
      membershipCubit: memberships,
      consentCubit: consent,
      loginPage: () => const Text('màn đăng nhập'),
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
    return router;
  }

  testWidgets('chưa đăng nhập: splash rồi về màn đăng nhập', (tester) async {
    final router = await pump(tester);
    // Đang kiểm phiên: ở splash.
    expect(find.byType(SplashPage), findsOneWidget);

    auth.set(
      AppAuthState.initial().copyWith(statusCheckToken: LoadingStatus.failure),
    );
    await tester.pumpAndSettle();
    expect(find.text('màn đăng nhập'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.login);
  });

  testWidgets('đăng nhập nhưng chưa có vai trò: màn chọn vai trò', (
    tester,
  ) async {
    final router = await pump(tester);
    auth.set(
      AppAuthState.initial().copyWith(
        statusCheckToken: LoadingStatus.success,
        user: _user,
      ),
    );
    memberships.set(const MembershipState(statusLoad: LoadingStatus.loading));
    await tester.pumpAndSettle();
    expect(find.byType(SplashPage), findsOneWidget); // chờ tải vai trò

    memberships.set(const MembershipState(statusLoad: LoadingStatus.success));
    await tester.pumpAndSettle();
    expect(find.byType(RolePickerPage), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.rolePicker,
    );
  });

  testWidgets('đã có vai trò: vào đúng mini-app của vai trò đang mở', (
    tester,
  ) async {
    final router = await pump(tester);
    auth.set(
      AppAuthState.initial().copyWith(
        statusCheckToken: LoadingStatus.success,
        user: _user,
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
    expect(
      router.routeInformationProvider.value.uri.path,
      TeachHubRoutes.teacher,
    );
  });

  testWidgets(
    'Phụ huynh: 403 CONSENT_REQUIRED giữa phiên đưa về màn đồng ý, đồng ý xong về /p',
    (tester) async {
      final router = await pump(tester);
      auth.set(
        AppAuthState.initial().copyWith(
          statusCheckToken: LoadingStatus.success,
          user: _user,
        ),
      );
      memberships.set(
        const MembershipState(
          statusLoad: LoadingStatus.success,
          memberships: [_parent],
          active: _parent,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('mini-app parent'), findsOneWidget);

      consent.markRequired('2026-12-01');
      await tester.pumpAndSettle();
      expect(find.byType(ConsentPage), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.consent);

      await tester.tap(find.text('Đồng ý và tiếp tục'));
      await tester.pumpAndSettle();
      expect(consentCalls, ['POST /consents']);
      expect(find.text('mini-app parent'), findsOneWidget);
      expect(
        router.routeInformationProvider.value.uri.path,
        TeachHubRoutes.parent,
      );
    },
  );
}
