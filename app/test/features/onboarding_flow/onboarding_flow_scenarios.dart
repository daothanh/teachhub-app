// S2-FL-06: luồng B (onboarding → tạo lớp → thêm học viên → đặt lịch) chạy trên
// GoRouter thật của shell và mini-app teacher thật, nói chuyện với backend giả có
// trạng thái (`FakeOnboardingBackend`). Dùng chung cho `flutter test` (CI) và
// integration test trên máy (integration_test/onboarding_flow_test.dart).
import 'dart:async';

import 'package:app/core/routing/app_router.dart';
import 'package:app/features/auth/auth_cubit.dart';
import 'package:app/features/auth/teachhub_user.dart';
import 'package:app/features/consent/consent_cubit.dart';
import 'package:app/features/role_picker/membership_cubit.dart';
import 'package:app/l10n/l10n.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasco_auth/tasco_auth.dart';
import 'package:tasco_core/tasco_core.dart';
import 'package:tasco_storage/tasco_storage.dart';
import 'package:tasco_module/tasco_module.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:tasco_utils/tasco_utils.dart';
import 'package:teacher/data/local_db/teacher_database.dart';
import 'package:teacher/data/remote/teacher_api.dart';
import 'package:teacher/data/sync/clock_skew.dart';
import 'package:teacher/data/sync/sync_engine.dart';
import 'package:teacher/features/attendance/data/attendance_repository.dart';
import 'package:teacher/l10n/l10n.dart' as teacher_l10n;
import 'package:teacher/teacher.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'fake_onboarding_backend.dart';

