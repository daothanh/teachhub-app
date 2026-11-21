import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';
import '../../billing/cubit/billing_periods_cubit.dart' show BillingLoad;
import '../../billing/widgets/billing_error_text.dart';
import '../../fees/data/fee_models.dart' show formatVnd;
import '../cubit/receivables_cubit.dart';
import '../data/receivable_models.dart';
import '../data/receivables_repository.dart';
import '../receivables_routes.dart';
import '../widgets/dunning_labels.dart';

/// T11: công nợ (US-8.3 AC1–AC2) — học viên còn nợ, tổng theo nhóm tuổi nợ,
/// lọc theo nhóm, tìm theo tên, sắp theo số nợ, cuộn tải thêm.
class ReceivablesPage extends StatelessWidget {
  const ReceivablesPage({super.key, this.repository});
  final ReceivablesRepository? repository;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        ReceivablesCubit(repository ?? receivablesRepository())..load(),
    child: const _View(),
  );
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cubit = context.read<ReceivablesCubit>();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.receivablesTitle),
        actions: [
          IconButton(
            tooltip: l10n.receivablesDunningSettings,
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () => context.push(ReceivablesRoutes.dunningSettings),
          ),
        ],
      ),
      body: BlocBuilder<ReceivablesCubit, ReceivablesState>(
        builder: (context, s) => RefreshIndicator(
          onRefresh: cubit.refresh,
          // Một ListView cho mọi trạng thái: ô tìm kiếm không mất tiêu điểm khi
          // danh sách tải lại.
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: s.load == BillingLoad.ready && s.items.isNotEmpty
                ? 1 + s.items.length + (s.hasMore ? 1 : 0)
                : 2,
            itemBuilder: (context, i) {
              if (i == 0) return const _Filters(key: ValueKey('filters'));
              if (s.load != BillingLoad.ready || s.items.isEmpty) {
                return _Status(state: s);
              }
              if (i <= s.items.length) {
                return _RowCard(row: s.items[i - 1]);
              }
              return s.moreFailed
                  ? _MoreFailed(onRetry: cubit.loadMore)
                  : const _AutoLoadMore();
            },
          ),
        ),
      ),
    );
  }
}

class _Filters extends StatefulWidget {
  const _Filters({super.key});

  @override
  State<_Filters> createState() => _FiltersState();
}

class _FiltersState extends State<_Filters> {
  final _query = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => context.read<ReceivablesCubit>().setQuery(v),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final cubit = context.read<ReceivablesCubit>();
    final s = context.select<ReceivablesCubit, ReceivablesState>(
      (c) => c.state,
    );
    final byBucket = {for (final b in s.buckets) b.bucket: b};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppInput(
          controller: _query,
          hint: l10n.receivablesSearchHint,
          prefix: const Icon(Icons.search),
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
        ),
        if (s.buckets.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.receivablesTotalOwed(formatVnd(s.totalAmount)),
            style: text.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppChoiceChip(
                label: l10n.receivablesBucketAll,
                selected: s.bucket == null,
                onTap: () => cubit.setBucket(null),
              ),
              for (final b in AgingBucket.values)
                AppChoiceChip(
                  label: l10n.receivablesBucketChip(
                    agingBucketLabel(l10n, b),
                    formatVnd(byBucket[b]?.totalAmount ?? 0),
                  ),
                  selected: s.bucket == b,
                  onTap: () => cubit.setBucket(s.bucket == b ? null : b),
                ),
            ],
          ),
        ],
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: cubit.toggleSort,
            icon: Icon(
              s.ascending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 18,
            ),
            label: Text(
              s.ascending ? l10n.receivablesSortAsc : l10n.receivablesSortDesc,
            ),
          ),
        ),
      ],
    );
  }
}

/// Đang tải, lỗi (thử lại) hoặc rỗng dưới thanh lọc.
class _Status extends StatelessWidget {
  const _Status({required this.state});
  final ReceivablesState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final s = state;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: switch (s.load) {
        BillingLoad.loading => const Center(child: CircularProgressIndicator()),
        BillingLoad.failure => AppEmptyState(
          message: s.error == null
              ? l10n.receivablesLoadFailed
              : billingErrorText(l10n, s.error!),
          action: AppButton(
            label: l10n.classesRetry,
            onPressed: context.read<ReceivablesCubit>().load,
          ),
        ),
        BillingLoad.ready when s.unfiltered => AppEmptyState(
          message: l10n.receivablesEmpty,
          subMessage: l10n.receivablesEmptyBody,
        ),
        BillingLoad.ready => AppEmptyState(
          message: l10n.receivablesEmptyFiltered,
        ),
      },
    );
  }
}

class _RowCard extends StatelessWidget {
  const _RowCard({required this.row});
  final ReceivableRow row;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final r = row;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () async {
          final cubit = context.read<ReceivablesCubit>();
          await context.push(ReceivablesRoutes.student(r.studentId));
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
                    Text(r.studentName, style: text.titleSmall),
                    Text(
                      l10n.receivablesRowOwed(formatVnd(r.outstandingAmount)),
                      style: text.titleSmall?.copyWith(color: scheme.primary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.receivablesRowMeta(
                        r.classNames.join(', '),
                        r.openInvoiceCount,
                      ),
                      style: text.bodySmall,
                    ),
                    Text(
                      '${agingBucketLabel(l10n, r.agingBucket)} · '
                      '${l10n.receivablesOverdue(r.overdueDays)}',
                      style: text.bodySmall?.copyWith(
                        color: r.agingBucket == AgingBucket.over60
                            ? scheme.error
                            : null,
                        fontWeight: r.agingBucket == AgingBucket.over60
                            ? FontWeight.w700
                            : null,
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

/// Cuối danh sách: được dựng (do cuộn tới hoặc vừa khung) thì tải trang kế.
class _AutoLoadMore extends StatefulWidget {
  const _AutoLoadMore();

  @override
  State<_AutoLoadMore> createState() => _AutoLoadMoreState();
}

class _AutoLoadMoreState extends State<_AutoLoadMore> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ReceivablesCubit>().loadMore();
    });
  }

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(AppSpacing.md),
    child: Center(child: CircularProgressIndicator()),
  );
}

class _MoreFailed extends StatelessWidget {
  const _MoreFailed({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return Row(
      children: [
        Expanded(child: Text(l10n.receivablesMoreFailed)),
        TextButton(onPressed: onRetry, child: Text(l10n.classesRetry)),
      ],
    );
  }
}
