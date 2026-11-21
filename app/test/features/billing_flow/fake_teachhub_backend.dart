// S5-FL-08: backend giả có trạng thái, dùng chung cho giáo viên và phụ huynh.
// Cắm vào `Dio.httpClientAdapter`, không mạng thật. Mô phỏng phần liên quan tới
// luồng học phí của hợp đồng Sprint 5: điểm danh → bản nháp của kỳ → điều chỉnh →
// chốt & gửi → `/family/invoices`. Phản hồi (và thân request) được đối chiếu với
// `contracts/openapi.json` nên lệch hợp đồng là đỏ ngay ở đây.
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

class FakeTeachHubBackend implements HttpClientAdapter {
  FakeTeachHubBackend({DateTime? now}) : now = now ?? DateTime.now();

  /// Mốc "hôm nay" của kịch bản: buổi học, kỳ thu đều tính từ đây.
  final DateTime now;

  static const className = 'Toán 9A';
  static const teacherName = 'Cô Lan';
  static const feePerSession = 150000;

  static String uid(int n) =>
      '00000000-0000-4000-8000-${n.toString().padLeft(12, '0')}';

  static final sessionId = uid(10);
  static final classId = uid(11);
  static final periodId = uid(12);
  static final minhAnh = (id: uid(1), name: 'Nguyễn Minh Anh');
  static final baoChau = (id: uid(2), name: 'Trần Bảo Châu');
  final _students = [minhAnh, baoChau];

  /// Tài khoản nhận tiền (chụp vào hóa đơn lúc chốt); `null` = chưa có.
  Map<String, Object?>? payout;

  /// Mã hóa đơn cấp lần lượt (Crockford, đúng mẫu `TH-xxxxxx` của hợp đồng).
  final _codes = ['25K7Q9', '26M8R2', '27N9S3'];

  /// Mọi request đã nhận: `METHOD /path`, đúng thứ tự.
  final requests = <String>[];

  /// Điểm danh đã đồng bộ lên server: học viên → (trạng thái, ghi chú, lúc ghi).
  final _attendance = <String, ({String status, String? note, String at})>{};
  final _adjustments = <String, List<Map<String, Object?>>>{};
  final _issued = <String, Map<String, Object?>>{};
  final _issueReplay = <String, Map<String, Object?>>{};
  final _syncReplay = <String, Map<String, Object?>>{};

  String get sessionDate => _isoDate(now);
  String get _month => '${now.year}-${now.month.toString().padLeft(2, '0')}-01';

  /// Số buổi đã ghi cho học viên, để test đối chiếu.
  String? attendanceOf(String studentId) => _attendance[studentId]?.status;

  /// Điểm danh đã có sẵn trên server (kịch bản không đi qua màn điểm danh).
  void recordAttendance(String studentId, String status) =>
      _attendance[studentId] = (
        status: status,
        note: null,
        at: now.toUtc().toIso8601String(),
      );

  /// Hóa đơn đã chốt của học viên (bản server giữ), `null` nếu chưa chốt.
  Map<String, Object?>? issuedInvoiceOf(String studentId) =>
      _issued[_invoiceId(studentId)];

  static String invoiceIdOf(String studentId) => _invoiceId(studentId);
  static String _invoiceId(String studentId) =>
      uid(int.parse(studentId.substring(studentId.length - 4)) + 200);

  Dio dio() =>
      Dio(BaseOptions(baseUrl: 'https://api.test/v1'))
        ..httpClientAdapter = this;

  // ---- dựng dữ liệu -------------------------------------------------------

  static String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, Object?> _session() {
    final start = DateTime(now.year, now.month, now.day, 18).toUtc();
    return {
      'id': sessionId,
      'classId': classId,
      'className': className,
      'sessionDate': sessionDate,
      'startsAt': start.toIso8601String(),
      'endsAt': start
          .add(const Duration(hours: 1, minutes: 30))
          .toIso8601String(),
      'status': _attendance.isEmpty ? 'planned' : 'taught',
      'isMakeup': false,
      'cancelReason': null,
      'makeupOf': null,
    };
  }

