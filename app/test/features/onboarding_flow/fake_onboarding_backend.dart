// S2-FL-06: backend giả có trạng thái cho luồng B (onboarding → tạo lớp → thêm
// học viên → đặt lịch). Cắm vào `Dio.httpClientAdapter`, không mạng thật. Mô
// phỏng `GET /onboarding`, `PATCH /onboarding/steps/{step}`, `/classes`,
// `/students`, `PUT /classes/{id}/schedule-rules` và `GET /sessions`; request và
// response được đối chiếu với `contracts/openapi.json`, lệch hợp đồng là đỏ ngay.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

const _contractPath = '../packages/teachhub_shared/contracts/openapi.json';

/// Hợp đồng đọc từ repo; `null` khi chạy trên máy thật (không có file) thì bỏ
/// qua bước đối chiếu, vẫn chạy được kịch bản.
final Map<String, dynamic>? _openapi = File(_contractPath).existsSync()
    ? jsonDecode(File(_contractPath).readAsStringSync()) as Map<String, dynamic>
    : null;

const _stepOrder = [
  'create_class',
  'add_students',
  'set_schedule',
  'payout_account',
  'compliance_checklist',
];

class FakeOnboardingBackend implements HttpClientAdapter {
  FakeOnboardingBackend({required this.now});

  /// Giờ của server giả, cố định để kịch bản không phụ thuộc ngày/giờ chạy.
  final DateTime now;

  static String uid(int n) =>
      '00000000-0000-4000-8000-${n.toString().padLeft(12, '0')}';

  static final classId = uid(11);
  static final studentId = uid(21);

  /// Mọi request đã nhận: `METHOD /path`, đúng thứ tự.
  final requests = <String>[];

  /// Trạng thái 5 bước của tenant mới (tất cả `pending`).
  final steps = {for (final s in _stepOrder) s: 'pending'};

  /// Lớp và học viên đã lưu trên server (`null`/rỗng = chưa có).
  Map<String, Object?>? savedClass;
  final savedStudents = <Map<String, Object?>>[];

  /// Học viên đã ghi danh vào lớp (id), và số lần `POST …/enrollments` nhận được.
  final enrolled = <String>[];
  int enrollCalls = 0;

  /// Số lần tới `POST …/enrollments` mất mạng trước khi ghi gì.
  int failEnrolls = 0;

  /// Số lần `POST /classes` và `POST /students` thật sự chạy.
  int classCreates = 0;
  int studentCreates = 0;

  /// Số lần tới `PATCH /onboarding/steps/{step}` mất mạng sau khi *không* ghi
  /// gì (ghi bước lỗi); đếm theo từng bước.
  final failStepPatches = <String, int>{};

  List<Map<String, Object?>> get rules =>
      ((savedClass?['scheduleRules'] as List?) ?? const [])
          .cast<Map<String, Object?>>();

  Dio dio() =>
      Dio(BaseOptions(baseUrl: 'https://api.test/v1'))
        ..httpClientAdapter = this;

  // ---- dựng dữ liệu -------------------------------------------------------

  static String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, Object?> _onboarding() {
    final current = _stepOrder.where((s) => steps[s] == 'pending').firstOrNull;
    return {
      'steps': [
        for (final s in _stepOrder) {'step': s, 'status': steps[s]},
      ],
      'currentStep': current,
    };
  }

  /// Ngày của buổi học: màn "Hôm nay" lấy ngày từ đồng hồ máy nên buổi được xếp
  /// vào đúng ngày app hỏi ở `GET /sessions?from=`.
  late String sessionDate = _isoDate(now);

  Map<String, Object?> _session() {
    final start = DateTime.parse('${sessionDate}T18:00:00+07:00').toUtc();
    return {
      'id': uid(10),
      'classId': classId,
      'className': savedClass!['name'],
      'sessionDate': sessionDate,
      'startsAt': start.toIso8601String(),
      'endsAt': start
          .add(const Duration(hours: 1, minutes: 30))
          .toIso8601String(),
      'status': 'planned',
      'isMakeup': false,
      'cancelReason': null,
      'makeupOf': null,
    };
  }

  Map<String, Object?> _err(String code) => {
    'code': code,
    'message': 'x',
    'requestId': 'r',
  };

  // ---- HTTP ---------------------------------------------------------------

