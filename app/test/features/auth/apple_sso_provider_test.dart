import 'dart:convert';

import 'package:app/features/auth/auth_config.dart';
import 'package:app/features/auth/sso/apple_sso_provider.dart';
import 'package:app/features/auth/sso/sso_cancelled.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:tasco_auth/tasco_auth.dart';
import 'package:tasco_storage/tasco_storage.dart';
import 'package:app/features/auth/teachhub_user.dart';

AuthorizationCredentialAppleID _cred({
  String? token = 'apple.jwt',
  String? given,
  String? family,
}) => AuthorizationCredentialAppleID(
  userIdentifier: 'u',
  givenName: given,
  familyName: family,
  authorizationCode: 'c',
  email: null,
  identityToken: token,
  state: null,
);

/// Adapter giả: ghi lại request, trả status/body cấu hình sẵn.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.status, this.body);
  final int status;
  final Map<String, Object?> body;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

DioAuthRepository<TeachHubUser> _repo(_Adapter a) => DioAuthRepository(
  dio: Dio(BaseOptions(baseUrl: 'https://x/v1'))..httpClientAdapter = a,
  tokenStore: TokenStore(InMemoryKeyValueStore()),
  config: teachHubAuthConfig,
);

const _ok = {
  'access_token': 'a',
  'refresh_token': 'r',
  'user': {'id': 'u1', 'email': 'a@b.vn', 'permissions': <String>[]},
};

void main() {
  test('gửi SHA-256(nonce) cho Apple, nonce thô và fullName lên API', () async {
    String? sentToApple;
    final provider = AppleSsoProvider(
      fetchCredential: ({required nonce}) async {
        sentToApple = nonce;
        return _cred(given: 'Lan', family: 'Nguyễn');
      },
    );
    final result = await provider.authenticate();
    final raw = result.extra['nonce'] as String;
    expect(raw.length, greaterThanOrEqualTo(32));
    expect(sentToApple, sha256.convert(utf8.encode(raw)).toString());
    expect(sentToApple, isNot(raw));

    final adapter = _Adapter(200, _ok);
    await _repo(adapter).loginWithSso(providerId: 'apple', ssoResult: result);
    expect(adapter.last!.path, '/auth/sso/apple');
    expect(adapter.last!.data, {
      'id_token': 'apple.jwt',
      'nonce': raw,
      'fullName': 'Lan Nguyễn',
    });
  });

  test('đăng nhập lại (Apple không trả tên) → không gửi fullName', () async {
    final r = await AppleSsoProvider(
      fetchCredential: ({required nonce}) async => _cred(),
    ).authenticate();
    expect(r.extra.keys, ['nonce']);
  });

  test('hai lần đăng nhập sinh nonce khác nhau', () async {
    final p = AppleSsoProvider(
      fetchCredential: ({required nonce}) async => _cred(),
    );
    expect(
      (await p.authenticate()).extra['nonce'],
      isNot((await p.authenticate()).extra['nonce']),
    );
  });

  test('thiếu identityToken → StateError', () {
    final p = AppleSsoProvider(
      fetchCredential: ({required nonce}) async => _cred(token: null),
    );
    expect(p.authenticate(), throwsStateError);
  });

  test('người dùng hủy → isSsoCancelled', () async {
    final p = AppleSsoProvider(
      fetchCredential: ({required nonce}) async =>
          throw const SignInWithAppleAuthorizationException(
            code: AuthorizationErrorCode.canceled,
            message: 'x',
          ),
    );
    await expectLater(
      p.authenticate(),
      throwsA(predicate<Object>(isSsoCancelled)),
    );
  });

  for (final (status, body) in [
    (401, {'code': 'UNAUTHENTICATED'}),
    (503, {'code': 'SERVICE_UNAVAILABLE'}),
    (
      401,
      {
        'code': 'UNAUTHENTICATED',
        'details': {'reason': 'EMAIL_REQUIRES_OTP'},
      },
    ),
  ]) {
    test('API $status ${body['details'] ?? ''} → DioException đúng status', () {
      final repo = _repo(_Adapter(status, body));
      expect(
        repo.loginWithSso(
          providerId: 'apple',
          ssoResult: const SsoResult(idToken: 't', extra: {'nonce': 'n'}),
        ),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            status,
          ),
        ),
      );
    });
  }
}
