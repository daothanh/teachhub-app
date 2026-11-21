import 'package:equatable/equatable.dart';

import '../../billing/data/billing_models.dart'
    show InvoiceStatus, PaymentMethod;

/// Mô hình công nợ (T11, US-8.3) và nhắc nợ (US-7.5) khớp `contracts/openapi.json`
/// (Receivables, StudentReceivableHistory, DunningSettings, DunningPreview,
/// InvoiceDunning, EnrollmentDunningResult). Tiền là số nguyên đồng.

/// Nhóm tuổi nợ: số ngày từ hạn của hóa đơn cũ nhất còn nợ; chưa tới hạn tính `0-30`.
enum AgingBucket {
  upTo30('0-30'),
  from31To60('31-60'),
  over60('over-60');

  const AgingBucket(this.wire);
  final String wire;

  /// Giá trị lạ coi như `0-30` (nhóm nhẹ nhất, không báo động sai).
  static AgingBucket fromWire(String? v) =>
      values.firstWhere((b) => b.wire == v, orElse: () => upTo30);
}

enum ReceivableSort {
  amount('amount'),
  overdueDays('overdueDays'),
  studentName('studentName');

  const ReceivableSort(this.wire);
  final String wire;
}

class ReceivableRow extends Equatable {
  const ReceivableRow({
    required this.studentId,
    required this.studentName,
    required this.classNames,
    required this.outstandingAmount,
    required this.openInvoiceCount,
    required this.oldestDueDate,
    required this.overdueDays,
    required this.agingBucket,
  });

  factory ReceivableRow.fromJson(Map<String, dynamic> json) => ReceivableRow(
    studentId: json['studentId'] as String,
    studentName: json['studentName'] as String,
    classNames: [for (final c in json['classNames'] as List) c as String],
    outstandingAmount: json['outstandingAmount'] as int,
    openInvoiceCount: json['openInvoiceCount'] as int,
    oldestDueDate: json['oldestDueDate'] as String,
    overdueDays: json['overdueDays'] as int,
    agingBucket: AgingBucket.fromWire(json['agingBucket'] as String?),
  );

  final String studentId;
  final String studentName;
  final List<String> classNames;
  final int outstandingAmount;
  final int openInvoiceCount;

  /// `YYYY-MM-DD`: hạn của hóa đơn cũ nhất còn nợ.
  final String oldestDueDate;

  /// 0 khi chưa tới hạn.
  final int overdueDays;
  final AgingBucket agingBucket;

  @override
  List<Object?> get props => [
    studentId, studentName, classNames, outstandingAmount, openInvoiceCount, //
    oldestDueDate, overdueDays, agingBucket,
  ];
}

class AgingSummary extends Equatable {
  const AgingSummary({
    required this.bucket,
    required this.studentCount,
    required this.totalAmount,
  });

  factory AgingSummary.fromJson(Map<String, dynamic> json) => AgingSummary(
    bucket: AgingBucket.fromWire(json['agingBucket'] as String?),
    studentCount: json['studentCount'] as int,
    totalAmount: json['totalAmount'] as int,
  );

  final AgingBucket bucket;
  final int studentCount;
  final int totalAmount;

  @override
  List<Object?> get props => [bucket, studentCount, totalAmount];
}

/// Một trang `GET /receivables` kèm tổng theo nhóm (không lọc theo nhóm đang chọn).
class ReceivablePage extends Equatable {
  const ReceivablePage({
    required this.items,
    required this.total,
    required this.page,
    required this.totalAmount,
    required this.buckets,
  });

  factory ReceivablePage.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>;
    return ReceivablePage(
      items: [
        for (final e in json['items'] as List)
          ReceivableRow.fromJson(e as Map<String, dynamic>),
      ],
      total: json['total'] as int,
      page: json['page'] as int,
      totalAmount: summary['totalAmount'] as int,
      buckets: [
        for (final b in summary['buckets'] as List)
          AgingSummary.fromJson(b as Map<String, dynamic>),
      ],
    );
  }

  final List<ReceivableRow> items;

  /// Số học viên khớp bộ lọc (mọi trang).
  final int total;
  final int page;
  final int totalAmount;
  final List<AgingSummary> buckets;

  @override
  List<Object?> get props => [items, total, page, totalAmount, buckets];
}

class ReceivableEnrollment extends Equatable {
  const ReceivableEnrollment({
    required this.enrollmentId,
    required this.classId,
    required this.className,
    required this.dunningEnabled,
  });

  factory ReceivableEnrollment.fromJson(Map<String, dynamic> json) =>
      ReceivableEnrollment(
        enrollmentId: json['enrollmentId'] as String,
        classId: json['classId'] as String,
        className: json['className'] as String,
        dunningEnabled: json['dunningEnabled'] as bool,
      );

  final String enrollmentId;
  final String classId;
  final String className;
  final bool dunningEnabled;

  ReceivableEnrollment withDunning(bool enabled) => ReceivableEnrollment(
    enrollmentId: enrollmentId,
    classId: classId,
    className: className,
    dunningEnabled: enabled,
  );

