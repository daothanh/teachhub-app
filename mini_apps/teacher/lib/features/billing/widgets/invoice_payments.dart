import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';
import '../../fees/data/fee_models.dart'
    show VndInputFormatter, formatVnd, parseVnd;
import '../cubit/invoice_cubit.dart';
import '../data/billing_models.dart';
import 'billing_error_text.dart';
import 'void_reason_dialog.dart';

String paymentMethodText(MiniAppLocalizations l10n, PaymentMethod m) =>
    switch (m) {
      PaymentMethod.bankTransfer => l10n.billingPayMethodBank,
      PaymentMethod.cash => l10n.billingPayMethodCash,
    };

/// Khối thanh toán trên chi tiết hóa đơn (US-7.4): đã thu, còn nợ, "Đã thu đủ",
/// "Thu một phần" và danh sách các lần thu (ai ghi, khi nào; hủy có lý do).
class InvoicePaymentsSection extends StatelessWidget {
  const InvoicePaymentsSection({
    super.key,
    required this.invoice,
    required this.payments,
    required this.busy,
  });
  final Invoice invoice;
  final List<Payment> payments;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    if (invoice.status == InvoiceStatus.draft) return const SizedBox.shrink();
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final inv = invoice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: AppSpacing.xl),
        if (inv.status != InvoiceStatus.voided) ...[
          _AmountRow(l10n.billingPaidAmount, inv.paidAmount),
          const SizedBox(height: AppSpacing.xs),
          _AmountRow(
            l10n.billingRemainingAmount,
            inv.remainingAmount,
            bold: true,
          ),
        ],
        if (inv.canRecordPayment) ...[
          const SizedBox(height: AppSpacing.md),
          if (inv.remainingAmount > 0)
            AppButton(
              label: l10n.billingPayFull,
              width: double.infinity,
              disabled: busy,
              onPressed: () => _openFull(context),
            ),
          if (inv.remainingAmount > 0) const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: l10n.billingPayPartial,
            variant: AppButtonVariant.outlinePrimary,
            width: double.infinity,
            disabled: busy,
            onPressed: () => showPaymentSheet(context, full: false),
          ),
        ],
        if (payments.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.billingPaymentsTitle, style: text.titleSmall),
          for (final p in payments) _PaymentTile(payment: p, busy: busy),
        ],
      ],
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow(this.label, this.amount, {this.bold = false});
  final String label;
  final int amount;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(formatVnd(amount), style: style),
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment, required this.busy});
  final Payment payment;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final p = payment;
    final when = formatIsoDateTime(p.recordedAt);
    final reason = p.voidReason ?? l10n.billingNoReason;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatVnd(p.amount),
            style: text.titleSmall?.copyWith(
              decoration: p.isVoided ? TextDecoration.lineThrough : null,
            ),
          ),
          Text(
            l10n.billingPaymentLine(
              paymentMethodText(l10n, p.method),
              formatIsoDate(p.paidOn),
            ),
            style: text.bodyMedium,
          ),
          Text(
            p.recordedBy == null
                ? l10n.billingPaymentAt(when)
                : l10n.billingPaymentBy(p.recordedBy!.name, when),
            style: text.bodySmall,
          ),
          if (p.isVoided) ...[
            Text(
              l10n.billingPaymentVoidedLabel,
              style: text.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.error,
              ),
            ),
            Text(
              p.voidedBy == null
                  ? l10n.billingPaymentVoidedReason(reason)
                  : l10n.billingPaymentVoidedBy(p.voidedBy!.name, reason),
              style: text.bodySmall,
            ),
          ] else
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: busy ? null : () => _openVoidPayment(context, p),
                child: Text(l10n.billingPaymentVoidAction),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Đã thu đủ": tải lại hóa đơn trước, để sheet hiện số còn nợ mới nhất.
Future<void> _openFull(BuildContext context) async {
  final ok = await context.read<InvoiceCubit>().reloadForPayment();
  if (ok && context.mounted) await showPaymentSheet(context, full: true);
}

Future<void> _openVoidPayment(BuildContext context, Payment p) async {
  final l10n = context.miniAppL10n;
  final cubit = context.read<InvoiceCubit>();
  final reason = await showDialog<String>(
    context: context,
    builder: (_) => VoidReasonDialog(
      title: l10n.billingPaymentVoidTitle,
      body: l10n.billingPaymentVoidBody(formatVnd(p.amount)),
      confirmLabel: l10n.billingPaymentVoidAction,
    ),
  );
  if (reason != null) await cubit.voidPayment(p.id, reason);
}

