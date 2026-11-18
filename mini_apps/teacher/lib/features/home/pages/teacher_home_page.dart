import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../../data/sync/connectivity.dart';
import '../../../l10n/l10n.dart';

/// Trang gốc của không gian Giáo viên. Các màn nghiệp vụ thay thế trang này theo
/// từng sprint.
class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({super.key, this.online});

  /// Trạng thái mạng; mặc định [onlineChanges].
  final Stream<bool>? online;

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  late final Stream<bool> _online = (widget.online ?? onlineChanges())
      .distinct();

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return Scaffold(
      appBar: AppBar(
        // Chip vai trò của shell (C20, mở T00); chạy riêng mini-app thì hiện tên không gian.
        title: RoleSwitcherScope.chipOf(context) ?? Text(l10n.spaceTitle),
        centerTitle: false,
      ),
      body: Column(
        children: [
          StreamBuilder<bool>(
            stream: _online,
            builder: (context, snap) => snap.data == false
                ? AppBanner(
                    tone: AppStatusTone.warning,
                    description: l10n.offlineBanner,
                    fullWidth: true,
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: AppEmptyState(
              message: l10n.spaceTitle,
              subMessage: l10n.spaceComingSoon,
              action: AppButton(
                label: l10n.switchRole,
                onPressed: () => context.go(TeachHubRoutes.rolePicker),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
