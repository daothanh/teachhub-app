import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/l10n.dart';
import '../data/invoice_models.dart';

/// `150.000 đ` (locale vi), `-50.000 đ` cho dòng giảm trừ.
String formatVndFor(String locale, int amount) =>
    '${NumberFormat.decimalPattern(locale).format(amount)} đ';

String formatVnd(BuildContext context, int amount) =>
    formatVndFor(Localizations.localeOf(context).toString(), amount);

String formatDate(BuildContext context, DateTime d) =>
    DateFormat.yMd(Localizations.localeOf(context).toString()).format(d);

String formatMonth(BuildContext context, DateTime d) =>
    DateFormat.yM(Localizations.localeOf(context).toString()).format(d);

String statusLabel(BuildContext context, InvoiceStatus s) {
  final l10n = context.miniAppL10n;
  return switch (s) {
    InvoiceStatus.issued => l10n.invoiceStatusIssued,
    InvoiceStatus.pendingConfirmation => l10n.invoiceStatusPending,
    InvoiceStatus.partiallyPaid => l10n.invoiceStatusPartial,
    InvoiceStatus.paid => l10n.invoiceStatusPaid,
    InvoiceStatus.voided => l10n.invoiceStatusVoid,
    InvoiceStatus.unknown => l10n.invoiceStatusUnknown,
  };
}
