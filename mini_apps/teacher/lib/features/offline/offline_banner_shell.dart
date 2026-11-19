import 'package:flutter/material.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../data/sync/connectivity.dart';
import '../../l10n/l10n.dart';

/// Màn đã có banner/ghi chú ngoại tuyến riêng: T03 `/t` và T04 (bảng điểm
/// danh). Shell không vẽ thêm ở đó để không trùng.
final _ownBanner = RegExp(
  '^${RegExp.escape(TeachHubRoutes.teacher)}/?\$|'
  '^${RegExp.escape(TeachHubRoutes.teacher)}/sessions/[^/]+/attendance/?\$',
);

bool hasOwnOfflineBanner(String path) => _ownBanner.hasMatch(path);

/// Khung bọc mọi route của teacher: hiện banner "Ngoại tuyến" phía trên màn
/// (theo [onlineChanges]), trừ màn đã có banner riêng ([hasOwnOfflineBanner]).
class OfflineBannerShell extends StatefulWidget {
  const OfflineBannerShell({
    super.key,
    required this.path,
    required this.child,
    this.online,
  });

  final String path;
  final Widget child;

  /// Mặc định [onlineChanges]; test truyền luồng giả.
  final Stream<bool>? online;

  @override
  State<OfflineBannerShell> createState() => _OfflineBannerShellState();
}

class _OfflineBannerShellState extends State<OfflineBannerShell> {
  late final Stream<bool> _online = (widget.online ?? onlineChanges())
      .distinct();

  @override
  Widget build(BuildContext context) {
    if (hasOwnOfflineBanner(widget.path)) return widget.child;
    return StreamBuilder<bool>(
      stream: _online,
      builder: (context, snap) {
        if (snap.data != false) return widget.child;
        return Column(
          children: [
            // Banner chiếm vùng tai thỏ; màn bên dưới bỏ phần đệm trên đó.
            SafeArea(
              bottom: false,
              child: AppBanner(
                tone: AppStatusTone.warning,
                description: context.miniAppL10n.offlineBanner,
                fullWidth: true,
              ),
            ),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: widget.child,
              ),
            ),
          ],
        );
      },
    );
  }
}
