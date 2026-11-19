import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:tasco_auth/tasco_auth.dart';

import '../../../core/network/teachhub_headers_interceptor.dart';

/// Sign in with Apple native (iOS), đổi `identityToken` lấy token TeachHub qua
/// `POST /auth/sso/apple`.
/// TODO(S1-FL-11): `/auth/sso/apple` chưa có trong contracts/openapi.json; đưa vào hợp đồng Sprint 2 (S2-BE-01).
///
/// Apple nhận SHA-256 của nonce; API nhận nonce gốc để so với claim `nonce`
/// trong token (spec §5.2a).
class AppleSsoProvider implements SsoProvider {
  AppleSsoProvider({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  @override
  String get providerId => 'apple';

  @override
  Future<SsoResult> authenticate() async {
    final nonce = uuidV4(_random);
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: sha256.convert(utf8.encode(nonce)).toString(),
    );
    final idToken = credential.identityToken;
    if (idToken == null) {
      throw StateError('Apple sign-in returned no identityToken');
    }
    return SsoResult(idToken: idToken, extra: {'nonce': nonce});
  }
}
