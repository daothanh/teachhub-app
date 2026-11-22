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

  test('màu Light theo DS v2: lime + ink, nền canvas ấm', () {
    final s = light.colorScheme;
    expect(s.primary, const Color(0xFFBDFF3E));
    expect(s.onPrimary, const Color(0xFF1F1F1F));
    expect(s.secondary, const Color(0xFF4F7300));
    expect(s.onSurface, const Color(0xFF1F1F1F));
    expect(s.onSurfaceVariant, const Color(0xFF52524C));
    expect(s.surface, Colors.white);
    expect(light.scaffoldBackgroundColor, const Color(0xFFF7F7F4));
    final t = light.extension<TascoThemeExtension>()!;
    expect(t.focusRingColor, const Color(0xFF4F7300));
    expect(t.placeholderColor, const Color(0xFF6B6B64));
    expect(t.successColor, const Color(0xFF047857));
  });

  test('bo góc và khoảng cách theo DS · Spacing & Size (lưới 4pt)', () {
    final t = light.extension<TascoThemeExtension>()!;
    expect(t.buttonRadius, 14);
    expect(t.cardRadius, 14);
    expect(t.fieldRadius, 12);
    expect(t.dialogRadius, 20);
    expect(t.sheetRadius, 28);
    expect(t.spacingPage, 16);
    expect(t.spacingContent, 12);
    expect(t.spacingSection, 24);
  });

  test('nút phụ trung tính (viền stone, chữ đen), nút chữ dùng lime/800', () {
    final t = light.extension<TascoThemeExtension>()!;
    final outline = t.buttonTheme!.variants!.outlinePrimary!;
    expect(outline.foregroundColor, const Color(0xFF1F1F1F));
    expect(outline.borderColor, const Color(0xFFD3D3CB));
    expect(
      light.textButtonTheme.style!.foregroundColor!.resolve({}),
      const Color(0xFF4F7300),
    );
    expect(t.buttonTheme!.sizes!.md!.height, 48);
  });

  test('viền ô nhập dùng border/control (≥ 3:1)', () {
    final border = light.inputDecorationTheme.enabledBorder!;
    expect(border.borderSide.color, const Color(0xFF8C8C84));
  });

  test('chữ Be Vietnam Pro theo thang DayHoc/*', () {
    final tt = light.textTheme;
    expect(tt.bodyMedium!.fontFamily, TeachHubTheme.fontFamily);
    expect(tt.bodyMedium!.fontSize, 14);
    expect(tt.headlineLarge!.fontSize, 24);
    expect(tt.titleLarge!.fontWeight, FontWeight.w600);
    expect(tt.headlineLarge!.letterSpacing, closeTo(-0.48, 1e-9));
    expect(tt.labelLarge!.fontWeight, FontWeight.w600);
    expect(
      light.appBarTheme.titleTextStyle!.fontFamily,
      TeachHubTheme.fontFamily,
    );
  });

  test('dark theo DS v2: nền xám ấm, chữ trên nền lime vẫn là ink', () {
    expect(dark.brightness, Brightness.dark);
    expect(dark.colorScheme.primary, const Color(0xFFBDFF3E));
    expect(dark.colorScheme.onPrimary, const Color(0xFF1F1F1F));
    expect(dark.scaffoldBackgroundColor, const Color(0xFF0F0F0E));
    expect(dark.colorScheme.surface, const Color(0xFF171716));
    expect(dark.colorScheme.onSurface, const Color(0xFFF2F2EE));
    expect(dark.colorScheme.outline, const Color(0xFF6B6B64));
  });
}
