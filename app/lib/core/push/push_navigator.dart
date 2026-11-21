import 'dart:async';
import 'dart:developer';

import 'package:tasco_core/tasco_core.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../routing/app_routes.dart';

/// Chạm thông báo đẩy → route (spec §2.11 G3, US-0.11 AC5).
///
/// Push là data-only, chỉ có `notificationId` và `type`; `deepLink` và
/// `membershipId` (G11) nếu server gửi thì được dùng. Shell chỉ ghép nối: đổi
/// loại thông báo thành vai trò + route, còn luật hiển thị ở mini-app.
/// Không ghi payload ra log (có thể chứa id của con).
class PushNavigator {
  PushNavigator({
    required this.resolve,
    required this.isAuthenticated,
    required this.memberships,
    required this.active,
    required this.select,
    required this.go,
    this.whenReady,
  });

  /// `TeachHubDeepLinkResolver.resolve`.
  final DeepLinkTarget? Function(Uri uri) resolve;
  final bool Function() isAuthenticated;
  final List<Membership> Function() memberships;
  final Membership? Function() active;

  /// Đổi vai trò đang mở (`MembershipCubit.select`).
  final Future<void> Function(Membership membership) select;
  final void Function(String path) go;

  /// Chờ phiên và danh sách vai trò sẵn sàng (mở app từ thông báo lúc app
  /// chưa chạy); `null` = luôn sẵn sàng; `false` = quá hạn, chưa biết trạng thái.
  final Future<bool> Function()? whenReady;

  /// Vai trò nhận từng loại thông báo khi payload không mang `membershipId`.
  static const _roleByType = {
    'student_absent': MembershipRole.parent,
    'student_absent_correction': MembershipRole.parent,
    'invoice_issued': MembershipRole.parent,
    'billing_ready': MembershipRole.tenantOwner,
  };

  /// Màn đích riêng của loại thông báo khi payload không mang `deepLink`
  /// (push data-only chỉ có `notificationId` và `type`, không có id hóa đơn hay id kỳ).
  static const _routeByType = {
    'invoice_issued': TeachHubRoutes.parentInvoices,
    'billing_ready': TeachHubRoutes.teacherBilling,
  };

  Future<void> handle(Map<String, dynamic> data) async {
    final ready = whenReady == null ? true : await whenReady!();
    final type = _str(data['type']);
    final membershipId = _str(data['membershipId']);
    final deepLink = _str(data['deepLink']);

    final byId = membershipId == null
        ? null
        : memberships().where((m) => m.id == membershipId).firstOrNull;
    final role = byId?.role ?? _roleByType[type] ?? _roleOf(deepLink);
    if (role == null) {
      log('Push loại lạ, bỏ qua: $type', name: 'push');
      return;
    }

    // Màn đích: deepLink nếu một mini-app nhận; không thì trang chủ vai trò.
    // shortcut: màn chi tiết của con phía phụ huynh chưa có, `student_absent*`
    // mở trang chủ /p; thay bằng route chi tiết khi có P02 (S4-FL-08).
    final target = deepLink == null ? null : _resolve(deepLink);
    final path = target?.path ?? _routeByType[type] ?? role.rootRoute;

    if (!ready) {
      // Phiên chưa xác định kịp: không điều hướng bừa, để router mở khi xong.
      PendingDeepLink.save(DeepLinkTarget(path: path));
      return;
    }

    if (!isAuthenticated()) {
      // Qua guard đăng nhập như deep link thường; đăng nhập xong router mở lại.
      PendingDeepLink.save(DeepLinkTarget(path: path));
      go(AppRoutes.login);
      return;
    }

    // Chưa có vai trò đang mở (chưa chọn) thì không tự chọn thay người dùng.
    if (active() != null && active()?.role != role) {
      final next =
          byId ?? memberships().where((m) => m.role == role).firstOrNull;
      if (next == null) {
        // Người dùng không còn vai trò đó (đã xóa): về trang chủ vai trò đang mở.
        go(active()?.role.rootRoute ?? AppRoutes.rolePicker);
        return;
      }
      await select(next);
    }
    go(path);
  }

  DeepLinkTarget? _resolve(String link) {
    final uri = Uri.tryParse(link);
    return uri == null ? null : resolve(uri);
  }

  static MembershipRole? _roleOf(String? deepLink) {
    final uri = deepLink == null ? null : Uri.tryParse(deepLink);
    if (uri == null) return null;
    final first = uri.scheme == 'teachhub'
        ? uri.host
        : uri.pathSegments.firstOrNull;
    return MembershipRole.values
        .where((r) => r.rootRoute == '/$first')
        .firstOrNull;
  }

  static String? _str(Object? v) => v is String && v.isNotEmpty ? v : null;
}
