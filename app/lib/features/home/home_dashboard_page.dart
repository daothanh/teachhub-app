import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:app/features/auth/auth_cubit.dart';
import 'package:tasco_module/tasco_module.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../core/routing/app_routes.dart';
import '../../l10n/l10n.dart';

class HomeDashboardPage extends StatelessWidget {
  const HomeDashboardPage({super.key});

  static List<_MenuItem> _fallbackMenu(AppLocalizations l10n) => [
    _MenuItem(
      iconPath: AppIcons.hrProfile,
      label: l10n.homeMenuHrProfile,
      route: null,
    ),
    _MenuItem(
      iconPath: AppIcons.training,
      label: l10n.homeMenuTraining,
      route: null,
    ),
    _MenuItem(
      iconPath: AppIcons.evaluation,
      label: l10n.homeMenuEvaluation,
      route: null,
    ),
    _MenuItem(
      iconPath: AppIcons.careerGrowth,
      label: l10n.homeMenuCareerPath,
      route: null,
    ),
    _MenuItem(
      iconPath: AppIcons.crossSale,
      label: l10n.homeMenuCrossSale,
      route: null,
    ),
    _MenuItem(
      iconPath: AppIcons.suggestions,
      label: l10n.homeMenuSuggestions,
      route: null,
    ),
    _MenuItem(
      iconPath: AppIcons.favorites,
      label: l10n.homeMenuFavorites,
      route: null,
    ),
    _MenuItem(
      iconPath: AppIcons.viewMore,
      label: l10n.homeMenuViewMore,
      route: null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final topPad = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = screenWidth * 0.72;

    // Dynamic mini-app menu from ModuleManager (slots declaring presentation).
    final moduleManager = GetIt.I.isRegistered<ModuleManager>()
        ? GetIt.I<ModuleManager>()
        : null;
    final dynamicSlots = moduleManager?.collectMenuSlots() ?? [];

    // Build the merged menu: dynamic slots first, then static fallback to fill.
    final menuItems = <_MenuItem>[
      for (final slot in dynamicSlots)
        _MenuItem(
          icon: ModuleIcons.resolve(slot.presentation!.iconName),
          label: slot.presentation!.displayName,
          route: slot.routePrefix,
        ),
      // Fill remaining slots from fallback up to 8 total.
      ..._fallbackMenu(l10n).take((8 - dynamicSlots.length).clamp(0, 8)),
    ];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // ── Banner background ──────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _BannerBackground(
              height: bannerHeight,
              colorScheme: colorScheme,
            ),
          ),

          // ── Scrollable body ────────────────────────────────────
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Space occupied by the banner
                SizedBox(height: bannerHeight - 48),

                // ── White card ─────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Section: Quick Access ────────────────────────
                      _SectionHeader(
                        title: l10n.homeQuickAccess,
                        textTheme: textTheme,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 12),
                      _MenuGrid(
                        items: menuItems,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                      ),

                      const SizedBox(height: 20),

