import 'package:equatable/equatable.dart';

import '../../billing/data/billing_models.dart' show PaymentMethod;

/// Mô hình báo cáo T12/T12a (US-8.1, US-8.2) khớp `contracts/openapi.json`
/// (MonthOverview, RevenueEntryPage, RevenueByClass, Revenue12m). Tiền là số
/// nguyên đồng. Hủy thanh toán sinh dòng đảo âm tính vào THÁNG CỦA KHOẢN THU GỐC
/// (không phải tháng hủy) nên "đã thu" của một tháng không âm; riêng dòng đảo
/// trong danh sách khoản thu mang số âm và nằm cùng tháng với dòng gốc.

class MonthOverview extends Equatable {
  const MonthOverview({
    required this.month,
    required this.billedAmount,
    required this.collectedAmount,
    required this.outstandingAmount,
    required this.activeStudentCount,
    required this.hasData,
  });

  factory MonthOverview.fromJson(Map<String, dynamic> json) => MonthOverview(
    month: json['month'] as String,
    billedAmount: json['billedAmount'] as int,
    collectedAmount: json['collectedAmount'] as int,
    outstandingAmount: json['outstandingAmount'] as int,
    activeStudentCount: json['activeStudentCount'] as int,
    hasData: json['hasData'] as bool,
  );

  /// `YYYY-MM`.
  final String month;
  final int billedAmount;
  final int collectedAmount;

  /// Nợ ròng hiện tại, không theo tháng chọn.
  final int outstandingAmount;
  final int activeStudentCount;
  final bool hasData;

  @override
  List<Object?> get props => [
    month, billedAmount, collectedAmount, outstandingAmount, //
    activeStudentCount, hasData,
  ];
}

enum RevenueEntryKind {
  payment('payment'),
  reversal('reversal');

  const RevenueEntryKind(this.wire);
  final String wire;

  /// Giá trị lạ coi như `payment` (hợp đồng).
  static RevenueEntryKind fromWire(String? v) =>
      values.firstWhere((k) => k.wire == v, orElse: () => payment);
}

/// Một dòng sổ doanh thu của tháng.
class RevenueEntry extends Equatable {
  const RevenueEntry({
    required this.id,
    required this.kind,
    required this.invoiceId,
    required this.invoiceCode,
    required this.studentName,
    required this.method,
    required this.entryDate,
    required this.amount,
  });

  factory RevenueEntry.fromJson(Map<String, dynamic> json) => RevenueEntry(
    id: json['id'] as String,
    kind: RevenueEntryKind.fromWire(json['kind'] as String?),
    invoiceId: json['invoiceId'] as String,
    invoiceCode: json['invoiceCode'] as String?,
    studentName: json['studentName'] as String,
    method: PaymentMethod.fromWire(json['method'] as String?),
    entryDate: json['entryDate'] as String,
    amount: json['amount'] as int,
  );

  final String id;
  final RevenueEntryKind kind;
  final String invoiceId;
  final String? invoiceCode;
  final String studentName;
  final PaymentMethod method;

  /// `YYYY-MM-DD`.
  final String entryDate;

  /// Có dấu: âm với dòng đảo (cùng tháng với khoản thu gốc).
  final int amount;

  @override
  List<Object?> get props => [
    id, kind, invoiceId, invoiceCode, studentName, method, entryDate, amount, //
  ];
}

class RevenueEntryPage extends Equatable {
  const RevenueEntryPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalAmount,
  });

  factory RevenueEntryPage.fromJson(Map<String, dynamic> json) =>
      RevenueEntryPage(
        items: [
          for (final e in json['items'] as List)
            RevenueEntry.fromJson(e as Map<String, dynamic>),
        ],
        total: json['total'] as int,
        page: json['page'] as int,
        pageSize: json['pageSize'] as int,
        totalAmount: json['totalAmount'] as int,
      );

  final List<RevenueEntry> items;
  final int total;
  final int page;
  final int pageSize;

  /// Σ mọi dòng của tháng, bằng `collectedAmount` của tổng quan.
  final int totalAmount;

  @override
  List<Object?> get props => [items, total, page, pageSize, totalAmount];
}

/// Một dòng của bảng theo lớp; [classId] null là dòng "Khác".
class ClassRevenue extends Equatable {
  const ClassRevenue({
    required this.classId,
    required this.className,
    required this.archived,
    required this.collectedAmount,
    required this.attendancePercent,
  });

  factory ClassRevenue.fromJson(Map<String, dynamic> json) => ClassRevenue(
    classId: json['classId'] as String?,
    className: json['className'] as String?,
    archived: json['archived'] as bool,
    collectedAmount: json['collectedAmount'] as int,
    attendancePercent: (json['attendancePercent'] as num?)?.toDouble(),
  );

  final String? classId;
  final String? className;
  final bool archived;
  final int collectedAmount;

  /// `null` khi lớp không có buổi đã dạy trong tháng.
  final double? attendancePercent;

  bool get isOther => classId == null;

  @override
  List<Object?> get props => [
    classId, className, archived, collectedAmount, attendancePercent, //
  ];
}

class RevenueByClass extends Equatable {
  const RevenueByClass({
    required this.month,
    required this.collectedAmount,
    required this.items,
  });

  factory RevenueByClass.fromJson(Map<String, dynamic> json) => RevenueByClass(
    month: json['month'] as String,
    collectedAmount: json['collectedAmount'] as int,
    items: [
      for (final e in json['items'] as List)
        ClassRevenue.fromJson(e as Map<String, dynamic>),
    ],
  );

  final String month;
  final int collectedAmount;
  final List<ClassRevenue> items;

  @override
  List<Object?> get props => [month, collectedAmount, items];
}

class MonthRevenue extends Equatable {
  const MonthRevenue({required this.month, required this.collectedAmount});

  factory MonthRevenue.fromJson(Map<String, dynamic> json) => MonthRevenue(
    month: json['month'] as String,
    collectedAmount: json['collectedAmount'] as int,
  );

  /// `YYYY-MM`.
  final String month;
  final int collectedAmount;

  @override
  List<Object?> get props => [month, collectedAmount];
}

/// 12 tháng liên tiếp, cũ nhất trước.
class Revenue12m extends Equatable {
  const Revenue12m({required this.months});

  factory Revenue12m.fromJson(Map<String, dynamic> json) => Revenue12m(
    months: [
      for (final e in json['months'] as List)
        MonthRevenue.fromJson(e as Map<String, dynamic>),
    ],
  );

  final List<MonthRevenue> months;

  @override
  List<Object?> get props => [months];
}

/// `2026-11` → (năm 2026, tháng 11).
({int year, int month}) parseYearMonth(String ym) =>
    (year: int.parse(ym.substring(0, 4)), month: int.parse(ym.substring(5, 7)));

/// Tháng kế (delta +1) hoặc trước (-1) của `YYYY-MM`.
String shiftMonth(String ym, int delta) {
  final p = parseYearMonth(ym);
  final idx = p.year * 12 + (p.month - 1) + delta;
  return '${(idx ~/ 12).toString().padLeft(4, '0')}-'
      '${(idx % 12 + 1).toString().padLeft(2, '0')}';
}
