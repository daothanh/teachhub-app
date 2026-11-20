import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';
import '../cubit/history_cubit.dart';
import '../data/attendance_models.dart';
import '../data/attendance_repository.dart';
import '../widgets_status.dart';

/// Nhật ký sửa điểm danh của buổi (US-3.3 AC2): chỉ tên người sửa, thời điểm,
/// trước/sau.
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.sessionId, this.repository});
  final String sessionId;
  final AttendanceRepository? repository;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        HistoryCubit(repository ?? attendanceRepository(), sessionId)..load(),
    child: const _HistoryView(),
  );
}

String _time(DateTime t) {
  final l = t.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(l.day)}/${two(l.month)} ${two(l.hour)}:${two(l.minute)}';
}

class _HistoryView extends StatelessWidget {
  const _HistoryView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cubit = context.read<HistoryCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, s) => switch (s.load) {
          HistoryLoad.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          HistoryLoad.failure => AppEmptyState(
            message: l10n.historyLoadFailed,
            action: AppButton(
              label: l10n.attendanceRetry,
              onPressed: cubit.load,
            ),
          ),
          HistoryLoad.ready when s.items.isEmpty => AppEmptyState(
            message: l10n.historyEmpty,
          ),
          HistoryLoad.ready => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              for (final i in s.items) _Item(item: i),
              if (s.nextCursor != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: AppButton(
                    label: s.loadingMore ? '…' : l10n.historyLoadMore,
                    variant: AppButtonVariant.outlinePrimary,
                    onPressed: s.loadingMore ? null : cubit.loadMore,
                  ),
                ),
            ],
          ),
        },
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.item});
  final HistoryItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final after = item.after;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.studentName, style: text.titleSmall),
          Text(
            l10n.historyChangedBy(
              item.changedByName ?? l10n.historyUnknownUser,
              _time(item.changedAt),
            ),
            style: text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (item.before?.status case final st?)
                AttendanceStatusLabel(st)
              else
                Text(l10n.historyFirst, style: text.bodyMedium),
              const Icon(Icons.arrow_forward, size: 18),
              if (after?.status case final st?) AttendanceStatusLabel(st),
            ],
          ),
          if (item.before != null && item.before!.note != after?.note)
            Text(
              '${l10n.historyNote(item.before!.note ?? l10n.historyNoNote)} → '
              '${after?.note ?? l10n.historyNoNote}',
              style: text.bodySmall,
            )
          else if ((after?.note ?? '').isNotEmpty)
            Text(l10n.historyNote(after!.note!), style: text.bodySmall),
        ],
      ),
    );
  }
}
