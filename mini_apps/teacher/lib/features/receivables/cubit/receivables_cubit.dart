import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../billing/cubit/billing_periods_cubit.dart' show BillingLoad;
import '../data/receivable_models.dart';
import '../data/receivables_repository.dart';

const receivablesPageSize = 20;

/// Hợp đồng chỉ nhận `q` từ 2 ký tự.
const receivablesQueryMin = 2;

class ReceivablesState extends Equatable {
  const ReceivablesState({
    this.load = BillingLoad.loading,
    this.items = const [],
    this.page = 1,
    this.total = 0,
    this.totalAmount = 0,
    this.buckets = const [],
    this.bucket,
    this.query = '',
    this.ascending = false,
    this.loadingMore = false,
    this.moreFailed = false,
    this.error,
  });

  final BillingLoad load;
  final List<ReceivableRow> items;

  /// Trang đã tải gần nhất.
  final int page;

  /// Số học viên khớp bộ lọc, mọi trang.
  final int total;
  final int totalAmount;
  final List<AgingSummary> buckets;

  /// `null` = tất cả nhóm.
  final AgingBucket? bucket;
  final String query;

  /// Sắp theo số nợ: mặc định giảm dần.
  final bool ascending;
  final bool loadingMore;

  /// Tải thêm lỗi: giữ danh sách, hiện nút thử lại ở cuối.
  final bool moreFailed;
  final ApiException? error;

  bool get hasMore => items.length < total;

  /// Không bộ lọc nào: danh sách rỗng nghĩa là không ai còn nợ.
  bool get unfiltered =>
      bucket == null && query.trim().length < receivablesQueryMin;

  @override
  List<Object?> get props => [
    load, items, page, total, totalAmount, buckets, bucket, query, ascending, //
    loadingMore, moreFailed, error,
  ];
}

/// Công nợ T11 (US-8.3 AC1–AC2): lọc theo nhóm tuổi nợ, tìm theo tên, sắp theo
/// số nợ, cuộn tải thêm. Phản hồi của yêu cầu cũ (đã đổi bộ lọc) bị bỏ qua.
class ReceivablesCubit extends Cubit<ReceivablesState> {
  ReceivablesCubit(this._repo) : super(const ReceivablesState());
  final ReceivablesRepository _repo;
  int _seq = 0;

  /// Lần đầu, "Thử lại" hoặc đổi bộ lọc: hiện vòng tải.
  Future<void> load() => _first(
    ReceivablesState(
      bucket: state.bucket,
      query: state.query,
      ascending: state.ascending,
    ),
  );

  /// Kéo để làm mới: giữ danh sách cũ tới khi có dữ liệu mới.
  Future<void> refresh() async {
    if (state.load != BillingLoad.ready) return load();
    await _first(state, keep: true);
  }

  Future<void> setBucket(AgingBucket? bucket) async {
    if (bucket == state.bucket) return;
    await _first(
      ReceivablesState(
        bucket: bucket,
        query: state.query,
        ascending: state.ascending,
        // Tổng theo nhóm không đổi khi lọc nhóm: giữ để thanh nhóm không nhấp nháy.
        buckets: state.buckets,
        totalAmount: state.totalAmount,
      ),
    );
  }

  Future<void> setQuery(String query) async {
    final q = query.trim();
    if (q == state.query) return;
    await _first(
      ReceivablesState(
        bucket: state.bucket,
        query: q,
        ascending: state.ascending,
        buckets: state.buckets,
        totalAmount: state.totalAmount,
      ),
    );
  }

  Future<void> toggleSort() => _first(
    ReceivablesState(
      bucket: state.bucket,
      query: state.query,
      ascending: !state.ascending,
      buckets: state.buckets,
      totalAmount: state.totalAmount,
    ),
  );

  Future<ReceivablePage> _fetch(int page, ReceivablesState s) => _repo.list(
    page: page,
    pageSize: receivablesPageSize,
    agingBucket: s.bucket,
    query: s.query.length < receivablesQueryMin ? null : s.query,
    ascending: s.ascending,
  );

  Future<void> _first(ReceivablesState next, {bool keep = false}) async {
    if (isClosed) return;
    final seq = ++_seq;
    if (!keep) emit(next);
    try {
      final p = await _fetch(1, next);
      if (isClosed || seq != _seq) return;
      emit(_ready(next, p, p.items));
    } on ApiException catch (e) {
      if (isClosed || seq != _seq) return;
      // Làm mới lỗi thì giữ danh sách đang có; chỉ lần tải đầu mới báo lỗi cả màn.
      if (keep) return;
      emit(
        ReceivablesState(
          load: BillingLoad.failure,
          bucket: next.bucket,
          query: next.query,
          ascending: next.ascending,
          error: e,
        ),
      );
    }
  }

  /// Cuộn tới cuối: tải trang kế; lỗi giữ danh sách và cho thử lại.
  Future<void> loadMore() async {
    final s = state;
    if (s.load != BillingLoad.ready || s.loadingMore || !s.hasMore) return;
    final seq = _seq;
    emit(_copy(s, loadingMore: true));
    try {
      final p = await _fetch(s.page + 1, s);
      if (isClosed || seq != _seq) return;
      // Dòng đã có (dữ liệu dịch trang) không hiện hai lần.
      final seen = {for (final r in s.items) r.studentId};
      emit(
        _ready(s, p, [
          ...s.items,
          for (final r in p.items)
            if (seen.add(r.studentId)) r,
        ]),
      );
    } on ApiException {
      if (isClosed || seq != _seq) return;
      emit(_copy(s, moreFailed: true));
    }
  }

  ReceivablesState _ready(
    ReceivablesState s,
    ReceivablePage p,
    List<ReceivableRow> items,
  ) => ReceivablesState(
    load: BillingLoad.ready,
    items: items,
    page: p.page,
    total: p.total,
    totalAmount: p.totalAmount,
    buckets: p.buckets,
    bucket: s.bucket,
    query: s.query,
    ascending: s.ascending,
  );

  ReceivablesState _copy(
    ReceivablesState s, {
    bool loadingMore = false,
    bool moreFailed = false,
  }) => ReceivablesState(
    load: s.load,
    items: s.items,
    page: s.page,
    total: s.total,
    totalAmount: s.totalAmount,
    buckets: s.buckets,
    bucket: s.bucket,
    query: s.query,
    ascending: s.ascending,
    loadingMore: loadingMore,
    moreFailed: moreFailed,
  );
}
