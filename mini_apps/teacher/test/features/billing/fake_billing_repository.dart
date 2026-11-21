import 'dart:async';

import 'package:teacher/features/billing/data/billing_models.dart';
import 'package:teacher/features/billing/data/billing_repository.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

const periodId = '019c0a00-0001-7b30-8c01-000000000001';

BillingPeriod samplePeriod({
  String id = periodId,
  String month = '2026-10-01',
  BillingPeriodStatus status = BillingPeriodStatus.drafting,
  int draftCount = 3,
  int issuedCount = 0,
  int draftTotal = 2700000,
  int issuedTotal = 0,
}) => BillingPeriod(
  id: id,
  periodMonth: month,
  closeDate: '2026-11-01',
  dueDate: '2026-11-11',
  status: status,
  draftCount: draftCount,
  issuedCount: issuedCount,
  voidCount: 0,
  draftTotalAmount: draftTotal,
  issuedTotalAmount: issuedTotal,
);

InvoiceSummary sampleSummary({
  String id = 'i1',
  String name = 'Nguyễn Minh Anh',
  InvoiceStatus status = InvoiceStatus.draft,
  int total = 1200000,
  bool override = false,
}) => InvoiceSummary(
  id: id,
  code: status == InvoiceStatus.draft ? null : 'TH-25K7Q9',
  status: status,
  studentId: 's-$id',
  studentName: name,
  totalAmount: total,
  hasOverride: override,
);

InvoiceLine sampleLine({
  String id = 'l1',
  InvoiceLineKind kind = InvoiceLineKind.session,
  String description = 'Buổi 2026-10-15',
  int amount = 150000,
  bool charged = true,
  NotChargedReason? reason,
  String? date = '2026-10-15',
  String? className = 'Toán 9A',
  String? adjustmentReason,
}) => InvoiceLine(
  id: id,
  kind: kind,
  description: description,
  amount: amount,
  charged: charged,
  notChargedReason: reason,
  sessionDate: date,
  className: className,
  adjustmentReason: adjustmentReason,
);

Invoice sampleInvoice({
  String id = 'i1',
  InvoiceStatus status = InvoiceStatus.draft,
  List<InvoiceLine>? lines,
  int total = 150000,
  int clamped = 0,
  String? voidReason,
}) => Invoice(
  id: id,
  periodId: periodId,
  periodMonth: '2026-10-01',
  code: status == InvoiceStatus.draft ? null : 'TH-25K7Q9',
  status: status,
  studentName: 'Nguyễn Minh Anh',
  totalAmount: total,
  dueDate: '2026-11-11',
  voidReason: voidReason,
  lines: lines ?? [sampleLine()],
  clampedAmount: clamped,
);

/// Bản giả: `calls` ghi tên lệnh, `keys` ghi Idempotency-Key, các `*Error` ném
/// một lần rồi tự xóa (mô phỏng lỗi chập chờn) trừ khi [stickyError].
class FakeBillingRepository implements BillingRepository {
  final calls = <String>[];
  final keys = <String>[];
  final adjustments = <AdjustmentInput>[];
  final issuedIds = <List<String>?>[];

  List<BillingPeriod> periods = [];
  BillingPeriodDetail? detail;
  Invoice? invoice;
  IssueResult issueResult = const IssueResult(
    issuedCount: 2,
    skipped: [],
    totalAmount: 2700000,
  );

  Object? listError;
  Object? periodError;
  Object? invoiceError;
  Object? adjustError;
  Object? issueError;
  Object? voidError;

  /// Giữ lệnh chốt đang chạy tới khi test hoàn tất cổng này.
  Completer<void>? issueGate;

  /// Hóa đơn trả về cho lần `getInvoice` kế tiếp (rồi tự xóa).
  Invoice? invoiceAfterError;

  @override
  Future<List<BillingPeriod>> listPeriods() async {
    calls.add('listPeriods');
    if (listError != null) throw listError!;
    return periods;
  }

  @override
  Future<BillingPeriodDetail> getPeriod(String id) async {
    calls.add('getPeriod:$id');
    if (periodError != null) throw periodError!;
    return detail!;
  }

  @override
  Future<Invoice> getInvoice(String id) async {
    calls.add('getInvoice:$id');
    if (invoiceError != null) throw invoiceError!;
    if (invoiceAfterError != null) {
      final i = invoiceAfterError!;
      invoiceAfterError = null;
      return invoice = i;
    }
    return invoice!;
  }

  @override
  Future<Invoice> addAdjustment(
    String invoiceId,
    AdjustmentInput input, {
    required String idempotencyKey,
  }) async {
    calls.add('adjust:$invoiceId');
    keys.add(idempotencyKey);
    adjustments.add(input);
    if (adjustError != null) {
      final e = adjustError!;
      adjustError = null;
      throw e;
    }
    // Server tính lại tổng: test đọc tổng từ phản hồi, không tự cộng.
    final lines = [
      ...invoice!.lines,
      sampleLine(
        id: 'adj${adjustments.length}',
        kind: InvoiceLineKind.manualAdjustment,
        description: input.description,
        amount: input.amount,
        date: null,
        className: null,
        adjustmentReason: input.reason,
      ),
    ];
    return invoice = sampleInvoice(
      id: invoiceId,
      lines: lines,
      total: lines.fold<int>(0, (s, l) => s + l.amount).clamp(0, 1 << 40),
    );
  }

  @override
  Future<IssueResult> issue(
    String periodId, {
    List<String>? invoiceIds,
    required String idempotencyKey,
  }) async {
    calls.add('issue:$periodId');
    keys.add(idempotencyKey);
    issuedIds.add(invoiceIds);
    await issueGate?.future;
    if (issueError != null) {
      final e = issueError!;
      issueError = null;
      throw e;
    }
    return issueResult;
  }

  @override
  Future<Invoice> voidInvoice(
    String invoiceId, {
    required String reason,
    required String idempotencyKey,
  }) async {
    calls.add('void:$invoiceId:$reason');
    keys.add(idempotencyKey);
    if (voidError != null) {
      final e = voidError!;
      voidError = null;
      throw e;
    }
    return invoice = sampleInvoice(
      id: invoiceId,
      status: InvoiceStatus.voided,
      voidReason: reason,
    );
  }
}

ApiException fieldErr(Map<String, List<String>> errors) => ApiException(
  code: ApiErrorCode.validationFailed,
  wireCode: 'VALIDATION_FAILED',
  status: 422,
  fieldErrors: errors,
);

BillingPeriodDetail sampleDetail({List<InvoiceSummary>? invoices}) {
  final items =
      invoices ??
      [
        sampleSummary(id: 'i1', name: 'An', total: 1200000),
        sampleSummary(id: 'i2', name: 'Bình', total: 1500000, override: true),
        sampleSummary(id: 'i3', name: 'Chi', total: 0),
      ];
  return BillingPeriodDetail(
    period: samplePeriod(),
    invoices: items,
    invoiceTotal: items.length,
  );
}
