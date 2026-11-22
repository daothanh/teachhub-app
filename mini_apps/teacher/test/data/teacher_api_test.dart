import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/data/remote/teacher_api.dart';
import 'package:teacher/data/sync/sync_engine.dart';

void main() {
  test('sync: result lạ thành rejected, không ném lỗi chặn hàng đợi', () async {
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) => h.resolve(
            Response(
              requestOptions: o,
              data: {
                'serverTime': '2026-11-18T10:00:00.000Z',
                'results': [
                  {'clientMutationId': 'm1', 'result': 'applied'},
                  {'clientMutationId': 'm2', 'result': 'deferred'},
                ],
              },
            ),
          ),
        ),
      );
    final res = await TeacherApi(dio, deviceId: 'd').sync(
      SyncRequest(
        sessionId: 's',
        idempotencyKey: 'k',
        deviceTime: DateTime.utc(2026, 11, 18),
        mutations: const [],
      ),
    );
    expect(res.results['m1']!.result, SyncResult.applied);
    expect(res.results['m2']!.result, SyncResult.rejected);
  });
}
