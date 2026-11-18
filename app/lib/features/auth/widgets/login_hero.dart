import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';

/// Hình minh họa "Thầy – Trò – Gia đình" của T01 (Figma 88:11172).
///
/// Bố cục cố định 358×232 như Figma, co giãn theo chiều rộng màn. Chỉ để
/// trang trí: không đọc cho trình đọc màn hình.
class LoginHero extends StatelessWidget {
  const LoginHero({super.key});

  static const _width = 358.0;
  static const _height = 232.0;
  static const _assets = 'assets/images/login';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tasco;
    final scheme = Theme.of(context).colorScheme;

    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.sheetRadius),
        child: ColoredBox(
          color: scheme.primaryContainer,
          child: AspectRatio(
            aspectRatio: _width / _height,
            child: FittedBox(
              child: SizedBox(
                width: _width,
                height: _height,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      left: 236,
                      top: -70,
                      child: SvgPicture.asset('$_assets/hero_accent.svg'),
                    ),
                    Positioned(
                      left: -46,
                      top: 150,
                      child: SvgPicture.asset('$_assets/hero_accent_2.svg'),
                    ),
                    _link(96, 78, 139.06, 'hero_link_gv_hs.svg'),
                    _link(179, 78, 40.94, 'hero_link_gv_ph.svg'),
                    Positioned(
                      left: 96,
                      top: 149.25,
                      child: SvgPicture.asset('$_assets/hero_link_hs_ph.svg'),
                    ),
                    Positioned(
                      left: 152,
                      top: 51,
                      child: _Person('MH', l10n.heroTeacher),
                    ),
                    Positioned(
                      left: 69,
                      top: 123,
                      child: _Person('NA', l10n.heroStudent),
                    ),
                    Positioned(
                      left: 235,
                      top: 123,
                      child: _Person('PH', l10n.heroFamily),
                    ),
                    Positioned(
                      left: 14,
                      top: 16,
                      child: _Tag(
                        l10n.heroAttended,
                        color: tokens.successColor,
                        check: true,
                      ),
                    ),
                    Positioned(
                      left: 228,
                      top: 16,
                      child: _Tag(
                        l10n.heroInvoiceSent,
                        color: scheme.onSurface,
                      ),
                    ),
                    Positioned(
                      left: 126,
                      top: 200,
                      child: _Tag(
                        l10n.heroAbsenceReported,
                        color: tokens.warningColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Đường nối nét đứt xoay trong khung 83×72 (giống frame xoay của Figma).
  static Widget _link(double left, double top, double degrees, String asset) =>
      Positioned(
        left: left,
        top: top,
        width: 83,
        height: 72,
        child: Center(
          child: Transform.rotate(
            angle: degrees * math.pi / 180,
            child: SvgPicture.asset('$_assets/$asset'),
          ),
        ),
      );
}

/// `Display/Avatar` 48 trong vòng trắng 3px + nhãn Caption Bold.
class _Person extends StatelessWidget {
  const _Person(this.initials, this.label);

  final String initials;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: scheme.surface,
            shape: BoxShape.circle,
            // DS/Elevation/1 · Raised
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(color: scheme.outlineVariant, width: 1.5),
            ),
            child: Text(initials, style: text.titleSmall),
          ),
        ),
        SizedBox(height: context.tasco.spacingInline),
        Text(
          label,
          style: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

/// `Display/Tag` Filled (Success có icon check đứng trước — trạng thái không chỉ dựa vào màu).
class _Tag extends StatelessWidget {
  const _Tag(this.label, {required this.color, this.check = false});

  final String label;
  final Color color;
  final bool check;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tasco;
    final onColor = Theme.of(context).colorScheme.onInverseSurface;
    return Container(
      height: 24,
      padding: EdgeInsets.only(
        left: check ? tokens.spacingInline : tokens.spacingControl,
        right: tokens.spacingControl,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(tokens.pillRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            offset: Offset(0, 4),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (check) ...[
            SvgPicture.asset(
              '${LoginHero._assets}/tag_check.svg',
              colorFilter: ColorFilter.mode(onColor, BlendMode.srcIn),
            ),
            SizedBox(width: tokens.spacingInline),
          ],
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: onColor),
          ),
        ],
      ),
    );
  }
}
