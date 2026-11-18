import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:tasco_utils/tasco_utils.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../core/routing/app_routes.dart';
import '../../l10n/l10n.dart';
import 'membership_cubit.dart';

/// [T01c] "Bạn là…?" · [T00] Chuyển vai trò.
///
/// Liệt kê vai trò đã có để mở, và các vai trò còn thiếu để thêm. Chủ trung
/// tâm (T01d) thuộc Giai đoạn 2.
class RolePickerPage extends StatelessWidget {
  const RolePickerPage({super.key});

  static String roleName(AppLocalizations l10n, MembershipRole role) =>
      switch (role) {
        MembershipRole.tenantOwner => l10n.roleTeacher,
        MembershipRole.parent => l10n.roleParent,
        MembershipRole.student => l10n.roleStudent,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tasco;
    final text = Theme.of(context).textTheme;

    return BlocConsumer<MembershipCubit, MembershipState>(
      listenWhen: (a, b) => a.statusCreate != b.statusCreate,
      listener: (context, state) {
        if (state.statusCreate == LoadingStatus.success &&
            state.active != null) {
          context.go(state.active!.role.rootRoute);
        } else if (state.statusCreate == LoadingStatus.failure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.roleAddFailed)));
        }
      },
      builder: (context, state) {
        final busy = state.statusCreate == LoadingStatus.loading;
        final owned = {for (final m in state.memberships) m.role};
        final missing = MembershipRole.values.where((r) => !owned.contains(r));
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.roleTitle),
            actions: [
              IconButton(
                tooltip: l10n.settings,
                icon: const Icon(TeachHubIcons.gear),
                onPressed: () => context.push(AppRoutes.settings),
              ),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.all(tokens.spacingPage),
            children: [
              if (state.memberships.isNotEmpty) ...[
                Text(l10n.roleYours, style: text.titleMedium),
                SizedBox(height: tokens.spacingControl),
                for (final m in state.memberships)
                  ListTile(
                    title: Text(roleName(l10n, m.role)),
                    subtitle: m.label.isEmpty ? null : Text(m.label),
                    selected: m == state.active,
                    trailing: const Icon(TeachHubIcons.caretRight),
                    onTap: busy
                        ? null
                        : () async {
                            await context.read<MembershipCubit>().select(m);
                            if (context.mounted) context.go(m.role.rootRoute);
                          },
                  ),
                SizedBox(height: tokens.spacingSection),
              ],
              if (missing.isNotEmpty) ...[
                Text(
                  state.memberships.isEmpty ? l10n.roleWhoAreYou : l10n.roleAdd,
                  style: text.titleMedium,
                ),
                SizedBox(height: tokens.spacingControl),
                for (final role in missing) ...[
                  AppButton(
                    label: roleName(l10n, role),
                    variant: AppButtonVariant.outlinePrimary,
                    onPressed: busy
                        ? null
                        : () => context.read<MembershipCubit>().addRole(role),
                  ),
                  SizedBox(height: tokens.spacingControl),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}
