import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/l10n.dart';
import '../data/family_models.dart';

String _dm(BuildContext context, DateTime d) =>
    DateFormat.Md(Localizations.localeOf(context).toString()).format(d);

/// Card chuyên cần tuần của con (P02, US-0.3 AC4).
class AttendanceWeekCard extends StatelessWidget {
  const AttendanceWeekCard({super.key, required this.week});

  final AttendanceWeek week;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final theme = Theme.of(context);
    final s = week.summary;
    final counts = <(String, int)>[
      (l10n.attendancePresent, s.present),
      (l10n.attendanceLate, s.late),
      (l10n.attendanceExcused, s.excused),
      (l10n.attendanceUnexcused, s.unexcused),
      (l10n.attendanceNotRecorded, s.notRecorded),
      (l10n.attendanceUpcoming, s.upcoming),
    ];
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.attendanceWeekTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
            Text(
              l10n.attendanceWeekRange(
                _dm(context, week.weekStart),
                _dm(context, week.weekEnd),
              ),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, count) in counts)
                  Semantics(
                    container: true,
                    label: l10n.attendanceCount(label, count),
                    child: ExcludeSemantics(
                      child: Chip(label: Text('$label · $count')),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (week.sessions.isEmpty)
              Text(l10n.attendanceNoSessions)
            else
              for (final session in week.sessions)
                _SessionRow(session: session),
          ],
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session});

  final AttendanceSession session;

  String _markLabel(BuildContext context) {
    final l10n = context.miniAppL10n;
    if (session.cancelled) return l10n.attendanceCancelled;
    return switch (session.mark) {
      AttendanceMark.present => l10n.attendancePresent,
      AttendanceMark.late => l10n.attendanceLate,
      AttendanceMark.excused => l10n.attendanceExcused,
      AttendanceMark.unexcused => l10n.attendanceUnexcused,
      null => l10n.attendanceNotRecorded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final t = session.startsAt;
    final when = DateFormat.Md(
      Localizations.localeOf(context).toString(),
    ).add_Hm().format(t);
    final title = session.isMakeup
        ? '${session.className} (${l10n.attendanceMakeup})'
        : session.className;
    final mark = _markLabel(context);
    return Semantics(
      container: true,
      label: '${l10n.attendanceSessionLine(title, when)}, $mark',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text(title), Text(when)],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(child: Text(mark, textAlign: TextAlign.end)),
            ],
          ),
        ),
      ),
    );
  }
}
