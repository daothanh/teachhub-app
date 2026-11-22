import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../data/billing_repository.dart';
import '../data/claim_models.dart';
import 'billing_periods_cubit.dart';

enum ClaimDone { confirmed, rejected }

class PaymentClaimsState extends Equatable {
  const PaymentClaimsState({
    this.load = BillingLoad.loading,
    this.claims = const [],
    this.busy = false,
    this.error,
    this.done,
    this.staleUnverified = false,
    this.invoiceChanged = 0,
  });

  final BillingLoad load;

  /// Mới nhất trước.
  final List<PaymentClaim> claims;

  /// Đang xác nhận hoặc từ chối.
  final bool busy;

  /// Lỗi tải ([load] là failure) hoặc lỗi của lệnh xử lý.
  final ApiException? error;
  final ClaimDone? done;

  /// 409 mà tải lại danh sách cũng lỗi: không được nói là đã cập nhật.
  final bool staleUnverified;

  /// Tăng mỗi khi hóa đơn có thể đã đổi (xử lý xong hoặc 409): trang tải lại hóa đơn.
  final int invoiceChanged;

  PaymentClaimsState copyWith({
    BillingLoad? load,
    List<PaymentClaim>? claims,
    bool busy = false,
    ApiException? error,
    ClaimDone? done,
    bool staleUnverified = false,
    bool invoiceChanged = false,
  }) => PaymentClaimsState(
    load: load ?? this.load,
    claims: claims ?? this.claims,
    busy: busy,
    error: error,
    done: done,
    staleUnverified: staleUnverified,
    invoiceChanged: this.invoiceChanged + (invoiceChanged ? 1 : 0),
  );

  @override
  List<Object?> get props => [
    load,
    claims,
    busy,
    error,
    done,
    staleUnverified,
    invoiceChanged,
  ];
}

/// Các lần phụ huynh báo đã chuyển khoản của một hóa đơn và việc xác nhận hoặc
/// từ chối (US-7.7 AC2, AC3). Mỗi lệnh giữ một `Idempotency-Key` qua thử lại.
class PaymentClaimsCubit extends Cubit<PaymentClaimsState> {
  PaymentClaimsCubit(this._repo, this.invoiceId, {DraftKeys? keys})
    : _keys = keys ?? DraftKeys(),
      super(const PaymentClaimsState());

  final BillingRepository _repo;
  final String invoiceId;
  final DraftKeys _keys;

  Future<void> load() async {
    if (isClosed) return;
    emit(const PaymentClaimsState());
    try {
      final claims = await _repo.listClaims(invoiceId);
      if (isClosed) return;
      emit(PaymentClaimsState(load: BillingLoad.ready, claims: claims));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(PaymentClaimsState(load: BillingLoad.failure, error: e));
    }
  }

  /// Xác nhận với số tiền ghi thu [amount] (sửa được so với số phụ huynh khai).
  Future<void> confirm(PaymentClaim claim, int amount) =>
      _resolve(claim, ClaimResolution.confirm(amount));

  Future<void> reject(PaymentClaim claim, String reason) =>
      _resolve(claim, ClaimResolution.reject(reason));

  Future<void> _resolve(PaymentClaim claim, ClaimResolution r) async {
    if (state.busy || !claim.isPending) return;
    if (r.validate().isNotEmpty) return;
    emit(state.copyWith(busy: true));
    final op = 'resolve:${claim.id}';
    try {
      final res = await _repo.resolveClaim(
        claim.id,
        r,
        idempotencyKey: _keys.of(op, '${r.amount}|${r.reason?.trim()}'),
      );
      _keys.done(op);
      if (isClosed) return;
      emit(
        state.copyWith(
          claims: [
            for (final c in state.claims) c.id == claim.id ? res.claim : c,
          ],
          done: r.isConfirm ? ClaimDone.confirmed : ClaimDone.rejected,
          invoiceChanged: true,
        ),
      );
    } on ApiException catch (e) {
      if (!e.retryable) _keys.done(op);
      if (isClosed) return;
      final stale =
          e.code == ApiErrorCode.conflictStale ||
          e.code == ApiErrorCode.invoiceNotPayable;
      emit(state.copyWith(error: e, invoiceChanged: stale));
      if (!stale) return;
      // Lần báo đã được xử lý ở nơi khác (hoặc kết quả lưu quá hạn phát lại):
      // tải lại danh sách để các nút phản ánh đúng; lần bấm sau dùng khóa mới.
      try {
        final claims = await _repo.listClaims(invoiceId);
        if (!isClosed) emit(state.copyWith(claims: claims, error: e));
      } on ApiException {
        if (!isClosed) emit(state.copyWith(error: e, staleUnverified: true));
      }
    }
  }
}
