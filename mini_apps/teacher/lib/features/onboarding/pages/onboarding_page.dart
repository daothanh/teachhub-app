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
import '../data/onboarding_draft.dart';
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
          // Sang bước khác: bỏ SnackBar "đã lưu" khỏi đè nút "Để sau"/"Thử lại".
          listenWhen: (a, b) =>
              a.onboarding?.currentStep != b.onboarding?.currentStep,
          listener: (context, _) =>
              ScaffoldMessenger.of(context).clearSnackBars(),
          child: BlocListener<OnboardingCubit, OnboardingState>(
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
                    // `extra` mới = TodayPage dựng lại: thấy buổi vừa đặt và thẻ nhắc.
                    onPressed: () => context.go(
                      TeachHubRoutes.teacher,
                      extra: DateTime.now(),
                    ),
                  ),
                ),
                OnboardingLoad.ready => _StepBody(
                  data: data!,
                  step: step!,
                  saving: state.saving,
                ),
              },
            ),
          ),
        );
      },
    );
  }
}

/// Ghi bước `done`; `true` khi server đã nhận (cubit không có lỗi).
Future<bool> _complete(OnboardingCubit cubit, OnboardingStep step) async {
  await cubit.complete(step);
  return !cubit.isClosed && cubit.state.error == null;
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
            OnboardingStep.addStudents => _AddStudentsStep(
              onSaved: () => _complete(cubit, step),
            ),
            OnboardingStep.createClass => _CreateClassStep(
              onSaved: () => _complete(cubit, step),
            ),
            OnboardingStep.setSchedule => _ScheduleStep(
              onSaved: () => _complete(cubit, step),
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

/// Kho bản nháp onboarding (đăng ký ở `TeacherController`).
OnboardingDraftStore _store() => GetIt.I<OnboardingDraftStore>();

/// Đọc [OnboardingDraft] đã lưu trước khi dựng bước (kill app giữa chừng thì
/// bước thấy lớp/học viên đã tạo và không tạo lại).
class _DraftGate extends StatefulWidget {
  const _DraftGate({required this.builder});

  final Widget Function(OnboardingDraft draft) builder;

  @override
  State<_DraftGate> createState() => _DraftGateState();
}

class _DraftGateState extends State<_DraftGate> {
  late final Future<OnboardingDraft> _draft = _store().read();

  @override
  Widget build(BuildContext context) => FutureBuilder<OnboardingDraft>(
    future: _draft,
    builder: (context, snap) => snap.hasData
        ? widget.builder(snap.data!)
        : const Center(child: CircularProgressIndicator()),
  );
}

/// Thông báo "đã lưu nhưng chưa xong bước" kèm Thử lại. Nằm trong vùng cuộn có
/// giới hạn nên bàn phím mở hay chữ lớn vẫn bấm được.
class _Notice extends StatelessWidget {
  const _Notice({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Flexible(
    flex: 0,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: [
          Text(message),
          const SizedBox(height: 8),
          AppButton(
            label: context.miniAppL10n.onboardingRetry,
            onPressed: onRetry,
          ),
        ],
      ),
    ),
  );
}

/// Bước 1: form lớp có sẵn. Lớp tạo xong thì `classId` được lưu bền vững trước
/// khi ghi bước; mở lại khi lớp đã tạo mà bước chưa `done` thì chỉ ghi lại bước.
class _CreateClassStep extends StatelessWidget {
  const _CreateClassStep({required this.onSaved});

  final Future<bool> Function() onSaved;

  @override
  Widget build(BuildContext context) => _DraftGate(
    builder: (draft) => _CreateClassBody(draft: draft, onSaved: onSaved),
  );
}

class _CreateClassBody extends StatefulWidget {
  const _CreateClassBody({required this.draft, required this.onSaved});

  final OnboardingDraft draft;
  final Future<bool> Function() onSaved;

  @override
  State<_CreateClassBody> createState() => _CreateClassBodyState();
}

class _CreateClassBodyState extends State<_CreateClassBody> {
  late final _keys = _store().keys(widget.draft, 'class');
  late bool _created = widget.draft.classId != null;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (_created) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _record());
    }
  }

  Future<void> _record() async {
    setState(() => _failed = false);
    final ok = await widget.onSaved();
    if (mounted && !ok) setState(() => _failed = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return Column(
      children: [
        Expanded(
          child: _created
              ? (_failed
                    ? const SizedBox.shrink()
                    : const Center(child: CircularProgressIndicator()))
              : ClassFormPage(
                  part: ClassFormPart.basics,
                  embedded: true,
                  keys: _keys,
                  onSaved: (c) async {
                    await _store().update((d) => d.copyWith(classId: c.id));
                    if (!mounted) return;
                    setState(() => _created = true);
                    await _record();
                  },
                ),
        ),
        if (_failed) _Notice(message: l10n.onboardingSaved, onRetry: _record),
      ],
    );
  }
}

/// Bước 2: tạo học viên rồi ghi danh vào lớp của bước 1. Chưa có lớp (bỏ qua
/// bước 1) thì chỉ tạo học viên. `studentId` và các khóa lưu bền vững tới khi
/// bước `done`: kill app giữa chừng thì ghi danh tiếp, không tạo học viên mới.
class _AddStudentsStep extends StatelessWidget {
  const _AddStudentsStep({required this.onSaved});

