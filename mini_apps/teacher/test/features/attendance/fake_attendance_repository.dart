import 'dart:async';

import 'package:teacher/features/attendance/data/attendance_models.dart';
import 'package:teacher/features/attendance/data/attendance_repository.dart';

/// Repository giả: giữ danh sách/buổi trong bộ nhớ, đẩy ra qua stream.
class FakeAttendanceRepository implements AttendanceRepository {
  FakeAttendanceRepository({
    List<TodaySession> sessions = const [],
    this.sheet,
    DateTime? now,
  }) : _sessions = sessions,
       _now = now ?? DateTime.utc(2026, 11, 18, 10);

  List<TodaySession> _sessions;
  SessionSheet? sheet;
  final DateTime _now;

  final _sessionsOut = StreamController<List<TodaySession>>.broadcast();
  final _sheetOut = StreamController<SessionSheet?>.broadcast();
  final _pendingOut = StreamController<int>.broadcast();

  int startSyncCalls = 0;
  int refreshTodayCalls = 0;
  int refreshSheetCalls = 0;
  final saves = <({String sessionId, List<AttendanceEntry> entries})>[];
  final discards = <String>[];

  /// Ném khi gọi refresh (đặt `ApiException.network()` để giả mất mạng).
  Object? refreshError;

  /// Chờ [saveGate] trước khi trả (để test emit sau close).
  Completer<void>? saveGate;
  Object? saveError;
  Object? discardError;

  /// Ném từ các stream (giả CSDL đóng).
  Object? streamError;

  int pending = 0;
  final histories = <HistoryChunk>[];
  int historyCalls = 0;
  Object? historyError;

  void setSessions(List<TodaySession> v) {
    _sessions = v;
    _sessionsOut.add(v);
  }

  void setSheet(SessionSheet v) {
    sheet = v;
    _sheetOut.add(v);
  }

  void setPending(int n) {
    pending = n;
    _pendingOut.add(n);
  }

  @override
  Future<void> startSync() async => startSyncCalls++;

  /// Mỗi lần đọc giờ server, giờ nhích thêm khoảng này (giả thời gian trôi).
  Duration advanceOnRead = Duration.zero;
  late DateTime _clock = _now;

  @override
  DateTime serverNow() {
    final v = _clock;
    _clock = _clock.add(advanceOnRead);
    return v;
  }

  @override
  Stream<int> watchPending() async* {
    if (streamError != null) throw streamError!;
    yield pending;
    yield* _pendingOut.stream;
  }

  @override
  Stream<List<TodaySession>> watchSessions(String date) async* {
    if (streamError != null) throw streamError!;
    yield _sessions;
    yield* _sessionsOut.stream;
  }

  @override
  Future<void> refreshToday(String date) async {
    refreshTodayCalls++;
    if (refreshError != null) throw refreshError!;
  }

  @override
  Stream<SessionSheet?> watchSheet(String sessionId) async* {
    if (streamError != null) throw streamError!;
    yield sheet;
    yield* _sheetOut.stream;
  }

  @override
  Future<void> refreshSheet(String sessionId) async {
    refreshSheetCalls++;
    if (refreshError != null) throw refreshError!;
  }

  @override
  Future<void> save(String sessionId, List<AttendanceEntry> entries) async {
    await saveGate?.future;
    if (saveError != null) throw saveError!;
    saves.add((sessionId: sessionId, entries: entries));
  }

  @override
  Future<void> discardFailed(String sessionId) async {
    if (discardError != null) throw discardError!;
    discards.add(sessionId);
  }

  @override
  Future<HistoryChunk> history(String sessionId, {String? cursor}) async {
    historyCalls++;
    if (historyError != null) throw historyError!;
    final i = cursor == null ? 0 : int.parse(cursor);
    return histories[i];
  }
}

const sessionId = 'sess-1';

SheetStudent student(
  int n, {
  AttendanceStatus? status,
  String? note,
  String? rejected,
}) => SheetStudent(
  studentId: 'st-$n',
  fullName: 'Em $n',
  status: status,
  note: note,
  rejectedCode: rejected,
);

SessionSheet sheetOf(
  List<SheetStudent> students, {
  bool cancelled = false,
  bool? canEdit = true,
  DateTime? editableUntil,
  String? batchErrorCode,
}) => SessionSheet(
  sessionId: sessionId,
  className: 'Toán 6A',
  sessionDate: '2026-11-18',
  startTime: '08:00',
  cancelled: cancelled,
  canEdit: canEdit,
  editableUntil: editableUntil ?? DateTime.utc(2026, 11, 25, 16, 59, 59),
  students: students,
  batchErrorCode: batchErrorCode,
);
