import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:teacher/features/billing/billing_routes.dart';
import 'package:teacher/features/billing/data/billing_repository.dart';
import 'package:teacher/features/receivables/receivables_routes.dart';
import 'package:teacher/features/reports/data/report_models.dart';
import 'package:teacher/features/reports/data/reports_repository.dart';
import 'package:teacher/features/reports/reports_routes.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../billing/fake_billing_repository.dart';
import '../classes/pump.dart';
import 'fake_reports_repository.dart';

void main() {
  late FakeReportsRepository repo;
  setUp(() {
    repo = FakeReportsRepository();
    GetIt.I
      ..registerSingleton<ReportsRepository>(repo)
      ..registerSingleton<BillingRepository>(FakeBillingRepository());
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
        ...reportsRoutes('teacher'),
        // Đích của lối chạm vào số: chỉ cần biết đã tới đúng đường dẫn.
        GoRoute(
          path: ReceivablesRoutes.list,
          builder: (_, _) => const Scaffold(body: Text('đích T11')),
        ),
        GoRoute(
          path: '${TeachHubRoutes.teacher}/invoices/:id',
          builder: (_, s) =>
              Scaffold(body: Text('hóa đơn ${s.pathParameters['id']}')),
        ),
        GoRoute(
          path: BillingRoutes.periods,
          builder: (_, _) => const Scaffold(body: Text('đích T10')),
        ),
      ],
      initial: initial,
      textScale: scale,
    );
    addTearDown(router.dispose);
    return router;
  }

  group('T12: tổng quan tháng', () {
    testWidgets('bốn ô số, định dạng tiền, doanh thu theo lớp có dòng Khác', (
      tester,
    ) async {
      await open(tester, ReportsRoutes.overview);
      expect(find.text('Tháng 11/2026'), findsOneWidget);
      expect(find.text('72.400.000 đ'), findsOneWidget);
      expect(find.text('6.800.000 đ'), findsOneWidget);
      expect(find.text('46'), findsOneWidget);
      // "Đã thu" xuất hiện ở ô số và ở dòng tháng chọn của biểu đồ.
      expect(find.text('65.600.000 đ'), findsOneWidget);
      expect(find.text('11/2026: 65.600.000 đ'), findsOneWidget);
      expect(find.text('Toán 9A'), findsOneWidget);
      expect(find.text('Chuyên cần 92%'), findsOneWidget);
      expect(find.text('Đã lưu trữ · Chuyên cần 88,5%'), findsOneWidget);
      expect(find.text('Khác'), findsOneWidget);
      expect(find.textContaining('không gán được cho lớp nào'), findsOneWidget);
      expect(find.text('36.000.000 đ'), findsOneWidget);
    });

    testWidgets('chữ 130%: không tràn, đủ nội dung', (tester) async {
      await open(tester, ReportsRoutes.overview, scale: 1.3);
      expect(tester.takeException(), isNull);
      expect(find.text('72.400.000 đ'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Khác'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('đổi tháng bằng mũi tên và bằng cột biểu đồ', (tester) async {
      await open(tester, ReportsRoutes.overview);
      await tester.tap(find.byTooltip('Tháng trước'));
      await tester.pumpAndSettle();
      expect(repo.overviewMonths.last, '2026-10');
      expect(find.text('Tháng 10/2026'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('bar-2026-05')));
      await tester.pumpAndSettle();
      expect(repo.overviewMonths.last, '2026-05');
      expect(find.text('Tháng 5/2026'), findsOneWidget);
    });

    testWidgets('đổi tháng lỗi: giữ biểu đồ và số liệu, hiện snackbar', (
      tester,
    ) async {
      await open(tester, ReportsRoutes.overview);
      repo.failOnMonth = const ApiException.unexpected();
      await tester.tap(find.byTooltip('Tháng trước'));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Tháng 11/2026'), findsOneWidget);
      expect(find.byKey(const ValueKey('bar-2026-05')), findsOneWidget);
      expect(find.text('Thử lại'), findsNothing);
    });

    testWidgets('mỗi cột biểu đồ có nhãn đọc màn hình kèm số tiền', (
      tester,
    ) async {
      await open(tester, ReportsRoutes.overview);
      expect(find.bySemanticsLabel('Tháng 11: 12.000.000 đ'), findsOneWidget);
      expect(find.byType(InkWell).evaluate().length, greaterThanOrEqualTo(12));
    });

    testWidgets('chạm Phải thu, Công nợ mở T10, T11', (tester) async {
      final router = await open(tester, ReportsRoutes.overview);
      await tester.tap(find.text('Phải thu'));
      await tester.pumpAndSettle();
      expect(find.text('đích T10'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Công nợ'));
      await tester.pumpAndSettle();
      expect(find.text('đích T11'), findsOneWidget);
    });

    testWidgets('chạm Đã thu mở danh sách khoản thu của đúng tháng', (
      tester,
    ) async {
      await open(tester, ReportsRoutes.overview);
      await tester.tap(find.byTooltip('Tháng trước'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đã thu'));
      await tester.pumpAndSettle();
      expect(find.text('Khoản đã thu'), findsOneWidget);
      expect(repo.paymentCalls.single.month, '2026-10');
    });

    testWidgets('tháng không có dữ liệu: báo "Chưa có dữ liệu tháng này"', (
      tester,
    ) async {
      repo.overview = const MonthOverview(
        month: '2026-11',
        billedAmount: 0,
        collectedAmount: 0,
        outstandingAmount: 0,
        activeStudentCount: 0,
        hasData: false,
      );
      repo.byClass = const RevenueByClass(
        month: '2026-11',
        collectedAmount: 0,
        items: [],
      );
      await open(tester, ReportsRoutes.overview);
      expect(find.text('Chưa có dữ liệu tháng này'), findsOneWidget);
      expect(
        find.text('Chưa có doanh thu theo lớp trong tháng này.'),
        findsOneWidget,
      );
      expect(find.text('0 đ'), findsWidgets);
    });

    testWidgets('lỗi tải: báo lỗi và thử lại được; ngoại tuyến cũng vậy', (
      tester,
    ) async {
      repo.failure = const ApiException.network();
      await open(tester, ReportsRoutes.overview);
      expect(find.text('Thử lại'), findsOneWidget);
      expect(find.text('72.400.000 đ'), findsNothing);
      repo.failure = null;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('72.400.000 đ'), findsOneWidget);
    });
  });

  group('danh sách khoản thu (US-8.1 AC3)', () {
    testWidgets('tổng cả tháng, dòng đảo báo hủy, chạm dòng mở hóa đơn', (
      tester,
    ) async {
      repo.entries = [
        sampleEntry(id: 'a', amount: 500000, student: 'Trần Bảo Bình'),
        sampleEntry(
          id: 'b',
          amount: -200000,
          kind: RevenueEntryKind.reversal,
          code: null,
        ),
      ];
      await open(tester, ReportsRoutes.payments('2026-11'));
      expect(find.text('Tổng 300.000 đ'), findsOneWidget);
      expect(find.text('500.000 đ'), findsOneWidget);
      expect(find.text('−200.000 đ'), findsOneWidget);
      expect(find.text('Hủy thanh toán'), findsOneWidget);
      expect(find.textContaining('chưa có mã'), findsOneWidget);
      await tester.tap(find.text('Trần Bảo Bình'));
      await tester.pumpAndSettle();
      expect(find.text('hóa đơn inv-a'), findsOneWidget);
    });

    testWidgets('total lớn hơn số dòng thật: hết dòng thì bỏ spinner', (
      tester,
    ) async {
      repo.entries = [
        for (var i = 0; i < 25; i++) sampleEntry(id: 'e$i', student: 'HV $i'),
      ];
      repo.totalOverride = 60;
      await open(tester, ReportsRoutes.payments('2026-11'));
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(repo.paymentCalls.map((c) => c.month).toSet(), {'2026-11'});
    });

    testWidgets('rỗng, lỗi (thử lại) và chữ 130%', (tester) async {
      repo.entries = [];
      await open(tester, ReportsRoutes.payments('2026-11'), scale: 1.3);
      expect(find.text('Tháng này chưa có khoản thu nào.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lỗi tải rồi thử lại', (tester) async {
      repo.failure = const ApiException.unexpected();
      await open(tester, ReportsRoutes.payments('2026-11'));
      expect(find.text('Thử lại'), findsOneWidget);
      repo.failure = null;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Tổng 500.000 đ'), findsOneWidget);
    });

    testWidgets('cuộn tới cuối tải trang kế', (tester) async {
      repo.entries = [
        for (var i = 0; i < 25; i++) sampleEntry(id: 'e$i', student: 'HV $i'),
      ];
      await open(tester, ReportsRoutes.payments('2026-11'));
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(repo.paymentCalls.map((c) => c.page), [1, 2]);
      await tester.scrollUntilVisible(find.text('HV 24'), 300);
      expect(find.text('HV 24'), findsOneWidget);
    });
  });

  testWidgets('lối vào từ màn kỳ thu (T10) mở T12', (tester) async {
    final router = await pumpRoutes(tester, [
      GoRoute(path: '/', builder: (_, _) => const Scaffold()),
      ...billingRoutes('teacher'),
      ...reportsRoutes('teacher'),
    ], initial: BillingRoutes.periods);
    addTearDown(router.dispose);
    await tester.tap(find.byTooltip('Báo cáo'));
    await tester.pumpAndSettle();
    expect(find.text('Tháng 11/2026'), findsOneWidget);
    expect(find.text('72.400.000 đ'), findsOneWidget);
  });
}