  Map<String, Object?> _roster() => {
    'sessionId': sessionId,
    'classId': classId,
    'className': className,
    'sessionDate': sessionDate,
    'startsAt': _session()['startsAt'],
    'sessionStatus': _session()['status'],
    'canEdit': true,
    'editableUntil': now.add(const Duration(days: 7)).toUtc().toIso8601String(),
    'serverTime': now.toUtc().toIso8601String(),
    'items': [
      for (final s in _students)
        {
          'studentId': s.id,
          'fullName': s.name,
          'status': _attendance[s.id]?.status,
          'note': _attendance[s.id]?.note,
          'clientUpdatedAt': _attendance[s.id]?.at,
          'syncedAt': _attendance[s.id] == null
              ? null
              : now.toUtc().toIso8601String(),
        },
    ],
    'summary': _summary(),
  };

  Map<String, Object?> _summary() => {
    for (final k in ['present', 'late', 'excused', 'unexcused'])
      k: _attendance.values.where((a) => a.status == k).length,
  };

  Map<String, Object?> _invoice(({String id, String name}) s) {
    final id = _invoiceId(s.id);
    final frozen = _issued[id];
    if (frozen != null) return frozen;
    final lines = _lines(s.id);
    final sum = lines.fold<int>(0, (t, l) => t + (l['amount']! as int));
    return {
      'id': id,
      'periodId': periodId,
      'periodMonth': _month,
      'code': null,
      'transferNote': null,
      'qrPayload': null,
      'status': 'draft',
      'studentId': s.id,
      'studentName': s.name,
      'totalAmount': sum < 0 ? 0 : sum,
      'dueDate': _dueDate(),
      'issuedAt': null,
      'payout': null,
      'voidedAt': null,
      'voidReason': null,
      'replacesInvoiceId': null,
      'replacementInvoiceId': null,
      'lines': lines,
      'installmentNo': null,
      'installmentCount': null,
      'clampedAmount': sum < 0 ? -sum : 0,
      'createdAt': now.toUtc().toIso8601String(),
    };
  }

  /// Chỉ tính buổi đã điểm danh; vắng có phép không tính tiền.
  List<Map<String, Object?>> _lines(String studentId) {
    final a = _attendance[studentId];
    return [
      if (a != null)
        {
          'id': uid(300 + int.parse(studentId.substring(studentId.length - 4))),
          'kind': 'session',
          'description': 'Buổi $sessionDate',
          'amount': a.status == 'excused' ? 0 : feePerSession,
          'charged': a.status != 'excused',
          'notChargedReason': a.status == 'excused'
              ? 'excused_not_charged'
              : null,
          'sessionId': sessionId,
          'sessionDate': sessionDate,
          'className': className,
          'adjustmentReason': null,
        },
      ...?_adjustments[studentId],
    ];
  }

  String _dueDate() => _isoDate(
    DateTime(now.year, now.month + 1, 1).add(const Duration(days: 10)),
  );

  Map<String, Object?> _summaryOf(Map<String, Object?> inv) => {
    'id': inv['id'],
    'code': inv['code'],
    'status': inv['status'],
    'studentId': inv['studentId'],
    'studentName': inv['studentName'],
    'totalAmount': inv['totalAmount'],
    'hasOverride': false,
  };

  Map<String, Object?> _period() {
    final all = [for (final s in _students) _invoice(s)];
    final drafts = all.where((i) => i['status'] == 'draft').toList();
    int sum(Iterable<Map<String, Object?>> l) =>
        l.fold(0, (t, i) => t + (i['totalAmount']! as int));
    final issued = all.where((i) => i['status'] == 'issued').toList();
    final pending = drafts.where((i) => (i['totalAmount']! as int) > 0);
    return {
      'id': periodId,
      'periodMonth': _month,
      'closeDate': _isoDate(DateTime(now.year, now.month + 1, 0)),
      'dueDate': _dueDate(),
      'status': pending.isEmpty && issued.isNotEmpty ? 'closed' : 'drafting',
      'draftCount': drafts.length,
      'issuedCount': issued.length,
      'voidCount': 0,
      'draftTotalAmount': sum(drafts),
      'issuedTotalAmount': sum(issued),
      'invoices': {
        'items': [for (final i in all) _summaryOf(i)],
        'total': all.length,
        'page': 1,
        'pageSize': 100,
      },
    };
  }

