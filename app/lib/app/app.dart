import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_core/tasco_core.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../core/theme/theme_controller.dart';
import '../features/auth/auth_cubit.dart';
import '../features/role_picker/membership_cubit.dart';
import '../features/role_picker/role_switcher.dart';
import '../l10n/l10n.dart';

class App extends StatelessWidget {
  final GoRouter router;
  final AppAuthCubit authCubit;
  final MembershipCubit membershipCubit;
  final LocaleController localeController;
  final ThemeController themeController;

  /// [TeachHubTheme.load] — dựng một lần ở bootstrap (đọc asset token).
  final ThemeData theme;
  final ThemeData darkTheme;
  final List<LocalizationsDelegate> miniAppDelegates;

  const App({
    super.key,
    required this.router,
    required this.authCubit,
    required this.membershipCubit,
    required this.localeController,
    required this.themeController,
    required this.theme,
    required this.darkTheme,
    this.miniAppDelegates = const [],
  });

  @override
  Widget build(BuildContext context) {
    // App-shell boilerplate (ScreenUtil + MaterialApp.router + EasyLoading +
    // runtime locale) lives in TascoApp (ui_kit, P2-17). Shell only supplies the
    // app-specific bits: AppAuthCubit, router, theme, locale source, l10n delegates.
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppAuthCubit>.value(value: authCubit),
        BlocProvider<MembershipCubit>.value(value: membershipCubit),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeController,
        // Chip vai trò C20 cho App Bar của mọi mini-app (US-0.11).
        builder: (context, themeMode, _) => RoleSwitcherScope(
          chip: (_) => const RoleChip(),
          child: TascoApp(
            routerConfig: router,
            theme: theme,
            darkTheme: darkTheme,
            themeMode: themeMode,
            localeListenable: localeController,
            localeOf: () => localeController.locale,
            localizationsDelegates: [
              ...AppLocalizations.localizationsDelegates,
              ...miniAppDelegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      ),
    );
  }
}
