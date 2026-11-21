import 'package:go_router/go_router.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'pages/plan_page.dart';

/// Đường dẫn T14 (gói và dùng thử Pro) của giáo viên.
abstract final class PlanRoutes {
  static const plan = '${TeachHubRoutes.teacher}/plan';
}

List<RouteBase> planRoutes(String moduleId) => [
  GoRoute(
    path: PlanRoutes.plan,
    name: '$moduleId.plan',
    builder: (context, state) => const PlanPage(),
  ),
];
