import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../billing/cubit/billing_periods_cubit.dart' show BillingLoad;
import '../../receivables/data/receivables_repository.dart' show asApiException;
import '../data/report_models.dart';
import '../data/reports_repository.dart';

const reportPaymentsPageSize = 20;

class ReportPaymentsState extends Equatable {
  const ReportPaymentsState({
    this.load = BillingLoad.loading,
    this.items = const [],
    this.page = 1,
    this.total = 0,
    this.totalAmount = 0,
    this.loadingMore = false,
    this.moreFailed = false,
    this.exhausted = false,
    this.refreshError,
    this.error,
  });

  final BillingLoad load;
  final List<RevenueEntry> items;
  final int page;
  final int total;

  /// Σ mọi dòng của tháng (không chỉ trang đã tải).
  final int totalAmount;
  final bool loadingMore;

  /// Tải thêm lỗi: giữ danh sách, hiện nút thử lại ở cuối.
  final bool moreFailed;

  /// Trang kế rỗng hoặc không thêm dòng mới: dừng tải dù `total` còn lớn hơn.
  final bool exhausted;
  final ApiException? refreshError;
  final ApiException? error;

  bool get hasMore => !exhausted && items.length < total;

  @override
  List<Object?> get props => [
    load,
    items,
    page,
    total,
    totalAmount,
    loadingMore,
    moreFailed,
    exhausted, //
    refreshError, error,
  ];
}

/// Danh sách khoản thu của ô "Đã thu" (US-8.1 AC3): sổ doanh thu của [month],
/// mới nhất trước, cuộn tải thêm.
class ReportPaymentsCubit extends Cubit<ReportPaymentsState> {
  ReportPaymentsCubit(this._repo, {required this.month})
    : super(const ReportPaymentsState());
  final ReportsRepository _repo;

  /// `YYYY-MM` cụ thể, gửi ở mọi trang để các trang cùng một tháng.
  final String month;
  int _seq = 0;

  Future<void> load() => _first(const ReportPaymentsState(), keep: false);

  Future<void> refresh() async {
    if (state.load != BillingLoad.ready) return load();
    await _first(state, keep: true);
  }

  Future<void> _first(ReportPaymentsState next, {required bool keep}) async {
    if (isClosed) return;
    final seq = ++_seq;
    if (!keep) {
      emit(next);
    } else {
      // Xóa lỗi cũ để lỗi lặp lại vẫn báo; bỏ `loadMore` đang bay.
      emit(_copy(state));
    }
    try {
      final p = await _repo.payments(
        month: month,
        pageSize: reportPaymentsPageSize,
      );
      if (isClosed || seq != _seq) return;
      emit(_ready(p, p.items));
    } on Object catch (raw) {
      final e = asApiException(raw);
      if (isClosed || seq != _seq) return;
      emit(
        keep
            ? _copy(state, refreshError: e)
            : ReportPaymentsState(load: BillingLoad.failure, error: e),
      );
    }
  }

  Future<void> loadMore() async {
    final s = state;
    if (s.load != BillingLoad.ready || s.loadingMore || !s.hasMore) return;
    final seq = _seq;
    emit(_copy(s, loadingMore: true));
    try {
      final p = await _repo.payments(
        month: month,
        page: s.page + 1,
        pageSize: reportPaymentsPageSize,
      );
      if (isClosed || seq != _seq) return;
      // Dòng đã có (dữ liệu dịch trang) không hiện hai lần.
      final seen = {for (final r in state.items) r.id};
      final fresh = [
        for (final r in p.items)
          if (seen.add(r.id)) r,
      ];
      final next = _ready(p, [...state.items, ...fresh]);
      emit(
        fresh.isEmpty
            ? ReportPaymentsState(
                load: next.load,
                items: next.items,
                page: next.page,
                total: next.total,
                totalAmount: next.totalAmount,
                exhausted: true,
              )
            : next,
      );
    } on Object {
      if (isClosed || seq != _seq) return;
      emit(_copy(state, moreFailed: true));
    }
  }

  ReportPaymentsState _ready(RevenueEntryPage p, List<RevenueEntry> items) =>
      ReportPaymentsState(
        load: BillingLoad.ready,
        items: items,
        page: p.page,
        total: p.total,
        totalAmount: p.totalAmount,
      );

  /// Sao chép giữ dữ liệu, cờ tải thêm/lỗi về mặc định nếu không truyền.
  ReportPaymentsState _copy(
    ReportPaymentsState s, {
    bool loadingMore = false,
    bool moreFailed = false,
    ApiException? refreshError,
  }) => ReportPaymentsState(
    load: s.load,
    items: s.items,
    page: s.page,
    total: s.total,
    totalAmount: s.totalAmount,
    loadingMore: loadingMore,
    moreFailed: moreFailed,
    exhausted: s.exhausted,
    refreshError: refreshError,
  );
}
