import 'package:app/features/app_version/app_version_gate.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Trả `GET /app-config` cố định, hoặc ném lỗi mạng khi [body] là null.
class _Api extends Interceptor {
  _Api(this.body);
  final Map<String, dynamic>? body;
  RequestOptions? last;

  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) {
    last = o;
    final b = body;
    if (b == null) {
      h.reject(
        DioException(requestOptions: o, type: DioExceptionType.connectionError),
      );
    } else {
      h.resolve(Response(requestOptions: o, statusCode: 200, data: b));
    }
  }
}

Future<(bool, _Api)> _check(
  Map<String, dynamic>? body, {
  String current = '1.2.0',
  String platform = 'android',
}) async {
  final api = _Api(body);
  final gate = AppVersionGate(
    api: Dio()..interceptors.add(api),
    currentVersion: current,
    platform: platform,
  );
  await gate.check();
  return (gate.value, api);
}

Map<String, dynamic> _config(String android, String ios) => {
  'minSupportedVersion': {'android': android, 'ios': ios},
};

void main() {
  group('isBelow (major.minor.patch)', () {
    test('so từng phần theo số, không theo chuỗi', () {
      expect(isBelow('1.9.0', '1.10.0'), isTrue);
      expect(isBelow('1.10.0', '1.9.0'), isFalse);
      expect(isBelow('1.2.0', '1.2.0'), isFalse);
      expect(isBelow('0.9.9', '1.0.0'), isTrue);
    });

    test('bỏ qua pre-release/build, thiếu phần coi là 0', () {
      expect(isBelow('1.2.0+45', '1.2.0'), isFalse);
      expect(isBelow('1.2.0-beta', '1.2.1'), isTrue);
      expect(isBelow('1.2', '1.2.0'), isFalse);
    });
  });

  test('bản cài thấp hơn mức tối thiểu của đúng nền tảng → chặn', () async {
    final (android, api) = await _check(_config('1.3.0', '0.0.0'));
    expect(android, isTrue);
    expect(api.last!.path, '/app-config');
    expect(api.last!.extra['requiresAuth'], isFalse);

    final (ios, _) = await _check(_config('1.3.0', '0.0.0'), platform: 'ios');
    expect(ios, isFalse);
  });

  test('đủ phiên bản → không chặn', () async {
    final (required, _) = await _check(_config('1.2.0', '1.2.0'));
    expect(required, isFalse);
  });

  test(
    'mất mạng hoặc body lạ → không chặn (app dùng được ngoại tuyến)',
    () async {
      expect((await _check(null)).$1, isFalse);
      expect((await _check({'minSupportedVersion': null})).$1, isFalse);
    },
  );
}
