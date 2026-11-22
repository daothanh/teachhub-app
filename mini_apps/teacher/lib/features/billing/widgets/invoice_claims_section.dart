import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';
import '../../fees/data/fee_models.dart' show formatVnd;
import '../cubit/billing_periods_cubit.dart' show BillingLoad;
import '../cubit/invoice_cubit.dart';
import '../cubit/payment_claims_cubit.dart';
import '../data/billing_models.dart' show formatIsoDateTime;
import '../data/billing_repository.dart';
import '../data/claim_models.dart';
import 'billing_error_text.dart';
import 'claim_dialogs.dart';
import 'receipt_viewer.dart';

String claimStatusText(MiniAppLocalizations l10n, ClaimStatus s) => switch (s) {
  ClaimStatus.pending => l10n.claimStatusPending,
  ClaimStatus.confirmed => l10n.claimStatusConfirmed,
  ClaimStatus.rejected => l10n.claimStatusRejected,
};

/// Khối "Phụ huynh báo đã chuyển khoản" trên chi tiết hóa đơn đã phát hành
/// (US-7.7): các lần báo, xem biên lai, xác nhận (sửa được số tiền) hoặc từ
/// chối có lý do. Tự tải; chỉ hiện khi có ít nhất một lần báo hoặc khi lỗi.
class InvoiceClaimsSection extends StatelessWidget {
  const InvoiceClaimsSection({super.key, required this.invoiceId});
  final String invoiceId;

  @override
  Widget build(BuildContext context) {
    final invoice = context.read<InvoiceCubit>();
    return BlocProvider(
      create: (_) => PaymentClaimsCubit(invoice.repository, invoiceId)..load(),
      child: _View(repository: invoice.repository),
    );
  }
}

class _View extends StatelessWidget {
  const _View({required this.repository});
  final BillingRepository repository;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return BlocConsumer<PaymentClaimsCubit, PaymentClaimsState>(
      listenWhen: (a, b) =>
          (b.done != null && a.done != b.done) ||
          (b.error != null &&
              b.load == BillingLoad.ready &&
              a.error != b.error) ||
          b.invoiceChanged != a.invoiceChanged,
      listener: (context, s) {
        if (s.invoiceChanged > 0) context.read<InvoiceCubit>().refresh();
        final msg = s.error != null
            ? billingErrorText(
                l10n,
                s.error!,
                staleUnverified: s.staleUnverified,
              )
            : switch (s.done) {
                ClaimDone.confirmed => l10n.claimConfirmedDone,
                ClaimDone.rejected => l10n.claimRejectedDone,
                null => null,
              };
        if (msg != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
      },
      builder: (context, s) {
        final text = Theme.of(context).textTheme;
        if (s.load == BillingLoad.ready && s.claims.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: AppSpacing.xl),
            Semantics(
              header: true,
              child: Text(l10n.claimsTitle, style: text.titleSmall),
            ),
            const SizedBox(height: AppSpacing.xs),
            switch (s.load) {
              BillingLoad.loading => const Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: Center(child: CircularProgressIndicator()),
              ),
              BillingLoad.failure => Row(
                children: [
                  Expanded(
                    child: Text(l10n.claimsLoadFailed, style: text.bodyMedium),
                  ),
                  TextButton(
                    onPressed: context.read<PaymentClaimsCubit>().load,
                    child: Text(l10n.classesRetry),
                  ),
                ],
              ),
              BillingLoad.ready => Column(
                children: [
                  for (final c in s.claims)
                    _ClaimCard(claim: c, busy: s.busy, repository: repository),
                ],
              ),
            },
          ],
        );
      },
    );
  }
}

class _ClaimCard extends StatelessWidget {
  const _ClaimCard({
    required this.claim,
    required this.busy,
    required this.repository,
  });
  final PaymentClaim claim;
  final bool busy;
  final BillingRepository repository;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final c = claim;
    return Card(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l10n.claimLine(
                    c.claimedByName,
                    formatIsoDateTime(c.createdAt),
                  ),
                  style: text.bodyMedium,
                ),
                Text(
                  claimStatusText(l10n, c.status),
                  style: text.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: c.status == ClaimStatus.rejected
                        ? scheme.error
                        : scheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.claimAmount(formatVnd(c.amount)), style: text.titleSmall),
            if (c.note != null && c.note!.isNotEmpty)
              Text(l10n.claimNote(c.note!), style: text.bodySmall),
            if (c.status == ClaimStatus.rejected && c.rejectReason != null)
              Text(
                l10n.claimRejectedReason(c.rejectReason!),
                style: text.bodySmall,
              ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: l10n.claimViewReceipt,
              variant: AppButtonVariant.outlinePrimary,
              width: double.infinity,
              onPressed: () => showDialog<void>(
                context: context,
                useSafeArea: false,
                builder: (_) => ReceiptViewer(
                  repository: repository,
                  fileId: c.receiptFileId,
                ),
              ),
            ),
            if (c.isPending) ...[
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: l10n.claimConfirm,
                width: double.infinity,
                disabled: busy,
                onPressed: () => _confirm(context, c),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: l10n.claimReject,
                variant: AppButtonVariant.outlinePrimary,
                width: double.infinity,
                disabled: busy,
                onPressed: () => _reject(context, c),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> _confirm(BuildContext context, PaymentClaim c) async {
  final cubit = context.read<PaymentClaimsCubit>();
  final amount = await showDialog<int>(
    context: context,
    builder: (_) => ClaimConfirmDialog(claim: c),
  );
  if (amount != null) await cubit.confirm(c, amount);
}

Future<void> _reject(BuildContext context, PaymentClaim c) async {
  final cubit = context.read<PaymentClaimsCubit>();
  final reason = await showDialog<String>(
    context: context,
    builder: (_) => const ClaimRejectDialog(),
  );
  if (reason != null) await cubit.reject(c, reason);
}
