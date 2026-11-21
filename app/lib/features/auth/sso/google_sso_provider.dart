import 'dart:developer';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:tasco_auth/tasco_auth.dart';

typedef GoogleIdTokenFetcher = Future<String?> Function();

/// Đăng nhập Google native, đổi `id_token` lấy token TeachHub qua
/// `POST /auth/sso/google` (body `{id_token}` do `DioAuthRepository` dựng).
class GoogleSsoProvider implements SsoProvider {
  GoogleSsoProvider({this.serverClientId, GoogleIdTokenFetcher? fetchIdToken})
    : _fetch = fetchIdToken;

  /// OAuth client "Web" — audience của `id_token` mà API xác minh. Bắt buộc
  /// trên Android; trên iOS client ID của app lấy từ `GIDClientID`.
  final String? serverClientId;
  final GoogleIdTokenFetcher? _fetch;

  static Future<void>? _initialized;

  @override
  String get providerId => 'google';

  @override
  Future<SsoResult> authenticate() async {
    final idToken = await (_fetch ?? _fetchFromGoogle)();
    if (idToken == null) {
      throw StateError('Google sign-in returned no id_token');
    }
    return SsoResult(idToken: idToken);
  }

  Future<String?> _fetchFromGoogle() async {
    final serverId = serverClientId?.trim();
    if (serverId == null || serverId.isEmpty) {
      throw StateError(
        'GOOGLE_SERVER_CLIENT_ID is not set in assets/.env.<flavor>',
      );
    }
    final signIn = GoogleSignIn.instance;
    try {
      await (_initialized ??= signIn.initialize(serverClientId: serverId));
    } catch (_) {
      _initialized = null; // cho phép thử lại nếu initialize lỗi
      rethrow;
    }
    return (await signIn.authenticate()).authentication.idToken;
  }

  /// Đăng xuất phiên Google để lần sau hiện lại bộ chọn tài khoản. Chỉ gọi
  /// plugin khi đã `initialize`; lỗi ghi log, không chặn đăng xuất của app.
  Future<void> signOut() async {
    final init = _initialized;
    if (init == null) return;
    try {
      await init;
      await GoogleSignIn.instance.signOut();
    } catch (e, st) {
      log('Google signOut lỗi', name: 'google_sso', error: e, stackTrace: st);
    }
  }
}
