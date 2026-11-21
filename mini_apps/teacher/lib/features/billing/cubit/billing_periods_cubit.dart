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

  Future<void> load() async {
    emit(const BillingPeriodsState());
    try {
      final items = await _repo.listPeriods();
      if (isClosed) return;
      emit(BillingPeriodsState(load: BillingLoad.ready, periods: items));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(BillingPeriodsState(load: BillingLoad.failure, error: e));
    }
  }
}
