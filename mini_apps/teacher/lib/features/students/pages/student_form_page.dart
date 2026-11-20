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
import 'contact_import_page.dart';

/// [T07] Thêm học viên. Route `/t/students/new`.
class StudentFormPage extends StatelessWidget {
  const StudentFormPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.miniAppL10n.studentsFormTitle)),
    body: StudentFormScope(onSaved: (_) => context.pop()),
  );
}

/// Form kèm cubit, dùng cho trang riêng và bước 2 của onboarding. Có [initial]
/// thì là form sửa học viên đó (S4-FL-01).
class StudentFormScope extends StatelessWidget {
  const StudentFormScope({super.key, required this.onSaved, this.initial});

  /// Gọi với id học viên vừa tạo hoặc hồ sơ có sẵn được chọn.
  final ValueChanged<String> onSaved;
  final Student? initial;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        StudentFormCubit(GetIt.I<StudentRepository>(), studentId: initial?.id),
    child: StudentFormView(onSaved: onSaved, initial: initial),
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
  _GuardianControllers([GuardianDraft? from])
    : id = from?.id,
      email = from?.email,
      relation = from?.relation ?? GuardianRelation.guardian {
    name.text = from?.fullName ?? '';
    phone.text = from?.phone ?? '';
  }

  /// Phụ huynh có sẵn (giữ `id`, `email` khi sửa); null = người mới.
  final String? id;
  final String? email;
  GuardianRelation relation;
  final name = TextEditingController();
  final phone = TextEditingController();
  void dispose() {
    name.dispose();
    phone.dispose();
  }
}

class StudentFormView extends StatefulWidget {
  const StudentFormView({super.key, required this.onSaved, this.initial});

  final ValueChanged<String> onSaved;
  final Student? initial;

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

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    if (s == null) return;
    _name.text = s.fullName;
    _school.text = s.school ?? '';
    _note.text = s.note ?? '';
    _dobValue = s.dob == null ? null : DateTime.tryParse(s.dob!);
    _guardians.addAll([for (final g in s.guardians) _GuardianControllers(g)]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Chữ ngày sinh theo locale nên chỉ dựng được khi đã có context.
    if (_dobValue != null && _dob.text.isEmpty) {
      _dob.text = MaterialLocalizations.of(
        context,
      ).formatCompactDate(_dobValue!);
    }
  }

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
        GuardianDraft(
          id: g.id,
          email: g.email,
          relation: g.relation,
          fullName: g.name.text.trim(),
          phone: _trimmed(g.phone),
        ),
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

  Future<void> _importFromContacts() async {
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ContactImportPage()),
    );
    if (id != null && mounted) widget.onSaved(id);
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
              if (!_editing) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: locked ? null : _importFromContacts,
                    icon: const Icon(Icons.contacts_outlined),
                    label: Text(l10n.contactsAdd),
                  ),
                ),
                const SizedBox(height: 8),
              ],
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
                // Wrap để chữ 200% đẩy nút xuống dòng thay vì tràn.
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      l10n.studentsGuardianTitle(i + 1),
                      style: Theme.of(context).textTheme.titleSmall,
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
                _RelationChips(
                  value: g.relation,
                  enabled: !locked,
                  onChanged: (r) => setState(() => g.relation = r),
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

/// Chọn quan hệ (bố, mẹ, người giám hộ). Dùng `Wrap` để xuống dòng khi chữ lớn.
class _RelationChips extends StatelessWidget {
  const _RelationChips({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final GuardianRelation value;
  final bool enabled;
  final ValueChanged<GuardianRelation> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return Semantics(
      container: true,
      label: l10n.studentsGuardianRelation,
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            l10n.studentsGuardianRelation,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          for (final r in GuardianRelation.values)
            ChoiceChip(
              label: Text(guardianRelationLabel(l10n, r)),
              selected: value == r,
              onSelected: enabled ? (_) => onChanged(r) : null,
            ),
        ],
      ),
    );
  }
}

String guardianRelationLabel(MiniAppLocalizations l10n, GuardianRelation r) =>
    switch (r) {
      GuardianRelation.father => l10n.studentsRelationFather,
      GuardianRelation.mother => l10n.studentsRelationMother,
      GuardianRelation.guardian => l10n.studentsRelationGuardian,
    };

/// [T07] bản sửa: tải hồ sơ đầy đủ (SĐT, phụ huynh) rồi hiện form. Route
/// `/t/students/:id/edit?classId=…`. Đóng với `true` khi đã lưu.
class StudentEditPage extends StatefulWidget {
  const StudentEditPage({
    super.key,
    required this.studentId,
    required this.classId,
    this.status = 'active',
  });

  final String studentId;
  final String classId;
  final String status;

  @override
  State<StudentEditPage> createState() => _StudentEditPageState();
}

class _StudentEditPageState extends State<StudentEditPage> {
  late Future<Student> _student = _load();

  Future<Student> _load() => GetIt.I<StudentRepository>().find(
    widget.studentId,
    classId: widget.classId,
    status: widget.status,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.studentsEditTitle)),
      body: FutureBuilder<Student>(
        future: _student,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data;
          if (data == null) {
            final e = snap.error;
            return AppEmptyState(
              message: e is ApiException
                  ? studentErrorMessage(l10n, e)
                  : l10n.studentsErrorGeneric,
              action: AppButton(
                label: l10n.classesRetry,
                onPressed: () => setState(() => _student = _load()),
              ),
            );
          }
          return StudentFormScope(
            initial: data,
            onSaved: (_) => context.pop(true),
          );
        },
      ),
    );
  }
}
