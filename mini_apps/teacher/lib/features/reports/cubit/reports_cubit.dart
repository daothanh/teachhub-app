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
    this.currentMonth,
    this.overview,
    this.byClass,
    this.months,
    this.loading = false,
    this.refreshError,
    this.error,
  });

  final BillingLoad load;

  /// `YYYY-MM` đang xem; `null` tới khi máy chủ trả tháng hiện tại của tenant.
  final String? month;

  /// Tháng hiện tại theo máy chủ (múi giờ tenant): mốc cuối của biểu đồ 12
  /// tháng và giới hạn của "tháng sau".
  final String? currentMonth;
  final MonthOverview? overview;
  final RevenueByClass? byClass;
  final Revenue12m? months;

  /// Đang đổi tháng hoặc làm mới trên số liệu đã có (spinner nhỏ, giữ khung).
  final bool loading;

  /// Đổi tháng/làm mới lỗi: giữ số liệu đang có, màn báo nhẹ.
  final ApiException? refreshError;

  /// Lỗi tải đầu ([load] là failure).
  final ApiException? error;

  ReportsState copyWith({
    BillingLoad? load,
    String? month,
    String? currentMonth,
    MonthOverview? overview,
    RevenueByClass? byClass,
    Revenue12m? months,
    bool loading = false,
    ApiException? refreshError,
    ApiException? error,
  }) => ReportsState(
    load: load ?? this.load,
    month: month ?? this.month,
    currentMonth: currentMonth ?? this.currentMonth,
    overview: overview ?? this.overview,
    byClass: byClass ?? this.byClass,
    months: months ?? this.months,
    loading: loading,
    refreshError: refreshError,
    error: error,
  );

  @override
  List<Object?> get props => [
    load, month, currentMonth, overview, byClass, months, loading, //
    refreshError, error,
  ];
}

/// T12/T12a (US-8.1, US-8.2): tổng quan, doanh thu theo lớp và biểu đồ 12 tháng.
/// Lần đầu gọi cả ba không kèm tháng (máy chủ trả tháng hiện tại của tenant);
/// biểu đồ chỉ gọi lúc đó và khi làm mới, đổi tháng chỉ gọi lại tổng quan và
/// theo lớp nên cột không trượt. Một lệnh lỗi là lỗi cả khối (số các khối phải
/// khớp nhau, US-8.2 AC3). Phản hồi của lần gọi cũ bị bỏ ([_seq]).
class ReportsCubit extends Cubit<ReportsState> {
  ReportsCubit(this._repo) : super(const ReportsState());
  final ReportsRepository _repo;
  int _seq = 0;

  /// Còn tháng sau để chuyển tới (không quá tháng hiện tại của máy chủ).
  bool get canGoNext {
    final m = state.month;
    final cur = state.currentMonth;
    return m != null && cur != null && m.compareTo(cur) < 0;
  }

  /// Lần đầu hoặc "Thử lại": hiện vòng tải toàn màn.
  Future<void> load() async {
    if (isClosed) return;
    final seq = ++_seq;
    emit(const ReportsState());
    try {
      final r = await Future.wait<Object>([
        _repo.monthOverview(),
        _repo.revenueByClass(),
        _repo.revenue12m(),
      ]);
      if (isClosed || seq != _seq) return;
      final o = r[0] as MonthOverview;
      emit(
        ReportsState(
          load: BillingLoad.ready,
          month: o.month,
          currentMonth: o.month,
          overview: o,
          byClass: r[1] as RevenueByClass,
          months: r[2] as Revenue12m,
        ),
      );
    } on Object catch (raw) {
      if (isClosed || seq != _seq) return;
      emit(ReportsState(load: BillingLoad.failure, error: asApiException(raw)));
    }
  }

  /// Kéo để làm mới: giữ số liệu cũ tới khi có số mới.
  Future<void> refresh() async {
    if (state.load != BillingLoad.ready) return load();
    final seq = ++_seq;
    emit(state.copyWith(loading: true));
    try {
      // Mốc biểu đồ lấy lại để qua tháng mới thì cột cuối cập nhật.
      final r = await Future.wait<Object>([
        _repo.monthOverview(month: state.month),
        _repo.revenueByClass(month: state.month),
        _repo.revenue12m(),
        _repo.monthOverview(),
      ]);
      if (isClosed || seq != _seq) return;
      emit(
        state.copyWith(
          overview: r[0] as MonthOverview,
          byClass: r[1] as RevenueByClass,
          months: r[2] as Revenue12m,
          currentMonth: (r[3] as MonthOverview).month,
        ),
      );
    } on Object catch (raw) {
      if (isClosed || seq != _seq) return;
      emit(state.copyWith(refreshError: asApiException(raw)));
    }
  }

  /// Đổi tháng xem: giữ khung và biểu đồ, lỗi thì ở lại tháng cũ và báo nhẹ.
  Future<void> selectMonth(String month) async {
    if (month == state.month || state.load != BillingLoad.ready) return;
    final seq = ++_seq;
    emit(state.copyWith(loading: true));
    try {
      final r = await Future.wait<Object>([
        _repo.monthOverview(month: month),
        _repo.revenueByClass(month: month),
      ]);
      if (isClosed || seq != _seq) return;
      final o = r[0] as MonthOverview;
      emit(
        state.copyWith(
          month: o.month,
          overview: o,
          byClass: r[1] as RevenueByClass,
        ),
      );
    } on Object catch (raw) {
      if (isClosed || seq != _seq) return;
      emit(state.copyWith(refreshError: asApiException(raw)));
    }
  }

  Future<void> previous() => selectMonth(shiftMonth(state.month!, -1));

  Future<void> next() async {
    if (canGoNext) await selectMonth(shiftMonth(state.month!, 1));
  }
}
