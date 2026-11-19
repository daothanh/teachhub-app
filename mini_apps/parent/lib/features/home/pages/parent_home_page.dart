import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../../l10n/l10n.dart';
import '../../family/cubit/family_cubit.dart';
import '../../family/widgets/attendance_week_card.dart';

/// Dựng P05; gọi `onLinked` khi vừa nhận lời mời để P02 tải lại danh sách con.
typedef NoInviteBuilder =
    Widget Function(BuildContext context, VoidCallback onLinked);

/// P02: trang gốc của không gian Phụ huynh — chọn con, chuyên cần tuần, banner
/// bật thông báo. Chưa có con nào (chưa nhận lời mời) thì hiện P05 do host gắn
/// qua [noInviteBuilder] (mini-app không import host).
class ParentHomePage extends StatelessWidget {
  const ParentHomePage({super.key, this.noInviteBuilder});

  final NoInviteBuilder? noInviteBuilder;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return BlocBuilder<FamilyCubit, FamilyState>(
      builder: (context, state) {
        final hasChildren = state.students.isNotEmpty;
        return Scaffold(
          appBar: AppBar(
            // Chip vai trò của shell (C20, mở T00); chạy riêng mini-app thì hiện tên không gian.
            title: RoleSwitcherScope.chipOf(context) ?? Text(l10n.spaceTitle),
            centerTitle: false,
            actions: [
              if (hasChildren)
                IconButton(
                  tooltip: l10n.parentAddInvite,
                  icon: const Icon(Icons.person_add_alt_1),
                  onPressed: () async {
                    final cubit = context.read<FamilyCubit>();
                    await context.push(TeachHubRoutes.inviteEntry);
                    cubit.load();
                  },
                ),
            ],
          ),
          body: switch (state.status) {
            FamilyStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            FamilyStatus.failure => AppEmptyState(
              message: l10n.parentLoadFailed,
              action: AppButton(
                label: l10n.parentRetry,
                onPressed: context.read<FamilyCubit>().load,
              ),
            ),
            FamilyStatus.ready when !hasChildren => _NoInvite(
              builder: noInviteBuilder,
            ),
            FamilyStatus.ready => const _Children(),
          },
        );
      },
    );
  }
}

class _NoInvite extends StatelessWidget {
  const _NoInvite({this.builder});

  final NoInviteBuilder? builder;

  @override
  Widget build(BuildContext context) {
    final custom = builder;
    if (custom != null) {
      return custom(context, context.read<FamilyCubit>().load);
    }
    final l10n = context.miniAppL10n;
    return AppEmptyState(
      message: l10n.parentNoInviteTitle,
      subMessage: l10n.parentNoInviteBody,
      action: AppButton(
        label: l10n.parentAddInvite,
        onPressed: () async {
          final cubit = context.read<FamilyCubit>();
          await context.push(TeachHubRoutes.inviteEntry);
          cubit.load();
        },
      ),
    );
  }
}

class _Children extends StatelessWidget {
  const _Children();

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final theme = Theme.of(context);
    final cubit = context.read<FamilyCubit>();
    return BlocBuilder<FamilyCubit, FamilyState>(
      builder: (context, state) {
        final child = state.selected;
        return RefreshIndicator(
          onRefresh: cubit.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              if (state.notificationsOff) ...[
                _NotificationBanner(onEnable: cubit.enableNotifications),
                const SizedBox(height: 16),
              ],
              Semantics(
                label: l10n.parentPickChild,
                container: true,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in state.students)
                      ChoiceChip(
                        label: Text(s.fullName),
                        selected: s.id == state.selectedId,
                        onSelected: (_) => cubit.select(s.id),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (child != null)
                Text(
                  child.classes.isEmpty
                      ? l10n.parentNoClasses
                      : l10n.parentChildClasses(
                          child.classes
                              .map((c) => '${c.name} (${c.teacherName})')
                              .join(', '),
                        ),
                  style: theme.textTheme.bodyMedium,
                ),
              const SizedBox(height: 16),
              if (state.weekLoading && state.week == null)
                const Center(child: CircularProgressIndicator())
              else if (state.weekFailed)
                AppEmptyState(
                  message: l10n.parentLoadFailed,
                  action: AppButton(
                    label: l10n.parentRetry,
                    onPressed: cubit.retryWeek,
                  ),
                )
              else if (state.week != null)
                AttendanceWeekCard(week: state.week!),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationBanner extends StatelessWidget {
  const _NotificationBanner({required this.onEnable});

  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: '${l10n.notificationBannerTitle}. ${l10n.notificationBannerBody}',
      child: Card(
        color: theme.colorScheme.secondaryContainer,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Text(
                  l10n.notificationBannerTitle,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 4),
              ExcludeSemantics(child: Text(l10n.notificationBannerBody)),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: onEnable,
                  child: Text(l10n.notificationBannerAction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
