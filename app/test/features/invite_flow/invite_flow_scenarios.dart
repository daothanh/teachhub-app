// S4-FL-11: luồng C (mời → nhận → đồng ý → P02) chạy trên GoRouter thật của
// shell, mini-app parent thật, `InviteCubit`/`InviteEntryCubit`/`ConsentCubit`/
// `MembershipCubit` thật, nói chuyện với một API giả có trạng thái
// (`_InviteBackend`). Giáo viên tạo lời mời bằng `InviteLinkCubit` thật của
// mini-app teacher; phụ huynh nhận bằng link (T01→thẻ lời mời) hoặc nhập mã
// (P05). Chưa đồng ý điều khoản thì API trả 403 `CONSENT_REQUIRED` như thật.
// Cùng kiểu với billing_flow_scenarios: dùng cho `flutter test` (CI).
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:app/core/routing/app_router.dart';
import 'package:app/core/routing/app_routes.dart';
import 'package:app/features/auth/auth_cubit.dart';
import 'package:app/features/auth/teachhub_user.dart';
import 'package:app/features/consent/consent_cubit.dart';
import 'package:app/features/invite/invite_cubit.dart';
import 'package:app/features/invite/invite_entry_cubit.dart';
import 'package:app/features/invite/invite_entry_view.dart';
import 'package:app/features/invite/invite_input.dart';
import 'package:app/features/invite/invite_repository.dart';
import 'package:app/features/role_picker/membership_cubit.dart';
import 'package:app/l10n/l10n.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:parent/parent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasco_auth/tasco_auth.dart';
import 'package:tasco_core/tasco_core.dart';
import 'package:tasco_module/tasco_module.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:tasco_utils/tasco_utils.dart';
import 'package:teacher/features/classes/data/class_models.dart';
import 'package:teacher/features/invites/cubit/invite_link_cubit.dart';
import 'package:teacher/features/invites/data/invite_models.dart';
import 'package:teacher/features/invites/data/invite_repository.dart'
    as teacher;
import 'package:teachhub_shared/teachhub_shared.dart';

const _user = TeachHubUser(id: 'u1', email: 'phuhuynh@example.com');
const _studentName = 'Nguyễn Minh Anh';
const _teacherName = 'Cô Lan';

class _NoRepo implements AuthRepository<TeachHubUser> {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Cubit phiên giả: chỉ phát trạng thái, không gọi repository.
class _Auth extends AppAuthCubit {
  _Auth() : super(repository: _NoRepo(), authEventBus: AuthEventBus());
  void set(AppAuthState s) => emit(s);
}

/// API giả có trạng thái: lời mời của giáo viên, đồng ý điều khoản, vai trò và
/// con của phụ huynh. Chỉ nhận lệnh đúng đường dẫn/phương thức của hợp đồng.
class _InviteBackend implements HttpClientAdapter {
  static const token = 'q3Zp8mT1xV0kLw5Hn2RcYb7JdFgSaE9uXoIiKtUeMhA';
  static const shortCode = 'K7M2Q9XA';
  static const studentId = 's1';

  final requests = <String>[];
  bool consentAccepted = false;
  bool issued = false;
  bool linked = false;

