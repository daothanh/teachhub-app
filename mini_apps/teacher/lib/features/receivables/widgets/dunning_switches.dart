import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/l10n.dart';
import '../cubit/student_receivable_cubit.dart';
import '../data/receivable_models.dart';

/// Trạng thái và công tắc nhắc nợ theo ghi danh của một học viên (US-7.5 AC3).
/// [onlyEnrollmentId] khác null: chỉ lớp đó (hộp thoại ở danh sách lớp).
/// Cần `StudentReceivableCubit` phía trên.
class DunningSwitches extends StatelessWidget {
  const DunningSwitches({
    super.key,
    required this.history,
    required this.toggling,
    this.onlyEnrollmentId,
  });
  final StudentReceivableHistory history;
  final Set<String> toggling;
  final String? onlyEnrollmentId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<StudentReceivableCubit>();
    final only = onlyEnrollmentId;
    final shown = [
      for (final e in history.enrollments)
        if (only == null || e.enrollmentId == only) e,
    ];
    final off = only == null
        ? !history.dunningEnabled
        : shown.any((e) => !e.dunningEnabled);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          off ? l10n.dunningStudentOff : l10n.dunningStudentOn,
          style: text.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: off ? scheme.error : scheme.primary,
          ),
        ),
        for (final e in shown)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.dunningClassSwitch(e.className)),
            value: e.dunningEnabled,
            onChanged: toggling.contains(e.enrollmentId)
                ? null
                : (v) => cubit.setDunning(e.enrollmentId, v),
          ),
        Text(l10n.dunningStudentHint, style: text.bodySmall),
      ],
    );
  }
}
