import 'package:equatable/equatable.dart';

/// Mô hình kỳ thu và hóa đơn khớp `contracts/openapi.json` (BillingPeriod,
/// InvoiceSummary, Invoice, InvoiceLine, IssueInvoicesResult). Tiền là số
/// nguyên đồng; dòng giảm trừ có dấu âm.

enum BillingPeriodStatus {
  drafting,
  closed;

  /// Giá trị lạ coi như còn soạn: không chặn người dùng chốt.
  static BillingPeriodStatus fromWire(String? v) =>
      v == 'closed' ? closed : drafting;
}

enum InvoiceStatus {
  draft,
  issued,
  pendingConfirmation,
  partiallyPaid,
  paid,
  voided;

  /// Hợp đồng: giá trị lạ coi như `issued`.
  static InvoiceStatus fromWire(String? v) => switch (v) {
    'draft' => draft,
    'pending_confirmation' => pendingConfirmation,
    'partially_paid' => partiallyPaid,
    'paid' => paid,
    'void' => voided,
    _ => issued,
  };

  /// Đã phát hành và chưa hủy: còn hủy được.
  bool get isLive => this != draft && this != voided;
}

class BillingPeriod extends Equatable {
  const BillingPeriod({
    required this.id,
    required this.periodMonth,
    required this.closeDate,
    required this.dueDate,
    required this.status,
    required this.draftCount,
    required this.issuedCount,
    required this.voidCount,
    required this.draftTotalAmount,
    required this.issuedTotalAmount,
  });

  factory BillingPeriod.fromJson(Map<String, dynamic> json) => BillingPeriod(
    id: json['id'] as String,
    periodMonth: json['periodMonth'] as String,
    closeDate: json['closeDate'] as String,
    dueDate: json['dueDate'] as String,
    status: BillingPeriodStatus.fromWire(json['status'] as String?),
    draftCount: json['draftCount'] as int,
    issuedCount: json['issuedCount'] as int,
    voidCount: json['voidCount'] as int,
    draftTotalAmount: json['draftTotalAmount'] as int,
    issuedTotalAmount: json['issuedTotalAmount'] as int,
  );

  final String id;

  /// `YYYY-MM-01`.
  final String periodMonth;

  /// `YYYY-MM-DD`.
  final String closeDate;
  final String dueDate;
  final BillingPeriodStatus status;
  final int draftCount;
  final int issuedCount;
  final int voidCount;
  final int draftTotalAmount;
  final int issuedTotalAmount;

  int get year => int.parse(periodMonth.substring(0, 4));
  int get month => int.parse(periodMonth.substring(5, 7));

  @override
  List<Object?> get props => [
    id, periodMonth, closeDate, dueDate, status, draftCount, //
    issuedCount, voidCount, draftTotalAmount, issuedTotalAmount,
  ];
}

class InvoiceSummary extends Equatable {
  const InvoiceSummary({
    required this.id,
    required this.code,
    required this.status,
    required this.studentId,
    required this.studentName,
    required this.totalAmount,
    required this.hasOverride,
  });

  factory InvoiceSummary.fromJson(Map<String, dynamic> json) => InvoiceSummary(
    id: json['id'] as String,
    code: json['code'] as String?,
    status: InvoiceStatus.fromWire(json['status'] as String?),
    studentId: json['studentId'] as String,
    studentName: json['studentName'] as String,
    totalAmount: json['totalAmount'] as int,
    hasOverride: json['hasOverride'] as bool,
  );

  final String id;
  final String? code;
  final InvoiceStatus status;
  final String studentId;
  final String studentName;
  final int totalAmount;
  final bool hasOverride;

  /// Bản nháp 0 đ: không gửi, không nhắc nợ (US-1.3 AC3).
  bool get isZeroDraft => status == InvoiceStatus.draft && totalAmount == 0;

  /// Bản nháp có tiền: chốt được.
  bool get isPayableDraft => status == InvoiceStatus.draft && totalAmount > 0;

  @override
  List<Object?> get props => [
    id, code, status, studentId, studentName, totalAmount, hasOverride, //
  ];
}

/// Chi tiết kỳ kèm toàn bộ hóa đơn (repository gộp các trang).
class BillingPeriodDetail extends Equatable {
  const BillingPeriodDetail({
    required this.period,
    required this.invoices,
    required this.invoiceTotal,
  });

