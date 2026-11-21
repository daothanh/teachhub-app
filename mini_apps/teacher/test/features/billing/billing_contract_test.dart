import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/features/billing/data/billing_models.dart';
import 'package:teacher/features/billing/data/billing_repository.dart';

/// Đối chiếu client kỳ thu và hóa đơn với `contracts/openapi.json` (Sprint 5 và 6).
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

Map<String, dynamic> _example(String name) =>
    _schema(name)['example'] as Map<String, dynamic>;

Set<String> _props(Map<String, dynamic> s) =>
    (s['properties'] as Map).keys.cast<String>().toSet();

Set<String> _required(Map<String, dynamic> s) =>
    (s['required'] as List).cast<String>().toSet();

Map<String, dynamic> _body(String path) {
  final op = (_paths[path] as Map)['post'] as Map<String, dynamic>;
  final schema =
      (((op['requestBody'] as Map)['content'] as Map)['application/json']
              as Map)['schema']
          as Map<String, dynamic>;
  return _schema((schema['\$ref'] as String).split('/').last);
}

/// Ghi lại request; trả phản hồi mẫu lấy từ chính hợp đồng.
class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  /// Trang hóa đơn của `GET /billing-periods/{id}` phát lần lượt.
  int periodPages = 1;

  /// Từ trang này trở đi server trả trang rỗng dù `total` còn lớn (đếm lệch).
  int emptyFrom = 99;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final period = _example('BillingPeriod');
    final summary = _example('InvoiceSummary');
    final Object body = switch ((options.method, options.path)) {
      ('GET', '/billing-periods') => {
        'items': [period],
        'total': 1,
        'page': 1,
        'pageSize': 100,
      },
      ('GET', final p) when p.startsWith('/billing-periods/') => {
        ...period,
        'invoices': {
          'items': [
            if ((options.queryParameters['page'] as int) < emptyFrom)
              {...summary, 'id': 'p${options.queryParameters['page']}'},
          ],
          'total': periodPages,
          'page': options.queryParameters['page'],
          'pageSize': 100,
        },
      },
      ('GET', final p) when p.endsWith('/payments') => {
        'items': [_example('Payment')],
      },
      ('POST', final p)
          when p.endsWith('/payments') || p.startsWith('/payments/') =>
        _example('PaymentResult'),
      ('POST', final p) when p.endsWith('/issue') => _example(
        'IssueInvoicesResult',
      ),
      ('POST', final p) when p.endsWith('/void') => {
        'invoice': _example('Invoice'),
        'replacementInvoiceId': null,
      },
      _ => _example('Invoice'),
    };
    return ResponseBody.fromString(
      jsonEncode(body),
      options.method == 'POST' &&
              (options.path.endsWith('/adjustments') ||
                  options.path.endsWith('/payments'))
          ? 201
          : 200,
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
  'Invoice': {'studentId', 'createdAt'},
  'PaymentResult': {'dunningCancelled'},
  // Người ghi/hủy có thể không xác định (null) nên thiếu khóa cũng đọc được.
  'Payment': {'recordedBy', 'voidedBy'},
};

