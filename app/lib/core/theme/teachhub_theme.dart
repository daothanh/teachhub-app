import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

/// Theme TeachHub = preset Tasco (`AppTheme.v1`/`v1Dark`)
/// + token ghi đè `assets/tokens/teachhub.tokens.json` (màu, bo góc, khoảng cách)
/// + thang chữ Inter của Figma DS (`TeachHub/*`).
///
/// Nguồn token: Figma kOMrSBbbMkgGSBTNnFV72z, mode "Brand". Mini-app kế thừa
/// theme này qua host shell, không tự dựng theme.
abstract final class TeachHubTheme {
  static const tokensAsset = 'assets/tokens/teachhub.tokens.json';
  static const fontFamily = 'Inter';

  /// `bg/disabled`, `text/disabled` (DS · Color). DS chưa có mode Dark nên
  /// dark giữ màu disabled của preset.
  static const _disabledBg = Color(0xFFE5E5E5);
  static const _disabledFg = Color(0xFF8A8A8A);

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
          primary: light
              ? const TascoButtonVariantTheme(
                  disabledBackgroundColor: _disabledBg,
                  disabledForegroundColor: _disabledFg,
                )
              : null,
          // Lime trên nền trắng chỉ 1.2:1 → nút viền dùng `action/secondary` (lime/800).
          outlinePrimary: TascoButtonVariantTheme(
            foregroundColor: scheme.secondary,
            borderColor: scheme.secondary,
          ),
        ),
      ),
    );

    // withTokens dựng lại component theme (app bar, input, nút…) theo chữ Inter.
    final base = AppTheme.withTokens(themed.copyWith(textTheme: text), tokens);
    return base.copyWith(
      extensions: [
        ...base.extensions.values,
        const TeachHubColors(warningBorder: Color(0xFFF59E0B)),
      ],
      disabledColor: light ? _disabledFg : null,
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

  /// Text style `TeachHub/*` của Figma → slot `TextTheme`.
  ///
  /// | Figma            | Cỡ/dòng/độ đậm | Slot                            |
  /// |------------------|----------------|---------------------------------|
  /// | Display          | 24/32/700      | `headlineLarge`                 |
  /// | H1               | 20/28/700      | `headlineMedium`, `headlineSmall` |
  /// | H2 (app bar)     | 17/24/700      | `titleLarge`, `titleMedium`     |
  /// | H3               | 15/22/700      | `titleSmall`                    |
  /// | Body             | 14/20/400      | `bodyLarge`, `bodyMedium`       |
  /// | Caption          | 12/16/400      | `bodySmall`                     |
  /// | Button           | 15/20/600      | `labelLarge`                    |
  /// | Label            | 12/16/600      | `labelMedium`                   |
  /// | Nav              | 11/14/400      | `labelSmall`                    |
  static TextTheme textTheme(Color color) => TextTheme(
    headlineLarge: _style(24, 32, FontWeight.w700, color),
    headlineMedium: _style(20, 28, FontWeight.w700, color),
    headlineSmall: _style(20, 28, FontWeight.w700, color),
    titleLarge: _style(17, 24, FontWeight.w700, color),
    titleMedium: _style(17, 24, FontWeight.w700, color),
    titleSmall: _style(15, 22, FontWeight.w700, color),
    bodyLarge: _style(14, 20, FontWeight.w400, color),
    bodyMedium: _style(14, 20, FontWeight.w400, color),
    bodySmall: _style(12, 16, FontWeight.w400, color),
    labelLarge: _style(15, 20, FontWeight.w600, color),
    labelMedium: _style(12, 16, FontWeight.w600, color),
    labelSmall: _style(11, 14, FontWeight.w400, color),
  );

  /// `TeachHub/Button S` — 13/18/600.
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
    Color color,
  ) => TextStyle(
    fontFamily: fontFamily,
    fontSize: size,
    height: lineHeight / size,
    fontWeight: weight,
    // Figma letterSpacing 0; không để Typography của Material chèn giá trị mặc định.
    letterSpacing: 0,
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
