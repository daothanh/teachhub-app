import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_module/tasco_module.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'features/home/pages/student_home_page.dart';
import 'l10n/l10n.dart';

/// Mini-app không gian Học sinh (spec §3.7), route gốc [TeachHubRoutes.student].
///
/// Gọi API qua `Dio` dùng chung của host (`TeachHubDiKey.api`) nên không tự
/// dựng client, không giữ token.
class StudentController {
  StudentController._();
  static final instance = StudentController._();

  String get moduleId => 'student';
  String get routePrefix => TeachHubRoutes.student;

  List<LocalizationsDelegate> get localizationsDelegates =>
      MiniAppLocalizations.localizationsDelegates;

  List<RouteBase> routes() => [
    GoRoute(
      path: routePrefix,
      name: '$moduleId.home',
      builder: (context, state) => const StudentHomePage(),
    ),
  ];

  ModuleSlot toModuleSlot() => ModuleSlot(
    moduleId: moduleId,
    routePrefix: routePrefix,
    notificationTypes: const {},
    init: () async {},
    routes: routes,
    onNotification: (type, data) async {},
    dispose: () async {},
  );
}
