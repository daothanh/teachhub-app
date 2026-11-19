import 'dart:async';
import 'dart:io';

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
import 'data/sync/background_sync.dart';
import 'data/sync/clock_skew.dart';
import 'data/sync/connectivity.dart';
import 'data/sync/sync_engine.dart';
import 'features/attendance/attendance_routes.dart';
import 'features/attendance/data/attendance_repository.dart';
import 'features/classes/classes_routes.dart';
import 'features/offline/offline_banner_shell.dart';
import 'features/onboarding/data/onboarding_models.dart';
import 'features/onboarding/data/onboarding_repository.dart';
import 'features/onboarding/pages/onboarding_page.dart';
import 'features/students/data/student_repository.dart';
import 'features/students/pages/student_form_page.dart';
import 'features/today/pages/today_page.dart';
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

  /// Mọi route teacher nằm trong khung banner "Ngoại tuyến" (S3-FL-09).
  List<RouteBase> routes() => [
    ShellRoute(
      builder: (context, state, child) =>
          OfflineBannerShell(path: state.uri.path, child: child),
      routes: _pageRoutes(),
    ),
  ];

  List<RouteBase> _pageRoutes() => [
    GoRoute(
      path: routePrefix,
      name: '$moduleId.home',
      builder: (context, state) => const TodayPage(),
      routes: [
        GoRoute(
          path: 'onboarding',
          name: '$moduleId.onboarding',
          builder: (context, state) => OnboardingPage(
            // `?step=` mở đúng một bước (thẻ nhắc ở T03), không thì bước dở.
            initialStep: OnboardingStep.fromWire(
              state.uri.queryParameters['step'],
            ),
          ),
        ),
        GoRoute(
          path: 'students/new',
          name: '$moduleId.studentNew',
          builder: (context, state) => const StudentFormPage(),
        ),
      ],
    ),
    ...classesRoutes(moduleId),
    ...attendanceRoutes(moduleId),
  ];

  /// CSDL chỉ mở ở lần đầu cần (lazy): người dùng không có vai trò Giáo viên
  /// không tạo file trên máy.
  Future<void> init() async {
    _registerRepositories();
    if (GetIt.I.isRegistered<TeacherDatabase>(instanceName: databaseKey)) {
      return;
    }
    GetIt.I.registerLazySingletonAsync<TeacherDatabase>(
      () => TeacherDatabase.openEncrypted(SecureStore()),
      instanceName: databaseKey,
      dispose: (db) => db.close(),
    );
  }

  /// Repository gọi API qua `Dio` của host; lazy nên chưa cần `Dio` lúc init.
  void _registerRepositories() {
    final getIt = GetIt.I;
    Dio api() => getIt<Dio>(instanceName: TeachHubDiKey.api);
    if (!getIt.isRegistered<StudentRepository>()) {
      getIt.registerLazySingleton<StudentRepository>(
        () => DioStudentRepository(api()),
      );
    }
    if (!getIt.isRegistered<AttendanceRepository>()) {
      getIt.registerLazySingleton<AttendanceRepository>(
        () => DriftAttendanceRepository(
          database: () =>
              getIt.getAsync<TeacherDatabase>(instanceName: databaseKey),
          api: _api,
          engine: () async => syncEngine,
          startSync: startSync,
          clock: clock,
        ),
      );
    }
    if (!getIt.isRegistered<OnboardingRepository>()) {
      getIt.registerLazySingleton<OnboardingRepository>(
        () => DioOnboardingRepository(api()),
      );
    }
  }

  /// CSDL gắn với phiên: đếm, xóa, đổi chủ (xem [TeacherLocalData]).
  late final localData = TeacherLocalData(
    keyStore: keyStoreOverride ?? SecureStore(),
    directory: () => documentsDirectory(),
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

  /// Có khi đang đồng bộ; xem [startSync].
  SyncEngine? syncEngine;
  bool _syncWanted = false;

  /// Shell cài móc hẹn/hủy đồng bộ nền (S3-FL-09); `null` = không có nền.
  BackgroundSyncHooks? backgroundSync;
  StreamSubscription<bool>? _pendingSub;

  Future<TeacherApi> _api() => loadTeacherApi(
    GetIt.I<Dio>(instanceName: TeachHubDiKey.api),
    keyStoreOverride ?? SecureStore(),
  );

  /// Cache buổi + học viên để UI đọc ngoại tuyến và làm mới từ API.
  Future<SessionCache> openSessionCache() async => SessionCache(
    await GetIt.I.getAsync<TeacherDatabase>(instanceName: databaseKey),
    await _api(),
    clock: clock,
  );

  /// Bật SyncEngine (đẩy ngay, đẩy khi có mạng, tự thử lại). Hook cho đồng bộ
  /// nền (S3-FL-09). Engine tự dừng khi xóa CSDL và bật lại sau đó.
  Future<void> startSync() {
    _syncWanted = true;
    return _starting ??= _start().whenComplete(() => _starting = null);
  }

  Future<void> _start() async {
    if (syncEngine != null) return;
    final db = await GetIt.I.getAsync<TeacherDatabase>(
      instanceName: databaseKey,
    );
    final api = await _api();
    if (!_syncWanted) return; // stopSync() gọi trong lúc chờ
    enginesCreated++;
    final engine = syncEngine = SyncEngine(db, api.sync, clock: clock)
      ..start(onlineChanges());
    // Còn mutation chờ thì hẹn lượt đẩy nền (app bị kill vẫn gửi được).
    _pendingSub = engine
        .watchPending()
        .map((n) => n > 0)
        .distinct()
        .listen(
          (has) => unawaited(
            (has ? backgroundSync?.schedule() : backgroundSync?.cancel()) ??
                Future.value(),
          ),
        );
  }

  Future<void>? _starting;

  /// Số engine đã dựng (để test kiểm các lần startSync chồng nhau).
  @visibleForTesting
  int enginesCreated = 0;

  /// Thư mục chứa file CSDL; test thay bằng thư mục tạm.
  @visibleForTesting
  Future<Directory> Function() documentsDirectory =
      getApplicationDocumentsDirectory;

  /// Thay kho khóa thật (Keychain/Keystore) trong test.
  @visibleForTesting
  KeyValueStore? keyStoreOverride;

  Future<void> stopSync() {
    _syncWanted = false;
    return _pauseSync();
  }

  Future<void> _pauseSync() async {
    await _starting; // chờ lượt startSync đang dựng engine
    final engine = syncEngine;
    syncEngine = null;
    await _pendingSub?.cancel();
    _pendingSub = null;
    await engine?.stop();
  }

  Future<void> _resumeSync() => _syncWanted ? startSync() : Future.value();

  Future<int> pendingSyncCount() => localData.pendingSyncCount();

  /// Sau đăng nhập: outbox còn dòng thì hẹn lại lượt nền ngay, không đợi vào
  /// màn teacher (lịch có thể đã bị hủy khi hết phiên).
  Future<void> rescheduleBackgroundIfPending() async {
    if (await pendingSyncCount() > 0) await backgroundSync?.schedule();
  }

  Future<int> failedSyncCount() => localData.failedSyncCount();
  Future<void> discardFailedSync() => localData.discardFailed();

  /// Đăng xuất: dừng đồng bộ trước rồi xóa (không để engine chạy lại với phiên
  /// đã mất). Vào lại màn chính của giáo viên thì [startSync] bật lại.
  Future<void> wipeLocalData() async {
    await stopSync();
    await backgroundSync?.cancel();
    await localData.wipe();
  }

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
