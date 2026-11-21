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

  /// Chờ SnackBar đang hiện tắt hẳn để thông báo kế tiếp hiện ngay.
  Future<void> dismissSnackBar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
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
    // SnackBar "chưa có tài khoản" còn hiện thì thông báo chốt xếp hàng sau nó;
    // đồng hồ thật (máy ảo) không tự trôi như đồng hồ giả.
    await dismissSnackBar(tester);
    await confirmIssueAll(tester);
    expect(
      find.text(
        '${tl.billingIssuedTotal(1, _vnd(total))} '
        '${tl.billingIssuedSkippedZero(1)}',
      ),
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

  testWidgets('chốt lỗi mạng rồi bấm lại: cùng Idempotency-Key, server phát '
      'lại, chỉ phát hành một lần', (tester) async {
    await pump(tester);
    seedPayable();
    backend.dropNextIssueResponse = true; // server đã chốt, phản hồi mất
    await openPeriod(tester);
    await confirmIssueAll(tester);
    expect(backend.issueExecutions, 1);
    final issuedBoth = tl.billingIssuedTotal(2, _vnd(300000));
    expect(find.text(issuedBoth), findsNothing);

    await dismissSnackBar(tester);
    await confirmIssueAll(tester);
    expect(backend.issueKeys, hasLength(2));
    expect(backend.issueKeys[1], backend.issueKeys[0]);
    expect(backend.issueExecutions, 1, reason: 'lần hai là phát lại');
    expect(find.text(issuedBoth), findsOneWidget);
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

  /// Chốt cả kỳ trên server rồi mở hóa đơn của Minh Anh phía giáo viên.
  Future<void> openIssuedInvoice(WidgetTester tester) async {
    backend.issueAllNow();
    await openPeriod(tester);
    await tapText(tester, FakeTeachHubBackend.minhAnh.name);
  }

  final minhAnhInvoiceId = FakeTeachHubBackend.invoiceIdOf(
    FakeTeachHubBackend.minhAnh.id,
  );

  /// Phụ huynh mở hóa đơn của Minh Anh ở P03.
  Future<void> parentOpensInvoice(WidgetTester tester) async {
    memberships.set(_state(_parent));
    router.go(TeachHubRoutes.parentInvoices);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(FakeTeachHubBackend.minhAnh.name));
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder f) => tester
      .scrollUntilVisible(f, 300, scrollable: find.byType(Scrollable).first);

  testWidgets('thu tiền: chốt → thu một phần → phụ huynh thấy "một phần" và '
      'biên nhận → thu nốt → "đã thu đủ"', (tester) async {
    await pump(tester);
    seedPayable();
    final minhAnh = FakeTeachHubBackend.minhAnh;
    const fee = FakeTeachHubBackend.feePerSession;
    await openPeriod(tester);
    await confirmIssueAll(tester);
    await dismissSnackBar(tester);

    // Danh sách của kỳ: hóa đơn đã phát hành có lối vào "Thu tiền".
    expect(find.text(tl.billingPayRecord), findsNWidgets(2));
    await tapText(tester, tl.billingPayRecord);
    expect(find.text(minhAnh.name), findsOneWidget);
    expect(find.text(tl.billingPayFull), findsOneWidget);

    // Thu một phần 50.000 đ bằng tiền mặt.
    await tapText(tester, tl.billingPayPartial);
    await tester.enterText(fieldOf(tl.billingPayAmount), '50000');
    await tester.tap(find.text(tl.billingPayMethodCash));
    await tester.pumpAndSettle();
    await tapText(tester, tl.billingPayConfirm);
    expect(find.text(tl.billingPaymentRecorded), findsOneWidget);
    final first = backend.activePaymentsOf(minhAnhInvoiceId).single;
    expect([first['amount'], first['method']], [50000, 'cash']);
    expect(backend.issuedInvoiceOf(minhAnh.id)!['status'], 'partially_paid');
    expect(find.text(tl.billingStatusPartial), findsOneWidget);
    expect(find.text(_vnd(fee - 50000)), findsOneWidget);
    expect(find.textContaining('Cô Lan'), findsOneWidget);
    await dismissSnackBar(tester);

    // Phụ huynh: "đã trả một phần", còn nợ, biên nhận, số cần chuyển (không QR).
    await parentOpensInvoice(tester);
    expect(find.text(pl.invoiceStatusPartial), findsOneWidget);
    expect(find.text(pl.invoiceRemainingAmount), findsOneWidget);
    expect(find.text(_vnd(fee - 50000)), findsOneWidget);
    await scrollTo(tester, find.text(pl.invoiceReceiptsTitle));
    expect(find.textContaining('${pl.invoiceMethodCash} ·'), findsOneWidget);
    // QR mang tổng tiền nên ẩn; hướng dẫn chuyển đúng số còn lại.
    expect(find.byType(QrImageView), findsNothing);
    await scrollTo(tester, find.text('0123456789'));
    expect(
      find.text(pl.invoiceAmountToTransfer(_vnd(fee - 50000))),
      findsOneWidget,
    );
    expect(find.text(pl.invoiceCopyAmount), findsOneWidget);

    // Giáo viên thu nốt bằng "Đã thu đủ": số tiền = còn nợ.
    memberships.set(_state(_teacher));
    await openPeriod(tester);
    await tapText(tester, minhAnh.name);
    await tapText(tester, tl.billingPayFull);
    expect(find.text(_vnd(fee - 50000)), findsWidgets);
    await tapText(tester, tl.billingPayConfirm);
    final payments = backend.activePaymentsOf(minhAnhInvoiceId);
    expect(payments.map((p) => p['amount']), [50000, fee - 50000]);
    expect(backend.issuedInvoiceOf(minhAnh.id)!['status'], 'paid');
    expect(find.text(tl.billingStatusPaid), findsOneWidget);
    expect(find.text(tl.billingPayFull), findsNothing);
    expect(find.text(tl.billingPayPartial), findsNothing);
    await dismissSnackBar(tester);

    // Phụ huynh: đã thu đủ, hai biên nhận, không còn kêu gọi chuyển khoản.
    await parentOpensInvoice(tester);
    expect(find.text(pl.invoiceStatusPaid), findsWidgets);
    expect(find.text(pl.invoicePaidNotice), findsOneWidget);
    expect(find.textContaining('${pl.invoiceMethodCash} ·'), findsOneWidget);
    expect(find.textContaining('${pl.invoiceMethodBank} ·'), findsOneWidget);
    expect(find.byType(QrImageView), findsNothing);
    expect(
      find.text(
        backend.issuedInvoiceOf(minhAnh.id)!['transferNote']! as String,
      ),
      findsNothing,
    );
    expect(find.text('0123456789'), findsNothing);
    await finish(tester);
  });

  testWidgets('thu tiền lỗi mạng rồi bấm lại: cùng Idempotency-Key, chỉ một '
      'thanh toán', (tester) async {
    await pump(tester);
    seedPayable();
    backend.dropNextPayResponse = true; // server đã ghi, phản hồi mất
    await openIssuedInvoice(tester);
    await tapText(tester, tl.billingPayFull);
    await tapText(tester, tl.billingPayConfirm);
    expect(backend.payExecutions, 1);
    expect(find.text(tl.billingPaymentRecorded), findsNothing);

    await tapText(tester, tl.billingPayConfirm);
    expect(backend.payKeys, hasLength(2));
    expect(backend.payKeys[1], backend.payKeys[0]);
    expect(backend.payExecutions, 1, reason: 'lần hai là phát lại');
    expect(backend.activePaymentsOf(minhAnhInvoiceId), hasLength(1));
    expect(find.text(tl.billingPaymentRecorded), findsOneWidget);
    expect(find.text(tl.billingStatusPaid), findsOneWidget);
    await finish(tester);
  });

  testWidgets('hủy thanh toán: giáo viên ghi lý do, phụ huynh thấy biên nhận '
      '"đã hủy" và hóa đơn lại chưa thanh toán', (tester) async {
    await pump(tester);
    seedPayable();
    backend.issueAllNow();
    backend.recordPaymentNow(FakeTeachHubBackend.minhAnh.id, 50000);
    await openPeriod(tester);
    await tapText(tester, FakeTeachHubBackend.minhAnh.name);
    expect(find.text(tl.billingStatusPartial), findsOneWidget);
    await tapText(tester, tl.billingPaymentVoidAction);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(EditableText),
      ),
      'Ghi nhầm',
    );
    await tester.tap(inDialog(tl.billingPaymentVoidAction));
    await tester.pumpAndSettle();
    expect(backend.activePaymentsOf(minhAnhInvoiceId), isEmpty);
    expect(
      backend.issuedInvoiceOf(FakeTeachHubBackend.minhAnh.id)!['status'],
      'issued',
    );
    expect(find.text(tl.billingPaymentVoidedLabel), findsOneWidget);
    expect(find.textContaining('Ghi nhầm'), findsOneWidget);
    await dismissSnackBar(tester);

    await parentOpensInvoice(tester);
    expect(find.text(pl.invoiceReceiptVoided), findsOneWidget);
    expect(find.text(pl.invoiceStatusIssued), findsOneWidget);
    expect(find.text(pl.invoicePaidAmount), findsNothing);
    expect(find.byType(QrImageView), findsOneWidget);
    await finish(tester);
  });

  testWidgets('chữ 130%: chi tiết hóa đơn, form thu (giáo viên) và P03 có biên '
      'nhận (phụ huynh) không vỡ', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pump(tester);
    seedPayable();
    backend.issueAllNow();
    backend.recordPaymentNow(FakeTeachHubBackend.minhAnh.id, 50000);
    await openPeriod(tester);
    await tapText(tester, FakeTeachHubBackend.minhAnh.name);
    await tapText(tester, tl.billingPayPartial);
    expect(tester.takeException(), isNull);
    router.pop();
    await tester.pumpAndSettle();
    await parentOpensInvoice(tester);
    expect(find.text(pl.invoiceReceiptsTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  /// Kỳ 1 chốt, Minh Anh thu một phần 50.000 đ qua màn hình giáo viên, rồi mở kỳ 2
  /// (Minh Anh có học phí tháng 300.000 đ; Bảo Châu không phát sinh nên không có
  /// hóa đơn kỳ 2 và nợ vẫn nằm ở hóa đơn kỳ 1).
  Future<void> collectPartOfPeriod1(WidgetTester tester) async {
    seedPayable();
    await openPeriod(tester);
    await confirmIssueAll(tester);
    await dismissSnackBar(tester);
    await tapText(tester, FakeTeachHubBackend.minhAnh.name);
    await tapText(tester, tl.billingPayPartial);
    await tester.enterText(fieldOf(tl.billingPayAmount), '50000');
    await tester.tap(find.text(tl.billingPayMethodCash));
    await tester.pumpAndSettle();
    await tapText(tester, tl.billingPayConfirm);
    await dismissSnackBar(tester);
    backend.seedNextPeriod(FakeTeachHubBackend.minhAnh.id, 300000);
  }

  /// Mở lại danh sách kỳ từ đầu: đi qua màn chủ để danh sách tải lại (đi thẳng
  /// về `/t/billing` sẽ lộ danh sách cũ còn trong ngăn xếp).
  Future<void> freshBilling(WidgetTester tester) async {
    router.go(TeachHubRoutes.teacher);
    await tester.pumpAndSettle();
    router.go(TeachHubRoutes.teacherBilling);
    await tester.pumpAndSettle();
  }

  Future<void> openPeriod2(WidgetTester tester) async {
    await freshBilling(tester);
    await tapText(
      tester,
      tl.billingPeriodMonth(backend.now.month + 1, backend.now.year),
    );
  }

  testWidgets('chuyển kỳ: kỳ 1 thu một phần → kỳ 2 nháp có "Nợ kỳ trước" → '
      'chốt kỳ 2 theo số dư lúc chốt → hóa đơn kỳ 1 "đã chuyển", phụ huynh '
      'chỉ còn một hóa đơn cần trả', (tester) async {
    await pump(tester);
    final minhAnh = FakeTeachHubBackend.minhAnh;
    final baoChau = FakeTeachHubBackend.baoChau;
    await collectPartOfPeriod1(tester);
    final old1 = FakeTeachHubBackend.invoiceIdOf(minhAnh.id);
    final new2 = FakeTeachHubBackend.invoice2IdOf(minhAnh.id);
    expect(backend.issuedInvoiceOf(minhAnh.id)!['remainingAmount'], 100000);

    // Kỳ 2: bản nháp gồm học phí 300.000 đ + nợ kỳ trước 100.000 đ (xem trước).
    await openPeriod2(tester);
    expect(find.text(minhAnh.name), findsOneWidget);
    expect(find.text(baoChau.name), findsNothing);
    expect(find.text(_vnd(400000)), findsWidgets);
    expect(find.text(tl.billingDraftPreviewNote), findsOneWidget);
    await tapText(tester, minhAnh.name);
    expect(find.text(tl.billingCarryTitle), findsOneWidget);
    expect(find.text(tl.billingCarryDebt), findsOneWidget);
    expect(find.text('+100.000 đ'), findsOneWidget);
    expect(find.text(tl.billingCarryPreviewNote), findsOneWidget);
    expect(find.text(tl.billingVoid), findsNothing);
    router.pop();
    await tester.pumpAndSettle();

    // Thu thêm 20.000 đ ở kỳ 1 từ thiết bị khác trước khi chốt: số dư đổi, tổng
    // cuối là số server tính lúc chốt (380.000 đ), không phải số xem trước.
    backend.recordPaymentNow(minhAnh.id, 20000);
    await confirmIssueAll(tester);
    expect(
      find.text(tl.billingIssuedTotal(1, _vnd(380000))),
      findsOneWidget,
      reason: 'tổng cuối theo phản hồi server',
    );
    final issued2 = backend.issuedInvoiceOf2(minhAnh.id)!;
    expect(issued2['totalAmount'], 380000);
    expect(
      (issued2['lines']! as List)
          .cast<Map>()
          .where((l) => l['kind'] == 'carry_over')
          .map((l) => l['amount']),
      [80000],
    );
    final old = backend.issuedInvoiceOf(minhAnh.id)!;
    expect([old['carriedAmount'], old['remainingAmount']], [80000, 0]);
    expect(
      backend.issuedInvoiceOf(baoChau.id)!['carriedAmount'],
      0,
      reason: 'Bảo Châu không có hóa đơn kỳ 2 nên nợ chưa chuyển',
    );
    await dismissSnackBar(tester);

    // Giáo viên mở lại hóa đơn kỳ 1: ghi "đã chuyển", không còn nút thu/hủy.
    await freshBilling(tester);
    await tapText(
      tester,
      tl.billingPeriodMonth(backend.now.month, backend.now.year),
    );
    await tapText(tester, minhAnh.name);
    expect(find.text(tl.billingCarriedAmount(_vnd(80000))), findsOneWidget);
    expect(find.text(tl.billingPayFull), findsNothing);
    expect(find.text(tl.billingPayPartial), findsNothing);
    expect(find.text(tl.billingVoid), findsNothing);

    // Phụ huynh: hóa đơn kỳ 2 đứng đầu, tổng gồm nợ cũ, có QR đúng tổng.
    memberships.set(_state(_parent));
    router.go(TeachHubRoutes.parentInvoices);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(minhAnh.name).first);
    await tester.pumpAndSettle();
    expect(find.text(pl.invoiceStatusIssued), findsOneWidget);
    expect(find.text(pl.invoiceLineCarryDebt), findsOneWidget);
    expect(find.text(_vnd(80000)), findsOneWidget);
    expect(find.text(_vnd(380000)), findsWidgets);
    final qr2 = issued2['qrPayload']! as String;
    expect(qr2, contains('|380000|'));
    expect(find.byType(QrImageView), findsOneWidget);
    expect(backend.requests, contains('GET /family/invoices/$new2'));

    // Hóa đơn kỳ 1 của phụ huynh: đã chuyển sang kỳ sau, không QR, không kêu
    // gọi chuyển khoản.
    router.go(TeachHubRoutes.parentInvoices);
    await tester.pumpAndSettle();
    expect(find.textContaining(pl.invoiceStatusCarried), findsOneWidget);
    final rows = find.textContaining(minhAnh.name);
    expect(rows, findsNWidgets(2));
    await tester.tap(rows.last);
    await tester.pumpAndSettle();
    expect(find.text(pl.invoiceStatusCarried), findsOneWidget);
    expect(find.text(pl.invoiceCarriedAmount), findsOneWidget);
    expect(find.text(pl.invoiceCarriedNotice), findsOneWidget);
    expect(find.byType(QrImageView), findsNothing);
    expect(find.text(pl.invoiceTransferNote), findsNothing);
    expect(backend.requests, contains('GET /family/invoices/$old1'));
    await finish(tester);
  });

  testWidgets('chuyển kỳ: hủy thanh toán ở hóa đơn đã chuyển nợ thì còn nợ lại '
      'đúng phần chưa chuyển, vẫn thu được; chữ 130% không vỡ', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pump(tester);
    final minhAnh = FakeTeachHubBackend.minhAnh;
    await collectPartOfPeriod1(tester);
    await openPeriod2(tester);
    await confirmIssueAll(tester);
    await dismissSnackBar(tester);
    expect(backend.issuedInvoiceOf(minhAnh.id)!['carriedAmount'], 100000);
    expect(backend.issuedInvoiceOf2(minhAnh.id)!['totalAmount'], 400000);

    // Hủy khoản thu 50.000 đ của hóa đơn kỳ 1: nợ quay lại đúng phần chưa chuyển.
    await freshBilling(tester);
    await tapText(
      tester,
      tl.billingPeriodMonth(backend.now.month, backend.now.year),
    );
    await tapText(tester, minhAnh.name);
    expect(find.text(tl.billingPayFull), findsNothing);
    await tapText(tester, tl.billingPaymentVoidAction);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(EditableText),
      ),
      'Ghi nhầm',
    );
    await tester.tap(inDialog(tl.billingPaymentVoidAction));
    await tester.pumpAndSettle();
    final old = backend.issuedInvoiceOf(minhAnh.id)!;
    expect([old['carriedAmount'], old['remainingAmount']], [100000, 50000]);
    expect(find.text(tl.billingPayFull), findsOneWidget);
    expect(find.text(tl.billingPayPartial), findsOneWidget);
    expect(find.text(tl.billingVoid), findsNothing);
    expect(tester.takeException(), isNull);

    // Thu nốt đúng 50.000 đ còn nợ bằng "Đã thu đủ".
    await dismissSnackBar(tester);
    await tapText(tester, tl.billingPayFull);
    expect(find.text(_vnd(50000)), findsWidgets);
    await tapText(tester, tl.billingPayConfirm);
    expect(backend.issuedInvoiceOf(minhAnh.id)!['remainingAmount'], 0);
    expect(find.text(tl.billingPayFull), findsNothing);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });
}
