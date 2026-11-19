import 'dart:async';
import 'dart:developer';
import 'dart:math' hide log;

import 'package:drift/drift.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../local_db/teacher_database.dart';
import 'clock_skew.dart';
import 'uuid.dart';

/// Kết quả từng mutation do `POST /attendance/sync` trả về (spec §5, M3).
enum SyncResult { applied, duplicate, stale, rejected }

/// Bản đang lưu trên server khi `stale`/`duplicate` (`current` trong hợp đồng).
class AttendanceCurrent {
  const AttendanceCurrent({
    required this.status,
    required this.note,
    required this.clientUpdatedAt,
  });
  final String status;
  final String? note;
  final DateTime clientUpdatedAt;
}

class MutationResult {
  const MutationResult(this.result, {this.errorCode, this.current});
  final SyncResult result;
  final String? errorCode;
  final AttendanceCurrent? current;
}

/// Một lô gửi lên server: một buổi, ≤500 mutation, kèm khóa và giờ máy cố định
/// theo lô (gửi lại cùng lô thì cùng khóa, cùng thân).
class SyncRequest {
  const SyncRequest({
    required this.sessionId,
    required this.idempotencyKey,
    required this.deviceTime,
    required this.mutations,
  });
  final String sessionId;
  final String idempotencyKey;
  final DateTime deviceTime;
  final List<OutboxMutation> mutations;
}

class SyncResponse {
  const SyncResponse({required this.serverTime, required this.results});
  final DateTime serverTime;

  /// Theo `clientMutationId`.
  final Map<String, MutationResult> results;
}

/// Gửi một lô lên API. Lỗi gửi phải ném [ApiException] (mất mạng =
/// [ApiException.network]) để engine phân loại.
typedef SyncTransport = Future<SyncResponse> Function(SyncRequest request);

/// [sent]: số mutation đã rời outbox (applied/duplicate/stale); [rejected]: bị
/// từ chối, giữ lại để hiện banner; [failed]: mutation của lô lỗi cả lô, giữ
/// lại; [retryIn]: còn việc, thử lại sau.
typedef SyncReport = ({int sent, int rejected, int failed, Duration? retryIn});

enum SyncEventKind {
  /// Server có bản mới hơn: bản cục bộ đã bị ghi đè.
  stale,

  /// Server từ chối mutation (kèm `errorCode`).
  rejected,

  /// Cả lô lỗi (buổi không có / đã hủy): người dùng phải xem lại.
  batchFailed,
}

/// Sự kiện cho banner. Chỉ mang id và mã lỗi, không có tên học viên hay ghi chú.
class SyncEvent {
  const SyncEvent(
    this.kind, {
    required this.sessionId,
    this.studentId,
    this.errorCode,
  });
  final SyncEventKind kind;
  final String sessionId;
  final String? studentId;
  final String? errorCode;
}

/// Mutation engine có thể gửi: đang chờ và đủ buổi + học viên.
Expression<bool> _sendable($OutboxMutationsTable r) =>
    outboxPending(r) & r.sessionId.isNotNull() & r.studentId.isNotNull();

/// Đẩy `outbox_mutations` lên server, mỗi lô một buổi, đúng thứ tự tạo
/// (spec §6.4).
///
/// Đúng một lần nhờ `clientMutationId`: server trả `duplicate` cho mutation đã
/// nhận, nên gửi lại sau khi mất phản hồi là an toàn. `Idempotency-Key` và
/// `deviceTime` của lô được lưu vào outbox ngay khi gom lô, nên gửi lại (kể cả
/// sau khi app bị kill) là đúng cùng một request.
class SyncEngine {
  SyncEngine(
    this._db,
    this._send, {
    this.batchSize = 500,
    ClockSkew? clock,
    Random? random,
    DateTime Function()? now,
    String Function()? newKey,
    this.sendTimeout = const Duration(seconds: 30),
  }) : assert(batchSize >= 1 && batchSize <= 500),
       clock = clock ?? ClockSkew(now: now),
       _random = random ?? Random(),
       _now = now ?? DateTime.now,
       _newKey = newKey ?? newUuid;

