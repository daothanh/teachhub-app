import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:parent/features/family/data/family_models.dart';
import 'package:parent/features/family/data/family_repository.dart';
import 'package:parent/features/invoice/cubit/invoice_detail_cubit.dart';
import 'package:parent/features/invoice/cubit/invoice_list_cubit.dart';
import 'package:parent/features/invoice/data/invoice_models.dart';
import 'package:parent/features/invoice/data/invoice_repository.dart';
import 'package:parent/features/invoice/data/qr_image_saver.dart';
import 'package:parent/features/invoice/widgets/invoice_format.dart';
import 'package:parent/l10n/l10n.dart';
import 'package:parent/parent.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

final _rowTitle = 'Minh Anh, ${DateFormat.yM('en').format(DateTime(2026, 12))}';
Map<String, dynamic> _receipt({
  String id = 'p1',
  int amount = 500000,
  String method = 'bank_transfer',
  String paidOn = '2026-12-05',
  bool voided = false,
}) => {
  'id': id,
  'amount': amount,
  'method': method,
  'paidOn': paidOn,
  'recordedAt': '2026-12-05T02:12:00.000Z',
  'voidedAt': voided ? '2026-12-06T02:00:00.000Z' : null,
};

final _due = DateFormat.yMd('en').format(DateTime(2026, 12, 15));
const _id = '019c0a10-0001-7b30-8c01-000000000001';

Map<String, dynamic> _json({
  String id = _id,
  String status = 'issued',
  int total = 1500000,
  int paid = 0,
  List<Map<String, dynamic>> payments = const [],
  bool voided = false,
}) => {
  'id': id,
  'code': 'TH-25K7Q9',
  'status': voided ? 'void' : status,
  'studentId': 'a',
  'studentName': 'Minh Anh',
  'teacherName': 'Cô Lan',
  'periodMonth': '2026-12-01',
  'totalAmount': total,
  'paidAmount': paid,
  'remainingAmount': voided ? 0 : (total - paid).clamp(0, total),
  'dueDate': '2026-12-15',
  'issuedAt': '2026-12-01T01:00:00.000Z',
  'lines': [
    {
      'kind': 'monthly',
      'className': 'Toán 9A',
      'description': 'Học phí tháng 12',
      'amount': 1500000,
    },
  ],
  'payments': payments,
  'transferNote': 'TH 25K7Q9',
  'qrPayload': voided ? null : 'vietqr-payload-secret',
  'payout': voided
      ? null
      : {
          'bankBin': '970436',
          'bankName': 'Vietcombank',
          'accountNo': '0011223344',
          'accountName': 'NGUYEN VAN A',
        },
  'voidedAt': voided ? '2026-12-02T01:00:00.000Z' : null,
};

class _FakeInvoices implements InvoiceRepository {
  final pages = <InvoicePage>[];
  final listCalls = <({String? cursor, InvoiceStatus? status})>[];
  Object? detailError;
  Map<String, dynamic> detailJson = _json();
  Object? listError;

  @override
  Future<InvoicePage> list({
    String? cursor,
    InvoiceStatus? status,
    String? studentId,
    int limit = 20,
  }) async {
    listCalls.add((cursor: cursor, status: status));
    if (listError != null) throw listError!;
    return cursor == null ? pages.first : pages.last;
  }

  @override
  Future<InvoiceDetail> detail(String id) async {
    if (detailError != null) throw detailError!;
    return InvoiceDetail.fromJson(detailJson);
  }
}

/// Trang đầu trả ngay; trang có cursor chờ [gate].
class _GatedInvoices implements InvoiceRepository {
  late InvoicePage first;
  late InvoicePage second;
  final gate = Completer<void>();

  @override
  Future<InvoicePage> list({
    String? cursor,
    InvoiceStatus? status,
    String? studentId,
    int limit = 20,
  }) async {
    if (cursor == null) return first;
    await gate.future;
    return second;
  }

  @override
  Future<InvoiceDetail> detail(String id) => throw UnimplementedError();
}

class _FakeSaver implements QrImageSaver {
  final saved = <String>[];
  Object? error;
  @override
  Future<void> save(String qrPayload, {required String name}) async {
    if (error != null) throw error!;
    saved.add(qrPayload);
  }
}

class _FamilyRepo implements FamilyRepository {
  @override
  Future<List<FamilyStudent>> students() async => const [
    FamilyStudent(id: 'a', fullName: 'Minh Anh', classes: []),
  ];

