import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/features/classes/data/class_models.dart';
import 'package:teacher/features/classes/data/classes_repository.dart';

/// Đối chiếu mô hình và client lớp học với `contracts/openapi.json` (bản chép
/// từ backend, cập nhật bằng `dart run tool/sync_openapi.dart` trong
/// packages/teachhub_shared). Hợp đồng đổi tên trường/đường dẫn mà app chưa
/// theo thì test đỏ.
final _openapi =
    jsonDecode(
          File(
            '../../packages/teachhub_shared/contracts/openapi.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;
final _schemas =
    (_openapi['components'] as Map)['schemas'] as Map<String, dynamic>;
final _paths = _openapi['paths'] as Map<String, dynamic>;

Map<String, dynamic> _schema(String name) =>
    _schemas[name] as Map<String, dynamic>;
Set<String> _props(Map<String, dynamic> s) =>
    (s['properties'] as Map).keys.cast<String>().toSet();

/// Map ghi lại các khóa mà `fromJson` đọc.
class _Spy extends MapBase<String, dynamic> {
  _Spy(this._inner);
  final Map<String, dynamic> _inner;
  final reads = <String>{};

  @override
  dynamic operator [](Object? key) {
    reads.add(key as String);
    return _inner[key];
  }

  @override
  void operator []=(String key, dynamic value) => _inner[key] = value;
  @override
  void clear() => _inner.clear();
  @override
  Iterable<String> get keys => _inner.keys;
  @override
  dynamic remove(Object? key) => _inner.remove(key);
}

/// Giá trị mẫu hợp lệ theo schema (kể cả `$ref`, enum, date, giờ `HH:mm`).
dynamic _sample(Object? node, [String? name]) {
  final s = node as Map<String, dynamic>;
  if (s['\$ref'] != null) {
    return _sample(_schemas[(s['\$ref'] as String).split('/').last]);
  }
  if (s['enum'] != null) return (s['enum'] as List).first;
  var type = s['type'];
  if (type is List) type = type.firstWhere((t) => t != 'null');
  switch (type) {
    case 'object':
      return <String, dynamic>{
        for (final e in (s['properties'] as Map).entries)
          e.key as String: _sample(e.value, e.key as String),
      };
    case 'array':
      return [_sample(s['items'])];
    case 'integer':
      return (s['minimum'] as num?)?.toInt().clamp(0, 1 << 30) ?? 1;
    case 'boolean':
      return false;
    default:
      if (s['format'] == 'date') return '2026-12-14';
      if (s['format'] == 'date-time') return '2026-12-14T11:00:00.000Z';
      if (name == 'startTime') return '18:00';
      return 'v-$name';
  }
}

/// Phản hồi theo `operationId`: lấy schema 2xx đầu tiên của hợp đồng.
class _ContractAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  /// Ép mã trạng thái (vd. 201 thay vì 200 cho ghi danh).
  int? status;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final op = _operation(options.method, options.path);
    final code =
        status?.toString() ??
        (op['responses'] as Map).keys.firstWhere(
          (c) => (c as String).startsWith('2'),
        );
    final body = _sample(
      (((op['responses'] as Map)[code] as Map)['content']
          as Map)['application/json']['schema'],
    );
    return ResponseBody.fromString(
      jsonEncode(body),
      int.parse(code as String),
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Tìm operation theo method + đường dẫn thật (`/v1` + mẫu có `{id}`).
Map<String, dynamic> _operation(String method, String path) {
  for (final e in _paths.entries) {
    final template = RegExp(
      '^${e.key.replaceFirst('/v1', '').replaceAll(RegExp(r'\{\w+\}'), r'[^/]+')}\$',
    );
    final op = (e.value as Map)[method.toLowerCase()];
    if (op != null && template.hasMatch(path)) {
      return op as Map<String, dynamic>;
    }
  }
  fail('Hợp đồng không có $method $path');
}

void main() {
  void modelReads(
    String schema,
    Object? Function(Map<String, dynamic>) parse, {
    Map<String, dynamic> overrides = const {},
    bool subset = false,
  }) {
    test('$schema: fromJson đọc đúng các trường của hợp đồng', () {
      final spy = _Spy({
        ...(_sample(_schema(schema)) as Map<String, dynamic>),
        ...overrides,
      });
      parse(spy);
      // `subset`: app chỉ cần một phần trường (vd. hồ sơ học viên khi tìm).
      expect(spy.reads, subset ? isNotEmpty : _props(_schema(schema)));
      expect(_props(_schema(schema)), containsAll(spy.reads));
    });
  }

  modelReads('Class', TeachClass.fromJson);
  modelReads('ScheduleRule', ScheduleRule.fromJson);
  modelReads('ClassCreated', ClassCreated.fromJson);
  modelReads('Enrollment', Enrollment.fromJson);
  modelReads('Student', StudentSummary.fromJson, subset: true);
  modelReads('Session', ClassSession.fromJson);
  modelReads('ScheduleRulesResult', ScheduleRulesResult.fromJson);

  test('Roster: mỗi mục đọc đúng các trường', () {
    final item =
        ((_schema('Roster')['properties'] as Map)['items'] as Map)['items']
            as Map<String, dynamic>;
    final spy = _Spy(_sample(item) as Map<String, dynamic>);
    RosterEntry.fromJson(spy);
    expect(spy.reads, _props(item));
  });

  test('enum trong hợp đồng khớp enum của app', () {
    List<Object?> en(String schema, String prop) =>
        ((_schema(schema)['properties'] as Map)[prop] as Map)['enum'] as List;
    expect(ClassMode.values.map((e) => e.name), en('Class', 'mode'));
    expect(ClassStatus.values.map((e) => e.name), en('Class', 'status'));
    expect(SessionStatus.values.map((e) => e.name), en('Session', 'status'));
  });

  test('trường nullable nhận null, app không ném', () {
    final c = {
      ...(_sample(_schema('Class')) as Map<String, dynamic>),
      'location': null,
      'capacity': null,
      'endDate': null,
    };
    final parsed = TeachClass.fromJson(c);
    expect(parsed.location, isNull);
    expect(parsed.capacity, isNull);
    expect(parsed.endDate, isNull);
  });

  test('body POST/PATCH /classes chỉ dùng khóa của hợp đồng, đủ required', () {
    const input = ClassInput(
      name: 'Toán 9A',
      subject: 'Toán',
      grade: 9,
      startDate: '2026-12-14',
      location: 'Nhà riêng',
    );
    Map<String, dynamic> body(String path, String method) =>
        (((_paths[path] as Map)[method] as Map)['requestBody']
                as Map)['content']['application/json']['schema']
            as Map<String, dynamic>;
    final post = body('/v1/classes', 'post');
    expect(_props(post), containsAll(input.toJson().keys));
    expect(input.toJson().keys, containsAll(post['required'] as List));
    expect(
      _props(body('/v1/classes/{id}', 'patch')),
      containsAll(input.toJson().keys),
    );

    final rule = body('/v1/classes/{id}/schedule-rules', 'put');
    final item = ((rule['properties'] as Map)['rules'] as Map)['items'] as Map;
    expect(
      const ScheduleRule(
        weekday: 1,
        startTime: '18:00',
        durationMin: 90,
      ).toJson().keys.toSet(),
      _props(item as Map<String, dynamic>),
    );
  });

  test('giới hạn kiểm tra ở máy khớp hợp đồng', () {
    final p =
        ((_paths['/v1/classes']['post']['requestBody']['content']
                    as Map)['application/json']['schema']['properties']
                as Map)
            .cast<String, Map>();
    expect(p['grade']!['minimum'], 1);
    expect(p['grade']!['maximum'], 12);
    expect(p['capacity']!['minimum'], 1);
    expect(p['capacity']!['maximum'], 500);
    final rule =
        ((_paths['/v1/classes/{id}/schedule-rules']['put']['requestBody']['content']
                    as Map)['application/json']['schema']['properties']
                as Map)['rules']
            as Map;
    expect(rule['maxItems'], 14);
    final d = (rule['items']['properties'] as Map)['durationMin'] as Map;
    expect(d['minimum'], 15);
    expect(d['maximum'], 480);
    expect(
      ((_paths['/v1/students']['get']['parameters'] as List).firstWhere(
        (x) => x['name'] == 'q',
      ))['schema']['minLength'],
      2,
    );
  });

  group('DioClassesRepository gọi đúng method, đường dẫn, tham số', () {
    late _ContractAdapter adapter;
    late DioClassesRepository repo;
    setUp(() {
      adapter = _ContractAdapter();
      repo = DioClassesRepository(
        Dio(BaseOptions(baseUrl: 'http://x/v1'))..httpClientAdapter = adapter,
      );
    });

    Set<String> queryNames(String method, String path) => {
      for (final p in (_operation(method, path)['parameters'] as List))
        if (p['in'] == 'query') p['name'] as String,
    };

    test(
      'mọi lệnh gọi có trong hợp đồng và chỉ dùng tham số query đã khai',
      () async {
        await repo.list(status: ClassStatus.archived, page: 2);
        await repo.get('c1');
        await repo.create(const ClassInput());
        await repo.update('c1', const ClassInput());
        await repo.archive('c1');
        await repo.roster('c1');
        await repo.enroll('c1', 's1');
        await repo.searchStudents('an');
        await repo.putRules('c1', const []);
        await repo.sessions(
          from: '2026-12-14',
          to: '2027-02-12',
          classId: 'c1',
        );

        expect(adapter.requests, hasLength(10));
        for (final r in adapter.requests) {
          _operation(r.method, r.path); // ném nếu hợp đồng không có
          expect(
            queryNames(r.method, r.path),
            containsAll(r.queryParameters.keys),
            reason: '${r.method} ${r.path}',
          );
        }
        expect(adapter.requests.first.queryParameters['status'], 'archived');
      },
    );

    test('ghi danh: 201 là mới, 200 là đã có', () async {
      adapter.status = 201;
      expect((await repo.enroll('c1', 's1')).alreadyEnrolled, isFalse);
      adapter.status = 200;
      expect((await repo.enroll('c1', 's1')).alreadyEnrolled, isTrue);
    });
  });
}
