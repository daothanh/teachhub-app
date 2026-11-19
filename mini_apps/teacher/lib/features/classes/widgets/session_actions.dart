import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../../l10n/l10n.dart';
import '../../attendance/attendance_routes.dart';
import '../cubit/class_detail_cubit.dart';
import '../data/class_models.dart';
import 'classes_error_text.dart';

enum SessionAction { reschedule, cancel, makeup }

/// Thao tác khả dụng cho một buổi (US-2.2): đổi giờ chỉ buổi dự kiến, hủy chỉ
/// buổi dự kiến, tạo buổi bù cho buổi đã hủy mà chưa có buổi bù nào trỏ tới.
List<SessionAction> sessionActionsFor(ClassSession s, List<ClassSession> all) =>
    switch (s.status) {
      SessionStatus.planned => [SessionAction.reschedule, SessionAction.cancel],
      SessionStatus.cancelled =>
        all.any((x) => x.makeupOf == s.id) ? const [] : [SessionAction.makeup],
      SessionStatus.taught => const [],
    };

/// ISO 8601 từ ngày + giờ tường, dùng offset của buổi gốc ([refIso]) để giờ
/// luôn theo múi giờ tenant chứ không theo máy.
String sessionStartsAt(DateTime date, TimeOfDay time, String refIso) {
  final offset = RegExp(r'(Z|[+-]\d\d:\d\d)$').firstMatch(refIso)?.group(1);
  String two(int v) => v.toString().padLeft(2, '0');
  return '${isoDate(date)}T${two(time.hour)}:${two(time.minute)}:00${offset ?? 'Z'}';
}

/// Mở hộp thoại tương ứng; xong thì báo snackbar, 409 đã có điểm danh thì
/// hướng dẫn sang T04.
Future<void> runSessionAction(
  BuildContext context,
  ClassDetailCubit cubit,
  ClassSession session,
  SessionAction action,
) async {
  final result = await showDialog<_Outcome>(
    context: context,
    builder: (_) =>
        _SessionDialog(cubit: cubit, session: session, action: action),
  );
  if (!context.mounted || result == null) return;
  final l10n = context.miniAppL10n;
  if (result == _Outcome.hasAttendance) {
    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.sessionHasAttendanceTitle),
        content: Text(l10n.sessionHasAttendanceBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.sessionClose),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.sessionOpenAttendance),
          ),
        ],
      ),
    );
    if (open == true && context.mounted) {
      await context.push(AttendanceRoutes.sheet(session.id));
    }
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(switch (action) {
        SessionAction.reschedule => l10n.sessionDoneRescheduled,
        SessionAction.cancel => l10n.sessionDoneCancelled,
        SessionAction.makeup => l10n.sessionDoneMakeup,
      }),
    ),
  );
}

enum _Outcome { done, hasAttendance }

class _SessionDialog extends StatefulWidget {
  const _SessionDialog({
    required this.cubit,
    required this.session,
    required this.action,
  });
  final ClassDetailCubit cubit;
  final ClassSession session;
  final SessionAction action;

  @override
  State<_SessionDialog> createState() => _SessionDialogState();
}

class _SessionDialogState extends State<_SessionDialog> {
  static const _reasonMax = 300;
  late DateTime _date = DateTime.parse(widget.session.sessionDate);
  late TimeOfDay _time = () {
    final p = widget.session.startTime.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }();
  final _reason = TextEditingController();
  bool _busy = false;
  String? _error;

  bool get _needsTime => widget.action != SessionAction.cancel;
  bool get _needsReason => widget.action != SessionAction.makeup;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(now) ? now : _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  Future<void> _submit() async {
    final l10n = context.miniAppL10n;
    final s = widget.session;
    final reason = _reason.text.trim().isEmpty ? null : _reason.text.trim();
    String? startsAt;
    if (_needsTime) {
      startsAt = sessionStartsAt(_date, _time, s.startsAt);
      if (!DateTime.parse(startsAt).isAfter(DateTime.now())) {
        setState(() => _error = l10n.sessionErrPast);
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final ApiException? err = switch (widget.action) {
      SessionAction.reschedule => await widget.cubit.rescheduleSession(
        s,
        startsAt: startsAt!,
        reason: reason,
      ),
      SessionAction.cancel => await widget.cubit.cancelSession(
        s,
        reason: reason,
      ),
      SessionAction.makeup => await widget.cubit.makeupSession(
        s,
        startsAt: startsAt!,
      ),
    };
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).pop(_Outcome.done);
    } else if (err.code == ApiErrorCode.sessionHasAttendance) {
      Navigator.of(context).pop(_Outcome.hasAttendance);
    } else {
      setState(() {
        _busy = false;
        _error = switch (err.code) {
          ApiErrorCode.sessionCancelled => l10n.sessionErrCancelled,
          _ when err.kind == ApiErrorKind.validation => l10n.sessionErrPast,
          _ => classesErrorText(l10n, err),
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final title = switch (widget.action) {
      SessionAction.reschedule => l10n.sessionRescheduleTitle,
      SessionAction.cancel => l10n.sessionCancelTitle,
      SessionAction.makeup => l10n.sessionMakeupTitle,
    };
    final confirm = switch (widget.action) {
      SessionAction.reschedule => l10n.sessionConfirmReschedule,
      SessionAction.cancel => l10n.sessionConfirmCancel,
      SessionAction.makeup => l10n.sessionConfirmMakeup,
    };
    final error = Theme.of(context).colorScheme.error;
    return AlertDialog(
      title: Text(title),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.action == SessionAction.cancel) ...[
            Text(l10n.sessionCancelBody),
            const SizedBox(height: 12),
          ],
          if (_needsTime)
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: _busy ? null : _pickDate,
                  child: Text(
                    '${l10n.sessionPickDate}: ${displayDate(isoDate(_date))}',
                  ),
                ),
                OutlinedButton(
                  onPressed: _busy ? null : _pickTime,
                  child: Text(
                    '${l10n.sessionPickTime}: ${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ],
            ),
          if (_needsReason) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _reason,
              enabled: !_busy,
              maxLength: _reasonMax,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(labelText: l10n.sessionReasonLabel),
            ),
          ],
          if (_error != null)
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: TextStyle(color: error)),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.sessionClose),
        ),
        TextButton(
          style: widget.action == SessionAction.cancel
              ? TextButton.styleFrom(foregroundColor: error)
              : null,
          onPressed: _busy ? null : _submit,
          child: Text(confirm),
        ),
      ],
    );
  }
}

/// Hàng nút thao tác dưới một buổi; `Wrap` để chữ 200% xuống dòng.
class SessionActionBar extends StatelessWidget {
  const SessionActionBar({
    super.key,
    required this.session,
    required this.sessions,
  });
  final ClassSession session;
  final List<ClassSession> sessions;

  @override
  Widget build(BuildContext context) {
    final actions = sessionActionsFor(session, sessions);
    if (actions.isEmpty) return const SizedBox.shrink();
    final l10n = context.miniAppL10n;
    final cubit = context.read<ClassDetailCubit>();
    return Semantics(
      container: true,
      label: l10n.sessionActionsLabel(
        displayDate(session.sessionDate),
        session.startTime,
      ),
      child: Wrap(
        spacing: 8,
        children: [
          for (final a in actions)
            TextButton(
              onPressed: () => runSessionAction(context, cubit, session, a),
              child: Text(switch (a) {
                SessionAction.reschedule => l10n.sessionActionReschedule,
                SessionAction.cancel => l10n.sessionActionCancel,
                SessionAction.makeup => l10n.sessionActionMakeup,
              }),
            ),
        ],
      ),
    );
  }
}
