import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../classes/data/draft_keys.dart';
import '../data/billing_models.dart';
import '../data/billing_repository.dart';
import 'billing_periods_cubit.dart';

enum InvoiceDone { adjusted, voided, paymentRecorded, paymentVoided }

class InvoiceState extends Equatable {
  const InvoiceState({
    this.load = BillingLoad.loading,
    this.invoice,
    this.payments = const [],
    this.busy = false,
    this.clientErrors = const {},
    this.payClientErrors = const {},
    this.serverErrors = const {},
    this.error,
    this.voidError,
    this.staleUnverified = false,
    this.done,
  });

  final BillingLoad load;
  final Invoice? invoice;

  /// Thanh toán của hóa đơn, mới ghi trước, gồm cả đã hủy.
  final List<Payment> payments;

  /// Đang thêm điều chỉnh, ghi thanh toán hoặc hủy.
  final bool busy;
  final Map<String, AdjustmentError> clientErrors;

  /// Trường của form thanh toán sai ở máy (`amount`).
  final Set<String> payClientErrors;

  /// 422 theo trường: `{ "amount": ["…"] }`.
  final Map<String, List<String>> serverErrors;

  /// Lỗi tải ([load] là failure) hoặc lỗi chung của lệnh ghi.
  final ApiException? error;

  /// Lỗi của lệnh hủy (hiện ở trang; lỗi điều chỉnh hiện trong form).
  final ApiException? voidError;

  /// Hủy hoặc ghi thanh toán gặp `CONFLICT_STALE` mà tải lại hóa đơn cũng lỗi.
  final bool staleUnverified;
  final InvoiceDone? done;

  InvoiceState copyWith({
    BillingLoad? load,
    Invoice? invoice,
    List<Payment>? payments,
    bool? busy,
    Map<String, AdjustmentError> clientErrors = const {},
    Set<String> payClientErrors = const {},
    Map<String, List<String>> serverErrors = const {},
    ApiException? error,
    ApiException? voidError,
    bool staleUnverified = false,
    InvoiceDone? done,
  }) => InvoiceState(
    load: load ?? this.load,
    invoice: invoice ?? this.invoice,
    payments: payments ?? this.payments,
    busy: busy ?? false,
    clientErrors: clientErrors,
    payClientErrors: payClientErrors,
    serverErrors: serverErrors,
    error: error,
    voidError: voidError,
    staleUnverified: staleUnverified,
    done: done,
  );

  @override
  List<Object?> get props => [
    load,
    invoice,
    payments,
    busy,
    clientErrors,
    payClientErrors,
    serverErrors,
    error,
    voidError,
    staleUnverified,
    done, //
  ];
}

/// Chi tiết một hóa đơn: dòng từng buổi, điều chỉnh bản nháp (US-7.2 AC2–AC3)
/// và hủy hóa đơn đã phát hành (US-7.3 AC4). Tổng luôn lấy từ phản hồi server.
class InvoiceCubit extends Cubit<InvoiceState> {
  InvoiceCubit(
    this._repo,
    this.invoiceId, {
    DraftKeys? keys,
    DateTime Function()? now,
  }) : _keys = keys ?? DraftKeys(),
       _now = now ?? DateTime.now,
       super(const InvoiceState());
  final BillingRepository _repo;
  final String invoiceId;
  final DraftKeys _keys;
  final DateTime Function() _now;

