import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/features/billing/cubit/billing_periods_cubit.dart'
    show BillingLoad;
import 'package:teacher/features/reports/cubit/report_payments_cubit.dart';
import 'package:teacher/features/reports/cubit/reports_cubit.dart';
import 'package:teacher/features/reports/data/report_models.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'fake_reports_repository.dart';

void main() {
  late FakeReportsRepository repo;
  setUp(() => repo = FakeReportsRepository());

  ReportsCubit cubit() => ReportsCubit(repo, now: () => DateTime(2026, 11, 21));

  test('shiftMonth qua ranh giới năm', () {
    expect(shiftMonth('2026-01', -1), '2025-12');
    expect(shiftMonth('2025-12', 1), '2026-01');
    expect(shiftMonth('2026-11', 0), '2026-11');
  });

  group('ReportsCubit', () {
    test(
      'tải đầu: không gửi tháng, lấy tháng của máy chủ; ba khối đủ',
      () async {
        final c = cubit();
        await c.load();
        expect(repo.overviewMonths, [null]);
        expect(c.state.load, BillingLoad.ready);
        expect(c.state.month, '2026-11');
        expect(c.state.overview!.collectedAmount, 65600000);
        expect(c.state.byClass!.items, hasLength(3));
        expect(c.state.months!.months, hasLength(12));
      },
    );

    test(
      'tổng theo lớp bằng đúng "đã thu" của tổng quan (US-8.2 AC3)',
      () async {
        final c = cubit();
        await c.load();
        final sum = c.state.byClass!.items.fold<int>(
          0,
          (s, i) => s + i.collectedAmount,
        );
        expect(sum, c.state.overview!.collectedAmount);
      },
    );

    test(
      'previous/next đổi tháng và gọi lại; không đi quá tháng hiện tại',
      () async {
        final c = cubit();
        await c.load();
        expect(c.canGoNext, isFalse);
        await c.next();
        expect(repo.overviewMonths, [null], reason: 'next bị chặn');
        await c.previous();
        expect(c.state.month, '2026-10');
        expect(repo.overviewMonths.last, '2026-10');
        expect(c.canGoNext, isTrue);
        await c.next();
        expect(c.state.month, '2026-11');
      },
    );

    test('một lệnh lỗi là lỗi cả màn, thử lại giữ tháng đang xem', () async {
      final c = cubit();
      await c.load();
      repo.failure = const ApiException.unexpected();
      await c.selectMonth('2026-09');
      expect(c.state.load, BillingLoad.failure);
      expect(c.state.error, isNotNull);
      expect(c.state.month, '2026-09');
      repo.failure = null;
      await c.load();
      expect(c.state.load, BillingLoad.ready);
      expect(c.state.month, '2026-09');
    });

    test('làm mới lỗi: giữ số liệu cũ và báo nhẹ', () async {
      final c = cubit();
      await c.load();
      repo.failure = const ApiException.unexpected();
      await c.refresh();
      expect(c.state.load, BillingLoad.ready);
      expect(c.state.overview, isNotNull);
      expect(c.state.refreshError, isNotNull);
    });

    test('phản hồi của lần đổi tháng cũ bị bỏ', () async {
      final c = cubit();
      await c.load();
      final gate = repo.gate = Completer();
      final slow = c.selectMonth('2026-08');
      repo.gate = null;
      await c.selectMonth('2026-07');
      expect(c.state.month, '2026-07');
      gate.complete();
      await slow;
      expect(c.state.month, '2026-07');
    });
  });

  group('ReportPaymentsCubit', () {
    List<RevenueEntry> many(int n) => [
      for (var i = 0; i < n; i++) sampleEntry(id: 'e$i', amount: 1000 + i),
    ];

    test('tải trang đầu: tổng là của cả tháng, không chỉ trang', () async {
      repo.entries = many(25);
      final c = ReportPaymentsCubit(repo, month: '2026-11');
      await c.load();
      expect(c.state.items, hasLength(20));
      expect(c.state.hasMore, isTrue);
      expect(
        c.state.totalAmount,
        repo.entries.fold<int>(0, (s, e) => s + e.amount),
      );
      expect(repo.paymentCalls.single.month, '2026-11');
    });

    test('loadMore nối trang kế, hết thì dừng', () async {
      repo.entries = many(25);
      final c = ReportPaymentsCubit(repo, month: '2026-11');
      await c.load();
      await c.loadMore();
      expect(c.state.items, hasLength(25));
      expect(c.state.hasMore, isFalse);
      await c.loadMore();
      expect(repo.paymentCalls, hasLength(2));
    });

    test('tải thêm lỗi: giữ danh sách, moreFailed; thử lại được', () async {
      repo.entries = many(25);
      final c = ReportPaymentsCubit(repo, month: '2026-11');
      await c.load();
      repo.failMore = true;
      await c.loadMore();
      expect(c.state.moreFailed, isTrue);
      expect(c.state.items, hasLength(20));
      repo.failMore = false;
      await c.loadMore();
      expect(c.state.items, hasLength(25));
      expect(c.state.moreFailed, isFalse);
    });

    test('lỗi tải đầu và rỗng', () async {
      repo.failure = const ApiException.unexpected();
      final c = ReportPaymentsCubit(repo, month: '2026-11');
      await c.load();
      expect(c.state.load, BillingLoad.failure);
      repo.failure = null;
      repo.entries = [];
      await c.load();
      expect(c.state.load, BillingLoad.ready);
      expect(c.state.items, isEmpty);
    });
  });
}
