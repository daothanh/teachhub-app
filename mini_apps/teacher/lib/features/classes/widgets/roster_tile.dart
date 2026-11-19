import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';
import '../../invites/pages/invite_share_sheet.dart';
import '../../students/data/student_models.dart' show GuardianRelation;
import '../../students/pages/student_form_page.dart' show guardianRelationLabel;
import '../../students/students_routes.dart';
import '../data/class_models.dart';

String guardianStatusLabel(MiniAppLocalizations l10n, GuardianInviteStatus s) =>
    switch (s) {
      GuardianInviteStatus.notInvited => l10n.inviteStatusNotInvited,
      GuardianInviteStatus.invited => l10n.inviteStatusInvited,
      GuardianInviteStatus.activated => l10n.inviteStatusActivated,
      GuardianInviteStatus.expired => l10n.inviteStatusExpired,
    };

/// Một học viên trong danh sách lớp (T06a): tên, trạng thái mời của từng phụ
/// huynh và nút "Chia sẻ link" / "Gửi lại link" (US-1.6 AC4). Chạm tên để sửa
/// học viên và phụ huynh (T07).
class RosterTile extends StatelessWidget {
  const RosterTile({
    super.key,
    required this.classId,
    required this.entry,
    required this.onChanged,
  });

  final String classId;
  final RosterEntry entry;

  /// Có thay đổi (đã sửa học viên, đã cấp link): màn tải lại danh sách.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final e = entry;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              button: true,
              label: l10n.rosterEditSemantics(e.fullName),
              excludeSemantics: true,
              child: InkWell(
                onTap: () async {
                  final saved = await context.push<bool>(
                    StudentsRoutes.edit(
                      e.studentId,
                      classId: classId,
                      status: e.studentStatus,
                    ),
                  );
                  if (saved == true) onChanged();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Expanded(child: Text(e.fullName, style: text.titleSmall)),
                      if (e.studentStatus == 'paused')
                        Text(l10n.classesStudentPaused, style: text.bodySmall),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
            if (e.guardians.isEmpty)
              Text(l10n.rosterNoGuardians, style: text.bodySmall)
            else
              for (final g in e.guardians)
                _GuardianRow(
                  studentId: e.studentId,
                  studentName: e.fullName,
                  guardian: g,
                  onChanged: onChanged,
                ),
          ],
        ),
      ),
    );
  }
}

class _GuardianRow extends StatelessWidget {
  const _GuardianRow({
    required this.studentId,
    required this.studentName,
    required this.guardian,
    required this.onChanged,
  });

  final String studentId;
  final String studentName;
  final RosterGuardian guardian;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final g = guardian;
    final who = l10n.rosterGuardianLine(
      guardianRelationLabel(l10n, GuardianRelation.fromWire(g.relation)),
      g.fullName,
    );
    final status = guardianStatusLabel(l10n, g.inviteStatus);
    final expired = g.inviteStatus == GuardianInviteStatus.expired;
    final action = switch (g.inviteStatus) {
      GuardianInviteStatus.activated => null,
      GuardianInviteStatus.expired => l10n.inviteResend,
      _ => l10n.inviteShare,
    };
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Semantics(
        container: true,
        label: l10n.rosterGuardianSemantics(who, status),
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ExcludeSemantics(child: Text(who, style: text.bodyMedium)),
            ExcludeSemantics(
              child: Text(
                '· $status',
                style: text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: expired ? Theme.of(context).colorScheme.error : null,
                ),
              ),
            ),
            if (action != null)
              TextButton(
                onPressed: () async {
                  final done = await showInviteShareSheet(
                    context,
                    studentId: studentId,
                    studentName: studentName,
                    guardian: g,
                  );
                  if (done) onChanged();
                },
                child: Text(action),
              ),
          ],
        ),
      ),
    );
  }
}