  static ResponseBody _json(int status, Object body) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  static ResponseBody _error(int status, String code) =>
      _json(status, {'code': code, 'message': 'x', 'requestId': 'r'});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final method = options.method;
    final path = options.path;
    requests.add('$method $path');
    final op = _operation(method, path);
    if (op == null) return _error(404, 'NOT_FOUND');
    final body = options.data == null
        ? null
        : jsonDecode(jsonEncode(options.data));
    // Interceptor của host tự gắn khóa cho PATCH; POST và PUT phải truyền sẵn.
    if (const {'POST', 'PUT'}.contains(method) &&
        options.headers['Idempotency-Key'] is! String) {
      return _error(422, 'VALIDATION_FAILED');
    }
    final reqSchema = _requestSchema(op);
    if (reqSchema != null && !_valid(body, reqSchema)) {
      return _error(422, 'VALIDATION_FAILED');
    }
    if (method == 'GET' && path == '/sessions') {
      sessionDate = options.queryParameters['from'] as String? ?? sessionDate;
    }
    if (failEnrolls > 0 && path.endsWith('/enrollments')) {
      failEnrolls--;
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    final step = RegExp(
      r'^PATCH /onboarding/steps/(.+)$',
    ).firstMatch('$method $path');
    if (step != null && (failStepPatches[step.group(1)] ?? 0) > 0) {
      failStepPatches[step.group(1)!] = failStepPatches[step.group(1)]! - 1;
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    final (status, out) = _route(method, path, body);
    // Chạy trên máy thật không có file hợp đồng (`_openapi == null`): bỏ đối chiếu.
    if (status < 300 && _openapi != null) {
      _conform(out, _responseSchema(op, status), '$method $path');
    }
    return _json(status, out);
  }

  (int, Object) _route(String method, String path, Object? body) {
    final m = '$method $path';
    if (m == 'GET /onboarding') return (200, _onboarding());
    final step = RegExp(r'^PATCH /onboarding/steps/(.+)$').firstMatch(m);
    if (step != null) {
      final name = step.group(1)!;
      if (!steps.containsKey(name)) return (404, _err('NOT_FOUND'));
      final status = (body! as Map)['status'] as String;
      // Bước 1 không được bỏ qua (US-0.2 AC2).
      if (name == 'create_class' && status == 'skipped') {
        return (422, _err('VALIDATION_FAILED'));
      }
      steps[name] = status;
      return (200, _onboarding());
    }
    if (m == 'GET /classes') {
      final c = savedClass;
      return (
        200,
        {
          'items': [?c],
          'total': c == null ? 0 : 1,
          'page': 1,
          'pageSize': 20,
        },
      );
    }
    if (m == 'POST /classes') {
      classCreates++;
      final b = body! as Map;
      savedClass = {
        'id': classId,
        'name': b['name'],
        'subject': b['subject'],
        'grade': b['grade'],
        'mode': b['mode'],
        'location': b['location'],
        'capacity': b['capacity'],
        'startDate': b['startDate'],
        'endDate': b['endDate'],
        'status': 'active',
        'enrolledCount': 0,
        'feeType': null,
        'feeAmount': null,
        'feeRules': null,
        'scheduleRules': <Object?>[],
        'createdAt': now.toUtc().toIso8601String(),
      };
      return (201, {...savedClass!, 'warnings': <Object?>[]});
    }
    if (m == 'PATCH /classes/$classId' && savedClass != null) {
      savedClass = {
        ...savedClass!,
        for (final e in (body! as Map).entries)
          if (savedClass!.containsKey(e.key)) e.key as String: e.value,
      };
      return (200, savedClass!);
    }
    if (m == 'GET /classes/$classId' && savedClass != null) {
      return (200, savedClass!);
    }
    if (m == 'PUT /classes/$classId/schedule-rules' && savedClass != null) {
      final list = ((body! as Map)['rules'] as List).cast<Map>();
      final saved = [
        for (final (i, r) in list.indexed)
          <String, Object?>{...r, 'id': uid(100 + i)},
      ];
      savedClass = {...savedClass!, 'scheduleRules': saved};
      return (
        200,
        {
          'rules': saved,
          'sessionsGenerated': saved.length * 8,
          'sessionsRemoved': 0,
        },
      );
    }
    if (m == 'POST /students') {
      studentCreates++;
      final b = body! as Map;
      final s = {
        'id': studentId,
        'fullName': b['fullName'],
        'dob': b['dob'],
        'school': b['school'],
        'schoolClass': b['schoolClass'],
        'note': b['note'],
        'status': 'active',
        'guardians': <Object?>[],
      };
      savedStudents.add(s);
      return (201, s);
    }
    if (m == 'POST /classes/$classId/enrollments' && savedClass != null) {
      enrollCalls++;
      final id = (body! as Map)['studentId'] as String;
      final again = enrolled.contains(id);
      if (!again) enrolled.add(id);
      savedClass = {...savedClass!, 'enrolledCount': enrolled.length};
      return (
        again ? 200 : 201,
        {
          'id': uid(300),
          'classId': classId,
          'studentId': id,
          'joinedOn': _isoDate(now),
        },
      );
    }
    if (m == 'GET /sessions/${uid(10)}/attendance' && rules.isNotEmpty) {
      final session = _session();
      return (
        200,
        {
          'sessionId': session['id'],
          'classId': classId,
          'className': session['className'],
          'sessionDate': sessionDate,
          'startsAt': session['startsAt'],
          'sessionStatus': 'planned',
          'canEdit': true,
          'editableUntil': now
              .add(const Duration(days: 7))
              .toUtc()
              .toIso8601String(),
          'serverTime': now.toUtc().toIso8601String(),
          'summary': {
            for (final k in ['present', 'late', 'excused', 'unexcused']) k: 0,
          },
          'items': [
            for (final s in savedStudents)
              if (enrolled.contains(s['id']))
                {
                  'studentId': s['id'],
                  'fullName': s['fullName'],
                  'status': null,
                  'note': null,
                  'clientUpdatedAt': null,
                  'syncedAt': null,
                },
          ],
        },
      );
    }
    if (m == 'GET /sessions') {
      return (
        200,
        {
          'items': [if (rules.isNotEmpty) _session()],
        },
      );
    }
    return (404, _err('NOT_FOUND'));
  }

  // ---- đối chiếu hợp đồng -------------------------------------------------

  /// Tìm thao tác của hợp đồng theo method và đường dẫn thật (`/x/{id}`).
  Map<String, dynamic>? _operation(String method, String path) {
    final spec = _openapi;
    if (spec == null) return const {};
    for (final MapEntry(:key, :value) in (spec['paths'] as Map).entries) {
      final template = (key as String).replaceFirst('/v1', '');
      final re = RegExp(
        '^${template.replaceAll(RegExp(r'\{[^}]+\}'), '[^/]+')}\$',
      );
      if (re.hasMatch(path)) {
        final op = (value as Map)[method.toLowerCase()];
        if (op != null) return op as Map<String, dynamic>;
      }
    }
    return null;
  }

