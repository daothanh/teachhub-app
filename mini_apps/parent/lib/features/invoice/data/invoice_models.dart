import 'package:equatable/equatable.dart';

/// Trạng thái hóa đơn phía phụ huynh (không có `draft`). Giá trị lạ → [unknown]
/// để app cũ không vỡ khi backend thêm trạng thái.
enum InvoiceStatus {
  issued,
  pendingConfirmation('pending_confirmation'),
  partiallyPaid('partially_paid'),
  paid,
  voided('void'),
  unknown('');

  const InvoiceStatus([String? wire]) : _wire = wire;
  final String? _wire;

  String get wire => _wire ?? name;

  static InvoiceStatus fromWire(Object? v) => values.firstWhere(
    (s) => s != unknown && s.wire == v,
    orElse: () => unknown,
  );

  /// Còn phải thanh toán (tính vào card học phí ở P02).
  bool get isUnpaid => this == issued || this == partiallyPaid;
}

/// Một dòng hóa đơn; `kind` lạ vẫn hiện như dòng thường.
class InvoiceLine extends Equatable {
  const InvoiceLine({
    required this.kind,
    required this.className,
    required this.description,
    required this.amount,
  });

  factory InvoiceLine.fromJson(Map<String, dynamic> j) => InvoiceLine(
    kind: j['kind'] as String,
    className: j['className'] as String?,
    description: j['description'] as String,
    amount: j['amount'] as int,
  );

  final String kind;
  final String? className;
  final String description;

  /// VND, có dấu (giảm trừ là số âm).
  final int amount;

  @override
  List<Object?> get props => [kind, className, description, amount];
}

/// Tài khoản nhận tiền chụp lúc phát hành. Không đưa vào log.
class InvoicePayout extends Equatable {
  const InvoicePayout({
    required this.bankBin,
    required this.bankName,
    required this.accountNo,
    required this.accountName,
  });

  factory InvoicePayout.fromJson(Map<String, dynamic> j) => InvoicePayout(
    bankBin: j['bankBin'] as String,
    bankName: j['bankName'] as String?,
    accountNo: j['accountNo'] as String,
    accountName: j['accountName'] as String,
  );

  final String bankBin;

  /// `null` khi BIN không có trong bảng của server: hiện [bankBin].
  final String? bankName;
  final String accountNo;
  final String accountName;

  @override
  List<Object?> get props => [bankBin, bankName, accountNo, accountName];
}

/// Dòng trong danh sách (`GET /family/invoices`).
class InvoiceSummary extends Equatable {
  const InvoiceSummary({
    required this.id,
    required this.code,
    required this.status,
    required this.studentId,
    required this.studentName,
    required this.teacherName,
    required this.periodMonth,
    required this.totalAmount,
    required this.dueDate,
  });

  factory InvoiceSummary.fromJson(Map<String, dynamic> j) => InvoiceSummary(
    id: j['id'] as String,
    code: j['code'] as String,
    status: InvoiceStatus.fromWire(j['status']),
    studentId: j['studentId'] as String,
    studentName: j['studentName'] as String,
    teacherName: j['teacherName'] as String,
    periodMonth: DateTime.parse(j['periodMonth'] as String),
    totalAmount: j['totalAmount'] as int,
    dueDate: DateTime.parse(j['dueDate'] as String),
  );

  final String id;
  final String code;
  final InvoiceStatus status;
  final String studentId;
  final String studentName;
  final String teacherName;
  final DateTime periodMonth;
  final int totalAmount;
  final DateTime dueDate;

  @override
  List<Object?> get props => [
    id,
    code,
    status,
    studentId,
    studentName,
    teacherName,
    periodMonth,
    totalAmount,
    dueDate,
  ];
}

class InvoicePage extends Equatable {
  const InvoicePage({required this.items, required this.nextCursor});

  factory InvoicePage.fromJson(Map<String, dynamic> j) => InvoicePage(
    items: [
      for (final i in j['items'] as List)
        InvoiceSummary.fromJson(i as Map<String, dynamic>),
    ],
    nextCursor: j['nextCursor'] as String?,
  );

  final List<InvoiceSummary> items;
  final String? nextCursor;

  @override
  List<Object?> get props => [items, nextCursor];
}

/// Chi tiết (`GET /family/invoices/{id}`). `void` thì [qrPayload] và [payout]
/// đều `null`. [qrPayload] chỉ để vẽ QR, không tự dựng, không log.
class InvoiceDetail extends Equatable {
  const InvoiceDetail({
    required this.summary,
    required this.lines,
    required this.transferNote,
    required this.qrPayload,
    required this.payout,
  });

  factory InvoiceDetail.fromJson(Map<String, dynamic> j) => InvoiceDetail(
    summary: InvoiceSummary.fromJson(j),
    lines: [
      for (final l in j['lines'] as List)
        InvoiceLine.fromJson(l as Map<String, dynamic>),
    ],
    transferNote: j['transferNote'] as String,
    qrPayload: j['qrPayload'] as String?,
    payout: j['payout'] == null
        ? null
        : InvoicePayout.fromJson(j['payout'] as Map<String, dynamic>),
  );

  final InvoiceSummary summary;
  final List<InvoiceLine> lines;
  final String transferNote;
  final String? qrPayload;
  final InvoicePayout? payout;

  @override
  List<Object?> get props => [summary, lines, transferNote, qrPayload, payout];
}
