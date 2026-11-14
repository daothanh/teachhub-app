import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tasco_core/tasco_core.dart';

class AppEnv {
  late final Env _env;

  AppEnv();

  Future<void> init(Env env) async {
    _env = env;
    await dotenv.load(fileName: _envFileName);
  }

  Env get current => _env;
  bool get isProduction => _env == Env.production;
  bool get isDevelopment => _env == Env.development;

  String get _envFileName {
    switch (_env) {
      case Env.development:
        return 'assets/.env.development';
      case Env.staging:
        return 'assets/.env.staging';
      case Env.production:
        return 'assets/.env.production';
    }
  }

  /// SHA-256 fingerprint của leaf certificate cho môi trường hiện tại.
  ///
  /// Framework cấp cơ chế (`CertificatePinning`), fingerprint là dữ liệu của
  /// sản phẩm nên khai trong `.env*` theo flavor:
  /// `CERT_PINS=aabb...,ccdd...` (chấp nhận cả dạng `AA:BB:..`).
  /// Rỗng ⇒ không pin — đây là mặc định, và là hành vi trước đây.
  Set<String> get certificatePins => (dotenv.env['CERT_PINS'] ?? '')
      .split(',')
      .map((pin) => pin.trim())
      .where((pin) => pin.isNotEmpty)
      .toSet();

  String get authUrl => dotenv.env['AUTH_URL'] ?? '';
  String get crmUrl => dotenv.env['CRM_URL'] ?? '';
  String get hrmUrl => dotenv.env['HRM_URL'] ?? '';
  String get ticketUrl => dotenv.env['TICKET_URL'] ?? '';

  /// The auth client this app signs in as (`clientId` in the sign-in body).
  /// Empty while unset.
  String get authClientId => dotenv.env['AUTH_CLIENT_ID'] ?? '';

  /// Which client the backend attributes requests to (the `client_source`
  /// header). Empty while unset.
  String get clientSource => dotenv.env['CLIENT_SOURCE'] ?? '';
}
