import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../classes/data/draft_keys.dart';
import '../data/fee_models.dart';
import '../data/fee_repository.dart';

enum FeeOverrideDone { saved, cleared }

class FeeOverrideState extends Equatable {
  const FeeOverrideState({
    this.saving = false,
    this.done,
    this.clientErrors = const {},
    this.serverErrors = const {},
    this.error,
  });

  final bool saving;
  final FeeOverrideDone? done;
  final Map<String, FeeOverrideError> clientErrors;

  /// 422 theo trường: `{ "feeAmount": ["…"] }`.
  final Map<String, List<String>> serverErrors;

  /// Lỗi chung (409, 429, mạng…) hoặc 422 không gắn được vào trường.
  final ApiException? error;

  @override
  List<Object?> get props => [saving, done, clientErrors, serverErrors, error];
}

/// Mức riêng của một học viên trong lớp (US-1.3): `PUT` thay toàn bộ, `{}` xóa.
/// Không tự thử lại khi lỗi (kể cả 429): người dùng bấm Lưu lại.
class FeeOverrideCubit extends Cubit<FeeOverrideState> {
  FeeOverrideCubit(this._repo, this.enrollmentId, {DraftKeys? keys})
    : _keys = keys ?? DraftKeys(),
      super(const FeeOverrideState());
  final FeeRepository _repo;
  final String enrollmentId;
  final DraftKeys _keys;

  Future<void> save(FeeOverride value) async {
    if (state.saving) return;
    final local = validateFeeOverride(value);
    if (local.isNotEmpty) {
      emit(FeeOverrideState(clientErrors: local));
      return;
    }
    emit(const FeeOverrideState(saving: true));
    final body = value.toJson().toString();
    try {
      await _repo.putFeeOverride(
        enrollmentId,
        value,
        idempotencyKey: _keys.of('put', body),
      );
      _keys.done('put');
      if (isClosed) return;
      emit(
        FeeOverrideState(
          done: value.isEmpty ? FeeOverrideDone.cleared : FeeOverrideDone.saved,
        ),
      );
    } on ApiException catch (e) {
      if (!e.retryable) _keys.done('put');
      if (isClosed) return;
      final known = e.fieldErrors.keys.every(_isKnown);
      emit(
        FeeOverrideState(
          serverErrors: {
            for (final MapEntry(:key, :value) in e.fieldErrors.entries)
              if (_isKnown(key)) key: value,
          },
          // Không trường nào nhận được lỗi thì báo chung.
          error: e.fieldErrors.isEmpty || !known ? e : null,
        ),
      );
    }
  }

  /// Xóa mức riêng: `PUT {}`.
  Future<void> clear() => save(const FeeOverride());

  static bool _isKnown(String key) =>
      key == 'feeAmount' ||
      key == 'installments' ||
      key.startsWith('discounts') ||
      key.startsWith('charge') ||
      key == 'deductCancelled';
}
