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
  _keyAndParseTests();

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

/// Giống interceptor header của host: chỉ gắn khóa khi chưa có (`putIfAbsent`).
class _HostLikeHeaders extends Interceptor {
  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) {
    if (const {'POST', 'PATCH'}.contains(o.method)) {
      o.headers.putIfAbsent('Idempotency-Key', () => 'host-generated');
    }
    h.next(o);
  }
}

class _Recorder implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  Object? responseBody = {};
  int status = 200;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(responseBody),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void _keyAndParseTests() {
  late _Recorder rec;
  late DioClassesRepository repo;
  setUp(() {
    rec = _Recorder();
    repo = DioClassesRepository(
      Dio(BaseOptions(baseUrl: 'http://x/v1'))
        ..httpClientAdapter = rec
        ..interceptors.add(_HostLikeHeaders()),
    );
  });

  test(
    'khóa truyền vào được giữ qua interceptor; không truyền thì host sinh',
    () async {
      rec.responseBody = {'error': 'x'};
      rec.status = 422;
      for (final key in ['k-1', 'k-1', null]) {
        await repo
            .archive('c1', idempotencyKey: key)
            .then<void>((_) {}, onError: (_) {});
      }
      expect(rec.requests.map((r) => r.headers['Idempotency-Key']), [
        'k-1',
        'k-1',
        'host-generated',
      ]);
    },
  );

  test(
    'PUT schedule-rules mang khóa dù interceptor host chỉ lo POST/PATCH',
    () async {
      rec.responseBody = {
        'rules': [],
        'sessionsGenerated': 0,
        'sessionsRemoved': 0,
      };
      await repo.putRules('c1', const [], idempotencyKey: 'k-put');
      expect(rec.requests.single.method, 'PUT');
      expect(rec.requests.single.headers['Idempotency-Key'], 'k-put');
      expect(rec.requests.single.data, {'rules': []});
    },
  );

  test(
    'body tạo lớp đúng hợp đồng: lớp trực tuyến không gửi địa điểm',
    () async {
      rec.status = 422;
      rec.responseBody = {
        'code': 'VALIDATION_FAILED',
        'errors': {
          'name': ['x'],
        },
      };
      await repo
          .create(
            const ClassInput(
              name: ' Toán ',
              subject: 'Toán',
              grade: 9,
              mode: ClassMode.online,
              location: 'bỏ',
              startDate: '2026-12-14',
            ),
            idempotencyKey: 'k',
          )
          .then<void>((_) {}, onError: (_) {});
      expect(rec.requests.single.data, {
        'name': 'Toán',
        'subject': 'Toán',
        'grade': 9,
        'mode': 'online',
        'location': null,
        'capacity': null,
        'startDate': '2026-12-14',
        'endDate': null,
      });
    },
  );

  group('phản hồi sai định dạng → ApiException chung, không ném lỗi lạ', () {
    Future<ApiException> fail(Future<Object?> f) => f.then<ApiException>(
      (_) => throw StateError('phải ném ApiException'),
      onError: (Object e) => e as ApiException,
    );

    test('thân rỗng, thiếu trường, sai kiểu', () async {
      for (final body in <Object?>[
        null,
        {},
        {'id': 1},
        [],
      ]) {
        rec.responseBody = body;
        final e = await fail(repo.get('c1'));
        expect(e.kind, ApiErrorKind.server, reason: '$body');
      }
    });

    test('status lớp lạ → lỗi chung (không hiện nhầm là đang dạy)', () async {
      rec.responseBody = {
        'id': 'c1',
        'name': 'n',
        'subject': 's',
        'grade': 9,
        'mode': 'offline',
        'location': null,
        'capacity': null,
        'startDate': '2026-12-14',
        'endDate': null,
        'status': 'frozen',
        'enrolledCount': 0,
        'scheduleRules': [],
        'createdAt': '2026-12-01T00:00:00.000Z',
      };
      expect((await fail(repo.get('c1'))).kind, ApiErrorKind.server);
    });

    test('mode lạ không ném, rơi về mặc định', () async {
      rec.responseBody = {
        'id': 'c1',
        'name': 'n',
        'subject': 's',
        'grade': 9,
        'mode': 'hybrid-moi',
        'location': null,
        'capacity': null,
        'startDate': '2026-12-14',
        'endDate': null,
        'status': 'active',
        'enrolledCount': 0,
        'scheduleRules': [],
        'createdAt': '2026-12-01T00:00:00.000Z',
      };
      final c = await repo.get('c1');
      expect(c.mode, ClassMode.offline);
      expect(c.status, ClassStatus.active);
    });
  });
}
