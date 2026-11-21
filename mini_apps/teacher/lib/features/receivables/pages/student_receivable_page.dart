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
import '../../billing/widgets/invoice_status_label.dart';
import '../../fees/data/fee_models.dart' show formatVnd;
import '../cubit/student_receivable_cubit.dart';
import '../data/receivable_models.dart';
import '../data/receivables_repository.dart';
import '../widgets/dunning_labels.dart';
import '../widgets/dunning_switches.dart';

/// T11: lịch sử hóa đơn, thanh toán, nhắc nợ của một học viên (US-8.3 AC3);
/// mở hóa đơn để ghi thu, bật/tắt nhắc nợ theo lớp (US-7.5 AC3).
class StudentReceivablePage extends StatelessWidget {
  const StudentReceivablePage({
    super.key,
    required this.studentId,
    this.repository,
  });
  final String studentId;
  final ReceivablesRepository? repository;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        StudentReceivableCubit(repository ?? receivablesRepository(), studentId)
          ..load(),
    child: const _View(),
  );
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cubit = context.read<StudentReceivableCubit>();
    return BlocConsumer<StudentReceivableCubit, StudentReceivableState>(
      listenWhen: (a, b) =>
          b.load == BillingLoad.ready && b.error != null && a.error != b.error,
      listener: (context, s) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(billingErrorText(l10n, s.error!)))),
      builder: (context, s) => Scaffold(
        appBar: AppBar(
          title: Text(s.history?.studentName ?? l10n.receivablesDetailTitle),
        ),
        body: switch (s.load) {
          BillingLoad.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          BillingLoad.failure => AppEmptyState(
            message: s.error == null
                ? l10n.receivablesLoadFailed
                : billingErrorText(l10n, s.error!),
            action: AppButton(label: l10n.classesRetry, onPressed: cubit.load),
          ),
          BillingLoad.ready => RefreshIndicator(
            onRefresh: cubit.refresh,
            child: _Body(history: s.history!, toggling: s.toggling),
          ),
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.history, required this.toggling});
  final StudentReceivableHistory history;
  final Set<String> toggling;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final h = history;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          l10n.receivablesRowOwed(formatVnd(h.outstandingAmount)),
          style: text.titleLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.dunningStudentTitle, style: text.titleSmall),
        DunningSwitches(history: h, toggling: toggling),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.receivablesInvoices, style: text.titleSmall),
        if (h.invoices.isEmpty) Text(l10n.receivablesNoInvoices),
        for (final i in h.invoices) _InvoiceTile(invoice: i),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.receivablesPayments, style: text.titleSmall),
        if (h.payments.isEmpty) Text(l10n.receivablesNoPayments),
        for (final p in h.payments) _PaymentTile(payment: p),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.receivablesReminders, style: text.titleSmall),
        if (h.reminders.isEmpty) Text(l10n.receivablesNoReminders),
        for (final r in h.reminders) _ReminderTile(reminder: r),
      ],
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({required this.invoice});
  final ReceivableInvoice invoice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final i = invoice;
    return Card(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      child: InkWell(
        onTap: () async {
          final cubit = context.read<StudentReceivableCubit>();
          await context.push(BillingRoutes.invoice(i.id));
          // Có thể đã ghi thu hoặc hủy thu ở màn hóa đơn.
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
                    Text(
                      l10n.receivablesInvoiceTitle(
                        i.code ?? l10n.receivablesNoCode,
                        i.month,
                        i.year,
                      ),
                      style: text.bodyMedium,
                    ),
                    InvoiceStatusLabel(status: i.status),
                    Text(
                      l10n.receivablesInvoiceDue(formatIsoDate(i.dueDate)),
                      style: text.bodySmall,
                    ),
                    Text(
                      l10n.receivablesInvoiceRemaining(
                        formatVnd(i.remainingAmount),
                        formatVnd(i.totalAmount),
                      ),
                      style: text.bodySmall,
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

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});
  final ReceivablePayment payment;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final p = payment;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.receivablesPaymentLine(
              formatVnd(p.amount),
              paymentMethodText(l10n, p.method),
            ),
            style: text.bodyMedium?.copyWith(
              decoration: p.voided ? TextDecoration.lineThrough : null,
            ),
          ),
          Text(
            [
              l10n.receivablesPaymentDate(formatIsoDate(p.paidOn)),
              if (p.invoiceCode != null) p.invoiceCode!,
              if (p.voided) l10n.receivablesPaymentVoided,
            ].join(' · '),
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.reminder});
  final ReceivableReminder reminder;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final r = reminder;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.receivablesReminderLine(
              dunningOffsetLabel(l10n, r.step.offsetDays),
              r.invoiceCode ?? l10n.receivablesNoCode,
            ),
            style: text.bodyMedium,
          ),
          Text(dunningStepText(l10n, r.step), style: text.bodySmall),
        ],
      ),
    );
  }
}
