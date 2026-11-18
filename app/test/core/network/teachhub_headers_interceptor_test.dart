import 'package:app/core/network/api_error.dart';
import 'package:teachhub_shared/teachhub_shared.dart';
import 'package:app/core/network/teachhub_headers_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ghi lại request đã đi qua interceptor thay vì gửi ra mạng.
class _Capture extends Interceptor {
  final requests = <RequestOptions>[];
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    requests.add(options);
    handler.resolve(Response(requestOptions: options, statusCode: 200));
  }
}

void main() {
  late Dio dio;
  late _Capture capture;

  setUp(() {
    capture = _Capture();
    dio = Dio(BaseOptions(baseUrl: 'https://api.teachhub.vn/v1'))
      ..interceptors.addAll([
        TeachHubHeadersInterceptor(clientInfo: 'teachhub-app/1.0.0 (ios)'),
        capture,
      ]);
  });

  test('every request carries a request id and the client info', () async {
    await dio.get<void>('/auth/me');
    final h = capture.requests.single.headers;
    expect(h['x-client-info'], 'teachhub-app/1.0.0 (ios)');
    expect(h['x-request-id'], matches(RegExp(r'^[0-9a-f-]{36}$')));
    expect(h.containsKey('Idempotency-Key'), isFalse);
  });

  test(
    'POST and PATCH get an Idempotency-Key, kept when already set',
    () async {
      await dio.post<void>('/workspaces');
      await dio.patch<void>('/onboarding/steps/1');
      await dio.post<void>(
        '/me/roles',
        options: Options(headers: {'Idempotency-Key': 'fixed'}),
      );
      final keys = capture.requests.map((r) => r.headers['Idempotency-Key']);
      expect(keys.elementAt(0), isNotNull);
      expect(keys.elementAt(1), isNot(keys.elementAt(0)));
      expect(keys.elementAt(2), 'fixed');
    },
  );

  test('a path with a leading slash keeps the /v1 prefix', () async {
    await dio.post<void>('/push/register');
    expect(
      capture.requests.single.uri.toString(),
      'https://api.teachhub.vn/v1/push/register',
    );
  });

  test(
    'apiException đọc body lỗi TeachHub, Retry-After; mất mạng → network',
    () {
      final options = RequestOptions(path: '/auth/login');
      final err = DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 429,
          data: {'code': 'RATE_LIMITED', 'message': 'x'},
          headers: Headers.fromMap({
            'retry-after': ['30'],
          }),
        ),
      );
      final e = apiException(err)!;
      expect(e.code, ApiErrorCode.rateLimited);
      expect(e.kind, ApiErrorKind.rateLimited);
      expect(e.retryAfter, const Duration(seconds: 30));

      final offline = apiException(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      )!;
      expect(offline.kind, ApiErrorKind.network);
      expect(apiException(StateError('x')), isNull);
    },
  );
}
