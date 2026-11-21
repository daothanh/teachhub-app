import 'dart:async';

import 'package:teacher/features/billing/data/billing_models.dart'
    show PaymentMethod;
import 'package:teacher/features/reports/data/report_models.dart';
import 'package:teacher/features/reports/data/reports_repository.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

RevenueEntry sampleEntry({
  String id = 'e1',
  String student = 'Nguyễn Minh Anh',
  int amount = 500000,
  RevenueEntryKind kind = RevenueEntryKind.payment,
  String date = '2026-11-05',
  String? code = 'TH-25K7Q9',
}) => RevenueEntry(
  id: id,
  kind: kind,
  invoiceId: 'inv-$id',
  invoiceCode: code,
  studentName: student,
  method: PaymentMethod.cash,
  entryDate: date,
  amount: amount,
);

/// Bản giả: ghi lại `month` mỗi lần gọi, phân trang như server, lỗi theo yêu cầu.
class FakeReportsRepository implements ReportsRepository {
  MonthOverview overview = const MonthOverview(
    month: '2026-11',
    billedAmount: 72400000,
    collectedAmount: 65600000,
    outstandingAmount: 6800000,
    activeStudentCount: 46,
    hasData: true,
  );
  RevenueByClass byClass = const RevenueByClass(
    month: '2026-11',
    collectedAmount: 65600000,
    items: [
      ClassRevenue(
        classId: 'c1',
        className: 'Toán 9A',
        archived: false,
        collectedAmount: 28800000,
        attendancePercent: 92,
      ),
      ClassRevenue(
        classId: 'c2',
        className: 'Lý 8B',
        archived: true,
        collectedAmount: 800000,
        attendancePercent: 88.5,
      ),
      ClassRevenue(
        classId: null,
        className: null,
        archived: false,
        collectedAmount: 36000000,
        attendancePercent: null,
      ),
    ],
  );
  Revenue12m months12 = Revenue12m(
    months: [
      for (var i = 0; i < 12; i++)
        MonthRevenue(
          month: shiftMonth('2026-11', i - 11),
          collectedAmount: (i + 1) * 1000000,
        ),
    ],
  );
  List<RevenueEntry> entries = [sampleEntry()];

  /// Đặt thì lệnh gọi tương ứng ném lỗi này.
  ApiException? failure;

  /// Chỉ lệnh `payments` trang > 1 lỗi.
  bool failMore = false;

  /// Tháng đã gọi, theo thứ tự (null = không gửi `month`).
  final overviewMonths = <String?>[];
  final paymentCalls = <({String? month, int page})>[];
  final months12Calls = <String?>[];

  /// Ép `total` của `payments` (mô phỏng dữ liệu dịch trang: total lớn hơn số dòng thật).
  int? totalOverride;

  /// Chặn `payments` trang > 1 tới khi hoàn tất.
  Completer<void>? pageGate;

  /// Chỉ `monthOverview`/`revenueByClass` có `month` lỗi (đổi tháng lỗi).
  ApiException? failOnMonth;

  /// Chặn `monthOverview` tới khi hoàn tất (test chạy đua).
  Completer<void>? gate;

  @override
  Future<MonthOverview> monthOverview({String? month}) async {
    overviewMonths.add(month);
    if (gate != null) await gate!.future;
    if (failure != null || (month != null && failOnMonth != null)) {
      throw failure ?? failOnMonth!;
    }
    return MonthOverview(
      month: month ?? overview.month,
      billedAmount: overview.billedAmount,
      collectedAmount: overview.collectedAmount,
      outstandingAmount: overview.outstandingAmount,
      activeStudentCount: overview.activeStudentCount,
      hasData: overview.hasData,
    );
  }

  @override
  Future<RevenueByClass> revenueByClass({String? month}) async {
    if (failure != null) throw failure!;
    return byClass;
  }

  @override
  Future<Revenue12m> revenue12m({String? month}) async {
    months12Calls.add(month);
    if (failure != null) throw failure!;
    return months12;
  }

  @override
  Future<RevenueEntryPage> payments({
    String? month,
    int page = 1,
    int pageSize = 20,
  }) async {
    paymentCalls.add((month: month, page: page));
    if (page > 1 && pageGate != null) await pageGate!.future;
    if (failure != null || (failMore && page > 1)) {
      throw failure ?? const ApiException.unexpected();
    }
    final from = (page - 1) * pageSize;
    return RevenueEntryPage(
      items: entries.skip(from).take(pageSize).toList(),
      total: totalOverride ?? entries.length,
      page: page,
      pageSize: pageSize,
      totalAmount: entries.fold(0, (s, e) => s + e.amount),
    );
  }
}
