import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and broadcasts the chosen [ThemeMode].
///
/// Registered as a singleton in [localModule] so the [App] widget can subscribe
/// and the [SettingsPage] can mutate it without a direct dependency on the
/// widget tree.
class ThemeController extends ValueNotifier<ThemeMode> {
  static const _key = 'app_theme_mode';

  final SharedPreferences _prefs;

  ThemeController(this._prefs) : super(_load(_prefs));

  static ThemeMode _load(SharedPreferences prefs) {
    final saved = prefs.getString(_key);
    return switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  ThemeMode get themeMode => value;

  Future<void> setThemeMode(ThemeMode mode) async {
    value = mode;
    final s = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(_key, s);
  }
}
