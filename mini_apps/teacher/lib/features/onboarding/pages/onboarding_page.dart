import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../../l10n/l10n.dart';
import '../../classes/cubit/class_form_cubit.dart';
import '../../classes/data/class_models.dart';
import '../../classes/data/classes_repository.dart';
import '../../fees/data/fee_models.dart';
import '../../students/pages/student_form_page.dart';
import '../cubit/onboarding_cubit.dart';
import '../data/onboarding_draft.dart';
import '../data/onboarding_models.dart';
import '../data/onboarding_repository.dart';

/// [T02] Thiết lập lớp học 3 bước (Figma B07–B09). Route `/t/onboarding`.
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

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key, this.initialStep});

  final OnboardingStep? initialStep;

  /// × trên app bar: mở riêng một bước thì quay lại; trong luồng thì hỏi trước.
  Future<void> _exit(BuildContext context) async {
    if (initialStep != null) {
      if (context.canPop()) context.pop();
      return;
    }
    final l10n = context.miniAppL10n;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.onboardingExitTitle),
        content: Text(l10n.onboardingExitBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.onboardingExitStay),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.onboardingExitLeave),
          ),
        ],
      ),
    );
    if (leave == true && context.mounted) {
      GoRouter.maybeOf(context)?.go(TeachHubRoutes.teacher);
    }
  }

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
          // Sang bước khác: bỏ SnackBar cũ; xong bước cuối thì vào thẳng Hôm nay
          // kèm lớp vừa tạo để gợi ý mời phụ huynh (Figma T02-3 → T03 + sheet).
          listenWhen: (a, b) =>
              a.onboarding?.currentStep != b.onboarding?.currentStep,
          listener: (context, s) async {
            ScaffoldMessenger.of(context).clearSnackBars();
            final router = GoRouter.maybeOf(context);
            if (initialStep != null ||
                s.onboarding?.currentStep != null ||
                router == null) {
              return; // không có router (test): giữ màn hoàn tất
            }
            final classId = (await _store().read()).classId;
            router.go(TeachHubRoutes.teacher, extra: (DateTime.now(), classId));
          },
          child: BlocListener<OnboardingCubit, OnboardingState>(
            // Mở một bước riêng: lưu hoặc bỏ qua xong thì quay lại màn trước.
            listenWhen: (a, b) =>
                initialStep != null && a.saving && !b.saving && b.error == null,
            listener: (context, _) {
              if (context.canPop()) context.pop();
            },
            child: Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.onboardingExit,
                  onPressed: () => _exit(context),
                ),
                title: Text(l10n.onboardingTitle),
                centerTitle: false,
                actions: [
                  if (state.load == OnboardingLoad.ready && step != null)
                    TextButton(
                      // Bước 1 bắt buộc (US-0.2 AC2).
                      onPressed: step.skippable && !state.saving
                          ? () => cubit.skip(step)
                          : null,
                      child: Text(l10n.onboardingSkip),
                    ),
                ],
              ),
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
                    onPressed: () => context.go(
                      TeachHubRoutes.teacher,
                      extra: DateTime.now(),
                    ),
                  ),
                ),
                OnboardingLoad.ready => _StepBody(data: data!, step: step!),
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
  const _StepBody({required this.data, required this.step});

  final Onboarding data;
  final OnboardingStep step;

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
              Text(
                l10n.onboardingProgress(step.index + 1, total),
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              // Tô tới bước đang làm (Figma: "Bước N/3" + N đoạn).
              AppProgressBar.segmented(
                value: (step.index + 1) / total,
                segments: total,
              ),
            ],
          ),
        ),
        // Key theo bước để form được dựng lại khi chuyển bước.
        Expanded(
          key: ValueKey(step),
          child: switch (step) {
            OnboardingStep.createClass => _CreateClassStep(
              onSaved: () => _complete(cubit, step),
            ),
            OnboardingStep.addStudents => _AddStudentsStep(
              onSaved: () => _complete(cubit, step),
            ),
            OnboardingStep.setSchedule => _ScheduleStep(
              onSaved: () => _complete(cubit, step),
            ),
          },
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

/// Tiêu đề H1 + mô tả của mỗi bước.
List<Widget> _heading(BuildContext context, String title, String caption) => [
  Text(title, style: Theme.of(context).textTheme.headlineMedium),
  const SizedBox(height: 4),
  Text(
    caption,
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  ),
  const SizedBox(height: 16),
];

/// Thanh hành động đáy: một nút chính (Figma Bottom Action Bar).
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: AppButton(
        label: label,
        width: double.infinity,
        onPressed: onPressed,
        disabled: onPressed == null,
      ),
    ),
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