  @override
  List<Object?> get props => [enrollmentId, classId, className, dunningEnabled];
}

class ReceivableInvoice extends Equatable {
  const ReceivableInvoice({
    required this.id,
    required this.code,
    required this.periodMonth,
    required this.status,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.dueDate,
  });

  factory ReceivableInvoice.fromJson(Map<String, dynamic> json) =>
      ReceivableInvoice(
        id: json['id'] as String,
        code: json['code'] as String?,
        periodMonth: json['periodMonth'] as String,
        status: InvoiceStatus.fromWire(json['status'] as String?),
        totalAmount: json['totalAmount'] as int,
        paidAmount: json['paidAmount'] as int,
        remainingAmount: json['remainingAmount'] as int,
        dueDate: json['dueDate'] as String,
      );

  final String id;
  final String? code;

  /// `YYYY-MM-01`.
  final String periodMonth;
  final InvoiceStatus status;
  final int totalAmount;
  final int paidAmount;
  final int remainingAmount;
  final String dueDate;

  int get year => int.parse(periodMonth.substring(0, 4));
  int get month => int.parse(periodMonth.substring(5, 7));

  @override
  List<Object?> get props => [
    id, code, periodMonth, status, totalAmount, paidAmount, remainingAmount, //
    dueDate,
  ];
}

class ReceivablePayment extends Equatable {
  const ReceivablePayment({
    required this.id,
    required this.invoiceId,
    required this.invoiceCode,
    required this.amount,
    required this.method,
    required this.paidOn,
    required this.voided,
  });

  factory ReceivablePayment.fromJson(Map<String, dynamic> json) =>
      ReceivablePayment(
        id: json['id'] as String,
        invoiceId: json['invoiceId'] as String,
        invoiceCode: json['invoiceCode'] as String?,
        amount: json['amount'] as int,
        method: PaymentMethod.fromWire(json['method'] as String?),
        paidOn: json['paidOn'] as String,
        voided: json['voidedAt'] != null,
      );

  final String id;
  final String invoiceId;
  final String? invoiceCode;
  final int amount;
  final PaymentMethod method;

  /// `YYYY-MM-DD`.
  final String paidOn;
  final bool voided;

  @override
  List<Object?> get props => [
    id, invoiceId, invoiceCode, amount, method, paidOn, voided, //
  ];
}

/// `pending` chờ tới mốc, `sent` đã gửi, `cancelled` đã hủy (thu đủ, tắt nhắc…).
enum DunningStepStatus {
  pending,
  sent,
  cancelled;

  static DunningStepStatus fromWire(String? v) => switch (v) {
    'sent' => sent,
    'cancelled' => cancelled,
    _ => pending,
  };
}

class DunningStep extends Equatable {
  const DunningStep({
    required this.offsetDays,
    required this.scheduledFor,
    required this.status,
    required this.sentAt,
  });

  factory DunningStep.fromJson(Map<String, dynamic> json) => DunningStep(
    offsetDays: json['offsetDays'] as int,
    scheduledFor: json['scheduledFor'] as String,
    status: DunningStepStatus.fromWire(json['status'] as String?),
    sentAt: json['sentAt'] as String?,
  );

  /// Ngày so với hạn thanh toán (âm là trước hạn).
  final int offsetDays;

  /// Thời điểm ISO có múi giờ.
  final String scheduledFor;
  final DunningStepStatus status;
  final String? sentAt;

  @override
  List<Object?> get props => [offsetDays, scheduledFor, status, sentAt];
}

class ReceivableReminder extends Equatable {
  const ReceivableReminder({required this.invoiceCode, required this.step});

  factory ReceivableReminder.fromJson(Map<String, dynamic> json) =>
      ReceivableReminder(
        invoiceCode: json['invoiceCode'] as String?,
        step: DunningStep.fromJson(json),
      );

  final String? invoiceCode;
  final DunningStep step;

  @override
  List<Object?> get props => [invoiceCode, step];
}

/// Lịch sử một học viên (US-8.3 AC3): mới nhất trước, chưa phân trang.
class StudentReceivableHistory extends Equatable {
  const StudentReceivableHistory({
    required this.studentId,
    required this.studentName,
    required this.outstandingAmount,
    required this.dunningEnabled,
    required this.enrollments,
    required this.invoices,
    required this.payments,
    required this.reminders,
  });

  factory StudentReceivableHistory.fromJson(Map<String, dynamic> json) =>
      StudentReceivableHistory(
        studentId: json['studentId'] as String,
        studentName: json['studentName'] as String,
        outstandingAmount: json['outstandingAmount'] as int,
        dunningEnabled: json['dunningEnabled'] as bool,
        enrollments: [
          for (final e in json['enrollments'] as List)
            ReceivableEnrollment.fromJson(e as Map<String, dynamic>),
        ],
        invoices: [
          for (final e in json['invoices'] as List)
            ReceivableInvoice.fromJson(e as Map<String, dynamic>),
        ],
        payments: [
          for (final e in json['payments'] as List)
            ReceivablePayment.fromJson(e as Map<String, dynamic>),
        ],
        reminders: [
          for (final e in json['reminders'] as List)
            ReceivableReminder.fromJson(e as Map<String, dynamic>),
        ],
      );