  static ResponseBody _json(int status, [Object? body]) =>
      ResponseBody.fromString(
        jsonEncode(body ?? {}),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  static ResponseBody _error(int status, String code) =>
      _json(status, {'code': code, 'message': 'x', 'requestId': 'r'});

  Dio dio() =>
      Dio(BaseOptions(baseUrl: 'https://api.test/v1'))
        ..httpClientAdapter = this;

  ResponseBody _accepted() {
    linked = true;
    consentAccepted = true; // nhận lời mời = server coi là đã đồng ý
    return _json(200, {
      'membershipId': 'm-p',
      'studentId': studentId,
      'studentName': _studentName,
    });
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? body,
    Future<void>? cancel,
  ) async {
    final key = '${o.method} ${o.path}';
    requests.add(key);
    final data = o.data is Map ? o.data as Map : const {};
    switch (key) {
      case 'POST /students/$studentId/invites':
        if (o.headers['Idempotency-Key'] is! String) {
          return _error(422, 'VALIDATION_FAILED');
        }
        issued = true;
        return _json(201, {
          'id': 'i1',
          'guardianId': 'g1',
          'url': 'https://dayhoc.app/i#t=$token',
          'shortCode': shortCode,
          'expiresAt': '2026-12-21T00:00:00Z',
          'shortCodeExpiresAt': '2026-11-23T00:00:00Z',
        });
      case 'POST /invites/preview':
        return data['token'] == token && issued
            ? _json(200, {
                'teacherName': _teacherName,
                'studentGivenName': 'Anh',
                'expiresAt': '2026-12-21T00:00:00Z',
              })
            : _error(410, 'INVITE_INVALID');
      case 'POST /invites/accept':
        if (data['token'] != token || !issued) {
          return _error(410, 'INVITE_INVALID');
        }
        return consentAccepted ? _accepted() : _error(403, 'CONSENT_REQUIRED');
      case 'POST /invites/redeem-code':
        if (data['code'] != shortCode || !issued) {
          return _error(410, 'INVITE_INVALID');
        }
        return consentAccepted ? _accepted() : _error(403, 'CONSENT_REQUIRED');
      case 'GET /consents/status':
        return _json(200, {
          'role': 'parent',
          'currentTermsVersion': 'v1',
          'accepted': consentAccepted,
          'acceptedAt': null,
          'acceptedTermsVersion': null,
        });
      case 'POST /consents':
        consentAccepted = true;
        return _json(201);
      case 'GET /me/memberships':
        return _json(200, {
          'items': [
            if (linked) {'id': 'm-p', 'role': 'parent', 'label': 'Phụ huynh'},
          ],
        });
      case 'PUT /me/active-membership':
        return _json(204);
      case 'GET /family/students':
        return _json(200, {
          'items': [
            if (linked)
              {'id': studentId, 'fullName': _studentName, 'classes': []},
          ],
        });
      case 'GET /family/invoices':
        return _json(200, {'items': [], 'nextCursor': null});
    }
    if (o.method == 'GET' &&
        o.path == '/family/students/$studentId/attendance') {
      return _json(200, {
        'studentId': studentId,
        'weekStart': '2026-11-16',
        'weekEnd': '2026-11-22',
        'summary': {
          'present': 0,
          'late': 0,
          'excused': 0,
          'unexcused': 0,
          'notRecorded': 0,
          'upcoming': 0,
        },
        'sessions': [],
      });
    }
    return _error(404, 'NOT_FOUND');
  }

  @override
  void close({bool force = false}) {}
}

void defineInviteFlowTests() {
  late _InviteBackend backend;
  late MembershipCubit memberships;
  late ConsentCubit consent;
  late GoRouter router;

  /// Dựng shell cho một người dùng đã đăng nhập, chưa có vai trò nào.
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1000) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    backend = _InviteBackend();
    final dio = backend.dio();
    await GetIt.I.reset();
    addTearDown(GetIt.I.reset);
    GetIt.I.registerSingleton<Dio>(dio, instanceName: TeachHubDiKey.api);

    final auth = _Auth();
    memberships = MembershipCubit(
      api: dio,
      prefs: await SharedPreferences.getInstance(),
      activeMembership: ActiveMembership(null),
    );
    consent = ConsentCubit(dio);
    final invites = DioInviteRepository(dio);
    GetIt.I
      ..registerSingleton<MembershipCubit>(memberships)
      ..registerSingleton<ConsentCubit>(consent)
      ..registerSingleton<InviteRepository>(invites)
      ..registerFactory<InviteEntryCubit>(
        () => InviteEntryCubit(
          repository: invites,
          memberships: memberships,
          consent: consent,
        ),
      );
    ParentController.instance.noInviteBuilder = (_, onLinked) =>
        embeddedInviteEntry(onLinked);
    addTearDown(() => ParentController.instance.noInviteBuilder = null);
    addTearDown(auth.close);
    addTearDown(memberships.close);
    addTearDown(consent.close);

