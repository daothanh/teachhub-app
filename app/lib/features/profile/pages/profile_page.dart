import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../core/routing/app_routes.dart';
import '../../../data/model/user_model.dart';
import '../../../l10n/l10n.dart';
import '../../auth/auth_cubit.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _expandedPermissions = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<AppAuthCubit, AppAuthState>(
      builder: (context, state) {
        final user = state.user;
        final name = user?.name ?? l10n.profileStandardUser;
        final username = user?.username ?? user?.id ?? l10n.profileStandardUser;
        final role = user?.role;
        final permissionItems = user?.permissionItems ?? [];

        final visiblePermissions = _expandedPermissions
            ? permissionItems
            : permissionItems.take(8).toList();

        return Scaffold(
          backgroundColor: scheme.surface,
          appBar: AppMainAppBar(title: l10n.tabProfile, showLeading: false),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User Card Info
                AppWrapperContainer(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    children: [
                      AppCircleAvatar(name: name, size: 56.sp),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: scheme.onSurface,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              '${l10n.username}: $username',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            if (role != null) ...[
                              SizedBox(height: 2.h),
                              Text(
                                l10n.profileRole(role),
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // Roles & Permissions Section
                AppWrapperContainer(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.profilePermissionsTitle,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          if (permissionItems.isNotEmpty)
                            Text(
                              l10n.profilePermissionsCount(
                                permissionItems.length,
                              ),
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      if (permissionItems.isNotEmpty) ...[
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: visiblePermissions
                              .map(
                                (p) => _PermissionChip(item: p, scheme: scheme),
                              )
                              .toList(),
                        ),
                        if (permissionItems.length > 8) ...[
                          SizedBox(height: 8.h),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _expandedPermissions = !_expandedPermissions;
                              });
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 4.h),
                              child: Text(
                                _expandedPermissions
                                    ? l10n.profileShowLess
                                    : l10n.profileShowMore(
                                        permissionItems.length - 8,
                                      ),
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ] else ...[
                        StatusBadge(
                          label: l10n.profileStandardUserPermissions,
                          backgroundColor: scheme.surfaceContainerHighest,
                          textColor: scheme.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // Settings action tile
                AppWrapperContainer(
                  padding: EdgeInsets.zero,
                  child: Material(
                    type: MaterialType.transparency,
                    child: ListTile(
                      leading: AppSvgIcon(
                        AppIcons.setting,
                        color: scheme.primary,
                        size: 20.sp,
                      ),
                      title: Text(
                        l10n.settings,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: scheme.onSurface,
                        ),
                      ),
                      trailing: AppSvgIcon(
                        AppIcons.arrowRight,
                        size: 14.sp,
                        color: scheme.onSurfaceVariant,
                      ),
                      onTap: () => context.push(AppRoutes.settings),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // Logout Action Button
                AppButton(
                  label: l10n.logout,
                  variant: AppButtonVariant.danger,
                  icon: AppSvgIcon(
                    AppIcons.logout,
                    size: 18.sp,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    context.read<AppAuthCubit>().logout();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PermissionChip extends StatelessWidget {
  const _PermissionChip({required this.item, required this.scheme});

  final PermissionItem item;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final hasType = item.type != null && item.type!.isNotEmpty;
    final hasUri = item.uri != null && item.uri!.isNotEmpty;

    if (!hasType && !hasUri) {
      return StatusBadge(
        label: item.name.toUpperCase(),
        backgroundColor: scheme.primaryContainer,
        textColor: scheme.primary,
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
              ),
              if (hasType) ...[
                SizedBox(width: 6.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 5.w,
                    vertical: 1.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    item.type!.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (hasUri) ...[
            SizedBox(height: 2.h),
            Text(
              item.uri!,
              style: TextStyle(fontSize: 10.sp, color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