  Map<String, Object?> _issue(List<String>? ids) {
    final skipped = <Map<String, Object?>>[];
    final done = <Map<String, Object?>>[];
    for (final s in _students) {
      final inv = _invoice(s);
      if (ids != null && !ids.contains(inv['id'])) continue;
      if (inv['status'] != 'draft') {
        skipped.add({
          'invoiceId': inv['id'],
          'studentName': s.name,
          'reason': 'NOT_DRAFT',
        });
        continue;
      }
      final total = inv['totalAmount']! as int;
      if (total == 0) {
        skipped.add({
          'invoiceId': inv['id'],
          'studentName': s.name,
          'reason': 'ZERO_AMOUNT',
        });
        continue;
      }
      final code = _codes.removeAt(0);
      final note = 'TH $code';
      final p = payout!;
      final frozen = {
        ...inv,
        'code': 'TH-$code',
        'transferNote': note,
        'qrPayload': 'VIETQR|${p['bankBin']}|${p['accountNo']}|$total|$note',
        'status': 'issued',
        'issuedAt': now.toUtc().toIso8601String(),
        'payout': p,
      };
      _issued[inv['id']! as String] = frozen;
      done.add(frozen);
    }
    return {
      'issuedCount': done.length,
      'skipped': skipped,
      'totalAmount': done.fold<int>(
        0,
        (t, i) => t + (i['totalAmount']! as int),
      ),
      'invoices': [
        for (final i in done)
          {
            for (final k in [
              'id',
              'code',
              'studentId',
              'studentName',
              'totalAmount',
              'dueDate',
              'transferNote',
              'qrPayload',
            ])
              k: i[k],
          },
      ],
    };
  }

  Map<String, Object?> _familySummary(Map<String, Object?> i) => {
    'id': i['id'],
    'code': i['code'],
    'status': i['status'],
    'studentId': i['studentId'],
    'studentName': i['studentName'],
    'teacherName': teacherName,
    'periodMonth': i['periodMonth'],
    'totalAmount': i['totalAmount'],
    'dueDate': i['dueDate'],
    'issuedAt': i['issuedAt'],
  };

  Map<String, Object?> _familyDetail(Map<String, Object?> i) => {
    ..._familySummary(i),
    'lines': [
      for (final l in (i['lines']! as List).cast<Map<String, Object?>>())
        {
          'kind': l['kind'],
          'className': l['className'],
          'description': l['description'],
          'amount': l['amount'],
        },
    ],
    'transferNote': i['transferNote'],
    'qrPayload': i['qrPayload'],
    'payout': i['payout'],
    'voidedAt': i['voidedAt'],
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
    if (method == 'POST' && options.headers['Idempotency-Key'] is! String) {
      return _error(422, 'VALIDATION_FAILED');
    }
    final reqSchema = _requestSchema(op);
    if (reqSchema != null && !_valid(body, reqSchema)) {
      return _error(422, 'VALIDATION_FAILED');
    }
    final (status, out) = _route(
      method,
      path,
      body,
      options.headers['Idempotency-Key'] as String?,
    );
    if (status < 300) {
      _conform(out, _responseSchema(op, status), '$method $path');
    }
    return _json(status, out);
  }

