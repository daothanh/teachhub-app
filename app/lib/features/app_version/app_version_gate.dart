import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Ép cập nhật (spec §5.1): `GET /v1/app-config` trả `minSupportedVersion`
/// theo nền tảng; bản đang cài thấp hơn → [value] = `true`, router chuyển sang
/// màn "Cần cập nhật".
///
/// Không chờ khi khởi động và không chặn khi gọi lỗi (mất mạng, API lỗi):
/// app phải dùng được ngoại tuyến (NFR-17); lần mở sau sẽ kiểm lại.
class AppVersionGate extends ValueNotifier<bool> {
  AppVersionGate({
    required Dio api,
    required this.currentVersion,
    required this.platform,
  }) : _api = api,
       super(false);

  final Dio _api;

  /// `version` của bản đang cài (pubspec, không gồm build number).
  final String currentVersion;

  /// `android` | `ios` — khóa trong `minSupportedVersion`.
  final String platform;

  Future<void> check() async {
    try {
      final res = await _api.get<Map<String, dynamic>>(
        '/app-config',
        options: Options(extra: const {'requiresAuth': false}),
      );
      final min = (res.data?['minSupportedVersion'] as Map?)?[platform];
      if (min is String) value = isBelow(currentVersion, min);
    } catch (e) {
      debugPrint('app-config: bỏ qua kiểm phiên bản ($e)');
    }
  }
}

/// `true` khi [current] < [minimum] theo `major.minor.patch`. Phần
/// pre-release/build (`-beta`, `+12`) bị bỏ qua; số không đọc được coi là 0.
@visibleForTesting
bool isBelow(String current, String minimum) {
  List<int> parts(String v) {
    final core = v.split(RegExp('[-+]')).first.split('.');
    return [
      for (var i = 0; i < 3; i++)
        int.tryParse(core.elementAtOrNull(i) ?? '') ?? 0,
    ];
  }

  final a = parts(current), b = parts(minimum);
  for (var i = 0; i < 3; i++) {
    if (a[i] != b[i]) return a[i] < b[i];
  }
  return false;
}
