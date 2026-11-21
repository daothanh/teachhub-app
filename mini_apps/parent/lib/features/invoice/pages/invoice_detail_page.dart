import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';
import '../cubit/invoice_detail_cubit.dart';
import '../data/invoice_models.dart';
import '../widgets/invoice_format.dart';

/// P03: chi tiết hóa đơn, VietQR, tài khoản nhận (US-7.3 AC1 đến AC3).
class InvoiceDetailPage extends StatelessWidget {
  const InvoiceDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return BlocConsumer<InvoiceDetailCubit, InvoiceDetailState>(
      listenWhen: (a, b) => a.qrSave != b.qrSave,
      listener: (context, state) {
        final msg = switch (state.qrSave) {
          QrSaveStatus.saved => l10n.invoiceQrSaved,
          QrSaveStatus.denied => l10n.invoiceQrDenied,
          QrSaveStatus.failed => l10n.invoiceQrFailed,
          _ => null,
        };
        if (msg == null) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
        context.read<InvoiceDetailCubit>().ackSave();
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text(l10n.invoiceListTitle)),
        body: switch (state.status) {
          InvoiceDetailStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          InvoiceDetailStatus.notFound => AppEmptyState(
            message: l10n.invoiceNotFound,
            subMessage: l10n.invoiceNotFoundBody,
          ),
          InvoiceDetailStatus.failure => AppEmptyState(
            message: l10n.invoiceLoadFailed,
            action: AppButton(
              label: l10n.parentRetry,
              onPressed: context.read<InvoiceDetailCubit>().load,
            ),
          ),
          InvoiceDetailStatus.ready => _Detail(invoice: state.invoice!),
        },
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.invoice});

  final InvoiceDetail invoice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final theme = Theme.of(context);
    final s = invoice.summary;
    final payout = invoice.payout;
    final qr = invoice.qrPayload;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.invoiceRowSubtitle(
            s.studentName,
            formatMonth(context, s.periodMonth),
          ),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          '${l10n.invoiceCodeLabel(s.code)} · ${s.teacherName}',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(label: Text(statusLabel(context, s.status))),
            Text(l10n.invoiceDue(formatDate(context, s.dueDate))),
          ],
        ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(
            l10n.invoiceLinesTitle,
            style: theme.textTheme.titleMedium,
          ),
        ),
        for (final l in invoice.lines)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.description),
            subtitle: l.className == null ? null : Text(l.className!),
            trailing: Text(formatVnd(context, l.amount)),
          ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.invoiceTotal, style: theme.textTheme.titleMedium),
          trailing: Text(
            formatVnd(context, s.totalAmount),
            style: theme.textTheme.titleMedium,
          ),
        ),
        if (s.status != InvoiceStatus.voided) ...[
          if (s.paidAmount > 0)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.invoicePaidAmount),
              trailing: Text(formatVnd(context, s.paidAmount)),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.invoiceRemainingAmount,
              style: theme.textTheme.titleMedium,
            ),
            trailing: Text(
              formatVnd(context, s.remainingAmount),
              style: theme.textTheme.titleMedium,
            ),
          ),
        ],
        if (invoice.payments.isNotEmpty) _Receipts(payments: invoice.payments),
        const SizedBox(height: 16),
        // Hóa đơn hủy: qrPayload và payout đều null, chỉ báo đã hủy. Đã thu đủ
        // thì không còn kêu gọi chuyển khoản.
        if (s.status == InvoiceStatus.voided)
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.invoiceVoidNotice),
            ),
          )
        else if (s.status == InvoiceStatus.paid)
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.invoicePaidNotice),
            ),
          )
        else if (qr != null || payout != null)
          _Pay(invoice: invoice),
      ],
    );
  }
}

/// Biên nhận từng lần thu (US-7.4 AC3); thanh toán đã hủy gạch và có nhãn.
class _Receipts extends StatelessWidget {
  const _Receipts({required this.payments});

  final List<InvoicePayment> payments;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Semantics(
          header: true,
          child: Text(
            l10n.invoiceReceiptsTitle,
            style: theme.textTheme.titleMedium,
          ),
        ),
        for (final p in payments)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              formatVnd(context, p.amount),
              style: p.voided
                  ? const TextStyle(decoration: TextDecoration.lineThrough)
                  : null,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.invoiceReceiptLine(
                    paymentMethodLabel(context, p.method),
                    formatDate(context, p.paidOn),
                  ),
                ),
                if (p.voided)
                  Text(
                    l10n.invoiceReceiptVoided,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Pay extends StatelessWidget {
  const _Pay({required this.invoice});

  final InvoiceDetail invoice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final theme = Theme.of(context);
    final payout = invoice.payout;
    final qr = invoice.qrPayload;
    final saving =
        context.watch<InvoiceDetailCubit>().state.qrSave == QrSaveStatus.saving;
    Future<void> copy(String text) async {
      final messenger = ScaffoldMessenger.of(context);
      final done = l10n.invoiceCopied;
      await Clipboard.setData(ClipboardData(text: text));
      messenger.showSnackBar(SnackBar(content: Text(done)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.invoicePayTitle, style: theme.textTheme.titleMedium),
        ),
        const SizedBox(height: 8),
        if (qr != null) ...[
          Center(
            child: Semantics(
              label: l10n.invoiceQrHint,
              image: true,
              child: ExcludeSemantics(
                // Nền trắng cứng để app ngân hàng quét được cả ở chế độ tối.
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: QrImageView(
                    data: qr,
                    size: 220,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(child: Text(l10n.invoiceQrHint)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: saving
                ? null
                : context.read<InvoiceDetailCubit>().saveQr,
            icon: const Icon(Icons.download),
            label: Text(l10n.invoiceSaveQr),
          ),
        ],
        const SizedBox(height: 8),
        if (payout != null) ...[
          _Info(l10n.invoiceBank, payout.bankName ?? payout.bankBin),
          _Info(l10n.invoiceAccountNo, payout.accountNo),
          _Info(l10n.invoiceAccountName, payout.accountName),
        ],
        _Info(l10n.invoiceTransferNote, invoice.transferNote),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => copy(invoice.transferNote),
          icon: const Icon(Icons.copy),
          label: Text(l10n.invoiceCopyNote),
        ),
        if (payout != null)
          OutlinedButton.icon(
            onPressed: () => copy(payout.accountNo),
            icon: const Icon(Icons.copy),
            label: Text(l10n.invoiceCopyAccount),
          ),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          SelectableText(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
