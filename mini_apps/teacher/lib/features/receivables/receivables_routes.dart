import 'package:go_router/go_router.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'pages/dunning_settings_page.dart';
import 'pages/receivables_page.dart';
import 'pages/student_receivable_page.dart';

/// Đường dẫn màn công nợ (T11) và cài đặt nhắc nợ của giáo viên.
abstract final class ReceivablesRoutes {
  static const list = '${TeachHubRoutes.teacher}/receivables';
  static String student(String studentId) => '$list/$studentId';

  /// Đặt ngoài `/receivables/:studentId` để không trùng tham số.
  static const dunningSettings = '${TeachHubRoutes.teacher}/dunning-settings';
}

List<RouteBase> receivablesRoutes(String moduleId) => [
  GoRoute(
    path: ReceivablesRoutes.list,
    name: '$moduleId.receivables',
    builder: (context, state) => const ReceivablesPage(),
  ),
  GoRoute(
    path: '${ReceivablesRoutes.list}/:studentId',
    name: '$moduleId.receivables.student',
    builder: (context, state) =>
        StudentReceivablePage(studentId: state.pathParameters['studentId']!),
  ),
  GoRoute(
    path: ReceivablesRoutes.dunningSettings,
    name: '$moduleId.dunningSettings',
    builder: (context, state) => const DunningSettingsPage(),
  ),
];
