import 'package:app/features/invite/invite_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

class _Api extends Interceptor {
  _Api(this.reply);
  final Response<dynamic> Function(RequestOptions) reply;
  RequestOptions? last;

  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) {
    last = o;
    final r = reply(o);
    if ((r.statusCode ?? 200) >= 400) {
      h.reject(DioException(requestOptions: o, response: r));
    } else {
      h.resolve(r);
    }
  }
}

Response<dynamic> _ok(RequestOptions o, Object data) =>
    Response(requestOptions: o, statusCode: 200, data: data);

void main() {
  test('preview/accept gửi token ở body, không ở đường dẫn', () async {
    final api = _Api((o) {
      if (o.path == '/invites/preview') {
        return _ok(o, {
          'teacherName': 'Cô Lan',
          'studentGivenName': 'Anh',
          'expiresAt': '2026-12-21T09:00:00+07:00',
        });
      }
      return _ok(o, {
        'membershipId': 'm1',
        'studentId': 's1',
        'studentName': 'Nguyễn Minh Anh',
      });
    });
    final repo = DioInviteRepository(Dio()..interceptors.add(api));

    final p = await repo.preview('tok');
    expect(p.teacherName, 'Cô Lan');
    expect(p.studentGivenName, 'Anh');
    expect(api.last!.data, {'token': 'tok'});
    expect(api.last!.uri.toString(), isNot(contains('tok')));

    final a = await repo.accept('tok');
    expect(a.membershipId, 'm1');
    expect(api.last!.path, '/invites/accept');
    expect(api.last!.data, {'token': 'tok'});
  });

  test('redeem-code gửi { code }', () async {
    final api = _Api(
      (o) =>
          _ok(o, {'membershipId': 'm1', 'studentId': 's', 'studentName': 'A'}),
    );
    await DioInviteRepository(
      Dio()..interceptors.add(api),
    ).redeemCode('7K3QZ9XM');
    expect(api.last!.path, '/invites/redeem-code');
    expect(api.last!.data, {'code': '7K3QZ9XM'});
  });

  test(
    'lỗi ra ngoài là ApiException: 410 và 429 khóa kèm retryAfterSec',
    () async {
      final api = _Api((o) {
        if (o.data['code'] == 'LOCKED') {
          return Response(
            requestOptions: o,
            statusCode: 429,
            data: {
              'code': 'INVITE_CODE_LOCKED',
              'message': 'x',
              'requestId': 'r',
              'details': {'retryAfterSec': 900},
            },
          );
        }
        return Response(
          requestOptions: o,
          statusCode: 410,
          data: {'code': 'INVITE_INVALID', 'message': 'x', 'requestId': 'r'},
        );
      });
      final repo = DioInviteRepository(Dio()..interceptors.add(api));

      await expectLater(
        repo.redeemCode('AAAAAAAA'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.inviteInvalid,
          ),
        ),
      );
      await expectLater(
        repo.redeemCode('LOCKED'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', ApiErrorCode.inviteCodeLocked)
              .having(
                (e) => e.retryAfter,
                'retryAfter',
                const Duration(minutes: 15),
              ),
        ),
      );
    },
  );
}
