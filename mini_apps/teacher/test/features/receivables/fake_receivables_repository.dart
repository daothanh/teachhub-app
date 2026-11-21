import 'dart:async';

import 'package:teacher/features/billing/data/billing_models.dart';
import 'package:teacher/features/receivables/data/receivable_models.dart';
import 'package:teacher/features/receivables/data/receivables_repository.dart';

ReceivableRow sampleRow({
  String id = 's1',
  String name = 'Nguyễn Minh Anh',
  List<String> classes = const ['Toán 9A'],
  int amount = 700000,
  int overdue = 12,
  AgingBucket bucket = AgingBucket.upTo30,
  int invoices = 1,
}) => ReceivableRow(
  studentId: id,
  studentName: name,
  classNames: classes,
  outstandingAmount: amount,
  openInvoiceCount: invoices,
  oldestDueDate: '2026-11-01',
  overdueDays: overdue,
  agingBucket: bucket,
);

DunningStep sampleStep({
  int offset = -1,
  DunningStepStatus status = DunningStepStatus.sent,
  String scheduled = '2026-11-10T09:00:00+07:00',
  String? sentAt = '2026-11-10T09:00:12+07:00',
}) => DunningStep(
  offsetDays: offset,
  scheduledFor: scheduled,
  status: status,
  sentAt: sentAt,
);

StudentReceivableHistory sampleHistory({
  String id = 's1',
  String name = 'Nguyễn Minh Anh',
  List<ReceivableEnrollment>? enrollments,
  List<ReceivableInvoice>? invoices,
  List<ReceivablePayment>? payments,
  List<ReceivableReminder>? reminders,
}) {
  final enr =
      enrollments ??
      const [
        ReceivableEnrollment(
          enrollmentId: 'e1',
          classId: 'c1',
          className: 'Toán 9A',
          dunningEnabled: true,
        ),
      ];
  return StudentReceivableHistory(
    studentId: id,
    studentName: name,
    outstandingAmount: 700000,
    dunningEnabled: enr.any((e) => e.dunningEnabled),
    enrollments: enr,
    invoices:
        invoices ??
        const [
          ReceivableInvoice(
            id: 'i1',
            code: 'TH-25K7Q9',
            periodMonth: '2026-10-01',
            status: InvoiceStatus.partiallyPaid,
            totalAmount: 1200000,
            paidAmount: 500000,
            remainingAmount: 700000,
            dueDate: '2026-11-11',
          ),
        ],
    payments:
        payments ??
        const [
          ReceivablePayment(
            id: 'p1',
            invoiceId: 'i1',
            invoiceCode: 'TH-25K7Q9',
            amount: 500000,
            method: PaymentMethod.cash,
            paidOn: '2026-11-05',
            voided: false,
          ),
        ],
    reminders:
        reminders ??
        [ReceivableReminder(invoiceCode: 'TH-25K7Q9', step: sampleStep())],
  );
}

/// Bản giả: lọc, sắp và phân trang như server (tổng theo nhóm không bị lọc nhóm).
/// Các `*Error` ném một lần rồi tự xóa (mô phỏng lỗi chập chờn).
class FakeReceivablesRepository implements ReceivablesRepository {
  final calls = <String>[];
  final listArgs = <({int page, AgingBucket? bucket, String? q, bool asc})>[];
  final putBodies = <DunningSettings>[];

  List<ReceivableRow> rows = [];
  final histories = <String, StudentReceivableHistory>{};
  DunningSettings settings = const DunningSettings(
    enabled: true,
    offsetsDays: defaultDunningOffsets,
  );
  final invoiceDunnings = <String, InvoiceDunning>{};

  Object? listError;
  Object? historyError;
  Object? settingsError;
  Object? putError;
  Object? previewError;
  Object? toggleError;
  Object? invoiceDunningError;

  /// Giữ `list` đang chạy tới khi test hoàn tất cổng này.
  Completer<void>? listGate;

