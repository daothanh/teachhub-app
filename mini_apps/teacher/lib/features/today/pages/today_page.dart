import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../../data/sync/connectivity.dart';
import '../../../l10n/l10n.dart';
import '../../attendance/attendance_routes.dart';
import '../../attendance/data/attendance_models.dart';
import '../../attendance/data/attendance_repository.dart';
import '../../classes/classes_routes.dart';
import '../../onboarding/data/onboarding_models.dart';
import '../../onboarding/data/onboarding_repository.dart';
import '../cubit/today_cubit.dart';

/// T03 "Hôm nay": màn chính của giáo viên (route `/t`).
class TodayPage extends StatelessWidget {
  const TodayPage({
    super.key,
    this.online,
    this.repository,
    this.onboardingRepository,
    this.inviteClassId,
  });

  /// Vừa xong onboarding: mở sheet gợi ý mời phụ huynh của lớp này một lần.
  final String? inviteClassId;

  /// Trạng thái mạng; mặc định [onlineChanges].
  final Stream<bool>? online;
  final AttendanceRepository? repository;
  final OnboardingRepository? onboardingRepository;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => TodayCubit(
      repository ?? attendanceRepository(),
      onboardingRepository ??
          (GetIt.I.isRegistered<OnboardingRepository>()
              ? GetIt.I<OnboardingRepository>()
              : null),
    )..start(),
    child: _TodayView(online: online, inviteClassId: inviteClassId),
  );
}

class _TodayView extends StatefulWidget {
  const _TodayView({this.online, this.inviteClassId});
  final Stream<bool>? online;
  final String? inviteClassId;

  @override
  State<_TodayView> createState() => _TodayViewState();
}

class _TodayViewState extends State<_TodayView> {
  late final Stream<bool> _online = (widget.online ?? onlineChanges())
      .distinct();

  @override
  void initState() {
    super.initState();
    final classId = widget.inviteClassId;
    if (classId != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _suggestInvite(classId),
      );
    }
  }

  /// Sheet "Mời phụ huynh theo dõi lớp" sau onboarding (Figma T02-3 → T03).
  Future<void> _suggestInvite(String classId) async {
    if (!mounted) return;
    final l10n = context.miniAppL10n;
    final send = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.todayInviteTitle,
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.todayInviteBody),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l10n.todayInviteSend,
                width: double.infinity,
                onPressed: () => Navigator.pop(ctx, true),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.todayInviteLater),
              ),
            ],
          ),
        ),
      ),
    );
    if (send == true && mounted) {
      await context.push(ClassesRoutes.inviteAll(classId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cubit = context.read<TodayCubit>();
    final chip = RoleSwitcherScope.chipOf(context);
    return Scaffold(
      appBar: AppBar(
        // Chip vai trò của shell (C20, mở T00); chạy riêng mini-app thì hiện tên
        // không gian và nút đổi vai trò.
        title: chip ?? Text(l10n.spaceTitle),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.todaySettings,
            onPressed: () => context.push(TeachHubRoutes.settings),
          ),
          if (chip == null)
            TextButton(
              onPressed: () => context.go(TeachHubRoutes.rolePicker),
              child: Text(l10n.switchRole),
            ),
        ],
      ),
      body: Column(
        children: [
          StreamBuilder<bool>(
            stream: _online,
            builder: (context, snap) =>
                snap.data == false ||
                    context.select((TodayCubit c) => c.state.offline)
                ? AppBanner(
                    tone: AppStatusTone.warning,
                    description: l10n.offlineBanner,
                    fullWidth: true,
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: cubit.refresh,
              child: const _TodayList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayList extends StatelessWidget {
  const _TodayList();

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final s = context.watch<TodayCubit>().state;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(l10n.todayTitle, style: text.headlineSmall),
        if (s.pending > 0)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                avatar: const Icon(Icons.sync, size: 18),
                label: Text(l10n.todayPending(s.pending)),
              ),
            ),
          ),
        if (s.error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              l10n.todayRefreshFailed,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (s.skippedSteps.isNotEmpty) _OnboardingCard(steps: s.skippedSteps),
        const SizedBox(height: AppSpacing.md),
        if (!s.loaded)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (s.sessions.isEmpty)
          AppEmptyState(
            message: l10n.todayEmpty,
            subMessage: l10n.todayEmptyHint,
          )
        else
          for (final session in s.sessions) _SessionCard(session: session),
      ],
    );
  }
}

String _stepTitle(MiniAppLocalizations l10n, OnboardingStep s) => switch (s) {
  OnboardingStep.createClass => l10n.onboardingStepCreateClass,
  OnboardingStep.addStudents => l10n.onboardingStepAddStudents,
  OnboardingStep.setSchedule => l10n.onboardingStepSetSchedule,
};

/// Nhắc các bước onboarding đã bỏ qua (US-0.2 AC2); bấm một bước thì mở đúng bước.
class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({required this.steps});
  final List<OnboardingStep> steps;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cubit = context.read<TodayCubit>();
    return Card(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.todayOnboardingTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final step in steps)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_stepTitle(l10n, step)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await context.push(
                    '${TeachHubRoutes.teacher}/onboarding?step=${step.wire}',
                  );
                  cubit.refresh();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});
  final TodaySession session;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final status = session.cancelled
        ? l10n.todaySessionCancelled
        : session.attended
        ? l10n.todaySessionAttended
        : l10n.todaySessionNotAttended;
    final icon = session.cancelled
        ? Icons.block
        : session.attended
        ? Icons.check_circle_outline
        : Icons.radio_button_unchecked;
    return Semantics(
      container: true,
      label: l10n.todaySessionSemantics(
        session.className,
        session.startTime,
        status,
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.startTime, style: text.titleMedium),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(session.className, style: text.titleMedium),
                  ),
                ],
              ),
              if (session.isMakeup)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Chip(label: Text(l10n.scheduleMakeup)),
                ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: Text(status, style: text.bodyMedium)),
                  if (!session.cancelled)
                    AppButton(
                      label: l10n.todayTakeAttendance,
                      size: AppButtonSize.sm,
                      onPressed: () =>
                          context.push(AttendanceRoutes.sheet(session.id)),
                    ),
                ],
              ),
              if (session.cancelled && session.cancelReason != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    l10n.scheduleCancelReason(session.cancelReason!),
                    style: text.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
