import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../billing/cubit/billing_periods_cubit.dart' show BillingLoad;
import '../../classes/data/draft_keys.dart';
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
    bool busy = false,
    ApiException? error,
    ApiException? actionError,
    PlanNotice? notice,
  }) => PlanState(
    load: load ?? this.load,
    usage: usage ?? this.usage,
    busy: busy,
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

  /// Giá từ store; `null` thì ẩn.
  String? get storePrice => _purchase.priceLabel;

  Future<void> load() async {
    if (isClosed) return;
    emit(const PlanState());
    try {
      final u = await _repo.usage();
      if (isClosed) return;
      emit(PlanState(load: BillingLoad.ready, usage: u));
    } on Object catch (e) {
      if (isClosed) return;
      emit(PlanState(load: BillingLoad.failure, error: asApiException(e)));
    }
  }

  /// Kéo để làm mới: lỗi thì giữ số cũ, không đổi màn.
  Future<void> refresh() async {
    if (state.load != BillingLoad.ready) return load();
    try {
      final u = await _repo.usage();
      if (!isClosed) emit(state.copyWith(usage: u));
    } on Object catch (e) {
      if (!isClosed) emit(state.copyWith(actionError: asApiException(e)));
    }
  }

  Future<void> startTrial() async {
    if (state.busy || state.usage == null) return;
    emit(state.copyWith(busy: true));
    try {
      final u = await _repo.startTrial(idempotencyKey: _keys.of('trial', ''));
      _keys.done('trial');
      if (isClosed) return;
      emit(state.copyWith(usage: u, notice: PlanNotice.trialStarted));
    } on ApiException catch (e) {
      if (!e.retryable) _keys.done('trial');
      if (isClosed) return;
      emit(state.copyWith(actionError: e));
      // Đã dùng thử (422) hoặc đang Pro (409): số liệu cũ sai, tải lại để nút đổi.
      if (e.code == ApiErrorCode.trialAlreadyUsed ||
          e.code == ApiErrorCode.conflictStale) {
        try {
          final u = await _repo.usage();
          if (!isClosed) emit(state.copyWith(usage: u, actionError: e));
        } on ApiException {
          // Kéo làm mới sẽ tải lại.
        }
      }
    }
  }

  Future<void> purchase() async {
    if (state.busy || state.usage == null) return;
    emit(state.copyWith(busy: true));
    final outcome = await _purchase.purchasePro();
    if (isClosed) return;
    switch (outcome) {
      case PurchaseOutcome.purchased:
        // Webhook kích hoạt ≤ 1 phút: tải lại một lần, không đợi.
        emit(state.copyWith(notice: PlanNotice.purchasePending));
        await refresh();
      case PurchaseOutcome.cancelled:
        emit(state.copyWith());
      case PurchaseOutcome.unavailable:
        emit(state.copyWith(notice: PlanNotice.purchaseUnavailable));
      case PurchaseOutcome.failed:
        emit(state.copyWith(notice: PlanNotice.purchaseFailed));
    }
  }
}
