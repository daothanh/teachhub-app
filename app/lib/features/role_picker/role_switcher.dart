import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../core/routing/app_routes.dart';
import '../../l10n/l10n.dart';
import 'membership_cubit.dart';
import 'role_picker_page.dart';

/// Phạm vi của vai trò, lấy từ nhãn API ("Giáo viên · Cô Lan" → "Cô Lan").
String _scope(AppLocalizations l10n, Membership m) {
  final i = m.label.indexOf(' · ');
  return i >= 0
      ? m.label.substring(i + 3)
      : RolePickerPage.roleDescription(l10n, m.role);
}

/// C20 Chip vai trò ở App Bar `Root` của mọi không gian. Một vai trò → chỉ hiện
/// tên; nhiều vai trò → có ▾, chạm mở [showRoleSwitcher] (T00).
class RoleChip extends StatelessWidget {
  const RoleChip({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return BlocBuilder<MembershipCubit, MembershipState>(
      buildWhen: (a, b) =>
          a.active != b.active || a.memberships != b.memberships,
      builder: (context, state) {
        final active = state.active;
        if (active == null) return const SizedBox.shrink();
        final name = RolePickerPage.roleName(l10n, active.role);
        final multi = state.memberships.length > 1;
        final chip = Container(
          height: 32,
          padding: const EdgeInsets.fromLTRB(4, 0, 10, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: scheme.outlineVariant, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Avatar(name, size: 24),
              const SizedBox(width: 6),
              Text(
                name,
                style: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (multi) ...[
                const SizedBox(width: 4),
                const Icon(TeachHubIcons.caretDown, size: 16),
              ],
            ],
          ),
        );
        if (!multi) return chip;
        return Semantics(
          button: true,
          label: l10n.roleSwitchTitle,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => showRoleSwitcher(context),
            child: chip,
          ),
        );
      },
    );
  }
}

/// [T00] Chuyển vai trò: đổi vai trò không đăng nhập lại, không đổi JWT (spec
/// §3.7) — chỉ đổi trạng thái ở shell rồi điều hướng, nên dưới 1 giây.
Future<void> showRoleSwitcher(BuildContext context) {
  final l10n = context.l10n;
  final cubit = context.read<MembershipCubit>();
  final router = GoRouter.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final state = cubit.state;

  return AppBottomSheet.show<void>(
    context: context,
    title: l10n.roleSwitchTitle,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final m in state.memberships)
          Builder(
            builder: (sheet) {
              final current = m.id == state.active?.id;
              final name = RolePickerPage.roleName(l10n, m.role);
              return AppListTile(
                leading: _Avatar(name, size: 36),
                title: name,
                subtitle: _scope(l10n, m),
                selected: current,
                trailing: current
                    ? const Icon(TeachHubIcons.check, size: 20)
                    : null,
                // `Current`: không bấm được (spec T00 §6).
                onTap: current
                    ? null
                    : () async {
                        Navigator.of(sheet).pop();
                        await cubit.select(m);
                        router.go(m.role.rootRoute);
                        messenger
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(content: Text(l10n.roleSwitchedTo(name))),
                          );
                      },
              );
            },
          ),
        const Divider(height: 1),
        Builder(
          builder: (sheet) => AppListTile(
            leading: const Icon(TeachHubIcons.plus),
            title: l10n.roleAdd,
            onTap: () {
              Navigator.of(sheet).pop();
              router.push(AppRoutes.rolePicker);
            },
          ),
        ),
      ],
    ),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar(this.name, {required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
      child: Text(
        name.characters.first,
        style: TextStyle(
          color: scheme.onPrimary,
          fontSize: size * 0.45,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
