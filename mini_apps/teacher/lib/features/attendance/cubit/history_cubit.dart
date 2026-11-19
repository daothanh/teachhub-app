import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../data/attendance_models.dart';
import '../data/attendance_repository.dart';

enum HistoryLoad { loading, ready, failure }

class HistoryState extends Equatable {
  const HistoryState({
    this.load = HistoryLoad.loading,
    this.items = const [],
    this.nextCursor,
    this.loadingMore = false,
    this.loadMoreFailed = false,
    this.error,
  });

  final HistoryLoad load;
  final List<HistoryItem> items;
  final String? nextCursor;
  final bool loadingMore;
  final bool loadMoreFailed;
  final ApiException? error;

  @override
  List<Object?> get props => [
    load,
    items,
    nextCursor,
    loadingMore,
    loadMoreFailed,
    error,
  ];
}

/// Nhật ký sửa điểm danh của một buổi (US-3.3 AC2), mới nhất trước.
class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit(this._repo, this.sessionId) : super(const HistoryState());

  final AttendanceRepository _repo;
  final String sessionId;
  int _gen = 0;

  Future<void> load() async {
    final gen = ++_gen;
    emit(const HistoryState());
    try {
      final page = await _repo.history(sessionId);
      if (isClosed || gen != _gen) return;
      emit(
        HistoryState(
          load: HistoryLoad.ready,
          items: page.items,
          nextCursor: page.nextCursor,
        ),
      );
    } on ApiException catch (e) {
      if (isClosed || gen != _gen) return;
      emit(HistoryState(load: HistoryLoad.failure, error: e));
    }
  }

  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (cursor == null || state.loadingMore) return;
    final gen = _gen;
    emit(
      HistoryState(
        load: HistoryLoad.ready,
        items: state.items,
        nextCursor: cursor,
        loadingMore: true,
      ),
    );
    try {
      final page = await _repo.history(sessionId, cursor: cursor);
      if (isClosed || gen != _gen) return;
      emit(
        HistoryState(
          load: HistoryLoad.ready,
          items: [...state.items, ...page.items],
          nextCursor: page.nextCursor,
        ),
      );
    } on ApiException {
      if (isClosed || gen != _gen) return;
      emit(
        HistoryState(
          load: HistoryLoad.ready,
          items: state.items,
          nextCursor: cursor,
          loadMoreFailed: true,
        ),
      );
    }
  }
}