void _snack(BuildContext context, String message) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(message)));

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Lỗi lưu lớp: thông báo đầu tiên của server theo trường, không thì lỗi chung.
String _classError(MiniAppLocalizations l10n, ClassFormState s) =>
    s.serverErrors.values.expand((m) => m).firstOrNull ??
    (s.error?.kind == ApiErrorKind.network
        ? l10n.onboardingErrorNetwork
        : l10n.onboardingErrorGeneric);

// ───────────────────────────── Bước 1 ─────────────────────────────

/// Bước 1 (Figma B07): tên lớp, môn, khối, cách thu và mức phí. Lớp tạo tại chỗ,
/// chưa có địa điểm, bắt đầu hôm nay (Owner chốt 23/11/2026). `classId` lưu bền
/// vững trước khi ghi bước; mở lại khi lớp đã tạo thì chỉ ghi lại bước.
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
  bool _saving = false;

  final _name = TextEditingController();
  final _subject = TextEditingController();
  final _grade = TextEditingController();
  final _amount = TextEditingController();
  final _endDate = TextEditingController();
  int? _gradeValue;
  DateTime? _endDateValue;
  FeeType _fee = FeeType.perSession;

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _subject, _amount]) {
      c.addListener(() => setState(() {}));
    }
    if (_created) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _record());
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _subject, _grade, _amount, _endDate]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      _subject.text.isNotEmpty &&
      _gradeValue != null &&
      (parseVnd(_amount.text) ?? 0) > 0 &&
      (_fee != FeeType.course || _endDateValue != null);

  Future<void> _record() async {
    setState(() => _failed = false);
    final ok = await widget.onSaved();
    if (mounted && !ok) setState(() => _failed = true);
  }

  Future<String?> _choose(String title, List<String> options) =>
      showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text(title, style: Theme.of(ctx).textTheme.titleMedium),
              ),
              for (final o in options)
                ListTile(title: Text(o), onTap: () => Navigator.pop(ctx, o)),
            ],
          ),
        ),
      );

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDateValue ?? now.add(const Duration(days: 90)),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _endDateValue = picked;
      _endDate.text = MaterialLocalizations.of(
        context,
      ).formatCompactDate(picked);
    });
  }

  Future<void> _save() async {
    final l10n = context.miniAppL10n;
    final amount = parseVnd(_amount.text)!;
    final course = _fee == FeeType.course;
    // Trọn khóa cần lịch học (server tính tổng buổi): ghi học phí ở bước 3.
    final input = ClassInput(
      name: _name.text.trim(),
      subject: _subject.text,
      grade: _gradeValue,
      startDate: _ymd(DateTime.now()),
      endDate: course ? _ymd(_endDateValue!) : null,
      feeType: course ? null : _fee,
      feeAmount: course ? null : amount,
    );
    setState(() => _saving = true);
    final cubit = ClassFormCubit(classesRepository(), keys: _keys);
    await cubit.save(input, const []);
    final saved = cubit.state.saved;
    final error = saved == null ? _classError(l10n, cubit.state) : null;
    await cubit.close();
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved == null) {
      _snack(context, error!);
      return;
    }
    await _store().update(
      (d) => d.copyWith(
        classId: saved.id,
        pendingFee: course ? (feeType: _fee.wire, amount: amount) : null,
      ),
    );
    if (!mounted) return;
    setState(() => _created = true);
    await _record();
  }

  String _feeLabel(MiniAppLocalizations l10n, FeeType t) => switch (t) {
    FeeType.perSession => l10n.feeTypePerSession,
    FeeType.monthly => l10n.feeTypeMonthly,
    FeeType.course => l10n.feeTypeCourse,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    if (_created) {
      return Column(
        children: [
          Expanded(
            child: _failed
                ? const SizedBox.shrink()
                : const Center(child: CircularProgressIndicator()),
          ),
          if (_failed) _Notice(message: l10n.onboardingSaved, onRetry: _record),
        ],
      );
    }
    const gap = SizedBox(height: 12);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ..._heading(
                context,
                l10n.onboardingStepCreateClass,
                l10n.onboardingClassCaption,
              ),
              AppTextFormField(
                controller: _name,
                label: l10n.classesFieldName,
                hint: l10n.onboardingClassNameHint,
                required: true,
                maxLength: 120,
              ),
              gap,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextFormField(
                      controller: _subject,
                      label: l10n.classesFieldSubject,
                      hint: l10n.onboardingSubjectHint,
                      required: true,
                      readOnly: true,
                      suffix: const Icon(Icons.expand_more),
                      onTap: () async {
                        final v = await _choose(
                          l10n.classesFieldSubject,
                          l10n.onboardingSubjects.split('|'),
                        );
                        if (v != null) _subject.text = v;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextFormField(
                      controller: _grade,
                      label: l10n.onboardingGradeLabel,
                      hint: l10n.onboardingGradeHint,
                      required: true,
                      readOnly: true,
                      suffix: const Icon(Icons.expand_more),
                      onTap: () async {
                        final v = await _choose(l10n.onboardingGradeLabel, [
                          for (var g = 1; g <= 12; g++) '$g',
                        ]);
                        if (v != null) {
                          setState(() => _gradeValue = int.parse(v));
                          _grade.text = v;
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  text: l10n.onboardingFeeSection,
                  children: [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              RadioGroup<FeeType>(
                groupValue: _fee,
                onChanged: (t) => setState(() => _fee = t ?? _fee),
                child: Column(
                  children: [
                    for (final t in FeeType.values)
                      RadioListTile<FeeType>(
                        value: t,
                        // DS v2: chỉ báo đang chọn màu mực, không dùng lime.
                        activeColor: Theme.of(context).colorScheme.onSurface,
                        contentPadding: EdgeInsets.zero,
                        title: Text(_feeLabel(l10n, t)),
                      ),
                  ],
                ),
              ),
              if (_fee == FeeType.course) ...[
                AppTextFormField(
                  controller: _endDate,
                  label: l10n.onboardingEndDateLabel,
                  required: true,
                  readOnly: true,
                  suffix: const Icon(Icons.calendar_today_outlined),
                  onTap: _pickEndDate,
                ),
                gap,
              ],
              AppTextFormField(
                controller: _amount,
                label: switch (_fee) {
                  FeeType.perSession => l10n.onboardingFeeAmountPerSession,
                  FeeType.monthly => l10n.onboardingFeeAmountMonthly,
                  FeeType.course => l10n.onboardingFeeAmountCourse,
                },
                hint: '0',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                suffix: const SizedBox(
                  width: 32,
                  child: Center(child: Text('đ')),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.onboardingFeeCaption,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        _ActionBar(
          label: _saving ? l10n.onboardingSaving : l10n.onboardingContinue,
          onPressed: _valid && !_saving ? _save : null,
        ),
      ],
    );
  }
}

// ───────────────────────────── Bước 2 ─────────────────────────────

/// Bước 2 (Figma B08): thêm từng học viên (họ tên, SĐT phụ huynh) rồi ghi danh
/// vào lớp của bước 1; chưa có lớp thì chỉ tạo học viên. Bấm "Tiếp tục (n học
/// sinh)" mới ghi bước `done`. Học viên đang dở và danh sách đã thêm lưu bền
/// vững: kill app giữa chừng thì ghi danh tiếp, không tạo học viên mới.
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
  late AddedStudent? _pending = widget.draft.studentName == null
      ? null
      : (name: widget.draft.studentName!, phone: widget.draft.studentPhone);
  late final List<AddedStudent> _added = [...widget.draft.added];
  AddedStudent? _justSaved;
  bool _running = false;

  /// Đổi để dựng form mới (trống) sau mỗi học viên đã thêm.
  int _form = 0;

  /// Lỗi ghi danh của học viên đang dở.
  bool _failed = false;

  /// Lỗi ghi bước khi bấm "Tiếp tục".
  bool _continueFailed = false;

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
      ok = true;
      _added.add(_pending ?? (name: '', phone: null));
      await _store().update(
        (d) => d.copyWith(clearStudent: true, added: [..._added]),
      );
    } on ApiException catch (e) {
      if (!e.retryable) _enrollKeys.done('enroll');
    } finally {
      if (mounted) {
        setState(() {
          _running = false;
          _failed = !ok;
          if (ok) {
            _studentId = null;
            _pending = null;
            _form++;
          }
        });
      }
    }
  }

  Future<void> _continue() async {
    setState(() => _continueFailed = false);
    final ok = await widget.onSaved();
    if (ok) {
      await _store().update((d) => d.copyWith(added: const []));
    } else if (mounted) {
      setState(() => _continueFailed = true);
    }
  }

  List<Widget> _addedList(BuildContext context, MiniAppLocalizations l10n) => [
    if (_added.isNotEmpty) ...[
      const SizedBox(height: 16),
      Text(
        l10n.onboardingAddedCount(_added.length),
        style: Theme.of(context).textTheme.labelMedium,
      ),
      for (final s in _added)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(child: Text(_initials(s.name))),
          title: Text(s.name),
          subtitle: s.phone == null
              ? null
              : Text(l10n.onboardingAddedPhone(s.phone!)),
        ),
    ],
  ];

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    return parts.length == 1
        ? first.toUpperCase()
        : (first + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final busy = _studentId != null;
    final heading = _heading(
      context,
      l10n.onboardingStudentsTitle,
      l10n.onboardingStudentsCaption,
    );
    return Column(
      children: [
        Expanded(
          child: busy
              ? (_failed
                    ? ListView(
                        padding: const EdgeInsets.all(16),
                        children: [...heading, ..._addedList(context, l10n)],
                      )
                    : const Center(child: CircularProgressIndicator()))
              : StudentFormScope(
                  key: ValueKey(_form),
                  keys: _studentKeys,
                  quickAdd: true,
                  header: heading,
                  footer: _addedList(context, l10n),
                  onSavedInfo: (name, phone) =>
                      _justSaved = (name: name, phone: phone),
                  onSaved: (id) async {
                    final saved = _justSaved;
                    await _store().update(
                      (d) => d.copyWith(
                        studentId: id,
                        studentName: saved?.name,
                        studentPhone: saved?.phone,
                      ),
                    );
                    if (!mounted) return;
                    setState(() {
                      _studentId = id;
                      _pending = saved;
                    });
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
        if (_continueFailed)
          _Notice(message: l10n.onboardingSaved, onRetry: _continue),
        _ActionBar(
          label: l10n.onboardingStudentsContinue(_added.length),
          onPressed: _added.isNotEmpty && !busy && !_continueFailed
              ? _continue
              : null,
        ),
      ],
    );
  }
}

// ───────────────────────────── Bước 3 ─────────────────────────────

/// Bước 3 (Figma B09): đặt lịch cho lớp của bước 1 (`classId` đã lưu, tải đủ
/// trường bằng `get`). Chưa có `classId`: có lớp thì cho chọn, không thì báo.
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
              ..._heading(
                context,
                l10n.onboardingScheduleTitle,
                l10n.onboardingScheduleCaption,
              ),
              Text(l10n.onboardingScheduleChooseClass),
              for (final c in r.choices)
                ListTile(title: Text(c.name), onTap: () => _choose(c)),
            ],
          );
        }
        return _RulesForm(
          cls: r.cls!,
          draft: widget.draft,
          onSaved: widget.onSaved,
        );
      },
    );
  }
}

