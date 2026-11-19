import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'center_waitlist_repository.dart';

enum WaitlistStatus { idle, submitting, sent, failure }

class CenterWaitlistState extends Equatable {
  const CenterWaitlistState({this.status = WaitlistStatus.idle, this.error});

  final WaitlistStatus status;
  final ApiException? error;

  @override
  List<Object?> get props => [status, error];
}

/// Đăng ký sớm Chủ trung tâm (US-0.10 AC4, T01d).
class CenterWaitlistCubit extends Cubit<CenterWaitlistState> {
  CenterWaitlistCubit(this._repo) : super(const CenterWaitlistState());

  final CenterWaitlistRepository _repo;

  Future<void> submit({
    required String centerName,
    required int teacherCount,
  }) async {
    if (state.status == WaitlistStatus.submitting) return;
    emit(const CenterWaitlistState(status: WaitlistStatus.submitting));
    try {
      await _repo.join(centerName: centerName, teacherCount: teacherCount);
      emit(const CenterWaitlistState(status: WaitlistStatus.sent));
    } on ApiException catch (e) {
      emit(CenterWaitlistState(status: WaitlistStatus.failure, error: e));
    }
  }
}
