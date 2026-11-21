import 'package:tasco_core/tasco_core.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../routing/app_routes.dart';

/// Đổi URI vào app thành route (spec §2.11 G3).
///
/// `DeepLinkService` của `tasco_core` chỉ nhận scheme `tasco://` và không có
/// host universal link, nên shell tự xử lý:
/// - `https://dayhoc.app/i/<token>` và `teachhub://i/<token>` → `/invite/<token>`
/// - `teachhub://invoices/<id>` (thông báo hóa đơn) → `/p/invoices/<id>`
/// - `teachhub://billing/periods/<id>` (thông báo `billing_ready`) → `/t/billing/<id>`
/// - `teachhub://<route>` → route đó nếu một mini-app nhận nó.
///
/// Mọi đích đều cần đăng nhập; URI lạ trả `null`.
class TeachHubDeepLinkResolver {
  const TeachHubDeepLinkResolver({this.moduleResolver});

  /// Mini-app nào sở hữu đường dẫn (qua `ModuleManager`).
  final DeepLinkModuleResolver? moduleResolver;

  static const _hosts = {'dayhoc.app', 'www.dayhoc.app'};
  static final _invite = RegExp(r'^/i/([A-Za-z0-9_-]+)/?$');
  static final _invoice = RegExp(r'^/invoices/([A-Za-z0-9-]+)/?$');
  static final _billingPeriod = RegExp(r'^/billing/periods/([A-Za-z0-9-]+)/?$');

  DeepLinkTarget? resolve(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final String path;
    if (scheme == 'teachhub' && uri.host.isNotEmpty) {
      path = '/${uri.host}${uri.path}';
    } else if (scheme == 'https' && _hosts.contains(uri.host.toLowerCase())) {
      path = uri.path;
    } else {
      return null;
    }

    final invite = _invite.firstMatch(path);
    if (invite != null) {
      return DeepLinkTarget(path: AppRoutes.invite(invite.group(1)!));
    }

    final invoice = _invoice.firstMatch(path);
    if (invoice != null) {
      return DeepLinkTarget(
        path: '${TeachHubRoutes.parentInvoices}/${invoice.group(1)!}',
      );
    }

    final billing = _billingPeriod.firstMatch(path);
    if (billing != null) {
      return DeepLinkTarget(
        path: '${TeachHubRoutes.teacherBilling}/${billing.group(1)!}',
      );
    }

    final match = moduleResolver?.call(path);
    if (match == null) return null;
    return DeepLinkTarget(
      path: match.path,
      pathParams: match.params,
      queryParams: uri.queryParameters,
      requiresAuth: match.requiresAuth,
    );
  }
}
