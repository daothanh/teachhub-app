import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:app/core/theme/teachhub_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ThemeData light;
  late ThemeData dark;

  setUpAll(() async {
    final themes = await TeachHubTheme.load();
    light = themes.light;
    dark = themes.dark;
  });

  test('màu Brand theo Figma DS: lime + ink, nền trắng', () {
    final s = light.colorScheme;
    expect(s.primary, const Color(0xFFBDFF3E));
    expect(s.onPrimary, const Color(0xFF1F1F1F));
    expect(s.secondary, const Color(0xFF4F7300));
    expect(s.onSurface, const Color(0xFF1F1F1F));
    expect(s.onSurfaceVariant, const Color(0xFF555555));
    expect(light.scaffoldBackgroundColor, Colors.white);
    final t = light.extension<TascoThemeExtension>()!;
    expect(t.focusRingColor, const Color(0xFF4F7300));
    expect(t.placeholderColor, const Color(0xFF6B6B6B));
    expect(t.successColor, const Color(0xFF047857));
  });

  test('bo góc và khoảng cách theo DS · Spacing & Size (lưới 4pt)', () {
    final t = light.extension<TascoThemeExtension>()!;
    expect(t.buttonRadius, 10);
    expect(t.fieldRadius, 8);
    expect(t.sheetRadius, 20);
    expect(t.spacingPage, 16);
    expect(t.spacingContent, 12);
    expect(t.spacingSection, 24);
  });

  test(
    'nút viền và nút chữ dùng lime/800, không dùng lime/500 trên nền trắng',
    () {
      final t = light.extension<TascoThemeExtension>()!;
      final outline = t.buttonTheme!.variants!.outlinePrimary!;
      expect(outline.foregroundColor, const Color(0xFF4F7300));
      expect(outline.borderColor, const Color(0xFF4F7300));
      expect(
        light.textButtonTheme.style!.foregroundColor!.resolve({}),
        const Color(0xFF4F7300),
      );
      expect(t.buttonTheme!.sizes!.md!.height, 48);
    },
  );

  test('chữ Inter theo thang TeachHub/*', () {
    final tt = light.textTheme;
    expect(tt.bodyMedium!.fontFamily, TeachHubTheme.fontFamily);
    expect(tt.bodyMedium!.fontSize, 14);
    expect(tt.headlineLarge!.fontSize, 24);
    expect(tt.titleLarge!.fontWeight, FontWeight.w700);
    expect(tt.labelLarge!.fontWeight, FontWeight.w600);
    expect(
      light.appBarTheme.titleTextStyle!.fontFamily,
      TeachHubTheme.fontFamily,
    );
  });

  test('dark dựng được, chữ trên nền lime vẫn là ink', () {
    expect(dark.brightness, Brightness.dark);
    expect(dark.colorScheme.primary, const Color(0xFFBDFF3E));
    expect(dark.colorScheme.onPrimary, const Color(0xFF1F1F1F));
  });
}
