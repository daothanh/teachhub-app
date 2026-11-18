import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_core/tasco_core.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import 'package:package_info_plus/package_info_plus.dart';
import '../../core/config/app_env.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/theme_controller.dart';
import '../../features/auth/auth_cubit.dart';
import '../../l10n/l10n.dart';

// ── Settings Page ─────────────────────────────────────────────────────────────

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppMainAppBar(
        title: l10n.settings,
        showLeading: true,
        leading: AppIconButton(
          icon: AppSvgIcon(
            AppIcons.arrowLeft,
            size: 18.sp,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppRoutes.rolePicker),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Biometric ───────────────────────────────────────────────
            _SectionHeader(title: l10n.settingsSecurity),
            SizedBox(height: 8.h),
            _BiometricTile(isDark: isDark),
            SizedBox(height: 20.h),

            // ── Language ────────────────────────────────────────────────
            _SectionHeader(title: l10n.settingsLanguage),
            SizedBox(height: 8.h),
            _LanguageSection(isDark: isDark),
            SizedBox(height: 20.h),

            // ── Theme ───────────────────────────────────────────────────
            _SectionHeader(title: l10n.settingsTheme),
            SizedBox(height: 8.h),
            _ThemeSection(isDark: isDark),
            SizedBox(height: 20.h),

            // ── About ───────────────────────────────────────────────────
            _SectionHeader(title: l10n.settingsAbout),
            SizedBox(height: 8.h),
            _AboutSection(isDark: isDark),
            SizedBox(height: 20.h),
            AppButton(
              label: l10n.logout,
              variant: AppButtonVariant.outlineDanger,
              onPressed: () => context.read<AppAuthCubit>().logout(),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          title,
          // TeachHub/Section: 12/16, đậm, chữ phụ.
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ── Card Shell ────────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;

  const _SettingsCard({required this.children, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // DS: card phân tầng bằng viền, không đổ bóng (elevation chỉ cho lớp nổi).
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.tasco.cardRadius),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

// ── Biometric Tile ────────────────────────────────────────────────────────────

class _BiometricTile extends StatelessWidget {
  final bool isDark;

  const _BiometricTile({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<AppAuthCubit, AppAuthState>(
      builder: (context, state) {
        final available = state.isBiometricAvailable;
        final enrolled = state.isBiometricEnrolled;
        final enabled = state.isBiometricEnabled && available;

        final subtitle = !available
            ? l10n.settingsBiometricSubtitleUnsupported
            : !enrolled
            ? l10n.settingsBiometricSubtitleNotEnrolled
            : l10n.settingsBiometricSubtitleAvailable;

        final subtitleColor = available && !enrolled
            ? context.tasco.warningColor
            : scheme.onSurfaceVariant;

        return _SettingsCard(
          isDark: isDark,
          children: [
            SwitchListTile.adaptive(
              key: const Key('biometric_switch'),
              secondary: AppSvgIcon(
                AppIcons.fingerprint,
                color: available ? scheme.onSurface : scheme.onSurfaceVariant,
                size: 28.sp,
              ),
              title: Text(
                l10n.settingsBiometricTitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              subtitle: Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: subtitleColor),
              ),
              value: enabled,
              onChanged: available && enrolled
                  ? (val) => _toggleBiometric(context, val)
                  : null,
            ),
          ],
        );
      },
    );
  }

  /// When enabling biometric, prompt the user to authenticate first.
  /// If the user cancels or fails, do not persist the change.
  Future<void> _toggleBiometric(BuildContext context, bool enable) async {
    final cubit = context.read<AppAuthCubit>();
    final l10n = AppLocalizations.of(context);

    if (enable) {
      // Verify fingerprint / face before allowing enable.
      final authenticated = await cubit.authenticateBiometric(
        localizedReason: l10n.settingsBiometricAuthReason,
      );
      if (!authenticated) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.settingsBiometricFailed),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return; // Do not enable.
      }
    }

    await cubit.setBiometricEnabled(enable);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enable
                ? l10n.settingsBiometricEnabled
                : l10n.settingsBiometricDisabled,
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

// ── Language Section ──────────────────────────────────────────────────────────

class _LanguageSection extends StatelessWidget {
  final bool isDark;

  const _LanguageSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final localeCtrl = GetIt.I<LocaleController>();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    final languages = [
      (code: null, label: l10n.settingsLanguageSystem, flag: '🌐'),
      (code: 'vi', label: 'Tiếng Việt', flag: '🇻🇳'),
      (code: 'en', label: 'English', flag: '🇬🇧'),
    ];

    return ListenableBuilder(
      listenable: localeCtrl,
      builder: (context, _) {
        final currentLocale = localeCtrl.locale;
        return _SettingsCard(
          isDark: isDark,
          children: [
            for (int i = 0; i < languages.length; i++) ...[
              _OptionTile(
                leading: Text(
                  languages[i].flag,
                  style: const TextStyle(fontSize: 22),
                ),
                label: languages[i].label,
                selected: currentLocale?.languageCode == languages[i].code,
                scheme: scheme,
                textTheme: textTheme,
                onTap: () => localeCtrl.setLocale(
                  languages[i].code != null ? Locale(languages[i].code!) : null,
                ),
              ),
              if (i < languages.length - 1)
                const AppDivider(indent: 52, endIndent: 16),
            ],
          ],
        );
      },
    );
  }
}

// ── Theme Section ─────────────────────────────────────────────────────────────

class _ThemeSection extends StatelessWidget {
  final bool isDark;

  const _ThemeSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = GetIt.I<ThemeController>();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    final themes = [
      (
        mode: ThemeMode.system,
        label: l10n.settingsThemeSystem,
        iconPath: AppIcons.config,
      ),
      (
        mode: ThemeMode.light,
        label: l10n.settingsThemeLight,
        iconPath: AppIcons.eye,
      ),
      (
        mode: ThemeMode.dark,
        label: l10n.settingsThemeDark,
        iconPath: AppIcons.eyeSlash,
      ),
    ];

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeCtrl,
      builder: (context, currentMode, _) {
        return _SettingsCard(
          isDark: isDark,
          children: [
            for (int i = 0; i < themes.length; i++) ...[
              _OptionTile(
                leading: AppSvgIcon(
                  themes[i].iconPath,
                  color: currentMode == themes[i].mode
                      ? scheme.onSurface
                      : scheme.onSurfaceVariant,
                  size: 22.sp,
                ),
                label: themes[i].label,
                selected: currentMode == themes[i].mode,
                scheme: scheme,
                textTheme: textTheme,
                onTap: () => themeCtrl.setThemeMode(themes[i].mode),
              ),
              if (i < themes.length - 1)
                const AppDivider(indent: 56, endIndent: 16),
            ],
          ],
        );
      },
    );
  }
}

// ── Shared Option Tile ────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final Widget leading;
  final String label;
  final bool selected;
  final ColorScheme scheme;
  final TextTheme textTheme;
  final VoidCallback onTap;

  const _OptionTile({
    required this.leading,
    required this.label,
    required this.selected,
    required this.scheme,
    required this.textTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: leading,
      title: Text(
        label,
        style: textTheme.bodyMedium?.copyWith(
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          color: scheme.onSurface,
        ),
      ),
      trailing: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: selected
            ? AppSvgIcon(
                AppIcons.checkCircle,
                color: scheme.onSurface,
                size: 20.sp,
                key: const ValueKey('checked'),
              )
            : AppSvgIcon(
                AppIcons.circleOutline,
                color: scheme.outlineVariant,
                size: 20.sp,
                key: const ValueKey('unchecked'),
              ),
      ),
    );
  }
}

