import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';
import '../../fees/data/fee_models.dart' show formatVnd;
import '../../receivables/receivables_routes.dart';
import '../billing_routes.dart';
import '../cubit/billing_periods_cubit.dart';
import '../data/billing_models.dart';
import '../data/billing_repository.dart';
import '../widgets/billing_error_text.dart';

/// T10: học phí theo kỳ thu (US-7.2 AC1) — danh sách kỳ, bấm vào để xem bản nháp.
class BillingPeriodsPage extends StatelessWidget {
  const BillingPeriodsPage({super.key, this.repository});
  final BillingRepository? repository;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        BillingPeriodsCubit(repository ?? billingRepository())..load(),
    child: const _View(),
  );
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cubit = context.read<BillingPeriodsCubit>();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.billingTitle),
        actions: [
          IconButton(
            tooltip: l10n.receivablesTitle,
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () => context.push(ReceivablesRoutes.list),
          ),
        ],
      ),
      body: BlocBuilder<BillingPeriodsCubit, BillingPeriodsState>(
        builder: (context, s) => switch (s.load) {
          BillingLoad.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          BillingLoad.failure => AppEmptyState(
            message: s.error == null
                ? l10n.billingLoadFailed
                : billingErrorText(l10n, s.error!),
            action: AppButton(label: l10n.classesRetry, onPressed: cubit.load),
          ),
          BillingLoad.ready when s.periods.isEmpty => AppEmptyState(
            message: l10n.billingPeriodsEmpty,
            subMessage: l10n.billingPeriodsEmptyBody,
          ),
          BillingLoad.ready => RefreshIndicator(
            onRefresh: cubit.refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: s.periods.length,
              itemBuilder: (_, i) => _PeriodCard(
                key: ValueKey(s.periods[i].id),
                period: s.periods[i],
              ),
            ),
          ),
        },
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({super.key, required this.period});
  final BillingPeriod period;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final p = period;
    final drafting = p.status == BillingPeriodStatus.drafting;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () async {
          final cubit = context.read<BillingPeriodsCubit>();
          await context.push(BillingRoutes.period(p.id));
          await cubit.refresh();
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.billingPeriodMonth(p.month, p.year),
                      style: text.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.billingPeriodDates(
                        formatIsoDate(p.closeDate),
                        formatIsoDate(p.dueDate),
                      ),
                      style: text.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.billingDraftSummary(
                        p.draftCount,
                        formatVnd(p.draftTotalAmount),
                      ),
                      style: text.bodyMedium,
                    ),
                    if (p.issuedCount > 0)
                      Text(
                        l10n.billingIssuedSummary(
                          p.issuedCount,
                          formatVnd(p.issuedTotalAmount),
                        ),
                        style: text.bodyMedium,
                      ),
                    if (p.voidCount > 0)
                      Text(
                        l10n.billingVoidSummary(p.voidCount),
                        style: text.bodySmall,
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      drafting
                          ? l10n.billingPeriodDrafting
                          : l10n.billingPeriodClosed,
                      style: text.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: drafting
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
