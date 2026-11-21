import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/features/receivables/data/receivable_models.dart';
import 'package:teacher/features/receivables/data/receivables_repository.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

/// Đối chiếu client công nợ và nhắc nợ với `contracts/openapi.json` (Sprint 6).
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

/// Ví dụ của hợp đồng; schema không có `example` thì dựng mẫu tối thiểu từ chính
/// schema (kiểu, enum, định dạng) để mô hình vẫn bị đối chiếu.
Map<String, dynamic> _example(String name) =>
    (_schema(name)['example'] ?? _gen(_schema(name))) as Map<String, dynamic>;

Object? _gen(Map<String, dynamic> s) {
  if (s['example'] != null) return s['example'];
  final ref = s[r'$ref'] as String?;
  if (ref != null) return _gen(_schema(ref.split('/').last));
  if (s['allOf'] != null) {
    return _gen((s['allOf'] as List).first as Map<String, dynamic>);
  }
  if (s['enum'] != null) {
    return (s['enum'] as List).firstWhere((e) => e != null);
  }
  final raw = s['type'];
  final type = raw is List ? raw.firstWhere((t) => t != 'null') : raw;
  return switch (type) {
    'object' => {
      for (final MapEntry(:key, :value)
          in (s['properties'] as Map<String, dynamic>).entries)
        key: _gen(value as Map<String, dynamic>),
    },
    'array' => [_gen(s['items'] as Map<String, dynamic>)],
    'boolean' => true,
    'integer' => ((s['minimum'] as num?) ?? 0) > 1 ? s['minimum'] : 1,
    _ => switch (s['format']) {
      'uuid' => '019c0a10-0001-7b30-8c01-000000000001',
      'date' => '2027-01-10',
      'date-time' => '2027-01-10T09:00:00+07:00',
      _ => 'x',
    },
  };
}

Set<String> _props(Map<String, dynamic> s) =>
    (s['properties'] as Map).keys.cast<String>().toSet();

Set<String> _required(Map<String, dynamic> s) =>
    (s['required'] as List).cast<String>().toSet();

Map<String, dynamic> _op(String path, String method) =>
    (_paths[path] as Map)[method] as Map<String, dynamic>;

/// Schema của thân yêu cầu, gỡ `allOf` một tầng (UpdateDunningSettingsRequest).
Map<String, dynamic> _body(String path, String method) {
  final content =
      ((_op(path, method)['requestBody'] as Map)['content']
              as Map)['application/json']
          as Map;
  var s = _schema(
    ((content['schema'] as Map)['\$ref'] as String).split('/').last,
  );
  while (s['allOf'] != null) {
    s = _schema(
      (((s['allOf'] as List).first as Map)['\$ref'] as String).split('/').last,
    );
  }
  return s;
}

List<String> _queryParams(String path) => [
  for (final p in _op(path, 'get')['parameters'] as List)
    if ((p as Map)['in'] == 'query') p['name'] as String,
];

/// Ghi lại request; trả phản hồi mẫu lấy từ chính hợp đồng.
class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final p = options.path;
    final Object body = switch ((options.method, p)) {
      ('GET', '/receivables') => _example('Receivables'),
      ('GET', _) when p.startsWith('/receivables/') => _example(
        'StudentReceivableHistory',
      ),
      ('GET', '/tenant/settings/dunning') ||
      ('PUT', '/tenant/settings/dunning') => _example('DunningSettings'),
      ('GET', '/tenant/settings/dunning/preview') => _example('DunningPreview'),
      ('PUT', _) when p.endsWith('/dunning') => _example(
        'EnrollmentDunningResult',
      ),
      _ => _example('InvoiceDunning'),
    };
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Trường bắt buộc của hợp đồng mà màn hình chưa dùng nên mô hình không đọc.
const _unread = {
  'ReceivableRow': <String>{},
  'StudentReceivableHistory': <String>{},
  'ReceivableInvoice': <String>{},
  // Ghi chú, người ghi/hủy và lý do hủy chưa hiện trong lịch sử T11.
  'ReceivablePayment': {
    'note',
    'recordedAt',
    'recordedBy',
    'voidedBy',
    'voidReason',
  },
  'ReceivableReminder': {'invoiceId'},
  'InvoiceDunning': {'invoiceId'},
  'EnrollmentDunningResult': {'studentId'},
};

