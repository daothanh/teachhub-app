import 'package:flutter/widgets.dart';

/// Icon Phosphor (bộ icon chính thức của Figma DS, weight Regular — nét 1.5px ở 24px).
///
/// Đóng gói thẳng font `Phosphor.ttf` (MIT, @phosphor-icons/core 2.1.1) thay cho
/// `phosphor_flutter` 2.1.0: gói đó kế thừa `IconData`, mà từ Flutter 3.44
/// `IconData` là `final class` nên không biên dịch được.
/// Thêm icon: lấy codepoint ở https://phosphoricons.com (tên giống Figma).
abstract final class TeachHubIcons {
  static const _family = 'Phosphor';
  static const _package = 'teachhub_shared';

  static const caretDown = IconData(
    0xe136,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const caretLeft = IconData(
    0xe138,
    fontFamily: _family,
    fontPackage: _package,
    matchTextDirection: true,
  );
  static const caretRight = IconData(
    0xe13a,
    fontFamily: _family,
    fontPackage: _package,
    matchTextDirection: true,
  );
  static const check = IconData(
    0xe182,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const gear = IconData(
    0xe270,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const plus = IconData(
    0xe3d4,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const xCircle = IconData(
    0xe4f8,
    fontFamily: _family,
    fontPackage: _package,
  );
}
