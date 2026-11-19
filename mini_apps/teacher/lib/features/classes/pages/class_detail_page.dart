import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';
import '../classes_routes.dart';
import '../cubit/class_detail_cubit.dart';
import '../cubit/classes_list_cubit.dart' show ClassesLoad;
import '../data/class_models.dart';
import '../data/classes_repository.dart';
import '../widgets/classes_error_text.dart';

/// T06a: chi tiết lớp, quy tắc lặp, buổi sắp tới, học viên, lưu trữ.
class ClassDetailPage extends StatelessWidget {
  const ClassDetailPage({super.key, required this.classId, this.repository});
  final String classId;
  final ClassesRepository? repository;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        ClassDetailCubit(repository ?? classesRepository(), classId)..load(),
    child: const _ClassDetailView(),
  );
}

class _ClassDetailView extends StatelessWidget {
  const _ClassDetailView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cubit = context.read<ClassDetailCubit>();
    return BlocConsumer<ClassDetailCubit, ClassDetailState>(
      listenWhen: (a, b) =>
          b.actionError != null && a.actionError != b.actionError,
      listener: (context, s) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(classesErrorText(l10n, s.actionError!))),
      ),
      builder: (context, s) {
        final cls = s.cls;
        return Scaffold(
          appBar: AppBar(
            title: Text(cls?.name ?? l10n.classesDetailTitle),
            actions: [
              if (cls != null && !cls.archived)
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'edit') {
                      final saved = await context.push<TeachClass>(
                        ClassesRoutes.edit(cls.id),
                        extra: cls,
                      );
                      if (saved != null) cubit.load();
                    } else {
                      await _confirmArchive(context, cubit);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Text(l10n.classesEdit)),
                    PopupMenuItem(
                      value: 'archive',
                      child: Text(l10n.classesArchive),
                    ),
                  ],
                ),
            ],
          ),
          body: switch (s.load) {
            ClassesLoad.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            ClassesLoad.failure => AppEmptyState(
              message: classesErrorText(l10n, s.error!),
              action: AppButton(
                label: l10n.classesRetry,
                onPressed: cubit.load,
              ),
            ),
            ClassesLoad.ready => _Body(state: s),
          },
        );
      },
    );
  }

  Future<void> _confirmArchive(
    BuildContext context,
    ClassDetailCubit cubit,
  ) async {
    final l10n = context.miniAppL10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.classesArchiveConfirmTitle),
        content: Text(l10n.classesArchiveConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.classesCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.classesArchive),
          ),
        ],
      ),
    );
    if (ok == true) await cubit.archive();
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});
  final ClassDetailState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cls = state.cls!;
    final text = Theme.of(context).textTheme;
    final modeText = cls.mode == ClassMode.offline
        ? l10n.classesModeOffline
        : l10n.classesModeOnline;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (cls.archived)
          AppBanner(
            tone: AppStatusTone.warning,
            description: l10n.classesArchivedBanner,
            fullWidth: true,
          ),
        Text(
          l10n.classesItemMeta(cls.subject, cls.grade),
          style: text.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        _Info(label: l10n.classesFieldMode, value: modeText),
        if ((cls.location ?? '').isNotEmpty)
          _Info(label: l10n.classesLabelLocation, value: cls.location!),
        if (cls.capacity != null)
          _Info(label: l10n.classesLabelCapacity, value: '${cls.capacity}'),
        _Info(label: l10n.classesLabelStart, value: displayDate(cls.startDate)),
        _Info(
          label: l10n.classesLabelEnd,
          value: cls.endDate == null
              ? l10n.classesNoEnd
              : displayDate(cls.endDate!),
        ),
        _Section(l10n.classesSectionSchedule),
        if (cls.scheduleRules.isEmpty) Text(l10n.classesNoRules),
        for (final r in cls.scheduleRules)
          Text(
            l10n.classesRuleLine(
              l10n.classesWeekday('${r.weekday}'),
              r.startTime,
              r.durationMin,
            ),
          ),
        if (!cls.archived) ...[
          _Section(l10n.classesSectionSessions),
          if (state.sessionsError)
            Text(l10n.classesSessionsLoadFailed)
          else if (state.sessions.isEmpty)
            Text(l10n.classesNoSessions),
          for (final s in state.sessions) _SessionTile(session: s),
        ],
        _Section(l10n.classesSectionStudents),
        if (state.roster.isEmpty) Text(l10n.classesNoStudents),
        for (final e in state.roster)
          AppListTile(
            title: e.fullName,
            trailingText: e.studentStatus == 'paused'
                ? l10n.classesStudentPaused
                : null,
          ),
        if (!cls.archived) ...[
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: l10n.classesAddStudent,
            variant: AppButtonVariant.outlinePrimary,
            width: double.infinity,
            onPressed: () async {
              final done = await context.push<bool>(
                ClassesRoutes.addStudent(cls.id),
              );
              if (done == true && context.mounted) {
                context.read<ClassDetailCubit>().load();
              }
            },
          ),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );
}

/// Nhãn trên, giá trị dưới: xuống dòng được khi chữ 130%.
class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.bodySmall),
          Text(value, style: text.bodyLarge),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});
  final ClassSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    String hm(DateTime t) {
      final l = t.toLocal();
      return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
    }

    final status = switch (session.status) {
      SessionStatus.planned => l10n.classesSessionPlanned,
      SessionStatus.taught => l10n.classesSessionTaught,
      SessionStatus.cancelled => l10n.classesSessionCancelled,
    };
    return AppListTile(
      title: l10n.classesSessionLine(
        displayDate(session.sessionDate),
        hm(session.startsAt),
        hm(session.endsAt),
      ),
      subtitle: session.isMakeup
          ? '$status · ${l10n.classesSessionMakeup}'
          : status,
    );
  }
}
