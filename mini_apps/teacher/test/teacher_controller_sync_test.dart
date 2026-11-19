import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:tasco_storage/tasco_storage.dart';
import 'package:teacher/data/local_db/teacher_database.dart';
import 'package:teacher/teacher_controller.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'support/fake_teachhub_server.dart';

void main() {
  late TeacherController controller;

  setUp(() {
    controller = TeacherController.instance
      ..keyStoreOverride = InMemoryKeyValueStore()
      ..enginesCreated = 0;
    GetIt.I
      ..registerLazySingletonAsync<TeacherDatabase>(
        () async => TeacherDatabase(NativeDatabase.memory()),
        instanceName: TeacherController.databaseKey,
      )
      ..registerSingleton<Dio>(
        FakeTeachHubServer().dio(),
        instanceName: TeachHubDiKey.api,
      );
  });
  tearDown(() async {
    await controller.stopSync();
    await GetIt.I.reset();
  });

  test('startSync gọi chồng nhau chỉ dựng một engine', () async {
    await Future.wait([
      controller.startSync(),
      controller.startSync(),
      controller.startSync(),
    ]);
    expect(controller.enginesCreated, 1);
    expect(controller.syncEngine, isNotNull);
    await controller.startSync(); // đã chạy: không dựng thêm
    expect(controller.enginesCreated, 1);
  });

  test(
    'stopSync trong lúc startSync đang dựng: không để engine mồ côi',
    () async {
      final starting = controller.startSync();
      await controller.stopSync();
      await starting;
      expect(controller.syncEngine, isNull);
    },
  );
}