  final TeacherDatabase _db;
  final SyncTransport _send;
  final int batchSize;

  /// Quá hạn thì coi như mất mạng (thử lại cùng khóa).
  final Duration sendTimeout;

  /// Lệch đồng hồ đo từ `serverTime`; UI dùng `clock.now()` để gắn `clientUpdatedAt`.
  final ClockSkew clock;
  final Random _random;
  final DateTime Function() _now;
  final String Function() _newKey;

  /// Trần của [backoff].
  static const maxBackoff = Duration(hours: 1);

  final _events = StreamController<SyncEvent>.broadcast();
  Future<SyncReport>? _running;
  StreamSubscription<bool>? _online;
  Timer? _retry;
  bool _paused = false;
  Completer<void> _abort = Completer();
  int _crashes = 0;

  /// Banner "stale"/"rejected"/"lô lỗi".
  Stream<SyncEvent> get events => _events.stream;

  /// Số mutation đang chờ gửi (chip "Chờ đồng bộ"); không tính dòng bị từ chối.
  Stream<int> watchPending() =>
      _db.outboxMutations.count(where: outboxPending).watchSingle();

  /// Giãn thử lại 1s, 2s, 4s… tối đa [maxBackoff] theo số lần thất bại, rồi
  /// giảm ngẫu nhiên tới một nửa để nhiều máy không dồn vào cùng lúc.
  Duration backoff(int attempts) {
    final base = min(1 << min(attempts - 1, 12), maxBackoff.inSeconds);
    return Duration(
      milliseconds: (base * 1000 * (0.5 + _random.nextDouble() / 2)).round(),
    );
  }

  /// Gộp các lần gọi chồng nhau thành một lượt; lượt chạy tới khi outbox hết
  /// mutation gửi được hoặc gặp lỗi. Đang [stop] thì không làm gì.
  Future<SyncReport> drain() =>
      _running ??= _drain().whenComplete(() => _running = null);

  /// Đẩy ngay khi có mạng trở lại và tự thử lại theo [backoff].
  void start(Stream<bool> online) {
    _paused = false;
    if (_abort.isCompleted) _abort = Completer();
    _online ??= online.where((up) => up).listen((_) => _drainAndSchedule());
    _drainAndSchedule();
  }

  /// Dừng hẳn và chờ lượt đang chạy xong: gọi trước khi đóng/xóa CSDL.
  Future<void> stop() async {
    _paused = true;
    if (!_abort.isCompleted) _abort.complete(); // bỏ chờ lượt gửi đang bay
    _retry?.cancel();
    await _online?.cancel();
    _online = null;
    await _running;
  }

  /// Dừng hẳn và đóng các stream; engine không dùng lại được.
  Future<void> dispose() async {
    await stop();
    await _events.close();
  }

  Future<void> _drainAndSchedule() async {
    _retry?.cancel();
    Duration? wait;
    try {
      wait = (await drain()).retryIn;
      _crashes = 0;
    } catch (e) {
      // Lỗi ngoài dự kiến (vd. CSDL): chỉ ghi loại lỗi, không ghi nội dung.
      log('SyncEngine lỗi nội bộ: ${e.runtimeType}', name: 'teacher');
      wait = backoff(++_crashes);
    }
    if (wait != null && _online != null && !_paused) {
      _retry = Timer(wait, _drainAndSchedule);
    }
  }

