import 'dart:io' show Platform;
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

/// UUID phiên bản 4 (RFC 4122).
String uuidV4(Random random) {
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
