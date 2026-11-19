import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tasco_module/tasco_module.dart';
import 'package:tasco_storage/tasco_storage.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'data/local_db/teacher_database.dart';
import 'features/home/pages/teacher_home_page.dart';
import 'l10n/l10n.dart';

/// Mini-app không gian Giáo viên (spec §3.7), route gốc [TeachHubRoutes.teacher].
///
/// Gọi API qua `Dio` dùng chung của host (`TeachHubDiKey.api`) nên không tự
/// dựng client, không giữ token.
class TeacherController {
  TeacherController._();
  static final instance = TeacherController._();

  String get moduleId => 'teacher';

  /// Khóa `GetIt` của CSDL cục bộ (`'<moduleId>.<tên>'`).
  static const databaseKey = 'teacher.database';
  String get routePrefix => TeachHubRoutes.teacher;

  List<LocalizationsDelegate> get localizationsDelegates =>
      MiniAppLocalizations.localizationsDelegates;

  List<RouteBase> routes() => [
    GoRoute(
      path: routePrefix,
      name: '$moduleId.home',
      builder: (context, state) => const TeacherHomePage(),
    ),
  ];

  /// CSDL chỉ mở ở lần đầu cần (lazy): người dùng không có vai trò Giáo viên
  /// không tạo file trên máy.
  Future<void> init() async {
    if (GetIt.I.isRegistered<TeacherDatabase>(instanceName: databaseKey)) {
      return;
    }
    GetIt.I.registerLazySingletonAsync<TeacherDatabase>(
      () => TeacherDatabase.openEncrypted(SecureStore()),
      instanceName: databaseKey,
      dispose: (db) => db.close(),
    );
  }

  /// Số buổi chưa đồng bộ (đăng xuất cần biết, spec §6.4). Chưa có file CSDL
  /// thì là 0 và không tạo file.
  Future<int> pendingSyncCount() async {
    final dir = await getApplicationDocumentsDirectory();
    if (!File('${dir.path}/teacher.sqlite').existsSync()) return 0;
    final db = await GetIt.I.getAsync<TeacherDatabase>(
      instanceName: databaseKey,
    );
    return pendingOutboxCount(db);
  }

  /// Đóng rồi xóa CSDL `teacher` và khóa của nó. Chỉ gọi khi outbox trống hoặc
  /// người dùng đã xác nhận bỏ dữ liệu chưa đồng bộ. CSDL mở lại lười khi cần.
  Future<void> wipeLocalData() async {
    await dispose();
    await deleteTeacherDatabase(
      SecureStore(),
      await getApplicationDocumentsDirectory(),
    );
    await init();
  }

  Future<void> dispose() async {
    if (GetIt.I.isRegistered<TeacherDatabase>(instanceName: databaseKey)) {
      await GetIt.I.unregister<TeacherDatabase>(instanceName: databaseKey);
    }
  }

  ModuleSlot toModuleSlot() => ModuleSlot(
    moduleId: moduleId,
    routePrefix: routePrefix,
    notificationTypes: const {},
    init: init,
    routes: routes,
    onNotification: (type, data) async {},
    dispose: dispose,
  );
}
