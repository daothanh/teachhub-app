import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';
import '../cubit/fee_override_cubit.dart';
import '../data/fee_models.dart';
import '../data/fee_repository.dart';
import '../widgets/fees_error_text.dart';

/// Dữ liệu truyền từ danh sách lớp tới màn mức riêng (`extra` của route).
class FeeOverrideArgs {
  const FeeOverrideArgs({this.studentName = '', this.feeType, this.initial});
  final String studentName;

  /// Kiểu học phí của lớp: chỉ hiện quy tắc áp dụng cho kiểu đó. `null` = hiện đủ.
  final FeeType? feeType;
  final FeeOverride? initial;
}

/// Mức riêng cho học viên (US-1.3): giá, quy tắc vắng, số đợt, miễn giảm.
/// Đóng với `true` khi đã lưu hoặc xóa để danh sách lớp tải lại.
class FeeOverridePage extends StatelessWidget {
  const FeeOverridePage({
    super.key,
    required this.enrollmentId,
    this.args = const FeeOverrideArgs(),
    this.repository,
  });
  final String enrollmentId;
  final FeeOverrideArgs args;
  final FeeRepository? repository;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        FeeOverrideCubit(repository ?? feeRepository(), enrollmentId),
    child: _View(args: args),
  );
}

class _View extends StatelessWidget {
  const _View({required this.args});
  final FeeOverrideArgs args;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return BlocConsumer<FeeOverrideCubit, FeeOverrideState>(
      listenWhen: (a, b) => a.done != b.done && b.done != null,
      listener: (context, s) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              s.done == FeeOverrideDone.cleared
                  ? l10n.feeOverrideCleared
                  : l10n.feeOverrideSaved,
            ),
          ),
        );
        context.pop(true);
      },
      builder: (context, s) => Scaffold(
        appBar: AppBar(
          title: Text(
            args.studentName.isEmpty
                ? l10n.feeOverrideTitle
                : l10n.feeOverrideFor(args.studentName),
          ),
        ),
        body: _Form(args: args, state: s),
      ),
    );
  }
}

class _DiscountRow {
  _DiscountRow({FeeDiscount? from})
    : kind = from?.kind ?? FeeDiscountKind.percent,
      description = TextEditingController(text: from?.description),
      value = TextEditingController(
        text: from == null
            ? null
            : from.kind == FeeDiscountKind.amount
            ? formatVnd(from.value)
            : '${from.value}',
      );
  FeeDiscountKind kind;
  final TextEditingController description;
  final TextEditingController value;

  void dispose() {
    description.dispose();
    value.dispose();
  }

  FeeDiscount get discount => FeeDiscount(
    kind: kind,
    description: description.text,
    value: parseVnd(value.text) ?? 0,
  );
}

class _Form extends StatefulWidget {
  const _Form({required this.args, required this.state});
  final FeeOverrideArgs args;
  final FeeOverrideState state;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final FeeOverride? _initial = widget.args.initial;
  late final _amount = TextEditingController(
    text: _initial?.feeAmount == null ? null : formatVnd(_initial!.feeAmount!),
  );
  late final _installments = TextEditingController(
    text: _initial?.installments?.toString(),
  );
  late bool? _excused = _initial?.chargeExcused;
  late bool? _unexcused = _initial?.chargeUnexcused;
  late bool? _deduct = _initial?.deductCancelled;
  late final List<_DiscountRow> _discounts = [
    for (final d in _initial?.discounts ?? const <FeeDiscount>[])
      _DiscountRow(from: d),
  ];

  @override
  void dispose() {
    _amount.dispose();
    _installments.dispose();
    for (final d in _discounts) {
      d.dispose();
    }
    super.dispose();
  }

  FeeType? get _type => widget.args.feeType;

  FeeOverride get _value => FeeOverride(
    feeAmount: _amount.text.isEmpty ? null : (parseVnd(_amount.text) ?? 0),
    chargeExcused: _showAbsence ? _excused : null,
    chargeUnexcused: _showAbsence ? _unexcused : null,
    deductCancelled: _showDeduct ? _deduct : null,
    installments: _showInstallments
        ? int.tryParse(_installments.text.trim())
        : null,
    discounts: [for (final d in _discounts) d.discount],
  );

  // Chỉ hiện quy tắc áp dụng cho kiểu học phí của lớp; chưa biết kiểu thì hiện đủ.
  bool get _showAbsence => _type == null || _type == FeeType.perSession;
  bool get _showDeduct => _type == null || _type == FeeType.monthly;
  bool get _showInstallments => _type == null || _type == FeeType.course;

