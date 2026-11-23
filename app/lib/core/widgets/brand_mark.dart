import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// `Brand/Logo` · Mark (Figma 80:2412): ô lime bo góc, ký hiệu D + chấm nặng màu
/// ink. Màu cố định ở mọi mode (`brand/logo` = `primary`, `brand/logo-fg` =
/// `onPrimary` trong theme DayHoc).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 48});

  /// 48 ở T01, 64 ở màn cập nhật, 160 ở splash; bo góc tỉ lệ như Figma (20/48).
  final double size;

  static const asset = 'assets/brand/logo_mark_glyph.svg';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'DayHoc',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(size * 20 / 48),
        ),
        child: SvgPicture.asset(
          asset,
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(scheme.onPrimary, BlendMode.srcIn),
        ),
      ),
    );
  }
}
