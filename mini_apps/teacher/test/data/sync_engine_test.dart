import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/data/local_db/teacher_database.dart';
import 'package:teacher/data/sync/sync_engine.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

/// Server giả của `POST /attendance/sync`: nhớ `clientMutationId` đã nhận.
class FakeSyncServer {
  final seen = <String>{};
  final applied = <String>[];
  final batches = <List<String>>[];
  bool offline = false;

  /// Áp dụng xong nhưng phản hồi mất trên đường về (lần gửi kế tiếp).
  bool dropNextResponse = false;
  final rejectIds = <String, String>{};
  final skipIds = <String>{};

  Future<Map<String, MutationResult>> send(List<OutboxMutation> batch) async {
    if (offline) throw const ApiException.network();
    batches.add([for (final m in batch) m.clientMutationId]);
    final out = <String, MutationResult>{};
    for (final m in batch) {
      final id = m.clientMutationId;
      if (skipIds.contains(id)) continue;
      if (rejectIds[id] case final code?) {
        out[id] = (result: SyncResult.rejected, errorCode: code);
      } else if (seen.add(id)) {
        applied.add(id);
        out[id] = (result: SyncResult.applied, errorCode: null);
      } else {
        out[id] = (result: SyncResult.duplicate, errorCode: null);
      }
    }
    if (dropNextResponse) {
      dropNextResponse = false;
      throw const ApiException.network();
    }
    return out;
  }
}

void main() {
  late TeacherDatabase db;
  late FakeSyncServer server;
  late SyncEngine engine;

  setUp(() {
    db = TeacherDatabase(NativeDatabase.memory());
    server = FakeSyncServer();
    engine = SyncEngine(db, server.send, batchSize: 2);
  });
  tearDown(() async {
    await engine.stop();
    await db.close();
  });

  Future<void> save(List<String> ids) => db.batch(
    (b) => b.insertAll(db.outboxMutations, [
      for (final id in ids)
        OutboxMutationsCompanion.insert(
          clientMutationId: id,
          entity: 'attendance',
          payload: '{}',
          clientUpdatedAt: DateTime.utc(2026, 11, 18),
        ),
    ]),
  );
  Future<List<OutboxMutation>> outbox() => db.select(db.outboxMutations).get();

  test(
    'pushes in creation order, in batches, and empties the outbox',
    () async {
      await save(['m1', 'm2', 'm3']);
      final report = await engine.drain();
      expect(report, (sent: 3, rejected: 0, retryIn: null));
      expect(server.batches, [
        ['m1', 'm2'],
        ['m3'],
      ]);
      expect(await outbox(), isEmpty);
    },
  );

  test('offline → save → online pushes each mutation exactly once', () async {
    server.offline = true;
    await save(['m1', 'm2']);
    var report = await engine.drain();
    expect(report.retryIn, const Duration(seconds: 1));
    report = await engine.drain();
    expect(report.retryIn, const Duration(seconds: 2));
    expect((await outbox()).map((r) => (r.attemptCount, r.lastError)), [
      (2, 'network'),
      (2, 'network'),
    ]);

    server.offline = false;
    expect(await engine.drain(), (sent: 2, rejected: 0, retryIn: null));
    expect(server.applied, ['m1', 'm2']);
    expect(await outbox(), isEmpty);
  });

  test(
    'a lost response is resent and counted as duplicate, not applied twice',
    () async {
      await save(['m1']);
      server.dropNextResponse = true;
      expect((await engine.drain()).retryIn, isNotNull);
      expect(await outbox(), hasLength(1));

      expect(await engine.drain(), (sent: 1, rejected: 0, retryIn: null));
      expect(server.applied, ['m1']);
      expect(server.batches, [
        ['m1'],
        ['m1'],
      ]);
    },
  );

  test('rejected mutations stay with their code and are not resent', () async {
    server.rejectIds['m1'] = 'ATTENDANCE_EDIT_WINDOW_CLOSED';
    await save(['m1', 'm2']);
    expect(await engine.drain(), (sent: 1, rejected: 1, retryIn: null));
    final left = await outbox();
    expect(left.single.lastError, 'rejected:ATTENDANCE_EDIT_WINDOW_CLOSED');

    await engine.drain();
    expect(server.batches, hasLength(1));
  });

  test(
    'a result missing from the response is retried later, not looped',
    () async {
      server.skipIds.add('m2');
      await save(['m1', 'm2']);
      final report = await engine.drain();
      expect(report.sent, 1);
      expect(report.retryIn, const Duration(seconds: 1));
      expect((await outbox()).single.lastError, 'MISSING_RESULT');
    },
  );

  test('a non-retryable error stops without a retry timer', () async {
    final forbidden = SyncEngine(db, (_) async {
      throw ApiException.fromResponse(403, {'code': 'FORBIDDEN'});
    });
    await save(['m1']);
    expect(await forbidden.drain(), (sent: 0, rejected: 0, retryIn: null));
    expect((await outbox()).single.lastError, 'FORBIDDEN');
  });

  test('overlapping drains share one run', () async {
    await save(['m1']);
    final a = engine.drain(), b = engine.drain();
    expect(identical(a, b), isTrue);
    await a;
    expect(server.batches, hasLength(1));
  });

  test('backoff doubles and caps at one hour', () {
    expect(SyncEngine.backoff(1), const Duration(seconds: 1));
    expect(SyncEngine.backoff(3), const Duration(seconds: 4));
    expect(SyncEngine.backoff(50), const Duration(hours: 1));
  });

  test('start() pushes again when connectivity comes back', () async {
    final online = StreamController<bool>();
    server.offline = true;
    await save(['m1']);
    engine.start(online.stream);
    await pumpEventQueue();
    expect(server.applied, isEmpty);

    server.offline = false;
    online.add(true);
    await pumpEventQueue();
    expect(server.applied, ['m1']);
    expect(await outbox(), isEmpty);
    await online.close();
  });
}
