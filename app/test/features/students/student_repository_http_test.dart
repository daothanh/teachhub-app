import 'dart:convert';
import 'dart:typed_data';

import 'package:app/core/network/teachhub_headers_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/features/students/data/student_models.dart';
import 'package:teacher/features/students/data/student_repository.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.status, this.body);
  final int status;
  final Map<String, Object?> body;
  RequestOptions? seen;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    seen = options;
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

DioStudentRepository _repo(_Adapter a) {
  final dio = Dio(BaseOptions(baseUrl: 'http://x/v1'))
    ..httpClientAdapter = a
    ..interceptors.add(TeachHubHeadersInterceptor(clientInfo: 't'));
  return DioStudentRepository(dio);
}

const _draft = StudentDraft(
  fullName: 'Minh Anh',
  guardians: [GuardianDraft(fullName: 'Hải', phone: '0912345678')],
);

void main() {
  test(
    'POST /students: giữ Idempotency-Key của cubit, confirmNew, không có guardians[].id',
    () async {
      final a = _Adapter(201, {'id': 's1', 'fullName': 'Minh Anh'});
      final s = await _repo(
        a,
      ).create(_draft, idempotencyKey: 'key-1', confirmNew: true);
      expect(s.id, 's1');
      expect(a.seen!.headers['Idempotency-Key'], 'key-1');
      expect(a.seen!.path, '/students');
      final body = a.seen!.data as Map;
      expect(body['confirmNew'], isTrue);
      expect((body['guardians'] as List).single, {
        'fullName': 'Hải',
        'phone': '0912345678',
      });
    },
  );

  test(
    '409 STUDENT_POSSIBLE_DUPLICATE → StudentDuplicateException có candidates',
    () async {
      final a = _Adapter(409, {
        'code': 'STUDENT_POSSIBLE_DUPLICATE',
        'message': 'x',
        'requestId': 'r',
        'details': {
          'candidates': [
            {
              'id': 's9',
              'fullName': 'Minh Anh',
              'dob': '2011-05-20',
              'school': null,
            },
          ],
        },
      });
      await expectLater(
        _repo(a).create(_draft, idempotencyKey: 'k'),
        throwsA(
          isA<StudentDuplicateException>().having(
            (e) => e.candidates.single.id,
            'id',
            's9',
          ),
        ),
      );
    },
  );

  test('phản hồi 201 sai hình dạng → lỗi chung, không ném kiểu lạ', () async {
    final a = _Adapter(201, {'id': 5});
    await expectLater(
      _repo(a).create(_draft, idempotencyKey: 'k'),
      throwsA(isA<Exception>()),
    );
  });
}