const _user = TeachHubUser(id: 'u1', email: 'a@b.vn');
const _teacher = Membership(
  id: 'm-t',
  role: MembershipRole.tenantOwner,
  label: 'Giáo viên',
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

MembershipState _state(Membership active) => MembershipState(
  statusLoad: LoadingStatus.success,
  memberships: const [_teacher],
  active: active,
);

void defineOnboardingFlowTests() {
  late FakeOnboardingBackend backend;
  late _Memberships memberships;
  late GoRouter router;
  late TeacherDatabase db;
  late SyncEngine engine;
  late teacher_l10n.MiniAppLocalizations tl;

  /// Kho khóa của máy (Keychain/Keystore): sống qua "kill app" như thật.
  late InMemoryKeyValueStore keyStore;

  /// Mở app như lần chạy mới (cây widget, CSDL máy, router đều mới); [backend]
  /// là server, sống qua các lần mở: gọi lại để mô phỏng "kill app, mở lại".
  Future<void> openApp(
    WidgetTester tester, {
    String route = '${TeachHubRoutes.teacher}/onboarding',
  }) async {
    tester.view.physicalSize = const Size(390, 1400) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    TeacherController.instance.keyStoreOverride = keyStore;
    final dio = backend.dio();
    await GetIt.I.reset();
    addTearDown(GetIt.I.reset);
    GetIt.I.registerSingleton<Dio>(dio, instanceName: TeachHubDiKey.api);

    db = TeacherDatabase(NativeDatabase.memory());
    GetIt.I.registerSingleton<TeacherDatabase>(
      db,
      instanceName: TeacherController.databaseKey,
    );
    final api = TeacherApi(
      dio,
      deviceId: '20000000-0000-4000-8000-000000000001',
    );
    final clock = ClockSkew(now: () => backend.now);
    engine = SyncEngine(db, api.sync, clock: clock, now: () => backend.now);
    GetIt.I.registerSingleton<AttendanceRepository>(
      DriftAttendanceRepository(
        database: () async => db,
        api: () async => api,
        engine: () async => engine,
        startSync: () async {},
        clock: clock,
      ),
    );
    final auth = _Auth();
    memberships = _Memberships(await SharedPreferences.getInstance());
    final consent = ConsentCubit(Dio())..markAccepted();
    addTearDown(auth.close);
    addTearDown(memberships.close);
    addTearDown(consent.close);
    final manager = ModuleManager()
      ..register(TeacherController.instance.toModuleSlot());
    await manager.initAll();
    router = buildAppRouter(
      moduleManager: manager,
      authCubit: auth,
      membershipCubit: memberships,
      consentCubit: consent,
      loginPage: () => const Text('màn đăng nhập'),
      inviteCubit: (_) => throw UnimplementedError(),
    );
    addTearDown(router.dispose);
    auth.set(
      AppAuthState.initial().copyWith(
        statusCheckToken: LoadingStatus.success,
        user: _user,
      ),
    );
    memberships.set(_state(_teacher));
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
              ...TeacherController.instance.localizationsDelegates,
              TascoUiKitLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // Tenant mới: app mở thẳng onboarding (US-0.2 AC1).
    router.go(route);
    await tester.pumpAndSettle();
  }

  /// Gỡ cây widget, cho timer đóng luồng truy vấn của drift chạy nốt, rồi đóng CSDL.
  /// Gọi trước khi mở lại app và cuối thân mỗi kịch bản.
  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    // `db.close()` phải chạy trên đồng hồ giả của test và được bơm khung hình:
    // drift chờ các future đã tạo trong vùng giả đó. Bọc trong `runAsync` hay đặt
    // ở addTearDown thì không bao giờ xong (từng làm rò CSDL sang test sau).
    await tester.runAsync(engine.dispose);
    var closed = false;
    unawaited(db.close().then((_) => closed = true));
    for (var i = 0; i < 20 && !closed; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(closed, isTrue, reason: 'db.close() không xong sau 2 giây giả');
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> setUpBackend(WidgetTester tester) async {
    tl = await teacher_l10n.MiniAppLocalizations.delegate.load(
      const Locale('vi'),
    );
    // 10:00 giờ Việt Nam, giữa tháng.
    backend = FakeOnboardingBackend(now: DateTime.utc(2026, 11, 15, 3));
    keyStore = InMemoryKeyValueStore();
    addTearDown(() => TeacherController.instance.keyStoreOverride = null);
  }

  Finder inputOf(String label) => find.byWidgetPredicate(
    (w) => w is AppInput && w.label == label,
    skipOffstage: false,
  );

  Finder fieldOf(String label) =>
      find.descendant(of: inputOf(label), matching: find.byType(EditableText));

  Future<void> reveal(WidgetTester tester, Finder f) async {
    await tester.scrollUntilVisible(
      f,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
  }

  Future<void> tapButton(WidgetTester tester, String label) async {
    final f = find.widgetWithText(AppButton, label);
    await reveal(tester, f);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Future<void> createClass(WidgetTester tester) async {
    await tester.enterText(fieldOf(tl.classesFieldName), 'Toán 9A');
    await tester.enterText(fieldOf(tl.classesFieldSubject), 'Toán');
    await tester.enterText(fieldOf(tl.classesFieldGrade), '9');
    await tester.enterText(fieldOf(tl.classesFieldLocation), 'Nhà riêng');
    await reveal(tester, inputOf(tl.classesFieldStart));
    await tester.tap(inputOf(tl.classesFieldStart));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tapButton(tester, tl.classesSave);
  }

  Future<void> continueStudents(WidgetTester tester) =>
      tapButton(tester, tl.onboardingStudentsContinue(1));

  Future<void> addStudent(WidgetTester tester) async {
    await tester.enterText(find.byType(EditableText).first, 'Minh Anh');
    await tapButton(tester, tl.onboardingAddStudent);
    // Ghi danh lỗi thì chưa có học sinh trong danh sách, chưa có "Tiếp tục".
    if (find.text(tl.onboardingStudentsContinue(1)).evaluate().isNotEmpty) {
      await continueStudents(tester);
    }
  }

  void expectStep(int n) =>
      expect(find.text(tl.onboardingProgress(n, 3)), findsOneWidget);

  /// Lưu quy tắc mặc định (thứ Hai 18:00, 90 phút) của bước 3.
  Future<void> addRuleAndSave(WidgetTester tester) async {
    await tapButton(tester, tl.classesRuleAdd);
    await tapButton(tester, tl.classesSave);
  }

  testWidgets('luồng B: onboarding 3 bước → tạo lớp → thêm học viên → đặt '
      'lịch → Hôm nay có buổi học', (tester) async {
    await setUpBackend(tester);
    await openApp(tester);

    // Bước 1: tạo lớp qua form lớp, không có lịch (để bước 3).
    expectStep(1);
    expect(find.text(tl.onboardingSkip), findsNothing);
    expect(find.text(tl.classesRuleAdd), findsNothing);
    await createClass(tester);
    expect(backend.savedClass!['name'], 'Toán 9A');
    expect(backend.steps['create_class'], 'done');

    // Bước 2: thêm học viên qua form học viên.
    expectStep(2);
    await addStudent(tester);
    expect(backend.savedStudents.single['fullName'], 'Minh Anh');
    expect(backend.enrolled, [FakeOnboardingBackend.studentId]);
    expect(backend.steps['add_students'], 'done');

    // Bước 3: đặt lịch lặp cho đúng lớp vừa tạo.
    expectStep(3);
    await addRuleAndSave(tester);
    expect(backend.rules.single['weekday'], 1);
    expect(backend.rules.single['startTime'], '18:00');
    expect(backend.steps['set_schedule'], 'done');
    expect(backend.classCreates, 1, reason: 'đặt lịch sửa lớp, không tạo lớp');

    // Server còn bước 4–5 nhưng app dừng ở bước 3 (22/11/2026), không ghi gì thêm.
    expect(backend.steps['payout_account'], isNot('skipped'));
    expect(backend.steps['compliance_checklist'], isNot('skipped'));

    // Xong bước 3: vào thẳng Hôm nay, gợi ý mời phụ huynh của lớp vừa tạo.
    expect(router.state.uri.path, TeachHubRoutes.teacher);
    expect(find.text(tl.todayInviteTitle), findsOneWidget);
    await tester.tap(find.text(tl.todayInviteLater));
    await tester.pumpAndSettle();

    // Hôm nay được làm mới ngay: buổi vừa đặt, không còn thẻ nhắc (không bỏ qua bước nào).
    expect(find.text('Toán 9A'), findsOneWidget);
    expect(find.text(tl.todayTakeAttendance), findsOneWidget);
    expect(find.text(tl.todayOnboardingTitle), findsNothing);

    // Màn điểm danh của buổi đó thấy học viên đã thêm ở bước 2.
    await tester.tap(find.text(tl.todayTakeAttendance));
    await tester.pumpAndSettle();
    // Danh sách lớp tải qua đồng bộ nền, chạy ngoài đồng hồ giả của test.
    for (var i = 0; i < 100 && find.text('Minh Anh').evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }

    await finish(tester);
  });

  testWidgets('kill app ở bước 3, mở lại: đúng bước 3, lớp và học viên còn', (
    tester,
  ) async {
    await setUpBackend(tester);
    await openApp(tester);
    await createClass(tester);
    await addStudent(tester);
    expectStep(3);

    await finish(tester); // kill app
    await openApp(tester);

    expectStep(3);
    expect(find.text(tl.onboardingStepSetSchedule), findsOneWidget);
    expect(find.text(tl.classesRuleAdd), findsOneWidget);
    expect(backend.classCreates, 1);
    expect(backend.studentCreates, 1);
    // Lớp tạo ở bước 1 vẫn là lớp được đặt lịch.
    await addRuleAndSave(tester);
    expect(backend.rules, hasLength(1));
    expect(find.text(tl.todayInviteTitle), findsOneWidget);

    await finish(tester);
  });

  testWidgets('đặt lịch xong mà chưa ghi được bước, kill app: quy tắc còn '
      'nguyên ở bước 3', (tester) async {
    await setUpBackend(tester);
    backend.failStepPatches['set_schedule'] = 1;
    await openApp(tester);
    await createClass(tester);
    await addStudent(tester);
    await addRuleAndSave(tester);
    expect(backend.rules, hasLength(1));
    expect(backend.steps['set_schedule'], 'pending');
    expect(find.text(tl.onboardingSaved), findsOneWidget);

    await finish(tester); // kill app trước khi kịp thử lại
    await openApp(tester);

    expectStep(3);
    expect(find.text(tl.classesRuleN(1)), findsOneWidget);
    expect(find.text('18:00'), findsOneWidget);
    expect(backend.classCreates, 1);

    await finish(tester);
  });

  testWidgets('ghi danh lỗi mạng ở bước 2: thử lại không tạo trùng học viên '
      'hay ghi danh', (tester) async {
    await setUpBackend(tester);
    backend.failEnrolls = 1;
    await openApp(tester);
    await createClass(tester);
    await addStudent(tester);

    expectStep(2);
    expect(backend.savedStudents, hasLength(1));
    expect(backend.enrolled, isEmpty);
    expect(backend.steps['add_students'], 'pending');
    await tapButton(tester, tl.onboardingRetry);
    await continueStudents(tester);

    expectStep(3);
    expect(backend.studentCreates, 1);
    expect(backend.enrolled, [FakeOnboardingBackend.studentId]);
    expect(backend.steps['add_students'], 'done');

    await finish(tester);
  });

  testWidgets('kill app sau khi tạo lớp mà chưa ghi done bước 1: mở lại không '
      'tạo lớp mới, chỉ ghi lại bước', (tester) async {
    await setUpBackend(tester);
    backend.failStepPatches['create_class'] = 1;
    await openApp(tester);
    await createClass(tester);
    expect(backend.classCreates, 1);
    expect(backend.steps['create_class'], 'pending');

    await finish(tester); // kill app
    await openApp(tester);

    expect(backend.classCreates, 1, reason: 'không tạo lớp thứ hai');
    expect(backend.steps['create_class'], 'done');
    expectStep(2);

    await finish(tester);
  });

  testWidgets('kill app sau khi tạo học viên mà ghi danh lỗi: mở lại ghi danh '
      'tiếp, không tạo học viên mới', (tester) async {
    await setUpBackend(tester);
    backend.failEnrolls = 1;
    await openApp(tester);
    await createClass(tester);
    await addStudent(tester);
    expect(backend.studentCreates, 1);
    expect(backend.enrolled, isEmpty);

    await finish(tester); // kill app
    await openApp(tester);

    expect(backend.studentCreates, 1, reason: 'không tạo học viên thứ hai');
    expect(backend.enrolled, [FakeOnboardingBackend.studentId]);
    await continueStudents(tester);
    expect(backend.steps['add_students'], 'done');
    expectStep(3);

    await finish(tester);
  });
}
