import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../data/fee_models.dart';
import '../data/fee_repository.dart';

enum PayoutStep { form, code }

class PayoutFormState extends Equatable {
  const PayoutFormState({
    this.step = PayoutStep.form,
    this.busy = false,
    this.codeSent = false,
    this.clientErrors = const {},
    this.serverErrors = const {},
    this.error,
    this.saved,
  });

  final PayoutStep step;
  final bool busy;

  /// Vừa gửi (hoặc gửi lại) mã thành công.
  final bool codeSent;
  final Map<String, PayoutFieldError> clientErrors;

  /// 422 theo trường: `bankBin`, `accountNo`, `accountName`, `otpCode`.
  final Map<String, List<String>> serverErrors;

  /// Lỗi chung hoặc lỗi mã (`OTP_INVALID`, `OTP_LOCKED`), 429, mạng…
  final ApiException? error;
  final PayoutAccount? saved;

  PayoutFormState copyWith({
    PayoutStep? step,
    bool? busy,
    bool? codeSent,
    Map<String, PayoutFieldError>? clientErrors,
    Map<String, List<String>>? serverErrors,
    ApiException? error,
    PayoutAccount? saved,
  }) => PayoutFormState(
    step: step ?? this.step,
    busy: busy ?? this.busy,
    codeSent: codeSent ?? this.codeSent,
    clientErrors: clientErrors ?? this.clientErrors,
    serverErrors: serverErrors ?? this.serverErrors,
    error: error,
    saved: saved ?? this.saved,
  );

  @override
  List<Object?> get props => [
    step, busy, codeSent, clientErrors, serverErrors, error, saved, //
  ];
}

/// Thêm hoặc sửa tài khoản nhận tiền. Thêm mới, đổi ngân hàng hoặc số tài
/// khoản phải qua OTP `payout_account`; chỉ đổi tên chủ tài khoản thì không.
/// Số tài khoản đầy đủ chỉ nằm trong [_pending] và request, không vào state.
class PayoutAccountFormCubit extends Cubit<PayoutFormState> {
  PayoutAccountFormCubit(this._repo, {this.editing, DraftKeys? keys})
    : _keys = keys ?? DraftKeys(),
      super(const PayoutFormState());
  final FeeRepository _repo;
  final PayoutAccount? editing;
  final DraftKeys _keys;
  PayoutAccountInput? _pending;

  bool _bankChanged(PayoutAccountInput i) =>
      editing != null && i.bankBin != editing!.bankBin;

  /// Có phải qua OTP không (thêm mới, hoặc đổi ngân hàng / số tài khoản).
  bool needsOtp(PayoutAccountInput i) =>
      editing == null || i.accountNo.isNotEmpty || _bankChanged(i);

  Future<void> submit(PayoutAccountInput input) async {
    if (state.busy) return;
    final local = validatePayoutInput(
      input,
      accountNoRequired: editing == null || _bankChanged(input),
    );
    if (local.isNotEmpty) {
      emit(PayoutFormState(clientErrors: local));
      return;
    }
    _pending = input;
    if (needsOtp(input)) return sendCode();
    return _save(input, otp: null);
  }

  /// Gửi (hoặc gửi lại) mã tới email của tài khoản đang đăng nhập.
  Future<void> sendCode() async {
    if (state.busy || _pending == null) return;
    // Gửi lại mã ở bước nhập mã: giữ lỗi theo trường và dòng "đã gửi mã".
    emit(
      state.step == PayoutStep.code
          ? state.copyWith(busy: true)
          : const PayoutFormState(busy: true),
    );
    try {
      await _repo.sendPayoutOtp();
      if (isClosed) return;
      emit(const PayoutFormState(step: PayoutStep.code, codeSent: true));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(busy: false, error: e));
    }
  }

  Future<void> confirm(String otp) async {
    final input = _pending;
    if (state.busy || input == null) return;
    return _save(input, otp: otp);
  }

  /// Quay lại form để sửa; quên dữ liệu đang giữ.
  void backToForm() {
    _pending = null;
    emit(const PayoutFormState());
  }

  Future<void> _save(PayoutAccountInput input, {required String? otp}) async {
    final current = editing;
    if (current != null &&
        !needsOtp(input) &&
        input.accountName.trim() == current.accountName) {
      // Không đổi gì: khỏi gọi API.
      emit(PayoutFormState(saved: current));
      return;
    }
    emit(PayoutFormState(step: state.step, busy: true));
    final draft =
        '${input.bankBin}|${input.accountNo}|${input.accountName}|$otp';
    try {
      final saved = editing == null
          ? await _repo.createPayoutAccount(
              input,
              otpCode: otp!,
              idempotencyKey: _keys.of('save', draft),
            )
          : await _repo.updatePayoutAccount(
              editing!.id,
              bankBin: _bankChanged(input) ? input.bankBin : null,
              accountNo: input.accountNo.isEmpty ? null : input.accountNo,
              accountName: input.accountName.trim() == editing!.accountName
                  ? null
                  : input.accountName,
              otpCode: otp,
              idempotencyKey: _keys.of('save', draft),
            );
      _keys.done('save');
      _pending = null;
      if (isClosed) return;
      emit(PayoutFormState(saved: saved));
    } on ApiException catch (e) {
      if (!e.retryable) _keys.done('save');
      if (isClosed) return;
      final fields = {
        for (final MapEntry(:key, :value) in e.fieldErrors.entries)
          if (_known.contains(key)) key: value,
      };
      final onlyCode = fields.keys.every((k) => k == 'otpCode');
      emit(
        PayoutFormState(
          // Lỗi ở trường khác ngoài mã thì về form để sửa.
          step: fields.isNotEmpty && !onlyCode ? PayoutStep.form : state.step,
          serverErrors: fields,
          error: fields.isEmpty || fields.length != e.fieldErrors.length
              ? e
              : null,
        ),
      );
    }
  }

  static const _known = {'bankBin', 'accountNo', 'accountName', 'otpCode'};
}
