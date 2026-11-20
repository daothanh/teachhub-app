import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teachhub_shared/teachhub_shared.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';
import '../../classes/widgets/read_only_field.dart';
import '../cubit/payout_account_form_cubit.dart';
import '../data/bank_bins.dart';
import '../data/fee_models.dart';
import '../data/fee_repository.dart';
import '../widgets/fees_error_text.dart';
import 'payout_accounts_page.dart' show payoutBankLabel;

/// Thêm hoặc sửa tài khoản nhận tiền. Đóng với `true` khi đã lưu.
class PayoutAccountFormPage extends StatelessWidget {
  const PayoutAccountFormPage({super.key, this.editing, this.repository});
  final PayoutAccount? editing;
  final FeeRepository? repository;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        PayoutAccountFormCubit(repository ?? feeRepository(), editing: editing),
    child: _View(editing: editing),
  );
}

class _View extends StatelessWidget {
  const _View({this.editing});
  final PayoutAccount? editing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return BlocConsumer<PayoutAccountFormCubit, PayoutFormState>(
      listenWhen: (a, b) => a.saved != b.saved && b.saved != null,
      listener: (context, s) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.payoutSaved)));
        context.pop(true);
      },
      builder: (context, s) => Scaffold(
        appBar: AppBar(
          title: Text(
            editing == null
                ? l10n.payoutFormNewTitle
                : l10n.payoutFormEditTitle,
          ),
        ),
        body: _Body(editing: editing, state: s),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.editing, required this.state});
  final PayoutAccount? editing;
  final PayoutFormState state;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late final _accountNo = TextEditingController();
  late final _name = TextEditingController(text: widget.editing?.accountName);
  final _otp = TextEditingController();
  late String? _bin = widget.editing?.bankBin;

  @override
  void dispose() {
    _accountNo.dispose();
    _name.dispose();
    _otp.dispose();
    super.dispose();
  }

  PayoutAccountInput get _input => PayoutAccountInput(
    bankBin: _bin ?? '',
    accountNo: _accountNo.text.trim(),
    accountName: _name.text,
  );

  String? _error(String field) {
    final l10n = context.miniAppL10n;
    final server = widget.state.serverErrors[field];
    if (server != null && server.isNotEmpty) return server.join('\n');
    return switch ((field, widget.state.clientErrors[field])) {
      (_, null) => null,
      ('bankBin', _) => l10n.payoutErrBank,
      (_, PayoutFieldError.required) => l10n.payoutErrRequired,
      (_, PayoutFieldError.accountNoFormat) => l10n.payoutErrAccountNo,
      (_, PayoutFieldError.nameTooLong) => l10n.payoutErrName,
    };
  }

  Future<void> _pickBank() async {
    final picked = await showModalBottomSheet<Bank>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final b in banks)
              ListTile(
                title: Text(b.name),
                selected: b.bin == _bin,
                onTap: () => Navigator.pop(ctx, b),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _bin = picked.bin);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final s = widget.state;
    final cubit = context.read<PayoutAccountFormCubit>();
    final codeStep = s.step == PayoutStep.code;
    final err = s.error;
    // Lỗi mã hiện ở ô mã; mọi lỗi chung khác hiện ở banner.
    final codeError =
        codeStep &&
            err != null &&
            (err.code == ApiErrorCode.otpInvalid ||
                err.code == ApiErrorCode.otpLocked)
        ? feesErrorText(l10n, err)
        : null;
    final banner = codeError == null && err != null
        ? feesErrorText(l10n, err)
        : null;
    const gap = SizedBox(height: AppSpacing.lg);
    final text = Theme.of(context).textTheme;
    final input = _input;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (banner != null) ...[
          AppBanner(
            tone: AppStatusTone.error,
            description: banner,
            fullWidth: true,
          ),
          gap,
        ],
        if (!codeStep) ...[
          ReadOnlyField(
            text: _bin == null ? '' : payoutBankLabel(l10n, _bin!),
            label: l10n.payoutFieldBank,
            hint: l10n.payoutPickBank,
            required: true,
            errorText: _error('bankBin'),
            suffix: const Icon(Icons.arrow_drop_down),
            onTap: _pickBank,
          ),
          gap,
          AppInput(
            controller: _accountNo,
            label: l10n.payoutFieldAccountNo,
            hint: widget.editing == null
                ? null
                : '${widget.editing!.accountNoMasked} · '
                      '${l10n.payoutFieldAccountNoEditHint}',
            required: widget.editing == null,
            keyboardType: TextInputType.number,
            maxLength: 19,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            errorText: _error('accountNo'),
            onChanged: (_) => setState(() {}),
          ),
          gap,
          AppInput(
            controller: _name,
            label: l10n.payoutFieldName,
            hint: l10n.payoutFieldNameHint,
            required: true,
            maxLength: 50,
            errorText: _error('accountName'),
          ),
          if (cubit.needsOtp(input)) ...[
            gap,
            Text(l10n.payoutOtpNeeded, style: text.bodySmall),
          ],
          gap,
          AppButton(
            label: cubit.needsOtp(input)
                ? l10n.payoutSendCode
                : l10n.payoutSave,
            width: double.infinity,
            disabled: s.busy,
            onPressed: () => cubit.submit(_input),
          ),
        ] else ...[
          if (s.codeSent && err == null) ...[
            Text(l10n.payoutOtpSent, style: text.bodyMedium),
            gap,
          ],
          AppInput(
            controller: _otp,
            label: l10n.payoutOtpField,
            required: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            errorText: codeError ?? _error('otpCode'),
            onChanged: (_) => setState(() {}),
          ),
          gap,
          AppButton(
            label: l10n.payoutOtpConfirm,
            width: double.infinity,
            disabled: s.busy || _otp.text.length != 6,
            onPressed: () => cubit.confirm(_otp.text),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            children: [
              TextButton(
                onPressed: s.busy ? null : cubit.sendCode,
                child: Text(l10n.payoutOtpResend),
              ),
              TextButton(
                onPressed: s.busy
                    ? null
                    : () {
                        _otp.clear();
                        cubit.backToForm();
                      },
                child: Text(l10n.payoutOtpBack),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
