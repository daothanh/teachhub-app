// S6-FL-05: số dư chuyển kỳ ở bản nháp, hóa đơn và công nợ của giáo viên.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teacher/features/billing/billing_routes.dart';
import 'package:teacher/features/billing/data/billing_models.dart';
import 'package:teacher/features/billing/data/billing_repository.dart';
import 'package:teacher/features/fees/data/fee_repository.dart';
import 'package:teacher/features/receivables/data/receivables_repository.dart';
import 'package:teacher/features/receivables/receivables_routes.dart';

import '../classes/pump.dart';
import '../fees/fake_fee_repository.dart';
import '../fees/finders.dart';
import '../receivables/fake_receivables_repository.dart';
import 'fake_billing_repository.dart';

void main() {
  late FakeBillingRepository repo;
  late FakeReceivablesRepository receivables;
  setUp(() {
    repo = FakeBillingRepository();
    receivables = FakeReceivablesRepository();
    GetIt.I
      ..registerSingleton<BillingRepository>(repo)
      ..registerSingleton<FeeRepository>(FakeFeeRepository())
      ..registerSingleton<ReceivablesRepository>(receivables);
  });
  tearDown(GetIt.I.reset);

  Future<void> open(
    WidgetTester tester,
    String initial, {
    double scale = 1,
  }) async {
    final router = await pumpRoutes(
      tester,
      [
        GoRoute(path: '/', builder: (_, _) => const Scaffold()),
        ...billingRoutes('teacher'),
        ...receivablesRoutes('teacher'),
      ],
      initial: initial,
      textScale: scale,
    );
    addTearDown(router.dispose);
  }

  final carryDebt = sampleLine(
    id: 'c1',
    kind: InvoiceLineKind.carryOver,
    description: 'Nợ kỳ trước',
    amount: 300000,
    date: null,
    className: null,
  );
  final carryCredit = sampleLine(
    id: 'c2',
    kind: InvoiceLineKind.carryOver,
    description: 'Tiền trả thừa',
    amount: -200000,
    date: null,
    className: null,
  );
  final prevAdjust = sampleLine(
    id: 'c3',
    kind: InvoiceLineKind.prevAdjustment,
    description: 'Buổi 2026-09-20 tính thêm',
    amount: 150000,
    date: null,
    className: 'Toán 9A',
  );

  group('mô hình', () {
    test('nợ đã chuyển: hết nợ thì không ghi thu, không hủy', () {
      final carried = sampleInvoice(
        status: InvoiceStatus.partiallyPaid,
        total: 1200000,
        paid: 500000,
        carried: 700000,
      );
      expect(carried.remainingAmount, 0);
      expect(carried.isCarriedOver, isTrue);
      expect(carried.canRecordPayment, isFalse);
      expect(carried.canVoid, isFalse);
      // Còn nợ lại (vd. hủy thanh toán) thì thu được, vẫn không hủy được.
      final again = sampleInvoice(
        status: InvoiceStatus.partiallyPaid,
        total: 1200000,
        paid: 400000,
        carried: 700000,
      );
      expect(again.remainingAmount, 100000);
      expect(again.canRecordPayment, isTrue);
      expect(again.canVoid, isFalse);
    });

    test('hóa đơn mang dòng chuyển kỳ không hủy được; 0 đ trả bằng số dư', () {
      final withCarry = sampleInvoice(
        status: InvoiceStatus.issued,
        lines: [sampleLine(), carryDebt],
      );
      expect(withCarry.hasCarryLine, isTrue);
      expect(withCarry.canVoid, isFalse);
      expect(sampleInvoice(status: InvoiceStatus.issued).canVoid, isTrue);
      final covered = sampleInvoice(
        status: InvoiceStatus.paid,
        total: 0,
        lines: [sampleLine(), carryCredit],
      );
      expect(covered.isCoveredByBalance, isTrue);
      expect(covered.canRecordPayment, isFalse);
    });

    test('dòng số dư tách khỏi dòng buổi và khoản khác', () {
      final inv = sampleInvoice(
        lines: [
          sampleLine(),
          carryDebt,
          prevAdjust,
          sampleLine(
            id: 'd',
            kind: InvoiceLineKind.discount,
            amount: -10000,
            description: 'Giảm',
          ),
        ],
      );
      expect(inv.carryLines.map((l) => l.id), ['c1', 'c3']);
      expect(inv.otherLines.map((l) => l.id), ['d']);
      expect(inv.sessionLines, hasLength(1));
    });

    test('IssueResult.fromJson đếm hóa đơn 0 đ đã trừ vào số dư', () {
      final r = IssueResult.fromJson({
        'issuedCount': 2,
        'skipped': [],
        'totalAmount': 900000,
        'invoices': [
          {'totalAmount': 900000},
          {'totalAmount': 0},
        ],
      });
      expect(r.coveredCount, 1);
      expect(r.totalAmount, 900000);
    });
  });

  group('chi tiết bản nháp (AC-2)', () {
    testWidgets('dòng nợ kỳ trước, trừ trả thừa, điều chỉnh kỳ trước hiện '
        'tách khỏi buổi, kèm ghi chú xem trước', (tester) async {
      repo.invoice = sampleInvoice(
        total: 400000,
        lines: [sampleLine(), carryDebt, carryCredit, prevAdjust],
      );
      await open(tester, BillingRoutes.invoice('i1'));
      expect(find.text('Số dư kỳ trước'), findsOneWidget);
      expect(find.text('Nợ kỳ trước'), findsOneWidget);
      expect(find.text('+300.000 đ'), findsOneWidget);
      expect(find.text('Trừ tiền trả thừa'), findsOneWidget);
      expect(find.text('−200.000 đ'), findsOneWidget);
      expect(find.text('Điều chỉnh kỳ trước'), findsOneWidget);
      expect(find.text('Buổi 2026-09-20 tính thêm'), findsOneWidget);
      expect(
        find.text('Số này tính theo hiện tại, có thể thay đổi khi chốt.'),
        findsOneWidget,
      );
      expect(find.text('Các buổi học'), findsOneWidget);
      // Không lẫn vào "Khoản khác".
      expect(find.text('Khoản khác'), findsNothing);
    });

    testWidgets('hóa đơn đã chốt: có dòng chuyển kỳ nhưng không ghi chú xem '
        'trước và không có nút hủy', (tester) async {
      repo
        ..invoice = sampleInvoice(
          status: InvoiceStatus.issued,
          total: 450000,
          lines: [sampleLine(), carryDebt],
        )
        ..payments = [];
      await open(tester, BillingRoutes.invoice('i1'));
      expect(find.text('Nợ kỳ trước'), findsOneWidget);
      expect(find.textContaining('có thể thay đổi khi chốt'), findsNothing);
      expect(find.text('Hủy hóa đơn'), findsNothing);
      expect(find.widgetWithText(AppButton, 'Đã thu đủ'), findsOneWidget);
    });

    testWidgets('không có số dư: không hiện mục số dư', (tester) async {
      repo.invoice = sampleInvoice();
      await open(tester, BillingRoutes.invoice('i1'));
      expect(find.text('Số dư kỳ trước'), findsNothing);
    });
  });

  group('hóa đơn đã chuyển nợ (AC-4)', () {
    testWidgets('hết nợ: hiện đã chuyển, ẩn thu tiền và hủy', (tester) async {
      repo
        ..invoice = sampleInvoice(
          status: InvoiceStatus.partiallyPaid,
          total: 1200000,
          paid: 500000,
          carried: 700000,
        )
        ..payments = [samplePayment()];
      await open(tester, BillingRoutes.invoice('i1'));
      expect(find.text('Đã chuyển 700.000 đ sang kỳ sau'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Đã thu đủ'), findsNothing);
      expect(find.widgetWithText(AppButton, 'Thu một phần'), findsNothing);
      expect(find.text('Hủy hóa đơn'), findsNothing);
      expect(
        find.text('Khoản này đã nằm ở hóa đơn kỳ sau, hãy thu ở đó.'),
        findsOneWidget,
      );
    });

    testWidgets('còn nợ sau khi hủy thanh toán: vẫn thu được, không hủy hóa '
        'đơn', (tester) async {
      repo
        ..invoice = sampleInvoice(
          status: InvoiceStatus.partiallyPaid,
          total: 1200000,
          paid: 400000,
          carried: 700000,
        )
        ..payments = [samplePayment(amount: 400000)];
      await open(tester, BillingRoutes.invoice('i1'));
      expect(find.text('Đã chuyển 700.000 đ sang kỳ sau'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Đã thu đủ'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Thu một phần'), findsOneWidget);
      expect(find.text('Hủy hóa đơn'), findsNothing);
      expect(
        find.text('Khoản này đã nằm ở hóa đơn kỳ sau, hãy thu ở đó.'),
        findsNothing,
      );
    });

    testWidgets('chữ 130% không vỡ', (tester) async {
      repo
        ..invoice = sampleInvoice(
          status: InvoiceStatus.partiallyPaid,
          total: 1200000,
          paid: 500000,
          carried: 700000,
          lines: [sampleLine(), carryDebt, carryCredit, prevAdjust],
        )
        ..payments = [samplePayment()];
      await open(tester, BillingRoutes.invoice('i1'), scale: 1.3);
      expect(tester.takeException(), isNull);
    });
  });

  group('hóa đơn 0 đ đã trừ vào số dư (AC-3)', () {
    testWidgets('chi tiết: ghi rõ đã trừ vào số dư, không nút thu/hủy', (
      tester,
    ) async {
      repo
        ..invoice = sampleInvoice(
          status: InvoiceStatus.paid,
          total: 0,
          lines: [sampleLine(), carryCredit],
        )
        ..payments = [];
      await open(tester, BillingRoutes.invoice('i1'), scale: 1.3);
      expect(find.text('Đã trừ vào số dư'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Đã thu đủ'), findsNothing);
      expect(find.widgetWithText(AppButton, 'Thu một phần'), findsNothing);
      expect(find.text('Hủy hóa đơn'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('bản nháp của kỳ với số dư (AC-2, AC-3)', () {
    Future<void> openPeriod(
      WidgetTester tester,
      List<InvoiceSummary> invoices, {
      double scale = 1,
    }) {
      repo.detail = sampleDetail(invoices: invoices);
      return open(tester, BillingRoutes.period(periodId), scale: scale);
    }

    Future<void> confirmIssueAll(WidgetTester tester) async {
      await tapButton(tester, 'Chốt & gửi tất cả');
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Gửi tất cả'),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('ghi chú tổng nháp đã gồm số dư và có thể đổi khi chốt', (
      tester,
    ) async {
      await openPeriod(tester, [sampleSummary(total: 1500000)]);
      expect(find.text('1.500.000 đ'), findsOneWidget);
      expect(
        find.textContaining('đã gồm nợ kỳ trước hoặc tiền trả thừa'),
        findsOneWidget,
      );
    });

    testWidgets('chốt xong: báo tổng cuối theo server, không dùng số xem '
        'trước', (tester) async {
      repo.issueResult = const IssueResult(
        issuedCount: 1,
        skipped: [],
        // Xem trước là 1.500.000 đ; lúc chốt số dư đổi nên server trả 1.650.000 đ.
        totalAmount: 1650000,
      );
      await openPeriod(tester, [sampleSummary(total: 1500000)]);
      await confirmIssueAll(tester);
      expect(find.text('Đã gửi 1 hóa đơn, tổng 1.650.000 đ.'), findsOneWidget);
      expect(find.textContaining('1.500.000 đ.'), findsNothing);
    });

    testWidgets('hóa đơn chốt 0 đ vì trả thừa: báo đã trừ vào số dư', (
      tester,
    ) async {
      repo.issueResult = const IssueResult(
        issuedCount: 2,
        skipped: [],
        totalAmount: 900000,
        coveredCount: 1,
      );
      await openPeriod(tester, [
        sampleSummary(id: 'i1', total: 900000),
        sampleSummary(id: 'i2', name: 'Bình', total: 0),
      ]);
      await confirmIssueAll(tester);
      expect(
        find.text(
          'Đã gửi 2 hóa đơn, tổng 900.000 đ. '
          '1 hóa đơn đã trừ vào số dư, không cần thu.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('hóa đơn đã chốt 0 đ trong kỳ: nhãn đã trừ vào số dư, không '
        'nút thu tiền', (tester) async {
      await openPeriod(tester, [
        sampleSummary(id: 'i2', status: InvoiceStatus.paid, total: 0),
      ], scale: 1.3);
      expect(find.text('Đã trừ vào số dư'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Thu tiền'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('chỉ còn bản nháp 0 đ: vẫn chốt được (số dư có thể trả đủ), '
        'server bỏ qua nếu không có phát sinh', (tester) async {
      repo.issueResult = const IssueResult(
        issuedCount: 0,
        skipped: [IssueSkipped(invoiceId: 'i1', reason: 'ZERO_AMOUNT')],
        totalAmount: 0,
      );
      await openPeriod(tester, [sampleSummary(total: 0)]);
      await tapButton(tester, 'Chốt & gửi tất cả');
      expect(find.textContaining('Chốt các bản nháp 0 đ'), findsOneWidget);
      await tester.tap(find.text('Gửi tất cả'));
      await tester.pumpAndSettle();
      expect(repo.issuedIds, [null]);
      expect(
        find.textContaining('Không có hóa đơn nào cần gửi'),
        findsOneWidget,
      );
    });
  });

  group('công nợ T11 và chi tiết học viên (AC-6)', () {
    testWidgets('nợ ròng + hóa đơn còn nợ + nợ ở sổ', (tester) async {
      receivables.histories['s1'] = sampleHistory(
        id: 's1',
        ledgerBalance: 300000,
      );
      await open(tester, ReceivablesRoutes.student('s1'));
      expect(find.text('Còn nợ 1.000.000 đ'), findsOneWidget);
      expect(find.text('Hóa đơn còn nợ: 700.000 đ'), findsOneWidget);
      expect(find.text('Nợ ở sổ: 300.000 đ'), findsOneWidget);
    });

    testWidgets('trả thừa giảm nợ ròng', (tester) async {
      receivables.histories['s1'] = sampleHistory(
        id: 's1',
        ledgerBalance: -200000,
      );
      await open(tester, ReceivablesRoutes.student('s1'), scale: 1.3);
      expect(find.text('Còn nợ 500.000 đ'), findsOneWidget);
      expect(find.text('Hóa đơn còn nợ: 700.000 đ'), findsOneWidget);
      expect(find.text('Trả thừa: 200.000 đ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sổ cân bằng: không hiện dòng số dư', (tester) async {
      await open(tester, ReceivablesRoutes.student('s1'));
      expect(find.text('Còn nợ 700.000 đ'), findsOneWidget);
      expect(find.textContaining('Nợ ở sổ'), findsNothing);
      expect(find.textContaining('Trả thừa'), findsNothing);
    });
  });
}
