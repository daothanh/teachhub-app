import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';
import '../../billing/billing_routes.dart';
import '../../billing/cubit/billing_periods_cubit.dart' show BillingLoad;
import '../../billing/widgets/billing_error_text.dart';
import '../../fees/data/fee_models.dart' show formatVnd;
import '../../receivables/receivables_routes.dart';
import '../cubit/reports_cubit.dart';
import '../data/report_models.dart';
import '../data/reports_repository.dart';
import '../reports_routes.dart';
import '../widgets/revenue_bar_chart.dart';

/// T12/T12a: báo cáo tháng (US-8.1, US-8.2) — bốn ô số (chạm để mở danh sách
/// tạo nên số), biểu đồ 12 tháng và doanh thu theo lớp; đổi tháng bằng mũi tên
/// hoặc chạm cột của biểu đồ.
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key, this.repository});
  final ReportsRepository? repository;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ReportsCubit(repository ?? reportsRepository())..load(),
    child: const _View(),
  );
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cubit = context.read<ReportsCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportsTitle)),
      body: BlocConsumer<ReportsCubit, ReportsState>(
        listenWhen: (a, b) =>
            b.refreshError != null && a.refreshError != b.refreshError,
        listener: (context, s) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(billingErrorText(l10n, s.refreshError!))),
        ),
        builder: (context, s) => switch (s.load) {
          BillingLoad.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          BillingLoad.failure => AppEmptyState(
            message: s.error == null
                ? l10n.reportsLoadFailed
                : billingErrorText(l10n, s.error!),
            action: AppButton(label: l10n.classesRetry, onPressed: cubit.load),
          ),
          BillingLoad.ready => RefreshIndicator(
            onRefresh: cubit.refresh,
            child: _Report(state: s),
          ),
        },
      ),
    );
  }
}

class _Report extends StatelessWidget {
  const _Report({required this.state});
  final ReportsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final cubit = context.read<ReportsCubit>();
    final o = state.overview!;
    final ym = parseYearMonth(o.month);
    final byClass = state.byClass!;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: l10n.reportsMonthPrev,
              icon: const Icon(Icons.chevron_left),
              onPressed: cubit.previous,
            ),
            Expanded(
              child: Text(
                l10n.billingPeriodMonth(ym.month, ym.year),
                textAlign: TextAlign.center,
                style: text.titleMedium,
              ),
            ),
            IconButton(
              tooltip: l10n.reportsMonthNext,
              icon: const Icon(Icons.chevron_right),
              onPressed: cubit.canGoNext ? cubit.next : null,
            ),
          ],
        ),
        if (!o.hasData) ...[
          const SizedBox(height: AppSpacing.sm),
          AppEmptyState(
            message: l10n.reportsNoData,
            subMessage: l10n.reportsNoDataBody,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _TileRow(
          left: _Tile(
            label: l10n.reportsBilled,
            value: formatVnd(o.billedAmount),
            onTap: () => context.push(BillingRoutes.periods),
          ),
          right: _Tile(
            label: l10n.reportsCollected,
            value: formatVnd(o.collectedAmount),
            onTap: () => context.push(ReportsRoutes.payments(o.month)),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _TileRow(
          left: _Tile(
            label: l10n.reportsOutstanding,
            value: formatVnd(o.outstandingAmount),
            onTap: () => context.push(ReceivablesRoutes.list),
          ),
          // Chưa có danh sách học viên ở app giáo viên để mở (US-8.1 AC3).
          right: _Tile(
            label: l10n.reportsStudents,
            value: '${o.activeStudentCount}',
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(l10n.reportsChartTitle, style: text.titleMedium),
        const SizedBox(height: AppSpacing.md),
        RevenueBarChart(
          months: state.months!.months,
          selected: o.month,
          onSelect: cubit.selectMonth,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.reportsChartSelected(
            ym.month,
            ym.year,
            formatVnd(o.collectedAmount),
          ),
          style: text.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(l10n.reportsByClass, style: text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (byClass.items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(l10n.reportsByClassEmpty, style: text.bodyMedium),
          )
        else
          for (final c in byClass.items) _ClassRow(item: c),
      ],
    );
  }
}

class _TileRow extends StatelessWidget {
  const _TileRow({required this.left, required this.right});
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: left),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: right),
      ],
    ),
  );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, this.onTap});
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: text.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: text.titleLarge),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassRow extends StatelessWidget {
  const _ClassRow({required this.item});
  final ClassRevenue item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final c = item;
    final percent = c.attendancePercent;
    final meta = [
      if (c.archived) l10n.reportsArchived,
      if (percent != null)
        l10n.reportsAttendance(
          // 92.0 → 92; 92.5 → "92,5" (tiếng Việt dùng dấu phẩy thập phân).
          percent == percent.roundToDouble()
              ? '${percent.round()}'
              : Localizations.localeOf(context).languageCode == 'vi'
              ? percent.toStringAsFixed(1).replaceFirst('.', ',')
              : percent.toStringAsFixed(1),
        ),
    ].join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.isOther
                        ? l10n.reportsOtherClass
                        : (c.className ?? l10n.reportsOtherClass),
                    style: text.titleSmall,
                  ),
                  if (c.isOther)
                    Text(l10n.reportsOtherClassHint, style: text.bodySmall),
                  if (meta.isNotEmpty) Text(meta, style: text.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(formatVnd(c.collectedAmount), style: text.titleSmall),
          ],
        ),
      ),
    );
  }
}