void main() {
  group('mô hình đọc được ví dụ của hợp đồng', () {
    test('Receivables: dòng và tổng theo ba nhóm', () {
      final p = ReceivablePage.fromJson(_example('Receivables'));
      expect(p.items, isNotEmpty);
      final r = p.items.first;
      expect(r.outstandingAmount, greaterThan(0));
      expect(r.classNames, isNotEmpty);
      expect(p.buckets.map((b) => b.bucket), AgingBucket.values);
      expect(p.totalAmount, greaterThan(0));
    });

    test(
      'StudentReceivableHistory: hóa đơn, thanh toán, nhắc nợ, ghi danh',
      () {
        final h = StudentReceivableHistory.fromJson(
          _example('StudentReceivableHistory'),
        );
        expect(h.enrollments, isNotEmpty);
        expect(h.invoices, isNotEmpty);
        expect(h.payments, isNotEmpty);
        expect(h.reminders, isNotEmpty);
        expect(h.invoiceOutstandingAmount, isNonNegative);
      },
    );

    test('DunningSettings: mặc định -1, 0, 3, 7 và khứ hồi thân PUT', () {
      final s = DunningSettings.fromJson(_example('DunningSettings'));
      expect(s.enabled, isTrue);
      expect(s.offsetsDays, defaultDunningOffsets);
      expect(s.toJson(), _example('DunningSettings'));
    });

    test('InvoiceDunning, DunningPreview, EnrollmentDunningResult', () {
      final d = InvoiceDunning.fromJson(_example('InvoiceDunning'));
      expect(d.enabled, isTrue);
      expect(d.steps, isNotEmpty);
      final p = DunningPreview.fromJson(_example('DunningPreview'));
      expect(p.title, isNotEmpty);
      final e = EnrollmentDunningResult.fromJson(
        _example('EnrollmentDunningResult'),
      );
      expect(e.cancelledCount, greaterThanOrEqualTo(0));
    });

    test('mô hình đọc hết trường bắt buộc: thiếu trường thì ném lỗi', () {
      for (final MapEntry(:key, :value) in {
        'ReceivableRow': ReceivableRow.fromJson,
        'StudentReceivableHistory': StudentReceivableHistory.fromJson,
        'ReceivableInvoice': ReceivableInvoice.fromJson,
        'ReceivablePayment': ReceivablePayment.fromJson,
        'ReceivableReminder': ReceivableReminder.fromJson,
        'InvoiceDunning': InvoiceDunning.fromJson,
        'EnrollmentDunningResult': EnrollmentDunningResult.fromJson,
        'DunningSettings': DunningSettings.fromJson,
        'DunningPreview': DunningPreview.fromJson,
      }.entries) {
        final props = _schema(key)['properties'] as Map<String, dynamic>;
        for (final field in _required(_schema(key))) {
          final nullable = jsonEncode(props[field]).contains('"null"');
          // Enum đọc khoan dung (giá trị lạ có mặc định) nên thiếu không lỗi.
          if (nullable ||
              const {
                'status',
                'method',
                'agingBucket',
                'disabledReason',
              }.contains(field) ||
              _unread[key]?.contains(field) == true) {
            continue;
          }
          final broken = {..._example(key)}..remove(field);
          expect(
            () => value(broken),
            throwsA(anything),
            reason: '$key bỏ $field phải lỗi (mô hình dùng trường này)',
          );
        }
      }
    });
  });

  test('enum khớp hợp đồng, mỗi giá trị một nhánh riêng', () {
    final aging = (_schema('AgingBucket')['enum'] as List).cast<String>();
    expect(aging, AgingBucket.values.map((b) => b.wire));
    expect(aging.map(AgingBucket.fromWire).toSet(), AgingBucket.values.toSet());
    final sort = (_schema('ReceivableSortField')['enum'] as List)
        .cast<String>();
    expect(sort, ReceivableSort.values.map((s) => s.wire));
    final step = (_schema('DunningStepStatus')['enum'] as List).cast<String>();
    // `unknown` chỉ dành cho giá trị lạ, không có trong hợp đồng.
    expect(
      step.map(DunningStepStatus.fromWire).toSet(),
      DunningStepStatus.values.toSet()..remove(DunningStepStatus.unknown),
    );
    expect(DunningStepStatus.fromWire('paused'), DunningStepStatus.unknown);
    expect(DunningStepStatus.fromWire(null), DunningStepStatus.unknown);
    expect(AgingBucket.fromWire('120+'), AgingBucket.upTo30);
    final reason =
        ((_schema('InvoiceDunning')['properties'] as Map)['disabledReason']
                as Map)['enum']
            as List;
    final parsed = reason
        .whereType<String>()
        .map(DunningDisabledReason.fromWire)
        .toSet();
    expect(parsed, DunningDisabledReason.values.toSet());
  });

  test('giới hạn mốc nhắc ở máy khớp hợp đồng', () {
    final p = _props(_body('/v1/tenant/settings/dunning', 'put'));
    expect(p, {'enabled', 'offsetsDays'});
    final offsets =
        (_body('/v1/tenant/settings/dunning', 'put')['properties']
                as Map)['offsetsDays']
            as Map;
    expect(offsets['maxItems'], dunningOffsetsMaxCount);
    expect((offsets['items'] as Map)['minimum'], dunningOffsetMin);
    expect((offsets['items'] as Map)['maximum'], dunningOffsetMax);
    expect(_example('DunningSettings')['offsetsDays'], defaultDunningOffsets);
  });

  group('DioReceivablesRepository', () {
    late _Adapter adapter;
    late DioReceivablesRepository repo;
    setUp(() {
      adapter = _Adapter();
      repo = DioReceivablesRepository(
        Dio(BaseOptions(baseUrl: 'http://x/v1'))..httpClientAdapter = adapter,
      );
    });

    test('mọi lệnh gọi đúng method, đường dẫn, query và thân', () async {
      await repo.list(
        page: 2,
        agingBucket: AgingBucket.over60,
        classId: 'cls1',
        query: 'minh',
        ascending: true,
      );
      await repo.list();
      await repo.history('stu1');
      await repo.getSettings();
      final put = await repo.putSettings(
        const DunningSettings(enabled: false, offsetsDays: [0, 5]),
      );
      expect(put.offsetsDays, defaultDunningOffsets);
      await repo.preview(3);
      await repo.setEnrollmentDunning('enr1', enabled: false);
      await repo.invoiceDunning('inv1');

      for (final r in adapter.requests) {
        final template = _paths.keys.firstWhere(
          (k) => RegExp(
            '^${k.replaceFirst('/v1', '').replaceAll(RegExp(r'\{\w+\}'), '[^/]+')}\$',
          ).hasMatch(r.path),
          orElse: () => fail('Hợp đồng không có ${r.method} ${r.path}'),
        );
        expect(_paths[template], contains(r.method.toLowerCase()));
      }

      final byPath = {
        for (final r in adapter.requests) '${r.method} ${r.path}': r,
      };
      final first = adapter.requests.first;
      expect(first.queryParameters, {
        'page': 2,
        'pageSize': 20,
        'agingBucket': 'over-60',
        'classId': 'cls1',
        'q': 'minh',
        'sortField': 'amount',
        'sortOrder': 'asc',
      });
      expect(
        _queryParams('/v1/receivables'),
        containsAll(first.queryParameters.keys),
      );
      // Mặc định: số nợ giảm dần, không gửi bộ lọc trống.
      expect(adapter.requests[1].queryParameters, {
        'page': 1,
        'pageSize': 20,
        'sortField': 'amount',
        'sortOrder': 'desc',
      });
      expect(byPath, contains('GET /receivables/stu1'));
      expect(byPath['PUT /tenant/settings/dunning']!.data, {
        'enabled': false,
        'offsetsDays': [0, 5],
      });
      expect(_required(_body('/v1/tenant/settings/dunning', 'put')), {
        'enabled',
        'offsetsDays',
      });
      expect(byPath['GET /tenant/settings/dunning/preview']!.queryParameters, {
        'offsetDays': 3,
      });
      expect(_queryParams('/v1/tenant/settings/dunning/preview'), [
        'offsetDays',
      ]);
      final toggle = byPath['PUT /enrollments/enr1/dunning']!;
      expect(toggle.data, {'enabled': false});
      expect(_required(_body('/v1/enrollments/{id}/dunning', 'put')), {
        'enabled',
      });
    });

    test('phản hồi sai kiểu: ra lỗi ApiException, không kẹt', () async {
      final bad = DioReceivablesRepository(
        Dio(BaseOptions(baseUrl: 'http://x/v1'))
          ..httpClientAdapter = _BadAdapter(),
      );
      await expectLater(bad.list(), throwsA(isA<ApiException>()));
    });
  });
}

class _BadAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '{"items": 1}',
    200,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );

  @override
  void close({bool force = false}) {}
}