  String? _error(String field) {
    final l10n = context.miniAppL10n;
    final server = widget.state.serverErrors[field];
    if (server != null && server.isNotEmpty) return server.join('\n');
    return switch (widget.state.clientErrors[field]) {
      null => null,
      FeeOverrideError.amountRange => l10n.feeOverrideErrAmount,
      FeeOverrideError.installmentsRange => l10n.feeOverrideErrInstallments,
      FeeOverrideError.discountDescription => l10n.feeOverrideErrDiscountDesc,
      FeeOverrideError.discountValue => l10n.feeOverrideErrDiscountValue,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final s = widget.state;
    final text = Theme.of(context).textTheme;
    const gap = SizedBox(height: AppSpacing.lg);
    final init = _initial;
    final canClear = init != null && !init.isEmpty;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (s.error != null) ...[
          AppBanner(
            tone: AppStatusTone.error,
            description: feesErrorText(l10n, s.error!),
            fullWidth: true,
          ),
          gap,
        ],
        Text(l10n.feeOverrideHint, style: text.bodyMedium),
        gap,
        AppInput(
          controller: _amount,
          label: l10n.feeOverrideAmount,
          keyboardType: TextInputType.number,
          inputFormatters: const [VndInputFormatter()],
          errorText: _error('feeAmount'),
        ),
        if (_showAbsence || _showDeduct) ...[
          gap,
          Text(l10n.feeOverrideRulesTitle, style: text.titleSmall),
        ],
        if (_showAbsence) ...[
          const SizedBox(height: AppSpacing.sm),
          _TriChoice(
            label: l10n.classesFeeChargeExcused,
            value: _excused,
            onChanged: (v) => setState(() => _excused = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _TriChoice(
            label: l10n.classesFeeChargeUnexcused,
            value: _unexcused,
            onChanged: (v) => setState(() => _unexcused = v),
          ),
        ],
        if (_showDeduct) ...[
          const SizedBox(height: AppSpacing.sm),
          _TriChoice(
            label: l10n.classesFeeDeductCancelled,
            value: _deduct,
            onChanged: (v) => setState(() => _deduct = v),
          ),
        ],
        if (_showInstallments) ...[
          gap,
          AppInput(
            controller: _installments,
            label: l10n.feeOverrideInstallments,
            keyboardType: TextInputType.number,
            maxLength: 2,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            errorText: _error('installments'),
          ),
        ],
        gap,
        Text(l10n.feeOverrideDiscounts, style: text.titleSmall),
        for (final (i, d) in _discounts.indexed)
          _DiscountEditor(
            key: ObjectKey(d),
            row: d,
            descError: _error('discounts.$i.description'),
            valueError: _error('discounts.$i.value'),
            onKind: (k) => setState(() {
              d.kind = k;
              d.value.clear();
            }),
            onRemove: () => setState(() => _discounts.removeAt(i).dispose()),
          ),
        if (_discounts.length < feeDiscountsMax)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => setState(() => _discounts.add(_DiscountRow())),
              icon: const Icon(Icons.add),
              label: Text(l10n.feeOverrideAddDiscount),
            ),
          ),
        if (s.serverErrors['discounts'] case final e?)
          Text(
            e.join('\n'),
            style: text.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        gap,
        AppButton(
          label: l10n.feeOverrideSave,
          width: double.infinity,
          disabled: s.saving,
          onPressed: () => context.read<FeeOverrideCubit>().save(_value),
        ),
        if (canClear) ...[
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: l10n.feeOverrideClear,
            variant: AppButtonVariant.outlinePrimary,
            width: double.infinity,
            disabled: s.saving,
            onPressed: context.read<FeeOverrideCubit>().clear,
          ),
        ],
      ],
    );
  }
}

/// Ba lựa chọn: theo lớp (null), tính (true), không tính (false).
class _TriChoice extends StatelessWidget {
  const _TriChoice({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool? value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppChoiceChip(
              label: l10n.feeOverrideInherit,
              selected: value == null,
              onTap: () => onChanged(null),
            ),
            AppChoiceChip(
              label: l10n.feeOverrideYes,
              selected: value == true,
              onTap: () => onChanged(true),
            ),
            AppChoiceChip(
              label: l10n.feeOverrideNo,
              selected: value == false,
              onTap: () => onChanged(false),
            ),
          ],
        ),
      ],
    );
  }
}

class _DiscountEditor extends StatelessWidget {
  const _DiscountEditor({
    super.key,
    required this.row,
    required this.onKind,
    required this.onRemove,
    this.descError,
    this.valueError,
  });
  final _DiscountRow row;
  final ValueChanged<FeeDiscountKind> onKind;
  final VoidCallback onRemove;
  final String? descError;
  final String? valueError;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final percent = row.kind == FeeDiscountKind.percent;
    return Card(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: AppInput(
                    controller: row.description,
                    label: l10n.feeOverrideDiscountDesc,
                    maxLength: 100,
                    errorText: descError,
                  ),
                ),
                IconButton(
                  tooltip: l10n.feeOverrideRemoveDiscount,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onRemove,
                ),
              ],
            ),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                AppChoiceChip(
                  label: l10n.feeOverrideDiscountPercent,
                  selected: percent,
                  onTap: () => onKind(FeeDiscountKind.percent),
                ),
                AppChoiceChip(
                  label: l10n.feeOverrideDiscountAmount,
                  selected: !percent,
                  onTap: () => onKind(FeeDiscountKind.amount),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppInput(
              controller: row.value,
              label: percent
                  ? l10n.feeOverrideDiscountPercentValue
                  : l10n.feeOverrideDiscountAmountValue,
              keyboardType: TextInputType.number,
              maxLength: percent ? 3 : null,
              inputFormatters: percent
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : const [VndInputFormatter()],
              errorText: valueError,
            ),
          ],
        ),
      ),
    );
  }
}
