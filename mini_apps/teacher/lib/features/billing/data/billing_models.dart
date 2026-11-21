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

  /// Đã phát hành, chưa hủy, chưa thu đủ: ghi thanh toán được.
  bool get canRecordPayment => status.isLive && status != InvoiceStatus.paid;

  /// Hóa đơn 0 đ đã chốt vì tiền trả thừa đủ trả kỳ này (không QR, không thu).
  bool get isCoveredByBalance =>
      status == InvoiceStatus.paid && totalAmount == 0;

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

  /// Dòng số dư kỳ trước, hiện tách khỏi các dòng buổi.
  bool get isCarry => this == carryOver || this == prevAdjustment;
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
    required this.paidAmount,
    required this.carriedAmount,
    required this.remainingAmount,
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
    paidAmount: json['paidAmount'] as int,
    carriedAmount: json['carriedAmount'] as int,
    remainingAmount: json['remainingAmount'] as int,
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

  /// Σ thanh toán chưa hủy; server tính, app không tự cộng.
  final int paidAmount;

  /// Phần còn nợ đã chuyển sang hóa đơn kỳ sau lúc phát hành hóa đơn đó (0 nếu
  /// chưa); không còn tính vào [remainingAmount].
  final int carriedAmount;

  /// 0 khi hóa đơn nháp hoặc đã hủy, còn lại max(0, tổng − đã thu − đã chuyển).
  final int remainingAmount;
  final String dueDate;
  final String? voidReason;
  final List<InvoiceLine> lines;
  final int clampedAmount;

  /// Còn ghi thanh toán được: đã phát hành, chưa hủy, chưa thu đủ và còn nợ
  /// (hóa đơn đã chuyển hết nợ sang kỳ sau thì còn lại là 409
  /// `INVOICE_NOT_PAYABLE`).
  bool get canRecordPayment =>
      status.isLive && status != InvoiceStatus.paid && remainingAmount > 0;

  /// Nợ đã chuyển sang hóa đơn kỳ sau.
  bool get isCarriedOver => carriedAmount > 0;

  /// Có dòng kết chuyển từ kỳ trước (khác 0).
  bool get hasCarryLine =>
      lines.any((l) => l.kind == InvoiceLineKind.carryOver && l.amount != 0);

  /// Hóa đơn 0 đ đã chốt vì tiền trả thừa đủ trả kỳ này: không QR, không thu.
  bool get isCoveredByBalance =>
      status == InvoiceStatus.paid && totalAmount == 0;

  /// Hủy được: server trả 409 khi đã có thanh toán, đã chuyển nợ hoặc đang mang
  /// dòng kết chuyển (chưa hỗ trợ trả khoản chuyển kỳ về).
  bool get canVoid =>
      status.isLive && paidAmount == 0 && !isCarriedOver && !hasCarryLine;

  /// Số liệu hóa đơn sau khi ghi hoặc hủy một thanh toán (lấy từ [PaymentResult]).
  Invoice afterPayment(PaymentResult r) => Invoice(
    id: id,
    periodId: periodId,
    periodMonth: periodMonth,
    code: code,
    status: r.status,
    studentName: studentName,
    totalAmount: totalAmount,
    paidAmount: r.paidAmount,
    carriedAmount: carriedAmount,
    remainingAmount: r.remainingAmount,
    dueDate: dueDate,
    voidReason: voidReason,
    lines: lines,
    clampedAmount: clampedAmount,
  );

  int get year => int.parse(periodMonth.substring(0, 4));
  int get month => int.parse(periodMonth.substring(5, 7));

  List<InvoiceLine> get sessionLines => [
    for (final l in lines)
      if (l.kind == InvoiceLineKind.session) l,
  ];

  /// Số dư kỳ trước (xem trước ở bản nháp): nợ/trả thừa và điều chỉnh kỳ trước.
  List<InvoiceLine> get carryLines => [
    for (final l in lines)
      if (l.kind.isCarry) l,
  ];

  List<InvoiceLine> get otherLines => [
    for (final l in lines)
      if (l.kind != InvoiceLineKind.session && !l.kind.isCarry) l,
  ];

  @override
  List<Object?> get props => [
    id, periodId, periodMonth, code, status, studentName, totalAmount, //
    paidAmount, carriedAmount, remainingAmount, dueDate, voidReason, lines, //
    clampedAmount,
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
    this.coveredCount = 0,
  });

  factory IssueResult.fromJson(Map<String, dynamic> json) => IssueResult(
    issuedCount: json['issuedCount'] as int,
    skipped: [
      for (final e in json['skipped'] as List)
        IssueSkipped.fromJson(e as Map<String, dynamic>),
    ],
    totalAmount: json['totalAmount'] as int,
    coveredCount: (json['invoices'] as List)
        .where((e) => (e as Map<String, dynamic>)['totalAmount'] == 0)
        .length,
  );

  final int issuedCount;
  final List<IssueSkipped> skipped;

  /// Tổng cuối của các hóa đơn vừa phát hành, theo server (đã gồm số dư lúc
  /// chốt; có thể khác số xem trước ở bản nháp).
  final int totalAmount;

  /// Số hóa đơn vừa chốt 0 đ vì tiền trả thừa đủ trả: không QR, không thu.
  final int coveredCount;

  int get zeroSkipped => skipped.where((s) => s.isZeroAmount).length;

  @override
  List<Object?> get props => [
    issuedCount, skipped, totalAmount, coveredCount, //
  ];
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

