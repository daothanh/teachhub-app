import 'package:app/features/consent/consent_cubit.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Api extends Interceptor {
  _Api(this.routes);
  final Map<String, Response<dynamic> Function(RequestOptions)> routes;
  final calls = <String>[];
  final bodies = <Object?>[];

  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) {
    calls.add('${o.method} ${o.path}');
    bodies.add(o.data);
    final r = routes['${o.method} ${o.path}']!(o);
    if ((r.statusCode ?? 200) >= 400) {
      h.reject(DioException(requestOptions: o, response: r));
    } else {
      h.resolve(r);
    }
  }
}

Response<dynamic> _r(RequestOptions o, int code, Object data) =>
    Response(requestOptions: o, statusCode: code, data: data);

Map<String, dynamic> _status(String v, {bool accepted = false}) => {
  'role': 'parent',
  'currentTermsVersion': v,
  'accepted': accepted,
  'acceptedAt': null,
  'acceptedTermsVersion': null,
};

void main() {
  test(
    'load: chưa đồng ý → required kèm phiên bản; đã đồng ý → accepted',
    () async {
      var accepted = false;
      final api = _Api({
        'GET /consents/status': (o) =>
            _r(o, 200, _status('v1', accepted: accepted)),
      });
      final c = ConsentCubit(Dio()..interceptors.add(api));
      await c.load();
      expect(c.state.phase, ConsentPhase.required);
      expect(c.state.termsVersion, 'v1');
      accepted = true;
      await c.load();
      expect(c.state.accepted, isTrue);
    },
  );

  test('accept: POST đúng phiên bản vừa đọc rồi accepted', () async {
    final api = _Api({
      'GET /consents/status': (o) => _r(o, 200, _status('v1')),
      'POST /consents': (o) => _r(o, 201, {}),
    });
    final c = ConsentCubit(Dio()..interceptors.add(api));
    await c.load();
    await c.accept();
    expect(api.bodies.last, {'role': 'parent', 'termsVersion': 'v1'});
    expect(c.state.accepted, isTrue);
  });

  test(
    'accept gặp 409 (đổi phiên bản): tải bản mới, báo đã đổi, chưa đồng ý',
    () async {
      var version = 'v1';
      final api = _Api({
        'GET /consents/status': (o) => _r(o, 200, _status(version)),
        'POST /consents': (o) {
          version = 'v2';
          return _r(o, 409, {
            'code': 'CONFLICT_STALE',
            'message': 'x',
            'requestId': 'r',
          });
        },
      });
      final c = ConsentCubit(Dio()..interceptors.add(api));
      await c.load();
      await c.accept();
      expect(c.state.phase, ConsentPhase.required);
      expect(c.state.termsVersion, 'v2');
      expect(c.state.termsChanged, isTrue);
    },
  );

  test('accept lỗi mạng: giữ required, báo submitFailed', () async {
    final api = _Api({
      'GET /consents/status': (o) => _r(o, 200, _status('v1')),
      'POST /consents': (o) => _r(o, 500, {
        'code': 'INTERNAL_ERROR',
        'message': 'x',
        'requestId': 'r',
      }),
    });
    final c = ConsentCubit(Dio()..interceptors.add(api));
    await c.load();
    await c.accept();
    expect(c.state.phase, ConsentPhase.required);
    expect(c.state.submitFailed, isTrue);
  });

  test('markRequired / markAccepted / clear', () {
    final c = ConsentCubit(Dio());
    c.markRequired('v3');
    expect(c.state.termsVersion, 'v3');
    expect(c.state.accepted, isFalse);
    c.markAccepted();
    expect(c.state.accepted, isTrue);
    c.clear();
    expect(c.state.phase, ConsentPhase.unknown);
  });
}
