import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:tasco_storage/tasco_storage.dart';
import 'package:teacher/data/local_db/teacher_database.dart';
import 'package:teacher/teacher_controller.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'package:teacher/data/sync/background_sync.dart';
import 'package:teacher/data/sync/enqueue_attendance.dart';

import 'support/fake_teachhub_server.dart';

void main() {
  late TeacherController controller;
  late FakeTeachHubServer server;

  setUp(() {
    server = FakeTeachHubServer();
    controller = TeacherController.instance
      ..keyStoreOverride = InMemoryKeyValueStore()
      ..enginesCreated = 0;
    GetIt.I
      ..registerLazySingletonAsync<TeacherDatabase>(
        () async => TeacherDatabase(NativeDatabase.memory()),
        instanceName: TeacherController.databaseKey,
      )
      ..registerSingleton<Dio>(server.dio(), instanceName: TeachHubDiKey.api);
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

  test(
    'wipeLocalData: dừng đồng bộ trước khi xóa, sau đó không còn engine',
    () async {
      final tmp = await Directory.systemTemp.createTemp('wipe');
      addTearDown(() => tmp.delete(recursive: true));
      controller.documentsDirectory = () async => tmp;
      await controller.startSync();
      expect(controller.syncEngine, isNotNull);

      await controller.wipeLocalData();

      expect(controller.syncEngine, isNull);
      // Chỉ màn chính bật lại engine: xóa xong không được tự dựng.
      expect(controller.enginesCreated, 1);
    },
  );

  test(
    'hẹn đồng bộ nền khi outbox có mutation, hủy khi hết và khi xóa',
    () async {
      final calls = <String>[];
      controller.backgroundSync = BackgroundSyncHooks(
        schedule: () async => calls.add('schedule'),
        cancel: () async => calls.add('cancel'),
      );
      addTearDown(() => controller.backgroundSync = null);
      final db = await GetIt.I.getAsync<TeacherDatabase>(
        instanceName: TeacherController.databaseKey,
      );
      server.offline = true; // giữ mutation trong outbox
      await controller.startSync();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(calls, ['cancel']); // outbox trống ban đầu

      await enqueueAttendance(
        db,
        sessionId: '10000000-0000-4000-8000-000000000001',
        studentId: '20000000-0000-4000-8000-000000000001',
        status: 'absent',
        clientUpdatedAt: DateTime.utc(2026, 11, 18, 9),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(calls.last, 'schedule');

      final tmp = await Directory.systemTemp.createTemp('wipe');
      addTearDown(() => tmp.delete(recursive: true));
      controller.documentsDirectory = () async => tmp;
      calls.clear();
      await controller.wipeLocalData();
      expect(calls, contains('cancel'));
    },
  );

  test('rescheduleBackgroundIfPending: chỉ hẹn khi outbox còn dòng', () async {
    final calls = <String>[];
    controller.backgroundSync = BackgroundSyncHooks(
      schedule: () async => calls.add('schedule'),
      cancel: () async => calls.add('cancel'),
    );
    addTearDown(() => controller.backgroundSync = null);
    final tmp = await Directory.systemTemp.createTemp('resched');
    addTearDown(() => tmp.delete(recursive: true));
    controller.documentsDirectory = () async => tmp;
    // Chưa có file CSDL → 0 dòng.
    await controller.rescheduleBackgroundIfPending();
    expect(calls, isEmpty);

    final db = await GetIt.I.getAsync<TeacherDatabase>(
      instanceName: TeacherController.databaseKey,
    );
    File('${tmp.path}/$teacherDatabaseFile').writeAsStringSync('x');
    await enqueueAttendance(
      db,
      sessionId: '10000000-0000-4000-8000-000000000001',
      studentId: '20000000-0000-4000-8000-000000000001',
      status: 'absent',
      clientUpdatedAt: DateTime.utc(2026, 11, 18, 9),
    );
    await controller.rescheduleBackgroundIfPending();
    expect(calls, ['schedule']);
  });
}
