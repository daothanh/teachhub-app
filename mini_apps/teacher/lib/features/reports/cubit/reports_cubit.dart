import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../billing/cubit/billing_periods_cubit.dart' show BillingLoad;
import '../../receivables/data/receivables_repository.dart' show asApiException;
import '../data/report_models.dart';
import '../data/reports_repository.dart';

class ReportsState extends Equatable {
  const ReportsState({
    this.load = BillingLoad.loading,
    this.month,
    this.overview,
    this.byClass,
    this.months,
    this.refreshError,
    this.error,
  });

  final BillingLoad load;

  /// `YYYY-MM` đang xem; `null` tới khi máy chủ trả tháng hiện tại của tenant.
  final String? month;
  final MonthOverview? overview;
  final RevenueByClass? byClass;
  final Revenue12m? months;

  /// Làm mới lỗi: giữ số liệu đang có, màn báo nhẹ.
  final ApiException? refreshError;

  /// Lỗi tải đầu ([load] là failure).
  final ApiException? error;

  @override
  List<Object?> get props => [
    load, month, overview, byClass, months, refreshError, error, //
  ];
}

/// T12/T12a (US-8.1, US-8.2): tổng quan, doanh thu theo lớp và biểu đồ 12 tháng
/// của một tháng. Ba lệnh gọi chạy song song; một lệnh lỗi là lỗi cả màn (số
/// các khối phải khớp nhau, US-8.2 AC3). Phản hồi của lần gọi cũ bị bỏ ([_seq]).
class ReportsCubit extends Cubit<ReportsState> {
  ReportsCubit(this._repo, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(const ReportsState());
  final ReportsRepository _repo;
  final DateTime Function() _now;
  int _seq = 0;

  String get currentMonth {
    final n = _now();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}';
  }

  /// Còn tháng sau để chuyển tới (không đi quá tháng hiện tại của máy).
  bool get canGoNext {
    final m = state.month;
    return m != null && m.compareTo(currentMonth) < 0;
  }

  /// Lần đầu, "Thử lại", đổi tháng: hiện vòng tải.
  Future<void> load({String? month}) =>
      _fetch(ReportsState(month: month ?? state.month), keep: false);

  /// Kéo để làm mới: giữ số liệu cũ tới khi có số mới.
  Future<void> refresh() async {
    if (state.load != BillingLoad.ready) return load();
    await _fetch(state, keep: true);
  }

  Future<void> selectMonth(String month) async {
    if (month == state.month) return;
    await load(month: month);
  }

  Future<void> previous() => selectMonth(shiftMonth(state.month!, -1));

  Future<void> next() async {
    if (canGoNext) await selectMonth(shiftMonth(state.month!, 1));
  }

  Future<void> _fetch(ReportsState next, {required bool keep}) async {
    if (isClosed) return;
    final seq = ++_seq;
    if (!keep) emit(next);
    final month = next.month;
    try {
      final r = await Future.wait<Object>([
        _repo.monthOverview(month: month),
        _repo.revenueByClass(month: month),
        _repo.revenue12m(month: month),
      ]);
      final overview = r[0] as MonthOverview;
      if (isClosed || seq != _seq) return;
      emit(
        ReportsState(
          load: BillingLoad.ready,
          month: overview.month,
          overview: overview,
          byClass: r[1] as RevenueByClass,
          months: r[2] as Revenue12m,
        ),
      );
    } on Object catch (raw) {
      final e = asApiException(raw);
      if (isClosed || seq != _seq) return;
      emit(
        keep
            ? ReportsState(
                load: state.load,
                month: state.month,
                overview: state.overview,
                byClass: state.byClass,
                months: state.months,
                refreshError: e,
              )
            : ReportsState(load: BillingLoad.failure, month: month, error: e),
      );
    }
  }
}
