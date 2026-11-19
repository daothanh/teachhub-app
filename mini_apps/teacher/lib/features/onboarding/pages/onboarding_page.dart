import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../../l10n/l10n.dart';
import '../../students/pages/student_form_page.dart';
import '../cubit/onboarding_cubit.dart';
import '../data/onboarding_models.dart';
import '../data/onboarding_repository.dart';

/// [T02] Khung onboarding 5 bước. Route `/t/onboarding`.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => OnboardingCubit(GetIt.I<OnboardingRepository>())..load(),
    child: const OnboardingView(),
  );
}

/// Chỗ nối màn do nhánh `s2-fl-classes` làm (tạo lớp, đặt lịch).
///
/// shortcut: placeholder chỉ có nút hoàn thành; sau khi merge s2-fl-classes thay
/// bằng màn lớp (bước 1) và màn lịch (bước 3), gọi [onDone] khi người dùng lưu xong.
class OnboardingPlaceholderStep extends StatelessWidget {
  const OnboardingPlaceholderStep({
    super.key,
    required this.body,
    required this.onDone,
  });

  final String body;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return AppEmptyState(
      message: body,
      action: AppButton(label: l10n.onboardingMarkDone, onPressed: onDone),
    );
  }
}

String _stepTitle(MiniAppLocalizations l10n, OnboardingStep s) => switch (s) {
  OnboardingStep.createClass => l10n.onboardingStepCreateClass,
  OnboardingStep.addStudents => l10n.onboardingStepAddStudents,
  OnboardingStep.setSchedule => l10n.onboardingStepSetSchedule,
  OnboardingStep.payoutAccount => l10n.onboardingStepPayoutAccount,
  OnboardingStep.complianceChecklist => l10n.onboardingStepComplianceChecklist,
};

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listenWhen: (a, b) => b.error != null && a.error != b.error,
      listener: (context, state) {
        final e = state.error!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(switch (e.kind) {
              ApiErrorKind.conflict => l10n.onboardingErrorBusy,
              ApiErrorKind.validation => l10n.onboardingErrorValidation,
              ApiErrorKind.network => l10n.onboardingErrorNetwork,
              _ => l10n.onboardingErrorGeneric,
            }),
          ),
        );
      },
      builder: (context, state) {
        final cubit = context.read<OnboardingCubit>();
        final data = state.onboarding;
        final step = data?.currentStep;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.onboardingTitle)),
          body: switch (state.load) {
            OnboardingLoad.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            OnboardingLoad.failure => AppEmptyState(
              message: l10n.onboardingLoadFailed,
              action: AppButton(
                label: l10n.onboardingRetry,
                onPressed: cubit.load,
              ),
            ),
            OnboardingLoad.ready when step == null => AppEmptyState(
              message: l10n.onboardingDoneTitle,
              subMessage: l10n.onboardingDoneBody,
              action: AppButton(
                label: l10n.onboardingFinish,
                onPressed: () => context.go(TeachHubRoutes.teacher),
              ),
            ),
            OnboardingLoad.ready => _StepBody(
              data: data!,
              step: step!,
              saving: state.saving,
            ),
          },
        );
      },
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({
    required this.data,
    required this.step,
    required this.saving,
  });

  final Onboarding data;
  final OnboardingStep step;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cubit = context.read<OnboardingCubit>();
    void done() => cubit.complete(step);
    final total = OnboardingStep.values.length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppProgressBar.segmented(
                value: data.handled / total,
                segments: total,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.onboardingProgress(step.index + 1, total),
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Text(
                _stepTitle(l10n, step),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        // Key theo bước để form học viên được dựng lại khi chuyển bước.
        Expanded(
          key: ValueKey(step),
          child: switch (step) {
            OnboardingStep.addStudents => StudentFormScope(
              onSaved: (_) => done(),
            ),
            OnboardingStep.createClass ||
            OnboardingStep.setSchedule => OnboardingPlaceholderStep(
              body: l10n.onboardingPlaceholderBody,
              onDone: done,
            ),
            OnboardingStep.payoutAccount => OnboardingPlaceholderStep(
              body: l10n.onboardingPayoutBody,
              onDone: done,
            ),
            OnboardingStep.complianceChecklist => OnboardingPlaceholderStep(
              body: l10n.onboardingComplianceBody,
              onDone: done,
            ),
          },
        ),
        if (step.skippable)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AppButton(
                label: l10n.onboardingSkip,
                variant: AppButtonVariant.outlinePrimary,
                onPressed: saving ? null : () => cubit.skip(step),
              ),
            ),
          ),
      ],
    );
  }
}