  @override
  Future<ReceivablePage> list({
    int page = 1,
    int pageSize = 20,
    AgingBucket? agingBucket,
    String? query,
    ReceivableSort sort = ReceivableSort.amount,
    bool ascending = false,
  }) async {
    calls.add('list:$page');
    listArgs.add((page: page, bucket: agingBucket, q: query, asc: ascending));
    await listGate?.future;
    if (listError != null) {
      final e = listError!;
      listError = null;
      throw e;
    }
    final byQuery = [
      for (final r in rows)
        if (query == null ||
            r.studentName.toLowerCase().contains(query.toLowerCase()))
          r,
    ];
    final filtered =
        [
          for (final r in byQuery)
            if (agingBucket == null || r.agingBucket == agingBucket) r,
        ]..sort(
          (a, b) => ascending
              ? a.outstandingAmount.compareTo(b.outstandingAmount)
              : b.outstandingAmount.compareTo(a.outstandingAmount),
        );
    final start = (page - 1) * pageSize;
    return ReceivablePage(
      items: filtered.skip(start).take(pageSize).toList(),
      total: filtered.length,
      page: page,
      totalAmount: byQuery.fold(0, (s, r) => s + r.outstandingAmount),
      buckets: [
        for (final b in AgingBucket.values)
          AgingSummary(
            bucket: b,
            studentCount: byQuery.where((r) => r.agingBucket == b).length,
            totalAmount: byQuery
                .where((r) => r.agingBucket == b)
                .fold(0, (s, r) => s + r.outstandingAmount),
          ),
      ],
    );
  }

  @override
  Future<StudentReceivableHistory> history(String studentId) async {
    calls.add('history:$studentId');
    if (historyError != null) {
      final e = historyError!;
      historyError = null;
      throw e;
    }
    return histories[studentId] ?? sampleHistory(id: studentId);
  }

  @override
  Future<DunningSettings> getSettings() async {
    calls.add('getSettings');
    if (settingsError != null) {
      final e = settingsError!;
      settingsError = null;
      throw e;
    }
    return settings;
  }

  @override
  Future<DunningSettings> putSettings(DunningSettings s) async {
    calls.add('putSettings');
    putBodies.add(s);
    if (putError != null) {
      final e = putError!;
      putError = null;
      throw e;
    }
    return settings = s;
  }

  @override
  Future<DunningPreview> preview(int offsetDays) async {
    calls.add('preview:$offsetDays');
    if (previewError != null) {
      final e = previewError!;
      previewError = null;
      throw e;
    }
    return DunningPreview(
      offsetDays: offsetDays,
      title: 'DayHoc nhắc học phí',
      body: 'Hóa đơn TH-25K7Q9 còn 700.000 đ (mốc $offsetDays).',
    );
  }

  @override
  Future<EnrollmentDunningResult> setEnrollmentDunning(
    String enrollmentId, {
    required bool enabled,
  }) async {
    calls.add('toggle:$enrollmentId:$enabled');
    if (toggleError != null) {
      final e = toggleError!;
      toggleError = null;
      throw e;
    }
    // Học viên còn được nhắc khi còn ít nhất một ghi danh bật.
    var result = EnrollmentDunningResult(
      enrollmentId: enrollmentId,
      enabled: enabled,
      studentDunningEnabled: enabled,
      cancelledCount: enabled ? 0 : 2,
    );
    for (final MapEntry(:key, :value) in histories.entries.toList()) {
      if (value.enrollments.any((e) => e.enrollmentId == enrollmentId)) {
        result = EnrollmentDunningResult(
          enrollmentId: enrollmentId,
          enabled: enabled,
          studentDunningEnabled: value.enrollments.any(
            (e) => e.enrollmentId == enrollmentId ? enabled : e.dunningEnabled,
          ),
          cancelledCount: result.cancelledCount,
        );
        histories[key] = value.afterToggle(result);
      }
    }
    return result;
  }

  @override
  Future<InvoiceDunning> invoiceDunning(String invoiceId) async {
    calls.add('invoiceDunning:$invoiceId');
    if (invoiceDunningError != null) {
      final e = invoiceDunningError!;
      invoiceDunningError = null;
      throw e;
    }
    return invoiceDunnings[invoiceId] ??
        InvoiceDunning(
          enabled: true,
          disabledReason: null,
          steps: [
            sampleStep(),
            sampleStep(
              offset: 0,
              status: DunningStepStatus.pending,
              scheduled: '2026-11-11T09:00:00+07:00',
              sentAt: null,
            ),
          ],
        );
  }
}
