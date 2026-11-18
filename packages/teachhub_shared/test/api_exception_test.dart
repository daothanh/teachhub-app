import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

void main() {
  group('ApiErrorCode — khớp contracts/error_codes.json', () {
    final contract =
        (jsonDecode(File('contracts/error_codes.json').readAsStringSync())
            as Map<String, dynamic>);

    test('mọi mã trong hợp đồng có trong enum, đúng HTTP status', () {
      for (final MapEntry(key: wire, value: def) in contract.entries) {
        final code = ApiErrorCode.fromWire(wire);
        expect(code, isNot(ApiErrorCode.unknown), reason: wire);
        expect(code.wire, wire);
        expect(code.http, (def as Map)['http'], reason: wire);
      }
      // Không có mã thừa ngoài hợp đồng (trừ unknown).
      expect(ApiErrorCode.values.length - 1, contract.length);
    });

    test('mã lạ hoặc thiếu → unknown', () {
      expect(
        ApiErrorCode.fromWire('NEW_CODE_FROM_SERVER'),
        ApiErrorCode.unknown,
      );
      expect(ApiErrorCode.fromWire(null), ApiErrorCode.unknown);
    });

    test(
      'bản sinh không lệch hợp đồng (dart run tool/gen_error_codes.dart --check)',
      () {
        final r = Process.runSync('dart', [
          'run',
          'tool/gen_error_codes.dart',
          '--check',
          'contracts/error_codes.json',
        ]);
        expect(r.exitCode, 0, reason: '${r.stderr}');
      },
    );
  });

  group('ApiException.fromResponse', () {
    test('đọc đủ code, details, errors, requestId', () {
      final e = ApiException.fromResponse(422, {
        'code': 'VALIDATION_FAILED',
        'message': 'Dữ liệu chưa hợp lệ.',
        'errors': {
          'dates.end': ['Sai ngày.'],
          '_': ['Thiếu dữ liệu.'],
        },
        'requestId': 'req-1',
      });
      expect(e.code, ApiErrorCode.validationFailed);
      expect(e.kind, ApiErrorKind.validation);
      expect(e.fieldErrors, {
        'dates.end': ['Sai ngày.'],
        '_': ['Thiếu dữ liệu.'],
      });
      expect(e.requestId, 'req-1');
    });

    test('nhóm lỗi theo HTTP status (spec §5.6)', () {
      final kinds = {
        400: ApiErrorKind.badRequest,
        401: ApiErrorKind.unauthenticated,
        402: ApiErrorKind.paymentRequired,
        403: ApiErrorKind.forbidden,
        404: ApiErrorKind.notFound,
        409: ApiErrorKind.conflict,
        410: ApiErrorKind.gone,
        422: ApiErrorKind.validation,
        429: ApiErrorKind.rateLimited,
        500: ApiErrorKind.server,
        503: ApiErrorKind.server,
      };
      for (final MapEntry(key: status, value: kind) in kinds.entries) {
        expect(
          ApiException.fromResponse(status, null).kind,
          kind,
          reason: '$status',
        );
      }
      expect(const ApiException.network().kind, ApiErrorKind.network);
    });

    test('body không đúng định dạng vẫn ra lỗi theo status, code unknown', () {
      final e = ApiException.fromResponse(502, '<html>Bad gateway</html>');
      expect(e.code, ApiErrorCode.unknown);
      expect(e.kind, ApiErrorKind.server);
      expect(e.details, isEmpty);
    });

    test('retryAfter: details.retryAfterSec trước, rồi header Retry-After', () {
      expect(
        ApiException.fromResponse(429, {
          'code': 'OTP_LOCKED',
          'details': {'retryAfterSec': 900},
        }, retryAfterHeader: '30').retryAfter,
        const Duration(minutes: 15),
      );
      expect(
        ApiException.fromResponse(429, {
          'code': 'RATE_LIMITED',
        }, retryAfterHeader: '30').retryAfter,
        const Duration(seconds: 30),
      );
      expect(ApiException.fromResponse(401, {}).retryAfter, isNull);
    });

    test(
      'chỉ tự thử lại khi mất mạng, 5xx, 429, 409 IDEMPOTENCY_IN_PROGRESS',
      () {
        expect(const ApiException.network().retryable, isTrue);
        expect(ApiException.fromResponse(503, null).retryable, isTrue);
        expect(
          ApiException.fromResponse(429, {'code': 'RATE_LIMITED'}).retryable,
          isTrue,
        );
        expect(
          ApiException.fromResponse(409, {
            'code': 'IDEMPOTENCY_IN_PROGRESS',
          }).retryable,
          isTrue,
        );
        expect(
          ApiException.fromResponse(409, {'code': 'CONFLICT_STALE'}).retryable,
          isFalse,
        );
        expect(
          ApiException.fromResponse(422, {
            'code': 'VALIDATION_FAILED',
          }).retryable,
          isFalse,
        );
      },
    );
  });

  test('Paginated.fromJson theo { items, total, page, pageSize }', () {
    final p = Paginated<String>.fromJson({
      'items': [
        {'name': 'Nam'},
        {'name': 'Chi'},
      ],
      'total': 41,
      'page': 2,
      'pageSize': 20,
    }, (j) => j['name'] as String);
    expect(p.items, ['Nam', 'Chi']);
    expect(p.hasMore, isTrue);
    expect(
      Paginated<String>.fromJson({
        'items': [],
        'total': 41,
        'page': 3,
        'pageSize': 20,
      }, (j) => '').hasMore,
      isFalse,
    );
  });
}
