import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';
import '../cubit/payout_accounts_cubit.dart';
import '../data/bank_bins.dart';
import '../data/fee_models.dart';
import '../data/fee_repository.dart';
import '../fees_routes.dart';
import '../widgets/fees_error_text.dart';

String payoutBankLabel(MiniAppLocalizations l10n, String bin) =>
    bankName(bin) ?? l10n.payoutUnknownBank(bin);

/// Danh sách tài khoản nhận tiền (US-7.3 AC5): chỉ hiện số đã che.
///
/// [embedded]: nằm trong onboarding bước 4 (không có Scaffold); có tài khoản
/// thì hiện nút "Tiếp tục" gọi [onContinue].
class PayoutAccountsPage extends StatelessWidget {
  const PayoutAccountsPage({
    super.key,
    this.repository,
    this.embedded = false,
    this.onContinue,
  });
  final FeeRepository? repository;
  final bool embedded;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => PayoutAccountsCubit(repository ?? feeRepository())..load(),
    child: _View(embedded: embedded, onContinue: onContinue),
  );
}

class _View extends StatelessWidget {
  const _View({required this.embedded, this.onContinue});
  final bool embedded;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final body = BlocConsumer<PayoutAccountsCubit, PayoutAccountsState>(
      listenWhen: (a, b) =>
          (b.notice != null && a.notice != b.notice) ||
          (b.load == PayoutLoad.ready && b.error != null && a.error != b.error),
      listener: (context, s) {
        final msg = s.error != null
            ? feesErrorText(l10n, s.error!)
            : switch (s.notice!) {
                PayoutNotice.primarySet => l10n.payoutPrimarySet,
                PayoutNotice.deleted => l10n.payoutDeleted,
              };
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
      builder: (context, s) => switch (s.load) {
        PayoutLoad.loading => const Center(child: CircularProgressIndicator()),
        PayoutLoad.failure => AppEmptyState(
          message: s.error == null
              ? l10n.payoutLoadFailed
              : feesErrorText(l10n, s.error!),
          action: AppButton(
            label: l10n.classesRetry,
            onPressed: context.read<PayoutAccountsCubit>().load,
          ),
        ),
        PayoutLoad.ready => _List(
          state: s,
          embedded: embedded,
          onContinue: onContinue,
        ),
      },
    );
    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.payoutTitle)),
      body: body,
    );
  }
}

Future<void> _openForm(
  BuildContext context, {
  String? editId,
  Object? extra,
}) async {
  final cubit = context.read<PayoutAccountsCubit>();
  final saved = await context.push<bool>(
    editId == null ? FeesRoutes.payoutNew : FeesRoutes.payoutEdit(editId),
    extra: extra,
  );
  if (saved == true) await cubit.load();
}

class _List extends StatelessWidget {
  const _List({required this.state, required this.embedded, this.onContinue});
  final PayoutAccountsState state;
  final bool embedded;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final addButton = AppButton(
      label: l10n.payoutAdd,
      width: double.infinity,
      disabled: state.busy || !state.canAdd,
      onPressed: () => _openForm(context),
    );
    if (state.accounts.isEmpty) {
      return Column(
        children: [
          if (embedded)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(l10n.onboardingPayoutIntro, style: text.bodyMedium),
            ),
          Expanded(
            child: AppEmptyState(
              message: l10n.payoutEmpty,
              subMessage: l10n.payoutEmptyBody,
              action: addButton,
            ),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (embedded) ...[
          Text(l10n.onboardingPayoutIntro, style: text.bodyMedium),
          const SizedBox(height: AppSpacing.md),
        ],
        for (final a in state.accounts)
          _AccountTile(account: a, busy: state.busy),
        const SizedBox(height: AppSpacing.md),
        addButton,
        if (!state.canAdd)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(l10n.payoutLimit, style: text.bodySmall),
          ),
        if (embedded && onContinue != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: l10n.payoutContinue,
            variant: AppButtonVariant.outlinePrimary,
            width: double.infinity,
            onPressed: onContinue,
          ),
        ],
      ],
    );
  }
}

enum _Action { edit, primary, delete }

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.account, required this.busy});
  final PayoutAccount account;
  final bool busy;

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = context.miniAppL10n;
    final cubit = context.read<PayoutAccountsCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.payoutDeleteTitle),
        content: Text(l10n.payoutDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.payoutCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.payoutDelete),
          ),
        ],
      ),
    );
    if (ok == true) await cubit.delete(account.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final a = account;
    final line = l10n.payoutLine(
      payoutBankLabel(l10n, a.bankBin),
      a.accountNoMasked,
    );
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                container: true,
                label: l10n.payoutSemantics(a.accountName, line),
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.accountName, style: text.titleSmall),
                    Text(line, style: text.bodyMedium),
                    if (a.isPrimary)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          l10n.payoutPrimaryBadge,
                          style: text.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            PopupMenuButton<_Action>(
              tooltip: l10n.payoutActionsSemantics(a.accountName),
              enabled: !busy,
              onSelected: (act) async {
                switch (act) {
                  case _Action.edit:
                    await _openForm(context, editId: a.id, extra: a);
                  case _Action.primary:
                    await context.read<PayoutAccountsCubit>().setPrimary(a.id);
                  case _Action.delete:
                    await _confirmDelete(context);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _Action.edit,
                  child: Text(l10n.payoutEdit),
                ),
                if (!a.isPrimary)
                  PopupMenuItem(
                    value: _Action.primary,
                    child: Text(l10n.payoutSetPrimary),
                  ),
                PopupMenuItem(
                  value: _Action.delete,
                  child: Text(l10n.payoutDelete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
