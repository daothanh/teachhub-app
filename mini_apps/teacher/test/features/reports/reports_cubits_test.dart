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

  ReportsCubit cubit() => ReportsCubit(repo);

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
      'previous/next đổi tháng; không đi quá tháng hiện tại của máy chủ',
      () async {
        final c = cubit();
        await c.load();
        expect(c.state.currentMonth, '2026-11');
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

    test(
      'đổi tháng chỉ gọi tổng quan và theo lớp; biểu đồ không trượt',
      () async {
        final c = cubit();
        await c.load();
        final chart = c.state.months;
        await c.selectMonth('2026-05');
        await c.previous();
        expect(repo.months12Calls, [null], reason: 'chỉ gọi lần tải đầu');
        expect(c.state.months, same(chart));
      },
    );

    test('đổi tháng giữ số liệu và biểu đồ khi đang tải', () async {
      final c = cubit();
      await c.load();
      final gate = repo.gate = Completer();
      final f = c.selectMonth('2026-09');
      expect(c.state.loading, isTrue);
      expect(c.state.overview, isNotNull);
      expect(c.state.months, isNotNull);
      gate.complete();
      await f;
      expect(c.state.loading, isFalse);
    });

    test('đổi tháng lỗi: ở lại tháng cũ với số liệu cũ và báo nhẹ', () async {
      final c = cubit();
      await c.load();
      repo.failOnMonth = const ApiException.unexpected();
      await c.selectMonth('2026-09');
      expect(c.state.load, BillingLoad.ready);
      expect(c.state.month, '2026-11');
      expect(c.state.overview, isNotNull);
      expect(c.state.refreshError, isNotNull);
      expect(c.state.loading, isFalse);
    });

    test('tải đầu lỗi: màn lỗi, thử lại được', () async {
      final c = cubit();
      repo.failure = const ApiException.unexpected();
      await c.load();
      expect(c.state.load, BillingLoad.failure);
      expect(c.state.error, isNotNull);
      repo.failure = null;
      await c.load();
      expect(c.state.load, BillingLoad.ready);
    });

    test('làm mới lỗi lặp lại: refreshError được xóa rồi đặt lại', () async {
      final c = cubit();
      await c.load();
      repo.failure = const ApiException.unexpected();
      final seen = <ApiException?>[];
      final sub = c.stream.listen((s) => seen.add(s.refreshError));
      await c.refresh();
      await c.refresh();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(c.state.load, BillingLoad.ready);
      expect(c.state.overview, isNotNull);
      expect(seen.where((e) => e != null), hasLength(2));
      expect(seen, contains(isNull), reason: 'lỗi cũ bị xóa giữa hai lần');
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

    test('mọi trang gửi cùng một tháng cụ thể', () async {
      repo.entries = many(25);
      final c = ReportPaymentsCubit(repo, month: '2026-11');
      await c.load();
      await c.loadMore();
      expect(repo.paymentCalls.map((e) => e.month), ['2026-11', '2026-11']);
    });

    test('trang kế rỗng dù total còn lớn: dừng, không kẹt hasMore', () async {
      repo.entries = many(20);
      repo.totalOverride = 40;
      final c = ReportPaymentsCubit(repo, month: '2026-11');
      await c.load();
      expect(c.state.hasMore, isTrue);
      await c.loadMore();
      expect(c.state.hasMore, isFalse);
      expect(c.state.items, hasLength(20));
    });

    test(
      'trang kế có dòng mới thì tiếp tục, trang sau rỗng thì dừng',
      () async {
        repo.entries = many(25);
        repo.totalOverride = 99;
        final c = ReportPaymentsCubit(repo, month: '2026-11');
        await c.load();
        await c.loadMore();
        expect(c.state.items, hasLength(25));
        expect(c.state.hasMore, isTrue);
        await c.loadMore();
        expect(c.state.hasMore, isFalse);
      },
    );

    test('làm mới khi đang tải trang 2: không kẹt đang tải thêm', () async {
      repo.entries = many(25);
      final c = ReportPaymentsCubit(repo, month: '2026-11');
      await c.load();
      final gate = repo.pageGate = Completer();
      final more = c.loadMore();
      expect(c.state.loadingMore, isTrue);
      repo.pageGate = null;
      await c.refresh();
      expect(c.state.loadingMore, isFalse);
      expect(c.state.hasMore, isTrue);
      gate.complete();
      await more;
      expect(c.state.loadingMore, isFalse);
      await c.loadMore();
      expect(c.state.items, hasLength(25));
    });

    test('loadMore khi đang làm mới trang 1: bỏ qua, không mất trang', () async {
      repo.entries = many(50);
      final c = ReportPaymentsCubit(repo, month: '2026-11');
      await c.load();
      await c.loadMore();
      expect(c.state.page, 2);
      final refreshing = c.refresh();
      await c.loadMore(); // trang 1 đang bay: không được tải trang 3
      await refreshing;
      expect(repo.paymentCalls.map((e) => e.page), [1, 2, 1]);
      await c.loadMore();
      expect(c.state.items.map((e) => e.id), [
        for (var i = 0; i < 40; i++) 'e$i',
      ]);
    });

    test('làm mới lỗi lặp lại: refreshError được xóa rồi đặt lại', () async {
      final c = ReportPaymentsCubit(repo, month: '2026-11');
      await c.load();
      repo.failure = const ApiException.unexpected();
      final seen = <ApiException?>[];
      final sub = c.stream.listen((s) => seen.add(s.refreshError));
      await c.refresh();
      await c.refresh();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(seen.where((e) => e != null), hasLength(2));
      expect(seen, contains(isNull));
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
