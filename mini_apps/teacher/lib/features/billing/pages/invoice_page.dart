import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';
import '../../fees/data/fee_models.dart' show VndInputFormatter, parseVnd;
import '../cubit/billing_periods_cubit.dart';
import '../cubit/invoice_cubit.dart';
import '../data/billing_models.dart';
import '../data/billing_repository.dart';
import '../widgets/billing_error_text.dart';
import '../widgets/invoice_status_label.dart';

/// Chi tiết hóa đơn (US-7.2 AC2): từng buổi tính hay không và lý do, dòng giá
/// riêng, miễn giảm, điều chỉnh; bản nháp thêm được điều chỉnh (AC3), hóa đơn
/// đã phát hành hủy được có lý do (US-7.3 AC4).
class InvoicePage extends StatelessWidget {
  const InvoicePage({super.key, required this.invoiceId, this.repository});
  final String invoiceId;
  final BillingRepository? repository;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        InvoiceCubit(repository ?? billingRepository(), invoiceId)..load(),
    child: const _View(),
  );
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cubit = context.read<InvoiceCubit>();
    return BlocConsumer<InvoiceCubit, InvoiceState>(
      listenWhen: (a, b) =>
          (b.done != null && a.done != b.done) ||
          // Lỗi của lệnh ghi ngoài form điều chỉnh (hủy hóa đơn).
          (b.load == BillingLoad.ready &&
              b.error != null &&
              a.error != b.error),
      listener: (context, s) {
        final msg = s.voidError != null
            ? billingErrorText(l10n, s.voidError!)
            : s.done == InvoiceDone.voided
            ? l10n.billingVoided
            : l10n.billingAdjusted;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
      builder: (context, s) => Scaffold(
        appBar: AppBar(title: Text(l10n.billingInvoiceTitle)),
        body: switch (s.load) {
          BillingLoad.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          BillingLoad.failure => AppEmptyState(
            message: s.error == null
                ? l10n.billingLoadFailed
                : billingErrorText(l10n, s.error!),
            action: AppButton(label: l10n.classesRetry, onPressed: cubit.load),
          ),
          BillingLoad.ready => _Body(invoice: s.invoice!, busy: s.busy),
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.invoice, required this.busy});
  final Invoice invoice;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final inv = invoice;
    final sessions = inv.sessionLines;
    final others = inv.otherLines;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(inv.studentName, style: text.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.billingPeriodMonth(inv.month, inv.year),
          style: text.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            InvoiceStatusLabel(status: inv.status),
            if (inv.code != null) Text(inv.code!, style: text.labelMedium),
          ],
        ),
        if (inv.status == InvoiceStatus.voided) ...[
          const SizedBox(height: AppSpacing.md),
          AppBanner(
            tone: AppStatusTone.warning,
            description: l10n.billingVoidedBanner(inv.voidReason ?? '—'),
            fullWidth: true,
          ),
        ],
        if (sessions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.billingLinesSessions, style: text.titleSmall),
          for (final l in sessions) _SessionLine(line: l),
        ],
        if (others.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.billingLinesOther, style: text.titleSmall),
          for (final l in others) _OtherLine(line: l),
        ],
        const Divider(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(child: Text(l10n.billingTotal, style: text.titleMedium)),
            Text(formatSignedVnd(inv.totalAmount), style: text.titleMedium),
          ],
        ),
        if (inv.clampedAmount > 0)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              l10n.billingClamped(formatSignedVnd(inv.clampedAmount)),
              style: text.bodySmall,
            ),
          ),
        if (inv.status == InvoiceStatus.draft) ...[
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: l10n.billingAddAdjustment,
            variant: AppButtonVariant.outlinePrimary,
            width: double.infinity,
            disabled: busy,
            onPressed: () => _openAdjustSheet(context),
          ),
        ],
        if (inv.status.isLive) ...[
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: l10n.billingVoid,
            variant: AppButtonVariant.outlinePrimary,
            width: double.infinity,
            disabled: busy,
            onPressed: () => _openVoidDialog(context),
          ),
        ],
      ],
    );
  }
}

String _reasonText(MiniAppLocalizations l10n, NotChargedReason? r) =>
    switch (r) {
      NotChargedReason.excused => l10n.billingReasonExcused,
      NotChargedReason.unexcused => l10n.billingReasonUnexcused,
      NotChargedReason.cancelled => l10n.billingReasonCancelled,
      NotChargedReason.makeup => l10n.billingReasonMakeup,
      _ => l10n.billingReasonOther,
    };

class _SessionLine extends StatelessWidget {
  const _SessionLine({required this.line});
  final InvoiceLine line;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final l = line;
    final date = l.sessionDate == null ? '' : formatIsoDate(l.sessionDate!);
    final title = l.className == null || l.className!.isEmpty
        ? date
        : l10n.billingSessionLine(date, l.className!);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.bodyMedium),
                Text(
                  l.charged
                      ? l10n.billingSessionCharged
                      : l10n.billingSessionNotCharged(
                          _reasonText(l10n, l.notChargedReason),
                        ),
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(formatSignedVnd(l.amount), style: text.bodyMedium),
        ],
      ),
    );
  }
}

