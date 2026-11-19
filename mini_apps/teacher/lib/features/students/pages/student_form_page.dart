import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../../l10n/l10n.dart';
import '../cubit/student_form_cubit.dart';
import '../data/student_models.dart';
import '../data/student_repository.dart';

/// [T07] Thêm học viên. Route `/t/students/new`.
class StudentFormPage extends StatelessWidget {
  const StudentFormPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.miniAppL10n.studentsFormTitle)),
    body: StudentFormScope(onSaved: (_) => context.pop()),
  );
}

/// Form kèm cubit, dùng cho trang riêng và bước 2 của onboarding.
class StudentFormScope extends StatelessWidget {
  const StudentFormScope({super.key, required this.onSaved});

  /// Gọi với id học viên vừa tạo hoặc hồ sơ có sẵn được chọn.
  final ValueChanged<String> onSaved;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => StudentFormCubit(GetIt.I<StudentRepository>()),
    child: StudentFormView(onSaved: onSaved),
  );
}

String studentErrorMessage(MiniAppLocalizations l10n, ApiException e) =>
    switch (e.kind) {
      ApiErrorKind.paymentRequired => l10n.studentsErrorLimit,
      ApiErrorKind.conflict => l10n.studentsErrorBusy,
      ApiErrorKind.validation => l10n.studentsErrorValidation,
      ApiErrorKind.network => l10n.studentsErrorNetwork,
      _ => l10n.studentsErrorGeneric,
    };

class _GuardianControllers {
  final name = TextEditingController();
  final phone = TextEditingController();
  void dispose() {
    name.dispose();
    phone.dispose();
  }
}

class StudentFormView extends StatefulWidget {
  const StudentFormView({super.key, required this.onSaved});

  final ValueChanged<String> onSaved;

  @override
  State<StudentFormView> createState() => _StudentFormViewState();
}

class _StudentFormViewState extends State<StudentFormView> {
  static const _maxGuardians = 2;
  static final _phoneRe = RegExp(r'^\+?[0-9]{8,15}$');

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _dob = TextEditingController();
  final _school = TextEditingController();
  final _note = TextEditingController();
  final _guardians = <_GuardianControllers>[];
  DateTime? _dobValue;

  @override
  void dispose() {
    for (final c in [_name, _dob, _school, _note]) {
      c.dispose();
    }
    for (final g in _guardians) {
      g.dispose();
    }
    super.dispose();
  }

  String? _trimmed(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  StudentDraft _draft() => StudentDraft(
    fullName: _name.text.trim(),
    dob: _dobValue,
    school: _trimmed(_school),
    note: _trimmed(_note),
    guardians: [
      for (final g in _guardians)
        GuardianDraft(fullName: g.name.text.trim(), phone: _trimmed(g.phone)),
    ],
  );

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dobValue ?? DateTime(now.year - 10),
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      _dobValue = picked;
      _dob.text = MaterialLocalizations.of(context).formatCompactDate(picked);
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<StudentFormCubit>().submit(_draft());
    }
  }

  Future<void> _showDuplicate(List<StudentCandidate> candidates) async {
    final cubit = context.read<StudentFormCubit>();
    final l10n = context.miniAppL10n;
    // Chỉ nhận lần bấm đầu: tránh gửi hai lần khi bấm nhanh.
    var acted = false;
    void once(BuildContext ctx, VoidCallback action) {
      if (acted) return;
      acted = true;
      Navigator.pop(ctx);
      action();
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.studentsDuplicateTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.studentsDuplicateBody),
              for (final c in candidates) ...[
                const SizedBox(height: 12),
                Text(c.fullName, style: Theme.of(ctx).textTheme.titleSmall),
                Text([c.dob, c.school].whereType<String>().join(' · ')),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => once(ctx, () => cubit.pickExisting(c)),
                    child: Text(l10n.studentsDuplicateSame),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => once(ctx, cubit.dismissDuplicate),
            child: Text(l10n.studentsDuplicateCancel),
          ),
          TextButton(
            onPressed: () => once(ctx, cubit.confirmNew),
            child: Text(l10n.studentsDuplicateNew),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return BlocConsumer<StudentFormCubit, StudentFormState>(
      listener: (context, state) {
        switch (state.status) {
          case StudentFormStatus.duplicate:
            _showDuplicate(state.candidates);
          case StudentFormStatus.success:
            widget.onSaved(state.savedId!);
          case StudentFormStatus.failure:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(studentErrorMessage(l10n, state.error!))),
            );
          case StudentFormStatus.idle || StudentFormStatus.submitting:
            break;
        }
      },
      builder: (context, state) {
        final busy = state.status == StudentFormStatus.submitting;
        // Đã lưu thì khóa form: bấm lại sẽ tạo học viên thứ hai.
        final locked = state.status == StudentFormStatus.success;
        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppTextFormField(
                controller: _name,
                label: l10n.studentsFullName,
                required: true,
                enabled: !locked,
                maxLength: 120,
                validator: (v) => (v ?? '').trim().isEmpty
                    ? l10n.studentsFullNameRequired
                    : null,
              ),
              const SizedBox(height: 12),
              AppTextFormField(
                controller: _dob,
                label: l10n.studentsDob,
                readOnly: true,
                enabled: !locked,
                onTap: _pickDob,
              ),
              const SizedBox(height: 12),
              AppTextFormField(
                controller: _school,
                enabled: !locked,
                label: l10n.studentsSchool,
                maxLength: 120,
              ),
              const SizedBox(height: 12),
              AppTextFormField(
                controller: _note,
                enabled: !locked,
                label: l10n.studentsNote,
                maxLines: 3,
                maxLength: 1000,
              ),
              for (final (i, g) in _guardians.indexed) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.studentsGuardianTitle(i + 1),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    TextButton(
                      onPressed: locked
                          ? null
                          : () => setState(() {
                              _guardians.removeAt(i).dispose();
                            }),
                      child: Text(l10n.studentsRemoveGuardian(i + 1)),
                    ),
                  ],
                ),
                AppTextFormField(
                  controller: g.name,
                  enabled: !locked,
                  label: l10n.studentsGuardianName,
                  maxLength: 120,
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? l10n.studentsGuardianNameRequired
                      : null,
                ),
                const SizedBox(height: 12),
                AppTextFormField(
                  controller: g.phone,
                  enabled: !locked,
                  label: l10n.studentsGuardianPhone,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    final t = (v ?? '').trim();
                    return t.isEmpty || _phoneRe.hasMatch(t)
                        ? null
                        : l10n.studentsGuardianPhoneInvalid;
                  },
                ),
              ],
              if (_guardians.length < _maxGuardians && !locked)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () =>
                        setState(() => _guardians.add(_GuardianControllers())),
                    child: Text(l10n.studentsAddGuardian),
                  ),
                ),
              const SizedBox(height: 16),
              AppButton(
                label: busy ? l10n.studentsSaving : l10n.studentsSave,
                onPressed: busy || locked ? null : _submit,
                disabled: busy || locked,
              ),
            ],
          ),
        );
      },
    );
  }
}
