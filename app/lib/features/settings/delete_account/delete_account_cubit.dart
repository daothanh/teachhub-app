import 'dart:developer';
import 'dart:math' show Random;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../auth/logout_service.dart';
import 'account_repository.dart';

enum DeleteStep { confirm, code, done }

/// Lý do không xóa được, để màn hình chọn đúng câu chữ.
enum DeleteFailure {
  network,
  otpInvalid,
  otpLocked,
  rateLimited,
  ownerHasStaff,
  tenantHasActiveClasses,
  stale,
  generic,
}

class DeleteAccountState extends Equatable {
  const DeleteAccountState({
    this.step = DeleteStep.confirm,
    this.pending,
    this.pendingLoaded = false,
    this.busy = false,
    this.failure,
    this.attemptsLeft,
    this.retryAfterSec,
  });

  final DeleteStep step;

  /// Số buổi chưa đồng bộ trên máy; `null` khi chưa đọc hoặc không đọc được.
  final int? pending;
  final bool pendingLoaded;
  final bool busy;
  final DeleteFailure? failure;
  final int? attemptsLeft;
  final int? retryAfterSec;

  DeleteAccountState copyWith({
    DeleteStep? step,
    int? pending,
    bool? pendingLoaded,
    bool? busy,
    DeleteFailure? failure,
    int? attemptsLeft,
    int? retryAfterSec,
    bool clearFailure = false,
  }) => DeleteAccountState(
    step: step ?? this.step,
    pending: pending ?? this.pending,
    pendingLoaded: pendingLoaded ?? this.pendingLoaded,
    busy: busy ?? this.busy,
    failure: clearFailure ? null : failure ?? this.failure,
    attemptsLeft: clearFailure ? null : attemptsLeft ?? this.attemptsLeft,
    retryAfterSec: clearFailure ? null : retryAfterSec ?? this.retryAfterSec,
  );

  @override
  List<Object?> get props => [
    step, pending, pendingLoaded, busy, failure, attemptsLeft, retryAfterSec, //
  ];
}

/// Xóa tài khoản: cảnh báo, gửi OTP, nhập OTP, `DELETE /me`, xóa dữ liệu máy.
class DeleteAccountCubit extends Cubit<DeleteAccountState> {
  DeleteAccountCubit({
    required AccountRepository repository,
    required Future<int?> Function() pendingCount,
    required Future<LogoutResult> Function() finish,
    Future<void> Function()? markDeleting,
    Future<void> Function()? clearDeleting,
    Random? random,
  }) : _repo = repository,
       _pendingCount = pendingCount,
       _finish = finish,
       _mark = markDeleting,
       _clear = clearDeleting,
       _random = random,
       super(const DeleteAccountState());

  final AccountRepository _repo;
  final Future<int?> Function() _pendingCount;

  /// Đăng xuất và xóa CSDL cục bộ qua luồng đăng xuất sẵn có.
  final Future<LogoutResult> Function() _finish;

  /// Đặt cờ trước `DELETE /me` (app chết sau 204 thì khởi động sau vẫn xóa
  /// CSDL máy) và bỏ cờ khi bị từ chối hẳn.
  final Future<void> Function()? _mark;
  final Future<void> Function()? _clear;
  final Random? _random;
  // Khóa hiện tại đã được gửi đi mà chưa biết kết quả (lỗi tạm thời).
  var _inFlight = false;
  String? _key;
  String? _otp;

  Future<void> load() async {
    final n = await _pendingCount();
    if (!isClosed) emit(state.copyWith(pending: n, pendingLoaded: true));
  }

  /// Gửi (hoặc gửi lại) mã tới [email] của tài khoản.
  Future<void> sendCode(String email) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true, clearFailure: true));
    try {
      await _repo.sendDeleteOtp(email);
      if (isClosed) return;
      emit(state.copyWith(busy: false, step: DeleteStep.code));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(_failed(e));
    }
  }

  Future<void> confirm(String otp) async {
    if (state.busy) return;
    // Cùng mã thử lại giữ khóa; mã khác là lệnh mới.
    if (_key == null || otp != _otp) {
      _key = uuidV4(_random ?? Random.secure());
      _inFlight = false;
    }
    _otp = otp;
    emit(state.copyWith(busy: true, clearFailure: true));
    try {
      await _mark?.call();
    } on Object catch (e, st) {
      // Không có lưới an toàn thì không gửi lệnh xóa.
      log('Đặt cờ xóa lỗi', name: 'delete_account', error: e, stackTrace: st);
      if (!isClosed) {
        emit(state.copyWith(busy: false, failure: DeleteFailure.generic));
      }
      return;
    }
    var alreadyDeleted = false;
    try {
      await _repo.deleteAccount(otp: otp, idempotencyKey: _key!);
    } on ApiException catch (e) {
      // 401 (không phải sai OTP) khi thử lại cùng khóa: token đã mất vì server
      // xử lý xong lần trước.
      alreadyDeleted =
          _inFlight && e.status == 401 && e.code != ApiErrorCode.otpInvalid;
      if (!alreadyDeleted) {
        _inFlight = e.retryable;
        if (!e.retryable) {
          _key = null;
          await _clear?.call();
        }
        if (isClosed) return;
        emit(_failed(e));
        return;
      }
    }
    _inFlight = false;
    // Server đã xóa; lỗi dọn máy không được làm người dùng tưởng chưa xóa.
    try {
      if (await _finish() == LogoutResult.wipeFailed) {
        log(
          'Xóa CSDL cục bộ lỗi sau khi xóa tài khoản; xóa nốt ở lần khởi động sau',
          name: 'delete_account',
        );
      }
    } on Object catch (e, st) {
      log('Dọn máy lỗi', name: 'delete_account', error: e, stackTrace: st);
    }
    if (!isClosed) emit(state.copyWith(busy: false, step: DeleteStep.done));
  }

  DeleteAccountState _failed(ApiException e) {
    final reason = e.details['reason'];
    final left = e.details['attemptsLeft'];
    final failure = switch (e.code) {
      ApiErrorCode.otpInvalid => DeleteFailure.otpInvalid,
      ApiErrorCode.otpLocked => DeleteFailure.otpLocked,
      ApiErrorCode.rateLimited => DeleteFailure.rateLimited,
      ApiErrorCode.conflictStale => switch (reason) {
        'OWNER_HAS_STAFF' => DeleteFailure.ownerHasStaff,
        'TENANT_HAS_ACTIVE_CLASSES' => DeleteFailure.tenantHasActiveClasses,
        _ => DeleteFailure.stale,
      },
      _ when e.kind == ApiErrorKind.network => DeleteFailure.network,
      _ => DeleteFailure.generic,
    };
    return state.copyWith(
      busy: false,
      failure: failure,
      attemptsLeft: left is int ? left : null,
      retryAfterSec: e.retryAfter?.inSeconds,
    );
  }
}
