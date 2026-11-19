// S0-FL-08: spike SyncEngine trên MÁY THẬT với CSDL teacher mã hóa.
//
// "Endpoint giả" `POST /v1/attendance/sync` là HttpServer chạy ngay trong app
// (loopback), nên "tắt mạng" = server chưa mở (connection refused) mà không phải
// đổi cài đặt mạng của máy. Kịch bản DoD: tắt mạng → lưu → bật mạng → mỗi
// mutation được áp dụng đúng 1 lần, kể cả khi một phản hồi bị mất giữa đường.
//   flutter test integration_test/sync_engine_device_test.dart -d <máy> --flavor development
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tasco_storage/tasco_storage.dart';
import 'package:teacher/data/local_db/teacher_database.dart';
import 'package:teacher/data/sync/connectivity.dart';
import 'package:teacher/data/sync/enqueue_attendance.dart';
import 'package:teacher/data/sync/sync_engine.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

/// Endpoint giả: nhớ `clientMutationId`, trả applied/duplicate như spec.
class FakeEndpoint {
  HttpServer? _server;
  final applied = <String>{};
  var duplicates = 0;
  var requests = 0;
  var dropNextResponse = false;

  Future<void> start(int port) async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    _server!.listen((req) async {
      requests++;
      final body = jsonDecode(await utf8.decodeStream(req)) as Map;
      final results = [
        for (final m in body['mutations'] as List)
          {
            'clientMutationId': m['clientMutationId'],
            'result': applied.add(m['clientMutationId'] as String)
                ? 'applied'
                : 'duplicate',
          },
      ];
      duplicates += results.where((r) => r['result'] == 'duplicate').length;
      if (dropNextResponse) {
        // Đã áp dụng nhưng client không nhận được phản hồi.
        dropNextResponse = false;
        (await req.response.detachSocket()).destroy();
        return;
      }
      req.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'results': results}));
      await req.response.close();
    });
  }

  Future<void> stop() async => _server?.close(force: true);
}

/// Transport tối giản cho spike (HttpClient trần, không qua Dio của host).
SyncTransport httpTransport(HttpClient client, Uri endpoint) => (req) async {
  try {
    final post = await client.postUrl(endpoint);
    post.headers.contentType = ContentType.json;
    post.write(
      jsonEncode({
        'mutations': [
          for (final m in req.mutations)
            {
              'clientMutationId': m.clientMutationId,
              'clientUpdatedAt': m.clientUpdatedAt.toIso8601String(),
              ...jsonDecode(m.payload) as Map,
            },
        ],
      }),
    );
    final res = await post.close();
    final body = jsonDecode(await utf8.decodeStream(res));
    if (res.statusCode != 200) {
      throw ApiException.fromResponse(res.statusCode, body);
    }
    return SyncResponse(
      serverTime: DateTime.now().toUtc(),
      results: {
        for (final r in (body as Map)['results'] as List)
          r['clientMutationId'] as String: MutationResult(
            SyncResult.values.byName(r['result'] as String),
            errorCode: r['errorCode'] as String?,
          ),
      },
    );
  } on IOException {
    throw const ApiException.network();
  }
};

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('tắt mạng → lưu → bật mạng → đẩy đúng 1 lần', () async {
    final log = Stopwatch()..start();
    void note(String s) =>
        print('SYNC ${log.elapsedMilliseconds}ms $s'); // ignore: avoid_print

    final realOnline = await onlineChanges().first;
    note('connectivity_plus báo có mạng: $realOnline');

    final store = SecureStore();
    await deleteTeacherDatabase(
      store,
      await getApplicationDocumentsDirectory(),
    );
    final db = await TeacherDatabase.openEncrypted(store);

    // Lấy một cổng trống rồi đóng lại: chưa có server = "mất mạng".
    final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = probe.port;
    await probe.close();
    final endpoint = FakeEndpoint();
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
    final engine = SyncEngine(
      db,
      httpTransport(
        client,
        Uri.parse('http://127.0.0.1:$port/v1/attendance/sync'),
      ),
      batchSize: 10,
    );
    final online = StreamController<bool>();

    try {
      final ids = [
        for (var i = 0; i < 25; i++)
          'cm-${DateTime.now().microsecondsSinceEpoch}-$i',
      ];
      final sw = Stopwatch()..start();
      for (final (i, id) in ids.indexed) {
        await enqueueAttendance(
          db,
          sessionId: 'session-1',
          studentId: 's$i',
          status: 'present',
          clientUpdatedAt: DateTime.now().toUtc(),
          clientMutationId: id,
        );
      }
      note(
        'đã lưu ${ids.length} mutation khi mất mạng (${sw.elapsedMilliseconds} ms)',
      );

      engine.start(online.stream);
      online.add(false);
      await Future<void>.delayed(
        const Duration(seconds: 4),
      ); // vài lượt backoff 1s, 2s
      final pending = await db.select(db.outboxMutations).get();
      note(
        'vẫn chờ: ${pending.length}, attemptCount=${pending.first.attemptCount}, '
        'lastError=${pending.first.lastError}',
      );
      expect(pending, hasLength(ids.length));
      expect(pending.first.attemptCount, greaterThanOrEqualTo(2));

      await endpoint.start(port);
      endpoint.dropNextResponse =
          true; // lô đầu áp dụng xong nhưng mất phản hồi
      online.add(true);
      note('bật mạng');

      final deadline = DateTime.now().add(const Duration(seconds: 30));
      while ((await db.select(db.outboxMutations).get()).isNotEmpty) {
        if (DateTime.now().isAfter(deadline)) fail('outbox không về 0');
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      note(
        'outbox trống sau ${endpoint.requests} request; '
        'server áp dụng ${endpoint.applied.length} mutation',
      );

      note('duplicate (gửi lại lô mất phản hồi): ${endpoint.duplicates}');
      expect(endpoint.applied, unorderedEquals(ids));
      // Lô 10 mutation mất phản hồi được gửi lại và nhận `duplicate`, không áp dụng lần 2.
      expect(endpoint.duplicates, 10);
    } finally {
      await engine.stop();
      await online.close();
      client.close(force: true);
      await endpoint.stop();
      await db.close();
      await deleteTeacherDatabase(
        store,
        await getApplicationDocumentsDirectory(),
      );
    }
  });
}
