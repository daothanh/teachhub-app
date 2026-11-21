// S5-FL-08: luồng A phần học phí chạy trên GoRouter thật của shell, mini-app
// teacher và parent thật, nói chuyện với một backend giả có trạng thái
// (`FakeTeachHubBackend`): điểm danh → bản nháp của kỳ → điều chỉnh → "Chốt & gửi"
// → phụ huynh thấy hóa đơn kèm VietQR ở P03. Dùng chung cho `flutter test` (CI) và
// integration test trên máy (integration_test/billing_flow_test.dart).
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
import 'package:parent/l10n/l10n.dart' as parent_l10n;
import 'package:parent/parent.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasco_auth/tasco_auth.dart';
import 'package:tasco_core/tasco_core.dart';
import 'package:tasco_module/tasco_module.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:tasco_utils/tasco_utils.dart';
import 'package:teacher/data/local_db/teacher_database.dart';
import 'package:teacher/data/remote/teacher_api.dart';
import 'package:teacher/data/sync/clock_skew.dart';
import 'package:teacher/data/sync/sync_engine.dart';
import 'package:teacher/features/attendance/data/attendance_repository.dart';
import 'package:teacher/features/fees/fees_routes.dart';
import 'package:teacher/l10n/l10n.dart' as teacher_l10n;
import 'package:teacher/teacher.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'fake_teachhub_backend.dart';

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

MembershipState _state(Membership active) => MembershipState(
  statusLoad: LoadingStatus.success,
  memberships: const [_teacher, _parent],
  active: active,
);

/// Tiền như app hiển thị: `100.000 đ` (các số trong kịch bản đều dưới 1 triệu).
String _vnd(int amount) =>
    '${amount ~/ 1000}.${'${amount % 1000}'.padLeft(3, '0')} đ';