  final BillingPeriod period;
  final List<InvoiceSummary> invoices;

  /// Tổng số hóa đơn theo server (để biết đã nạp đủ chưa).
  final int invoiceTotal;

  List<InvoiceSummary> get payableDrafts => [
    for (final i in invoices)
      if (i.isPayableDraft) i,
  ];

  int get payableTotal => payableDrafts.fold(0, (s, i) => s + i.totalAmount);

  int get zeroDraftCount => invoices.where((i) => i.isZeroDraft).length;

  @override
  List<Object?> get props => [period, invoices, invoiceTotal];
}

/// Một trang của `GET /billing-periods/{id}`.
class BillingPeriodPageData {
  const BillingPeriodPageData({
    required this.period,
    required this.items,
    required this.total,
  });

  factory BillingPeriodPageData.fromJson(Map<String, dynamic> json) {
    final invoices = json['invoices'] as Map<String, dynamic>;
    return BillingPeriodPageData(
      period: BillingPeriod.fromJson(json),
      items: [
        for (final e in invoices['items'] as List)
          InvoiceSummary.fromJson(e as Map<String, dynamic>),
      ],
      total: invoices['total'] as int,
    );
  }

  final BillingPeriod period;
  final List<InvoiceSummary> items;
  final int total;
}

enum InvoiceLineKind {
  session,
  monthly,
  courseInstallment,
  carryOver,
  prevAdjustment,
  discount,
  surcharge,
  manualAdjustment;

  /// Hợp đồng: giá trị lạ coi như dòng thường (`monthly`).
  static InvoiceLineKind fromWire(String? v) => switch (v) {
    'session' => session,
    'course_installment' => courseInstallment,
    'carry_over' => carryOver,
    'prev_adjustment' => prevAdjustment,
    'discount' => discount,
    'surcharge' => surcharge,
    'manual_adjustment' => manualAdjustment,
    _ => monthly,
  };
}

enum NotChargedReason {
  excused,
  unexcused,
  cancelled,
  makeup,
  other;

  static NotChargedReason? fromWire(String? v) => switch (v) {
    null => null,
    'excused_not_charged' => excused,
    'unexcused_not_charged' => unexcused,
    'cancelled' => cancelled,
    'makeup' => makeup,
    _ => other,
  };
}

class InvoiceLine extends Equatable {
  const InvoiceLine({
    required this.id,
    required this.kind,
    required this.description,
    required this.amount,
    required this.charged,
    this.notChargedReason,
    this.sessionDate,
    this.className,
    this.adjustmentReason,
  });

  factory InvoiceLine.fromJson(Map<String, dynamic> json) => InvoiceLine(
    id: json['id'] as String,
    kind: InvoiceLineKind.fromWire(json['kind'] as String?),
    description: json['description'] as String,
    amount: json['amount'] as int,
    charged: json['charged'] as bool,
    notChargedReason: NotChargedReason.fromWire(
      json['notChargedReason'] as String?,
    ),
    sessionDate: json['sessionDate'] as String?,
    className: json['className'] as String?,
    adjustmentReason: json['adjustmentReason'] as String?,
  );

  final String id;
  final InvoiceLineKind kind;
  final String description;
  final int amount;
  final bool charged;
  final NotChargedReason? notChargedReason;
  final String? sessionDate;
  final String? className;
  final String? adjustmentReason;

  @override
  List<Object?> get props => [
    id, kind, description, amount, charged, notChargedReason, sessionDate, //
    className, adjustmentReason,
  ];
}

