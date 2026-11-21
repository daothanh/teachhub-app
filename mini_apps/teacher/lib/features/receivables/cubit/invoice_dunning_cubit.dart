import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../billing/cubit/billing_periods_cubit.dart' show BillingLoad;
import '../data/receivable_models.dart';
import '../data/receivables_repository.dart';

class InvoiceDunningState extends Equatable {
  const InvoiceDunningState({
    this.load = BillingLoad.loading,
    this.dunning,
    this.error,
  });

  final BillingLoad load;
  final InvoiceDunning? dunning;
  final ApiException? error;

  @override
  List<Object?> get props => [load, dunning, error];
}

/// Trạng thái nhắc của một hóa đơn (US-7.5): đã nhắc lúc nào, lần nhắc tới.
/// Lỗi chỉ ảnh hưởng khối này, không làm hỏng chi tiết hóa đơn.
class InvoiceDunningCubit extends Cubit<InvoiceDunningState> {
  InvoiceDunningCubit(this._repo, this.invoiceId)
    : super(const InvoiceDunningState());
  final ReceivablesRepository _repo;
  final String invoiceId;

  Future<void> load() async {
    if (isClosed) return;
    emit(const InvoiceDunningState());
    try {
      final d = await _repo.invoiceDunning(invoiceId);
      if (isClosed) return;
      emit(InvoiceDunningState(load: BillingLoad.ready, dunning: d));
    } on Object catch (raw) {
      final e = asApiException(raw);
      if (isClosed) return;
      emit(InvoiceDunningState(load: BillingLoad.failure, error: e));
    }
  }
}
