import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../consent/consent_cubit.dart';
import '../role_picker/membership_cubit.dart';
import 'invite_accept.dart';
import 'invite_repository.dart';

enum InviteEntryPhase {
  idle,
  submitting,

  /// Server đòi đồng ý điều khoản: view mở màn đồng ý rồi gọi [InviteEntryCubit.redeem] lại.
  consentRequired,
  accepted,

  /// 410 (mã sai, hết hạn, đã dùng): cùng một thông báo.
  invalid,

  /// 429 `INVITE_CODE_LOCKED`: nhập sai 5 lần, khóa tới [InviteEntryState.lockedUntil].
  locked,

  /// 429 `RATE_LIMITED` hay lỗi khác.
  failed,
}

class InviteEntryState extends Equatable {
  const InviteEntryState({
    this.phase = InviteEntryPhase.idle,
    this.lockedUntil,
    this.errorCode,
  });

  final InviteEntryPhase phase;
  final DateTime? lockedUntil;
  final ApiErrorCode? errorCode;

  @override
  List<Object?> get props => [phase, lockedUntil, errorCode];
}

/// Nhập mã mời ngắn ở P05 (US-0.12 AC2, AC5). Khóa 5 lần sai do server giữ;
/// cubit chỉ hiển thị và chặn nhập tới hết thời gian khóa.
///
/// Mã là bí mật: chỉ giữ trong bộ nhớ, bỏ ngay khi dùng xong.
class InviteEntryCubit extends Cubit<InviteEntryState> {
  InviteEntryCubit({
    required InviteRepository repository,
    required MembershipCubit memberships,
    required ConsentCubit consent,
    DateTime Function()? clock,
  }) : _repo = repository,
       _memberships = memberships,
       _consent = consent,
       _now = clock ?? DateTime.now,
       super(const InviteEntryState());

  final InviteRepository _repo;
  final MembershipCubit _memberships;
  final ConsentCubit _consent;
  final DateTime Function() _now;
  Timer? _unlock;
  String? _code;

  /// Mặc định khi server không kèm `retryAfterSec` (cùng quy tắc OTP: 15 phút).
  static const defaultLock = Duration(minutes: 15);

  /// `POST /invites/redeem-code`. [code] bỏ trống = thử lại mã đang giữ (sau màn đồng ý).
  Future<void> redeem([String? code]) async {
    if (code != null) _code = code;
    final value = _code;
    if (value == null || state.phase == InviteEntryPhase.submitting) return;
    final lockedUntil = state.lockedUntil;
    if (lockedUntil != null && lockedUntil.isAfter(_now())) return;
    emit(const InviteEntryState(phase: InviteEntryPhase.submitting));
    try {
      final accepted = await _repo.redeemCode(value);
      await completeInvite(
        accepted: accepted,
        memberships: _memberships,
        consent: _consent,
      );
      _code = null;
      if (!isClosed) {
        emit(const InviteEntryState(phase: InviteEntryPhase.accepted));
      }
    } catch (error) {
      if (isClosed) return;
      final e = error is ApiException ? error : null;
      switch (e?.code) {
        case ApiErrorCode.consentRequired:
          emit(const InviteEntryState(phase: InviteEntryPhase.consentRequired));
        case ApiErrorCode.inviteCodeLocked:
          _code = null;
          _lock(e?.retryAfter ?? defaultLock);
        case ApiErrorCode.inviteInvalid:
          _code = null;
          emit(
            const InviteEntryState(
              phase: InviteEntryPhase.invalid,
              errorCode: ApiErrorCode.inviteInvalid,
            ),
          );
        default:
          emit(
            InviteEntryState(
              phase: InviteEntryPhase.failed,
              errorCode: e?.code,
            ),
          );
      }
    }
  }

  /// Thoát màn đồng ý mà chưa đồng ý: bỏ mã đang giữ.
  void consentDeclined() {
    _code = null;
    if (state.phase == InviteEntryPhase.consentRequired) {
      emit(const InviteEntryState());
    }
  }

  void _lock(Duration d) {
    final until = _now().add(d);
    _unlock?.cancel();
    _unlock = Timer(d, () {
      if (!isClosed) emit(const InviteEntryState());
    });
    emit(InviteEntryState(phase: InviteEntryPhase.locked, lockedUntil: until));
  }

  @override
  Future<void> close() {
    _unlock?.cancel();
    return super.close();
  }
}
