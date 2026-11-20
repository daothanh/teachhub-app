import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/features/classes/cubit/classes_list_cubit.dart';
import 'package:teacher/features/classes/data/class_models.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'fake_classes_repository.dart';

void main() {
  test(
    'loadMore lỗi: đặt cờ, không tự gọi lại; retryLoadMore mới gọi',
    () async {
      final repo = FakeClassesRepository()
        ..active = [sampleClass()]
        ..listTotal = 40
        ..listErrorPage = 2;
      final cubit = ClassesListCubit(repo);
      await cubit.load();
      await cubit.loadMore();
      expect(cubit.state.loadMoreFailed, isTrue);
      expect(cubit.state.loadingMore, isFalse);

      await cubit.loadMore();
      await cubit.loadMore();
      expect(repo.calls.where((c) => c == 'list:active:2'), hasLength(1));

      repo.listErrorPage = null;
      await cubit.retryLoadMore();
      expect(cubit.state.loadMoreFailed, isFalse);
      expect(cubit.state.items, hasLength(2));
      expect(repo.calls.where((c) => c == 'list:active:2'), hasLength(2));
      await cubit.close();
    },
  );

  test('load lỗi rồi đóng cubit: không emit sau close', () async {
    final repo = FakeClassesRepository()
      ..listError = const ApiException.network()
      ..listGate = Completer<void>();
    final cubit = ClassesListCubit(repo);
    final f = cubit.load();
    await cubit.close();
    repo.listGate!.complete();
    await f;
  });

  test('đổi tab khi loadMore đang bay: kết quả cũ bị bỏ', () async {
    final repo = FakeClassesRepository()
      ..active = [sampleClass()]
      ..archived = [
        sampleClass(id: 'a1', name: 'Cũ', status: ClassStatus.archived),
      ]
      ..listTotal = 40;
    final cubit = ClassesListCubit(repo);
    await cubit.load();
    repo.listGate = Completer<void>();
    final more = cubit.loadMore(); // trang 2 của tab active, đang chờ
    final gate = repo.listGate!;
    repo.listGate = null;
    await cubit.load(archived: true);
    gate.complete();
    await more;

    expect(cubit.state.archived, isTrue);
    expect(cubit.state.items.map((c) => c.id), ['a1']);
    await cubit.close();
  });

  test('refresh giữ danh sách cũ khi lỗi và thay khi thành công', () async {
    final repo = FakeClassesRepository()..active = [sampleClass()];
    final cubit = ClassesListCubit(repo);
    await cubit.load();
    repo.listError = const ApiException.network();
    await cubit.refresh();
    expect(cubit.state.items, hasLength(1));
    expect(cubit.state.load, ClassesLoad.ready);

    repo
      ..listError = null
      ..active = [sampleClass(), sampleClass(id: 'c2')];
    await cubit.refresh();
    expect(cubit.state.items, hasLength(2));
    await cubit.close();
  });
}
