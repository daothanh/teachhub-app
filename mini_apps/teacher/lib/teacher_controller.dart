import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tasco_module/tasco_module.dart';
import 'package:tasco_storage/tasco_storage.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'data/local_db/teacher_database.dart';
import 'data/local_db/teacher_local_data.dart';
import 'features/classes/classes_routes.dart';
import 'features/home/pages/teacher_home_page.dart';
import 'features/onboarding/data/onboarding_repository.dart';
import 'features/onboarding/pages/onboarding_page.dart';
import 'features/students/data/student_repository.dart';
import 'features/students/pages/student_form_page.dart';
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
      routes: [
        GoRoute(
          path: 'onboarding',
          name: '$moduleId.onboarding',
          builder: (context, state) => const OnboardingPage(),
        ),
        GoRoute(
          path: 'students/new',
          name: '$moduleId.studentNew',
          builder: (context, state) => const StudentFormPage(),
        ),
      ],
    ),
    ...classesRoutes(moduleId),
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
    if (!getIt.isRegistered<OnboardingRepository>()) {
      getIt.registerLazySingleton<OnboardingRepository>(
        () => DioOnboardingRepository(api()),
      );
    }
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
  );

  Future<int> pendingSyncCount() => localData.pendingSyncCount();
  Future<void> wipeLocalData() => localData.wipe();
  Future<void> retryPendingWipe() => localData.retryPendingWipe();
  Future<void> claimDatabaseFor(String userId) => localData.claimFor(userId);

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
