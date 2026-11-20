import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';
import '../attendance_routes.dart';
import '../cubit/attendance_cubit.dart';
import '../data/attendance_models.dart';
import '../data/attendance_repository.dart';
import '../widgets_status.dart';

/// T04: điểm danh 1 chạm (US-3.1) và sửa trong 7 ngày (US-3.3).
class AttendancePage extends StatelessWidget {
  const AttendancePage({
    super.key,
    required this.sessionId,
    this.repository,
    this.analytics = const NoopAttendanceAnalytics(),
  });

  final String sessionId;
  final AttendanceRepository? repository;
  final AttendanceAnalytics analytics;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => AttendanceCubit(
      repository ?? attendanceRepository(),
      sessionId,
      analytics: analytics,
    )..load(),
    child: _AttendanceView(sessionId: sessionId),
  );
}

class _AttendanceView extends StatelessWidget {
  const _AttendanceView({required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cubit = context.read<AttendanceCubit>();
    return BlocConsumer<AttendanceCubit, AttendanceState>(
      listenWhen: (a, b) =>
          (!a.saved && b.saved) || (!a.saveFailed && b.saveFailed),
      listener: (context, s) {
        if (s.saved) {
          if (context.canPop()) context.pop();
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.attendanceSaveFailed)));
        }
      },
      builder: (context, s) {
        final sheet = s.sheet;
        return Scaffold(
          appBar: AppBar(
            title: Text(sheet?.className ?? l10n.attendanceTitle),
            actions: [
              IconButton(
                tooltip: l10n.attendanceHistory,
                icon: const Icon(Icons.history),
                onPressed: () =>
                    context.push(AttendanceRoutes.history(sessionId)),
              ),
            ],
          ),
          body: Column(
            children: [
              if (s.offline)
                AppBanner(
                  tone: AppStatusTone.warning,
                  description: l10n.attendanceOfflineNotice,
                  fullWidth: true,
                ),
              if (s.readOnly != null)
                AppBanner(
                  tone: AppStatusTone.info,
                  description: switch (s.readOnly!) {
                    ReadOnlyReason.cancelled =>
                      l10n.attendanceReadOnlyCancelled,
                    ReadOnlyReason.windowClosed =>
                      l10n.attendanceReadOnlyWindow,
                  },
                  fullWidth: true,
                ),
              if (sheet?.hasFailure ?? false)
                AppBanner(
                  tone: AppStatusTone.error,
                  description: sheet!.batchErrorCode == null
                      ? l10n.attendanceRejectedGeneric
                      : _batchText(l10n, sheet.batchErrorCode!),
                  actionLabel: l10n.attendanceDiscard,
                  onAction: cubit.discardFailed,
                  fullWidth: true,
                ),
              Expanded(child: _Body(state: s)),
              SafeArea(
                minimum: const EdgeInsets.all(AppSpacing.lg),
                child: AppButton(
                  label: s.saving ? l10n.attendanceSaving : l10n.attendanceSave,
                  width: double.infinity,
                  onPressed: s.canSave ? cubit.save : null,
                  disabled: !s.canSave,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _batchText(MiniAppLocalizations l10n, String code) => switch (code) {
  'NOT_FOUND' => l10n.attendanceBatchNotFound,
  'SESSION_CANCELLED' => l10n.attendanceBatchCancelled,
  _ => l10n.attendanceBatchGeneric,
};

String _rejectedText(MiniAppLocalizations l10n, String code) => switch (code) {
  'ATTENDANCE_EDIT_WINDOW_CLOSED' => l10n.attendanceRejectedWindow,
  'READONLY_PLAN_LIMIT' => l10n.attendanceRejectedPlan,
  'NOT_FOUND' => l10n.attendanceRejectedNotFound,
  _ => l10n.attendanceRejectedGeneric,
};

class _Body extends StatelessWidget {
  const _Body({required this.state});
  final AttendanceState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cubit = context.read<AttendanceCubit>();
    final students = state.sheet?.students ?? const <SheetStudent>[];
    return switch (state.load) {
      AttendanceLoad.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      AttendanceLoad.failure => AppEmptyState(
        message: l10n.attendanceLoadFailed,
        action: AppButton(label: l10n.attendanceRetry, onPressed: cubit.load),
      ),
      AttendanceLoad.ready when students.isEmpty => AppEmptyState(
        message: l10n.attendanceEmptyRoster,
      ),
      AttendanceLoad.ready => ListView.separated(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: students.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) => _StudentRow(
          key: ValueKey(students[i].studentId),
          student: students[i],
        ),
      ),
    };
  }
}

class _StudentRow extends StatefulWidget {
  const _StudentRow({super.key, required this.student});
  final SheetStudent student;

  @override
  State<_StudentRow> createState() => _StudentRowState();
}

class _StudentRowState extends State<_StudentRow> {
  late final _note = TextEditingController(text: widget.student.note ?? '');
  late bool _noteOpen = (widget.student.note ?? '').isNotEmpty;

  final _focus = FocusNode();

  /// Ghi chú đổi từ nguồn khác (bỏ bản bị từ chối, làm mới): cập nhật ô nhập,
  /// trừ khi người dùng đang gõ.
  @override
  void didUpdateWidget(_StudentRow old) {
    super.didUpdateWidget(old);
    final note = widget.student.note ?? '';
    if (old.student.note != widget.student.note &&
        !_focus.hasFocus &&
        _note.text != note) {
      _note.text = note;
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cubit = context.read<AttendanceCubit>();
    final state = context.watch<AttendanceCubit>().state;
    final s = widget.student;
    final status = state.statusOf(s);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: state.editable,
                  label: l10n.attendanceStudentSemantics(
                    s.fullName,
                    attendanceStatusLabel(l10n, status),
                  ),
                  excludeSemantics: true,
                  onTap: state.editable ? () => cubit.tap(s.studentId) : null,
                  child: InkWell(
                    onTap: state.editable ? () => cubit.tap(s.studentId) : null,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.fullName,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(child: AttendanceStatusLabel(status)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.attendanceNoteToggle(s.fullName),
                isSelected: _noteOpen,
                icon: const Icon(Icons.edit_note_outlined),
                selectedIcon: const Icon(Icons.edit_note),
                onPressed: () => setState(() => _noteOpen = !_noteOpen),
              ),
            ],
          ),
          if (_noteOpen)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: TextField(
                controller: _note,
                focusNode: _focus,
                enabled: state.editable,
                maxLength: attendanceNoteMax,
                maxLines: null,
                decoration: InputDecoration(
                  labelText: l10n.attendanceNoteLabel,
                ),
                onChanged: (t) => cubit.setNote(s.studentId, t),
              ),
            ),
          if (s.rejectedCode != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                _rejectedText(l10n, s.rejectedCode!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}
