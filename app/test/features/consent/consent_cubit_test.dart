import 'dart:async';

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

  group('chống ghi đè lệch thứ tự (generation)', () {
    Future<ConsentCubit> slow(Completer<Response<dynamic>> gate) async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) async {
            final r = await gate.future;
            h.resolve(
              Response(requestOptions: o, statusCode: 200, data: r.data),
            );
          },
        ),
      );
      return ConsentCubit(dio);
    }

    test('load chậm trả về sau clear() bị bỏ', () async {
      final gate = Completer<Response<dynamic>>();
      final c = await slow(gate);
      final pending = c.load();
      c.clear();
      gate.complete(
        Response(requestOptions: RequestOptions(), data: _status('v1')),
      );
      await pending;
      expect(c.state.phase, ConsentPhase.unknown);
    });

    test(
      'load chậm trả về sau markAccepted() không hạ xuống required',
      () async {
        final gate = Completer<Response<dynamic>>();
        final c = await slow(gate);
        final pending = c.load();
        c.markAccepted();
        gate.complete(
          Response(requestOptions: RequestOptions(), data: _status('v1')),
        );
        await pending;
        expect(c.state.accepted, isTrue);
      },
    );

    test('load chậm trả về sau markRequired() không ghi đè', () async {
      final gate = Completer<Response<dynamic>>();
      final c = await slow(gate);
      final pending = c.load();
      c.markRequired('v9');
      gate.complete(
        Response(
          requestOptions: RequestOptions(),
          data: _status('v1', accepted: true),
        ),
      );
      await pending;
      expect(c.state.termsVersion, 'v9');
      expect(c.state.accepted, isFalse);
    });
  });

  test(
    'resetForNewUser: có vai Phụ huynh thì tải lại, không thì chỉ xóa',
    () async {
      final api = _Api({
        'GET /consents/status': (o) => _r(o, 200, _status('v2')),
      });
      final c = ConsentCubit(Dio()..interceptors.add(api));
      await c.load();
      expect(c.state.phase, ConsentPhase.required);

      c.resetForNewUser(hasParentRole: false);
      expect(c.state.phase, ConsentPhase.unknown);
      expect(api.calls, hasLength(1));

      c.resetForNewUser(hasParentRole: true);
      await pumpEventQueue();
      expect(api.calls, hasLength(2));
      expect(c.state.phase, ConsentPhase.required);
    },
  );
}