class Invoice extends Equatable {
  const Invoice({
    required this.id,
    required this.periodId,
    required this.periodMonth,
    required this.code,
    required this.status,
    required this.studentName,
    required this.totalAmount,
    required this.dueDate,
    required this.voidReason,
    required this.lines,
    required this.clampedAmount,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
    id: json['id'] as String,
    periodId: json['periodId'] as String,
    periodMonth: json['periodMonth'] as String,
    code: json['code'] as String?,
    status: InvoiceStatus.fromWire(json['status'] as String?),
    studentName: json['studentName'] as String,
    totalAmount: json['totalAmount'] as int,
    dueDate: json['dueDate'] as String,
    voidReason: json['voidReason'] as String?,
    lines: [
      for (final e in json['lines'] as List)
        InvoiceLine.fromJson(e as Map<String, dynamic>),
    ],
    clampedAmount: json['clampedAmount'] as int,
  );

  final String id;
  final String periodId;
  final String periodMonth;
  final String? code;
  final InvoiceStatus status;
  final String studentName;
  final int totalAmount;
  final String dueDate;
  final String? voidReason;
  final List<InvoiceLine> lines;
  final int clampedAmount;

  int get year => int.parse(periodMonth.substring(0, 4));
  int get month => int.parse(periodMonth.substring(5, 7));

  List<InvoiceLine> get sessionLines => [
    for (final l in lines)
      if (l.kind == InvoiceLineKind.session) l,
  ];

  List<InvoiceLine> get otherLines => [
    for (final l in lines)
      if (l.kind != InvoiceLineKind.session) l,
  ];

  @override
  List<Object?> get props => [
    id, periodId, periodMonth, code, status, studentName, totalAmount, //
    dueDate, voidReason, lines, clampedAmount,
  ];
}

class IssueSkipped extends Equatable {
  const IssueSkipped({required this.invoiceId, required this.reason});

  factory IssueSkipped.fromJson(Map<String, dynamic> json) => IssueSkipped(
    invoiceId: json['invoiceId'] as String,
    reason: json['reason'] as String,
  );

  final String invoiceId;

  /// `ZERO_AMOUNT` hoặc `NOT_DRAFT`.
  final String reason;

  bool get isZeroAmount => reason == 'ZERO_AMOUNT';

  @override
  List<Object?> get props => [invoiceId, reason];
}

class IssueResult extends Equatable {
  const IssueResult({
    required this.issuedCount,
    required this.skipped,
    required this.totalAmount,
  });

  factory IssueResult.fromJson(Map<String, dynamic> json) => IssueResult(
    issuedCount: json['issuedCount'] as int,
    skipped: [
      for (final e in json['skipped'] as List)
        IssueSkipped.fromJson(e as Map<String, dynamic>),
    ],
    totalAmount: json['totalAmount'] as int,
  );

  final int issuedCount;
  final List<IssueSkipped> skipped;
  final int totalAmount;

  int get zeroSkipped => skipped.where((s) => s.isZeroAmount).length;

  @override
  List<Object?> get props => [issuedCount, skipped, totalAmount];
}

const adjustmentAmountMax = 1000000000;
const adjustmentDescriptionMax = 200;
const adjustmentReasonMax = 300;
const voidReasonMax = 300;

/// Dòng điều chỉnh gửi lên: [amount] có dấu, khác 0.
class AdjustmentInput extends Equatable {
  const AdjustmentInput({
    required this.amount,
    required this.description,
    required this.reason,
  });

  final int amount;
  final String description;
  final String reason;

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'description': description.trim(),
    'adjustmentReason': reason.trim(),
  };

  @override
  List<Object?> get props => [amount, description, reason];
}

enum AdjustmentError { amount, description, reason }

/// Kiểm tra ở máy theo hợp đồng `CreateInvoiceAdjustmentRequest`.
Map<String, AdjustmentError> validateAdjustment(AdjustmentInput i) => {
  if (i.amount == 0 || i.amount.abs() > adjustmentAmountMax)
    'amount': AdjustmentError.amount,
  if (i.description.trim().isEmpty ||
      i.description.trim().length > adjustmentDescriptionMax)
    'description': AdjustmentError.description,
  if (i.reason.trim().isEmpty || i.reason.trim().length > adjustmentReasonMax)
    'adjustmentReason': AdjustmentError.reason,
};

/// `-150000` → `-150.000 đ`; dương có `+` khi [plus] (dòng điều chỉnh/giảm).
String formatSignedVnd(int amount, {bool plus = false}) {
  final digits = amount.abs().toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write('.');
    out.write(digits[i]);
  }
  final sign = amount < 0
      ? '−'
      : plus && amount > 0
      ? '+'
      : '';
  return '$sign$out đ';
}

/// `2026-12-31` → `31/12/2026`.
String formatIsoDate(String iso) {
  final p = iso.split('-');
  return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : iso;
}
