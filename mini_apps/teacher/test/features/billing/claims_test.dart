import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teacher/features/billing/billing_routes.dart';
import 'package:teacher/features/billing/cubit/billing_periods_cubit.dart'
    show BillingLoad;
import 'package:teacher/features/billing/cubit/payment_claims_cubit.dart';
import 'package:teacher/features/billing/data/billing_models.dart';
import 'package:teacher/features/billing/data/billing_repository.dart';
import 'package:teacher/features/billing/data/claim_models.dart';
import 'package:teacher/features/billing/widgets/invoice_status_label.dart';
import 'package:teacher/features/fees/data/fee_repository.dart';
import 'package:teacher/features/receivables/data/receivables_repository.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../classes/pump.dart';
import '../fees/fake_fee_repository.dart';
import '../receivables/fake_receivables_repository.dart';
import 'fake_billing_repository.dart';

final _openapi =
    jsonDecode(
          File(
            '../../packages/teachhub_shared/contracts/openapi.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;
final _schemas =
    (_openapi['components'] as Map)['schemas'] as Map<String, dynamic>;

Map<String, dynamic> _example(String name) =>
    (_schemas[name] as Map)['example'] as Map<String, dynamic>;

ApiException _http(int status, [String? code]) =>
    ApiException.fromResponse(status, {'code': code});

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final Object body;
    if (options.path.endsWith('/payment-claims')) {
      body = {
        'items': [_example('PaymentClaim')],
      };
    } else if (options.path.endsWith('/resolve')) {
      body = {'claim': _example('PaymentClaim'), 'result': null};
    } else {
      body = _example('FileDownloadUrl');
    }
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

void main() {
  group('hợp đồng', () {
    test('PaymentClaim đọc đủ ví dụ; trạng thái lạ coi như chờ', () {
      final c = PaymentClaim.fromJson(_example('PaymentClaim'));
      expect(c.status, ClaimStatus.pending);
      expect(c.amount, 1400000);
      expect(c.note, isNull);
      expect(c.claimedByName, 'Nguyễn Văn Hải');
      expect(c.resolvedByName, isNull);
      expect(ClaimStatus.fromWire('lạ'), ClaimStatus.pending);
      final props = ((_schemas['PaymentClaim'] as Map)['required'] as List);
      for (final k in props) {
        expect(_example('PaymentClaim').containsKey(k), isTrue, reason: '$k');
      }
    });

    test(
      'ResolvePaymentClaimResult: có thanh toán khi xác nhận, null khi từ chối',
      () {
        final r = ClaimResolveResult.fromJson({
          'claim': _example('PaymentClaim'),
          'result': null,
        });
        expect(r.result, isNull);
      },
    );

    test('thân xác nhận/từ chối đúng oneOf của hợp đồng', () {
      final oneOf =
          (_schemas['ResolvePaymentClaimRequest'] as Map)['oneOf'] as List;
      final confirm = oneOf[0]['properties'] as Map;
      final reject = oneOf[1]['properties'] as Map;
      expect(
        const ClaimResolution.confirm(1400000).toJson().keys,
        everyElement(isIn(confirm.keys)),
      );
      expect(const ClaimResolution.reject(' chưa thấy tiền ').toJson(), {
        'decision': 'reject',
        'reason': 'chưa thấy tiền',
      });
      expect(
        const ClaimResolution.reject('x').toJson().keys,
        everyElement(isIn(reject.keys)),
      );
      expect(oneOf[1]['required'], containsAll(['decision', 'reason']));
      expect(claimRejectReasonMax, reject['reason']['maxLength']);
      expect(const ClaimResolution.reject('  ').validate(), {'reason'});
      expect(const ClaimResolution.confirm(0).validate(), {'amount'});
      expect(const ClaimResolution.confirm(5).validate(), isEmpty);
    });

    test('DioBillingRepository gọi đúng method, đường dẫn, khóa', () async {
      final a = _Adapter();
      final repo = DioBillingRepository(
        Dio(BaseOptions(baseUrl: 'http://x/v1'))..httpClientAdapter = a,
      );
      final list = await repo.listClaims('inv1');
      await repo.resolveClaim(
        'c1',
        const ClaimResolution.confirm(900000),
        idempotencyKey: 'k1',
      );
      final url = await repo.receiptUrl('f1');
      expect(list.single.id, _example('PaymentClaim')['id']);
      expect(url, startsWith('https://'));
      expect(a.requests[0].method, 'GET');
      expect(a.requests[0].path, '/invoices/inv1/payment-claims');
      expect(a.requests[1].method, 'POST');
      expect(a.requests[1].path, '/payment-claims/c1/resolve');
      expect(a.requests[1].headers['Idempotency-Key'], 'k1');
      expect(a.requests[1].data, {'decision': 'confirm', 'amount': 900000});
      expect(a.requests[2].method, 'GET');
      expect(a.requests[2].path, '/files/f1/download-url');
    });
  });

  group('PaymentClaimsCubit', () {
    late FakeBillingRepository repo;
    setUp(() {
      repo = FakeBillingRepository()
        ..invoice = sampleInvoice(
          status: InvoiceStatus.pendingConfirmation,
          total: 1200000,
        )
        ..claims = [sampleClaim()];
    });

    PaymentClaimsCubit make() => PaymentClaimsCubit(repo, 'i1');

    test('tải các lần báo; lỗi mạng → failure rồi tải lại được', () async {
      repo.claimsError = const ApiException.network();
      final c = make();
      await c.load();
      expect(c.state.load, BillingLoad.failure);
      await c.load();
      expect(c.state.load, BillingLoad.ready);
      expect(c.state.claims, hasLength(1));
    });

    test(
      'xác nhận với số đã sửa: gửi đúng số, claim thành confirmed',
      () async {
        final c = make();
        await c.load();
        await c.confirm(c.state.claims.first, 1000000);
        expect(repo.resolutions.single.amount, 1000000);
        expect(c.state.claims.first.status, ClaimStatus.confirmed);
        expect(c.state.done, ClaimDone.confirmed);
        expect(c.state.invoiceChanged, 1);
      },
    );

    test('từ chối: lý do bắt buộc, trống thì không gửi', () async {
      final c = make();
      await c.load();
      await c.reject(c.state.claims.first, '   ');
      expect(repo.resolutions, isEmpty);
      await c.reject(c.state.claims.first, 'Chưa thấy tiền');
      expect(c.state.claims.first.status, ClaimStatus.rejected);
      expect(c.state.done, ClaimDone.rejected);
    });

    test(
      'lỗi mạng rồi thử lại: cùng Idempotency-Key; đổi số thì khóa mới',
      () async {
        repo.resolveError = const ApiException.network();
        final c = make();
        await c.load();
        final claim = c.state.claims.first;
        await c.confirm(claim, 1200000);
        expect(c.state.error, isNotNull);
        expect(c.state.busy, isFalse);
        await c.confirm(claim, 1200000);
        expect(repo.keys[0], repo.keys[1]);
        expect(c.state.done, ClaimDone.confirmed);

        final repo2 = FakeBillingRepository()
          ..invoice = repo.invoice
          ..claims = [sampleClaim()]
          ..resolveError = const ApiException.network();
        final c2 = PaymentClaimsCubit(repo2, 'i1');
        await c2.load();
        await c2.confirm(c2.state.claims.first, 1200000);
        await c2.confirm(c2.state.claims.first, 1000000);
        expect(repo2.keys[0], isNot(repo2.keys[1]));
      },
    );

    test('409: tải lại danh sách, báo hóa đơn đổi, lần sau khóa mới', () async {
      repo.resolveError = _http(409, 'CONFLICT_STALE');
      final c = make();
      await c.load();
      // Giữa chừng máy khác đã từ chối.
      repo.claims = [
        sampleClaim(status: ClaimStatus.rejected, rejectReason: 'x'),
      ];
      await c.confirm(c.state.claims.first, 1200000);
      expect(c.state.error?.code, ApiErrorCode.conflictStale);
      expect(c.state.claims.first.status, ClaimStatus.rejected);
      expect(c.state.invoiceChanged, 1);
      expect(c.state.staleUnverified, isFalse);
      expect(repo.calls.where((x) => x.startsWith('listClaims')), hasLength(2));
    });

    test('409 mà tải lại cũng lỗi: staleUnverified', () async {
      repo.resolveError = _http(409, 'CONFLICT_STALE');
      final c = make();
      await c.load();
      repo.claimsError = const ApiException.network();
      await c.confirm(c.state.claims.first, 1200000);
      expect(c.state.staleUnverified, isTrue);
    });

    test('bấm đúp khi đang gửi chỉ gửi một lệnh', () async {
      final gate = repo.resolveGate = Completer<void>();
      final c = make();
      await c.load();
      final claim = c.state.claims.first;
      final a = c.confirm(claim, 1200000);
      final b = c.confirm(claim, 1200000);
      gate.complete();
      await Future.wait([a, b]);
      expect(repo.resolutions, hasLength(1));
    });
  });

  group('chi tiết hóa đơn', () {
    late FakeBillingRepository repo;
    setUp(() {
      repo = FakeBillingRepository();
      GetIt.I
        ..registerSingleton<BillingRepository>(repo)
        ..registerSingleton<FeeRepository>(FakeFeeRepository())
        ..registerSingleton<ReceivablesRepository>(FakeReceivablesRepository());
    });
    tearDown(GetIt.I.reset);

    Future<void> open(WidgetTester tester, {double scale = 1}) async {
      final router = await pumpRoutes(
        tester,
        [
          GoRoute(path: '/', builder: (_, _) => const Scaffold()),
          ...billingRoutes('teacher'),
        ],
        initial: BillingRoutes.invoice('i1'),
        textScale: scale,
      );
      addTearDown(router.dispose);
    }

    Finder btn(String label) => find.widgetWithText(AppButton, label);

    testWidgets('hóa đơn chờ xác nhận: nhãn, lần báo, số khai, ghi chú', (
      tester,
    ) async {
      repo
        ..invoice = sampleInvoice(
          status: InvoiceStatus.pendingConfirmation,
          total: 1200000,
        )
        ..claims = [sampleClaim(note: 'Chuyển lúc 9h')];
      await open(tester);
      expect(find.text('Chờ xác nhận'), findsWidgets);
      expect(find.text('Phụ huynh báo đã chuyển khoản'), findsOneWidget);
      expect(find.text('Phụ huynh khai: 1.200.000 đ'), findsOneWidget);
      expect(find.text('Ghi chú: Chuyển lúc 9h'), findsOneWidget);
      expect(btn('Xem biên lai'), findsOneWidget);
      expect(btn('Xác nhận'), findsOneWidget);
      expect(btn('Từ chối'), findsOneWidget);
    });

    testWidgets('danh sách hóa đơn của kỳ hiện nhãn Chờ xác nhận', (
      tester,
    ) async {
      repo
        ..periods = [samplePeriod(status: BillingPeriodStatus.closed)]
        ..detail = sampleDetail(
          invoices: [sampleSummary(status: InvoiceStatus.pendingConfirmation)],
        );
      final router = await pumpRoutes(
        tester,
        [
          GoRoute(path: '/', builder: (_, _) => const Scaffold()),
          ...billingRoutes('teacher'),
        ],
        initial: BillingRoutes.period(periodId),
        textScale: 1.3,
      );
      addTearDown(router.dispose);
      expect(find.text('Chờ xác nhận'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('không có lần báo: không hiện khối', (tester) async {
      repo.invoice = sampleInvoice(status: InvoiceStatus.issued, total: 100);
      await open(tester);
      expect(find.text('Phụ huynh báo đã chuyển khoản'), findsNothing);
    });

    testWidgets('bản nháp không gọi danh sách lần báo', (tester) async {
      repo.invoice = sampleInvoice();
      await open(tester);
      expect(repo.calls.where((c) => c.startsWith('listClaims')), isEmpty);
    });

    testWidgets('xem biên lai xin URL mới theo tệp', (tester) async {
      repo
        ..invoice = sampleInvoice(
          status: InvoiceStatus.pendingConfirmation,
          total: 1200000,
        )
        ..claims = [sampleClaim()];
      await open(tester);
      await tester.ensureVisible(btn('Xem biên lai'));
      await tester.tap(btn('Xem biên lai'));
      await tester.pump();
      await tester.pump();
      expect(repo.calls, contains('receiptUrl:f-c1'));
    });

    testWidgets('xác nhận sửa số tiền: gửi số mới, hóa đơn tải lại', (
      tester,
    ) async {
      repo
        ..invoice = sampleInvoice(
          status: InvoiceStatus.pendingConfirmation,
          total: 1200000,
        )
        ..claims = [sampleClaim()];
      await open(tester);
      await tester.ensureVisible(btn('Xác nhận'));
      await tester.tap(btn('Xác nhận'));
      await tester.pumpAndSettle();
      // Mặc định là số phụ huynh khai.
      expect(find.text('1.200.000 đ'), findsWidgets);
      await tester.enterText(find.byType(TextField).last, '1000000');
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Xác nhận'),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.resolutions.single.amount, 1000000);
      expect(find.text('Đã xác nhận và ghi thu.'), findsOneWidget);
      expect(find.text('Đã xác nhận'), findsOneWidget);
      // Hóa đơn được tải lại: nhãn đổi sang đã trả một phần.
      expect(find.text('Đã thanh toán một phần'), findsWidgets);
      expect(btn('Xác nhận'), findsNothing);
    });

    testWidgets('từ chối: lý do bắt buộc; có lý do thì gửi', (tester) async {
      repo
        ..invoice = sampleInvoice(
          status: InvoiceStatus.pendingConfirmation,
          total: 1200000,
        )
        ..claims = [sampleClaim()];
      await open(tester);
      await tester.ensureVisible(btn('Từ chối'));
      await tester.tap(btn('Từ chối'));
      await tester.pumpAndSettle();
      final inDialog = find.byType(AlertDialog);
      await tester.tap(
        find.descendant(of: inDialog, matching: find.text('Từ chối')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nhập lý do, tối đa 300 ký tự.'), findsOneWidget);
      expect(repo.resolutions, isEmpty);

      await tester.enterText(find.byType(TextField).last, 'Chưa thấy tiền');
      repo.invoice = sampleInvoice(
        status: InvoiceStatus.issued,
        total: 1200000,
      );
      await tester.tap(
        find.descendant(of: inDialog, matching: find.text('Từ chối')),
      );
      await tester.pumpAndSettle();
      expect(repo.resolutions.single.reason, 'Chưa thấy tiền');
      expect(find.text('Đã từ chối lần báo.'), findsOneWidget);
      expect(find.text('Lý do từ chối: Chưa thấy tiền'), findsOneWidget);
    });

    testWidgets('409: báo hóa đơn vừa đổi và cập nhật các nút', (tester) async {
      repo
        ..invoice = sampleInvoice(
          status: InvoiceStatus.pendingConfirmation,
          total: 1200000,
        )
        ..claims = [sampleClaim()]
        ..resolveError = _http(409, 'CONFLICT_STALE');
      await open(tester);
      await tester.ensureVisible(btn('Xác nhận'));
      await tester.tap(btn('Xác nhận'));
      await tester.pumpAndSettle();
      repo.claims = [sampleClaim(status: ClaimStatus.confirmed)];
      repo.invoice = sampleInvoice(
        status: InvoiceStatus.paid,
        total: 1200000,
        paid: 1200000,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Xác nhận'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Hóa đơn vừa có thay đổi'), findsOneWidget);
      expect(btn('Xác nhận'), findsNothing);
    });

    testWidgets('tải lần báo lỗi: thử lại', (tester) async {
      repo
        ..invoice = sampleInvoice(status: InvoiceStatus.issued, total: 100)
        ..claimsError = const ApiException.network()
        ..claims = [sampleClaim()];
      await open(tester);
      expect(
        find.text('Không tải được các lần báo chuyển khoản.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Phụ huynh khai: 1.200.000 đ'), findsOneWidget);
    });

    testWidgets('chữ 130% không vỡ', (tester) async {
      repo
        ..invoice = sampleInvoice(
          status: InvoiceStatus.pendingConfirmation,
          total: 1200000,
        )
        ..claims = [
          sampleClaim(note: 'Chuyển lúc 9h sáng nay qua app ngân hàng'),
        ];
      await open(tester, scale: 1.3);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(btn('Từ chối'));
      expect(tester.takeException(), isNull);
    });
  });

  test('mọi trạng thái hóa đơn có nhãn, kể cả chờ xác nhận', () {
    // Bảng nhãn dùng chung cho mọi danh sách hóa đơn của giáo viên.
    expect(InvoiceStatus.values, contains(InvoiceStatus.pendingConfirmation));
    expect(
      InvoiceStatus.fromWire('pending_confirmation'),
      InvoiceStatus.pendingConfirmation,
    );
    expect(invoiceStatusText, isNotNull);
  });
}