void defineBillingFlowTests() {
  late FakeTeachHubBackend backend;
  late _Memberships memberships;
  late GoRouter router;
  late TeacherDatabase db;
  late SyncEngine engine;
  late teacher_l10n.MiniAppLocalizations tl;
  late parent_l10n.MiniAppLocalizations pl;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1400) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    // 10:00 giờ Việt Nam, giữa tháng. Chỗ còn phụ thuộc đồng hồ máy: màn "Hôm nay"
    // (TodayCubit lấy DateTime.now, không tiêm được) nên backend giả xếp buổi học
    // vào đúng ngày app hỏi; mọi thứ còn lại theo mốc cố định này.
    backend = FakeTeachHubBackend(now: DateTime.utc(2026, 11, 15, 3));
    tl = await teacher_l10n.MiniAppLocalizations.delegate.load(
      const Locale('vi'),
    );
    pl = await parent_l10n.MiniAppLocalizations.delegate.load(
      const Locale('vi'),
    );
    final dio = backend.dio();
    await GetIt.I.reset();
    addTearDown(GetIt.I.reset);
    GetIt.I.registerSingleton<Dio>(dio, instanceName: TeachHubDiKey.api);

    // CSDL ngoại tuyến của teacher chạy trong bộ nhớ, đồng bộ lên backend giả.
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
      ..register(TeacherController.instance.toModuleSlot())
      ..register(ParentController.instance.toModuleSlot());
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
              ...ParentController.instance.localizationsDelegates,
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
  }

  /// Gỡ cây widget, cho timer đóng luồng truy vấn của drift chạy nốt, rồi đóng CSDL.
  /// Mọi kịch bản phải gọi cuối thân test.
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

  Future<void> tapText(WidgetTester tester, String text) async {
    final f = find.text(text).first;
    await tester.ensureVisible(f);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Finder inDialog(String text) =>
      find.descendant(of: find.byType(AlertDialog), matching: find.text(text));

  Finder fieldOf(String label) => find.descendant(
    of: find.byWidgetPredicate((w) => w is AppInput && w.label == label),
    matching: find.byType(EditableText),
  );

  /// Chờ điều kiện trên backend: đồng bộ nền chạy ngoài đồng hồ giả của test.
  Future<void> until(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 500 && !done(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(done(), isTrue, reason: 'hết 10 giây: ${backend.requests}');
  }

  Future<void> openPeriod(WidgetTester tester) async {
    router.go(TeachHubRoutes.teacherBilling);
    await tester.pumpAndSettle();
    await tapText(
      tester,
      tl.billingPeriodMonth(backend.now.month, backend.now.year),
    );
  }

  Future<void> confirmIssueAll(WidgetTester tester) async {
    await tapText(tester, tl.billingIssueAll);
    await tester.tap(inDialog(tl.billingIssueAllConfirmAction));
    await tester.pumpAndSettle();
  }

  testWidgets('luồng A: điểm danh → bản nháp → điều chỉnh → chốt & gửi → '
      'phụ huynh thấy hóa đơn kèm VietQR ở P03', (tester) async {
    await pump(tester);
    final minhAnh = FakeTeachHubBackend.minhAnh;
    final baoChau = FakeTeachHubBackend.baoChau;
    const fee = FakeTeachHubBackend.feePerSession;

    // T03 → T04: điểm danh. Minh Anh có mặt (mặc định), Bảo Châu vắng có phép.
    expect(find.text(FakeTeachHubBackend.className), findsOneWidget);
    await tapText(tester, tl.todayTakeAttendance);
    await tapText(tester, baoChau.name);
    await tapText(tester, tl.attendanceSave);
    await until(
      tester,
      () =>
          backend.attendanceOf(minhAnh.id) != null &&
          backend.attendanceOf(baoChau.id) != null,
    );
    expect(backend.attendanceOf(minhAnh.id), 'present');
    expect(backend.attendanceOf(baoChau.id), 'excused');

    // T10: kỳ thu có bản nháp; chỉ buổi Minh Anh có mặt tính tiền.
    await openPeriod(tester);
    expect(find.text(minhAnh.name), findsOneWidget);
    expect(find.text(_vnd(fee)), findsWidgets);
    expect(find.text(tl.billingNoSend), findsOneWidget);

    // Điều chỉnh giảm 50.000 đ: tổng bản nháp lấy từ server.
    await tapText(tester, minhAnh.name);
    await tapText(tester, tl.billingAddAdjustment);
    await tester.enterText(fieldOf(tl.billingAdjustAmount), '50000');
    await tester.enterText(
      fieldOf(tl.billingAdjustDescription),
      'Giảm học thử',
    );
    await tester.enterText(fieldOf(tl.billingAdjustReason), 'Đã thỏa thuận');
    await tapText(tester, tl.billingAdjustSave);
    const total = fee - 50000;
    expect(find.text(_vnd(total)), findsWidgets);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text(tl.billingDraftSummary(2, _vnd(total))), findsOneWidget);

    // Chốt khi chưa có tài khoản nhận tiền → mở màn tài khoản, chưa phát hành.
    await tapText(tester, tl.billingIssueAll);
    expect(
      find.text(tl.billingIssueAllConfirmBody(1, _vnd(total))),
      findsOneWidget,
    );
    await tester.tap(inDialog(tl.billingIssueAllConfirmAction));
    await tester.pumpAndSettle();
    expect(find.text(tl.billingPayoutMissingTitle), findsOneWidget);
    await tapText(tester, tl.billingPayoutMissingAction);
    expect(router.state.uri.path, FeesRoutes.payoutAccounts);
    expect(backend.issuedInvoiceOf(minhAnh.id), isNull);

    // Có tài khoản (form tài khoản đã có test riêng) → quay lại chốt tiếp.
    backend.payout = {
      'bankBin': '970436',
      'bankName': 'Vietcombank',
      'accountNo': '0123456789',
      'accountName': 'NGUYEN VAN LAN',
    };
    router.pop();
    await tester.pumpAndSettle();
    await confirmIssueAll(tester);
    expect(
      find.text('${tl.billingIssued(1)} ${tl.billingIssuedSkippedZero(1)}'),
      findsOneWidget,
    );
    final issued = backend.issuedInvoiceOf(minhAnh.id)!;
    expect(issued['totalAmount'], total);
    expect(issued['status'], 'issued');
    expect(
      backend.issuedInvoiceOf(baoChau.id),
      isNull,
      reason: 'hóa đơn 0 đ không gửi',
    );
    final code = issued['code']! as String;
    expect(find.text(code), findsOneWidget);

    // Phụ huynh: P03 thấy đúng hóa đơn đã chốt, kèm VietQR.
    memberships.set(_state(_parent));
    router.go(TeachHubRoutes.parentInvoices);
    await tester.pumpAndSettle();
    expect(find.textContaining(minhAnh.name), findsOneWidget);
    expect(find.textContaining(baoChau.name), findsNothing);
    await tester.tap(find.textContaining(minhAnh.name));
    await tester.pumpAndSettle();
    expect(
      find.text(
        '${pl.invoiceCodeLabel(code)} · ${FakeTeachHubBackend.teacherName}',
      ),
      findsOneWidget,
    );
    expect(find.text(_vnd(total)), findsWidgets);
    final note = issued['transferNote']! as String;
    expect(find.text(note), findsOneWidget);
    expect(find.text('0123456789'), findsOneWidget);
    final qr = issued['qrPayload']! as String;
    expect(qr, contains('|$total|$note'));
    // QrImageView không lộ `data`: so ảnh mã đang vẽ với ảnh dựng từ qrPayload.
    Future<List<int>> image() async {
      final p =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(QrImageView),
                      matching: find.byWidgetPredicate(
                        (w) => w is CustomPaint && w.painter is QrPainter,
                      ),
                    ),
                  )
                  .painter!
              as QrPainter;
      return (await tester.runAsync(
        () async => (await p.toImageData(220))!.buffer.asUint8List(),
      ))!;
    }

    final shown = await image();
    Future<List<int>> built(String data) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: QrImageView(
            data: data,
            size: 220,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
            backgroundColor: Colors.white,
          ),
        ),
      );
      return image();
    }

    expect(await built(qr), shown);
    expect(
      await built(qr.replaceFirst('|$total|', '|1|')),
      isNot(shown),
      reason: 'mã khác số tiền phải ra ảnh khác',
    );
    await finish(tester);
  });

  testWidgets('chốt khi chưa có tài khoản nhận tiền: mở màn tài khoản, không '
      'phát hành hóa đơn nào', (tester) async {
    await pump(tester);
    backend.recordAttendance(FakeTeachHubBackend.minhAnh.id, 'present');
    backend.recordAttendance(FakeTeachHubBackend.baoChau.id, 'late');
    await openPeriod(tester);
    await confirmIssueAll(tester);
    expect(find.text(tl.billingPayoutMissingTitle), findsOneWidget);
    await tapText(tester, tl.billingPayoutMissingAction);
    expect(router.state.uri.path, FeesRoutes.payoutAccounts);
    expect(backend.issuedInvoiceOf(FakeTeachHubBackend.minhAnh.id), isNull);
    expect(backend.issuedInvoiceOf(FakeTeachHubBackend.baoChau.id), isNull);
    await finish(tester);
  });

  /// Hai học viên cùng có mặt (mỗi người 150.000 đ) và đã có tài khoản nhận tiền.
  void seedPayable() {
    backend.recordAttendance(FakeTeachHubBackend.minhAnh.id, 'present');
    backend.recordAttendance(FakeTeachHubBackend.baoChau.id, 'present');
    backend.payout = {
      'bankBin': '970436',
      'bankName': 'Vietcombank',
      'accountNo': '0123456789',
      'accountName': 'NGUYEN VAN LAN',
    };
  }

  /// Chờ SnackBar đang hiện tắt hẳn để thông báo kế tiếp hiện ngay.
  Future<void> dismissSnackBar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  }

  testWidgets('chốt lỗi mạng rồi bấm lại: cùng Idempotency-Key, server phát '
      'lại, chỉ phát hành một lần', (tester) async {
    await pump(tester);
    seedPayable();
    backend.dropNextIssueResponse = true; // server đã chốt, phản hồi mất
    await openPeriod(tester);
    await confirmIssueAll(tester);
    expect(backend.issueExecutions, 1);
    expect(find.text(tl.billingIssued(2)), findsNothing);

    await dismissSnackBar(tester);
    await confirmIssueAll(tester);
    expect(backend.issueKeys, hasLength(2));
    expect(backend.issueKeys[1], backend.issueKeys[0]);
    expect(backend.issueExecutions, 1, reason: 'lần hai là phát lại');
    expect(find.text(tl.billingIssued(2)), findsOneWidget);
    final codes = [
      for (final s in [
        FakeTeachHubBackend.minhAnh,
        FakeTeachHubBackend.baoChau,
      ])
        backend.issuedInvoiceOf(s.id)!['code'],
    ];
    expect(codes, ['TH-25K7Q9', 'TH-26M8R2'], reason: 'không cấp mã lần hai');
    await finish(tester);
  });

  testWidgets('409 CONFLICT_STALE dù hóa đơn đã phát hành: tải lại, hiện trạng '
      'thái đã phát hành, không tạo hóa đơn thứ hai', (tester) async {
    await pump(tester);
    seedPayable();
    await openPeriod(tester);
    backend
      ..issueAllNow() // thiết bị khác vừa chốt
      ..staleIssues = 1;
    await confirmIssueAll(tester);
    expect(find.text(tl.billingErrStale), findsOneWidget);
    expect(find.text(tl.billingErrStaleUnverified), findsNothing);
    expect(find.text('TH-25K7Q9'), findsOneWidget);
    expect(find.text('TH-26M8R2'), findsOneWidget);
    expect(find.text(tl.billingNoPayableDrafts), findsOneWidget);
    expect(backend.issueExecutions, 1, reason: 'chỉ lần chốt của thiết bị kia');
    await finish(tester);
  });

  testWidgets('409 CONFLICT_STALE mà tải lại cũng lỗi: báo chưa xác nhận; bấm '
      'lại dùng khóa mới, issuedCount = 0, không báo lỗi', (tester) async {
    await pump(tester);
    seedPayable();
    await openPeriod(tester);
    backend
      ..issueAllNow()
      ..staleIssues = 1
      ..failPeriodGets = 1;
    await confirmIssueAll(tester);
    expect(find.text(tl.billingErrStaleUnverified), findsOneWidget);
    expect(find.text(tl.billingErrStale), findsNothing);

    await dismissSnackBar(tester);
    await confirmIssueAll(tester);
    expect(backend.issueKeys, hasLength(2));
    expect(backend.issueKeys[1], isNot(backend.issueKeys[0]));
    expect(find.text(tl.billingIssuedNone), findsOneWidget);
    expect(find.text(tl.billingErrStale), findsNothing);
    expect(find.text(tl.billingErrStaleUnverified), findsNothing);
    expect(
      backend.issuedInvoiceOf(FakeTeachHubBackend.minhAnh.id)!['code'],
      'TH-25K7Q9',
      reason: 'không tạo hóa đơn thứ hai',
    );
    expect(find.text(tl.billingNoPayableDrafts), findsOneWidget);
    await finish(tester);
  });
}
