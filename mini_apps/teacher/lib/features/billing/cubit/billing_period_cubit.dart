import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../classes/data/draft_keys.dart';
import '../data/billing_models.dart';
import '../data/billing_repository.dart';
import 'billing_periods_cubit.dart';

class BillingPeriodState extends Equatable {
  const BillingPeriodState({
    this.load = BillingLoad.loading,
    this.detail,
    this.issuing = false,
    this.error,
    this.result,
    this.staleUnverified = false,
  });

  final BillingLoad load;
  final BillingPeriodDetail? detail;

  /// Đang gửi lệnh chốt: chặn bấm lặp.
  final bool issuing;

  /// Lỗi tải ([load] là failure) hoặc lỗi của lệnh chốt.
  final ApiException? error;

  /// Kết quả lệnh chốt vừa xong (một lần, để hiện thông báo).
  final IssueResult? result;

  /// 409 `CONFLICT_STALE` mà tải lại kỳ cũng lỗi: chưa biết trạng thái mới.
  final bool staleUnverified;

  BillingPeriodState copyWith({
    BillingLoad? load,
    BillingPeriodDetail? detail,
    bool? issuing,
    ApiException? error,
    IssueResult? result,
    bool staleUnverified = false,
  }) => BillingPeriodState(
    load: load ?? this.load,
    detail: detail ?? this.detail,
    issuing: issuing ?? this.issuing,
    error: error,
    result: result,
    staleUnverified: staleUnverified,
  );

  @override
  List<Object?> get props => [
    load, detail, issuing, error, result, staleUnverified, //
  ];
}

/// Một kỳ thu: bản nháp của kỳ và lệnh "Chốt & gửi" (US-7.2 AC4).
class BillingPeriodCubit extends Cubit<BillingPeriodState> {
  BillingPeriodCubit(this._repo, this.periodId, {DraftKeys? keys})
    : _keys = keys ?? DraftKeys(),
      super(const BillingPeriodState());
  final BillingRepository _repo;
  final String periodId;
  final DraftKeys _keys;

  /// Phản hồi GET của lần gọi cũ bị bỏ: làm mới về muộn không ghi đè dữ liệu
  /// sau khi chốt.
  int _seq = 0;

  /// Lần đầu và "Thử lại": hiện vòng tải.
  Future<void> load() async {
    if (isClosed) return;
    final seq = ++_seq;
    emit(const BillingPeriodState());
    try {
      final d = await _repo.getPeriod(periodId);
      if (isClosed || seq != _seq) return;
      emit(BillingPeriodState(load: BillingLoad.ready, detail: d));
    } on ApiException catch (e) {
      if (isClosed || seq != _seq) return;
      emit(BillingPeriodState(load: BillingLoad.failure, error: e));
    }
  }

  /// Kéo để làm mới hoặc quay lại màn: giữ danh sách và cờ `issuing`, chỉ thay
  /// dữ liệu khi xong. Lỗi làm mới báo bằng [BillingPeriodState.error].
  Future<void> refresh() async {
    if (isClosed) return;
    if (state.load != BillingLoad.ready) return load();
    final seq = ++_seq;
    try {
      final d = await _repo.getPeriod(periodId);
      if (isClosed || seq != _seq) return;
      emit(state.copyWith(detail: d));
    } on ApiException catch (e) {
      if (isClosed || seq != _seq) return;
      emit(state.copyWith(error: e));
    }
  }

  /// "Chốt & gửi tất cả" bản nháp có tiền của kỳ.
  Future<void> issueAll() => _issue(null);

  /// Chốt từng hóa đơn.
  Future<void> issueOne(String invoiceId) => _issue([invoiceId]);

  /// Xóa lỗi đã hiện (vd. sau khi quay lại từ màn tài khoản nhận tiền).
  void clearError() {
    if (!isClosed && state.error != null && state.load == BillingLoad.ready) {
      emit(state.copyWith());
    }
  }

  Future<void> _issue(List<String>? ids) async {
    if (state.issuing || state.load != BillingLoad.ready) return;
    emit(state.copyWith(issuing: true));
    // GET làm mới đang bay mang dữ liệu trước khi chốt: bỏ.
    var seq = ++_seq;
    // Cùng tập hóa đơn thì cùng khóa: thử lại sau lỗi mạng không phát hành hai lần.
    final draft = ids == null ? '*' : (ids.toList()..sort()).join(',');
    final IssueResult result;
    try {
      result = await _repo.issue(
        periodId,
        invoiceIds: ids,
        idempotencyKey: _keys.of('issue', draft),
      );
      _keys.done('issue');
    } on ApiException catch (e) {
      if (!e.retryable) _keys.done('issue');
      if (isClosed) return;
      if (e.code == ApiErrorCode.conflictStale) {
        // Kết quả đã lưu quá hạn phát lại: tải lại kỳ, không tự gửi lại; lần
        // bấm sau dùng khóa mới (đã `done` ở trên).
        BillingPeriodDetail? fresh;
        try {
          fresh = await _repo.getPeriod(periodId);
        } on ApiException {
          // Giữ danh sách cũ; kéo để làm mới sẽ tải lại.
        }
        if (isClosed) return;
        emit(
          state.copyWith(
            issuing: false,
            // Có lần làm mới mới hơn thì để nó thay dữ liệu.
            detail: seq == _seq ? fresh : null,
            error: e,
            staleUnverified: fresh == null,
          ),
        );
        return;
      }
      emit(state.copyWith(issuing: false, error: e));
      return;
    }
    if (isClosed) return;
    // Lệnh đã thành công: tải lại lỗi thì giữ danh sách cũ, không báo như chốt lỗi.
    emit(state.copyWith(issuing: false, result: result));
    seq = ++_seq;
    try {
      final d = await _repo.getPeriod(periodId);
      if (isClosed || seq != _seq) return;
      emit(state.copyWith(detail: d));
    } on ApiException {
      // Kéo để làm mới sẽ tải lại.
    }
  }
}