void main() {
  group('mô hình đọc được ví dụ của hợp đồng', () {
    test('BillingPeriod', () {
      final p = BillingPeriod.fromJson(_example('BillingPeriod'));
      expect(p.status, BillingPeriodStatus.drafting);
      expect([p.month, p.year, p.draftCount], [12, 2026, 18]);
      expect(p.draftTotalAmount, 21600000);
    });

    test('InvoiceSummary: bản nháp chưa có mã', () {
      final i = InvoiceSummary.fromJson(_example('InvoiceSummary'));
      expect(i.code, isNull);
      expect(i.isPayableDraft, isTrue);
    });

    test('Invoice: dòng buổi tính và không tính kèm lý do', () {
      final inv = Invoice.fromJson(_example('Invoice'));
      expect(inv.sessionLines, hasLength(2));
      expect(inv.sessionLines.last.charged, isFalse);
      expect(inv.sessionLines.last.notChargedReason, NotChargedReason.excused);
      expect(inv.totalAmount, 150000);
    });

    test('Invoice: đã thu, còn nợ; ghi được thanh toán theo trạng thái', () {
      final inv = Invoice.fromJson(_example('Invoice'));
      expect([inv.paidAmount, inv.remainingAmount], [0, 150000]);
      expect(inv.carriedAmount, 0);
      expect(inv.status, InvoiceStatus.draft);
      expect(inv.canRecordPayment, isFalse);
      final issued = Invoice.fromJson({
        ..._example('Invoice'),
        'status': 'issued',
        'remainingAmount': 150000,
      });
      expect(issued.canRecordPayment, isTrue);
      for (final (status, can) in [
        ('partially_paid', true),
        ('paid', false),
        ('void', false),
        ('draft', false),
      ]) {
        expect(
          Invoice.fromJson({
            ..._example('Invoice'),
            'status': status,
          }).canRecordPayment,
          can,
          reason: status,
        );
      }
    });

    test('Payment: người ghi, hủy và lý do; null khi không xác định', () {
      final p = Payment.fromJson(_example('Payment'));
      expect(p.amount, 500000);
      expect(p.method, PaymentMethod.bankTransfer);
      expect(p.recordedBy!.name, 'Cô Lan');
      expect(p.isVoided, isFalse);
      final v = Payment.fromJson({
        ..._example('Payment'),
        'recordedBy': null,
        'voidedAt': '2027-01-06T08:00:00+07:00',
        'voidedBy': {'id': 'u', 'name': 'Cô Lan'},
        'voidReason': 'Ghi nhầm',
      });
      expect(v.isVoided, isTrue);
      expect(v.recordedBy, isNull);
      expect(v.voidedBy!.name, 'Cô Lan');
    });

    test('PaymentResult: trạng thái và số liệu sau thao tác', () {
      final r = PaymentResult.fromJson(_example('PaymentResult'));
      expect(r.status, InvoiceStatus.partiallyPaid);
      expect(
        [r.paidAmount, r.remainingAmount, r.overpaidAmount],
        [500000, 700000, 0],
      );
      final inv = Invoice.fromJson({
        ..._example('Invoice'),
        'status': 'issued',
      }).afterPayment(r);
      expect(inv.status, InvoiceStatus.partiallyPaid);
      expect(inv.remainingAmount, 700000);
    });

    test('IssueInvoicesResult: bỏ qua hóa đơn 0 đ', () {
      final r = IssueResult.fromJson(_example('IssueInvoicesResult'));
      expect(r.issuedCount, 1);
      expect(r.zeroSkipped, 1);
      expect(r.coveredCount, 0);
    });

    test('mô hình đọc hết trường bắt buộc: thiếu trường thì ném lỗi', () {
      for (final MapEntry(:key, :value) in {
        'BillingPeriod': BillingPeriod.fromJson,
        'InvoiceSummary': InvoiceSummary.fromJson,
        'Invoice': Invoice.fromJson,
        'Payment': Payment.fromJson,
        'PaymentResult': PaymentResult.fromJson,
        'IssueInvoicesResult': IssueResult.fromJson,
      }.entries) {
        final props = _schema(key)['properties'] as Map<String, dynamic>;
        for (final field in _required(_schema(key))) {
          // Enum đọc khoan dung (giá trị lạ/thiếu có mặc định) và trường null
          // được thì thiếu không phải lỗi.
          final nullable = jsonEncode(props[field]).contains('"null"');
          if (nullable ||
              field == 'status' ||
              field == 'method' ||
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
    final status = (_schema('InvoiceStatus')['enum'] as List).cast<String>();
    expect(
      status.map(InvoiceStatus.fromWire).toSet(),
      hasLength(status.length),
    );
    final kinds = (_schema('InvoiceLineKind')['enum'] as List).cast<String>();
    expect(
      kinds.map(InvoiceLineKind.fromWire).toSet(),
      hasLength(kinds.length),
    );
    final reasons = (_schema('SessionNotChargedReason')['enum'] as List)
        .cast<String>();
    final parsed = reasons.map(NotChargedReason.fromWire).toSet();
    expect(parsed, hasLength(reasons.length));
    expect(parsed, isNot(contains(NotChargedReason.other)));
    final methods = (_schema('PaymentMethod')['enum'] as List).cast<String>();
    expect(
      methods.map(PaymentMethod.fromWire).toSet(),
      PaymentMethod.values.toSet(),
    );
    expect(methods, PaymentMethod.values.map((m) => m.wire));
    final period = (_schema('BillingPeriodStatus')['enum'] as List)
        .cast<String>();
    expect(
      period.map(BillingPeriodStatus.fromWire).toSet(),
      BillingPeriodStatus.values.toSet(),
    );
  });

  test('giới hạn kiểm tra ở máy khớp hợp đồng', () {
    final p = (_body('/v1/invoices/{id}/adjustments')['properties'] as Map)
        .cast<String, Map>();
    expect(p['amount']!['maximum'], adjustmentAmountMax);
    expect(p['amount']!['minimum'], -adjustmentAmountMax);
    expect(p['description']!['maxLength'], adjustmentDescriptionMax);
    expect(p['adjustmentReason']!['maxLength'], adjustmentReasonMax);
    final v = (_body('/v1/invoices/{id}/void')['properties'] as Map)
        .cast<String, Map>();
    expect(v['reason']!['maxLength'], voidReasonMax);
    final pay = (_body('/v1/invoices/{id}/payments')['properties'] as Map)
        .cast<String, Map>();
    expect(pay['amount']!['minimum'], 1);
    expect(pay['amount']!['maximum'], paymentAmountMax);
    expect(pay['note']!['maxLength'], paymentNoteMax);
    final vp = (_body('/v1/payments/{id}/void')['properties'] as Map)
        .cast<String, Map>();
    expect(vp['reason']!['maxLength'], voidReasonMax);
  });

  group('DioBillingRepository', () {
    late _Adapter adapter;
    late DioBillingRepository repo;
    setUp(() {
      adapter = _Adapter();
      repo = DioBillingRepository(
        Dio(BaseOptions(baseUrl: 'http://x/v1'))..httpClientAdapter = adapter,
      );
    });

    test(
      'mọi lệnh gọi đúng method, đường dẫn, khóa body và có Idempotency-Key',
      () async {
        await repo.listPeriods();
        await repo.getPeriod('per1');
        await repo.getInvoice('inv1');
        await repo.addAdjustment(
          'inv1',
          const AdjustmentInput(
            amount: -100000,
            description: ' Giảm học thử ',
            reason: ' Đã thỏa thuận ',
          ),
          idempotencyKey: 'k1',
        );
        await repo.issue('per1', idempotencyKey: 'k2');
        await repo.issue('per1', invoiceIds: ['a', 'b'], idempotencyKey: 'k3');
        final voided = await repo.voidInvoice(
          'inv1',
          reason: ' Sai số buổi ',
          idempotencyKey: 'k4',
        );
        expect(voided.id, _example('Invoice')['id']);

        for (final r in adapter.requests) {
          final template = _paths.keys.firstWhere(
            (k) => RegExp(
              '^${k.replaceFirst('/v1', '').replaceAll(RegExp(r'\{\w+\}'), '[^/]+')}\$',
            ).hasMatch(r.path),
            orElse: () => fail('Hợp đồng không có ${r.method} ${r.path}'),
          );
          expect(_paths[template], contains(r.method.toLowerCase()));
        }
        // Mọi lệnh ghi bắt buộc Idempotency-Key.
        for (final r in adapter.requests.where((r) => r.method == 'POST')) {
          expect(r.headers['Idempotency-Key'], isNotNull, reason: r.path);
        }

        final byPath = {
          for (final r in adapter.requests) '${r.method} ${r.path}': r,
        };
        final adjust = byPath['POST /invoices/inv1/adjustments']!;
        final adjustBody = _body('/v1/invoices/{id}/adjustments');
        expect((adjust.data as Map).keys.toSet(), _required(adjustBody));
        expect(_props(adjustBody), containsAll((adjust.data as Map).keys));
        expect(adjust.data, {
          'amount': -100000,
          'description': 'Giảm học thử',
          'adjustmentReason': 'Đã thỏa thuận',
        });

        final issues = adapter.requests
            .where((r) => r.path == '/billing-periods/per1/issue')
            .toList();
        // Khóa `invoiceIds` bắt buộc có, kể cả null (chốt tất cả).
        expect(issues[0].data, {'invoiceIds': null});
        expect(issues[1].data, {
          'invoiceIds': ['a', 'b'],
        });
        expect(_required(_body('/v1/billing-periods/{id}/issue')), {
          'invoiceIds',
        });

        final voidReq = byPath['POST /invoices/inv1/void']!;
        expect(voidReq.data, {'reason': 'Sai số buổi'});
        expect(
          _props(_body('/v1/invoices/{id}/void')),
          containsAll((voidReq.data as Map).keys),
        );
      },
    );

    test('thanh toán: đúng method, đường dẫn, thân và Idempotency-Key', () async {
      final list = await repo.listPayments('inv1');
      expect(list.single.id, _example('Payment')['id']);
      final r = await repo.recordPayment(
        'inv1',
        const PaymentInput(
          amount: 500000,
          method: PaymentMethod.cash,
          paidOn: '2027-01-05',
          note: ' Đóng tiền mặt ',
        ),
        idempotencyKey: 'k5',
      );
      expect(r.status, InvoiceStatus.partiallyPaid);
      await repo.voidPayment(
        'pay1',
        reason: ' Ghi nhầm ',
        idempotencyKey: 'k6',
      );

      final byPath = {
        for (final r in adapter.requests) '${r.method} ${r.path}': r,
      };
      for (final r in adapter.requests) {
        final template = _paths.keys.firstWhere(
          (k) => RegExp(
            '^${k.replaceFirst('/v1', '').replaceAll(RegExp(r'\{\w+\}'), '[^/]+')}\$',
          ).hasMatch(r.path),
          orElse: () => fail('Hợp đồng không có ${r.method} ${r.path}'),
        );
        expect(_paths[template], contains(r.method.toLowerCase()));
      }
      final rec = byPath['POST /invoices/inv1/payments']!;
      final recBody = _body('/v1/invoices/{id}/payments');
      expect(rec.headers['Idempotency-Key'], 'k5');
      expect(rec.data, {
        'amount': 500000,
        'method': 'cash',
        'paidOn': '2027-01-05',
        'note': 'Đóng tiền mặt',
      });
      expect(_required(recBody), isNot(contains('paidOn')));
      expect(_props(recBody), containsAll((rec.data as Map).keys));
      final voidReq = byPath['POST /payments/pay1/void']!;
      expect(voidReq.headers['Idempotency-Key'], 'k6');
      expect(voidReq.data, {'reason': 'Ghi nhầm'});
    });

    test('getPeriod dừng khi gặp trang rỗng dù total còn lớn', () async {
      adapter
        ..periodPages = 5
        ..emptyFrom = 3;
      final d = await repo.getPeriod('per1');
      expect(d.invoices.map((i) => i.id), ['p1', 'p2']);
      expect(adapter.requests, hasLength(3));
    });

    test(
      'getPeriod gộp các trang hóa đơn, pageSize không vượt hợp đồng',
      () async {
        adapter.periodPages = 2;
        final d = await repo.getPeriod('per1');
        expect(d.invoices.map((i) => i.id), ['p1', 'p2']);
        final pageSize =
            ((((_paths['/v1/billing-periods/{id}'] as Map)['get']
                            as Map)['parameters']
                        as List)
                    .cast<Map>()
                    .firstWhere((p) => p['name'] == 'pageSize')['schema']
                as Map)['maximum'];
        for (final r in adapter.requests) {
          expect(r.queryParameters['pageSize'], lessThanOrEqualTo(pageSize));
        }
      },
    );
  });
}
