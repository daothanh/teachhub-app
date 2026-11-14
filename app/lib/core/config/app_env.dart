import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tasco_core/tasco_core.dart';

/// Cấu hình theo flavor, đọc từ `assets/.env.<flavor>`.
///
/// Mỗi bản build chỉ đóng gói file `.env` của flavor đó (asset theo flavor
/// trong pubspec.yaml), nên bản production không chứa URL dev/staging.
class AppEnv {
  AppEnv(this.current, Map<String, String> values)
    : apiUrl = values['TEACHHUB_API_URL']?.trim() ?? '',
      googleServerClientId = _orNull(values['GOOGLE_SERVER_CLIENT_ID']),
      certificatePins = (values['CERT_PINS'] ?? '')
          .split(',')
          .map((pin) => pin.trim())
          .where((pin) => pin.isNotEmpty)
          .toSet() {
    if (apiUrl.isEmpty) {
      throw StateError(
        'TEACHHUB_API_URL is empty in assets/.env.${current.name}',
      );
    }
  }

  static Future<AppEnv> load(Env env) async {
    await dotenv.load(fileName: 'assets/.env.${env.name}');
    return AppEnv(env, dotenv.env);
  }

  final Env current;

  /// Base URL của TeachHub API, đã gồm `/v1`.
  final String apiUrl;

  /// SHA-256 pin của leaf certificate API. Rỗng = không pin.
  final Set<String> certificatePins;

  /// OAuth client "Web" để id_token Google có audience mà API xác minh.
  final String? googleServerClientId;

  bool get isProduction => current == Env.production;
  bool get isDevelopment => current == Env.development;

  static String? _orNull(String? v) =>
      (v == null || v.trim().isEmpty) ? null : v.trim();
}
