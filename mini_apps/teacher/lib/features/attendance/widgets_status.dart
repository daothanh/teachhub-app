import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import 'data/attendance_models.dart';

String attendanceStatusLabel(MiniAppLocalizations l10n, AttendanceStatus s) =>
    switch (s) {
      AttendanceStatus.present => l10n.attendanceStatusPresent,
      AttendanceStatus.late => l10n.attendanceStatusLate,
      AttendanceStatus.excused => l10n.attendanceStatusExcused,
      AttendanceStatus.unexcused => l10n.attendanceStatusUnexcused,
    };

/// Màu + biểu tượng + chữ: không chỉ dựa vào màu.
({Color color, IconData icon}) attendanceStatusStyle(AttendanceStatus s) =>
    switch (s) {
      AttendanceStatus.present => (
        color: Colors.green.shade800,
        icon: Icons.check_circle_outline,
      ),
      AttendanceStatus.late => (
        color: Colors.orange.shade900,
        icon: Icons.schedule,
      ),
      AttendanceStatus.excused => (
        color: Colors.blue.shade800,
        icon: Icons.event_busy_outlined,
      ),
      AttendanceStatus.unexcused => (
        color: Colors.red.shade800,
        icon: Icons.cancel_outlined,
      ),
    };

/// Nhãn trạng thái: nền nhạt cùng tông, chữ xuống dòng được khi chữ 130%.
class AttendanceStatusLabel extends StatelessWidget {
  const AttendanceStatusLabel(this.status, {super.key});
  final AttendanceStatus status;

  @override
  Widget build(BuildContext context) {
    final style = attendanceStatusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: style.color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 18, color: style.color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              attendanceStatusLabel(context.miniAppL10n, status),
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: style.color),
            ),
          ),
        ],
      ),
    );
  }
}
