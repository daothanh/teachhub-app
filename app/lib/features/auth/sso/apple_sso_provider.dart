import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:tasco_auth/tasco_auth.dart';

typedef AppleCredentialFetcher =
    Future<AuthorizationCredentialAppleID> Function({required String nonce});

/// Sign in with Apple native (iOS), đổi `identityToken` lấy token TeachHub qua
/// `POST /auth/sso/apple` (body do `DioAuthRepository` dựng từ [SsoResult]).
///
/// Quy ước nonce khớp `AppleIdTokenService` của backend: Apple nhận SHA-256
/// dạng hex của nonce, API nhận nonce thô rồi tự băm lại để so với claim `nonce`.
class AppleSsoProvider implements SsoProvider {
  AppleSsoProvider({Random? random, AppleCredentialFetcher? fetchCredential})
    : _random = random ?? Random.secure(),
      _fetch = fetchCredential ?? _fetchFromApple;

  final Random _random;
  final AppleCredentialFetcher _fetch;

  @override
  String get providerId => 'apple';

  @override
  Future<SsoResult> authenticate() async {
    final nonce = base64UrlEncode(
      List.generate(32, (_) => _random.nextInt(256)),
    ).replaceAll('=', '');
    final credential = await _fetch(
      nonce: sha256.convert(utf8.encode(nonce)).toString(),
    );
    final idToken = credential.identityToken;
    if (idToken == null) {
      throw StateError('Apple sign-in returned no identityToken');
    }
    // Apple chỉ trả tên ở lần đăng nhập đầu.
    final fullName = [credential.givenName, credential.familyName]
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .join(' ');
    return SsoResult(
      idToken: idToken,
      extra: {'nonce': nonce, if (fullName.isNotEmpty) 'fullName': fullName},
    );
  }

  static Future<AuthorizationCredentialAppleID> _fetchFromApple({
    required String nonce,
  }) => SignInWithApple.getAppleIDCredential(
    scopes: [
      AppleIDAuthorizationScopes.email,
      AppleIDAuthorizationScopes.fullName,
    ],
    nonce: nonce,
  );
}