  @override
  Future<AttendanceWeek> attendance(String studentId, {DateTime? week}) async =>
      AttendanceWeek(
        studentId: studentId,
        weekStart: DateTime(2026, 12, 14),
        weekEnd: DateTime(2026, 12, 20),
        summary: const AttendanceSummary(
          present: 0,
          late: 0,
          excused: 0,
          unexcused: 0,
          notRecorded: 0,
          upcoming: 0,
        ),
        sessions: const [],
      );
}

InvoicePage _page(List<Map<String, dynamic>> items, [String? next]) =>
    InvoicePage.fromJson({'items': items, 'nextCursor': next});

ApiException _http(int status, [String? code]) =>
    ApiException.fromResponse(status, {'code': code});

Future<void> _pump(
  WidgetTester tester,
  _FakeInvoices repo,
  _FakeSaver saver, {
  String location = TeachHubRoutes.parent,
  double textScale = 1,
}) async {
  // Màn cao để nút ở cuối chi tiết hóa đơn nằm trong khung nhìn.
  tester.view
    ..physicalSize = const Size(800, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final c = ParentController.instance
    ..familyRepository = _FamilyRepo()
    ..invoiceRepository = repo
    ..qrImageSaver = saver;
  addTearDown(() {
    c
      ..familyRepository = null
      ..invoiceRepository = null
      ..qrImageSaver = null;
  });
  final router = GoRouter(initialLocation: location, routes: c.routes());
  await tester.pumpWidget(
    ScreenUtilPlusInit(
      designSize: const Size(393, 852),
      builder: (context, _) => MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: const [
          ...MiniAppLocalizations.localizationsDelegates,
          TascoUiKitLocalizations.delegate,
        ],
        supportedLocales: MiniAppLocalizations.supportedLocales,
        theme: AppTheme.v1,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('InvoiceListCubit', () {
    test('load, loadMore theo con trỏ, đổi bộ lọc', () async {
      final repo = _FakeInvoices()
        ..pages.addAll([
          _page([_json()], 'c2'),
          _page([_json(id: 'x2', status: 'paid')]),
        ]);
      final cubit = InvoiceListCubit(repo);
      await cubit.load();
      expect(cubit.state.items.length, 1);
      expect(cubit.state.hasMore, isTrue);

      await cubit.loadMore();
      expect(cubit.state.items.map((i) => i.id), [_id, 'x2']);
      expect(cubit.state.hasMore, isFalse);
      expect(repo.listCalls.last.cursor, 'c2');

      await cubit.load(filter: InvoiceStatus.paid);
      expect(repo.listCalls.last.status, InvoiceStatus.paid);
      expect(cubit.state.filter, InvoiceStatus.paid);
      await cubit.close();
    });

    test('lỗi tải → failure', () async {
      final repo = _FakeInvoices()..listError = const ApiException.network();
      final cubit = InvoiceListCubit(repo);
      await cubit.load();
      expect(cubit.state.status, InvoiceListStatus.failure);
      await cubit.close();
    });
  });

  test('loadMore đang chờ rồi refresh: trang cũ không nối vào', () async {
    final repo = _GatedInvoices()
      ..first = _page([_json()], 'c2')
      ..second = _page([_json(id: 'old')]);
    final cubit = InvoiceListCubit(repo);
    await cubit.load();
    final more = cubit.loadMore();
    await Future<void>.delayed(Duration.zero);
    repo.first = _page([_json(id: 'fresh')]);
    await cubit.load(keepFilter: true);
    repo.gate.complete();
    await more;
    expect(cubit.state.items.map((i) => i.id), ['fresh']);
    expect(cubit.state.loadingMore, isFalse);
    await cubit.close();
  });

  test('formatVndFor: 150.000 đ, dấu chấm nghìn, chữ đ thường', () {
    expect(formatVndFor('vi', 150000), '150.000 đ');
    expect(formatVndFor('vi', -50000), '-50.000 đ');
    expect(formatVndFor('vi', 0), '0 đ');
  });

  testWidgets('ảnh QR lưu: module nguyên px, viền trắng từ 4 module', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final png = await renderQrPng('vietqr-payload-secret');
      final codec = await ui.instantiateImageCodec(png.bytes);
      final img = (await codec.getNextFrame()).image;
      expect(img.width, (png.moduleCount + 8) * QrPng.px);
      expect(img.height, img.width);
      final rgba = (await img.toByteData())!;
      bool white(int x, int y) =>
          rgba.getUint32((y * img.width + x) * 4) == 0xFFFFFFFF;
      final border = QrPng.quiet * QrPng.px;
      for (var i = 0; i < img.width; i++) {
        for (var d = 0; d < border; d++) {
          expect(white(i, d), isTrue);
          expect(white(i, img.width - 1 - d), isTrue);
          expect(white(d, i), isTrue);
          expect(white(img.width - 1 - d, i), isTrue);
        }
      }
      // Ô định vị góc trên trái đen ngay sau viền.
      expect(white(border, border), isFalse);
    });
  });

  group('InvoiceDetailCubit', () {
    test('chi tiết có QR và tài khoản nhận', () async {
      final cubit = InvoiceDetailCubit(_FakeInvoices(), _FakeSaver(), _id);
      await cubit.load();
      expect(cubit.state.status, InvoiceDetailStatus.ready);
      expect(cubit.state.invoice!.payout!.accountNo, '0011223344');
      expect(cubit.state.invoice!.lines.single.className, 'Toán 9A');
      await cubit.close();
    });

    test('hóa đơn void: không QR, không payout, không lỗi', () async {
      final repo = _FakeInvoices()..detailJson = _json(voided: true);
      final saver = _FakeSaver();
      final cubit = InvoiceDetailCubit(repo, saver, _id);
      await cubit.load();
      expect(cubit.state.status, InvoiceDetailStatus.ready);
      expect(cubit.state.invoice!.summary.status, InvoiceStatus.voided);
      expect(cubit.state.invoice!.qrPayload, isNull);
      expect(cubit.state.invoice!.payout, isNull);
      await cubit.saveQr();
      expect(cubit.state.qrSave, QrSaveStatus.idle);
      expect(saver.saved, isEmpty);
      await cubit.close();
    });

    test('404 → notFound; lỗi khác → failure', () async {
      final repo = _FakeInvoices()..detailError = _http(404, 'NOT_FOUND');
      final cubit = InvoiceDetailCubit(repo, _FakeSaver(), _id);
      await cubit.load();
      expect(cubit.state.status, InvoiceDetailStatus.notFound);
      repo.detailError = const ApiException.network();
      await cubit.load();
      expect(cubit.state.status, InvoiceDetailStatus.failure);
      await cubit.close();
    });

    test('lưu ảnh QR: thành công, bị từ chối quyền, lỗi khác', () async {
      final saver = _FakeSaver();
      final cubit = InvoiceDetailCubit(_FakeInvoices(), saver, _id);
      await cubit.load();
      await cubit.saveQr();
      expect(saver.saved, ['vietqr-payload-secret']);
      expect(cubit.state.qrSave, QrSaveStatus.saved);
      saver.error = const QrSaveDenied();
      await cubit.saveQr();
      expect(cubit.state.qrSave, QrSaveStatus.denied);
      saver.error = StateError('x');
      await cubit.saveQr();
      expect(cubit.state.qrSave, QrSaveStatus.failed);
      await cubit.close();
    });

    test(
      'biên nhận và số liệu thanh toán đọc đúng; method lạ → chuyển khoản',
      () {
        final d = InvoiceDetail.fromJson(
          _json(
            status: 'partially_paid',
            paid: 500000,
            payments: [
              _receipt(),
              _receipt(id: 'p2', method: 'cash', voided: true),
              _receipt(id: 'p3', method: 'crypto'),
            ],
          ),
        );
        expect(
          [d.summary.paidAmount, d.summary.remainingAmount],
          [500000, 1000000],
        );
        expect(d.payments.map((p) => p.voided), [false, true, false]);
        expect(d.payments.map((p) => p.method), [
          PaymentMethod.bankTransfer,
          PaymentMethod.cash,
          PaymentMethod.bankTransfer,
        ]);
        expect(d.payments.first.paidOn, DateTime(2026, 12, 5));
      },
    );

    test('status lạ không làm vỡ model', () {
      expect(InvoiceStatus.fromWire('abc'), InvoiceStatus.unknown);
      expect(InvoiceStatus.fromWire('void'), InvoiceStatus.voided);
      expect(
        InvoiceStatus.fromWire('partially_paid'),
        InvoiceStatus.partiallyPaid,
      );
    });
  });

  group('widget', () {
    testWidgets('P02 có card học phí, bấm mở danh sách P03', (tester) async {
      final repo = _FakeInvoices()
        ..pages.add(
          _page([
            _json(),
            _json(
              id: 'i2',
              total: 500000,
              paid: 200000,
              status: 'partially_paid',
            ),
            _json(id: 'i3', status: 'paid'),
          ]),
        );
      await _pump(tester, repo, _FakeSaver());
      expect(
        find.text('2 invoices not settled, 1,800,000 đ outstanding'),
        findsOneWidget,
      );
      await tester.tap(find.text('Tuition'));
      await tester.pumpAndSettle();
      expect(find.text('Invoices'), findsOneWidget);
      expect(find.text(_rowTitle), findsNWidgets(3));
      expect(find.text('Paid · Due $_due'), findsOneWidget);
    });

    testWidgets('card học phí còn trang sau: hiện "N+", không hiện tổng', (
      tester,
    ) async {
      final repo = _FakeInvoices()..pages.add(_page([_json()], 'c2'));
      await _pump(tester, repo, _FakeSaver());
      expect(find.text('1+ invoices not settled'), findsOneWidget);
    });

    testWidgets('danh sách: bấm hóa đơn mở chi tiết với QR và tài khoản', (
      tester,
    ) async {
      final repo = _FakeInvoices()..pages.add(_page([_json()]));
      await _pump(
        tester,
        repo,
        _FakeSaver(),
        location: TeachHubRoutes.parentInvoices,
      );
      await tester.tap(find.text(_rowTitle));
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('Vietcombank'), findsOneWidget);
      expect(find.text('0011223344'), findsOneWidget);
      expect(find.text('Toán 9A'), findsOneWidget);
    });

    testWidgets('chi tiết void: báo đã hủy, không QR, không tài khoản', (
      tester,
    ) async {
      final repo = _FakeInvoices()..detailJson = _json(voided: true);
      await _pump(
        tester,
        repo,
        _FakeSaver(),
        location: '${TeachHubRoutes.parentInvoices}/$_id',
      );
      expect(find.text('Cancelled'), findsOneWidget);
      expect(
        find.text('This invoice was cancelled. No payment needed.'),
        findsOneWidget,
      );
      expect(find.byType(QrImageView), findsNothing);
      expect(find.text('Account number'), findsNothing);
    });

    testWidgets('thu một phần: hiện đã thanh toán, còn nợ, biên nhận và vẫn '
        'ẩn QR, hướng dẫn chuyển đúng số còn lại', (tester) async {
      final repo = _FakeInvoices()
        ..detailJson = _json(
          status: 'partially_paid',
          paid: 500000,
          payments: [
            _receipt(),
            _receipt(id: 'p0', amount: 100000, method: 'cash'),
          ],
        );
      await _pump(
        tester,
        repo,
        _FakeSaver(),
        location: '${TeachHubRoutes.parentInvoices}/$_id',
      );
      expect(find.text('Partially paid'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);
      expect(
        find.text('500,000 đ'),
        findsNWidgets(2),
        reason: 'dòng đã trả + biên nhận',
      );
      expect(find.text('Outstanding'), findsOneWidget);
      expect(find.text('1,000,000 đ'), findsOneWidget);
      expect(find.text('Receipts'), findsOneWidget);
      final d = DateFormat.yMd('en').format(DateTime(2026, 12, 5));
      expect(find.text('Bank transfer · Received $d'), findsOneWidget);
      expect(find.text('Cash · Received $d'), findsOneWidget);
      expect(find.text('Voided'), findsNothing);
      expect(find.byType(QrImageView), findsNothing);
      expect(find.text('Save QR image'), findsNothing);
      expect(find.textContaining('do not scan it'), findsOneWidget);
      expect(find.text('Amount to transfer: 1,000,000 đ'), findsOneWidget);
      expect(find.text('Vietcombank'), findsOneWidget);
      expect(find.text('0011223344'), findsOneWidget);
      expect(find.text('TH 25K7Q9'), findsOneWidget);
    });

    testWidgets('chưa thu: còn nợ bằng tổng, chưa có biên nhận', (
      tester,
    ) async {
      await _pump(
        tester,
        _FakeInvoices(),
        _FakeSaver(),
        location: '${TeachHubRoutes.parentInvoices}/$_id',
      );
      expect(find.text('Outstanding'), findsOneWidget);
      expect(find.text('Paid'), findsNothing, reason: 'chưa có khoản đã trả');
      expect(find.text('Receipts'), findsNothing);
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('đã thu đủ: có biên nhận, không còn kêu gọi chuyển khoản', (
      tester,
    ) async {
      final repo = _FakeInvoices()
        ..detailJson = _json(
          status: 'paid',
          paid: 1500000,
          payments: [_receipt(amount: 1500000)],
        );
      await _pump(
        tester,
        repo,
        _FakeSaver(),
        location: '${TeachHubRoutes.parentInvoices}/$_id',
      );
      expect(
        find.text('Paid'),
        findsNWidgets(2),
        reason: 'nhãn trạng thái + dòng đã trả',
      );
      expect(find.text('0 đ'), findsOneWidget);
      expect(
        find.text('This invoice is paid in full. No transfer needed.'),
        findsOneWidget,
      );
      expect(find.text('Receipts'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
      expect(find.text('Account number'), findsNothing);
      expect(find.text('Copy transfer note'), findsNothing);
    });

    testWidgets(
      'biên nhận đã hủy: gạch số tiền, có nhãn Voided, không tính vào '
      'đã trả',
      (tester) async {
        final repo = _FakeInvoices()
          ..detailJson = _json(payments: [_receipt(voided: true)]);
        await _pump(
          tester,
          repo,
          _FakeSaver(),
          location: '${TeachHubRoutes.parentInvoices}/$_id',
        );
        expect(find.text('Voided'), findsOneWidget);
        final amount = tester.widget<Text>(find.text('500,000 đ'));
        expect(amount.style?.decoration, TextDecoration.lineThrough);
        expect(find.text('Paid'), findsNothing);
        expect(find.text('1,500,000 đ'), findsWidgets);
        expect(find.byType(QrImageView), findsOneWidget);
      },
    );

    testWidgets(
      'thu một phần: sao chép số tiền còn lại và nội dung chuyển khoản',
      (tester) async {
        final copied = <String>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copied.add((call.arguments as Map)['text'] as String);
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        final repo = _FakeInvoices()
          ..detailJson = _json(
            status: 'partially_paid',
            paid: 500000,
            payments: [_receipt()],
          );
        await _pump(
          tester,
          repo,
          _FakeSaver(),
          location: '${TeachHubRoutes.parentInvoices}/$_id',
        );
        await tester.scrollUntilVisible(
          find.text('Copy transfer note'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Copy amount'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Copy transfer note'));
        await tester.pumpAndSettle();
        expect(copied, ['1000000', 'TH 25K7Q9']);
      },
    );

    testWidgets('chữ 130% không vỡ ở chi tiết có biên nhận', (tester) async {
      final repo = _FakeInvoices()
        ..detailJson = _json(
          status: 'partially_paid',
          paid: 600000,
          payments: [
            _receipt(),
            _receipt(id: 'p0', amount: 100000, voided: true),
          ],
        );
      await _pump(
        tester,
        repo,
        _FakeSaver(),
        location: '${TeachHubRoutes.parentInvoices}/$_id',
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Copy account number'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('404 → màn không tìm thấy hóa đơn', (tester) async {
      final repo = _FakeInvoices()..detailError = _http(404, 'NOT_FOUND');
      await _pump(
        tester,
        repo,
        _FakeSaver(),
        location: '${TeachHubRoutes.parentInvoices}/$_id',
      );
      expect(find.text('Invoice not found'), findsOneWidget);
    });

    testWidgets('lưu ảnh QR gọi saver và báo kết quả', (tester) async {
      final saver = _FakeSaver();
      await _pump(
        tester,
        _FakeInvoices(),
        saver,
        location: '${TeachHubRoutes.parentInvoices}/$_id',
      );
      await tester.tap(find.text('Save QR image'));
      await tester.pumpAndSettle();
      expect(saver.saved, ['vietqr-payload-secret']);
      expect(find.text('QR image saved.'), findsOneWidget);
    });

    testWidgets('lưu ảnh bị từ chối quyền → nhắc cấp quyền', (tester) async {
      final saver = _FakeSaver()..error = const QrSaveDenied();
      await _pump(
        tester,
        _FakeInvoices(),
        saver,
        location: '${TeachHubRoutes.parentInvoices}/$_id',
      );
      await tester.tap(find.text('Save QR image'));
      await tester.pumpAndSettle();
      expect(
        find.text('No permission to save photos. Allow it in Settings.'),
        findsOneWidget,
      );
    });

    testWidgets('sao chép nội dung chuyển khoản và số tài khoản', (
      tester,
    ) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await _pump(
        tester,
        _FakeInvoices(),
        _FakeSaver(),
        location: '${TeachHubRoutes.parentInvoices}/$_id',
      );
      await tester.scrollUntilVisible(
        find.text('Copy account number'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Copy transfer note'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy account number'));
      await tester.pumpAndSettle();
      expect(copied, ['TH 25K7Q9', '0011223344']);
      expect(find.text('Copied.'), findsOneWidget);
    });
  });
}
