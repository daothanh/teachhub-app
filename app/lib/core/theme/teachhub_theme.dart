import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

/// Theme DayHoc = preset Tasco (`AppTheme.v1`/`v1Dark`)
/// + token ghi đè `assets/tokens/teachhub.tokens.json` (màu, bo góc, khoảng cách)
/// + thang chữ Be Vietnam Pro của Figma DS v2 (`DayHoc/*`).
///
/// Nguồn token: Figma kOMrSBbbMkgGSBTNnFV72z, mode "Light"/"Dark". Mini-app kế
/// thừa theme này qua host shell, không tự dựng theme.
abstract final class TeachHubTheme {
  static const tokensAsset = 'assets/tokens/teachhub.tokens.json';
  static const fontFamily = 'Be Vietnam Pro';

  /// `bg/disabled`, `text/disabled` (DS · Color Light/Dark).
  static const _disabledBg = Color(0xFFE4E4DE);
  static const _disabledFg = Color(0xFF8C8C84);
  static const _disabledBgDark = Color(0xFF2A2A27);
  static const _disabledFgDark = Color(0xFF6B6B64);

  /// `action/secondary/border` — viền nút phụ (nút trung tính, chữ đen).
  static const _secondaryBorder = Color(0xFFD3D3CB);
  static const _secondaryBorderDark = Color(0xFF4A4A45);

  static Future<({ThemeData light, ThemeData dark})> load([
    AssetBundle? bundle,
  ]) async {
    final overlay = TascoTokenOverlay.parse(
      await (bundle ?? rootBundle).loadString(tokensAsset),
    );
    return (
      light: build(overlay, AppTheme.v1),
      dark: build(overlay, AppTheme.v1Dark),
    );
  }

  static ThemeData build(TascoTokenOverlay overlay, ThemeData preset) {
    final themed = overlay.apply(preset);
    final scheme = themed.colorScheme;
    final light = themed.brightness == Brightness.light;
    final text = textTheme(scheme.onSurface);

    final tokens = themed.extension<TascoThemeExtension>()!.copyWith(
      buttonTheme: TascoButtonTheme(
        sizes: TascoButtonSizes(
          md: TascoButtonSizeTheme(height: 48, textStyle: text.labelLarge),
          lg: TascoButtonSizeTheme(height: 48, textStyle: text.labelLarge),
          sm: TascoButtonSizeTheme(height: 40, textStyle: buttonSmall),
        ),
        variants: TascoButtonVariants(
          primary: TascoButtonVariantTheme(
            disabledBackgroundColor: light ? _disabledBg : _disabledBgDark,
            disabledForegroundColor: light ? _disabledFg : _disabledFgDark,
          ),
          // DS v2: nút phụ trung tính (viền stone, chữ đen); lime chỉ cho hành động chính.
          outlinePrimary: TascoButtonVariantTheme(
            foregroundColor: scheme.onSurface,
            borderColor: light ? _secondaryBorder : _secondaryBorderDark,
          ),
        ),
      ),
    );

    // withTokens dựng lại component theme (app bar, input, nút…) theo chữ DS.
    final base = AppTheme.withTokens(themed.copyWith(textTheme: text), tokens);
    // Preset viền ô nhập bằng `outlineVariant` (border/default, chỉ ~1.3:1);
    // DS v2 dùng `border/control` (= `outline`, ≥ 3:1, WCAG 1.4.11).
    final controlBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(tokens.fieldRadius),
      borderSide: BorderSide(color: scheme.outline),
    );
    return base.copyWith(
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        border: controlBorder,
        enabledBorder: controlBorder,
      ),
      extensions: [
        ...base.extensions.values,
        const TeachHubColors(warningBorder: Color(0xFFF59E0B)),
      ],
      disabledColor: light ? _disabledFg : _disabledFgDark,
      // Mặc định Material lấy `primary` (lime) cho chữ nút và vạch tiến trình — không đủ tương phản.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.secondary,
          textStyle: text.labelLarge,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.onSurface,
      ),
    );
  }

  /// Text style `DayHoc/*` của Figma DS v2 → slot `TextTheme`.
  ///
  /// | Figma            | Cỡ/dòng/độ đậm/giãn chữ | Slot                              |
  /// |------------------|-------------------------|-----------------------------------|
  /// | Display          | 24/32/600/−2%           | `headlineLarge`                   |
  /// | H1               | 20/28/600/−1,5%         | `headlineMedium`, `headlineSmall` |
  /// | H2 (app bar)     | 17/24/600/−1%           | `titleLarge`, `titleMedium`       |
  /// | H3               | 15/22/600/−0,5%         | `titleSmall`                      |
  /// | Body             | 14/20/400               | `bodyLarge`, `bodyMedium`         |
  /// | Caption          | 12/16/400               | `bodySmall`                       |
  /// | Button           | 15/20/600               | `labelLarge`                      |
  /// | Label            | 12/16/500               | `labelMedium`                     |
  /// | Nav              | 11/14/500               | `labelSmall`                      |
  static TextTheme textTheme(Color color) => TextTheme(
    headlineLarge: _style(24, 32, FontWeight.w600, color, -2),
    headlineMedium: _style(20, 28, FontWeight.w600, color, -1.5),
    headlineSmall: _style(20, 28, FontWeight.w600, color, -1.5),
    titleLarge: _style(17, 24, FontWeight.w600, color, -1),
    titleMedium: _style(17, 24, FontWeight.w600, color, -1),
    titleSmall: _style(15, 22, FontWeight.w600, color, -0.5),
    bodyLarge: _style(14, 20, FontWeight.w400, color),
    bodyMedium: _style(14, 20, FontWeight.w400, color),
    bodySmall: _style(12, 16, FontWeight.w400, color),
    labelLarge: _style(15, 20, FontWeight.w600, color),
    labelMedium: _style(12, 16, FontWeight.w500, color),
    labelSmall: _style(11, 14, FontWeight.w500, color),
  );

  /// `DayHoc/Button S` — 13/18/600.
  static const buttonSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  static TextStyle _style(
    double size,
    double lineHeight,
    FontWeight weight,
    Color color, [
    double trackingPercent = 0,
  ]) => TextStyle(
    fontFamily: fontFamily,
    fontSize: size,
    height: lineHeight / size,
    fontWeight: weight,
    // Figma giãn chữ theo % cỡ chữ; luôn đặt để Material không chèn giá trị mặc định.
    letterSpacing: size * trackingPercent / 100,
    color: color,
  );
}

/// Màu DS không có slot trong `ColorScheme`/`TascoThemeExtension` (token riêng
/// của app nên là extension riêng — README tasco_ui_kit). Chỉ thêm khi màn cần.
@immutable
class TeachHubColors extends ThemeExtension<TeachHubColors> {
  const TeachHubColors({required this.warningBorder});

  /// `status/warning/border` (amber/500) — viền thẻ "Sắp ra mắt".
  final Color warningBorder;

  @override
  TeachHubColors copyWith({Color? warningBorder}) =>
      TeachHubColors(warningBorder: warningBorder ?? this.warningBorder);

  @override
  TeachHubColors lerp(TeachHubColors? other, double t) => other == null
      ? this
      : TeachHubColors(
          warningBorder: Color.lerp(warningBorder, other.warningBorder, t)!,
        );
}

extension TeachHubColorsX on BuildContext {
  /// Rơi về preset khi theme không có extension (test dùng `AppTheme.v1`).
  TeachHubColors get teachHubColors =>
      Theme.of(this).extension<TeachHubColors>() ??
      TeachHubColors(warningBorder: tasco.warningColor);
}
