import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:tasco_utils/tasco_utils.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../core/routing/app_routes.dart';
import '../../core/theme/teachhub_theme.dart';
import '../../core/widgets/bottom_action_bar.dart';
import '../../core/widgets/dashed_border.dart';
import '../../l10n/l10n.dart';
import 'membership_cubit.dart';

/// [T01c] "Bạn là…?" (Figma B04, B05, B15).
///
/// Chọn một vai trò rồi "Tiếp tục": vai trò đã có → mở luôn; chưa có → tạo
/// (Giáo viên = `POST /workspaces`, Phụ huynh/Học sinh = `POST /me/roles`).
/// Chủ trung tâm chưa mở: chạm vào thẻ để đăng ký sớm (T01d).
class RolePickerPage extends StatefulWidget {
  const RolePickerPage({super.key});

  static String roleName(AppLocalizations l10n, MembershipRole role) =>
      switch (role) {
        MembershipRole.tenantOwner => l10n.roleTeacher,
        MembershipRole.parent => l10n.roleParent,
        MembershipRole.student => l10n.roleStudent,
      };

  static String roleDescription(AppLocalizations l10n, MembershipRole role) =>
      switch (role) {
        MembershipRole.tenantOwner => l10n.roleTeacherDesc,
        MembershipRole.parent => l10n.roleParentDesc,
        MembershipRole.student => l10n.roleStudentDesc,
      };

  @override
  State<RolePickerPage> createState() => _RolePickerPageState();
}

class _RolePickerPageState extends State<RolePickerPage> {
  MembershipRole? _selected;

  Future<void> _continue(MembershipState state) async {
    final role = _selected;
    if (role == null) return;
    final cubit = context.read<MembershipCubit>();
    final owned = state.memberships.where((m) => m.role == role).firstOrNull;
    if (owned == null) return cubit.addRole(role); // listener điều hướng
    await cubit.select(owned);
    if (mounted) context.go(owned.role.rootRoute);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tasco;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

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
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                tokens.spacingPage,
                tokens.spacingSection,
                tokens.spacingPage,
                tokens.spacingPage,
              ),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.roleWhoAreYou,
                        style: text.headlineLarge,
                      ),
                    ),
                    // Ngoài thiết kế: lối vào Cài đặt (ngôn ngữ, giao diện, sinh trắc học).
                    IconButton(
                      tooltip: l10n.settings,
                      icon: const Icon(TeachHubIcons.gear),
                      onPressed: () => context.push(AppRoutes.settings),
                    ),
                  ],
                ),
                SizedBox(height: tokens.spacingContent),
                Text(
                  l10n.roleIntro,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                for (final role in MembershipRole.values) ...[
                  SizedBox(height: tokens.spacingContent),
                  _RoleCard(
                    title: RolePickerPage.roleName(l10n, role),
                    caption: RolePickerPage.roleDescription(l10n, role),
                    selected: _selected == role,
                    tag: _selected == role
                        ? l10n.roleSelected
                        : owned.contains(role)
                        ? l10n.roleOwned
                        : null,
                    onTap: busy ? null : () => setState(() => _selected = role),
                  ),
                ],
                SizedBox(height: tokens.spacingContent),
                _RoleCard(
                  title: l10n.roleCenterOwner,
                  caption: l10n.roleCenterOwnerDesc,
                  comingSoon: l10n.roleComingSoon,
                  onTap: () => context.push(AppRoutes.centerWaitlist),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomActionBar(
            child: AppButton(
              label: busy ? l10n.loading : l10n.roleContinue,
              onPressed: _selected == null || busy
                  ? null
                  : () => _continue(state),
              // tasco_ui_kit chỉ tô màu disabled khi `disabled: true`.
              disabled: _selected == null || busy,
            ),
          ),
        );
      },
    );
  }
}

/// `Surfaces/Card` của T01c: Default (viền 1.5), Emphasis khi chọn (viền ink
/// 2.5 + tag "Đã chọn"), Dashed amber cho mục sắp ra mắt.
class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.caption,
    this.selected = false,
    this.tag,
    this.comingSoon,
    this.onTap,
  });

  final String title;
  final String caption;
  final bool selected;
  final String? tag;
  final String? comingSoon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tasco;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(tokens.cardRadius);

    final content = Padding(
      padding: EdgeInsets.all(tokens.spacingContent),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleSmall),
                const SizedBox(height: 2),
                Text(
                  caption,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (tag != null)
            _Tag(tag!, filled: selected)
          else if (comingSoon != null)
            DashedBorder(
              color: scheme.outlineVariant,
              radius: tokens.pillRadius,
              child: _Tag(comingSoon!, filled: false, bordered: false),
            ),
        ],
      ),
    );

    if (comingSoon != null) {
      return Semantics(
        button: onTap != null,
        child: DashedBorder(
          color: context.teachHubColors.warningBorder,
          radius: tokens.cardRadius,
          child: InkWell(borderRadius: radius, onTap: onTap, child: content),
        ),
      );
    }
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: selected
              ? BorderSide(color: scheme.onSurface, width: 2.5)
              : BorderSide(color: scheme.outlineVariant, width: 1.5),
        ),
        child: InkWell(borderRadius: radius, onTap: onTap, child: content),
      ),
    );
  }
}

/// `Display/Tag` 24px: Filled ink ("Đã chọn") hoặc Outline.
class _Tag extends StatelessWidget {
  const _Tag(this.label, {required this.filled, this.bordered = true});

  final String label;
  final bool filled;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tasco;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 24,
      padding: EdgeInsets.symmetric(horizontal: tokens.spacingControl),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? scheme.onSurface : scheme.surface,
        borderRadius: BorderRadius.circular(tokens.pillRadius),
        border: filled || !bordered
            ? null
            : Border.all(color: scheme.outlineVariant, width: 1.5),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: filled ? scheme.onInverseSurface : scheme.onSurface,
        ),
      ),
    );
  }
}
