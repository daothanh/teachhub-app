import 'package:go_router/go_router.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'data/fee_models.dart';
import 'pages/fee_override_page.dart';
import 'pages/payout_account_form_page.dart';
import 'pages/payout_accounts_page.dart';

/// Đường dẫn màn học phí riêng và tài khoản nhận tiền.
abstract final class FeesRoutes {
  /// Danh sách tài khoản nhận tiền. Màn chốt kỳ mở route này khi API trả
  /// `PAYOUT_ACCOUNT_MISSING` (US-7.3 AC5).
  static const payoutAccounts = '${TeachHubRoutes.teacher}/payout-accounts';
  static const payoutNew = '$payoutAccounts/new';
  static String payoutEdit(String id) => '$payoutAccounts/$id/edit';

  /// Mức riêng của một học viên; `extra` là [FeeOverrideArgs].
  static String feeOverride(String classId, String enrollmentId) =>
      '${TeachHubRoutes.teacher}/classes/$classId/enrollments/$enrollmentId/fee';
}

/// `/new` đứng trước `/:id` để không bị nuốt thành id.
List<RouteBase> feesRoutes(String moduleId) => [
  GoRoute(
    path: FeesRoutes.payoutAccounts,
    name: '$moduleId.payoutAccounts',
    builder: (context, state) => const PayoutAccountsPage(),
  ),
  GoRoute(
    path: FeesRoutes.payoutNew,
    name: '$moduleId.payoutAccounts.new',
    builder: (context, state) => const PayoutAccountFormPage(),
  ),
  GoRoute(
    path: '${FeesRoutes.payoutAccounts}/:id/edit',
    name: '$moduleId.payoutAccounts.edit',
    builder: (context, state) => switch (state.extra) {
      final PayoutAccount a => PayoutAccountFormPage(editing: a),
      // Mở thẳng không có dữ liệu: về danh sách để chọn lại.
      _ => const PayoutAccountsPage(),
    },
  ),
  GoRoute(
    path: '${TeachHubRoutes.teacher}/classes/:id/enrollments/:enrollmentId/fee',
    name: '$moduleId.feeOverride',
    builder: (context, state) => FeeOverridePage(
      enrollmentId: state.pathParameters['enrollmentId']!,
      args: switch (state.extra) {
        final FeeOverrideArgs a => a,
        _ => const FeeOverrideArgs(),
      },
    ),
  ),
];