  (int, Object) _route(String method, String path, Object? body, String? key) {
    final m = '$method $path';
    if (m == 'GET /sessions') {
      return (
        200,
        {
          'items': [_session()],
        },
      );
    }
    if (m == 'GET /sessions/$sessionId/attendance') return (200, _roster());
    if (m == 'POST /attendance/sync') return _sync(body! as Map, key!);
    if (m == 'GET /payout-accounts') {
      final p = payout;
      return (
        200,
        {
          'items': [
            if (p != null)
              {
                'id': uid(50),
                'bankBin': p['bankBin'],
                'accountNoMasked':
                    '******${(p['accountNo']! as String).substring(6)}',
                'accountName': p['accountName'],
                'isPrimary': true,
                'createdAt': now.toUtc().toIso8601String(),
              },
          ],
        },
      );
    }
    if (m == 'GET /family/students') {
      return (
        200,
        {
          'items': [
            for (final i in _issued.values)
              {
                'id': i['studentId'],
                'fullName': i['studentName'],
                'classes': [],
              },
          ],
        },
      );
    }
    if (m == 'GET /billing-periods') {
      return (
        200,
        {
          'items': [
            if (_attendance.isNotEmpty)
              {
                for (final e in _period().entries)
                  if (e.key != 'invoices') e.key: e.value,
              },
          ],
          'total': _attendance.isEmpty ? 0 : 1,
          'page': 1,
          'pageSize': 100,
        },
      );
    }
    if (m == 'GET /billing-periods/$periodId') return (200, _period());
    if (m == 'POST /billing-periods/$periodId/issue') {
      final replay = _issueReplay[key];
      if (replay != null) return (200, replay);
      if (payout == null) return (422, _err('PAYOUT_ACCOUNT_MISSING'));
      final ids = (body! as Map)['invoiceIds'] as List?;
      return (200, _issueReplay[key!] = _issue(ids?.cast<String>()));
    }
    final inv = RegExp(
      r'^(GET|POST) /invoices/([^/]+)(/adjustments)?$',
    ).firstMatch(m);
    if (inv != null) {
      final student = _students
          .where((s) => _invoiceId(s.id) == inv.group(2))
          .firstOrNull;
      if (student == null) return (404, _err('NOT_FOUND'));
      if (inv.group(3) == null) return (200, _invoice(student));
      if (_issued.containsKey(inv.group(2))) {
        return (409, _err('INVOICE_IMMUTABLE'));
      }
      final b = body! as Map;
      (_adjustments[student.id] ??= []).add({
        'id': uid(
          400 +
              (_adjustments[student.id]?.length ?? 0) +
              int.parse(student.id.substring(student.id.length - 4)) * 10,
        ),
        'kind': 'manual_adjustment',
        'description': b['description'],
        'amount': b['amount'],
        'charged': true,
        'notChargedReason': null,
        'sessionId': null,
        'sessionDate': null,
        'className': null,
        'adjustmentReason': b['adjustmentReason'],
      });
      return (201, _invoice(student));
    }
    // Phụ huynh chỉ thấy hóa đơn đã phát hành.
    if (m == 'GET /family/invoices') {
      return (
        200,
        {
          'items': [for (final i in _issued.values) _familySummary(i)],
          'nextCursor': null,
        },
      );
    }
    final fam = RegExp(r'^GET /family/invoices/([^/]+)$').firstMatch(m);
    if (fam != null) {
      final i = _issued[fam.group(1)];
      return i == null ? (404, _err('NOT_FOUND')) : (200, _familyDetail(i));
    }
    return (404, _err('NOT_FOUND'));
  }

  Map<String, Object?> _err(String code) => {
    'code': code,
    'message': 'x',
    'requestId': 'r',
  };

  (int, Object) _sync(Map body, String key) {
    final replay = _syncReplay[key];
    if (replay != null) return (200, replay);
    final results = <Map<String, Object?>>[];
    for (final m in (body['mutations'] as List).cast<Map>()) {
      _attendance[m['studentId'] as String] = (
        status: m['status'] as String,
        note: m['note'] as String?,
        at: m['clientUpdatedAt'] as String,
      );
      results.add({
        'clientMutationId': m['clientMutationId'],
        'studentId': m['studentId'],
        'result': 'applied',
      });
    }
    return (
      200,
      _syncReplay[key] = {
        'sessionId': sessionId,
        'sessionStatus': 'taught',
        'serverTime': now.toUtc().toIso8601String(),
        'results': results,
        'summary': _summary(),
        'parentsToNotify': 0,
      },
    );
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
