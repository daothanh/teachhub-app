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

/// Nhãn trạng thái của một hóa đơn: hóa đơn đã chuyển nợ hay đã trừ vào số dư
/// có nhãn riêng thay cho "Chưa thanh toán"/"Đã thanh toán".
String invoiceStatusLabel(BuildContext context, InvoiceSummary i) {
  final l10n = context.miniAppL10n;
  if (i.isCarriedOver) return l10n.invoiceStatusCarried;
  if (i.isCoveredByBalance) return l10n.invoiceStatusCovered;
  return statusLabel(context, i.status);
}

/// Nhãn dòng hóa đơn: dòng số dư kỳ trước có nhãn cố định theo loại và dấu.
String invoiceLineLabel(BuildContext context, InvoiceLine l) {
  final l10n = context.miniAppL10n;
  return switch (l.kind) {
    'carry_over' when l.amount < 0 => l10n.invoiceLineCarryCredit,
    'carry_over' => l10n.invoiceLineCarryDebt,
    'prev_adjustment' => l10n.invoiceLinePrevAdjustment,
    _ => l.description,
  };
}

String paymentMethodLabel(BuildContext context, PaymentMethod m) {
  final l10n = context.miniAppL10n;
  return switch (m) {
    PaymentMethod.bankTransfer => l10n.invoiceMethodBank,
    PaymentMethod.cash => l10n.invoiceMethodCash,
  };
}
