import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/features/classes/data/class_models.dart';
import 'package:teacher/features/classes/data/classes_repository.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.status, this.body);
  final int? status;
  final Map<String, dynamic> body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (status == null) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status!,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

DioClassesRepository _repo(
  int? status, [
  Map<String, dynamic> body = const {},
]) => DioClassesRepository(
  Dio(BaseOptions(baseUrl: 'http://x/v1'))
    ..httpClientAdapter = _Adapter(status, body),
);

void main() {
  test('422 có errors theo trường → ApiException.fieldErrors', () async {
    final e =
        await _repo(422, {
              'code': 'VALIDATION_FAILED',
              'message': 'Sai dữ liệu',
              'errors': {
                'endDate': ['Ngày kết thúc không được trước ngày bắt đầu.'],
              },
              'requestId': 'r',
            })
            .create(const ClassInput())
            .then<ApiException>(
              (_) => fail('phải ném'),
              onError: (Object e) => e as ApiException,
            );
    expect(e.code, ApiErrorCode.validationFailed);
    expect(e.fieldErrors['endDate'], isNotEmpty);
  });

  test('402 → PLAN_LIMIT_EXCEEDED, 409 → CONFLICT_STALE', () async {
    Future<ApiException> run(int s, String code) =>
        _repo(s, {'code': code, 'message': 'm', 'requestId': 'r'})
            .enroll('c', 's')
            .then<ApiException>(
              (_) => fail('phải ném'),
              onError: (Object e) => e as ApiException,
            );
    expect(
      (await run(402, 'PLAN_LIMIT_EXCEEDED')).code,
      ApiErrorCode.planLimitExceeded,
    );
    expect((await run(409, 'CONFLICT_STALE')).code, ApiErrorCode.conflictStale);
  });

  test('mất mạng → ApiException.network', () async {
    final e = await _repo(null)
        .get('c')
        .then<ApiException>(
          (_) => fail('phải ném'),
          onError: (Object e) => e as ApiException,
        );
    expect(e.kind, ApiErrorKind.network);
  });
}
