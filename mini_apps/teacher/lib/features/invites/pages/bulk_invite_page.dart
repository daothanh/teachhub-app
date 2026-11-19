import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';
import '../../classes/data/classes_repository.dart';
import '../../classes/widgets/classes_error_text.dart';
import '../../students/pages/student_form_page.dart' show guardianRelationLabel;
import '../../students/data/student_models.dart' show GuardianRelation;
import '../cubit/bulk_invite_cubit.dart';
import '../data/invite_repository.dart';
import '../data/invite_sharer.dart';
import 'invite_link_card.dart';

/// "Mời tất cả phụ huynh chưa kích hoạt" (US-1.6 AC3): tạo link cho từng người
/// rồi liệt kê để giáo viên gửi lần lượt. Route `/t/classes/:id/invite-all`.
class BulkInvitePage extends StatelessWidget {
  const BulkInvitePage({
    super.key,
    required this.classId,
    this.classes,
    this.invites,
  });
  final String classId;
  final ClassesRepository? classes;
  final InviteRepository? invites;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => BulkInviteCubit(
      classes ?? classesRepository(),
      invites ?? inviteRepository(),
      classId,
    )..start(),
    child: const _BulkView(),
  );
}

class _BulkView extends StatelessWidget {
  const _BulkView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cubit = context.read<BulkInviteCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.inviteAllTitle)),
      body: BlocBuilder<BulkInviteCubit, BulkInviteState>(
        builder: (context, s) => switch (s.status) {
          BulkInviteStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          BulkInviteStatus.failure => AppEmptyState(
            message: classesErrorText(l10n, s.error!),
            action: AppButton(label: l10n.classesRetry, onPressed: cubit.start),
          ),
          _ when s.items.isEmpty => AppEmptyState(message: l10n.inviteAllEmpty),
          _ => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Semantics(
                liveRegion: true,
                child: Text(
                  l10n.inviteAllProgress(s.ready, s.items.length),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.inviteAllHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              if (s.status == BulkInviteStatus.paused) ...[
                _PausedBanner(retryAfter: s.retryAfter, onResume: cubit.resume),
                const SizedBox(height: AppSpacing.md),
              ],
              for (final (i, item) in s.items.indexed)
                _BulkRow(
                  index: i,
                  item: item,
                  paused: s.status == BulkInviteStatus.paused,
                ),
            ],
          ),
        },
      ),
    );
  }
}

class _PausedBanner extends StatelessWidget {
  const _PausedBanner({required this.retryAfter, required this.onResume});
  final Duration? retryAfter;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final wait = retryAfter?.inSeconds;
    final message = retryAfter == null
        ? l10n.inviteAllPausedNetwork
        : wait != null && wait > 0
        ? l10n.inviteAllPausedRate(wait)
        : l10n.inviteAllPausedRateNoWait;
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(liveRegion: true, child: Text(message)),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: l10n.inviteAllResume,
              size: AppButtonSize.sm,
              onPressed: onResume,
            ),
          ],
        ),
      ),
    );
  }
}

class _BulkRow extends StatelessWidget {
  const _BulkRow({
    required this.index,
    required this.item,
    required this.paused,
  });
  final int index;
  final BulkInviteItem item;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final cubit = context.read<BulkInviteCubit>();
    final g = item.guardian;
    final link = item.link;
    final who = l10n.rosterGuardianLine(
      guardianRelationLabel(l10n, GuardianRelation.fromWire(g.relation)),
      g.fullName,
    );
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.studentName, style: text.titleSmall),
            Text(who, style: text.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            if (item.error != null) ...[
              Text(
                classesErrorText(l10n, item.error!),
                style: text.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => cubit.retry(index),
                  child: Text(l10n.classesRetry),
                ),
              ),
            ] else if (link == null && paused)
              Text(l10n.inviteAllWaiting, style: text.bodySmall)
            else if (link == null)
              Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(l10n.inviteAllCreating, style: text.bodySmall),
                  ),
                ],
              )
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Builder(
                    builder: (context) => AppButton(
                      label: item.shared
                          ? l10n.inviteAllShareAgain
                          : l10n.inviteShare,
                      size: AppButtonSize.sm,
                      onPressed: () async {
                        final opened = await inviteSharer().share(
                          inviteMessage(
                            l10n,
                            guardianName: g.fullName,
                            studentName: item.studentName,
                            link: link,
                          ),
                          origin: shareOrigin(context),
                        );
                        if (opened) cubit.markShared(index);
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) => SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: InviteLinkCard(
                          link: link,
                          studentName: item.studentName,
                          guardianName: g.fullName,
                          onShared: () => cubit.markShared(index),
                        ),
                      ),
                    ),
                    child: Text(l10n.inviteAllShowQr),
                  ),
                  if (item.shared)
                    Text(l10n.inviteAllSharedMark, style: text.bodySmall),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
