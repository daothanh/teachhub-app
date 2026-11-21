import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';
import '../../billing/billing_routes.dart';
import '../../billing/cubit/billing_periods_cubit.dart' show BillingLoad;
import '../../billing/data/billing_models.dart' show formatIsoDate;
import '../../billing/widgets/billing_error_text.dart';
import '../../billing/widgets/invoice_payments.dart' show paymentMethodText;
import '../../fees/data/fee_models.dart' show formatVnd;
import '../cubit/report_payments_cubit.dart';
import '../data/report_models.dart';
import '../data/reports_repository.dart';

/// Danh sách khoản thu tạo nên ô "Đã thu" của một tháng (US-8.1 AC2–AC3): tổng
/// ở đầu danh sách bằng đúng số "Đã thu" của tổng quan; chạm dòng mở hóa đơn.
class ReportPaymentsPage extends StatelessWidget {
  const ReportPaymentsPage({super.key, required this.month, this.repository});

  /// `YYYY-MM` của tháng đang xem ở tổng quan.
  final String month;
  final ReportsRepository? repository;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        ReportPaymentsCubit(repository ?? reportsRepository(), month: month)
          ..load(),
    child: const _View(),
  );
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cubit = context.read<ReportPaymentsCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportsPaymentsTitle)),
      body: BlocConsumer<ReportPaymentsCubit, ReportPaymentsState>(
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
                ? l10n.reportsPaymentsLoadFailed
                : billingErrorText(l10n, s.error!),
            action: AppButton(label: l10n.classesRetry, onPressed: cubit.load),
          ),
          BillingLoad.ready when s.items.isEmpty => AppEmptyState(
            message: l10n.reportsPaymentsEmpty,
          ),
          BillingLoad.ready => RefreshIndicator(
            onRefresh: cubit.refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: 1 + s.items.length + (s.hasMore ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(
                      l10n.reportsPaymentsTotal(formatVnd(s.totalAmount)),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  );
                }
                if (i <= s.items.length) {
                  return _EntryCard(entry: s.items[i - 1]);
                }
                return s.moreFailed
                    ? _MoreFailed(onRetry: cubit.loadMore)
                    : _AutoLoadMore(state: s);
              },
            ),
          ),
        },
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});
  final RevenueEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final e = entry;
    final reversal = e.kind == RevenueEntryKind.reversal;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => context.push(BillingRoutes.invoice(e.invoiceId)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.studentName, style: text.titleSmall),
                    Text(
                      l10n.reportsEntryMeta(
                        formatIsoDate(e.entryDate),
                        paymentMethodText(l10n, e.method),
                        e.invoiceCode ?? l10n.receivablesNoCode,
                      ),
                      style: text.bodySmall,
                    ),
                    if (reversal)
                      Text(
                        l10n.reportsReversal,
                        style: text.labelMedium?.copyWith(color: scheme.error),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                formatVnd(e.amount),
                style: text.titleSmall?.copyWith(
                  color: reversal ? scheme.error : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cuối danh sách: mỗi lần dựng hoặc state đổi mà vẫn hiện (vd. làm mới đang
/// chặn lần gọi trước) thì xin tải trang kế; cubit tự bỏ qua khi đang bận.
class _AutoLoadMore extends StatefulWidget {
  const _AutoLoadMore({required this.state});
  final ReportPaymentsState state;

  @override
  State<_AutoLoadMore> createState() => _AutoLoadMoreState();
}

class _AutoLoadMoreState extends State<_AutoLoadMore> {
  @override
  void initState() {
    super.initState();
    _ask();
  }

  @override
  void didUpdateWidget(_AutoLoadMore old) {
    super.didUpdateWidget(old);
    _ask();
  }

  void _ask() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) context.read<ReportPaymentsCubit>().loadMore();
  });

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
