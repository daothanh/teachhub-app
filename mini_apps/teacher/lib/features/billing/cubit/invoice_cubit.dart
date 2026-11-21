import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../classes/data/draft_keys.dart';
import '../data/billing_models.dart';
import '../data/billing_repository.dart';
import 'billing_periods_cubit.dart';

enum InvoiceDone { adjusted, voided }

class InvoiceState extends Equatable {
  const InvoiceState({
    this.load = BillingLoad.loading,
    this.invoice,
    this.busy = false,
    this.clientErrors = const {},
    this.serverErrors = const {},
    this.error,
    this.voidError,
    this.done,
  });

  final BillingLoad load;
  final Invoice? invoice;

  /// Đang thêm điều chỉnh hoặc hủy.
  final bool busy;
  final Map<String, AdjustmentError> clientErrors;

  /// 422 theo trường: `{ "amount": ["…"] }`.
  final Map<String, List<String>> serverErrors;

  /// Lỗi tải ([load] là failure) hoặc lỗi chung của lệnh ghi.
  final ApiException? error;

  /// Lỗi của lệnh hủy (hiện ở trang; lỗi điều chỉnh hiện trong form).
  final ApiException? voidError;
  final InvoiceDone? done;

  InvoiceState copyWith({
    BillingLoad? load,
    Invoice? invoice,
    bool? busy,
    Map<String, AdjustmentError> clientErrors = const {},
    Map<String, List<String>> serverErrors = const {},
    ApiException? error,
    ApiException? voidError,
    InvoiceDone? done,
  }) => InvoiceState(
    load: load ?? this.load,
    invoice: invoice ?? this.invoice,
    busy: busy ?? false,
    clientErrors: clientErrors,
    serverErrors: serverErrors,
    error: error,
    voidError: voidError,
    done: done,
  );

  @override
  List<Object?> get props => [
    load, invoice, busy, clientErrors, serverErrors, error, voidError, done, //
  ];
}

/// Chi tiết một hóa đơn: dòng từng buổi, điều chỉnh bản nháp (US-7.2 AC2–AC3)
/// và hủy hóa đơn đã phát hành (US-7.3 AC4). Tổng luôn lấy từ phản hồi server.
class InvoiceCubit extends Cubit<InvoiceState> {
  InvoiceCubit(this._repo, this.invoiceId, {DraftKeys? keys})
    : _keys = keys ?? DraftKeys(),
      super(const InvoiceState());
  final BillingRepository _repo;
  final String invoiceId;
  final DraftKeys _keys;

  Future<void> load() async {
    if (isClosed) return;
    emit(const InvoiceState());
    try {
      final inv = await _repo.getInvoice(invoiceId);
      if (isClosed) return;
      emit(InvoiceState(load: BillingLoad.ready, invoice: inv));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(InvoiceState(load: BillingLoad.failure, error: e));
    }
  }

  /// Xóa lỗi cũ khi mở lại form điều chỉnh.
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
      emit(state.copyWith(voidError: e));
    }
  }
}
