import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/invoice_models.dart';
import '../data/invoice_repository.dart';

enum InvoiceListStatus { loading, ready, failure }

class InvoiceListState extends Equatable {
  const InvoiceListState({
    this.status = InvoiceListStatus.loading,
    this.items = const [],
    this.nextCursor,
    this.filter,
    this.loadingMore = false,
    this.moreFailed = false,
  });

  final InvoiceListStatus status;
  final List<InvoiceSummary> items;
  final String? nextCursor;

  /// `null` = mọi trạng thái (trừ nháp, do server).
  final InvoiceStatus? filter;
  final bool loadingMore;
  final bool moreFailed;

  bool get hasMore => nextCursor != null;

  @override
  List<Object?> get props => [
    status,
    items,
    nextCursor,
    filter,
    loadingMore,
    moreFailed,
  ];
}

/// P03: danh sách hóa đơn của các con, phân trang con trỏ, lọc theo trạng thái.
class InvoiceListCubit extends Cubit<InvoiceListState> {
  InvoiceListCubit(this._repo) : super(const InvoiceListState());

  final InvoiceRepository _repo;

  /// Tăng mỗi lần [load]; kết quả [loadMore] mang token cũ bị bỏ.
  int _generation = 0;

  Future<void> load({InvoiceStatus? filter, bool keepFilter = false}) async {
    final f = keepFilter ? state.filter : filter;
    final gen = ++_generation;
    emit(InvoiceListState(filter: f));
    try {
      final page = await _repo.list(status: f);
      if (isClosed || gen != _generation) return;
      emit(
        InvoiceListState(
          status: InvoiceListStatus.ready,
          items: page.items,
          nextCursor: page.nextCursor,
          filter: f,
        ),
      );
    } catch (_) {
      if (isClosed || gen != _generation) return;
      emit(InvoiceListState(status: InvoiceListStatus.failure, filter: f));
    }
  }

  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (cursor == null || state.loadingMore) return;
    final f = state.filter;
    final gen = _generation;
    emit(
      InvoiceListState(
        status: state.status,
        items: state.items,
        nextCursor: cursor,
        filter: f,
        loadingMore: true,
      ),
    );
    try {
      final page = await _repo.list(cursor: cursor, status: f);
      // Đã tải lại hoặc đổi bộ lọc trong lúc chờ: bỏ trang cũ.
      if (isClosed || gen != _generation) return;
      emit(
        InvoiceListState(
          status: state.status,
          items: [...state.items, ...page.items],
          nextCursor: page.nextCursor,
          filter: f,
        ),
      );
    } catch (_) {
      if (isClosed || gen != _generation) return;
      emit(
        InvoiceListState(
          status: state.status,
          items: state.items,
          nextCursor: cursor,
          filter: f,
          moreFailed: true,
        ),
      );
    }
  }
}
