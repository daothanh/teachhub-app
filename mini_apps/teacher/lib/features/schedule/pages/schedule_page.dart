import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../data/sync/connectivity.dart';
import '../../../l10n/l10n.dart';
import '../../attendance/attendance_routes.dart';
import '../../classes/data/class_models.dart' show SessionStatus;
import '../cubit/schedule_cubit.dart';
import '../data/schedule_models.dart';
import '../data/schedule_repository.dart';

/// T05 "Lịch": buổi của mọi lớp theo ngày hoặc tuần (tuần bắt đầu Thứ Hai).
class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key, this.online, this.repository, this.now});

  /// Trạng thái mạng; mặc định [onlineChanges].
  final Stream<bool>? online;
  final ScheduleRepository? repository;
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        ScheduleCubit(repository ?? scheduleRepository(), now: now)..start(),
    child: _ScheduleView(online: online),
  );
}

class _ScheduleView extends StatefulWidget {
  const _ScheduleView({this.online});
  final Stream<bool>? online;

  @override
  State<_ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<_ScheduleView> {
  late final Stream<bool> _online = (widget.online ?? onlineChanges())
      .distinct();

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cubit = context.read<ScheduleCubit>();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scheduleTitle),
        centerTitle: false,
        // Ở thanh trên để thanh công cụ không tràn khi chữ phóng to.
        actions: [
          TextButton(onPressed: cubit.goToday, child: Text(l10n.scheduleToday)),
        ],
      ),
      body: Column(
        children: [
          StreamBuilder<bool>(
            stream: _online,
            builder: (context, snap) =>
                snap.data == false ||
                    context.select((ScheduleCubit c) => c.state.offline)
                ? AppBanner(
                    tone: AppStatusTone.warning,
                    description: l10n.scheduleOfflineBanner,
                    fullWidth: true,
                  )
                : const SizedBox.shrink(),
          ),
          const _Toolbar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: cubit.refresh,
              child: const _Body(),
            ),
          ),
        ],
      ),
    );
  }
}

String _two(int n) => n.toString().padLeft(2, '0');
String _ddMM(DateTime d) => '${_two(d.day)}/${_two(d.month)}';
String _ddMMyyyy(DateTime d) => '${_ddMM(d)}/${d.year}';

class _Toolbar extends StatelessWidget {
  const _Toolbar();

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cubit = context.read<ScheduleCubit>();
    final s = context.watch<ScheduleCubit>().state;
    final label = s.mode == ScheduleMode.day
        ? l10n.scheduleDayHeading(
            l10n.classesWeekday('${s.from.weekday}'),
            _ddMMyyyy(s.from),
          )
        : l10n.scheduleWeekRange(_ddMM(s.from), _ddMMyyyy(s.to));
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ScheduleMode>(
              segments: [
                ButtonSegment(
                  value: ScheduleMode.day,
                  label: Text(l10n.scheduleModeDay),
                ),
                ButtonSegment(
                  value: ScheduleMode.week,
                  label: Text(l10n.scheduleModeWeek),
                ),
              ],
              selected: {s.mode},
              showSelectedIcon: false,
              onSelectionChanged: (v) => cubit.setMode(v.single),
            ),
          ),
          Row(
            children: [
              IconButton(
                tooltip: l10n.schedulePrevious,
                icon: const Icon(Icons.chevron_left),
                onPressed: () => cubit.shift(-1),
              ),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                tooltip: l10n.scheduleNext,
                icon: const Icon(Icons.chevron_right),
                onPressed: () => cubit.shift(1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cubit = context.read<ScheduleCubit>();
    final s = context.watch<ScheduleCubit>().state;
    final retry = AppButton(
      label: l10n.scheduleRetry,
      variant: AppButtonVariant.outlinePrimary,
      onPressed: cubit.refresh,
    );
    final children = <Widget>[
      if (s.error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Column(
            children: [
              Text(
                l10n.scheduleLoadFailed,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (s.sessions.isNotEmpty) retry,
            ],
          ),
        ),
      if (s.loading)
        const Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (s.sessions.isEmpty)
        Column(
          children: [
            // Lỗi đã có dòng báo ở trên; chỉ báo "rỗng" khi tải được mà không có buổi.
            if (s.error == null) AppEmptyState(message: l10n.scheduleEmpty),
            const SizedBox(height: AppSpacing.sm),
            retry,
          ],
        )
      else
        ..._grouped(context, s),
    ];
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: children,
    );
  }

  /// Tuần: mỗi ngày một tiêu đề. Ngày: không cần tiêu đề (đã có trên thanh trên).
  List<Widget> _grouped(BuildContext context, ScheduleState s) {
    final l10n = context.miniAppL10n;
    final out = <Widget>[];
    String? last;
    for (final x in s.sessions) {
      if (s.mode == ScheduleMode.week && x.sessionDate != last) {
        last = x.sessionDate;
        final d = DateTime.tryParse(x.sessionDate);
        if (d != null) {
          out.add(
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: AppSpacing.xs,
              ),
              child: Text(
                l10n.scheduleDayHeading(
                  l10n.classesWeekday('${d.weekday}'),
                  _ddMM(d),
                ),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          );
        }
      }
      out.add(_SessionCard(session: x));
    }
    return out;
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});
  final ScheduleSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final cancelled = session.cancelled;
    final status = switch (session.status) {
      SessionStatus.planned => l10n.classesSessionPlanned,
      SessionStatus.taught => l10n.classesSessionTaught,
      SessionStatus.cancelled => l10n.scheduleCancelled,
    };
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    // Buổi hủy: gạch ngang và màu phụ (đủ tương phản), không làm mờ cả thẻ.
    final title = text.titleMedium?.copyWith(
      decoration: cancelled ? TextDecoration.lineThrough : null,
      color: cancelled ? muted : null,
    );
    void open() => context.push(AttendanceRoutes.sheet(session.id));
    return Semantics(
      container: true,
      button: !cancelled,
      // Một nhãn gọn cho cả thẻ, không đọc lại từng Text bên trong.
      excludeSemantics: true,
      onTap: cancelled ? null : open,
      label: [
        l10n.todaySessionSemantics(
          session.className,
          session.startTime,
          status,
        ),
        if (session.isMakeup) l10n.scheduleMakeup,
        if (cancelled && session.cancelReason != null)
          l10n.scheduleCancelReason(session.cancelReason!),
      ].join(', '),
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: InkWell(
          // Buổi đã hủy không có gì để điểm danh.
          onTap: cancelled ? null : open,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.startTime, style: title),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Text(session.className, style: title)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      status,
                      style: text.bodyMedium?.copyWith(
                        color: cancelled ? muted : null,
                      ),
                    ),
                    if (session.isMakeup)
                      Chip(
                        avatar: const Icon(Icons.event_repeat, size: 18),
                        label: Text(l10n.scheduleMakeup),
                      ),
                  ],
                ),
                if (cancelled && session.cancelReason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      l10n.scheduleCancelReason(session.cancelReason!),
                      style: text.bodySmall?.copyWith(color: muted),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
