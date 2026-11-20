import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';
import '../../fees/data/fee_models.dart';

/// Phần học phí của form lớp (US-1.2): bật/tắt, 3 kiểu, số tiền `150.000 đ`,
/// quy tắc theo kiểu. Giữ không trạng thái: form cha giữ giá trị và controller.
///
/// Quy tắc chỉ hiện đúng kiểu áp dụng (hợp đồng): vắng có/không phép cho theo
/// buổi, trừ buổi hủy cho theo tháng, số đợt cho trọn khóa.
class ClassFeeSection extends StatelessWidget {
  const ClassFeeSection({
    super.key,
    required this.enabled,
    required this.type,
    required this.rules,
    required this.amount,
    required this.installments,
    required this.onEnabled,
    required this.onType,
    required this.onRules,
    this.typeError,
    this.amountError,
    this.rulesError,
  });

  final bool enabled;
  final FeeType type;
  final FeeRules rules;
  final TextEditingController amount;
  final TextEditingController installments;
  final ValueChanged<bool> onEnabled;
  final ValueChanged<FeeType> onType;
  final ValueChanged<FeeRules> onRules;
  final String? typeError;
  final String? amountError;
  final String? rulesError;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final error = Theme.of(context).colorScheme.error;
    const gap = SizedBox(height: AppSpacing.lg);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.classesFeeSection, style: text.titleSmall),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.classesFeeEnabled),
          value: enabled,
          onChanged: onEnabled,
        ),
        if (enabled) ...[
          Text(l10n.classesFeeTypeLabel, style: text.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final t in FeeType.values)
                AppChoiceChip(
                  label: switch (t) {
                    FeeType.perSession => l10n.feeTypePerSession,
                    FeeType.monthly => l10n.feeTypeMonthly,
                    FeeType.course => l10n.feeTypeCourse,
                  },
                  selected: type == t,
                  onTap: () => onType(t),
                ),
            ],
          ),
          if (typeError != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                typeError!,
                style: text.bodySmall?.copyWith(color: error),
              ),
            ),
          gap,
          AppInput(
            controller: amount,
            label: switch (type) {
              FeeType.perSession => l10n.classesFeeAmountPerSession,
              FeeType.monthly => l10n.classesFeeAmountMonthly,
              FeeType.course => l10n.classesFeeAmountCourse,
            },
            required: true,
            keyboardType: TextInputType.number,
            inputFormatters: const [VndInputFormatter()],
            errorText: amountError,
          ),
          if (type == FeeType.perSession) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.classesFeeChargeExcused),
              value: rules.chargeExcused,
              onChanged: (v) => onRules(rules.copyWith(chargeExcused: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.classesFeeChargeUnexcused),
              value: rules.chargeUnexcused,
              onChanged: (v) => onRules(rules.copyWith(chargeUnexcused: v)),
            ),
          ],
          if (type == FeeType.monthly)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.classesFeeDeductCancelled),
              value: rules.deductCancelled,
              onChanged: (v) => onRules(rules.copyWith(deductCancelled: v)),
            ),
          if (type == FeeType.course) ...[
            gap,
            AppInput(
              controller: installments,
              label: l10n.classesFeeInstallments,
              keyboardType: TextInputType.number,
              maxLength: 2,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              errorText: rulesError,
            ),
          ] else if (rulesError != null)
            Text(rulesError!, style: text.bodySmall?.copyWith(color: error)),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.classesFeeNote, style: text.bodySmall),
        ],
      ],
    );
  }
}
