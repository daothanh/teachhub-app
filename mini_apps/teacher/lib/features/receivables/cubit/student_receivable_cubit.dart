import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../billing/cubit/billing_periods_cubit.dart' show BillingLoad;
import '../data/receivable_models.dart';
import '../data/receivables_repository.dart';

class StudentReceivableState extends Equatable {
  const StudentReceivableState({
    this.load = BillingLoad.loading,
    this.history,
    this.toggling = const {},
    this.error,
  });

  final BillingLoad load;
  final StudentReceivableHistory? history;

  /// Ghi danh đang gọi bật/tắt nhắc nợ.
  final Set<String> toggling;

  /// Lỗi tải ([load] là failure) hoặc lỗi của lệnh bật/tắt.
  final ApiException? error;

  @override
  List<Object?> get props => [load, history, toggling, error];
}

/// Lịch sử công nợ một học viên (US-8.3 AC3) và bật/tắt nhắc nợ theo ghi danh
/// (US-7.5 AC3). Dùng chung cho màn T11 chi tiết và hộp thoại ở danh sách lớp.
class StudentReceivableCubit extends Cubit<StudentReceivableState> {
  StudentReceivableCubit(this._repo, this.studentId)
    : super(const StudentReceivableState());
  final ReceivablesRepository _repo;
  final String studentId;
  int _seq = 0;

  Future<void> load() async {
    if (isClosed) return;
    emit(const StudentReceivableState());
    await _fetch(++_seq);
  }

  /// Quay lại màn (đã ghi thu ở chi tiết hóa đơn): giữ dữ liệu cũ tới khi có mới.
  Future<void> refresh() async {
    if (state.load != BillingLoad.ready) return load();
    await _fetch(++_seq);
  }

  /// Phản hồi của lần tải cũ (đã có lần tải mới hơn) bị bỏ.
  Future<void> _fetch(int seq) async {
    try {
      final h = await _repo.history(studentId);
      if (isClosed || seq != _seq) return;
      emit(
        StudentReceivableState(
          load: BillingLoad.ready,
          history: h,
          toggling: state.toggling,
        ),
      );
    } on Object catch (raw) {
      final e = asApiException(raw);
      if (isClosed || seq != _seq || state.load == BillingLoad.ready) return;
      emit(StudentReceivableState(load: BillingLoad.failure, error: e));
    }
  }

  /// Bật/tắt nhắc nợ của một ghi danh; trạng thái lấy từ phản hồi server.
  Future<void> setDunning(String enrollmentId, bool enabled) async {
    final s = state;
    final h = s.history;
    if (h == null || s.toggling.contains(enrollmentId)) return;
    emit(
      StudentReceivableState(
        load: s.load,
        history: h,
        toggling: {...s.toggling, enrollmentId},
      ),
    );
    try {
      final r = await _repo.setEnrollmentDunning(
        enrollmentId,
        enabled: enabled,
      );
      if (isClosed) return;
      emit(
        StudentReceivableState(
          load: s.load,
          history: (state.history ?? h).afterToggle(r),
          toggling: {...state.toggling}..remove(enrollmentId),
        ),
      );
    } on Object catch (raw) {
      final e = asApiException(raw);
      if (isClosed) return;
      emit(
        StudentReceivableState(
          load: s.load,
          history: state.history,
          toggling: {...state.toggling}..remove(enrollmentId),
          error: e,
        ),
      );
    }
  }
}
