import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:teacher/features/billing/billing_routes.dart';
import 'package:teacher/features/billing/data/billing_models.dart';
import 'package:teacher/features/billing/data/billing_repository.dart';
import 'package:teacher/features/fees/data/fee_repository.dart';
import 'package:teacher/features/fees/fees_routes.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../classes/pump.dart';
import '../fees/fake_fee_repository.dart';
import '../fees/finders.dart';
import 'fake_billing_repository.dart';

void main() {
  late FakeBillingRepository repo;
  late FakeFeeRepository fees;
  setUp(() {
    repo = FakeBillingRepository();
    fees = FakeFeeRepository();
    GetIt.I.registerSingleton<BillingRepository>(repo);
    GetIt.I.registerSingleton<FeeRepository>(fees);
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
        expect(find.text('1 hóa đơn 0 đ sẽ không được gửi.'), findsOneWidget);
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
        find.text('Đã gửi 2 hóa đơn. 1 hóa đơn 0 đ không gửi.'),
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
        expect(find.text('Đã gửi 2 hóa đơn.'), findsOneWidget);
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
      ('409', apiErr(ApiErrorCode.conflictStale), 'Dữ liệu vừa thay đổi'),
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
}