  final String studentId;
  final String studentName;
  final int outstandingAmount;

  /// Học viên có được nhắc nợ không (còn ít nhất một ghi danh bật nhắc).
  final bool dunningEnabled;
  final List<ReceivableEnrollment> enrollments;
  final List<ReceivableInvoice> invoices;
  final List<ReceivablePayment> payments;
  final List<ReceivableReminder> reminders;

  /// Sau `PUT /enrollments/{id}/dunning`: đổi một ghi danh, cờ học viên theo server.
  StudentReceivableHistory afterToggle(EnrollmentDunningResult r) =>
      StudentReceivableHistory(
        studentId: studentId,
        studentName: studentName,
        outstandingAmount: outstandingAmount,
        dunningEnabled: r.studentDunningEnabled,
        enrollments: [
          for (final e in enrollments)
            e.enrollmentId == r.enrollmentId ? e.withDunning(r.enabled) : e,
        ],
        invoices: invoices,
        payments: payments,
        reminders: reminders,
      );

  @override
  List<Object?> get props => [
    studentId, studentName, outstandingAmount, dunningEnabled, enrollments, //
    invoices, payments, reminders,
  ];
}

class EnrollmentDunningResult extends Equatable {
  const EnrollmentDunningResult({
    required this.enrollmentId,
    required this.enabled,
    required this.studentDunningEnabled,
    required this.cancelledCount,
  });

  factory EnrollmentDunningResult.fromJson(Map<String, dynamic> json) =>
      EnrollmentDunningResult(
        enrollmentId: json['enrollmentId'] as String,
        enabled: json['enabled'] as bool,
        studentDunningEnabled: json['studentDunningEnabled'] as bool,
        cancelledCount: json['cancelledCount'] as int,
      );

  final String enrollmentId;
  final bool enabled;
  final bool studentDunningEnabled;
  final int cancelledCount;

  @override
  List<Object?> get props => [
    enrollmentId, enabled, studentDunningEnabled, cancelledCount, //
  ];
}

/// Vì sao hóa đơn không còn nhắc.
enum DunningDisabledReason {
  tenantDisabled,
  studentDisabled,
  paid,
  voided;

  static DunningDisabledReason? fromWire(String? v) => switch (v) {
    'tenant_disabled' => tenantDisabled,
    'student_disabled' => studentDisabled,
    'paid' => paid,
    'void' => voided,
    _ => null,
  };
}

/// Trạng thái nhắc của một hóa đơn (US-7.5): các mốc đã lập theo thứ tự thời gian.
class InvoiceDunning extends Equatable {
  const InvoiceDunning({
    required this.enabled,
    required this.disabledReason,
    required this.steps,
  });

  factory InvoiceDunning.fromJson(Map<String, dynamic> json) => InvoiceDunning(
    enabled: json['enabled'] as bool,
    disabledReason: DunningDisabledReason.fromWire(
      json['disabledReason'] as String?,
    ),
    steps: [
      for (final s in json['steps'] as List)
        DunningStep.fromJson(s as Map<String, dynamic>),
    ],
  );

  final bool enabled;
  final DunningDisabledReason? disabledReason;
  final List<DunningStep> steps;

  /// Lần nhắc tới: mốc chờ sớm nhất (chỉ khi còn nhắc).
  DunningStep? get next {
    if (!enabled) return null;
    for (final s in steps) {
      if (s.status == DunningStepStatus.pending) return s;
    }
    return null;
  }

  /// Lần nhắc gần nhất đã gửi.
  DunningStep? get lastSent {
    DunningStep? last;
    for (final s in steps) {
      if (s.status == DunningStepStatus.sent) last = s;
    }
    return last;
  }

  @override
  List<Object?> get props => [enabled, disabledReason, steps];
}

/// Giới hạn mốc nhắc của hợp đồng (`DunningSettings.offsetsDays`).
const dunningOffsetMin = -7;
const dunningOffsetMax = 30;
const dunningOffsetsMaxCount = 6;
const defaultDunningOffsets = [-1, 0, 3, 7];

class DunningSettings extends Equatable {
  const DunningSettings({required this.enabled, required this.offsetsDays});

  factory DunningSettings.fromJson(Map<String, dynamic> json) =>
      DunningSettings(
        enabled: json['enabled'] as bool,
        offsetsDays: [for (final o in json['offsetsDays'] as List) o as int],
      );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'offsetsDays': offsetsDays,
  };

  final bool enabled;
  final List<int> offsetsDays;

  @override
  List<Object?> get props => [enabled, offsetsDays];
}

class DunningPreview extends Equatable {
  const DunningPreview({
    required this.offsetDays,
    required this.title,
    required this.body,
  });

  factory DunningPreview.fromJson(Map<String, dynamic> json) => DunningPreview(
    offsetDays: json['offsetDays'] as int,
    title: json['title'] as String,
    body: json['body'] as String,
  );

  final int offsetDays;
  final String title;
  final String body;

  @override
  List<Object?> get props => [offsetDays, title, body];
}
