import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
/// [embedded]: nhúng không có Scaffold (từng là onboarding bước 4, tạm bỏ 22/11/2026); có tài khoản
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
          _AccountTile(
            account: a,
            busy: state.busy,
            isLast: state.accounts.length == 1,
          ),
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
  const _AccountTile({
    required this.account,
    required this.busy,
    required this.isLast,
  });
  final PayoutAccount account;
  final bool busy;

  /// Chỉ còn tài khoản này: xóa xong sẽ chặn chốt kỳ (US-7.3 AC5).
  final bool isLast;

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = context.miniAppL10n;
    final cubit = context.read<PayoutAccountsCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.payoutDeleteTitle),
        content: Text(
          isLast ? l10n.payoutDeleteLastBody : l10n.payoutDeleteBody,
        ),
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
    if (ok != true || !context.mounted) return;
    final otp = cubit.deleteNeedsOtp(account.id)
        ? await _askOtp(context)
        : null;
    if (cubit.deleteNeedsOtp(account.id) && otp == null) return;
    await cubit.delete(account.id, otpCode: otp);
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
                    final cubit = context.read<PayoutAccountsCubit>();
                    final otp = cubit.setPrimaryNeedsOtp(a.id)
                        ? await _askOtp(context)
                        : null;
                    if (cubit.setPrimaryNeedsOtp(a.id) && otp == null) return;
                    await cubit.setPrimary(a.id, otpCode: otp);
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

/// Gửi mã tới email rồi hỏi mã 6 số (đổi tài khoản chính, hợp đồng US-7.3).
/// Trả `null` khi hủy hoặc không gửi được mã (đã báo lỗi bằng SnackBar).
Future<String?> _askOtp(BuildContext context) async {
  final l10n = context.miniAppL10n;
  final cubit = context.read<PayoutAccountsCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final err = await cubit.sendOtp();
  if (err != null) {
    messenger.showSnackBar(SnackBar(content: Text(feesErrorText(l10n, err))));
    return null;
  }
  if (!context.mounted) return null;
  return showDialog<String>(
    context: context,
    builder: (_) => BlocProvider.value(value: cubit, child: const _OtpDialog()),
  );
}

class _OtpDialog extends StatefulWidget {
  const _OtpDialog();

  @override
  State<_OtpDialog> createState() => _OtpDialogState();
}

class _OtpDialogState extends State<_OtpDialog> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return AlertDialog(
      title: Text(l10n.payoutOtpActionTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.payoutOtpActionBody),
            const SizedBox(height: AppSpacing.md),
            AppInput(
              controller: _code,
              label: l10n.payoutOtpField,
              autofillHints: const [AutofillHints.oneTimeCode],
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.read<PayoutAccountsCubit>().sendOtp(),
          child: Text(l10n.payoutOtpResend),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.payoutCancel),
        ),
        TextButton(
          onPressed: _code.text.length == 6
              ? () => Navigator.pop(context, _code.text)
              : null,
          child: Text(l10n.payoutOtpActionConfirm),
        ),
      ],
    );
  }
}
