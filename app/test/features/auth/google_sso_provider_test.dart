import 'package:app/features/auth/auth_config.dart';
import 'package:app/features/auth/sso/google_sso_provider.dart';
import 'package:app/features/auth/sso/sso_cancelled.dart';
import 'package:app/features/auth/teachhub_user.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tasco_auth/tasco_auth.dart';
import 'package:tasco_storage/tasco_storage.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.status);
  final int status;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      status == 200
          ? '{"access_token":"a","refresh_token":"r","user":{"id":"u1","email":"a@b.vn","permissions":[]}}'
          : '{"code":"X"}',
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

void main() {
  group('GoogleSsoProvider', () {
    test(
      'thành công: id_token đi lên POST /auth/sso/google đúng hợp đồng',
      () async {
        final provider = GoogleSsoProvider(fetchIdToken: () async => 'g.jwt');
        expect(provider.providerId, 'google');
        final result = await provider.authenticate();
        final adapter = _Adapter(200);
        await _repo(
          adapter,
        ).loginWithSso(providerId: 'google', ssoResult: result);
        expect(adapter.last!.path, '/auth/sso/google');
        expect(adapter.last!.data, {'id_token': 'g.jwt'});
      },
    );

    test('thiếu id_token → StateError', () {
      final p = GoogleSsoProvider(fetchIdToken: () async => null);
      expect(p.authenticate(), throwsStateError);
    });

    test('người dùng hủy → isSsoCancelled', () async {
      final p = GoogleSsoProvider(
        fetchIdToken: () async => throw const GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
        ),
      );
      await expectLater(
        p.authenticate(),
        throwsA(predicate<Object>(isSsoCancelled)),
      );
    });

    test('lỗi mạng khi gọi Google được ném nguyên', () {
      final p = GoogleSsoProvider(
        fetchIdToken: () async => throw const GoogleSignInException(
          code: GoogleSignInExceptionCode.unknownError,
        ),
      );
      expect(p.authenticate(), throwsA(isA<GoogleSignInException>()));
    });

    for (final status in [401, 503]) {
      test('API $status → DioException đúng status', () {
        final repo = _repo(_Adapter(status));
        expect(
          repo.loginWithSso(
            providerId: 'google',
            ssoResult: const SsoResult(idToken: 't'),
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

    test(
      'serverClientId null/rỗng → StateError cấu hình, không gọi plugin',
      () {
        for (final id in [null, '', '  ']) {
          expect(
            GoogleSsoProvider(serverClientId: id).authenticate(),
            throwsA(
              isA<StateError>().having(
                (e) => e.message,
                'message',
                contains('GOOGLE_SERVER_CLIENT_ID'),
              ),
            ),
          );
        }
      },
    );
  });
}