  Map<String, dynamic>? _requestSchema(Map<String, dynamic> op) {
    final c = (op['requestBody'] as Map?)?['content'] as Map?;
    return (c?['application/json'] as Map?)?['schema'] as Map<String, dynamic>?;
  }

  Map<String, dynamic> _responseSchema(Map<String, dynamic> op, int status) {
    final r = (op['responses'] as Map)['$status'] as Map;
    return ((r['content'] as Map)['application/json'] as Map)['schema']
        as Map<String, dynamic>;
  }

  bool _valid(Object? v, Map<String, dynamic> schema) {
    try {
      _conform(v, schema, 'request');
      return true;
    } on StateError {
      return false;
    }
  }

  /// Kiểm giá trị theo schema: kiểu, enum, mẫu chuỗi, trường bắt buộc và không
  /// có trường lạ khi `additionalProperties: false`.
  void _conform(Object? v, Map<String, dynamic> s, String at) {
    final spec = _openapi;
    if (spec == null) return;
    final ref = s[r'$ref'] as String?;
    if (ref != null) {
      final schemas =
          (spec['components'] as Map)['schemas'] as Map<String, dynamic>;
      return _conform(
        v,
        schemas[ref.split('/').last] as Map<String, dynamic>,
        at,
      );
    }
    for (final k in ['oneOf', 'anyOf', 'allOf']) {
      final options = s[k] as List?;
      if (options == null) continue;
      if (k == 'allOf') {
        for (final o in options) {
          _conform(v, o as Map<String, dynamic>, at);
        }
        return;
      }
      if (v == null && options.any((o) => (o as Map)['type'] == 'null')) return;
      for (final o in options) {
        try {
          return _conform(v, o as Map<String, dynamic>, at);
        } on StateError {
          continue;
        }
      }
      throw StateError('$at: không khớp $k');
    }
    final type = s['type'];
    final types = type is List ? type : [type];
    if (v == null) {
      if (!types.contains('null')) throw StateError('$at: null không hợp lệ');
      return;
    }
    bool ok(Object? t) => switch (t) {
      'string' => v is String,
      'integer' => v is int,
      'number' => v is num,
      'boolean' => v is bool,
      'array' => v is List,
      'object' => v is Map,
      _ => true,
    };
    if (!types.any(ok)) throw StateError('$at: sai kiểu ($v, cần $type)');
    if (s['enum'] case final List e when !e.contains(v)) {
      throw StateError('$at: $v ngoài enum $e');
    }
    if (v is String && s['pattern'] is String) {
      if (!RegExp(s['pattern'] as String).hasMatch(v)) {
        throw StateError('$at: "$v" sai mẫu ${s['pattern']}');
      }
    }
    if (v is int && s['minimum'] is num && v < (s['minimum'] as num)) {
      throw StateError('$at: $v < ${s['minimum']}');
    }
    if (v is List) {
      final item = s['items'];
      if (item is Map<String, dynamic>) {
        for (var i = 0; i < v.length; i++) {
          _conform(v[i], item, '$at[$i]');
        }
      }
    }
    if (v is Map) {
      final props = (s['properties'] as Map?)?.cast<String, dynamic>() ?? {};
      for (final r in (s['required'] as List? ?? const [])) {
        if (!v.containsKey(r)) throw StateError('$at: thiếu "$r"');
      }
      for (final MapEntry(:key, :value) in v.entries) {
        final sub = props[key];
        if (sub == null) {
          if (s['additionalProperties'] == false) {
            throw StateError('$at: trường lạ "$key"');
          }
          continue;
        }
        _conform(value, sub as Map<String, dynamic>, '$at.$key');
      }
    }
  }

  @override
  void close({bool force = false}) {}
}
