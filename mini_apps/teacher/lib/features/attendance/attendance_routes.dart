import 'package:go_router/go_router.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'pages/attendance_page.dart';
import 'pages/history_page.dart';

/// Đường dẫn T04 và nhật ký sửa.
abstract final class AttendanceRoutes {
  static String sheet(String sessionId) =>
      '${TeachHubRoutes.teacher}/sessions/$sessionId/attendance';
  static String history(String sessionId) => '${sheet(sessionId)}/history';
}

List<RouteBase> attendanceRoutes(String moduleId) => [
  GoRoute(
    path: '${TeachHubRoutes.teacher}/sessions/:id/attendance',
    name: '$moduleId.attendance',
    builder: (context, state) =>
        AttendancePage(sessionId: state.pathParameters['id']!),
    routes: [
      GoRoute(
        path: 'history',
        name: '$moduleId.attendance.history',
        builder: (context, state) =>
            HistoryPage(sessionId: state.pathParameters['id']!),
      ),
    ],
  ),
];
