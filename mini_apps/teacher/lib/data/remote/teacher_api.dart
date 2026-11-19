import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../sync/sync_engine.dart';

/// Buổi học từ `GET /sessions`.
typedef SessionDto = ({
  String id,
  String classId,
  String className,
  String sessionDate,
  DateTime startsAt,
  DateTime endsAt,
  String status,
  bool isMakeup,
  int? tzOffsetMinutes,
});

typedef AttendanceItemDto = ({
  String studentId,
  String fullName,
  String? status,
  String? note,
  DateTime? clientUpdatedAt,
});

typedef HistorySnapshotDto = ({String status, String? note});

typedef HistoryItemDto = ({
  String id,
  String studentName,
  String? changedByName,
  DateTime changedAt,
  HistorySnapshotDto? before,
  HistorySnapshotDto? after,
});

typedef HistoryPageDto = ({List<HistoryItemDto> items, String? nextCursor});

/// `GET /sessions/{id}/attendance`.
typedef AttendanceDto = ({
  String sessionId,
  String sessionStatus,
  bool canEdit,
  DateTime editableUntil,
  DateTime serverTime,
  List<AttendanceItemDto> items,
});

/// Các endpoint teacher dùng ngoại tuyến, trên `Dio` của host
/// (`TeachHubDiKey.api`, baseUrl `<base>/v1`). Lỗi luôn ra [ApiException]:
/// mất mạng là [ApiException.network].
class TeacherApi {
  TeacherApi(this._dio, {required this.deviceId});

  final Dio _dio;
  final String deviceId;

  Future<List<SessionDto>> sessions(String from, String to) => _call(() async {
    final res = await _dio.get<Object?>(
      '/sessions',
      queryParameters: {'from': from, 'to': to},
    );
    return [
      for (final s in (_map(res.data)['items'] as List).cast<Map>())
        (
          id: s['id'] as String,
          classId: s['classId'] as String,
          className: s['className'] as String,
          sessionDate: s['sessionDate'] as String,
          startsAt: DateTime.parse(s['startsAt'] as String),
          endsAt: DateTime.parse(s['endsAt'] as String),
          status: s['status'] as String,
          isMakeup: s['isMakeup'] as bool,
          tzOffsetMinutes: offsetMinutes(s['startsAt'] as String),
        ),
    ];
  });

  Future<AttendanceDto> attendance(String sessionId) => _call(() async {
    final res = await _dio.get<Object?>('/sessions/$sessionId/attendance');
    final m = _map(res.data);
    return (
      sessionId: m['sessionId'] as String,
      sessionStatus: m['sessionStatus'] as String,
      canEdit: m['canEdit'] as bool,
      editableUntil: DateTime.parse(m['editableUntil'] as String),
      serverTime: DateTime.parse(m['serverTime'] as String),
      items: [
        for (final i in (m['items'] as List).cast<Map>())
          (
            studentId: i['studentId'] as String,
            fullName: i['fullName'] as String,
            status: i['status'] as String?,
            note: i['note'] as String?,
            clientUpdatedAt: _date(i['clientUpdatedAt']),
          ),
      ],
    );
  });

  /// [SyncTransport] thật: `POST /attendance/sync`, một buổi một lô.
  Future<SyncResponse> sync(SyncRequest req) => _call(() async {
    final res = await _dio.post<Object?>(
      '/attendance/sync',
      options: Options(headers: {'Idempotency-Key': req.idempotencyKey}),
      data: {
        'deviceId': deviceId,
        'deviceTime': req.deviceTime.toUtc().toIso8601String(),
        'sessionId': req.sessionId,
        // Lưu điểm danh = buổi đã dạy; buổi đã dạy thì server bỏ qua cờ.
        'markSessionTaught': true,
        'mutations': [
          for (final m in req.mutations)
            {
              'clientMutationId': m.clientMutationId,
              'studentId': m.studentId!,
              ...(jsonDecode(m.payload) as Map<String, Object?>),
              'clientUpdatedAt': m.clientUpdatedAt.toUtc().toIso8601String(),
            },
        ],
      },
    );
    final body = _map(res.data);
    return SyncResponse(
      serverTime: DateTime.parse(body['serverTime'] as String),
      results: {
        for (final r in (body['results'] as List).cast<Map>())
          r['clientMutationId'] as String: MutationResult(
            SyncResult.values.byName(r['result'] as String),
            errorCode: r['errorCode'] as String?,
            current: switch (r['current']) {
              final Map c => AttendanceCurrent(
                status: c['status'] as String,
                note: c['note'] as String?,
                clientUpdatedAt: DateTime.parse(c['clientUpdatedAt'] as String),
              ),
              _ => null,
            },
          ),
      },
    );
  });

  /// Offset UTC (phút) ở cuối chuỗi ISO 8601 (`+07:00`, `Z`); null nếu không có.
  @visibleForTesting
  static int? offsetMinutes(String iso) {
    if (iso.endsWith('Z')) return 0;
    final m = RegExp(r'([+-])(\d\d):?(\d\d)$').firstMatch(iso);
    if (m == null) return null;
    final v = int.parse(m[2]!) * 60 + int.parse(m[3]!);
    return m[1] == '-' ? -v : v;
  }

  /// `GET /sessions/{id}/attendance/history`, mới nhất trước.
  Future<HistoryPageDto> history(String sessionId, {String? cursor}) =>
      _call(() async {
        final res = await _dio.get<Object?>(
          '/sessions/$sessionId/attendance/history',
          queryParameters: {'cursor': ?cursor, 'limit': 20},
        );
        final m = _map(res.data);
        return (
          items: [
            for (final i in (m['items'] as List).cast<Map>())
              (
                id: i['id'] as String,
                studentName: i['studentName'] as String,
                changedByName: i['changedByName'] as String?,
                changedAt: DateTime.parse(i['changedAt'] as String),
                before: _snapshot(i['before']),
                after: _snapshot(i['after']),
              ),
          ],
          nextCursor: m['nextCursor'] as String?,
        );
      });

  static HistorySnapshotDto? _snapshot(Object? v) => v is Map
      ? (status: v['status'] as String, note: v['note'] as String?)
      : null;

  static DateTime? _date(Object? v) => v == null ? null : DateTime.parse('$v');

  static Map _map(Object? data) =>
      data is Map ? data : throw const FormatException();

  Future<T> _call<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw ApiException.fromDio(e)!;
    } on FormatException {
      throw const ApiException.unexpected();
    } on TypeError {
      // Ép kiểu trong lúc đọc JSON sai hợp đồng (thiếu trường, sai kiểu).
      throw const ApiException.unexpected();
    }
  }
}
