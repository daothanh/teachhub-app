import 'package:go_router/go_router.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'pages/report_payments_page.dart';
import 'pages/reports_page.dart';

/// Đường dẫn màn báo cáo (T12/T12a) của giáo viên.
abstract final class ReportsRoutes {
  static const overview = '${TeachHubRoutes.teacher}/reports';

  /// Danh sách khoản thu của ô "Đã thu"; `month` là `YYYY-MM`.
  static String payments(String month) => '$overview/payments?month=$month';
}

List<RouteBase> reportsRoutes(String moduleId) => [
  GoRoute(
    path: ReportsRoutes.overview,
    name: '$moduleId.reports',
    builder: (context, state) => const ReportsPage(),
  ),
  GoRoute(
    path: '${ReportsRoutes.overview}/payments',
    name: '$moduleId.reports.payments',
    builder: (context, state) =>
        ReportPaymentsPage(month: state.uri.queryParameters['month']),
  ),
];
