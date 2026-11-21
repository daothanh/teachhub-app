import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../classes/data/draft_keys.dart';
import '../data/fee_models.dart';
import '../data/fee_repository.dart';

enum PayoutLoad { loading, ready, failure }

enum PayoutNotice { primarySet, deleted }

class PayoutAccountsState extends Equatable {
  const PayoutAccountsState({
    this.load = PayoutLoad.loading,
    this.accounts = const [],
    this.busy = false,
    this.error,
    this.notice,
  });

  final PayoutLoad load;
  final List<PayoutAccount> accounts;

  /// Đang đặt chính hoặc xóa.
  final bool busy;

  /// Lỗi tải (khi [load] là failure) hoặc lỗi của lệnh đặt chính/xóa.
  final ApiException? error;
  final PayoutNotice? notice;

  bool get canAdd => accounts.length < payoutAccountsMax;

  PayoutAccountsState copyWith({
    PayoutLoad? load,
    List<PayoutAccount>? accounts,
    bool? busy,
    ApiException? error,
    PayoutNotice? notice,
  }) => PayoutAccountsState(
    load: load ?? this.load,
    accounts: accounts ?? this.accounts,
    busy: busy ?? this.busy,
    error: error,
    notice: notice,
  );

  @override
  List<Object?> get props => [load, accounts, busy, error, notice];
}

/// Danh sách tài khoản nhận tiền (US-7.3 AC5): tải, đặt chính, xóa. Thêm và
/// sửa ở [PayoutAccountFormCubit] (cần OTP).
class PayoutAccountsCubit extends Cubit<PayoutAccountsState> {
  PayoutAccountsCubit(this._repo, {DraftKeys? keys})
    : _keys = keys ?? DraftKeys(),
      super(const PayoutAccountsState());
  final FeeRepository _repo;
  final DraftKeys _keys;

  Future<void> load() async {
    emit(state.copyWith(load: PayoutLoad.loading));
    try {
      final items = await _repo.listPayoutAccounts();
      if (isClosed) return;
      emit(PayoutAccountsState(load: PayoutLoad.ready, accounts: items));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(load: PayoutLoad.failure, error: e));
    }
  }

  /// Đặt tài khoản khác làm chính cần OTP (hợp đồng); tài khoản đã là chính
  /// thì không đổi gì.
  bool setPrimaryNeedsOtp(String id) =>
      state.accounts.any((a) => a.id == id && !a.isPrimary);

  /// Xóa tài khoản chính lúc còn tài khoản khác cần OTP; tài khoản phụ hoặc
  /// tài khoản chính duy nhất thì không.
  bool deleteNeedsOtp(String id) =>
      state.accounts.length > 1 &&
      state.accounts.any((a) => a.id == id && a.isPrimary);

  /// Gửi mã `payout_account` tới email đang đăng nhập; `null` = đã gửi.
  Future<ApiException?> sendOtp() async {
    if (state.busy) return null;
    emit(state.copyWith(busy: true));
    try {
      await _repo.sendPayoutOtp();
      if (!isClosed) emit(state.copyWith(busy: false));
      return null;
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(busy: false));
      return e;
    }
  }

  Future<void> setPrimary(String id, {String? otpCode}) =>
      _act('primary|$id', otpCode, PayoutNotice.primarySet, (key) async {
        await _repo.updatePayoutAccount(
          id,
          makePrimary: true,
          otpCode: otpCode,
          idempotencyKey: key,
        );
      });

  Future<void> delete(String id, {String? otpCode}) =>
      _act('delete|$id', otpCode, PayoutNotice.deleted, (key) async {
        await _repo.deletePayoutAccount(
          id,
          otpCode: otpCode,
          idempotencyKey: key,
        );
      });

  Future<void> _act(
    String op,
    String? otpCode,
    PayoutNotice notice,
    Future<void> Function(String key) run,
  ) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    try {
      await run(_keys.of(op, '$op|$otpCode'));
      _keys.done(op);
    } on ApiException catch (e) {
      if (!e.retryable) _keys.done(op);
      if (isClosed) return;
      emit(state.copyWith(busy: false, error: e));
      return;
    }
    // Lệnh ghi đã thành công: tải lại lỗi không được báo như ghi lỗi.
    // Tải lại vì xóa tài khoản chính đổi chính sang tài khoản khác (server).
    try {
      final items = await _repo.listPayoutAccounts();
      if (isClosed) return;
      emit(
        PayoutAccountsState(
          load: PayoutLoad.ready,
          accounts: items,
          notice: notice,
        ),
      );
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(_applyLocally(op, notice, e));
    }
  }

  /// Tải lại lỗi: cập nhật danh sách tại máy theo lệnh đã thành công. Xóa tài
  /// khoản chính khi còn tài khoản khác thì chưa biết server chọn tài khoản
  /// nào làm chính → trạng thái tải lỗi, có nút thử lại.
  PayoutAccountsState _applyLocally(
    String op,
    PayoutNotice notice,
    ApiException e,
  ) {
    final id = op.split('|').last;
    final accounts = state.accounts;
    if (notice == PayoutNotice.primarySet) {
      return PayoutAccountsState(
        load: PayoutLoad.ready,
        notice: notice,
        accounts: [
          for (final a in accounts)
            PayoutAccount(
              id: a.id,
              bankBin: a.bankBin,
              accountNoMasked: a.accountNoMasked,
              accountName: a.accountName,
              isPrimary: a.id == id,
            ),
        ],
      );
    }
    final removedPrimary = accounts.any((a) => a.id == id && a.isPrimary);
    final rest = [
      for (final a in accounts)
        if (a.id != id) a,
    ];
    if (removedPrimary && rest.isNotEmpty) {
      return PayoutAccountsState(load: PayoutLoad.failure, error: e);
    }
    return PayoutAccountsState(
      load: PayoutLoad.ready,
      accounts: rest,
      notice: notice,
    );
  }
}