class _OtherLine extends StatelessWidget {
  const _OtherLine({required this.line});
  final InvoiceLine line;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final l = line;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.description, style: text.bodyMedium),
                if (l.className != null && l.className!.isNotEmpty)
                  Text(l.className!, style: text.bodySmall),
                if (l.adjustmentReason != null)
                  Text(
                    l10n.billingAdjustmentReasonLine(l.adjustmentReason!),
                    style: text.bodySmall,
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(formatSignedVnd(l.amount, plus: true), style: text.bodyMedium),
        ],
      ),
    );
  }
}

Future<void> _openVoidDialog(BuildContext context) async {
  final cubit = context.read<InvoiceCubit>();
  final reason = await showDialog<String>(
    context: context,
    builder: (_) => const _VoidDialog(),
  );
  if (reason != null) await cubit.voidInvoice(reason);
}

class _VoidDialog extends StatefulWidget {
  const _VoidDialog();

  @override
  State<_VoidDialog> createState() => _VoidDialogState();
}

class _VoidDialogState extends State<_VoidDialog> {
  final _reason = TextEditingController();
  bool _invalid = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return AlertDialog(
      title: Text(l10n.billingVoidTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.billingVoidBody),
            const SizedBox(height: AppSpacing.md),
            AppInput(
              controller: _reason,
              label: l10n.billingVoidReason,
              maxLines: 3,
              errorText: _invalid ? l10n.billingErrReason : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.billingVoidKeep),
        ),
        TextButton(
          onPressed: () {
            final r = _reason.text.trim();
            if (r.isEmpty || r.length > voidReasonMax) {
              setState(() => _invalid = true);
              return;
            }
            Navigator.pop(context, r);
          },
          child: Text(l10n.billingVoidConfirm),
        ),
      ],
    );
  }
}

Future<void> _openAdjustSheet(BuildContext context) {
  final cubit = context.read<InvoiceCubit>()..clearErrors();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        BlocProvider.value(value: cubit, child: const _AdjustSheet()),
  );
}

class _AdjustSheet extends StatefulWidget {
  const _AdjustSheet();

  @override
  State<_AdjustSheet> createState() => _AdjustSheetState();
}

class _AdjustSheetState extends State<_AdjustSheet> {
  final _amount = TextEditingController();
  final _description = TextEditingController();
  final _reason = TextEditingController();
  bool _decrease = true;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _reason.dispose();
    super.dispose();
  }

  AdjustmentInput get _input {
    final v = parseVnd(_amount.text) ?? 0;
    return AdjustmentInput(
      amount: _decrease ? -v : v,
      description: _description.text,
      reason: _reason.text,
    );
  }

  String? _error(InvoiceState s, String field, String clientText) {
    final server = s.serverErrors[field];
    if (server != null && server.isNotEmpty) return server.join('\n');
    return s.clientErrors.containsKey(field) ? clientText : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    return BlocConsumer<InvoiceCubit, InvoiceState>(
      listenWhen: (a, b) => b.done == InvoiceDone.adjusted && a.done != b.done,
      listener: (context, _) => Navigator.pop(context),
      builder: (context, s) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.billingAdjustTitle, style: text.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.billingAdjustHint, style: text.bodySmall),
              if (s.error != null) ...[
                const SizedBox(height: AppSpacing.md),
                AppBanner(
                  tone: AppStatusTone.error,
                  description: billingErrorText(l10n, s.error!),
                  fullWidth: true,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppChoiceChip(
                    label: l10n.billingAdjustDecrease,
                    selected: _decrease,
                    onTap: () => setState(() => _decrease = true),
                  ),
                  AppChoiceChip(
                    label: l10n.billingAdjustIncrease,
                    selected: !_decrease,
                    onTap: () => setState(() => _decrease = false),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppInput(
                controller: _amount,
                label: l10n.billingAdjustAmount,
                keyboardType: TextInputType.number,
                inputFormatters: const [VndInputFormatter()],
                errorText: _error(s, 'amount', l10n.billingErrAmount),
              ),
              const SizedBox(height: AppSpacing.md),
              AppInput(
                controller: _description,
                label: l10n.billingAdjustDescription,
                maxLength: adjustmentDescriptionMax,
                errorText: _error(s, 'description', l10n.billingErrDescription),
              ),
              const SizedBox(height: AppSpacing.md),
              AppInput(
                controller: _reason,
                label: l10n.billingAdjustReason,
                maxLines: 3,
                maxLength: adjustmentReasonMax,
                errorText: _error(s, 'adjustmentReason', l10n.billingErrReason),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: l10n.billingAdjustSave,
                width: double.infinity,
                disabled: s.busy,
                onPressed: () =>
                    context.read<InvoiceCubit>().addAdjustment(_input),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
