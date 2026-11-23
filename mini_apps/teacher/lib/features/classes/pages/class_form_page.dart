import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../../l10n/l10n.dart';
import '../../fees/data/fee_models.dart';
import '../cubit/class_form_cubit.dart';
import '../data/class_models.dart';
import '../data/classes_repository.dart';
import '../../plan/plan_routes.dart';
import '../widgets/class_fee_section.dart';
import '../widgets/classes_error_text.dart';
import '../widgets/read_only_field.dart';
import '../widgets/schedule_rules_editor.dart';

/// Phần form hiện ra: onboarding tách tạo lớp (bước 1) và đặt lịch (bước 3).
enum ClassFormPart { all, basics, schedule }

/// T06b: tạo/sửa lớp kèm quy tắc lặp. Đóng với [TeachClass] đã lưu.
///
/// Sửa: truyền [initial] hoặc chỉ [classId] (tự tải).
class ClassFormPage extends StatelessWidget {
  const ClassFormPage({
    super.key,
    this.classId,
    this.initial,
    this.repository,
    this.onSaved,
    this.part = ClassFormPart.all,
    this.embedded = false,
    this.keys,
  });
  final String? classId;
  final TeachClass? initial;
  final ClassesRepository? repository;

  /// Thay cho việc đóng màn khi nhúng vào luồng khác (onboarding).
  final ValueChanged<TeachClass>? onSaved;
  final ClassFormPart part;

  /// Nhúng trong màn khác: không có thanh tiêu đề riêng.
  final bool embedded;

  /// Khóa bền vững (onboarding); null = khóa trong bộ nhớ.
  final DraftKeys? keys;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ClassFormCubit(
      repository ?? classesRepository(),
      initial: initial,
      classId: classId,
      keys: keys,
    )..load(),
    child: _FormView(onSaved: onSaved, part: part, embedded: embedded),
  );
}

class _FormView extends StatelessWidget {
  const _FormView({this.onSaved, required this.part, required this.embedded});
  final ValueChanged<TeachClass>? onSaved;
  final ClassFormPart part;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return BlocConsumer<ClassFormCubit, ClassFormState>(
      listenWhen: (a, b) => a.saved != b.saved && b.saved != null,
      listener: (context, s) {
        final n = s.sessionsGenerated;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              n == null
                  ? l10n.classesFormSaved
                  : l10n.classesFormSavedSessions(n),
            ),
          ),
        );
        if (onSaved != null) {
          onSaved!(s.saved!);
        } else {
          context.pop(s.saved);
        }
      },
      builder: (context, s) {
        final editing = s.initial != null;
        final body = s.loading
            ? (s.error == null
                  ? const Center(child: CircularProgressIndicator())
                  : AppEmptyState(
                      message: classesErrorText(l10n, s.error!),
                      action: AppButton(
                        label: l10n.classesRetry,
                        onPressed: context.read<ClassFormCubit>().load,
                      ),
                    ))
            : _FormBody(initial: s.initial, state: s, part: part);
        // Nhúng trong màn khác: dùng Scaffold của màn đó (không lồng Scaffold
        // con tự co theo bàn phím lần hai).
        if (embedded) return body;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              editing ? l10n.classesFormEditTitle : l10n.classesFormNewTitle,
            ),
          ),
          body: body,
        );
      },
    );
  }
}

class _FormBody extends StatefulWidget {
  const _FormBody({
    required this.initial,
    required this.state,
    required this.part,
  });
  final TeachClass? initial;
  final ClassFormState state;
  final ClassFormPart part;

  @override
  State<_FormBody> createState() => _FormBodyState();
}

