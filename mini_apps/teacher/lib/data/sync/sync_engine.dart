import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../local_db/teacher_database.dart';

/// Kết quả từng mutation do `POST /attendance/sync` trả về (spec §5, M3).
enum SyncResult { applied, duplicate, stale, rejected }

typedef MutationResult = ({SyncResult result, String? errorCode});

/// Gửi một lô lên API, trả kết quả theo `clientMutationId`. Lỗi gửi phải ném
/// [ApiException] (mất mạng = [ApiException.network]) để engine phân loại.
typedef SyncTransport =
    Future<Map<String, MutationResult>> Function(List<OutboxMutation> batch);

/// [sent]: số mutation đã rời outbox (applied/duplicate/stale); [rejected]:
/// bị từ chối, giữ lại để hiện banner; [retryIn]: còn việc, thử lại sau.
typedef SyncReport = ({int sent, int rejected, Duration? retryIn});

/// Prefix của `lastError` cho mutation bị từ chối: không gửi lại nữa.
const rejectedPrefix = 'rejected:';

/// Đẩy `outbox_mutations` lên server theo lô, đúng thứ tự tạo (spec §6.4).
///
/// Đúng một lần nhờ `clientMutationId`: server trả `duplicate` cho mutation đã
/// nhận, nên gửi lại sau khi mất phản hồi là an toàn. Bản thử S0-FL-08 —
/// S3-FL-08 nối transport thật (Dio) và xử lý `stale` bằng bản của server.
class SyncEngine {
  SyncEngine(this._db, this._send, {this.batchSize = 100});

  final TeacherDatabase _db;
  final SyncTransport _send;
  final int batchSize;

  Future<SyncReport>? _running;
  StreamSubscription<bool>? _online;
  Timer? _retry;

  /// Giãn thử lại 1s, 2s, 4s… tối đa 1 giờ theo số lần thất bại.
  static Duration backoff(int attempts) =>
      Duration(seconds: min(1 << min(attempts - 1, 12), 3600));

  /// Gộp các lần gọi chồng nhau thành một lượt; lượt chạy tới khi outbox hết
  /// mutation gửi được hoặc gặp lỗi.
  Future<SyncReport> drain() =>
      _running ??= _drain().whenComplete(() => _running = null);

  /// Đẩy ngay khi có mạng trở lại và tự thử lại theo [backoff].
  void start(Stream<bool> online) {
    _online ??= online.where((up) => up).listen((_) => _drainAndSchedule());
    _drainAndSchedule();
  }

  Future<void> stop() async {
    _retry?.cancel();
    await _online?.cancel();
    _online = null;
  }

  Future<void> _drainAndSchedule() async {
    _retry?.cancel();
    final report = await drain();
    final wait = report.retryIn;
    if (wait != null && _online != null) {
      _retry = Timer(wait, _drainAndSchedule);
    }
  }

  Future<SyncReport> _drain() async {
    final t = _db.outboxMutations;
    var sent = 0, rejected = 0;
    while (true) {
      final batch =
          await (_db.select(t)
                ..where(
                  (r) =>
                      r.lastError.isNull() |
                      r.lastError.like('$rejectedPrefix%').not(),
                )
                ..orderBy([(r) => OrderingTerm(expression: r.id)])
                ..limit(batchSize))
              .get();
      if (batch.isEmpty) return (sent: sent, rejected: rejected, retryIn: null);

      final Map<String, MutationResult> results;
      try {
        results = await _send(batch);
      } on ApiException catch (e) {
        final attempts = await _markFailed(batch, e.wireCode ?? e.kind.name);
        // Lỗi không tự hết (403, 422…): dừng, chờ lần kích hoạt sau.
        final retryIn = e.retryable
            ? (e.retryAfter ?? backoff(attempts))
            : null;
        return (sent: sent, rejected: rejected, retryIn: retryIn);
      }

      final missing = <OutboxMutation>[];
      await _db.transaction(() async {
        for (final row in batch) {
          final r = results[row.clientMutationId];
          switch (r?.result) {
            case null:
              missing.add(row);
            case SyncResult.rejected:
              rejected++;
              await (_db.update(t)..where((x) => x.id.equals(row.id))).write(
                OutboxMutationsCompanion(
                  lastError: Value(
                    '$rejectedPrefix${r!.errorCode ?? 'UNKNOWN'}',
                  ),
                ),
              );
            case SyncResult.applied ||
                SyncResult.duplicate ||
                // shortcut: stale chỉ bỏ bản cục bộ; S3-FL-08 kéo bản của server về.
                SyncResult.stale:
              sent++;
              await (_db.delete(t)..where((x) => x.id.equals(row.id))).go();
          }
        }
      });
      // Server bỏ sót mutation: không lặp vô hạn, thử lại sau.
      if (missing.isNotEmpty) {
        final attempts = await _markFailed(missing, 'MISSING_RESULT');
        return (sent: sent, rejected: rejected, retryIn: backoff(attempts));
      }
    }
  }

  /// Tăng `attemptCount` của [rows], trả số lần thất bại lớn nhất.
  Future<int> _markFailed(List<OutboxMutation> rows, String error) async {
    final t = _db.outboxMutations;
    await (_db.update(t)..where((r) => r.id.isIn(rows.map((r) => r.id)))).write(
      OutboxMutationsCompanion.custom(
        attemptCount: t.attemptCount + const Constant(1),
        lastError: Variable(error),
      ),
    );
    return rows.map((r) => r.attemptCount).reduce(max) + 1;
  }
}
