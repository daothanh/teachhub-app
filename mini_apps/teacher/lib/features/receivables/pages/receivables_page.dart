import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teachhub_shared/teachhub_shared.dart' show ApiException;

import '../../../l10n/l10n.dart';
import '../../billing/cubit/billing_periods_cubit.dart' show BillingLoad;
import '../../billing/widgets/billing_error_text.dart';
import '../../classes/data/class_models.dart' show TeachClass;
import '../../classes/data/classes_repository.dart';
import '../../fees/data/fee_models.dart' show formatVnd;
import '../cubit/receivables_cubit.dart';
import '../data/receivable_models.dart';
import '../data/receivables_repository.dart';
import '../receivables_routes.dart';
import '../widgets/dunning_labels.dart';

/// T11: công nợ (US-8.3 AC1–AC2) — học viên còn nợ, tổng theo nhóm tuổi nợ,
/// lọc theo nhóm, tìm theo tên, sắp theo số nợ, cuộn tải thêm.
class ReceivablesPage extends StatelessWidget {
  const ReceivablesPage({super.key, this.repository, this.classes});
  final ReceivablesRepository? repository;

  /// Nguồn danh sách lớp cho bộ lọc lớp.
  final ClassesRepository? classes;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        ReceivablesCubit(repository ?? receivablesRepository())..load(),
    child: _View(classes: classes),
  );
}

class _View extends StatelessWidget {
  const _View({this.classes});
  final ClassesRepository? classes;

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
      body: BlocConsumer<ReceivablesCubit, ReceivablesState>(
        listenWhen: (a, b) =>
            b.refreshError != null && a.refreshError != b.refreshError,
        listener: (context, s) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(billingErrorText(l10n, s.refreshError!))),
        ),
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
              if (i == 0) {
                return _Filters(
                  key: const ValueKey('filters'),
                  classes: classes,
                );
              }
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
  const _Filters({super.key, this.classes});
  final ClassesRepository? classes;

  @override
  State<_Filters> createState() => _FiltersState();
}

class _FiltersState extends State<_Filters> {
  final _query = TextEditingController();
  Timer? _debounce;

  /// Lớp đang mở để chọn lọc; chỉ trang đầu (shortcut: tenant nhiều hơn một
  /// trang lớp thì chọn lớp ngoài trang đầu chưa được, nâng lên khi cần).
  List<TeachClass> _classes = const [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final r = await (widget.classes ?? classesRepository()).list();
      if (mounted) setState(() => _classes = r.items);
    } on ApiException {
      // Không tải được lớp thì ẩn bộ lọc lớp, danh sách vẫn dùng được.
    }
  }

  Future<void> _pickClass() async {
    final cubit = context.read<ReceivablesCubit>();
    final picked = await showModalBottomSheet<({String? id})>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => _ClassSheet(classes: _classes),
    );
    if (picked != null) await cubit.setClass(picked.id);
  }

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
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            if (_classes.isNotEmpty)
              TextButton.icon(
                onPressed: _pickClass,
                icon: const Icon(Icons.class_outlined, size: 18),
                label: Text(
                  l10n.receivablesClassFilter(
                    _classes
                            .where((c) => c.id == s.classId)
                            .map((c) => c.name)
                            .firstOrNull ??
                        l10n.receivablesClassAll,
                  ),
                ),
              ),
            TextButton.icon(
              onPressed: cubit.toggleSort,
              icon: Icon(
                s.ascending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 18,
              ),
              label: Text(
                s.ascending
                    ? l10n.receivablesSortAsc
                    : l10n.receivablesSortDesc,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ClassSheet extends StatelessWidget {
  const _ClassSheet({required this.classes});
  final List<TeachClass> classes;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          l10n.receivablesClassPick,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        ListTile(
          title: Text(l10n.receivablesClassAll),
          onTap: () => Navigator.pop(context, (id: null)),
        ),
        for (final c in classes)
          ListTile(
            title: Text(c.name),
            onTap: () => Navigator.pop(context, (id: c.id)),
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
                      l10n.receivablesAgingLine(
                        agingBucketLabel(l10n, r.agingBucket),
                        l10n.receivablesOverdue(r.overdueDays),
                      ),
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
