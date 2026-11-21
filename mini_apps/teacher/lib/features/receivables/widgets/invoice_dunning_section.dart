import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';
import '../../billing/cubit/billing_periods_cubit.dart' show BillingLoad;
import '../cubit/invoice_dunning_cubit.dart';
import '../data/receivable_models.dart';
import '../data/receivables_repository.dart';
import '../../billing/data/billing_models.dart' show formatIsoDateTime;
import 'dunning_labels.dart';

/// Khối nhắc nợ trên chi tiết hóa đơn (US-7.5): đã nhắc lúc nào, lần nhắc tới,
/// hoặc vì sao không còn nhắc. Tự tải; lỗi chỉ hiện trong khối này.
class InvoiceDunningSection extends StatelessWidget {
  const InvoiceDunningSection({
    super.key,
    required this.invoiceId,
    this.repository,
  });
  final String invoiceId;
  final ReceivablesRepository? repository;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        InvoiceDunningCubit(repository ?? receivablesRepository(), invoiceId)
          ..load(),
    child: const _View(),
  );
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: AppSpacing.xl),
        Text(l10n.invoiceDunningTitle, style: text.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        BlocBuilder<InvoiceDunningCubit, InvoiceDunningState>(
          builder: (context, s) => switch (s.load) {
            BillingLoad.loading => const Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: Center(child: CircularProgressIndicator()),
            ),
            BillingLoad.failure => Row(
              children: [
                Expanded(
                  child: Text(l10n.dunningLoadFailed, style: text.bodyMedium),
                ),
                TextButton(
                  onPressed: context.read<InvoiceDunningCubit>().load,
                  child: Text(l10n.classesRetry),
                ),
              ],
            ),
            BillingLoad.ready => _Steps(dunning: s.dunning!),
          },
        ),
      ],
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.dunning});
  final InvoiceDunning dunning;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final d = dunning;
    final last = d.lastSent;
    final next = d.next;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (d.disabledReason != null)
          Text(
            dunningReasonText(l10n, d.disabledReason!),
            style: text.bodyMedium,
          ),
        Text(
          last == null
              ? l10n.invoiceDunningNone
              : l10n.invoiceDunningLastSent(
                  formatIsoDateTime(last.sentAt ?? last.scheduledFor),
                ),
          style: text.bodyMedium,
        ),
        if (next != null)
          Text(
            l10n.invoiceDunningNext(formatIsoDateTime(next.scheduledFor)),
            style: text.bodyMedium,
          ),
        for (final s in d.steps)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              '${dunningOffsetLabel(l10n, s.offsetDays)} · ${dunningStepText(l10n, s)}',
              style: text.bodySmall,
            ),
          ),
      ],
    );
  }
}
