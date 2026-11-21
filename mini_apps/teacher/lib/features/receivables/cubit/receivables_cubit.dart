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
    this.classId,
    this.query = '',
    this.ascending = false,
    this.loadingMore = false,
    this.moreFailed = false,
    this.refreshError,
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

  /// `null` = tất cả lớp.
  final String? classId;

  /// Từ khóa hiệu lực: rỗng hoặc từ 2 ký tự (ngắn hơn coi như không tìm).
  final String query;

  /// Sắp theo số nợ: mặc định giảm dần.
  final bool ascending;
  final bool loadingMore;

  /// Tải thêm lỗi: giữ danh sách, hiện nút thử lại ở cuối.
  final bool moreFailed;

  /// Làm mới lỗi: giữ danh sách, màn báo nhẹ.
  final ApiException? refreshError;

  /// Lỗi tải đầu ([load] là failure).
  final ApiException? error;

  bool get hasMore => items.length < total;

  /// Không bộ lọc nào: danh sách rỗng nghĩa là không ai còn nợ.
  bool get unfiltered => bucket == null && classId == null && query.isEmpty;

  static const _keep = Object();

  /// Các trường lỗi và cờ tải thêm luôn về mặc định nếu không truyền.
  ReceivablesState copyWith({
    BillingLoad? load,
    List<ReceivableRow>? items,
    int? page,
    int? total,
    int? totalAmount,
    List<AgingSummary>? buckets,
    Object? bucket = _keep,
    Object? classId = _keep,
    String? query,
    bool? ascending,
    bool loadingMore = false,
    bool moreFailed = false,
    ApiException? refreshError,
    ApiException? error,
  }) => ReceivablesState(
    load: load ?? this.load,
    items: items ?? this.items,
    page: page ?? this.page,
    total: total ?? this.total,
    totalAmount: totalAmount ?? this.totalAmount,
    buckets: buckets ?? this.buckets,
    bucket: identical(bucket, _keep) ? this.bucket : bucket as AgingBucket?,
    classId: identical(classId, _keep) ? this.classId : classId as String?,
    query: query ?? this.query,
    ascending: ascending ?? this.ascending,
    loadingMore: loadingMore,
    moreFailed: moreFailed,
    refreshError: refreshError,
    error: error,
  );

  @override
  List<Object?> get props => [
    load, items, page, total, totalAmount, buckets, bucket, classId, query, //
    ascending, loadingMore, moreFailed, refreshError, error,
  ];
}

/// Công nợ T11 (US-8.3 AC1–AC2): lọc theo nhóm tuổi nợ và lớp, tìm theo tên,
/// sắp theo số nợ, cuộn tải thêm. Mỗi lần tải trang 1 (đổi lọc, làm mới) tăng
/// [_seq]; phản hồi của lần cũ và `loadMore` đang bay đều bị bỏ.
class ReceivablesCubit extends Cubit<ReceivablesState> {
  ReceivablesCubit(this._repo) : super(const ReceivablesState());
  final ReceivablesRepository _repo;
  int _seq = 0;

  /// Đang tải trang 1: không cho `loadMore` chạy chen vào.
  bool _firstInFlight = false;

  /// Lần đầu, "Thử lại": hiện vòng tải, bỏ tổng cũ.
  Future<void> load() => _first(
    ReceivablesState(
      bucket: state.bucket,
      classId: state.classId,
      query: state.query,
      ascending: state.ascending,
    ),
  );

  /// Kéo để làm mới: giữ danh sách cũ tới khi có dữ liệu mới.
  Future<void> refresh() async {
    if (state.load != BillingLoad.ready) return load();
    await _first(state, keep: true);
  }

  /// Đổi bộ lọc: hiện vòng tải nhưng giữ tổng theo nhóm để thanh nhóm không nhấp nháy.
  Future<void> _refilter(ReceivablesState next) => _first(
    next.copyWith(
      load: BillingLoad.loading,
      items: const [],
      page: 1,
      total: 0,
    ),
  );

  Future<void> setBucket(AgingBucket? bucket) async {
    if (bucket == state.bucket) return;
    await _refilter(state.copyWith(bucket: bucket));
  }

  Future<void> setClass(String? classId) async {
    if (classId == state.classId) return;
    await _refilter(state.copyWith(classId: classId));
  }

  /// Chỉ gọi lại khi từ khóa hiệu lực đổi (rỗng ↔ từ 2 ký tự).
  Future<void> setQuery(String query) async {
    final t = query.trim();
    final q = t.length < receivablesQueryMin ? '' : t;
    if (q == state.query) return;
    await _refilter(state.copyWith(query: q));
  }

  Future<void> toggleSort() =>
      _refilter(state.copyWith(ascending: !state.ascending));

  Future<ReceivablePage> _fetch(int page, ReceivablesState s) => _repo.list(
    page: page,
    pageSize: receivablesPageSize,
    agingBucket: s.bucket,
    classId: s.classId,
    query: s.query.isEmpty ? null : s.query,
    ascending: s.ascending,
  );

  Future<void> _first(ReceivablesState next, {bool keep = false}) async {
    if (isClosed) return;
    final seq = ++_seq;
    _firstInFlight = true;
    if (!keep) {
      emit(next);
    } else if (state.loadingMore || state.moreFailed) {
      // `loadMore` đang bay bị bỏ: trả cờ về mặc định kẻo kẹt.
      emit(state.copyWith());
    }
    try {
      final p = await _fetch(1, next);
      if (isClosed || seq != _seq) return;
      _firstInFlight = false;
      emit(_ready(next, p, p.items));
    } on ApiException catch (e) {
      if (isClosed || seq != _seq) return;
      _firstInFlight = false;
      emit(
        keep
            // Làm mới lỗi thì giữ danh sách đang có và báo nhẹ.
            ? state.copyWith(refreshError: e)
            : next.copyWith(load: BillingLoad.failure, error: e),
      );
    }
  }

  /// Cuộn tới cuối: tải trang kế; lỗi giữ danh sách và cho thử lại. Không chạy
  /// khi đang tải trang 1.
  Future<void> loadMore() async {
    final s = state;
    if (s.load != BillingLoad.ready ||
        s.loadingMore ||
        !s.hasMore ||
        _firstInFlight) {
      return;
    }
    final seq = _seq;
    emit(s.copyWith(loadingMore: true));
    try {
      final p = await _fetch(s.page + 1, s);
      if (isClosed || seq != _seq) return;
      // Nối vào danh sách hiện tại; dòng đã có (dữ liệu dịch trang) không hiện hai lần.
      final cur = state;
      final seen = {for (final r in cur.items) r.studentId};
      emit(
        _ready(cur, p, [
          ...cur.items,
          for (final r in p.items)
            if (seen.add(r.studentId)) r,
        ]),
      );
    } on ApiException {
      if (isClosed || seq != _seq) return;
      emit(state.copyWith(moreFailed: true));
    }
  }

  ReceivablesState _ready(
    ReceivablesState s,
    ReceivablePage p,
    List<ReceivableRow> items,
  ) => s.copyWith(
    load: BillingLoad.ready,
    items: items,
    page: p.page,
    total: p.total,
    totalAmount: p.totalAmount,
    buckets: p.buckets,
  );
}
