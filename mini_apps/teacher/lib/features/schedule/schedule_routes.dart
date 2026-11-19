import 'package:go_router/go_router.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'pages/schedule_page.dart';

/// Đường dẫn T05 (lịch ngày/tuần).
abstract final class ScheduleRoutes {
  static const schedule = '${TeachHubRoutes.teacher}/schedule';
}

List<RouteBase> scheduleRoutes(String moduleId) => [
  GoRoute(
    path: ScheduleRoutes.schedule,
    name: '$moduleId.schedule',
    builder: (context, state) => const SchedulePage(),
  ),
];