enum PaymentMethod {
  bankTransfer('bank_transfer'),
  cash('cash');

  const PaymentMethod(this.wire);
  final String wire;

  /// Giá trị lạ coi như chuyển khoản (mặc định của hợp đồng).
  static PaymentMethod fromWire(String? v) =>
      values.firstWhere((m) => m.wire == v, orElse: () => bankTransfer);
}

/// Người ghi hoặc hủy thanh toán (`PaymentActor`).
class PaymentActor extends Equatable {
  const PaymentActor({required this.id, required this.name});

  factory PaymentActor.fromJson(Map<String, dynamic> json) =>
      PaymentActor(id: json['id'] as String, name: json['name'] as String);

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

/// Một lần thu (`Payment`). Hủy không xóa dòng: [voidedAt] khác null.
class Payment extends Equatable {
  const Payment({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.method,
    required this.paidOn,
    required this.note,
    required this.recordedAt,
    required this.recordedBy,
    required this.voidedAt,
    required this.voidedBy,
    required this.voidReason,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    id: json['id'] as String,
    invoiceId: json['invoiceId'] as String,
    amount: json['amount'] as int,
    method: PaymentMethod.fromWire(json['method'] as String?),
    paidOn: json['paidOn'] as String,
    note: json['note'] as String?,
    recordedAt: json['recordedAt'] as String,
    recordedBy: _actor(json['recordedBy']),
    voidedAt: json['voidedAt'] as String?,
    voidedBy: _actor(json['voidedBy']),
    voidReason: json['voidReason'] as String?,
  );

  static PaymentActor? _actor(Object? v) =>
      v == null ? null : PaymentActor.fromJson(v as Map<String, dynamic>);

  final String id;
  final String invoiceId;
  final int amount;
  final PaymentMethod method;

  /// `YYYY-MM-DD`.
  final String paidOn;
  final String? note;

  /// Thời điểm ISO có múi giờ.
  final String recordedAt;

  /// `null` khi không xác định được (tài khoản đã xóa).
  final PaymentActor? recordedBy;
  final String? voidedAt;
  final PaymentActor? voidedBy;
  final String? voidReason;

  bool get isVoided => voidedAt != null;

  Payment replacing(Payment other) => other.id == id ? other : this;

  @override
  List<Object?> get props => [
    id, invoiceId, amount, method, paidOn, note, recordedAt, recordedBy, //
    voidedAt, voidedBy, voidReason,
  ];
}

/// Phản hồi ghi hoặc hủy thanh toán (`PaymentResult`).
class PaymentResult extends Equatable {
  const PaymentResult({
    required this.payment,
    required this.status,
    required this.paidAmount,
    required this.remainingAmount,
    required this.overpaidAmount,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> json) => PaymentResult(
    payment: Payment.fromJson(json['payment'] as Map<String, dynamic>),
    status: InvoiceStatus.fromWire(json['status'] as String?),
    paidAmount: json['paidAmount'] as int,
    remainingAmount: json['remainingAmount'] as int,
    overpaidAmount: json['overpaidAmount'] as int,
  );

  final Payment payment;
  final InvoiceStatus status;
  final int paidAmount;
  final int remainingAmount;
  final int overpaidAmount;

  @override
  List<Object?> get props => [
    payment, status, paidAmount, remainingAmount, overpaidAmount, //
  ];
}

const paymentAmountMax = 100000000000;
const paymentNoteMax = 300;

/// Thanh toán gửi lên: [amount] > 0 (bằng số còn nợ là "đã thu đủ"), [paidOn]
/// `YYYY-MM-DD` không sau hôm nay.
class PaymentInput extends Equatable {
  const PaymentInput({
    required this.amount,
    required this.method,
    required this.paidOn,
    this.note = '',
  });

  final int amount;
  final PaymentMethod method;
  final String paidOn;

  /// Ghi chú tùy chọn của giáo viên (phụ huynh không thấy); trống thì không gửi.
  final String note;

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'method': method.wire,
    'paidOn': paidOn,
    if (note.trim().isNotEmpty) 'note': note.trim(),
  };

  @override
  List<Object?> get props => [amount, method, paidOn, note];
}

/// Kiểm tra ở máy theo hợp đồng `RecordPaymentRequest`: tên các trường sai.
Set<String> validatePayment(PaymentInput i) => {
  if (i.amount < 1 || i.amount > paymentAmountMax) 'amount',
  if (i.note.trim().length > paymentNoteMax) 'note',
};

/// `2026-12-31` → `31/12/2026`.
String formatIsoDate(String iso) {
  final p = iso.split('-');
  return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : iso;
}

/// `2027-01-05T09:12:00+07:00` → `05/01/2027 09:12` theo giờ máy.
String formatIsoDateTime(String iso) {
  final t = DateTime.tryParse(iso)?.toLocal();
  if (t == null) return iso;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.day)}/${two(t.month)}/${t.year} ${two(t.hour)}:${two(t.minute)}';
}