// ── About Section ─────────────────────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  final bool isDark;

  const _AboutSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    // Guard: env may not be registered in test environments.
    late final String envLabel;
    late final Color envColor;
    try {
      final env = GetIt.I<AppEnv>();
      envLabel = switch (env.current) {
        Env.development => 'Development',
        Env.staging => 'Staging',
        Env.production => 'Production',
      };
      envColor = switch (env.current) {
        Env.development => context.tasco.warningColor,
        Env.staging => context.tasco.infoColor,
        Env.production => context.tasco.successColor,
      };
    } catch (_) {
      envLabel = '—';
      envColor = scheme.onSurfaceVariant;
    }

    return _SettingsCard(
      isDark: isDark,
      children: [
        _AboutTile(
          iconPath: AppIcons.grid,
          label: l10n.settingsAboutApp,
          value: l10n.appName,
          isDark: isDark,
        ),
        const AppDivider(indent: 56, endIndent: 16),
        _AboutTile(
          iconPath: AppIcons.infoCircle,
          label: l10n.settingsAboutVersion,
          value: GetIt.I<PackageInfo>().version,
          isDark: isDark,
        ),
        const AppDivider(indent: 56, endIndent: 16),
        ListTile(
          leading: AppSvgIcon(
            AppIcons.network,
            color: scheme.onSurface,
            size: 20.sp,
          ),
          title: Text(
            l10n.settingsAboutEnv,
            style: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: envColor.withValues(
                alpha: context.tasco.statusTintOpacity,
              ),
              borderRadius: BorderRadius.circular(context.tasco.pillRadius),
            ),
            child: Text(
              envLabel,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: envColor),
            ),
          ),
        ),
        const AppDivider(indent: 56, endIndent: 16),
        ListTile(
          leading: AppSvgIcon(
            AppIcons.document,
            color: scheme.onSurface,
            size: 20.sp,
          ),
          title: Text(
            l10n.settingsAboutTerms,
            style: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
          ),
          trailing: AppSvgIcon(
            AppIcons.arrowRight,
            size: 14.sp,
            color: scheme.onSurfaceVariant,
          ),
          onTap: () {
            // TODO(P2): open in-app WebView with terms URL
          },
        ),
      ],
    );
  }
}

class _AboutTile extends StatelessWidget {
  final String iconPath;
  final String label;
  final String value;
  final bool isDark;

  const _AboutTile({
    required this.iconPath,
    required this.label,
    required this.value,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      leading: AppSvgIcon(iconPath, color: scheme.onSurface, size: 20.sp),
      title: Text(
        label,
        style: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
      ),
      trailing: Text(
        value,
        style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}
