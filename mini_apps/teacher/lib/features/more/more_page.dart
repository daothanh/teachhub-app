import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../l10n/l10n.dart';
import '../fees/fees_routes.dart';
import '../plan/plan_routes.dart';
import '../receivables/receivables_routes.dart';
import '../reports/reports_routes.dart';

abstract final class MoreRoutes {
  static const more = '${TeachHubRoutes.teacher}/more';
}

/// Tab "Thêm": các mục ít dùng hằng ngày (công nợ, báo cáo, gói, tài khoản
/// nhận tiền, cài đặt).
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final entries = [
      (
        Icons.receipt_long_outlined,
        l10n.receivablesTitle,
        ReceivablesRoutes.list,
      ),
      (Icons.bar_chart_outlined, l10n.reportsTitle, ReportsRoutes.overview),
      (Icons.workspace_premium_outlined, l10n.todayPlanEntry, PlanRoutes.plan),
      (
        Icons.account_balance_outlined,
        l10n.payoutTitle,
        FeesRoutes.payoutAccounts,
      ),
      (Icons.settings_outlined, l10n.todaySettings, TeachHubRoutes.settings),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navMore)),
      body: ListView(
        children: [
          for (final (icon, label, path) in entries)
            ListTile(
              leading: Icon(icon),
              title: Text(label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(path),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.moreIconCredit,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
