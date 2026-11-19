import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tasco_module/tasco_module.dart';
import 'package:tasco_storage/tasco_storage.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'data/cache/session_cache.dart';
import 'data/local_db/teacher_database.dart';
import 'data/local_db/teacher_local_data.dart';
import 'data/remote/teacher_api.dart';
import 'data/sync/clock_skew.dart';
import 'data/sync/connectivity.dart';
import 'data/sync/sync_engine.dart';
import 'data/sync/uuid.dart';
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

  /// CSDL gắn với phiên: đếm, xóa, đổi chủ (xem [TeacherLocalData]).
  late final localData = TeacherLocalData(
    keyStore: SecureStore(),
    directory: getApplicationDocumentsDirectory,
    // Lấy qua GetIt mỗi lần, không giữ instance: xóa xong đăng ký lại.
    database: () =>
        GetIt.I.getAsync<TeacherDatabase>(instanceName: databaseKey),
    close: dispose,
    reopen: init,
    pauseSync: _pauseSync,
    resumeSync: _resumeSync,
  );

  /// Lệch đồng hồ máy/server dùng chung cho engine và cache.
  final clock = ClockSkew();

  static const _deviceIdKey = 'teacher.device_id';

  /// Có khi đang đồng bộ; xem [startSync].
  SyncEngine? syncEngine;
  bool _syncWanted = false;

  /// Mã thiết bị ổn định của máy này (không xóa khi đăng xuất: là của máy).
  Future<TeacherApi> _api() async {
    final keys = SecureStore();
    var id = await keys.read(_deviceIdKey);
    if (id == null) {
      id = newUuid();
      await keys.write(_deviceIdKey, id);
    }
    return TeacherApi(
      GetIt.I<Dio>(instanceName: TeachHubDiKey.api),
      deviceId: id,
    );
  }

  /// Cache buổi + học viên để UI đọc ngoại tuyến và làm mới từ API.
  Future<SessionCache> openSessionCache() async => SessionCache(
    await GetIt.I.getAsync<TeacherDatabase>(instanceName: databaseKey),
    await _api(),
    clock: clock,
  );

  /// Bật SyncEngine (đẩy ngay, đẩy khi có mạng, tự thử lại). Hook cho đồng bộ
  /// nền (S3-FL-09). Engine tự dừng khi xóa CSDL và bật lại sau đó.
  Future<void> startSync() async {
    _syncWanted = true;
    if (syncEngine != null) return;
    final db = await GetIt.I.getAsync<TeacherDatabase>(
      instanceName: databaseKey,
    );
    final api = await _api();
    syncEngine = SyncEngine(db, api.sync, clock: clock)..start(onlineChanges());
  }

  Future<void> stopSync() {
    _syncWanted = false;
    return _pauseSync();
  }

  Future<void> _pauseSync() async {
    final engine = syncEngine;
    syncEngine = null;
    await engine?.stop();
  }

  Future<void> _resumeSync() => _syncWanted ? startSync() : Future.value();

  Future<int> pendingSyncCount() => localData.pendingSyncCount();
  Future<void> wipeLocalData() => localData.wipe();
  Future<void> retryPendingWipe() => localData.retryPendingWipe();
  Future<void> claimDatabaseFor(String userId) => localData.claimFor(userId);

  Future<void> dispose() async {
    await _pauseSync();
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
