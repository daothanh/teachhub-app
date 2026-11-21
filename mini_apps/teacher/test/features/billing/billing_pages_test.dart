import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teacher/features/billing/billing_routes.dart';
import 'package:teacher/features/billing/data/billing_models.dart';
import 'package:teacher/features/billing/data/billing_repository.dart';
import 'package:teacher/features/fees/data/fee_repository.dart';
import 'package:teacher/features/fees/fees_routes.dart';
import 'package:teacher/features/receivables/data/receivables_repository.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../classes/pump.dart';
import '../fees/fake_fee_repository.dart';
import '../fees/finders.dart';
import '../receivables/fake_receivables_repository.dart';
import 'fake_billing_repository.dart';

void main() {
  late FakeBillingRepository repo;
  late FakeFeeRepository fees;
  setUp(() {
    repo = FakeBillingRepository();
    fees = FakeFeeRepository();
    GetIt.I.registerSingleton<BillingRepository>(repo);
    GetIt.I.registerSingleton<FeeRepository>(fees);
    // Chi tiết hóa đơn đã phát hành tự tải trạng thái nhắc nợ.
    GetIt.I.registerSingleton<ReceivablesRepository>(
      FakeReceivablesRepository(),
    );
  });
  tearDown(GetIt.I.reset);

  Future<GoRouter> open(
    WidgetTester tester,
    String initial, {
    double scale = 1,
  }) async {
    final router = await pumpRoutes(
      tester,
      [
        GoRoute(path: '/', builder: (_, _) => const Scaffold()),
        ...billingRoutes('teacher'),
        ...feesRoutes('teacher'),
      ],
      initial: initial,
      textScale: scale,
    );
    addTearDown(router.dispose);
    return router;
  }

  group('T10 danh sách kỳ (AC-1)', () {
    testWidgets('hiện số bản nháp, tổng tiền; bấm mở bản nháp của kỳ', (
      tester,
    ) async {
      repo
        ..periods = [samplePeriod()]
        ..detail = sampleDetail();
      await open(tester, BillingRoutes.periods);
      expect(find.text('Tháng 10/2026'), findsOneWidget);
      expect(find.textContaining('3 bản nháp · 2.700.000 đ'), findsOneWidget);
      expect(find.text('Chốt 01/11/2026 · Hạn 11/11/2026'), findsOneWidget);
      await tester.tap(find.text('Tháng 10/2026'));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('getPeriod:$periodId'));
      expect(find.text('Chốt & gửi tất cả'), findsOneWidget);
    });

    testWidgets('chưa có kỳ: trạng thái rỗng', (tester) async {
      await open(tester, BillingRoutes.periods);
      expect(find.text('Chưa có kỳ thu nào'), findsOneWidget);
    });

    testWidgets('lỗi mạng: báo và thử lại tải được', (tester) async {
      repo.listError = const ApiException.network();
      await open(tester, BillingRoutes.periods);
      expect(find.text('Thử lại'), findsOneWidget);
      repo
        ..listError = null
        ..periods = [samplePeriod()];
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Tháng 10/2026'), findsOneWidget);
    });

    testWidgets('chữ 130% không vỡ', (tester) async {
      repo.periods = [samplePeriod(issuedCount: 12, issuedTotal: 123456789)];
      await open(tester, BillingRoutes.periods, scale: 1.3);
      expect(tester.takeException(), isNull);
    });
  });

  group('bản nháp của kỳ (AC-1, AC-4, AC-5)', () {
    Future<GoRouter> openPeriod(WidgetTester tester, {double scale = 1}) {
      repo.detail = sampleDetail();
      return open(tester, BillingRoutes.period(periodId), scale: scale);
    }

    testWidgets(
      'từng hóa đơn: trạng thái, tiền, Giá riêng; 0 đ ghi "Không gửi"',
      (tester) async {
        await openPeriod(tester);
        expect(find.text('An'), findsOneWidget);
        expect(find.text('1.200.000 đ'), findsOneWidget);
        expect(find.text('Giá riêng'), findsOneWidget);
        expect(find.text('Bản nháp'), findsNWidgets(3));
        expect(find.text('Không gửi'), findsOneWidget);
        // Chỉ bản nháp có tiền mới có nút chốt riêng.
        expect(find.text('Chốt & gửi'), findsNWidgets(2));
        expect(
          find.text(
            '1 hóa đơn 0 đ: nếu không có khoản phát sinh thì sẽ không được gửi.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('chốt tất cả: có xác nhận; hủy thì không gọi API', (
      tester,
    ) async {
      await openPeriod(tester);
      await tapButton(tester, 'Chốt & gửi tất cả');
      expect(
        find.textContaining('Chốt 2 hóa đơn, tổng 2.700.000 đ'),
        findsOneWidget,
      );
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(repo.issuedIds, isEmpty);
    });

    testWidgets('chốt tất cả: xác nhận → invoiceIds null, báo bỏ qua 0 đ', (
      tester,
    ) async {
      repo.issueResult = const IssueResult(
        issuedCount: 2,
        skipped: [IssueSkipped(invoiceId: 'i3', reason: 'ZERO_AMOUNT')],
        totalAmount: 2700000,
      );
      await openPeriod(tester);
      await tapButton(tester, 'Chốt & gửi tất cả');
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Gửi tất cả'),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.issuedIds, [null]);
      expect(
        find.text(
          'Đã gửi 2 hóa đơn, tổng 2.700.000 đ. 1 hóa đơn 0 đ không gửi.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('chốt từng hóa đơn gửi đúng id', (tester) async {
      await openPeriod(tester);
      await tester.tap(find.text('Chốt & gửi').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('hóa đơn của An'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Chốt & gửi'),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.issuedIds, [
        ['i1'],
      ]);
    });

    testWidgets(
      'PAYOUT_ACCOUNT_MISSING: mở màn tài khoản, quay lại chốt tiếp',
      (tester) async {
        repo.issueError = apiErr(ApiErrorCode.payoutAccountMissing);
        final router = await openPeriod(tester);
        await tapButton(tester, 'Chốt & gửi tất cả');
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Gửi tất cả'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Chưa có tài khoản nhận tiền'), findsOneWidget);
        await tester.tap(find.text('Thêm tài khoản'));
        await tester.pumpAndSettle();
        expect(
          router.state.uri.toString(),
          FeesRoutes.payoutAccounts,
          reason: 'mở thẳng màn tài khoản nhận tiền',
        );
        expect(fees.calls, contains('list'));

        router.pop();
        await tester.pumpAndSettle();
        expect(router.state.uri.toString(), BillingRoutes.period(periodId));
        await tapButton(tester, 'Chốt & gửi tất cả');
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Gửi tất cả'),
          ),
        );
        await tester.pumpAndSettle();
        expect(repo.issuedIds, hasLength(2));
        expect(
          find.text('Đã gửi 2 hóa đơn, tổng 2.700.000 đ.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('409 CONFLICT_STALE khi chốt: báo đã cập nhật, không gửi lại', (
      tester,
    ) async {
      repo.issueError = apiErr(ApiErrorCode.conflictStale);
      await openPeriod(tester);
      await tapButton(tester, 'Chốt & gửi tất cả');
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Gửi tất cả'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('đã cập nhật trạng thái mới nhất'),
        findsOneWidget,
      );
      expect(repo.issuedIds, hasLength(1));
      expect(repo.calls.last, 'getPeriod:$periodId');
    });

    testWidgets(
      '409 mà tải lại kỳ lỗi: báo chưa xác nhận, không nói đã cập nhật',
      (tester) async {
        repo.issueError = apiErr(ApiErrorCode.conflictStale);
        await openPeriod(tester);
        repo.periodError = const ApiException.network();
        await tapButton(tester, 'Chốt & gửi tất cả');
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Gửi tất cả'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Chưa xác nhận được kết quả'),
          findsOneWidget,
        );
        expect(find.textContaining('đã cập nhật trạng thái'), findsNothing);
      },
    );

    testWidgets('lỗi mạng khi chốt: báo lỗi và vẫn bấm lại được', (
      tester,
    ) async {
      repo.issueError = const ApiException.network();
      await openPeriod(tester);
      await tapButton(tester, 'Chốt & gửi tất cả');
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Gửi tất cả'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('mạng'), findsOneWidget);
      expect(repo.keys, hasLength(1));
    });

    testWidgets('không còn bản nháp có tiền: nút chốt tất cả bị khóa', (
      tester,
    ) async {
      repo.detail = sampleDetail(
        invoices: [sampleSummary(status: InvoiceStatus.issued)],
      );
      await open(tester, BillingRoutes.period(periodId));
      expect(
        find.text('Không còn bản nháp nào có tiền để gửi.'),
        findsOneWidget,
      );
      expect(find.text('Đã phát hành'), findsOneWidget);
      expect(find.text('TH-25K7Q9'), findsOneWidget);
    });

    testWidgets('chữ 130% không vỡ', (tester) async {
      await openPeriod(tester, scale: 1.3);
      expect(tester.takeException(), isNull);
    });
  });

  group('chi tiết hóa đơn (AC-2, AC-3, AC-6)', () {
    final lines = [
      sampleLine(id: 'l1'),
      sampleLine(
        id: 'l2',
        description: 'Buổi 2026-10-17 (không tính)',
        amount: 0,
        charged: false,
        reason: NotChargedReason.excused,
        date: '2026-10-17',
      ),
      sampleLine(
        id: 'l3',
        kind: InvoiceLineKind.discount,
        description: 'Con thứ hai',
        amount: -15000,
        date: null,
        className: null,
      ),
      sampleLine(
        id: 'l4',
        kind: InvoiceLineKind.manualAdjustment,
        description: 'Phụ thu tài liệu',
        amount: 20000,
        date: null,
        className: null,
        adjustmentReason: 'Mua giáo trình',
      ),
    ];

    Future<void> openInvoice(
      WidgetTester tester, {
      InvoiceStatus status = InvoiceStatus.draft,
      double scale = 1,
      int clamped = 0,
    }) async {
      repo.invoice = sampleInvoice(
        status: status,
        lines: lines,
        total: 155000,
        clamped: clamped,
      );
      await open(tester, BillingRoutes.invoice('i1'), scale: scale);
    }

    testWidgets(
      'từng buổi: tính/không tính và lý do; dòng giảm, điều chỉnh có dấu',
      (tester) async {
        await openInvoice(tester);
        expect(find.text('15/10/2026 · Toán 9A'), findsOneWidget);
        expect(find.text('Tính tiền'), findsOneWidget);
        expect(find.text('Không tính: vắng có phép'), findsOneWidget);
        expect(find.text('Con thứ hai'), findsOneWidget);
        expect(find.text('−15.000 đ'), findsOneWidget);
        expect(find.text('+20.000 đ'), findsOneWidget);
        expect(find.text('Lý do: Mua giáo trình'), findsOneWidget);
        expect(find.text('155.000 đ'), findsOneWidget);
      },
    );

    testWidgets('phần âm bị cắt được giải thích', (tester) async {
      await openInvoice(tester, clamped: 30000);
      await reveal(tester, find.textContaining('phần âm 30.000 đ'));
      expect(find.textContaining('phần âm 30.000 đ'), findsOneWidget);
    });

    testWidgets('bản nháp có nút điều chỉnh, không có nút hủy', (tester) async {
      await openInvoice(tester);
      expect(find.text('Thêm điều chỉnh'), findsOneWidget);
      expect(find.text('Hủy hóa đơn'), findsNothing);
    });

    testWidgets('điều chỉnh: thiếu lý do báo tại trường, không gọi API', (
      tester,
    ) async {
      await openInvoice(tester);
      await tapButton(tester, 'Thêm điều chỉnh');
      await tester.enterText(fieldOf('Số tiền'), '50000');
      await tester.enterText(fieldOf('Mô tả'), 'Giảm học thử');
      await tapButton(tester, 'Lưu điều chỉnh');
      expect(find.text('Nhập lý do, tối đa 300 ký tự.'), findsOneWidget);
      expect(repo.adjustments, isEmpty);
    });

    testWidgets('điều chỉnh giảm: gửi số âm, tổng cập nhật theo server', (
      tester,
    ) async {
      await openInvoice(tester);
      await tapButton(tester, 'Thêm điều chỉnh');
      await tester.enterText(fieldOf('Số tiền'), '50000');
      await tester.enterText(fieldOf('Mô tả'), 'Giảm học thử');
      await tester.enterText(fieldOf('Lý do (bắt buộc)'), 'Đã thỏa thuận');
      await tapButton(tester, 'Lưu điều chỉnh');
      expect(repo.adjustments.single.amount, -50000);
      expect(repo.adjustments.single.reason, 'Đã thỏa thuận');
      expect(find.text('Đã thêm điều chỉnh.'), findsOneWidget);
      expect(find.text('105.000 đ'), findsOneWidget);
      expect(find.text('Giảm học thử'), findsOneWidget);
    });

    testWidgets('điều chỉnh phụ thu: gửi số dương', (tester) async {
      await openInvoice(tester);
      await tapButton(tester, 'Thêm điều chỉnh');
      await tester.tap(find.text('Phụ thu'));
      await tester.pumpAndSettle();
      await tester.enterText(fieldOf('Số tiền'), '10000');
      await tester.enterText(fieldOf('Mô tả'), 'Tài liệu');
      await tester.enterText(fieldOf('Lý do (bắt buộc)'), 'Mua thêm');
      await tapButton(tester, 'Lưu điều chỉnh');
      expect(repo.adjustments.single.amount, 10000);
    });

    testWidgets('409 INVOICE_IMMUTABLE hiện trong form, không đóng form', (
      tester,
    ) async {
      repo.adjustError = apiErr(ApiErrorCode.invoiceImmutable);
      await openInvoice(tester);
      await tapButton(tester, 'Thêm điều chỉnh');
      await tester.enterText(fieldOf('Số tiền'), '50000');
      await tester.enterText(fieldOf('Mô tả'), 'x');
      await tester.enterText(fieldOf('Lý do (bắt buộc)'), 'y');
      await tapButton(tester, 'Lưu điều chỉnh');
      expect(
        find.textContaining('Hóa đơn đã phát hành nên không sửa được'),
        findsOneWidget,
      );
      expect(find.text('Điều chỉnh hóa đơn'), findsOneWidget);
      // M1: lỗi không được kèm snackbar "đã thêm".
      expect(find.text('Đã thêm điều chỉnh.'), findsNothing);
    });

    testWidgets('422 theo trường hiện đúng dưới ô Số tiền', (tester) async {
      repo.adjustError = fieldErr({
        'amount': ['Số tiền vượt giới hạn'],
      });
      await openInvoice(tester);
      await tapButton(tester, 'Thêm điều chỉnh');
      await tester.enterText(fieldOf('Số tiền'), '50000');
      await tester.enterText(fieldOf('Mô tả'), 'x');
      await tester.enterText(fieldOf('Lý do (bắt buộc)'), 'y');
      await tapButton(tester, 'Lưu điều chỉnh');
      expect(find.text('Số tiền vượt giới hạn'), findsOneWidget);
      expect(find.text('Đã thêm điều chỉnh.'), findsNothing);
    });

    testWidgets('hóa đơn đã phát hành: có nút hủy, không có nút điều chỉnh', (
      tester,
    ) async {
      await openInvoice(tester, status: InvoiceStatus.issued);
      expect(find.text('Thêm điều chỉnh'), findsNothing);
      expect(find.text('Hủy hóa đơn'), findsOneWidget);
    });

    testWidgets('hủy: bắt buộc lý do; có lý do → hóa đơn thành đã hủy', (
      tester,
    ) async {
      await openInvoice(tester, status: InvoiceStatus.issued);
      await tapButton(tester, 'Hủy hóa đơn');
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Hủy hóa đơn'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nhập lý do, tối đa 300 ký tự.'), findsOneWidget);
      expect(repo.calls.where((c) => c.startsWith('void')), isEmpty);

      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(EditableText),
        ),
        'Sai số buổi',
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Hủy hóa đơn'),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.calls.last, 'void:i1:Sai số buổi');
      expect(find.text('Hóa đơn đã hủy. Lý do: Sai số buổi'), findsOneWidget);
      expect(find.text('Hủy hóa đơn'), findsNothing);
    });

    for (final (name, error, text) in [
      (
        '409',
        apiErr(ApiErrorCode.conflictStale),
        'đã cập nhật trạng thái mới nhất',
      ),
      ('mạng', const ApiException.network(), 'mạng'),
    ]) {
      testWidgets('hủy lỗi ($name): có SnackBar lỗi, hóa đơn giữ nguyên', (
        tester,
      ) async {
        repo.voidError = error;
        await openInvoice(tester, status: InvoiceStatus.issued);
        await tapButton(tester, 'Hủy hóa đơn');
        await tester.enterText(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(EditableText),
          ),
          'Sai số buổi',
        );
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Hủy hóa đơn'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byType(SnackBar),
            matching: find.textContaining(text),
          ),
          findsOneWidget,
        );
        expect(find.text('Đã hủy hóa đơn.'), findsNothing);
        expect(find.text('Hủy hóa đơn'), findsOneWidget);
      });
    }

    testWidgets('tải lỗi: thử lại', (tester) async {
      repo.invoiceError = const ApiException.network();
      await open(tester, BillingRoutes.invoice('i1'));
      expect(find.text('Thử lại'), findsOneWidget);
    });

    testWidgets('chữ 130% không vỡ (chi tiết và form điều chỉnh)', (
      tester,
    ) async {
      await openInvoice(tester, scale: 1.3);
      expect(tester.takeException(), isNull);
      await tapButton(tester, 'Thêm điều chỉnh');
      expect(tester.takeException(), isNull);
    });
  });

  group('thanh toán trên chi tiết hóa đơn (US-7.4)', () {
    Future<void> openIssued(
      WidgetTester tester, {
      int paid = 0,
      List<Payment>? payments,
      double scale = 1,
    }) async {
      repo.invoice = sampleInvoice(
        status: paid == 0 ? InvoiceStatus.issued : InvoiceStatus.partiallyPaid,
        total: 1200000,
        paid: paid,
      );
      repo.payments = payments ?? [];
      await open(tester, BillingRoutes.invoice('i1'), scale: scale);
    }

    final dialog = find.byType(AlertDialog);
    Finder inDialog(Finder f) => find.descendant(of: dialog, matching: f);

    testWidgets('hiện đã thu, còn nợ và hai nút ghi thanh toán', (
      tester,
    ) async {
      await openIssued(tester);
      expect(find.text('Đã thu'), findsOneWidget);
      expect(find.text('Còn nợ'), findsOneWidget);
      expect(find.text('0 đ'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Đã thu đủ'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Thu một phần'), findsOneWidget);
    });

    testWidgets('bản nháp không có khối thanh toán', (tester) async {
      repo.invoice = sampleInvoice();
      await open(tester, BillingRoutes.invoice('i1'));
      expect(find.text('Đã thu đủ'), findsNothing);
      expect(find.text('Còn nợ'), findsNothing);
    });

    testWidgets('Đã thu đủ: một chạm mở xác nhận, số tiền = còn nợ, mặc định '
        'chuyển khoản và hôm nay', (tester) async {
      await openIssued(tester);
      await tapButton(tester, 'Đã thu đủ');
      expect(find.text('Ghi nhận đã thu đủ'), findsOneWidget);
      expect(find.text('1.200.000 đ'), findsWidgets);
      expect(repo.paymentInputs, isEmpty, reason: 'chưa xác nhận thì chưa gửi');
      final n = DateTime.now();
      String two(int v) => v.toString().padLeft(2, '0');
      expect(
        find.text('${two(n.day)}/${two(n.month)}/${n.year}'),
        findsOneWidget,
      );
      await tapButton(tester, 'Xác nhận đã thu');
      final sent = repo.paymentInputs.single;
      expect(sent.amount, 1200000);
      expect(sent.method, PaymentMethod.bankTransfer);
      expect(sent.paidOn, '${n.year}-${two(n.month)}-${two(n.day)}');
      expect(find.text('Đã ghi nhận thanh toán.'), findsOneWidget);
      expect(find.text('Ghi nhận đã thu đủ'), findsNothing);
      expect(find.text('Đã thanh toán'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Đã thu đủ'), findsNothing);
      expect(find.widgetWithText(AppButton, 'Thu một phần'), findsNothing);
      expect(find.textContaining('Ghi bởi Cô Lan'), findsOneWidget);
    });

    testWidgets('Thu một phần bằng tiền mặt: gửi đúng, hiện đã thu và còn nợ, '
        'ẩn nút hủy hóa đơn', (tester) async {
      await openIssued(tester);
      expect(find.text('Hủy hóa đơn'), findsOneWidget);
      await tapButton(tester, 'Thu một phần');
      await tester.enterText(fieldOf('Số tiền thu'), '500000');
      await tester.tap(find.text('Tiền mặt'));
      await tester.pumpAndSettle();
      await tapButton(tester, 'Xác nhận đã thu');
      final sent = repo.paymentInputs.single;
      expect([sent.amount, sent.method], [500000, PaymentMethod.cash]);
      expect(find.text('500.000 đ'), findsWidgets);
      expect(find.text('700.000 đ'), findsOneWidget);
      expect(find.text('Đã thanh toán một phần'), findsOneWidget);
      expect(find.textContaining('Tiền mặt ·'), findsOneWidget);
      expect(find.text('Hủy hóa đơn'), findsNothing);
      expect(find.widgetWithText(AppButton, 'Đã thu đủ'), findsOneWidget);
    });

    testWidgets('Thu một phần: số tiền trống báo tại trường, không gọi API', (
      tester,
    ) async {
      await openIssued(tester);
      await tapButton(tester, 'Thu một phần');
      await tapButton(tester, 'Xác nhận đã thu');
      expect(
        find.text('Nhập số tiền thu lớn hơn 0 và không quá 100.000.000.000 đ.'),
        findsOneWidget,
      );
      expect(repo.paymentInputs, isEmpty);
    });

    testWidgets('Thu một phần: số tiền lớn hơn còn nợ có ghi chú phần dư', (
      tester,
    ) async {
      await openIssued(tester);
      await tapButton(tester, 'Thu một phần');
      await tester.enterText(fieldOf('Số tiền thu'), '1300000');
      await tester.pump();
      expect(find.textContaining('Phần dư được ghi lại'), findsOneWidget);
    });

    testWidgets('422 tại trường Ngày thu', (tester) async {
      repo.payError = fieldErr({
        'paidOn': ['Ngày thu không được sau hôm nay'],
      });
      await openIssued(tester);
      await tapButton(tester, 'Đã thu đủ');
      await tapButton(tester, 'Xác nhận đã thu');
      expect(
        find.textContaining('Ngày thu không hợp lệ theo giờ Việt Nam'),
        findsOneWidget,
      );
      expect(find.text('Đã ghi nhận thanh toán.'), findsNothing);
    });

    testWidgets(
      'lỗi mạng rồi bấm lại: cùng Idempotency-Key, ra một thanh toán',
      (tester) async {
        repo.payError = const ApiException.network();
        await openIssued(tester);
        await tapButton(tester, 'Đã thu đủ');
        await tapButton(tester, 'Xác nhận đã thu');
        expect(find.text('Đã ghi nhận thanh toán.'), findsNothing);
        await tapButton(tester, 'Xác nhận đã thu');
        expect(repo.keys, hasLength(2));
        expect(repo.keys[1], repo.keys[0]);
        expect(repo.payments, hasLength(1));
        expect(find.text('Đã ghi nhận thanh toán.'), findsOneWidget);
      },
    );

    testWidgets('INVOICE_NOT_PAYABLE khi thu một phần: báo đúng, tải lại, '
        'không ghi thêm được', (tester) async {
      await openIssued(tester);
      await tapButton(tester, 'Thu một phần');
      await tester.enterText(fieldOf('Số tiền thu'), '500000');
      repo.payError = apiErr(ApiErrorCode.invoiceNotPayable);
      repo.payments = [samplePayment(amount: 1200000)];
      repo.invoiceAfterError = sampleInvoice(
        status: InvoiceStatus.paid,
        total: 1200000,
        paid: 1200000,
      );
      await tapButton(tester, 'Xác nhận đã thu');
      expect(
        find.textContaining('không ghi thanh toán được nữa'),
        findsOneWidget,
      );
      expect(find.text('Đã ghi nhận thanh toán.'), findsNothing);
      final confirm = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Xác nhận đã thu'),
      );
      expect(confirm.disabled, isTrue);
      expect(repo.paymentInputs, hasLength(1));
    });

    testWidgets(
      'INVOICE_NOT_PAYABLE mà tải lại lỗi: báo chưa xác nhận, khóa nút',
      (tester) async {
        await openIssued(tester);
        await tapButton(tester, 'Thu một phần');
        await tester.enterText(fieldOf('Số tiền thu'), '500000');
        repo.payError = apiErr(ApiErrorCode.invoiceNotPayable);
        repo.invoiceError = const ApiException.network();
        await tapButton(tester, 'Xác nhận đã thu');
        expect(
          find.textContaining('Chưa xác nhận được kết quả'),
          findsOneWidget,
        );
        expect(
          find.textContaining('không ghi thanh toán được nữa'),
          findsNothing,
        );
        final confirm = tester.widget<AppButton>(
          find.widgetWithText(AppButton, 'Xác nhận đã thu'),
        );
        expect(confirm.disabled, isTrue);
      },
    );

    group('Đã thu đủ kiểm lại số còn nợ', () {
      Invoice withPaid(int paid, {int total = 1200000}) => sampleInvoice(
        status: paid == 0 ? InvoiceStatus.issued : InvoiceStatus.partiallyPaid,
        total: total,
        paid: paid,
      );

      testWidgets('mở sheet: tải lại và hiện số còn nợ mới nhất', (
        tester,
      ) async {
        await openIssued(tester);
        repo.invoice = withPaid(200000);
        await tapButton(tester, 'Đã thu đủ');
        expect(find.text('1.000.000 đ'), findsWidgets);
        expect(find.textContaining('vừa thay đổi'), findsNothing);
        await tapButton(tester, 'Xác nhận đã thu');
        expect(repo.paymentInputs.single.amount, 1000000);
      });

      testWidgets('mở sheet khi hóa đơn đã thu đủ: không mở, báo trạng thái', (
        tester,
      ) async {
        await openIssued(tester);
        repo.invoice = sampleInvoice(
          status: InvoiceStatus.paid,
          total: 1200000,
          paid: 1200000,
        );
        await tapButton(tester, 'Đã thu đủ');
        expect(find.text('Ghi nhận đã thu đủ'), findsNothing);
        expect(
          find.textContaining('không ghi thanh toán được nữa'),
          findsOneWidget,
        );
        expect(repo.paymentInputs, isEmpty);
        expect(find.widgetWithText(AppButton, 'Đã thu đủ'), findsNothing);
      });

      for (final (name, fresh, shown) in [
        ('nhỏ hơn', withPaid(200000), '1.000.000 đ'),
        ('lớn hơn', withPaid(0, total: 1500000), '1.500.000 đ'),
      ]) {
        testWidgets('số còn nợ đổi $name sau khi mở sheet: không gửi, hiện số '
            'mới, xác nhận lại mới gửi', (tester) async {
          await openIssued(tester);
          await tapButton(tester, 'Đã thu đủ');
          repo.invoice = fresh;
          await tapButton(tester, 'Xác nhận đã thu');
          expect(repo.paymentInputs, isEmpty);
          expect(find.textContaining('Số còn nợ vừa thay đổi'), findsOneWidget);
          expect(find.text(shown), findsWidgets);
          await tapButton(tester, 'Xác nhận đã thu');
          expect(repo.paymentInputs.single.amount, fresh.remainingAmount);
          expect(find.text('Đã ghi nhận thanh toán.'), findsOneWidget);
        });
      }

      testWidgets('hóa đơn thành đã thu đủ sau khi mở sheet: đóng sheet, báo '
          'trạng thái, không gửi', (tester) async {
        await openIssued(tester);
        await tapButton(tester, 'Đã thu đủ');
        repo.invoice = sampleInvoice(
          status: InvoiceStatus.paid,
          total: 1200000,
          paid: 1200000,
        );
        await tapButton(tester, 'Xác nhận đã thu');
        expect(repo.paymentInputs, isEmpty);
        expect(find.text('Ghi nhận đã thu đủ'), findsNothing);
        expect(
          find.textContaining('không ghi thanh toán được nữa'),
          findsOneWidget,
        );
      });
    });

    testWidgets('ghi chú tùy chọn được gửi (đã cắt khoảng trắng)', (
      tester,
    ) async {
      await openIssued(tester);
      await tapButton(tester, 'Thu một phần');
      await tester.enterText(fieldOf('Số tiền thu'), '500000');
      await tester.enterText(
        fieldOf('Ghi chú (chỉ bạn thấy)'),
        '  Đóng tiền mặt  ',
      );
      await tapButton(tester, 'Xác nhận đã thu');
      expect(repo.paymentInputs.single.toJson()['note'], 'Đóng tiền mặt');
    });

    testWidgets(
      'biên số tiền: 0 và 12 chữ số báo tại trường, đúng trần thì gửi',
      (tester) async {
        await openIssued(tester);
        await tapButton(tester, 'Thu một phần');
        const msg =
            'Nhập số tiền thu lớn hơn 0 và không quá 100.000.000.000 đ.';
        await tester.enterText(fieldOf('Số tiền thu'), '0');
        await tapButton(tester, 'Xác nhận đã thu');
        expect(find.text(msg), findsOneWidget);
        await tester.enterText(fieldOf('Số tiền thu'), '123456789012');
        await tapButton(tester, 'Xác nhận đã thu');
        expect(find.text(msg), findsOneWidget);
        expect(repo.paymentInputs, isEmpty);
        await tester.enterText(fieldOf('Số tiền thu'), '100000000000');
        await tapButton(tester, 'Xác nhận đã thu');
        expect(repo.paymentInputs.single.amount, 100000000000);
      },
    );

    testWidgets('409 CONFLICT_STALE khi ghi: báo đã cập nhật', (tester) async {
      repo.payError = apiErr(ApiErrorCode.conflictStale);
      await openIssued(tester);
      await tapButton(tester, 'Đã thu đủ');
      await tapButton(tester, 'Xác nhận đã thu');
      expect(
        find.textContaining('đã cập nhật trạng thái mới nhất'),
        findsOneWidget,
      );
    });

    testWidgets('hủy thanh toán: bắt buộc lý do; sau hủy hiện nhãn Đã hủy, '
        'gạch số tiền, hóa đơn về đã phát hành', (tester) async {
      await openIssued(tester, paid: 500000, payments: [samplePayment()]);
      repo.invoice = sampleInvoice(
        status: InvoiceStatus.partiallyPaid,
        total: 1200000,
        paid: 500000,
      );
      await tester.tap(find.text('Hủy thanh toán'));
      await tester.pumpAndSettle();
      await tester.tap(inDialog(find.text('Hủy thanh toán')));
      await tester.pumpAndSettle();
      expect(find.text('Nhập lý do, tối đa 300 ký tự.'), findsOneWidget);
      expect(repo.calls.where((c) => c.startsWith('voidPayment')), isEmpty);

      await tester.enterText(inDialog(find.byType(EditableText)), 'Ghi nhầm');
      await tester.tap(inDialog(find.text('Hủy thanh toán')));
      await tester.pumpAndSettle();
      expect(repo.calls.last, 'voidPayment:p1:Ghi nhầm');
      expect(find.text('Đã hủy thanh toán.'), findsOneWidget);
      expect(find.text('Đã hủy'), findsOneWidget);
      expect(
        find.textContaining('Hủy bởi Cô Lan. Lý do: Ghi nhầm'),
        findsOneWidget,
      );
      final amount = tester.widget<Text>(find.text('500.000 đ'));
      expect(amount.style?.decoration, TextDecoration.lineThrough);
      expect(find.text('Hủy thanh toán'), findsNothing);
      expect(find.text('Đã phát hành'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Đã thu đủ'), findsOneWidget);
    });

    testWidgets('thanh toán đã hủy hiện sẵn khi mở hóa đơn, không có nút hủy', (
      tester,
    ) async {
      await openIssued(tester, payments: [samplePayment(voided: true)]);
      expect(find.text('Đã hủy'), findsOneWidget);
      expect(find.text('Hủy thanh toán'), findsNothing);
    });

    testWidgets('hủy thanh toán lỗi mạng: báo lỗi, thanh toán giữ nguyên', (
      tester,
    ) async {
      repo.voidPaymentError = const ApiException.network();
      await openIssued(tester, paid: 500000, payments: [samplePayment()]);
      await tester.tap(find.text('Hủy thanh toán'));
      await tester.pumpAndSettle();
      await tester.enterText(inDialog(find.byType(EditableText)), 'Ghi nhầm');
      await tester.tap(inDialog(find.text('Hủy thanh toán')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.textContaining('mạng'),
        ),
        findsOneWidget,
      );
      expect(find.text('Đã hủy thanh toán.'), findsNothing);
      expect(find.text('Hủy thanh toán'), findsOneWidget);
    });

    testWidgets('danh sách của kỳ: hóa đơn đã phát hành có nút Thu tiền mở chi '
        'tiết hóa đơn', (tester) async {
      repo
        ..periods = [samplePeriod()]
        ..invoice = sampleInvoice(status: InvoiceStatus.issued)
        ..detail = sampleDetail(
          invoices: [
            sampleSummary(id: 'i1', status: InvoiceStatus.issued),
            sampleSummary(id: 'i2', status: InvoiceStatus.paid),
            sampleSummary(id: 'i3'),
          ],
        );
      await open(tester, BillingRoutes.period(periodId));
      expect(find.widgetWithText(AppButton, 'Thu tiền'), findsOneWidget);
      await tester.tap(find.widgetWithText(AppButton, 'Thu tiền'));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('getInvoice:i1'));
      expect(find.text('Đã thu đủ'), findsOneWidget);
    });

    testWidgets('chữ 130% không vỡ (khối thanh toán, form thu, danh sách)', (
      tester,
    ) async {
      await openIssued(
        tester,
        paid: 500000,
        payments: [
          samplePayment(),
          samplePayment(id: 'p0', voided: true, method: PaymentMethod.cash),
        ],
        scale: 1.3,
      );
      expect(tester.takeException(), isNull);
      await tapButton(tester, 'Thu một phần');
      expect(tester.takeException(), isNull);
      await tester.enterText(fieldOf('Số tiền thu'), '9999999');
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
