import 'package:google_sign_in/google_sign_in.dart';
import 'package:tasco_auth/tasco_auth.dart';

/// Đăng nhập Google native, đổi `id_token` lấy token TeachHub qua
/// `POST /auth/sso/google`.
class GoogleSsoProvider implements SsoProvider {
  GoogleSsoProvider({this.serverClientId});

  /// OAuth client "Web" — audience của `id_token` mà API xác minh. Bắt buộc
  /// trên Android; trên iOS client ID của app lấy từ `GIDClientID`.
  final String? serverClientId;

  static Future<void>? _initialized;

  @override
  String get providerId => 'google';

  @override
  Future<SsoResult> authenticate() async {
    final signIn = GoogleSignIn.instance;
    await (_initialized ??= signIn.initialize(serverClientId: serverClientId));
    final account = await signIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw StateError('Google sign-in returned no id_token');
    }
    return SsoResult(idToken: idToken);
  }
}
