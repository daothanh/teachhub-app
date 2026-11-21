import 'package:go_router/go_router.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'pages/billing_period_page.dart';
import 'pages/billing_periods_page.dart';
import 'pages/invoice_page.dart';

/// Đường dẫn màn kỳ thu và hóa đơn của giáo viên.
abstract final class BillingRoutes {
  /// T10: danh sách kỳ thu. Thông báo `billing_ready` mở thẳng chi tiết kỳ
  /// qua [period] (deep link `teachhub://billing/periods/<id>`).
  static const periods = TeachHubRoutes.teacherBilling;
  static String period(String id) => '$periods/$id';
  static String invoice(String id) => '${TeachHubRoutes.teacher}/invoices/$id';
}

List<RouteBase> billingRoutes(String moduleId) => [
  GoRoute(
    path: BillingRoutes.periods,
    name: '$moduleId.billing',
    builder: (context, state) => const BillingPeriodsPage(),
  ),
  GoRoute(
    path: '${BillingRoutes.periods}/:periodId',
    name: '$moduleId.billing.period',
    builder: (context, state) =>
        BillingPeriodPage(periodId: state.pathParameters['periodId']!),
  ),
  GoRoute(
    path: '${TeachHubRoutes.teacher}/invoices/:invoiceId',
    name: '$moduleId.billing.invoice',
    builder: (context, state) =>
        InvoicePage(invoiceId: state.pathParameters['invoiceId']!),
  ),
];
