import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../classes/data/class_models.dart';
import '../data/invite_models.dart';
import '../data/invite_repository.dart';

enum InviteLinkStatus { loading, ready, failure }

class InviteLinkState extends Equatable {
  const InviteLinkState({
    this.status = InviteLinkStatus.loading,
    this.link,
    this.error,
  });

  final InviteLinkStatus status;
  final InviteLink? link;
  final ApiException? error;

  @override
  List<Object?> get props => [status, link, error];
}

/// Cấp link mời cho MỘT phụ huynh (US-1.6 AC2): hết hạn thì gửi lại bằng lời
/// mời cũ (`resend`), còn lại tạo mới. Thử lại sau lỗi mạng giữ nguyên khóa nên
/// không sinh hai lời mời.
class InviteLinkCubit extends Cubit<InviteLinkState> {
  InviteLinkCubit(this._repo, this.studentId, this.guardian, {Random? random})
    : _random = random,
      super(const InviteLinkState());

  final InviteRepository _repo;
  final String studentId;
  final RosterGuardian guardian;
  final Random? _random;
  String? _key;

  Future<void> start() async {
    emit(const InviteLinkState());
    final key = _key ??= uuidV4(_random ?? Random.secure());
    final resendOf = guardian.inviteStatus == GuardianInviteStatus.expired
        ? guardian.latestInvite?.id
        : null;
    try {
      final link = resendOf == null
          ? await _repo.create(studentId, guardian.id, idempotencyKey: key)
          : await _repo.resend(resendOf, idempotencyKey: key);
      if (isClosed) return;
      emit(InviteLinkState(status: InviteLinkStatus.ready, link: link));
    } on ApiException catch (e) {
      // Lỗi chắc chắn (409, 422…) thì lần sau là lệnh mới; lỗi mạng giữ khóa.
      if (!e.retryable) _key = null;
      if (isClosed) return;
      emit(InviteLinkState(status: InviteLinkStatus.failure, error: e));
    }
  }
}