  /// Hôm nay `YYYY-MM-DD` (ngày thu mặc định và cận trên của ngày thu).
  String get today {
    final d = _now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  Future<void> load() async {
    if (isClosed) return;
    emit(const InvoiceState());
    try {
      final (inv, pays) = await _fetch();
      if (isClosed) return;
      emit(InvoiceState(load: BillingLoad.ready, invoice: inv, payments: pays));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(InvoiceState(load: BillingLoad.failure, error: e));
    }
  }

  /// Bản nháp chưa có thanh toán (và `GET …/payments` trả 404 cho bản nháp).
  Future<(Invoice, List<Payment>)> _fetch() async {
    final inv = await _repo.getInvoice(invoiceId);
    final pays = inv.status == InvoiceStatus.draft
        ? const <Payment>[]
        : await _repo.listPayments(invoiceId);
    return (inv, pays);
  }

  /// Xóa lỗi cũ khi mở lại form điều chỉnh hoặc thanh toán.
  void clearErrors() {
    if (!isClosed) emit(state.copyWith(invoice: state.invoice));
  }

  Future<void> addAdjustment(AdjustmentInput input) async {
    if (state.busy || state.invoice == null) return;
    final local = validateAdjustment(input);
    if (local.isNotEmpty) {
      emit(state.copyWith(clientErrors: local));
      return;
    }
    emit(state.copyWith(busy: true));
    try {
      final inv = await _repo.addAdjustment(
        invoiceId,
        input,
        idempotencyKey: _keys.of(
          'adjust',
          '${input.amount}|${input.description}|${input.reason}',
        ),
      );
      _keys.done('adjust');
      if (isClosed) return;
      emit(state.copyWith(invoice: inv, done: InvoiceDone.adjusted));
    } on ApiException catch (e) {
      if (!e.retryable) _keys.done('adjust');
      if (isClosed) return;
      const known = {'amount', 'description', 'adjustmentReason'};
      final fields = {
        for (final MapEntry(:key, :value) in e.fieldErrors.entries)
          if (known.contains(key)) key: value,
      };
      emit(
        state.copyWith(
          serverErrors: fields,
          // Không trường nào nhận được lỗi thì báo chung.
          error: fields.isEmpty ? e : null,
        ),
      );
      // Hóa đơn đã đổi trạng thái ở nơi khác (đã phát hành/hủy): tải lại để
      // trang không còn hiện nút điều chỉnh; lỗi vẫn giữ trong form.
      if (e.code == ApiErrorCode.invoiceImmutable) {
        try {
          final inv = await _repo.getInvoice(invoiceId);
          if (!isClosed) emit(state.copyWith(invoice: inv, error: e));
        } on ApiException {
          // Kéo làm mới/vào lại sẽ tải lại.
        }
      }
    }
  }

  Future<void> voidInvoice(String reason) async {
    if (state.busy || state.invoice == null) return;
    emit(state.copyWith(busy: true));
    try {
      final inv = await _repo.voidInvoice(
        invoiceId,
        reason: reason,
        idempotencyKey: _keys.of('void', reason.trim()),
      );
      _keys.done('void');
      if (isClosed) return;
      emit(state.copyWith(invoice: inv, done: InvoiceDone.voided));
    } on ApiException catch (e) {
      if (!e.retryable) _keys.done('void');
      if (isClosed) return;
      Invoice? fresh;
      if (e.code == ApiErrorCode.conflictStale) {
        // Kết quả hủy đã lưu quá hạn phát lại: tải lại hóa đơn, lần bấm sau dùng khóa mới.
        try {
          fresh = await _repo.getInvoice(invoiceId);
        } on ApiException {
          // Giữ bản cũ; kéo làm mới/vào lại sẽ tải lại.
        }
        if (isClosed) return;
      }
      emit(
        state.copyWith(
          invoice: fresh,
          voidError: e,
          staleUnverified:
              e.code == ApiErrorCode.conflictStale && fresh == null,
        ),
      );
    }
  }

  Future<void> recordPayment(PaymentInput input) async {
    if (state.busy || state.invoice == null) return;
    final bad = validatePayment(input);
    if (bad.isNotEmpty) {
      emit(state.copyWith(payClientErrors: bad));
      return;
    }
    emit(state.copyWith(busy: true));
    try {
      final r = await _repo.recordPayment(
        invoiceId,
        input,
        idempotencyKey: _keys.of(
          'pay',
          '${input.amount}|${input.method.wire}|${input.paidOn}',
        ),
      );
      _keys.done('pay');
      if (isClosed) return;
      emit(
        state.copyWith(
          invoice: state.invoice!.afterPayment(r),
          payments: [r.payment, ...state.payments],
          done: InvoiceDone.paymentRecorded,
        ),
      );
    } on ApiException catch (e) {
      if (!e.retryable) _keys.done('pay');
      if (isClosed) return;
      const known = {'amount', 'paidOn', 'method'};
      final fields = {
        for (final MapEntry(:key, :value) in e.fieldErrors.entries)
          if (known.contains(key)) key: value,
      };
      emit(
        state.copyWith(serverErrors: fields, error: fields.isEmpty ? e : null),
      );
      await _reloadAfterConflict(e, formError: true);
    }
  }

  Future<void> voidPayment(String paymentId, String reason) async {
    if (state.busy || state.invoice == null) return;
    emit(state.copyWith(busy: true));
    try {
      final r = await _repo.voidPayment(
        paymentId,
        reason: reason,
        idempotencyKey: _keys.of('voidPay:$paymentId', reason.trim()),
      );
      _keys.done('voidPay:$paymentId');
      if (isClosed) return;
      emit(
        state.copyWith(
          invoice: state.invoice!.afterPayment(r),
          payments: [for (final p in state.payments) p.replacing(r.payment)],
          done: InvoiceDone.paymentVoided,
        ),
      );
    } on ApiException catch (e) {
      if (!e.retryable) _keys.done('voidPay:$paymentId');
      if (isClosed) return;
      emit(state.copyWith(voidError: e));
      await _reloadAfterConflict(e, formError: false);
    }
  }

  /// `CONFLICT_STALE` (kết quả đã lưu quá hạn phát lại) hoặc
  /// `INVOICE_NOT_PAYABLE` (hóa đơn đổi trạng thái ở nơi khác): tải lại hóa đơn
  /// và thanh toán, giữ lỗi; lần bấm sau dùng khóa mới. Tải lại cũng lỗi thì
  /// không được nói là đã cập nhật.
  Future<void> _reloadAfterConflict(
    ApiException e, {
    required bool formError,
  }) async {
    if (e.code != ApiErrorCode.conflictStale &&
        e.code != ApiErrorCode.invoiceNotPayable) {
      return;
    }
    try {
      final (inv, pays) = await _fetch();
      if (isClosed) return;
      emit(
        state.copyWith(
          invoice: inv,
          payments: pays,
          error: formError ? e : null,
          voidError: formError ? null : e,
        ),
      );
    } on ApiException {
      if (isClosed) return;
      emit(
        state.copyWith(
          error: formError ? e : null,
          voidError: formError ? null : e,
          staleUnverified: e.code == ApiErrorCode.conflictStale,
        ),
      );
    }
  }
}