/// Một hàng lịch đang soạn; `weekday` null = chưa chọn thứ (hàng mới thêm).
class _Row {
  _Row({this.weekday, this.start = '17:30', this.duration = 90});
  int? weekday;
  String start;
  int duration;
}

class _RulesForm extends StatefulWidget {
  const _RulesForm({
    required this.cls,
    required this.draft,
    required this.onSaved,
  });

  final TeachClass cls;
  final OnboardingDraft draft;
  final Future<bool> Function() onSaved;

  @override
  State<_RulesForm> createState() => _RulesFormState();
}

class _RulesFormState extends State<_RulesForm> {
  static const _durations = [60, 90, 120];

  /// Độ rộng cột Thứ · Giờ · Thời lượng: "90 phút" cần chỗ hơn "T2".
  static const _flex = (8, 9, 10);

  late final _keys = _store().keys(widget.draft, 'rules');
  late final List<_Row> _rows = widget.cls.scheduleRules.isEmpty
      ? [_Row(weekday: 1)] // Figma: mặc định "T2 · 17:30 · 90 phút"
      : [
          for (final r in widget.cls.scheduleRules)
            _Row(
              weekday: r.weekday,
              start: r.startTime,
              duration: r.durationMin,
            ),
        ];
  bool _saving = false;
  bool _failed = false;

