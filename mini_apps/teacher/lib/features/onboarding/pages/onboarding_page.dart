import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../../l10n/l10n.dart';
import '../../classes/data/class_models.dart';
import '../../classes/data/classes_repository.dart';
import '../../classes/pages/class_form_page.dart';
import '../../fees/pages/payout_accounts_page.dart';
import '../../students/pages/student_form_page.dart';
import '../cubit/onboarding_cubit.dart';
import '../data/onboarding_models.dart';
import '../data/onboarding_repository.dart';

/// [T02] Khung onboarding 5 bước. Route `/t/onboarding`.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key, this.initialStep});

  /// Mở đúng bước này (thẻ nhắc bước đã bỏ qua); null = bước đang dở.
  final OnboardingStep? initialStep;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => OnboardingCubit(GetIt.I<OnboardingRepository>())..load(),
    child: OnboardingView(initialStep: initialStep),
  );
}

/// Màn giữ chỗ của bước 5 (checklist tuân thủ, chưa có màn thật).
///
/// shortcut: không có nút hoàn thành (không ghi `done` khi chưa làm gì); thay
/// bằng màn thật khi có, truyền [onDone] để gọi khi người dùng xong.
class OnboardingPlaceholderStep extends StatelessWidget {
  const OnboardingPlaceholderStep({super.key, required this.body, this.onDone});

  final String body;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) => AppEmptyState(
    message: body,
    action: onDone == null
        ? null
        : AppButton(
            label: context.miniAppL10n.onboardingMarkDone,
            onPressed: onDone,
          ),
  );
}

String _stepTitle(MiniAppLocalizations l10n, OnboardingStep s) => switch (s) {
  OnboardingStep.createClass => l10n.onboardingStepCreateClass,
  OnboardingStep.addStudents => l10n.onboardingStepAddStudents,
  OnboardingStep.setSchedule => l10n.onboardingStepSetSchedule,
  OnboardingStep.payoutAccount => l10n.onboardingStepPayoutAccount,
  OnboardingStep.complianceChecklist => l10n.onboardingStepComplianceChecklist,
};

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key, this.initialStep});

  final OnboardingStep? initialStep;

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
        final step = initialStep ?? data?.currentStep;
        return BlocListener<OnboardingCubit, OnboardingState>(
          // Mở một bước riêng: lưu hoặc bỏ qua xong thì quay lại màn trước.
          listenWhen: (a, b) =>
              initialStep != null && a.saving && !b.saving && b.error == null,
          listener: (context, _) {
            if (context.canPop()) context.pop();
          },
          child: Scaffold(
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
          ),
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
            OnboardingStep.addStudents => _SaveThenComplete(
              builder: (onSaved) => StudentFormScope(onSaved: (_) => onSaved()),
              onSaved: () => cubit.complete(step),
            ),
            OnboardingStep.createClass => _SaveThenComplete(
              builder: (onSaved) => ClassFormPage(
                part: ClassFormPart.basics,
                embedded: true,
                onSaved: (_) => onSaved(),
              ),
              onSaved: () => cubit.complete(step),
            ),
            OnboardingStep.setSchedule => _ScheduleStep(
              onSaved: () => cubit.complete(step),
            ),
            OnboardingStep.payoutAccount => PayoutAccountsPage(
              embedded: true,
              onContinue: () => cubit.complete(step),
            ),
            OnboardingStep.complianceChecklist => OnboardingPlaceholderStep(
              body: l10n.onboardingComplianceBody,
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

/// Bước nhúng một form có sẵn (tạo lớp, thêm học viên). Lưu xong form đã gọi
/// API thật; nếu ghi bước thất bại thì chỉ thử lại việc ghi bước, không gửi
/// lại dữ liệu.
class _SaveThenComplete extends StatefulWidget {
  const _SaveThenComplete({required this.builder, required this.onSaved});

  final Widget Function(VoidCallback onSaved) builder;
  final VoidCallback onSaved;

  @override
  State<_SaveThenComplete> createState() => _SaveThenCompleteState();
}

class _SaveThenCompleteState extends State<_SaveThenComplete> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final state = context.watch<OnboardingCubit>().state;
    final failed = _saved && !state.saving && state.error != null;
    return Column(
      children: [
        Expanded(
          child: widget.builder(() {
            setState(() => _saved = true);
            widget.onSaved();
          }),
        ),
        if (failed)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                Text(l10n.onboardingSaved),
                const SizedBox(height: 8),
                AppButton(
                  label: l10n.onboardingRetry,
                  onPressed: widget.onSaved,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Bước 3: đặt lịch cho lớp đã tạo ở bước 1. Lớp lấy từ server nên mở lại app
/// vẫn đúng lớp và quy tắc đã lưu.
class _ScheduleStep extends StatefulWidget {
  const _ScheduleStep({required this.onSaved});

  final VoidCallback onSaved;

  @override
  State<_ScheduleStep> createState() => _ScheduleStepState();
}

class _ScheduleStepState extends State<_ScheduleStep> {
  late Future<TeachClass?> _class = _load();

  // shortcut: lấy lớp đầu danh sách; lớp mới nhất = lớp ở bước 1 khi chưa có lớp
  // khác, đủ cho onboarding của tenant mới.
  Future<TeachClass?> _load() async =>
      (await classesRepository().list()).items.firstOrNull;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return FutureBuilder<TeachClass?>(
      future: _class,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final c = snap.data;
        if (snap.hasError || c == null) {
          return AppEmptyState(
            message: snap.hasError
                ? l10n.onboardingLoadFailed
                : l10n.onboardingScheduleNoClass,
            action: AppButton(
              label: l10n.onboardingRetry,
              onPressed: () => setState(() => _class = _load()),
            ),
          );
        }
        return _SaveThenComplete(
          builder: (onSaved) => ClassFormPage(
            initial: c,
            part: ClassFormPart.schedule,
            embedded: true,
            onSaved: (_) => onSaved(),
          ),
          onSaved: widget.onSaved,
        );
      },
    );
  }
}