    final manager = ModuleManager()
      ..register(ParentController.instance.toModuleSlot());
    await manager.initAll();
    router = buildAppRouter(
      moduleManager: manager,
      authCubit: auth,
      membershipCubit: memberships,
      consentCubit: consent,
      loginPage: () => const Text('màn đăng nhập'),
      inviteCubit: (token) => InviteCubit(
        repository: invites,
        memberships: memberships,
        consent: consent,
        token: token,
      ),
    );
    addTearDown(router.dispose);
    auth.set(
      AppAuthState.initial().copyWith(
        statusCheckToken: LoadingStatus.success,
        user: _user,
      ),
    );
    await tester.runAsync(memberships.load);
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
            localizationsDelegates: [
              ...AppLocalizations.localizationsDelegates,
              ...ParentController.instance.localizationsDelegates,
              TascoUiKitLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.rolePicker);
  }

  /// Chờ tới khi [finder] có trên màn: lệnh gọi API chạy ngoài đồng hồ giả.
  Future<void> until(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 500 && finder.evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(finder, findsOneWidget, reason: 'hết 10 giây: ${backend.requests}');
  }

  /// Giáo viên cấp lời mời cho phụ huynh của Minh Anh (`InviteLinkCubit` thật).
  Future<InviteLink> teacherInvites(WidgetTester tester) async {
    final cubit = InviteLinkCubit(
      teacher.DioInviteRepository(backend.dio()),
      _InviteBackend.studentId,
      const RosterGuardian(
        id: 'g1',
        fullName: 'Nguyễn Văn Bình',
        relation: 'father',
        inviteStatus: GuardianInviteStatus.notInvited,
      ),
    );
    addTearDown(cubit.close);
    await tester.runAsync(cubit.start);
    expect(cubit.state.status, InviteLinkStatus.ready);
    return cubit.state.link!;
  }

  Future<void> accept(WidgetTester tester) async {
    await until(tester, find.text('Đồng ý và tiếp tục'));
    await tester.tap(find.text('Đồng ý và tiếp tục'));
    await tester.pump();
  }

  testWidgets('luồng C qua link: giáo viên tạo lời mời → phụ huynh mở link → '
      'chưa đồng ý điều khoản → đồng ý → nhận → P02 thấy con', (tester) async {
    await pump(tester);
    final link = await teacherInvites(tester);
    expect(backend.issued, isTrue);

    // Link giáo viên gửi qua Zalo: app đọc token ra, mở thẻ lời mời.
    final input = InviteInput.parse(link.url);
    expect(input, isA<InviteToken>());
    router.go(AppRoutes.invite((input! as InviteToken).value));
    await until(tester, find.text('Lời mời từ $_teacherName'));

    await tester.tap(find.text('Nhận lời mời'));
    await tester.pump();
    // Server đòi đồng ý điều khoản trước (403 CONSENT_REQUIRED) → màn đồng ý.
    await until(tester, find.text('Phiên bản điều khoản: v1'));
    expect(backend.linked, isFalse);
    await accept(tester);

    // Nhận lại sau khi đồng ý → vào P02 của vai trò Phụ huynh.
    await until(tester, find.text(_studentName));
    expect(router.state.uri.path, TeachHubRoutes.parent);
    expect(backend.linked, isTrue);
    expect(memberships.state.active?.role, MembershipRole.parent);
    expect(
      backend.requests.where((r) => r == 'POST /invites/accept'),
      hasLength(2),
      reason: 'lần đầu 403, lần hai sau khi đồng ý',
    );
    expect(consent.state.accepted, isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('luồng C qua mã: phụ huynh nhập mã ở P05 (mã sai báo lỗi, mã '
      'đúng đi qua đồng ý) → P02 thấy con', (tester) async {
    await pump(tester);
    final link = await teacherInvites(tester);
    router.go(AppRoutes.inviteEntry);
    await tester.pumpAndSettle();

    Future<void> submit(String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.tap(find.text('Tiếp tục'));
      await tester.pump();
    }

    // Mã sai: 410, cùng một thông báo, chưa vào đâu.
    await submit('ZZZZ9999');
    await until(
      tester,
      find.text(
        'Mã không đúng hoặc đã hết hạn. Hãy nhắn giáo viên xin mã mới.',
      ),
    );

    await submit(link.shortCode);
    await until(tester, find.text('Phiên bản điều khoản: v1'));
    await accept(tester);

    await until(tester, find.text(_studentName));
    expect(router.state.uri.path, TeachHubRoutes.parent);
    expect(backend.linked, isTrue);
    expect(memberships.state.active?.role, MembershipRole.parent);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
