import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../data/billing_models.dart';

String invoiceStatusText(MiniAppLocalizations l10n, InvoiceStatus s) =>
    switch (s) {
      InvoiceStatus.draft => l10n.billingStatusDraft,
      InvoiceStatus.issued => l10n.billingStatusIssued,
      InvoiceStatus.pendingConfirmation => l10n.billingStatusPending,
      InvoiceStatus.partiallyPaid => l10n.billingStatusPartial,
      InvoiceStatus.paid => l10n.billingStatusPaid,
      InvoiceStatus.voided => l10n.billingStatusVoid,
    };

/// Nhãn trạng thái hóa đơn, chữ đậm theo tông màu.
class InvoiceStatusLabel extends StatelessWidget {
  const InvoiceStatusLabel({super.key, required this.status});
  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      InvoiceStatus.draft => scheme.onSurfaceVariant,
      InvoiceStatus.voided => scheme.error,
      _ => scheme.primary,
    };
    return Text(
      invoiceStatusText(context.miniAppL10n, status),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}
