import 'package:app/core/network/consent_required_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

Dio _dio(void Function(String?) onRequired, int status, Object body) {
  final dio = Dio();
  // Interceptor từ chối đứng trước: lỗi chỉ đi tiếp qua các interceptor đứng sau.
  dio.interceptors
    ..add(
      InterceptorsWrapper(
        onRequest: (o, h) => h.reject(
          DioException(
            requestOptions: o,
            response: Response(
              requestOptions: o,
              statusCode: status,
              data: body,
            ),
          ),
          true,
        ),
      ),
    )
    ..add(ConsentRequiredInterceptor(onRequired));
  return dio;
}

void main() {
  test(
    '403 CONSENT_REQUIRED báo termsVersion và vẫn ném lỗi cho nơi gọi',
    () async {
      String? seen;
      var calls = 0;
      final dio = _dio(
        (v) {
          seen = v;
          calls++;
        },
        403,
        {
          'code': 'CONSENT_REQUIRED',
          'message': 'x',
          'requestId': 'r',
          'details': {'termsVersion': '2026-12-01'},
        },
      );
      await expectLater(
        dio.get<void>('/family/students'),
        throwsA(isA<DioException>()),
      );
      expect(seen, '2026-12-01');
      expect(calls, 1);
    },
  );

  test('403 FORBIDDEN và lỗi khác không kích hoạt', () async {
    var calls = 0;
    for (final (status, code) in [
      (403, 'FORBIDDEN'),
      (410, 'INVITE_INVALID'),
    ]) {
      final dio = _dio((_) => calls++, status, {
        'code': code,
        'message': 'x',
        'requestId': 'r',
      });
      await expectLater(dio.get<void>('/x'), throwsA(isA<DioException>()));
    }
    expect(calls, 0);
  });
}
