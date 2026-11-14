import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:app/core/theme/theme_controller.dart';

void main() {
  late SharedPreferences prefs;
  late ThemeController ctrl;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    ctrl = ThemeController(prefs);
  });

  tearDown(() => ctrl.dispose());

  group('ThemeController', () {
    test('defaults to ThemeMode.system when no prefs saved', () {
      expect(ctrl.themeMode, ThemeMode.system);
    });

    test('setThemeMode(light) persists and notifies', () async {
      var notified = false;
      ctrl.addListener(() => notified = true);

      await ctrl.setThemeMode(ThemeMode.light);

      expect(ctrl.themeMode, ThemeMode.light);
      expect(notified, isTrue);
      expect(prefs.getString('app_theme_mode'), 'light');
    });

    test('setThemeMode(dark) persists and notifies', () async {
      await ctrl.setThemeMode(ThemeMode.dark);

      expect(ctrl.themeMode, ThemeMode.dark);
      expect(prefs.getString('app_theme_mode'), 'dark');
    });

    test('setThemeMode(system) persists "system"', () async {
      await ctrl.setThemeMode(ThemeMode.dark); // set first
      await ctrl.setThemeMode(ThemeMode.system); // reset

      expect(ctrl.themeMode, ThemeMode.system);
      expect(prefs.getString('app_theme_mode'), 'system');
    });

    test('restores persisted ThemeMode on construction', () async {
      await prefs.setString('app_theme_mode', 'dark');
      final restored = ThemeController(prefs);
      addTearDown(restored.dispose);

      expect(restored.themeMode, ThemeMode.dark);
    });

    test('restores light mode from prefs', () async {
      await prefs.setString('app_theme_mode', 'light');
      final restored = ThemeController(prefs);
      addTearDown(restored.dispose);

      expect(restored.themeMode, ThemeMode.light);
    });

    test('unknown prefs value falls back to system', () async {
      await prefs.setString('app_theme_mode', 'unknown_value');
      final restored = ThemeController(prefs);
      addTearDown(restored.dispose);

      expect(restored.themeMode, ThemeMode.system);
    });
  });
}