  Future<SyncReport> _drain() async {
    final t = _db.outboxMutations;
    var sent = 0, rejected = 0, failed = 0;
    SyncReport report(Duration? retryIn) =>
        (sent: sent, rejected: rejected, failed: failed, retryIn: retryIn);

    // Buổi bỏ qua trong lượt này (lỗi không tự hết) để không chặn buổi khác.
    final skip = <String>{};
    // Buổi đã reset khóa vì 422 IDEMPOTENCY_KEY_REUSED (chỉ một lần).
    final keyReset = <String>{};

    while (!_paused) {
      final batch = await _nextBatch(skip);
      if (batch == null) return report(null);
      final sessionId = batch.first.sessionId!;

      final sentAt = _now();
      final SyncResponse? response;
      try {
        response = await Future.any<SyncResponse?>([
          _send(
            SyncRequest(
              sessionId: sessionId,
              idempotencyKey: batch.first.batchKey!,
              deviceTime: batch.first.batchDeviceTime!,
              mutations: batch,
            ),
          ).timeout(
            sendTimeout,
            onTimeout: () => throw const ApiException.network(),
          ),
          _abort.future.then((_) => null),
        ]);
      } on ApiException catch (e) {
        final code = e.wireCode ?? e.kind.name;
        if (e.code == ApiErrorCode.idempotencyKeyReused &&
            keyReset.add(sessionId)) {
          // Thân lô khác bản đã gửi với khóa này: gom lại với khóa mới.
          await _resetBatch(batch);
          continue;
        }
        // Thử lại vẫn y vậy: buổi không có (404), đã hủy (409), dữ liệu sai
        // (422), hoặc khóa vẫn bị dùng lại sau khi đã reset.
        if (e.status == 404 ||
            (e.status == 409 && !e.retryable) ||
            e.status == 422) {
          await _setError(batch, '$batchFailedPrefix$code');
          failed += batch.length;
          _events.add(
            SyncEvent(
              SyncEventKind.batchFailed,
              sessionId: sessionId,
              errorCode: code,
            ),
          );
          continue;
        }
        final attempts = await _markFailed(batch, code);
        if (e.retryable) {
          return report(e.retryAfter ?? backoff(attempts));
        }
        // Lỗi không tự hết (403…): bỏ qua buổi này, chờ lần kích hoạt sau.
        skip.add(sessionId);
        continue;
      }
      if (response == null) return report(null); // bị stop() giữa chừng
      final results = response.results;
      clock.observe(response.serverTime, sentAt: sentAt, receivedAt: _now());

      final missing = <OutboxMutation>[];
      final events = <SyncEvent>[];
      await _db.transaction(() async {
        for (final row in batch) {
          final r = results[row.clientMutationId];
          switch (r?.result) {
            case null:
              missing.add(row);
            case SyncResult.rejected:
              rejected++;
              await _setError([
                row,
              ], '$rejectedPrefix${r!.errorCode ?? 'UNKNOWN'}');
              events.add(
                SyncEvent(
                  SyncEventKind.rejected,
                  sessionId: sessionId,
                  studentId: row.studentId,
                  errorCode: r.errorCode,
                ),
              );
            case SyncResult.applied || SyncResult.duplicate:
              sent++;
              await (_db.delete(t)..where((x) => x.id.equals(row.id))).go();
            case SyncResult.stale:
              sent++;
              await (_db.delete(t)..where((x) => x.id.equals(row.id))).go();
              await _adoptServerCopy(row, r!.current);
              events.add(
                SyncEvent(
                  SyncEventKind.stale,
                  sessionId: sessionId,
                  studentId: row.studentId,
                ),
              );
          }
        }
        // Lô gửi lại chỉ còn các dòng thiếu: thân khác thì khóa phải khác.
        if (missing.isNotEmpty) {
          await (_db.update(
            t,
          )..where((x) => x.id.isIn(missing.map((m) => m.id)))).write(
            const OutboxMutationsCompanion(
              batchKey: Value(null),
              batchDeviceTime: Value(null),
            ),
          );
        }
      });
      events.forEach(_events.add);
      // Server bỏ sót mutation: không lặp vô hạn, thử lại sau.
      if (missing.isNotEmpty) {
        final attempts = await _markFailed(missing, 'MISSING_RESULT');
        return report(backoff(attempts));
      }
    }
    return report(null);
  }

