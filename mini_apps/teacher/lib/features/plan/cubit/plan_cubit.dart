import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../billing/cubit/billing_periods_cubit.dart' show BillingLoad;
import '../../receivables/data/receivables_repository.dart' show asApiException;
import '../data/plan_models.dart';
import '../data/plan_repository.dart';
import '../data/purchase_service.dart';

/// Thông báo một lần sau lệnh của T14.
enum PlanNotice {
  trialStarted,
  purchasePending,
  purchaseUnavailable,
  purchaseFailed,
}

class PlanState extends Equatable {
  const PlanState({
    this.load = BillingLoad.loading,
    this.usage,
    this.busy = false,
    this.error,
    this.actionError,
    this.notice,
  });

  final BillingLoad load;
  final PlanUsage? usage;

  /// Đang bật dùng thử hoặc mua.
  final bool busy;

  /// Lỗi tải ([load] là failure).
  final ApiException? error;

  /// Lỗi của lệnh dùng thử.
  final ApiException? actionError;
  final PlanNotice? notice;

  PlanState copyWith({
    BillingLoad? load,
    PlanUsage? usage,
    bool? busy,
    ApiException? error,
    ApiException? actionError,
    PlanNotice? notice,
  }) => PlanState(
    load: load ?? this.load,
    usage: usage ?? this.usage,
    busy: busy ?? this.busy,
    error: error,
    actionError: actionError,
    notice: notice,
  );

  @override
  List<Object?> get props => [load, usage, busy, error, actionError, notice];
}

/// T14 (US-0.7, US-0.8): gói hiện tại, mức dùng, dùng thử và mua Pro.
class PlanCubit extends Cubit<PlanState> {
  PlanCubit(this._repo, this._purchase, {DraftKeys? keys})
    : _keys = keys ?? DraftKeys(),
      super(const PlanState());
  final PlanRepository _repo;
  final PurchaseService _purchase;
  final DraftKeys _keys;

  /// Tăng mỗi khi lệnh ghi/tải lại bắt đầu: phản hồi làm mới cũ bị bỏ.
  int _seq = 0;

  /// Giá từ store; `null` thì ẩn.
  String? get storePrice => _purchase.priceLabel;

  Future<void> load() async {
    if (isClosed) return;
    final seq = ++_seq;
    emit(const PlanState());
    try {
      final u = await _repo.usage();
      if (isClosed || seq != _seq) return;
      emit(PlanState(load: BillingLoad.ready, usage: u));
    } on Object catch (e) {
      if (isClosed || seq != _seq) return;
      emit(PlanState(load: BillingLoad.failure, error: asApiException(e)));
    }
  }

  /// Kéo để làm mới: lỗi thì giữ số cũ, không đổi màn. Bỏ qua khi đang gửi lệnh
  /// ghi; phản hồi cũ không ghi đè kết quả của lệnh bắt đầu sau nó. [quiet]:
  /// lỗi không thay thông báo đang hiện.
  Future<void> refresh({bool quiet = false}) async {
    if (state.load != BillingLoad.ready) return load();
    if (state.busy) return;
    final seq = ++_seq;
    try {
      final u = await _repo.usage();
      if (!isClosed && seq == _seq) emit(state.copyWith(usage: u));
    } on Object catch (e) {
      if (!isClosed && seq == _seq && !quiet) {
        emit(state.copyWith(actionError: asApiException(e)));
      }
    }
  }

  Future<void> startTrial() async {
    if (state.busy || state.usage == null) return;
    _seq++;
    emit(state.copyWith(busy: true));
    try {
      final u = await _repo.startTrial(idempotencyKey: _keys.of('trial', ''));
      _keys.done('trial');
      if (isClosed) return;
      emit(
        state.copyWith(usage: u, busy: false, notice: PlanNotice.trialStarted),
      );
    } on Object catch (raw) {
      final e = asApiException(raw);
      if (!e.retryable) _keys.done('trial');
      if (isClosed) return;
      emit(state.copyWith(busy: false, actionError: e));
      // Đã dùng thử (422) hoặc đang Pro (409): số liệu cũ sai, tải lại để nút đổi.
      if (e.code == ApiErrorCode.trialAlreadyUsed ||
          e.code == ApiErrorCode.conflictStale) {
        try {
          final u = await _repo.usage();
          if (!isClosed) emit(state.copyWith(usage: u, actionError: e));
        } on Object {
          // Kéo làm mới sẽ tải lại.
        }
      }
    }
  }

  Future<void> purchase() async {
    if (state.busy || state.usage == null) return;
    _seq++;
    emit(state.copyWith(busy: true));
    var outcome = PurchaseOutcome.failed;
    try {
      outcome = await _purchase.purchasePro();
    } on Object {
      // Giữ failed: không kẹt busy.
    }
    if (isClosed) return;
    switch (outcome) {
      case PurchaseOutcome.purchased:
        // Webhook kích hoạt ≤ 1 phút: tải lại một lần, lỗi không thay thông báo.
        emit(state.copyWith(busy: false, notice: PlanNotice.purchasePending));
        await refresh(quiet: true);
      case PurchaseOutcome.cancelled:
        emit(state.copyWith(busy: false));
      case PurchaseOutcome.unavailable:
        emit(
          state.copyWith(busy: false, notice: PlanNotice.purchaseUnavailable),
        );
      case PurchaseOutcome.failed:
        emit(state.copyWith(busy: false, notice: PlanNotice.purchaseFailed));
    }
  }
}
