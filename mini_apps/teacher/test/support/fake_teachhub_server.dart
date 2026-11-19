import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Máy chủ TeachHub giả cho test: cắm vào `Dio.httpClientAdapter`, không mạng
/// thật. Mô phỏng phần liên quan tới đồng bộ của hợp đồng Sprint 3:
/// `Idempotency-Key` (phát lại phản hồi cũ, 422 nếu thân khác), dedupe theo
/// `clientMutationId`, LWW theo `clientUpdatedAt` (bằng nhau → stale).
class FakeTeachHubServer implements HttpClientAdapter {
  /// Giờ server trả ở `serverTime`.
  DateTime serverTime = DateTime.utc(2026, 11, 18, 10);

  /// Không có phản hồi (mất mạng) cho tới khi tắt cờ.
  bool offline = false;

  /// Áp dụng xong nhưng phản hồi mất trên đường về — một lần.
  bool dropNextResponse = false;

  /// Trả lỗi này cho cả lô của buổi tương ứng (status, code).
  final failSession = <String, (int, String)>{};

  /// Trả lỗi 5xx cho request kế tiếp, từng lần một.
  int serverErrors = 0;

  /// `clientMutationId` → `errorCode`: bị từ chối.
  final rejectIds = <String, String>{};

  /// `clientMutationId` mà phản hồi cố tình không nhắc tới.
  final skipIds = <String>{};

  /// Dữ liệu GET.
  List<Map<String, Object?>> sessions = [];
  final attendance = <String, Map<String, Object?>>{};

  /// Mọi request POST tới `/attendance/sync`, đúng thứ tự.
  final syncRequests = <({String key, Map<String, Object?> body})>[];

  /// Số lần mỗi `clientMutationId` được áp dụng (phải ≤ 1).
  final appliedCount = <String, int>{};

  final _byKey = <String, ({String body, Map<String, Object?> response})>{};
  final _seen = <String, Map<String, Object?>>{};
  final _current = <(String, String), Map<String, Object?>>{};

  /// Server có sẵn bản điểm danh này (để tạo xung đột).
  void seedCurrent(
    String sessionId,
    String studentId, {
    required String status,
    String? note,
    required DateTime clientUpdatedAt,
  }) => _current[(sessionId, studentId)] = {
    'status': status,
    'note': note,
    'clientUpdatedAt': clientUpdatedAt.toUtc().toIso8601String(),
    'recordedByName': 'Cô Lan',
  };

  Dio dio() =>
      Dio(BaseOptions(baseUrl: 'https://api.test/v1'))
        ..httpClientAdapter = this;

  ResponseBody _json(int status, Object body) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  ResponseBody _error(int status, String code) =>
      _json(status, {'code': code, 'message': 'x', 'requestId': 'r'});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (offline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    if (options.method == 'GET' && options.path == '/sessions') {
      return _json(200, {'items': sessions});
    }
    final get = RegExp(
      r'^/sessions/([^/]+)/attendance$',
    ).firstMatch(options.path);
    if (options.method == 'GET' && get != null) {
      final data = attendance[get.group(1)];
      return data == null ? _error(404, 'NOT_FOUND') : _json(200, data);
    }
    if (options.method == 'POST' && options.path == '/attendance/sync') {
      return _sync(options);
    }
    return _error(404, 'NOT_FOUND');
  }

  ResponseBody _sync(RequestOptions options) {
    final key = options.headers['Idempotency-Key'] as String?;
    if (key == null) return _error(422, 'VALIDATION_FAILED');
    final raw = jsonEncode(options.data);
    final body = (jsonDecode(raw) as Map).cast<String, Object?>();
    syncRequests.add((key: key, body: body));

    if (serverErrors > 0) {
      serverErrors--;
      return _error(503, 'INTERNAL');
    }
    final stored = _byKey[key];
    if (stored != null) {
      if (stored.body != raw) return _error(422, 'IDEMPOTENCY_KEY_REUSED');
      return _json(200, stored.response);
    }
    final sessionId = body['sessionId'] as String;
    if (failSession[sessionId] case (final status, final code)) {
      return _error(status, code);
    }

    final results = <Map<String, Object?>>[];
    for (final m in (body['mutations'] as List).cast<Map<String, Object?>>()) {
      final id = m['clientMutationId'] as String;
      final student = m['studentId'] as String;
      final at = DateTime.parse(m['clientUpdatedAt'] as String);
      if (skipIds.contains(id)) continue;
      Map<String, Object?> r(String result, {String? code, Object? current}) =>
          {
            'clientMutationId': id,
            'studentId': student,
            'result': result,
            'errorCode': ?code,
            'current': ?current,
          };
      if (rejectIds[id] case final code?) {
        results.add(r('rejected', code: code));
      } else if (_seen[id] case final cur?) {
        results.add(r('duplicate', current: cur));
      } else if (_current[(sessionId, student)] case final cur?
          when !at.isAfter(DateTime.parse(cur['clientUpdatedAt'] as String))) {
        results.add(r('stale', current: cur));
      } else {
        appliedCount.update(id, (n) => n + 1, ifAbsent: () => 1);
        seedCurrent(
          sessionId,
          student,
          status: m['status'] as String,
          note: m['note'] as String?,
          clientUpdatedAt: at,
        );
        _seen[id] = _current[(sessionId, student)]!;
        results.add(r('applied'));
      }
    }
    final response = <String, Object?>{
      'sessionId': sessionId,
      'sessionStatus': 'taught',
      'serverTime': serverTime.toIso8601String(),
      'results': results,
      'summary': {'present': 0, 'late': 0, 'excused': 0, 'unexcused': 0},
      'parentsToNotify': 0,
    };
    _byKey[key] = (body: raw, response: response);
    if (dropNextResponse) {
      dropNextResponse = false;
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'response lost',
      );
    }
    return _json(200, response);
  }

  @override
  void close({bool force = false}) {}
}
