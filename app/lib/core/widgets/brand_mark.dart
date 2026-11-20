import 'package:flutter/material.dart';

/// `Brand/Logo` · Mark: ô vuông lime, chữ "D" ink. Màu cố định ở mọi mode
/// (`brand/logo` = `primary`, `brand/logo-fg` = `onPrimary` trong theme TeachHub).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 48});

  /// 48 ở T01, 160 ở splash. Bo góc và cỡ chữ tỉ lệ theo [size] như Figma.
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Text(
        'D',
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
          fontSize: size / 2,
          height: 4 / 3,
          color: scheme.onPrimary,
        ),
      ),
    );
  }
}
