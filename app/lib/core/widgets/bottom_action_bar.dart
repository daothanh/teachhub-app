import 'package:flutter/material.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

/// `Actions/Bottom Action Bar` (C13): thanh nút cố định đáy màn, viền trên.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tasco;
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: scheme.outlineVariant, width: 1.5),
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.only(bottom: tokens.spacingPage),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.spacingPage,
            tokens.spacingContent,
            tokens.spacingPage,
            0,
          ),
          child: child,
        ),
      ),
    );
  }
}
