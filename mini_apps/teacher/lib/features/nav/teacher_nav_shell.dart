import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../l10n/l10n.dart';
import '../billing/billing_routes.dart';
import '../classes/classes_routes.dart';
import '../more/more_page.dart';
import '../schedule/schedule_routes.dart';

/// Một tab của Bottom Nav: đường dẫn gốc, nhãn, icon Solar (Linear/Bold).
typedef TeacherTab = ({
  String path,
  String icon,
  String Function(MiniAppLocalizations) label,
});

/// 5 tab của giáo viên (Figma `Navigation/Bottom Nav` · Role=Teacher).
final List<TeacherTab> teacherTabs = [
  (path: TeachHubRoutes.teacher, icon: 'home-2', label: (l) => l.navToday),
  (
    path: ScheduleRoutes.schedule,
    icon: 'calendar',
    label: (l) => l.navSchedule,
  ),
  (
    path: ClassesRoutes.list,
    icon: 'users-group-rounded',
    label: (l) => l.navClasses,
  ),
  (path: BillingRoutes.periods, icon: 'wallet', label: (l) => l.navFees),
  (path: MoreRoutes.more, icon: 'widget', label: (l) => l.navMore),
];

/// Bọc màn gốc của từng tab bằng Bottom Nav dạng viên nổi (DS v2). Màn con
/// (chi tiết, form) không có thanh để giữ chỗ cho Bottom Action Bar.
class TeacherNavShell extends StatelessWidget {
  const TeacherNavShell({super.key, required this.path, required this.child});

  final String path;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final index = teacherTabs.indexWhere((t) => t.path == path);
    if (index < 0) return child;
    return Scaffold(
      body: child,
      bottomNavigationBar: TeacherBottomNav(
        selected: index,
        onSelect: (i) {
          if (i == index) return;
          HapticFeedback.selectionClick();
          context.go(teacherTabs[i].path);
        },
      ),
    );
  }
}

/// Thanh nổi: viên bo tròn, nền `bg/surface` 88% + blur 24, viền `border/subtle`,
/// bóng mềm; tab đang chọn là viên lime với icon Bold và chữ đen.
class TeacherBottomNav extends StatelessWidget {
  const TeacherBottomNav({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.miniAppL10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                offset: Offset(0, 8),
                blurRadius: 24,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    for (final (i, tab) in teacherTabs.indexed)
                      Expanded(
                        child: _NavItem(
                          label: tab.label(l10n),
                          icon: tab.icon,
                          selected: i == selected,
                          onTap: () => onSelect(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Đang chọn: `action/primary/fg` (đen trên lime, đạt cả Light và Dark).
    final fg = selected ? scheme.onPrimary : scheme.onSurfaceVariant;
    final style = Theme.of(context).textTheme.labelSmall!.copyWith(
      color: fg,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
    );
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          height: 56,
          decoration: ShapeDecoration(
            color: selected ? scheme.primary : Colors.transparent,
            shape: const StadiumBorder(),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icons/solar/$icon${selected ? '-bold' : ''}.svg',
                package: 'teacher',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
