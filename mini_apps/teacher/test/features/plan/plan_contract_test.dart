import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/features/plan/data/plan_models.dart';
import 'package:teacher/features/plan/data/plan_repository.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

/// Đối chiếu client gói/dùng thử với `contracts/openapi.json` (Sprint 7).
final _openapi =
    jsonDecode(
          File(
            '../../packages/teachhub_shared/contracts/openapi.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;
final _schemas =
    (_openapi['components'] as Map)['schemas'] as Map<String, dynamic>;
final _paths = _openapi['paths'] as Map<String, dynamic>;

Map<String, dynamic> get _example =>
    (_schemas['PlanUsage'] as Map)['example'] as Map<String, dynamic>;

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int status = 200;
  Object body = _example;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
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

void main() {
  test(
    'mô hình đọc được ví dụ của hợp đồng (đang dùng thử, không giới hạn)',
    () {
      final u = PlanUsage.fromJson(_example);
      expect(u.isPro, isTrue);
      expect(u.status, SubscriptionStatus.trialing);
      expect([u.daysLeft, u.endDate], [14, '15/03/2027']);
      expect(u.trialAvailable, isFalse);
      expect([u.maxActiveClasses, u.maxActiveStudents], [null, null]);
      expect([u.activeClasses, u.activeStudents], [4, 23]);
      expect(u.hasReadOnly, isFalse);
      expect(u.features, {'compliance.form02': true, 'revenue.export': true});
    },
  );

  test('trạng thái lạ coi như free; chỉ đọc sau hết hạn', () {
    final u = PlanUsage.fromJson({
      ..._example,
      'plan': {
        ...(_example['plan'] as Map<String, dynamic>),
        'code': 'free',
        'status': 'moi-la',
        'currentPeriodEnd': null,
        'daysLeft': null,
        'trialAvailable': false,
      },
      'readOnly': {'classCount': 1, 'studentCount': 5},
    });
    expect([u.isPro, u.status], [false, SubscriptionStatus.free]);
    expect(u.endDate, isNull);
    expect(u.hasReadOnly, isTrue);
  });

  test('mô hình chỉ đọc trường có trong hợp đồng', () {
    // Mọi trường bắt buộc của PlanUsage và plan mà mô hình đọc đều có ở hợp đồng.
    final top = (_schemas['PlanUsage'] as Map)['properties'] as Map;
    for (final k in ['plan', 'limits', 'usage', 'readOnly', 'features']) {
      expect(top, contains(k));
    }
    final plan = (top['plan'] as Map)['properties'] as Map;
    for (final k in [
      'code',
      'status',
      'currentPeriodEnd',
      'daysLeft',
      'trialAvailable',
    ]) {
      expect(plan, contains(k));
    }
  });

  test(
    'đúng method, đường dẫn; trial có Idempotency-Key, không body',
    () async {
      final adapter = _Adapter();
      final repo = DioPlanRepository(
        Dio(BaseOptions(baseUrl: 'http://x/v1'))..httpClientAdapter = adapter,
      );
      await repo.usage();
      await repo.startTrial(idempotencyKey: 'k1');
      final [get, post] = adapter.requests;
      expect([get.method, get.path], ['GET', '/plan-usage']);
      expect([post.method, post.path], ['POST', '/subscription/trial']);
      expect(post.headers['Idempotency-Key'], 'k1');
      expect(post.data, isNull);
      expect(_paths['/v1/plan-usage'], contains('get'));
      final trial = (_paths['/v1/subscription/trial'] as Map)['post'] as Map;
      expect(
        [for (final p in trial['parameters'] as List) (p as Map)['name']],
        ['Idempotency-Key'],
      );
      expect(trial.containsKey('requestBody'), isFalse);
    },
  );

  test('422 TRIAL_ALREADY_USED, 409 và phản hồi sai hình dạng', () async {
    final adapter = _Adapter()
      ..status = 422
      ..body = {'code': 'TRIAL_ALREADY_USED', 'message': 'x', 'requestId': 'r'};
    final repo = DioPlanRepository(
      Dio(BaseOptions(baseUrl: 'http://x/v1'))..httpClientAdapter = adapter,
    );
    await expectLater(
      repo.startTrial(idempotencyKey: 'k'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          ApiErrorCode.trialAlreadyUsed,
        ),
      ),
    );
    adapter
      ..status = 409
      ..body = {'code': 'CONFLICT_STALE', 'message': 'x', 'requestId': 'r'};
    await expectLater(
      repo.startTrial(idempotencyKey: 'k'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          ApiErrorCode.conflictStale,
        ),
      ),
    );
    adapter
      ..status = 200
      ..body = {'plan': 1};
    await expectLater(repo.usage(), throwsA(isA<ApiException>()));
  });
}
