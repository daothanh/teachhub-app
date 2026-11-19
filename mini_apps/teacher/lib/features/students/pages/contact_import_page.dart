import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';
import '../cubit/contact_import_cubit.dart';
import '../data/contacts_service.dart';
import '../data/student_models.dart';
import '../data/student_repository.dart';
import 'student_form_page.dart' show studentErrorMessage;

/// [US-1.4 AC2] Thêm nhiều học viên từ danh bạ. Mở từ nút "Thêm từ danh bạ" ở
/// form T07; trả id học viên đầu tiên đã lưu, hoặc `null` (nhập tay / chưa lưu gì).
class ContactImportPage extends StatelessWidget {
  const ContactImportPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    // Hỏi quyền ngay khi trang mở: trang chỉ mở sau khi người dùng bấm nút.
    create: (_) => ContactImportCubit(
      GetIt.I<ContactsService>(),
      GetIt.I<StudentRepository>(),
    )..start(),
    child: const _ImportView(),
  );
}

class _ImportView extends StatelessWidget {
  const _ImportView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return BlocBuilder<ContactImportCubit, ContactImportState>(
      builder: (context, state) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          Navigator.pop(
            context,
            state.rows.where((r) => r.savedId != null).firstOrNull?.savedId,
          );
        },
        child: Scaffold(
          appBar: AppBar(title: Text(l10n.contactsTitle)),
          body: switch (state.phase) {
            ImportPhase.requesting => const Center(
              child: CircularProgressIndicator(),
            ),
            ImportPhase.denied ||
            ImportPhase.permanentlyDenied => _Denied(state: state),
            ImportPhase.picking => _Picking(state: state),
            ImportPhase.review => _Review(state: state),
          },
        ),
      ),
    );
  }
}

class _Denied extends StatelessWidget {
  const _Denied({required this.state});
  final ContactImportState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cubit = context.read<ContactImportCubit>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.contactsDeniedTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        Text(l10n.contactsDeniedBody),
        const SizedBox(height: 16),
        AppButton(
          label: l10n.contactsOpenSettings,
          onPressed: cubit.openSettings,
        ),
        if (state.phase == ImportPhase.denied) ...[
          const SizedBox(height: 8),
          AppButton(
            label: l10n.contactsAllow,
            variant: AppButtonVariant.outlinePrimary,
            onPressed: cubit.start,
          ),
        ],
        const SizedBox(height: 8),
        AppButton(
          label: l10n.contactsManual,
          variant: AppButtonVariant.outlinePrimary,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

class _Picking extends StatelessWidget {
  const _Picking({required this.state});
  final ContactImportState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cubit = context.read<ContactImportCubit>();
    if (state.loadFailed || state.contacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            state.loadFailed ? l10n.contactsLoadFailed : l10n.contactsEmpty,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: state.contacts.length,
            itemBuilder: (context, i) {
              final c = state.contacts[i];
              return CheckboxListTile(
                value: state.selected.contains(c.id),
                onChanged: (_) => cubit.toggle(c.id),
                title: Text(c.name),
                subtitle: Text(normalizePhone(c.phone) ?? l10n.contactsNoPhone),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AppButton(
              label: l10n.contactsContinue(state.selected.length),
              onPressed: state.selected.isEmpty ? null : cubit.confirmSelection,
              disabled: state.selected.isEmpty,
            ),
          ),
        ),
      ],
    );
  }
}

class _Review extends StatelessWidget {
  const _Review({required this.state});
  final ContactImportState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cubit = context.read<ContactImportCubit>();
    final pending = state.toSend.length;
    final allSaved =
        state.rows.isNotEmpty &&
        state.rows.every((r) => r.status == RowStatus.saved);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.contactsReviewHint),
              for (final r in state.rows)
                _RowTile(key: ValueKey(r.id), row: r, locked: state.saving),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.hasSaved && pending == 0 || allSaved)
                  AppButton(
                    label: l10n.contactsDone,
                    onPressed: () => Navigator.pop(
                      context,
                      state.rows.where((r) => r.savedId != null).first.savedId,
                    ),
                  )
                else
                  AppButton(
                    label: state.saving
                        ? l10n.studentsSaving
                        : l10n.contactsSaveAll(pending),
                    onPressed: state.canSave ? cubit.saveAll : null,
                    disabled: !state.canSave,
                  ),
                if (!state.hasSaved && !state.saving) ...[
                  const SizedBox(height: 8),
                  AppButton(
                    label: l10n.contactsBack,
                    variant: AppButtonVariant.outlinePrimary,
                    onPressed: cubit.backToPicking,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({super.key, required this.row, required this.locked});
  final DraftRow row;
  final bool locked;

  String _status(MiniAppLocalizations l10n) => switch (row.status) {
    RowStatus.pending => '',
    RowStatus.saving => l10n.contactsRowSaving,
    RowStatus.saved => l10n.contactsRowSaved,
    RowStatus.duplicate => l10n.contactsRowDuplicate,
    RowStatus.failed =>
      '${l10n.contactsRowFailed}. ${studentErrorMessage(l10n, row.error!)}',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cubit = context.read<ContactImportCubit>();
    final enabled = row.editable && !locked;
    final status = _status(l10n);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Semantics(
        container: true,
        label: [row.name, status].where((s) => s.isNotEmpty).join(', '),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextFormField(
                    initialValue: row.name,
                    label: l10n.studentsFullName,
                    enabled: enabled,
                    maxLength: 120,
                    forceErrorText: row.nameValid
                        ? null
                        : l10n.studentsFullNameRequired,
                    onChanged: (v) => cubit.edit(row.id, name: v),
                  ),
                ),
                IconButton(
                  tooltip: l10n.contactsRemoveRow(row.name),
                  icon: const Icon(Icons.close),
                  onPressed: row.editable && !locked
                      ? () => cubit.remove(row.id)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppTextFormField(
              initialValue: row.phone,
              label: l10n.studentsGuardianPhone,
              enabled: enabled,
              keyboardType: TextInputType.phone,
              forceErrorText: row.phoneValid
                  ? null
                  : l10n.studentsGuardianPhoneInvalid,
              onChanged: (v) => cubit.edit(row.id, phone: v),
            ),
            if (status.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                status,
                style: TextStyle(
                  color: row.status == RowStatus.failed
                      ? Theme.of(context).colorScheme.error
                      : null,
                ),
              ),
            ],
            if (row.status == RowStatus.duplicate && !locked)
              TextButton(
                onPressed: () => _showDuplicate(context, row),
                child: Text(l10n.contactsRowReview),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showDuplicate(BuildContext context, DraftRow row) {
  final cubit = context.read<ContactImportCubit>();
  final l10n = context.miniAppL10n;
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.studentsDuplicateTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.studentsDuplicateBody),
            for (final StudentCandidate c in row.candidates) ...[
              const SizedBox(height: 12),
              Text(c.fullName, style: Theme.of(ctx).textTheme.titleSmall),
              Text([c.dob, c.school].whereType<String>().join(' · ')),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    cubit.pickExisting(row.id, c);
                  },
                  child: Text(l10n.studentsDuplicateSame),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.studentsDuplicateCancel),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            cubit.confirmNew(row.id);
          },
          child: Text(l10n.studentsDuplicateNew),
        ),
      ],
    ),
  );
}