/// Form ghi thanh toán. [full]: số tiền cố định bằng số còn nợ ("Đã thu đủ",
/// một chạm rồi xác nhận); không thì nhập số tiền ("Thu một phần").
Future<void> showPaymentSheet(BuildContext context, {required bool full}) {
  final cubit = context.read<InvoiceCubit>()..clearErrors();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _PaymentSheet(full: full),
    ),
  );
}

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({required this.full});
  final bool full;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final _amount = TextEditingController();
  final _date = TextEditingController();
  final _note = TextEditingController();
  PaymentMethod _method = PaymentMethod.bankTransfer;
  late String _paidOn;

  /// "Đã thu đủ": số còn nợ người dùng đang thấy và sẽ xác nhận.
  late int _expected;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<InvoiceCubit>();
    _expected = cubit.state.invoice!.remainingAmount;
    _paidOn = cubit.today;
    _date.text = formatIsoDate(_paidOn);
  }

  @override
  void dispose() {
    _amount.dispose();
    _date.dispose();
    _note.dispose();
    super.dispose();
  }

  int get _value => widget.full ? _expected : (parseVnd(_amount.text) ?? 0);

  Future<void> _pickDate() async {
    final last = DateTime.parse(context.read<InvoiceCubit>().today);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_paidOn),
      firstDate: DateTime(2020),
      lastDate: last,
    );
    if (picked == null) return;
    String two(int n) => n.toString().padLeft(2, '0');
    setState(() {
      _paidOn = '${picked.year}-${two(picked.month)}-${two(picked.day)}';
      _date.text = formatIsoDate(_paidOn);
    });
  }

  String? _error(InvoiceState s, String field, String clientText) {
    final server = s.serverErrors[field];
    if (server != null && server.isNotEmpty) return server.join('\n');
    return s.payClientErrors.contains(field) ? clientText : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    return BlocConsumer<InvoiceCubit, InvoiceState>(
      listenWhen: (a, b) =>
          (b.done == InvoiceDone.paymentRecorded && a.done != b.done) ||
          (b.notice != null && a.notice != b.notice),
      listener: (context, s) {
        if (s.notice == PayNotice.remainingChanged) {
          // Hiện số mới, chờ người dùng xác nhận lại; chưa gửi gì.
          setState(() => _expected = s.invoice!.remainingAmount);
        } else {
          // Đã ghi xong, hoặc hóa đơn không còn ghi được (trang báo trạng thái).
          Navigator.pop(context);
        }
      },
      builder: (context, s) {
        final inv = s.invoice!;
        final amount = _value;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.full
                      ? l10n.billingPayFullTitle
                      : l10n.billingPayPartialTitle,
                  style: text.titleMedium,
                ),
                if (s.error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppBanner(
                    tone: AppStatusTone.error,
                    description: billingErrorText(
                      l10n,
                      s.error!,
                      staleUnverified: s.staleUnverified,
                    ),
                    fullWidth: true,
                  ),
                ],
                if (s.notice == PayNotice.remainingChanged) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppBanner(
                    tone: AppStatusTone.warning,
                    description: l10n.billingPayRemainingChanged(
                      formatVnd(_expected),
                    ),
                    fullWidth: true,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                if (widget.full) ...[
                  Text(l10n.billingPayAmount, style: text.bodySmall),
                  Text(formatVnd(amount), style: text.headlineSmall),
                ] else ...[
                  AppInput(
                    controller: _amount,
                    label: l10n.billingPayAmount,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [VndInputFormatter()],
                    onChanged: (_) => setState(() {}),
                    errorText: _error(s, 'amount', l10n.billingErrPayAmount),
                  ),
                  if (amount > inv.remainingAmount)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        l10n.billingPayOverHint,
                        style: text.bodySmall,
                      ),
                    ),
                ],
                const SizedBox(height: AppSpacing.md),
                Text(l10n.billingPayMethod, style: text.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final m in PaymentMethod.values)
                      AppChoiceChip(
                        label: paymentMethodText(l10n, m),
                        selected: _method == m,
                        onTap: () => setState(() => _method = m),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppInput(
                  controller: _date,
                  label: l10n.billingPayDate,
                  readOnly: true,
                  onTap: _pickDate,
                  errorText: s.serverErrors.containsKey('paidOn')
                      ? l10n.billingErrPayDateVn
                      : _error(s, 'paidOn', l10n.billingErrPayDate),
                ),
                const SizedBox(height: AppSpacing.md),
                AppInput(
                  controller: _note,
                  label: l10n.billingPayNote,
                  maxLines: 2,
                  maxLength: paymentNoteMax,
                  errorText: _error(s, 'note', l10n.billingErrPayNote),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: l10n.billingPayConfirm,
                  width: double.infinity,
                  disabled:
                      s.busy || !inv.canRecordPayment || s.staleUnverified,
                  onPressed: () => context.read<InvoiceCubit>().recordPayment(
                    PaymentInput(
                      amount: amount,
                      method: _method,
                      paidOn: _paidOn,
                      note: _note.text,
                    ),
                    expectedRemaining: widget.full ? _expected : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
