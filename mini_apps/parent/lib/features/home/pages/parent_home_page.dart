import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../../l10n/l10n.dart';

/// Trang gốc của không gian Phụ huynh. Các màn nghiệp vụ thay thế trang này theo
/// từng sprint.
class ParentHomePage extends StatelessWidget {
  const ParentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return Scaffold(
      appBar: AppBar(
        // Chip vai trò của shell (C20, mở T00); chạy riêng mini-app thì hiện tên không gian.
        title: RoleSwitcherScope.chipOf(context) ?? Text(l10n.spaceTitle),
        centerTitle: false,
      ),
      body: AppEmptyState(
        message: l10n.spaceTitle,
        subMessage: l10n.spaceComingSoon,
        action: AppButton(
          label: l10n.switchRole,
          onPressed: () => context.go(TeachHubRoutes.rolePicker),
        ),
      ),
    );
  }
}