  final Future<bool> Function() onSaved;

  @override
  Widget build(BuildContext context) => _DraftGate(
    builder: (draft) => _AddStudentsBody(draft: draft, onSaved: onSaved),
  );
}

class _AddStudentsBody extends StatefulWidget {
  const _AddStudentsBody({required this.draft, required this.onSaved});

  final OnboardingDraft draft;
  final Future<bool> Function() onSaved;

  @override
  State<_AddStudentsBody> createState() => _AddStudentsBodyState();
}

class _AddStudentsBodyState extends State<_AddStudentsBody> {
  late final _studentKeys = _store().keys(widget.draft, 'student');
  late final _enrollKeys = _store().keys(widget.draft, 'enroll');
  late String? _studentId = widget.draft.studentId;
  bool _running = false;

  /// Lỗi của lần chạy hiện tại (đã xóa lỗi cũ trước khi chạy).
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (_studentId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _run());
    }
  }

  Future<void> _run() async {
    final studentId = _studentId;
    if (studentId == null || _running) return;
    setState(() {
      _running = true;
      _failed = false;
    });
    var ok = false;
    try {
      final classId = widget.draft.classId;
      if (classId != null) {
        final enrolled = _enrollKeys.of('enroll', '$classId|$studentId');
        await classesRepository().enroll(
          classId,
          studentId,
          idempotencyKey: enrolled,
        );
        _enrollKeys.done('enroll');
      }
      ok = await widget.onSaved();
      if (ok) {
        await _store().update((d) => d.copyWith(clearStudent: true));
      }
    } on ApiException catch (e) {
      if (!e.retryable) _enrollKeys.done('enroll');
    } finally {
      if (mounted) {
        setState(() {
          _running = false;
          _failed = !ok;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return Column(
      children: [
        Expanded(
          child: _studentId != null
              ? (_failed
                    ? const SizedBox.shrink()
                    : const Center(child: CircularProgressIndicator()))
              : StudentFormScope(
                  keys: _studentKeys,
                  onSaved: (id) async {
                    await _store().update((d) => d.copyWith(studentId: id));
                    if (!mounted) return;
                    setState(() => _studentId = id);
                    await _run();
                  },
                ),
        ),
        if (_failed && !_running)
          _Notice(
            message: widget.draft.classId == null
                ? l10n.onboardingSaved
                : l10n.onboardingStudentNotEnrolled,
            onRetry: _run,
          ),
      ],
    );
  }
}

/// Bước 3: đặt lịch cho lớp của bước 1 (`classId` đã lưu, tải đủ trường bằng
/// `get`). Chưa có `classId`: có lớp thì cho chọn, không có lớp thì báo.
class _ScheduleStep extends StatelessWidget {
  const _ScheduleStep({required this.onSaved});

  final Future<bool> Function() onSaved;

  @override
  Widget build(BuildContext context) => _DraftGate(
    builder: (draft) => _ScheduleBody(draft: draft, onSaved: onSaved),
  );
}

typedef _Resolved = ({TeachClass? cls, List<TeachClass> choices});

class _ScheduleBody extends StatefulWidget {
  const _ScheduleBody({required this.draft, required this.onSaved});

  final OnboardingDraft draft;
  final Future<bool> Function() onSaved;

  @override
  State<_ScheduleBody> createState() => _ScheduleBodyState();
}

class _ScheduleBodyState extends State<_ScheduleBody> {
  late Future<_Resolved> _resolved = _resolve(widget.draft.classId);
  bool _failed = false;

  Future<_Resolved> _resolve(String? classId) async {
    final repo = classesRepository();
    if (classId != null) {
      try {
        return (cls: await repo.get(classId), choices: <TeachClass>[]);
      } on ApiException catch (e) {
        if (e.kind != ApiErrorKind.notFound) rethrow;
      }
    }
    return (cls: null, choices: (await repo.list()).items);
  }

  Future<void> _choose(TeachClass c) async {
    await _store().update((d) => d.copyWith(classId: c.id));
    if (mounted) {
      setState(() {
        _resolved = _resolve(c.id);
      });
    }
  }

  Future<void> _record() async {
    setState(() => _failed = false);
    final ok = await widget.onSaved();
    if (mounted && !ok) setState(() => _failed = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return FutureBuilder<_Resolved>(
      future: _resolved,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final r = snap.data;
        Widget retry(String message) => AppEmptyState(
          message: message,
          action: AppButton(
            label: l10n.onboardingRetry,
            onPressed: () => setState(() {
              _resolved = _resolve(widget.draft.classId);
            }),
          ),
        );
        if (r == null) return retry(l10n.onboardingLoadFailed);
        if (r.cls == null && r.choices.isEmpty) {
          return retry(l10n.onboardingScheduleNoClass);
        }
        if (r.cls == null) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.onboardingScheduleChooseClass),
              for (final c in r.choices)
                ListTile(title: Text(c.name), onTap: () => _choose(c)),
            ],
          );
        }
        return Column(
          children: [
            Expanded(
              child: ClassFormPage(
                initial: r.cls,
                part: ClassFormPart.schedule,
                embedded: true,
                onSaved: (_) => _record(),
              ),
            ),
            if (_failed)
              _Notice(message: l10n.onboardingSaved, onRetry: _record),
          ],
        );
      },
    );
  }
}
