import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../data/billing_models.dart';
import '../data/billing_repository.dart';

enum BillingLoad { loading, ready, failure }

class BillingPeriodsState extends Equatable {
  const BillingPeriodsState({
    this.load = BillingLoad.loading,
    this.periods = const [],
    this.error,
  });

  final BillingLoad load;
  final List<BillingPeriod> periods;
  final ApiException? error;

  @override
  List<Object?> get props => [load, periods, error];
}

/// Danh sách kỳ thu (T10, US-7.2 AC1).
class BillingPeriodsCubit extends Cubit<BillingPeriodsState> {
  BillingPeriodsCubit(this._repo) : super(const BillingPeriodsState());
  final BillingRepository _repo;

  /// Phản hồi của lần gọi cũ bị bỏ.
  int _seq = 0;

  /// Lần đầu và "Thử lại": hiện vòng tải.
  Future<void> load() async {
    if (isClosed) return;
    emit(const BillingPeriodsState());
    await _fetch();
  }

  /// Kéo để làm mới hoặc quay lại màn: giữ danh sách cũ tới khi có dữ liệu mới.
  Future<void> refresh() async {
    if (isClosed) return;
    if (state.load != BillingLoad.ready) return load();
    await _fetch();
  }

  Future<void> _fetch() async {
    final seq = ++_seq;
    try {
      final items = await _repo.listPeriods();
      if (isClosed || seq != _seq) return;
      emit(BillingPeriodsState(load: BillingLoad.ready, periods: items));
    } on ApiException catch (e) {
      if (isClosed || seq != _seq) return;
      // Làm mới lỗi thì giữ danh sách đang có; chỉ lần tải đầu mới báo lỗi cả màn.
      if (state.load == BillingLoad.ready) return;
      emit(BillingPeriodsState(load: BillingLoad.failure, error: e));
    }
  }
}
