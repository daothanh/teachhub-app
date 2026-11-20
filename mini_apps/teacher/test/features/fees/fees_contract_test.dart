import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/features/fees/data/fee_models.dart';
import 'package:teacher/features/fees/data/fee_repository.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

/// Đối chiếu client học phí với `contracts/openapi.json` (Sprint 5).
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

Map<String, dynamic> _op(String path, String method) =>
    (_paths[path] as Map)[method] as Map<String, dynamic>;

Map<String, dynamic> _body(String path, String method) {
  final schema =
      (((_op(path, method)['requestBody'] as Map)['content']
                  as Map)['application/json']
              as Map)['schema']
          as Map<String, dynamic>;
  final ref = schema['\$ref'] as String?;
  return ref == null ? schema : _schemas[ref.split('/').last]!;
}

Set<String> _props(Map<String, dynamic> s) =>
    (s['properties'] as Map).keys.cast<String>().toSet();

/// Ghi lại request, trả phản hồi tối thiểu hợp lệ.
class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final Object? body = switch ((options.method, options.path)) {
      ('PUT', _) => {
        'enrollmentId': 'e',
        'studentId': 's',
        'classId': 'c',
        'feeOverride': null,
      },
      ('GET', '/payout-accounts') => {'items': []},
      ('GET', '/auth/me') => {'email': 'co.lan@example.com'},
      ('POST', '/payout-accounts') || ('PATCH', _) => {
        'id': 'a1',
        'bankBin': '970436',
        'accountNoMasked': '******6789',
        'accountName': 'A',
        'isPrimary': true,
        'createdAt': '2027-01-20T09:30:00+07:00',
      },
      _ => null,
    };
    final status = body == null ? 204 : 200;
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'PayoutAccount: fromJson đọc đúng trường (số đã che, không số đầy đủ)',
    () {
      final schema = _schemas['PayoutAccount']!;
      expect(
        _props(schema),
        containsAll([
          'id',
          'bankBin',
          'accountNoMasked',
          'accountName',
          'isPrimary',
        ]),
      );
      expect(_props(schema), isNot(contains('accountNo')));
    },
  );

  test('FeeDiscount: hai nhánh percent/amount khớp mô hình', () {
    final branches = (_schemas['FeeDiscount']!['oneOf'] as List)
        .cast<Map<String, dynamic>>();
    expect(branches.map(_props), [
      {'kind', 'description', 'percent'},
      {'kind', 'description', 'amount'},
    ]);
    const p = FeeDiscount(
      kind: FeeDiscountKind.percent,
      description: 'Con thứ hai',
      value: 10,
    );
    const a = FeeDiscount(
      kind: FeeDiscountKind.amount,
      description: 'Hỗ trợ',
      value: 50000,
    );
    expect(p.toJson().keys.toSet(), _props(branches[0]));
    expect(a.toJson().keys.toSet(), _props(branches[1]));
    expect(FeeDiscount.fromJson(a.toJson()), a);
    final max = (branches[0]['properties'] as Map)['percent'] as Map;
    expect([max['minimum'], max['maximum']], [1, 100]);
  });

  test('giới hạn kiểm tra ở máy khớp hợp đồng', () {
    final fee = _body('/v1/enrollments/{id}/fee-override', 'put');
    final props = (fee['properties'] as Map).cast<String, Map>();
    expect(props['discounts']!['maxItems'], feeDiscountsMax);
    expect(props['installments']!['maximum'], feeInstallmentsMax);
    final cls = (_body('/v1/classes/{id}', 'patch')['properties'] as Map)
        .cast<String, Map>();
    expect(cls['feeAmount']!['maximum'], feeAmountMax);
    final pa = _body('/v1/payout-accounts', 'post');
    expect(
      (pa['required'] as List),
      containsAll(['bankBin', 'accountNo', 'accountName', 'otpCode']),
    );
    expect(payoutAccountsMax, 5);
  });

  test('enum FeeType khớp hợp đồng', () {
    expect(FeeType.values.map((e) => e.wire), _schemas['FeeType']!['enum']);
  });

  test('purpose payout_account có trong hợp đồng OTP', () {
    final purpose =
        (_body('/v1/auth/otp/send', 'post')['properties'] as Map)['purpose']
            as Map;
    expect(purpose['enum'], contains('payout_account'));
  });

  group('DioFeeRepository', () {
    late _Adapter adapter;
    late DioFeeRepository repo;
    setUp(() {
      adapter = _Adapter();
      repo = DioFeeRepository(
        Dio(BaseOptions(baseUrl: 'http://x/v1'))..httpClientAdapter = adapter,
      );
    });

    test(
      'mọi lệnh gọi đúng method, đường dẫn, khóa body và có Idempotency-Key',
      () async {
        await repo.putFeeOverride(
          'e1',
          const FeeOverride(
            feeAmount: 1,
            discounts: [
              FeeDiscount(
                kind: FeeDiscountKind.amount,
                description: 'x',
                value: 1,
              ),
            ],
          ),
          idempotencyKey: 'k1',
        );
        await repo.putFeeOverride(
          'e1',
          const FeeOverride(),
          idempotencyKey: 'k2',
        );
        await repo.listPayoutAccounts();
        await repo.sendPayoutOtp();
        await repo.createPayoutAccount(
          const PayoutAccountInput(
            bankBin: '970436',
            accountNo: '0123456789',
            accountName: 'A',
          ),
          otpCode: '123456',
          idempotencyKey: 'k3',
        );
        await repo.updatePayoutAccount(
          'a1',
          makePrimary: true,
          idempotencyKey: 'k4',
        );
        await repo.deletePayoutAccount('a1', idempotencyKey: 'k5');

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
        // Ghi tiền: khóa idempotency luôn có (PUT/DELETE interceptor không tự gắn).
        for (final r in adapter.requests.where(
          (r) =>
              {'PUT', 'DELETE', 'PATCH'}.contains(r.method) ||
              (r.method == 'POST' && r.path == '/payout-accounts'),
        )) {
          expect(r.headers['Idempotency-Key'], isNotNull, reason: r.path);
        }
        final put = adapter.requests.first.data as Map;
        expect(
          put.keys.toSet(),
          _props(_body('/v1/enrollments/{id}/fee-override', 'put')),
        );
        expect(adapter.requests[1].data, <String, dynamic>{});
        final create = byPath['POST /payout-accounts']!.data as Map;
        expect(
          create.keys.toSet(),
          containsAll(['bankBin', 'accountNo', 'accountName', 'otpCode']),
        );
        expect(
          _props(_body('/v1/payout-accounts', 'post')),
          containsAll(create.keys),
        );
        expect(byPath['PATCH /payout-accounts/a1']!.data, {'isPrimary': true});
        final otp = byPath['POST /auth/otp/send']!;
        expect(otp.data, {
          'email': 'co.lan@example.com',
          'purpose': 'payout_account',
        });
        expect(otp.extra['requiresAuth'], isFalse);
      },
    );
  });
}
