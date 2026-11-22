import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../data/class_models.dart';
import '../data/classes_repository.dart';

enum ClassesLoad { loading, ready, failure }

class ClassesListState extends Equatable {
  const ClassesListState({
    this.load = ClassesLoad.loading,
    this.archived = false,
    this.items = const [],
    this.page = 0,
    this.hasMore = false,
    this.loadingMore = false,
    this.loadMoreFailed = false,
    this.error,
  });

  final ClassesLoad load;

  /// `false` = lớp đang dạy (mặc định), `true` = lớp đã lưu trữ.
  final bool archived;
  final List<TeachClass> items;
  final int page;
  final bool hasMore;
  final bool loadingMore;

  /// Tải trang tiếp lỗi: không tự gọi lại, chờ người dùng bấm Thử lại.
  final bool loadMoreFailed;
  final ApiException? error;

  ClassesListState copyWith({
    ClassesLoad? load,
    bool? archived,
    List<TeachClass>? items,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    bool? loadMoreFailed,
    ApiException? error,
  }) => ClassesListState(
    load: load ?? this.load,
    archived: archived ?? this.archived,
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    error: error,
  );

  @override
  List<Object?> get props => [
    load, archived, items, page, hasMore, loadingMore, loadMoreFailed, error, //
  ];
}

/// Danh sách lớp (T06). Mặc định chỉ lớp đang dạy; lớp lưu trữ ở tab riêng.
class ClassesListCubit extends Cubit<ClassesListState> {
  ClassesListCubit(this._repo) : super(const ClassesListState());
  final ClassesRepository _repo;

  /// Thế hệ yêu cầu: đổi tab hoặc tải lại làm kết quả cũ (kể cả loadMore) bị bỏ.
  int _gen = 0;

  ClassStatus _status(bool archived) =>
      archived ? ClassStatus.archived : ClassStatus.active;

  Future<void> load({bool? archived}) async {
    final arch = archived ?? state.archived;
    final gen = ++_gen;
    emit(ClassesListState(archived: arch));
    try {
      final p = await _repo.list(status: _status(arch));
      if (isClosed || gen != _gen) return;
      emit(
        ClassesListState(
          load: ClassesLoad.ready,
          archived: arch,
          items: p.items,
          page: p.page,
          hasMore: p.hasMore,
        ),
      );
    } on ApiException catch (e) {
      if (isClosed || gen != _gen) return;
      emit(
        ClassesListState(load: ClassesLoad.failure, archived: arch, error: e),
      );
    }
  }

  /// Tải lại trang đầu mà không xóa danh sách đang hiện (sau khi quay về từ
  /// chi tiết/form). Lỗi thì giữ nguyên.
  Future<void> refresh() async {
    if (state.load != ClassesLoad.ready) return load();
    final gen = ++_gen;
    try {
      final p = await _repo.list(status: _status(state.archived));
      if (isClosed || gen != _gen) return;
      emit(
        ClassesListState(
          load: ClassesLoad.ready,
          archived: state.archived,
          items: p.items,
          page: p.page,
          hasMore: p.hasMore,
        ),
      );
    } on ApiException {
      // Giữ danh sách cũ. loadMore đang bay đã bị bỏ (gen đổi) nên tự gỡ cờ
      // của nó, không thì kẹt "đang tải thêm" mãi.
      if (isClosed || gen != _gen || !state.loadingMore) return;
      emit(state.copyWith(loadingMore: false));
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore || state.loadMoreFailed) return;
    final gen = _gen;
    emit(state.copyWith(loadingMore: true));
    try {
      final p = await _repo.list(
        status: _status(state.archived),
        page: state.page + 1,
      );
      if (isClosed || gen != _gen) return;
      emit(
        state.copyWith(
          items: [...state.items, ...p.items],
          page: p.page,
          hasMore: p.hasMore,
          loadingMore: false,
        ),
      );
    } on ApiException {
      if (isClosed || gen != _gen) return;
      emit(state.copyWith(loadingMore: false, loadMoreFailed: true));
    }
  }

  /// Người dùng bấm Thử lại ở ô cuối danh sách.
  Future<void> retryLoadMore() {
    emit(state.copyWith(loadMoreFailed: false));
    return loadMore();
  }
}