  /// Gỡ khóa và giờ máy của lô để lần sau gom lại với khóa mới.
  Future<void> _resetBatch(List<OutboxMutation> rows) =>
      (_db.update(
        _db.outboxMutations,
      )..where((x) => x.id.isIn(rows.map((m) => m.id)))).write(
        const OutboxMutationsCompanion(
          batchKey: Value(null),
          batchDeviceTime: Value(null),
        ),
      );

  /// Lô kế tiếp: buổi của mutation chờ gửi cũ nhất. Lô đã gom từ trước (còn
  /// `batchKey`) được gửi lại nguyên vẹn; chưa có thì gom tối đa [batchSize]
  /// dòng và lưu khóa + giờ máy vào chính các dòng đó.
  Future<List<OutboxMutation>?> _nextBatch(Set<String> skip) async {
    final t = _db.outboxMutations;
    final first =
        await (_db.select(t)
              ..where((r) => _sendable(r) & r.sessionId.isNotIn(skip))
              ..orderBy([(r) => OrderingTerm(expression: r.id)])
              ..limit(1))
            .getSingleOrNull();
    if (first == null) return null;

    final key = first.batchKey;
    Future<List<OutboxMutation>> rowsOf(
      Expression<bool> Function($OutboxMutationsTable) extra, {
      int? limit,
    }) =>
        (_db.select(t)
              ..where(
                (r) =>
                    _sendable(r) &
                    r.sessionId.equals(first.sessionId!) &
                    extra(r),
              )
              ..orderBy([(r) => OrderingTerm(expression: r.id)])
              ..limit(limit ?? 1 << 30))
            .get();
    if (key != null) return rowsOf((r) => r.batchKey.equals(key));

    final rows = await rowsOf((r) => r.batchKey.isNull(), limit: batchSize);
    await (_db.update(t)..where((r) => r.id.isIn(rows.map((r) => r.id)))).write(
      OutboxMutationsCompanion(
        batchKey: Value(_newKey()),
        batchDeviceTime: Value(_now().toUtc()),
      ),
    );
    // Đọc lại để `batchDeviceTime` đúng giá trị DB lưu (làm tròn giây) — đúng
    // thứ sẽ có sau khi app khởi động lại.
    return (_db.select(t)
          ..where((r) => r.id.isIn(rows.map((r) => r.id)))
          ..orderBy([(r) => OrderingTerm(expression: r.id)]))
        .get();
  }

  /// Ghi đè bản cục bộ bằng bản của server, trừ khi người dùng đã sửa tiếp
  /// (còn mutation khác của học viên đó trong outbox: bản đó sẽ được gửi sau).
  Future<void> _adoptServerCopy(
    OutboxMutation row,
    AttendanceCurrent? c,
  ) async {
    if (c == null) return;
    final o = _db.outboxMutations;
    final newer =
        await (_db.select(o)
              ..where(
                (r) =>
                    outboxPending(r) &
                    r.sessionId.equals(row.sessionId!) &
                    r.studentId.equals(row.studentId!),
              )
              ..limit(1))
            .get();
    if (newer.isNotEmpty) return;
    final a = _db.cachedAttendances;
    await (_db.update(a)..where(
          (r) =>
              r.sessionId.equals(row.sessionId!) &
              r.studentId.equals(row.studentId!),
        ))
        .write(
          CachedAttendancesCompanion(
            status: Value(c.status),
            note: Value(c.note),
            clientUpdatedAt: Value(c.clientUpdatedAt),
          ),
        );
  }

  Future<void> _setError(List<OutboxMutation> rows, String error) =>
      (_db.update(_db.outboxMutations)
            ..where((r) => r.id.isIn(rows.map((r) => r.id))))
          .write(OutboxMutationsCompanion(lastError: Value(error)));

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
