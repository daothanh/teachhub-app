import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_module/tasco_module.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'features/home/pages/parent_home_page.dart';
import 'l10n/l10n.dart';

/// Mini-app không gian Phụ huynh (spec §3.7), route gốc [TeachHubRoutes.parent].
///
/// Gọi API qua `Dio` dùng chung của host (`TeachHubDiKey.api`) nên không tự
/// dựng client, không giữ token.
class ParentController {
  ParentController._();
  static final instance = ParentController._();

  String get moduleId => 'parent';
  String get routePrefix => TeachHubRoutes.parent;

  List<LocalizationsDelegate> get localizationsDelegates =>
      MiniAppLocalizations.localizationsDelegates;

  List<RouteBase> routes() => [
    GoRoute(
      path: routePrefix,
      name: '$moduleId.home',
      builder: (context, state) => const ParentHomePage(),
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
