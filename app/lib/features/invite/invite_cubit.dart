import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../consent/consent_cubit.dart';
import '../role_picker/membership_cubit.dart';
import 'invite_accept.dart';
import 'invite_repository.dart';

enum InvitePhase {
  /// Đang xem trước lời mời.
  loading,

  /// Thẻ lời mời đã hiện, chờ người dùng nhận.
  ready,
  accepting,

  /// Server đòi đồng ý điều khoản: trang mở màn đồng ý rồi gọi [InviteCubit.accept] lại.
  consentRequired,
  accepted,

  /// 410: link sai, hết hạn, đã dùng hay bị thu hồi (cùng một thông báo).
  invalid,
  failed,
}

class InviteState extends Equatable {
  const InviteState({
    this.phase = InvitePhase.loading,
    this.preview,
    this.errorCode,
  });

  final InvitePhase phase;
  final InvitePreview? preview;
  final ApiErrorCode? errorCode;

  @override
  List<Object?> get props => [
    phase,
    preview?.teacherName,
    preview?.studentGivenName,
    errorCode,
  ];
}

/// Nhận lời mời từ link/QR (token) — spec §5.2c, US-0.3, US-0.12 AC2.
///
/// Token là bí mật: chỉ giữ trong bộ nhớ của cubit, bỏ ngay khi dùng xong.
class InviteCubit extends Cubit<InviteState> {
  InviteCubit({
    required InviteRepository repository,
    required MembershipCubit memberships,
    required ConsentCubit consent,
    required String token,
  }) : _repo = repository,
       _memberships = memberships,
       _consent = consent,
       _token = token,
       super(const InviteState());

  final InviteRepository _repo;
  final MembershipCubit _memberships;
  final ConsentCubit _consent;
  String? _token;

  /// `POST /invites/preview` (công khai).
  Future<void> load() async {
    final token = _token;
    if (token == null) return;
    emit(const InviteState());
    try {
      final preview = await _repo.preview(token);
      if (!isClosed) {
        emit(InviteState(phase: InvitePhase.ready, preview: preview));
      }
    } catch (e) {
      _fail(e);
    }
  }

  /// `POST /invites/accept`; 403 `CONSENT_REQUIRED` → [InvitePhase.consentRequired].
  Future<void> accept() async {
    final token = _token;
    if (token == null || state.phase == InvitePhase.accepting) return;
    emit(InviteState(phase: InvitePhase.accepting, preview: state.preview));
    try {
      final accepted = await _repo.accept(token);
      await completeInvite(
        accepted: accepted,
        memberships: _memberships,
        consent: _consent,
      );
      _token = null;
      if (!isClosed) {
        emit(InviteState(phase: InvitePhase.accepted, preview: state.preview));
      }
    } catch (e) {
      _fail(e);
    }
  }

  /// Người dùng thoát màn đồng ý mà chưa đồng ý: quay lại thẻ lời mời.
  void consentDeclined() {
    if (state.phase == InvitePhase.consentRequired) {
      emit(InviteState(phase: InvitePhase.ready, preview: state.preview));
    }
  }

  void _fail(Object error) {
    if (isClosed) return;
    final code = error is ApiException ? error.code : ApiErrorCode.unknown;
    final phase = switch (code) {
      ApiErrorCode.consentRequired => InvitePhase.consentRequired,
      ApiErrorCode.inviteInvalid => InvitePhase.invalid,
      _ => InvitePhase.failed,
    };
    if (phase == InvitePhase.invalid) _token = null;
    emit(InviteState(phase: phase, preview: state.preview, errorCode: code));
  }
}
