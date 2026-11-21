import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../../l10n/l10n.dart';
import '../../fees/data/fee_models.dart' show formatVnd;
import '../../fees/fees_routes.dart';
import '../billing_routes.dart';
import '../cubit/billing_period_cubit.dart';
import '../cubit/billing_periods_cubit.dart';
import '../data/billing_models.dart';
import '../data/billing_repository.dart';
import '../widgets/billing_error_text.dart';
import '../widgets/invoice_status_label.dart';

/// Bản nháp của một kỳ (T10): số bản nháp, tổng tiền, trạng thái từng hóa đơn
/// và lệnh "Chốt & gửi" (US-7.2 AC4).
class BillingPeriodPage extends StatelessWidget {
  const BillingPeriodPage({super.key, required this.periodId, this.repository});
  final String periodId;
  final BillingRepository? repository;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        BillingPeriodCubit(repository ?? billingRepository(), periodId)..load(),
    child: const _View(),
  );
}

class _View extends StatelessWidget {
  const _View();

  Future<void> _onError(
    BuildContext context,
    ApiException e, {
    bool staleUnverified = false,
  }) async {
    final l10n = context.miniAppL10n;
    final cubit = context.read<BillingPeriodCubit>();
    if (e.code != ApiErrorCode.payoutAccountMissing) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            billingErrorText(l10n, e, staleUnverified: staleUnverified),
          ),
        ),
      );
      return;
    }
    // US-7.3 AC5: chưa có tài khoản nhận tiền → mở màn tài khoản, quay lại chốt tiếp.
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.billingPayoutMissingTitle),
        content: Text(l10n.billingPayoutMissingBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.classesCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.billingPayoutMissingAction),
          ),
        ],
      ),
    );
    if (go == true && context.mounted) {
      await context.push(FeesRoutes.payoutAccounts);
    }
    cubit.clearError();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cubit = context.read<BillingPeriodCubit>();
    return BlocConsumer<BillingPeriodCubit, BillingPeriodState>(
      listenWhen: (a, b) =>
          (b.result != null && a.result != b.result) ||
          (b.load == BillingLoad.ready &&
              b.error != null &&
              a.error != b.error),
      listener: (context, s) {
        if (s.error != null) {
          _onError(context, s.error!, staleUnverified: s.staleUnverified);
          return;
        }
        final r = s.result!;
        final msg = r.issuedCount == 0
            ? l10n.billingIssuedNone
            : l10n.billingIssued(r.issuedCount);
        final zero = r.zeroSkipped == 0
            ? ''
            : ' ${l10n.billingIssuedSkippedZero(r.zeroSkipped)}';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$msg$zero')));
      },
      builder: (context, s) {
        final d = s.detail;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              d == null
                  ? l10n.billingTitle
                  : l10n.billingPeriodMonth(d.period.month, d.period.year),
            ),
          ),
          body: switch (s.load) {
            BillingLoad.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            BillingLoad.failure => AppEmptyState(
              message: s.error == null
                  ? l10n.billingLoadFailed
                  : billingErrorText(l10n, s.error!),
              action: AppButton(
                label: l10n.classesRetry,
                onPressed: cubit.load,
              ),
            ),
            BillingLoad.ready => RefreshIndicator(
              onRefresh: cubit.refresh,
              child: _Body(detail: d!, issuing: s.issuing),
            ),
          },
        );
      },
    );
  }
}

Future<void> _confirmIssue(
  BuildContext context, {
  required String body,
  required String confirmLabel,
  required VoidCallback onConfirm,
}) async {
  final l10n = context.miniAppL10n;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.billingIssueConfirmTitle),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.classesCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  if (ok == true) onConfirm();
}

class _Body extends StatelessWidget {
  const _Body({required this.detail, required this.issuing});
  final BillingPeriodDetail detail;
  final bool issuing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final cubit = context.read<BillingPeriodCubit>();
    final p = detail.period;
    final payable = detail.payableDrafts;
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.billingPeriodDates(
            formatIsoDate(p.closeDate),
            formatIsoDate(p.dueDate),
          ),
          style: text.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.billingDraftSummary(p.draftCount, formatVnd(p.draftTotalAmount)),
          style: text.titleMedium,
        ),
        if (p.issuedCount > 0)
          Text(
            l10n.billingIssuedSummary(
              p.issuedCount,
              formatVnd(p.issuedTotalAmount),
            ),
            style: text.bodyMedium,
          ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: l10n.billingIssueAll,
          width: double.infinity,
          disabled: issuing || payable.isEmpty,
          onPressed: () => _confirmIssue(
            context,
            confirmLabel: l10n.billingIssueAllConfirmAction,
            body: l10n.billingIssueAllConfirmBody(
              payable.length,
              formatVnd(detail.payableTotal),
            ),
            onConfirm: cubit.issueAll,
          ),
        ),
        if (payable.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(l10n.billingNoPayableDrafts, style: text.bodySmall),
          ),
        if (detail.zeroDraftCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              l10n.billingZeroDraftNote(detail.zeroDraftCount),
              style: text.bodySmall,
            ),
          ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
    // Phần đầu là mục 0; mỗi hóa đơn một mục dựng lười, khóa theo id.
    final empty = detail.invoices.isEmpty;
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 1 + (empty ? 1 : detail.invoices.length),
      itemBuilder: (_, i) {
        if (i == 0) return header;
        if (empty) return AppEmptyState(message: l10n.billingInvoicesEmpty);
        final inv = detail.invoices[i - 1];
        return _InvoiceTile(
          key: ValueKey(inv.id),
          invoice: inv,
          issuing: issuing,
        );
      },
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({super.key, required this.invoice, required this.issuing});
  final InvoiceSummary invoice;
  final bool issuing;

  Future<void> _open(BuildContext context) async {
    final cubit = context.read<BillingPeriodCubit>();
    await context.push(BillingRoutes.invoice(invoice.id));
    await cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final i = invoice;
    final cubit = context.read<BillingPeriodCubit>();
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(i.studentName, style: text.titleSmall),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.sm,
                          children: [
                            InvoiceStatusLabel(status: i.status),
                            if (i.hasOverride)
                              Text(
                                l10n.billingHasOverride,
                                style: text.labelMedium,
                              ),
                            if (i.code != null)
                              Text(i.code!, style: text.labelMedium),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(formatVnd(i.totalAmount), style: text.titleSmall),
                ],
              ),
              if (i.isZeroDraft)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(l10n.billingNoSend, style: text.bodySmall),
                ),
              if (i.canRecordPayment)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: AppButton(
                      label: l10n.billingPayRecord,
                      size: AppButtonSize.sm,
                      variant: AppButtonVariant.outlinePrimary,
                      // Tóm tắt của kỳ không có số còn nợ: mở chi tiết hóa đơn,
                      // nơi có "Đã thu đủ" và "Thu một phần".
                      onPressed: () => _open(context),
                    ),
                  ),
                ),
              if (i.isPayableDraft)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: AppButton(
                      label: l10n.billingIssueOne,
                      size: AppButtonSize.sm,
                      disabled: issuing,
                      onPressed: () => _confirmIssue(
                        context,
                        confirmLabel: l10n.billingIssueOne,
                        body: l10n.billingIssueOneConfirmBody(
                          i.studentName,
                          formatVnd(i.totalAmount),
                        ),
                        onConfirm: () => cubit.issueOne(i.id),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