class _FormBodyState extends State<_FormBody> {
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _subject = TextEditingController(text: widget.initial?.subject);
  late final _grade = TextEditingController(
    text: widget.initial?.grade.toString(),
  );
  late final _location = TextEditingController(text: widget.initial?.location);
  late final _capacity = TextEditingController(
    text: widget.initial?.capacity?.toString(),
  );
  late ClassMode _mode = widget.initial?.mode ?? ClassMode.offline;
  late String? _start = widget.initial?.startDate;
  late String? _end = widget.initial?.endDate;
  late List<ScheduleRule> _rules = [...?widget.initial?.scheduleRules];

  // Lớp chưa có học phí (lớp mới, lớp cũ) mở form với công tắc tắt.
  late bool _feeOn = widget.initial?.feeType != null;
  late FeeType _feeType = widget.initial?.feeType ?? FeeType.perSession;
  late FeeRules _feeRules = widget.initial?.feeRules ?? const FeeRules();
  late final _feeAmount = TextEditingController(
    text: widget.initial?.feeAmount == null
        ? null
        : formatVnd(widget.initial!.feeAmount!),
  );
  late final _feeInstallments = TextEditingController(
    text: (widget.initial?.feeRules?.installments ?? 1).toString(),
  );

  @override
  void dispose() {
    for (final c in [
      _name, _subject, _grade, _location, _capacity, //
      _feeAmount, _feeInstallments,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  ClassInput get _input => ClassInput(
    name: _name.text,
    subject: _subject.text,
    grade: int.tryParse(_grade.text.trim()),
    mode: _mode,
    location: _location.text,
    capacity: int.tryParse(_capacity.text.trim()),
    startDate: _start,
    endDate: _end,
    feeType: _feeOn ? _feeType : null,
    // Ô trống = chưa nhập (null); chuỗi quá dài không đọc được = 0 để báo sai.
    feeAmount: !_feeOn || _feeAmount.text.isEmpty
        ? null
        : (parseVnd(_feeAmount.text) ?? 0),
    // Số đợt chỉ có nghĩa với trọn khóa; kiểu khác luôn 1.
    feeRules: _feeOn
        ? _feeRules.copyWith(
            installments: _feeType == FeeType.course
                ? int.tryParse(_feeInstallments.text.trim()) ?? 0
                : 1,
          )
        : null,
  );

  /// Lỗi server của trường (ưu tiên) hoặc lỗi kiểm tra ở máy.
  String? _error(String field) {
    final l10n = context.miniAppL10n;
    final server = widget.state.serverErrors[field];
    if (server != null && server.isNotEmpty) return server.join('\n');
    return switch (widget.state.clientErrors[field]) {
      null => null,
      ClassFieldError.required => l10n.classesErrRequired,
      ClassFieldError.gradeRange => l10n.classesErrGrade,
      ClassFieldError.capacityRange => l10n.classesErrCapacity,
      ClassFieldError.endBeforeStart => l10n.classesErrEndBeforeStart,
      ClassFieldError.rulesDuplicate => l10n.classesErrRulesDuplicate,
      ClassFieldError.rulesDuration => l10n.classesErrRulesDuration,
      ClassFieldError.rulesOverflow => l10n.classesErrRulesOverflow,
      ClassFieldError.rulesTooMany => l10n.classesErrRulesTooMany,
      ClassFieldError.feeAmountRequired => l10n.classesErrFeeAmountRequired,
      ClassFieldError.feeAmountRange => l10n.classesErrFeeAmountRange,
      ClassFieldError.feeInstallments => l10n.classesErrFeeInstallments,
      ClassFieldError.feeCourseNeedsSchedule =>
        l10n.classesErrFeeCourseSchedule,
    };
  }

  Future<void> _pickDate({required bool start}) async {
    final current = DateTime.tryParse((start ? _start : _end) ?? '');
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => start ? _start = isoDate(picked) : _end = isoDate(picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final s = widget.state;
    final part = widget.part;
    const gap = SizedBox(height: AppSpacing.lg);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (s.error != null) ...[
          AppBanner(
            tone: AppStatusTone.error,
            description: classesErrorText(l10n, s.error!),
            fullWidth: true,
            // 402 hết hạn mức: mở T14 (US-0.7 AC1).
            actionLabel: s.error!.kind == ApiErrorKind.paymentRequired
                ? l10n.planLimitAction
                : null,
            onAction: s.error!.kind == ApiErrorKind.paymentRequired
                ? () => context.push(PlanRoutes.plan)
                : null,
          ),
          gap,
        ],
        if (part != ClassFormPart.schedule) ...[
          AppInput(
            controller: _name,
            label: l10n.classesFieldName,
            required: true,
            maxLength: 120,
            errorText: _error('name'),
          ),
          gap,
          AppInput(
            controller: _subject,
            label: l10n.classesFieldSubject,
            required: true,
            maxLength: 80,
            errorText: _error('subject'),
          ),
          gap,
          AppInput(
            controller: _grade,
            label: l10n.classesFieldGrade,
            required: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            errorText: _error('grade'),
          ),
          gap,
          Text(
            l10n.classesFieldMode,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppChoiceChip(
                label: l10n.classesModeOffline,
                selected: _mode == ClassMode.offline,
                onTap: () => setState(() => _mode = ClassMode.offline),
              ),
              AppChoiceChip(
                label: l10n.classesModeOnline,
                selected: _mode == ClassMode.online,
                onTap: () => setState(() => _mode = ClassMode.online),
              ),
            ],
          ),
          // Địa điểm chỉ có ở lớp tại chỗ (US-1.1 AC1).
          if (_mode == ClassMode.offline) ...[
            gap,
            AppInput(
              controller: _location,
              label: l10n.classesFieldLocation,
              maxLength: 200,
              errorText: _error('location'),
            ),
          ],
          gap,
          AppInput(
            controller: _capacity,
            label: l10n.classesFieldCapacity,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            errorText: _error('capacity'),
          ),
          gap,
          _DateField(
            label: l10n.classesFieldStart,
            value: _start,
            required: true,
            error: _error('startDate'),
            onTap: () => _pickDate(start: true),
          ),
          gap,
          _DateField(
            label: l10n.classesFieldEnd,
            value: _end,
            error: _error('endDate'),
            onTap: () => _pickDate(start: false),
            onClear: _end == null ? null : () => setState(() => _end = null),
          ),
        ],
        if (part == ClassFormPart.all) gap,
        if (part != ClassFormPart.basics) ...[
          ScheduleRulesEditor(
            rules: _rules,
            error: _error('rules'),
            onChanged: (r) => setState(() => _rules = r),
          ),
        ],
        // Onboarding không hỏi học phí: cấu hình sau trong màn lớp.
        if (part == ClassFormPart.all) ...[
          gap,
          ClassFeeSection(
            enabled: _feeOn,
            type: _feeType,
            rules: _feeRules,
            amount: _feeAmount,
            installments: _feeInstallments,
            onEnabled: (v) => setState(() => _feeOn = v),
            onType: (t) => setState(() => _feeType = t),
            onRules: (r) => setState(() => _feeRules = r),
            typeError: _error('feeType'),
            amountError: _error('feeAmount'),
            rulesError: _error('feeRules'),
          ),
        ],
        gap,
        AppButton(
          label: l10n.classesSave,
          width: double.infinity,
          disabled: s.saving,
          onPressed: () => context.read<ClassFormCubit>().save(_input, _rules),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.required = false,
    this.error,
    this.onClear,
  });
  final String label;
  final String? value;
  final bool required;
  final String? error;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return ReadOnlyField(
      text: value == null ? '' : displayDate(value!),
      label: label,
      hint: l10n.classesPickDate,
      required: required,
      onTap: onTap,
      errorText: error,
      suffix: onClear == null
          ? const Icon(Icons.calendar_today_outlined)
          : IconButton(
              tooltip: l10n.classesClearEnd,
              icon: const Icon(Icons.close),
              onPressed: onClear,
            ),
    );
  }
}
