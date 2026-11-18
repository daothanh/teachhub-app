import 'package:flutter/widgets.dart';

/// Chip vai trò C20 (spec Figma-AI §0.5): shell dựng, mini-app chỉ đặt vào App Bar
/// `Root` nên không phụ thuộc Cubit hay route của shell (US-0.11).
class RoleSwitcherScope extends InheritedWidget {
  const RoleSwitcherScope({
    super.key,
    required this.chip,
    required super.child,
  });

  final WidgetBuilder chip;

  /// Chip của shell; `null` khi chạy mini-app một mình (vd. widget test).
  static Widget? chipOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<RoleSwitcherScope>()
      ?.chip(context);

  @override
  bool updateShouldNotify(RoleSwitcherScope oldWidget) =>
      oldWidget.chip != chip;
}
