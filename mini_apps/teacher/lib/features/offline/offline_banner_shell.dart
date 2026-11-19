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
    final own = hasOwnOfflineBanner(widget.path);
    // Cấu trúc cây cố định dù có banner hay không: nếu không, đổi trạng thái
    // mạng sẽ dựng lại Navigator của teacher và mất ngăn xếp màn/biểu mẫu.
    return StreamBuilder<bool>(
      stream: _online,
      builder: (context, snap) {
        final offline = !own && snap.data == false;
        return Column(
          children: [
            if (offline)
              // Banner chiếm vùng tai thỏ; màn bên dưới bỏ phần đệm trên đó.
              SafeArea(
                bottom: false,
                child: AppBanner(
                  tone: AppStatusTone.warning,
                  description: context.miniAppL10n.offlineBanner,
                  fullWidth: true,
                ),
              )
            else
              const SizedBox.shrink(),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: offline,
                child: widget.child,
              ),
            ),
          ],
        );
      },
    );
  }
}
