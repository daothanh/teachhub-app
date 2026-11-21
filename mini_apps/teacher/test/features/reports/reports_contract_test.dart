import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/features/reports/data/report_models.dart';
import 'package:teacher/features/reports/data/reports_repository.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

/// Đối chiếu client báo cáo T12/T12a với `contracts/openapi.json` (Sprint 7).
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

Set<String> _required(Map<String, dynamic> s) =>
    (s['required'] as List).cast<String>().toSet();

Map<String, dynamic> _op(String path, String method) =>
    (_paths[path] as Map)[method] as Map<String, dynamic>;

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
    final Object body = switch (options.path) {
      '/reports/month-overview' => _example('MonthOverview'),
      '/reports/payments' => _example('RevenueEntryPage'),
      '/reports/revenue-by-class' => _example('RevenueByClass'),
      _ => _example('Revenue12m'),
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
  // Id thanh toán và học viên chưa dùng: chạm dòng mở hóa đơn (invoiceId).
  'RevenueEntry': {'paymentId', 'studentId'},
};

void main() {
  group('mô hình đọc được ví dụ của hợp đồng', () {
    test('MonthOverview: bốn ô số và hasData', () {
      final o = MonthOverview.fromJson(_example('MonthOverview'));
      expect(o.month, matches(RegExp(r'^\d{4}-\d{2}$')));
      expect(o.billedAmount, greaterThan(0));
      expect(o.collectedAmount, greaterThan(0));
      expect(o.outstandingAmount, greaterThanOrEqualTo(0));
      expect(o.activeStudentCount, greaterThan(0));
      expect(o.hasData, isTrue);
    });

    test('RevenueEntryPage: dòng sổ, tổng cả tháng', () {
      final p = RevenueEntryPage.fromJson(_example('RevenueEntryPage'));
      expect(p.items, isNotEmpty);
      expect(p.items.first.invoiceId, isNotEmpty);
      expect(p.page, greaterThanOrEqualTo(1));
      expect(p.totalAmount, isNotNull);
    });

    test('RevenueByClass: lớp, lớp lưu trữ, dòng "Khác" (classId null)', () {
      final r = RevenueByClass.fromJson(_example('RevenueByClass'));
      expect(r.items, isNotEmpty);
      expect(r.items.any((c) => c.isOther), isTrue);
      final other = r.items.firstWhere((c) => c.isOther);
      expect(other.className, isNull);
      expect(other.attendancePercent, isNull);
      expect(r.items.first.attendancePercent, isA<double>());
    });

    test('Revenue12m: đọc được danh sách tháng', () {
      final r = Revenue12m.fromJson(_example('Revenue12m'));
      expect(r.months, isNotEmpty);
      expect(r.months.first.month, matches(RegExp(r'^\d{4}-\d{2}$')));
    });

    test('mô hình đọc hết trường bắt buộc: thiếu trường thì ném lỗi', () {
      for (final MapEntry(:key, :value) in {
        'MonthOverview': MonthOverview.fromJson,
        'RevenueEntryPage': RevenueEntryPage.fromJson,
        'RevenueEntry': RevenueEntry.fromJson,
        'RevenueByClass': RevenueByClass.fromJson,
        'ClassRevenue': ClassRevenue.fromJson,
        'Revenue12m': Revenue12m.fromJson,
      }.entries) {
        final props = _schema(key)['properties'] as Map<String, dynamic>;
        for (final field in _required(_schema(key))) {
          final nullable = jsonEncode(props[field]).contains('"null"');
          // Enum đọc khoan dung (giá trị lạ có mặc định) nên thiếu không lỗi;
          // thiếu trường nullable thì mô hình nhận null.
          if (nullable ||
              const {'kind', 'method'}.contains(field) ||
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

  test('enum khớp hợp đồng, giá trị lạ coi như payment', () {
    final kind = (_schema('RevenueEntryKind')['enum'] as List).cast<String>();
    expect(kind, RevenueEntryKind.values.map((k) => k.wire));
    expect(RevenueEntryKind.fromWire('refund'), RevenueEntryKind.payment);
    expect(RevenueEntryKind.fromWire(null), RevenueEntryKind.payment);
  });

  group('DioReportsRepository', () {
    late _Adapter adapter;
    late DioReportsRepository repo;
    setUp(() {
      adapter = _Adapter();
      repo = DioReportsRepository(
        Dio(BaseOptions(baseUrl: 'http://x/v1'))..httpClientAdapter = adapter,
      );
    });

    test('mọi lệnh gọi đúng method, đường dẫn và query', () async {
      await repo.monthOverview();
      await repo.monthOverview(month: '2026-10');
      await repo.payments(month: '2026-10', page: 2, pageSize: 10);
      await repo.payments();
      await repo.revenueByClass(month: '2026-10');
      await repo.revenue12m(month: '2026-10');

      for (final r in adapter.requests) {
        final template = _paths.keys.firstWhere(
          (k) => k.replaceFirst('/v1', '') == r.path,
          orElse: () => fail('Hợp đồng không có ${r.method} ${r.path}'),
        );
        expect(_paths[template], contains(r.method.toLowerCase()));
        expect(
          _queryParams(template),
          containsAll(r.queryParameters.keys),
          reason: '${r.path} gửi query ngoài hợp đồng',
        );
      }
      final q = [for (final r in adapter.requests) r.queryParameters];
      // Không gửi `month` trống: máy chủ lấy tháng hiện tại của tenant.
      expect(q[0], isEmpty);
      expect(q[1], {'month': '2026-10'});
      expect(q[2], {'month': '2026-10', 'page': 2, 'pageSize': 10});
      expect(q[3], {'page': 1, 'pageSize': 20});
      expect(q[4], {'month': '2026-10'});
      expect(q[5], {'month': '2026-10'});
    });

    test('phản hồi sai kiểu: ra lỗi ApiException, không kẹt', () async {
      final bad = DioReportsRepository(
        Dio(BaseOptions(baseUrl: 'http://x/v1'))
          ..httpClientAdapter = _BadAdapter(),
      );
      await expectLater(bad.monthOverview(), throwsA(isA<ApiException>()));
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
    '{"month": 1}',
    200,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );

  @override
  void close({bool force = false}) {}
}
