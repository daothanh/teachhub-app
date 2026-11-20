import 'dart:math';

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
  (String, int)? _lastInput;
  String? _key;

  Future<void> submit({
    required String centerName,
    required int teacherCount,
  }) async {
    if (state.status == WaitlistStatus.submitting) return;
    // Thử lại cùng nội dung giữ khóa; đổi nội dung thì khóa mới.
    final input = (centerName, teacherCount);
    if (_key == null || input != _lastInput) _key = uuidV4(Random.secure());
    _lastInput = input;
    emit(const CenterWaitlistState(status: WaitlistStatus.submitting));
    try {
      await _repo.join(
        centerName: centerName,
        teacherCount: teacherCount,
        idempotencyKey: _key!,
      );
      if (isClosed) return;
      emit(const CenterWaitlistState(status: WaitlistStatus.sent));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(CenterWaitlistState(status: WaitlistStatus.failure, error: e));
    }
  }
}