                      // ── Section: Overview ────────────────────────────
                      _SectionHeader(
                        title: l10n.homeOverview,
                        textTheme: textTheme,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 12),
                      _OverviewGrid(colorScheme: colorScheme),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Floating header overlay ────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _HeaderOverlay(
              topPad: topPad,
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Banner Background ────────────────────────────────────────────────────────

class _BannerBackground extends StatelessWidget {
  final double height;
  final ColorScheme colorScheme;

  const _BannerBackground({required this.height, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Image.asset(
        AppImages.bannerAppTasco,
        package: 'tasco_ui_kit',
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, st) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.primary.withValues(alpha: 0.75),
                colorScheme.primaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header Overlay ───────────────────────────────────────────────────────────

class _HeaderOverlay extends StatelessWidget {
  final double topPad;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  const _HeaderOverlay({
    required this.topPad,
    required this.textTheme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppAuthCubit, AppAuthState>(
      builder: (context, state) {
        final user = state.user;
        final name = user?.name;
        final username = user?.username;
        final displayName = (name != null && name.isNotEmpty)
            ? name
            : (username != null && username.isNotEmpty)
            ? username
            : 'Tasco';
        final avatarName = displayName;

        return Padding(
          padding: EdgeInsets.only(
            top: topPad + 8,
            left: 16,
            right: 16,
            bottom: 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Greeting
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _greeting(context.l10n),
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),

              // Notification bell
              _IconButton(
                iconPath: AppIcons.notification,
                onTap: () => context.go(AppRoutes.notification),
                tooltip: context.l10n.tabNotification,
                badge: null, // TODO: unread count
              ),
              const SizedBox(width: 8),

              // Avatar
              GestureDetector(
                onTap: () => context.go(AppRoutes.profile),
                child: AppCircleAvatar(name: avatarName, size: 40),
              ),
            ],
          ),
        );
      },
    );
  }

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.greetingMorning;
    if (hour < 18) return l10n.greetingAfternoon;
    return l10n.greetingEvening;
  }
}

// ── Notification icon button ─────────────────────────────────────────────────

class _IconButton extends StatelessWidget {
  final String iconPath;
  final VoidCallback onTap;
  final String? tooltip;
  final int? badge;

  const _IconButton({
    required this.iconPath,
    required this.onTap,
    this.tooltip,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: AppIconButton(
            icon: AppSvgIcon(iconPath, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            onPressed: onTap,
            tooltip: tooltip ?? 'Thông báo',
          ),
        ),
        if (badge != null && badge! > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  badge! > 9 ? '9+' : '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  const _SectionHeader({
    required this.title,
    required this.textTheme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

// ── Menu Grid ────────────────────────────────────────────────────────────────

class _MenuGrid extends StatelessWidget {
  final List<_MenuItem> items;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _MenuGrid({
    required this.items,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 4,
        childAspectRatio: 0.80,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _MenuCell(
        item: items[index],
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
    );
  }
}

class _MenuItem {
  final String? iconPath;
  final IconData? icon;
  final String label;
  final String? route;
  const _MenuItem({
    this.iconPath,
    this.icon,
    required this.label,
    required this.route,
  });
}

class _MenuCell extends StatelessWidget {
  final _MenuItem item;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _MenuCell({
    required this.item,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (item.route != null) {
          context.go(item.route!);
        } else {
          _showUnderConstruction(context);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon container with subtle gradient background
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.12),
                  colorScheme.primary.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Center(
              child: item.iconPath != null
                  ? AppSvgIcon(
                      item.iconPath!,
                      size: 24,
                      color: colorScheme.primary,
                    )
                  : (item.icon != null
                        ? Icon(item.icon, size: 24, color: colorScheme.primary)
                        : AppSvgIcon(
                            AppIcons.grid,
                            size: 24,
                            color: colorScheme.primary,
                          )),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              fontSize: 10,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Overview Grid (stat cards) ───────────────────────────────────────────────

class _OverviewGrid extends StatelessWidget {
  final ColorScheme colorScheme;

  const _OverviewGrid({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tascoTheme = context.tasco;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: l10n.homeStatInsuranceOrders,
                value: '12',
                iconPath: AppIcons.shield,
                color: colorScheme.primary,
                onTap: () => _showUnderConstruction(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: l10n.homeStatPending,
                value: '3',
                iconPath: AppIcons.clock,
                color: tascoTheme.warningColor,
                onTap: () => _showUnderConstruction(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: l10n.homeStatTodayTasks,
                value: '5',
                iconPath: AppIcons.tasks,
                color: tascoTheme.successColor,
                onTap: () => _showUnderConstruction(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: l10n.homeStatNewNotifications,
                value: '2',
                iconPath: AppIcons.notification,
                color: colorScheme.tertiary,
                onTap: () => context.go(AppRoutes.notification),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String iconPath;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.iconPath,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppWrapperContainer(
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: AppSvgIcon(iconPath, color: color, size: 20),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            AppSvgIcon(
              AppIcons.chevronRight,
              size: 16,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Demo Module Card (shown when no real mini-app declares presentation) ─────

// ── Under Construction Bottom Sheet ─────────────────────────────────────────

void _showUnderConstruction(BuildContext context) {
  final l10n = context.l10n;
  final colorScheme = Theme.of(context).colorScheme;
  AppBottomSheet.show(
    context: context,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AppSvgIcon(
                AppIcons.wrench,
                size: 30,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.underConstructionTitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.underConstructionMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: l10n.understood,
            variant: AppButtonVariant.primary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    ),
  );
}
