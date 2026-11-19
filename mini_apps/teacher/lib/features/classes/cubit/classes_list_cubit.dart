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
    this.error,
  });

  final ClassesLoad load;

  /// `false` = lớp đang dạy (mặc định), `true` = lớp đã lưu trữ.
  final bool archived;
  final List<TeachClass> items;
  final int page;
  final bool hasMore;
  final bool loadingMore;
  final ApiException? error;

  ClassesListState copyWith({
    ClassesLoad? load,
    bool? archived,
    List<TeachClass>? items,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    ApiException? error,
  }) => ClassesListState(
    load: load ?? this.load,
    archived: archived ?? this.archived,
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    error: error,
  );

  @override
  List<Object?> get props => [
    load, archived, items, page, hasMore, loadingMore, error, //
  ];
}

/// Danh sách lớp (T06). Mặc định chỉ lớp đang dạy; lớp lưu trữ ở tab riêng.
class ClassesListCubit extends Cubit<ClassesListState> {
  ClassesListCubit(this._repo) : super(const ClassesListState());
  final ClassesRepository _repo;

  Future<void> load({bool? archived}) async {
    final arch = archived ?? state.archived;
    emit(ClassesListState(archived: arch));
    try {
      final p = await _repo.list(
        status: arch ? ClassStatus.archived : ClassStatus.active,
      );
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
      emit(
        ClassesListState(load: ClassesLoad.failure, archived: arch, error: e),
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore) return;
    emit(state.copyWith(loadingMore: true));
    try {
      final p = await _repo.list(
        status: state.archived ? ClassStatus.archived : ClassStatus.active,
        page: state.page + 1,
      );
      emit(
        state.copyWith(
          items: [...state.items, ...p.items],
          page: p.page,
          hasMore: p.hasMore,
          loadingMore: false,
        ),
      );
    } on ApiException {
      // Giữ danh sách đã có; người dùng kéo xuống thử lại.
      emit(state.copyWith(loadingMore: false));
    }
  }
}
