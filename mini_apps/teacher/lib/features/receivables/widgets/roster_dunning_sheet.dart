import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';
import '../../billing/cubit/billing_periods_cubit.dart' show BillingLoad;
import '../../billing/widgets/billing_error_text.dart';
import '../cubit/student_receivable_cubit.dart';
import '../data/receivables_repository.dart';
import 'dunning_switches.dart';

/// Hộp thoại bật/tắt nhắc nợ của một học viên trong một lớp (US-7.5 AC3), mở từ
/// danh sách lớp. Trạng thái lấy từ `GET /receivables/{studentId}`.
Future<void> showRosterDunningSheet(
  BuildContext context, {
  required String studentId,
  required String studentName,
  required String enrollmentId,
  ReceivablesRepository? repository,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => BlocProvider(
    create: (_) =>
        StudentReceivableCubit(repository ?? receivablesRepository(), studentId)
          ..load(),
    child: _Sheet(studentName: studentName, enrollmentId: enrollmentId),
  ),
);

class _Sheet extends StatelessWidget {
  const _Sheet({required this.studentName, required this.enrollmentId});
  final String studentName;
  final String enrollmentId;

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
      builder: (context, s) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.rosterDunningTitle(studentName),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            switch (s.load) {
              BillingLoad.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              BillingLoad.failure => AppEmptyState(
                message: s.error == null
                    ? l10n.dunningLoadFailed
                    : billingErrorText(l10n, s.error!),
                action: AppButton(
                  label: l10n.classesRetry,
                  onPressed: cubit.load,
                ),
              ),
              BillingLoad.ready => DunningSwitches(
                history: s.history!,
                toggling: s.toggling,
                onlyEnrollmentId: enrollmentId,
              ),
            },
          ],
        ),
      ),
    );
  }
}
