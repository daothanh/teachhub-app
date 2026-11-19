import 'dart:io' show Platform;
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:teachhub_shared/teachhub_shared.dart' show uuidV4;

export 'package:teachhub_shared/teachhub_shared.dart' show uuidV4;

/// Gắn các header TeachHub API yêu cầu (spec §5.3):
///
/// - `x-request-id`: UUID cho mỗi request, để truy vết log end-to-end.
/// - `x-client-info`: `teachhub-app/<version> (<platform>)`.
/// - `Idempotency-Key`: UUID cho mọi POST/PATCH. Đặt ở `onRequest`, nên khi
///   `RetryInterceptor`/`AuthInterceptor` gửi lại cùng `RequestOptions` thì
///   khóa giữ nguyên và API chỉ áp dụng lệnh một lần.
///
/// Phải đứng đầu chuỗi interceptor.
class TeachHubHeadersInterceptor extends Interceptor {
  TeachHubHeadersInterceptor({required this.clientInfo, Random? random})
    : _random = random ?? Random.secure();

  final String clientInfo;
  final Random _random;

  static const _idempotentMethods = {'POST', 'PATCH'};

  /// `teachhub-app/<version> (<platform>)` của bản đang cài.
  static Future<String> resolveClientInfo() async {
    final info = await PackageInfo.fromPlatform();
    return 'teachhub-app/${info.version} (${Platform.operatingSystem})';
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final headers = options.headers;
    headers.putIfAbsent('x-request-id', () => uuidV4(_random));
    headers['x-client-info'] = clientInfo;
    if (_idempotentMethods.contains(options.method.toUpperCase())) {
      headers.putIfAbsent('Idempotency-Key', () => uuidV4(_random));
    }
    handler.next(options);
  }
}