  List<ScheduleRule> get _rules => [
    for (final r in _rows)
      if (r.weekday != null)
        ScheduleRule(
          weekday: r.weekday!,
          startTime: r.start,
          durationMin: r.duration,
        ),
  ];

  /// Hàng chồng giờ với một hàng trước nó cùng thứ: (chỉ số hàng sau, hàng trước).
  (int, _Row)? get _overlap {
    for (var j = 1; j < _rows.length; j++) {
      for (var i = 0; i < j; i++) {
        final a = _rows[i], b = _rows[j];
        if (a.weekday == null || a.weekday != b.weekday) continue;
        final aS = minutesOf(a.start), bS = minutesOf(b.start);
        if (aS < bS + b.duration && bS < aS + a.duration) return (j, a);
      }
    }
    return null;
  }

  bool get _valid =>
      _rows.every((r) => r.weekday != null) &&
      _overlap == null &&
      _rows.every((r) => minutesOf(r.start) + r.duration <= 1440);

  String _day(MiniAppLocalizations l10n, int d) =>
      l10n.classesWeekdayShort('$d');

  static String _hhmm(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:'
      '${(m % 60).toString().padLeft(2, '0')}';

  /// "T4 11/11 · 17:30–19:00": ngày đầu tiên từ hôm bắt đầu có buổi theo lịch.
  String? _firstSession(MiniAppLocalizations l10n) {
    final rules = _rules;
    if (rules.isEmpty) return null;
    final start = DateTime.tryParse(widget.cls.startDate) ?? DateTime.now();
    final today = DateUtils.dateOnly(DateTime.now());
    final from = start.isAfter(today) ? start : today;
    for (var k = 0; k < 7; k++) {
      final d = from.add(Duration(days: k));
      final hits = rules.where((r) => r.weekday == d.weekday).toList()
        ..sort((a, b) => minutesOf(a.startTime) - minutesOf(b.startTime));
      if (hits.isEmpty) continue;
      final r = hits.first;
      final s = minutesOf(r.startTime);
      return '${_day(l10n, r.weekday)} ${d.day}/${d.month} · '
          '${r.startTime}–${_hhmm(s + r.durationMin)}';
    }
    return null;
  }

  String _summary(MiniAppLocalizations l10n) {
    final rules = [..._rules]
      ..sort(
        (a, b) => a.weekday != b.weekday
            ? a.weekday - b.weekday
            : minutesOf(a.startTime) - minutesOf(b.startTime),
      );
    return rules
        .map((r) => '${_day(l10n, r.weekday)} ${r.startTime}')
        .join(' · ');
  }

  Future<void> _pickTime(_Row row) async {
    final p = row.start.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1])),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => row.start = _hhmm(picked.hour * 60 + picked.minute));
  }

  Future<void> _record() async {
    setState(() => _failed = false);
    final ok = await widget.onSaved();
    if (mounted && !ok) setState(() => _failed = true);
  }

  Future<void> _save() async {
    final l10n = context.miniAppL10n;
    final c = widget.cls;
    final fee = widget.draft.pendingFee;
    // Học phí "Trọn khóa" chọn ở bước 1 được ghi cùng lịch (cần lịch để tính).
    final input = ClassInput(
      name: c.name,
      subject: c.subject,
      grade: c.grade,
      mode: c.mode,
      location: c.location,
      capacity: c.capacity,
      startDate: c.startDate,
      endDate: c.endDate,
      feeType: fee == null ? c.feeType : FeeType.fromWire(fee.feeType),
      feeAmount: fee?.amount ?? c.feeAmount,
      feeRules: c.feeRules,
    );
    setState(() => _saving = true);
    final cubit = ClassFormCubit(classesRepository(), initial: c, keys: _keys);
    await cubit.save(input, _rules);
    final saved = cubit.state.saved;
    final error = saved == null ? _classError(l10n, cubit.state) : null;
    await cubit.close();
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved == null) {
      _snack(context, error!);
      return;
    }
    if (fee != null) {
      await _store().update((d) => d.copyWith(clearPendingFee: true));
    }
    if (mounted) await _record();
  }

  Widget _labels(BuildContext context, MiniAppLocalizations l10n) {
    final style = Theme.of(context).textTheme.labelMedium;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            flex: _flex.$1,
            child: Text('${l10n.onboardingRuleWeekday} *', style: style),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: _flex.$2,
            child: Text('${l10n.onboardingRuleStart} *', style: style),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: _flex.$3,
            child: Text(l10n.onboardingRuleDuration, style: style),
          ),
          if (_rows.length > 1) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, MiniAppLocalizations l10n, int i) {
    final row = _rows[i];
    final overlap = _overlap;
    final scheme = Theme.of(context).colorScheme;
    final err = overlap != null && overlap.$1 == i
        ? l10n.onboardingRuleOverlap(
            _day(l10n, overlap.$2.weekday!),
            overlap.$2.start,
          )
        : null;
    const decoration = InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: _flex.$1,
                child: DropdownButtonFormField<int>(
                  initialValue: row.weekday,
                  isExpanded: true,
                  // Cỡ chữ thân như ô giờ: "90 phút" vừa cột.
                  style: Theme.of(context).textTheme.bodyLarge,
                  iconSize: 20,
                  decoration: decoration,
                  hint: Text(l10n.onboardingRuleWeekday),
                  items: [
                    for (var d = 1; d <= 7; d++)
                      DropdownMenuItem(value: d, child: Text(_day(l10n, d))),
                  ],
                  onChanged: (d) => setState(() => row.weekday = d),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: _flex.$2,
                child: InkWell(
                  onTap: () => _pickTime(row),
                  child: InputDecorator(
                    decoration: decoration.copyWith(
                      prefixIcon: const Icon(Icons.schedule, size: 18),
                      prefixIconConstraints: const BoxConstraints(minWidth: 32),
                    ),
                    child: Text(row.start),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: _flex.$3,
                child: DropdownButtonFormField<int>(
                  initialValue: _durations.contains(row.duration)
                      ? row.duration
                      : null,
                  isExpanded: true,
                  // Cỡ chữ thân như ô giờ: "90 phút" vừa cột.
                  style: Theme.of(context).textTheme.bodyLarge,
                  iconSize: 20,
                  decoration: decoration,
                  items: [
                    for (final m in _durations)
                      DropdownMenuItem(
                        value: m,
                        child: Text(
                          l10n.onboardingRuleDurationValue(m),
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                  ],
                  onChanged: (m) => setState(() => row.duration = m ?? 90),
                ),
              ),
              if (_rows.length > 1)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(width: 40),
                  padding: EdgeInsets.zero,
                  tooltip: l10n.onboardingRuleRemove(i + 1),
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _rows.removeAt(i)),
                ),
            ],
          ),
          if (err != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                err,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.error),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final first = _valid ? _firstSession(l10n) : null;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ..._heading(
                context,
                l10n.onboardingScheduleTitle,
                l10n.onboardingScheduleCaption,
              ),
              Text(
                '${l10n.onboardingRulesLabel} *',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _labels(context, l10n),
              for (var i = 0; i < _rows.length; i++)
                // Key theo đối tượng hàng: xóa hàng giữa không lẫn giá trị.
                KeyedSubtree(
                  key: ObjectKey(_rows[i]),
                  child: _row(context, l10n, i),
                ),
              Align(
                alignment: Alignment.centerLeft,
                // Nút phụ trung tính (DS v2); Figma: chép giờ và thời lượng của
                // hàng cuối, thứ để trống.
                child: AppButton(
                  label: '+ ${l10n.onboardingRuleAdd}',
                  variant: AppButtonVariant.outlinePrimary,
                  onPressed: _rows.length >= 14
                      ? null
                      : () => setState(
                          () => _rows.add(
                            _Row(
                              start: _rows.last.start,
                              duration: _rows.last.duration,
                            ),
                          ),
                        ),
                ),
              ),
              if (first != null) ...[
                const SizedBox(height: 16),
                AppCard.outlined(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.onboardingFirstSession(first),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _summary(l10n),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_failed) _Notice(message: l10n.onboardingSaved, onRetry: _record),
        _ActionBar(
          label: _saving ? l10n.onboardingSaving : l10n.onboardingFinishSetup,
          onPressed: _valid && !_saving && !_failed ? _save : null,
        ),
      ],
    );
  }
}
