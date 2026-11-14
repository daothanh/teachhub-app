import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../../l10n/l10n.dart';

/// Trang gốc của không gian Giáo viên. Các màn nghiệp vụ thay thế trang này theo
/// từng sprint.
class TeacherHomePage extends StatelessWidget {
  const TeacherHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.spaceTitle)),
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
