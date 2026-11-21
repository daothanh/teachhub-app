import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/features/billing/cubit/billing_period_cubit.dart';
import 'package:teacher/features/billing/cubit/billing_periods_cubit.dart';
import 'package:teacher/features/billing/cubit/invoice_cubit.dart';
import 'package:teacher/features/billing/data/billing_models.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../fees/fake_fee_repository.dart' show apiErr;
import 'fake_billing_repository.dart';

void main() {
  late FakeBillingRepository repo;
  setUp(() => repo = FakeBillingRepository());

  group('BillingPeriodsCubit (AC-1)', () {
    test('tải danh sách kỳ; rỗng vẫn là ready', () async {
      repo.periods = [samplePeriod()];
      final c = BillingPeriodsCubit(repo);
      await c.load();
      expect(c.state.load, BillingLoad.ready);
      expect(c.state.periods.single.draftCount, 3);

      repo.periods = [];
      await c.load();
      expect(c.state.load, BillingLoad.ready);
      expect(c.state.periods, isEmpty);
      await c.close();
    });

    test('lỗi mạng → failure, thử lại tải được', () async {
      repo.listError = const ApiException.network();
      final c = BillingPeriodsCubit(repo);
      await c.load();
      expect(c.state.load, BillingLoad.failure);
      expect(c.state.error!.kind, ApiErrorKind.network);

      repo
        ..listError = null
        ..periods = [samplePeriod()];
      await c.load();
      expect(c.state.load, BillingLoad.ready);
      await c.close();
    });
  });

  group('BillingPeriodCubit (AC-1, AC-4, AC-5)', () {
    // `result` là trạng thái một lần (tải lại kỳ xóa nó), nên ghi lại qua stream.
    late List<IssueResult> results;
    BillingPeriodCubit make() {
      results = [];
      return BillingPeriodCubit(repo, periodId)
        ..stream.listen((s) {
          if (s.result != null) results.add(s.result!);
        });
    }

    test('load: bản nháp có tiền và bản nháp 0 đ tách đúng', () async {
      repo.detail = sampleDetail();
      final c = make();
      await c.load();
      final d = c.state.detail!;
      expect(d.payableDrafts.map((i) => i.id), ['i1', 'i2']);
      expect(d.payableTotal, 2700000);
      expect(d.zeroDraftCount, 1);
      await c.close();
    });

    test('chốt tất cả: invoiceIds null, báo kết quả, tải lại kỳ', () async {
      repo.detail = sampleDetail();
      final c = make();
      await c.load();
      await c.issueAll();
      expect(repo.issuedIds, [null]);
      await pumpEventQueue();
      expect(results.single.issuedCount, 2);
      expect(c.state.issuing, isFalse);
      expect(repo.calls.where((x) => x.startsWith('getPeriod')), hasLength(2));
      await c.close();
    });

    test('chốt từng hóa đơn gửi đúng id', () async {
      repo.detail = sampleDetail();
      final c = make();
      await c.load();
      await c.issueOne('i2');
      expect(repo.issuedIds, [
        ['i2'],
      ]);
      await c.close();
    });

    test('chặn double-tap: bấm lúc đang gửi chỉ gọi API một lần', () async {
      repo.detail = sampleDetail();
      final c = make();
      await c.load();
      final a = c.issueAll();
      final b = c.issueAll();
      await Future.wait([a, b]);
      expect(repo.calls.where((x) => x.startsWith('issue')), hasLength(1));
      await c.close();
    });

    test(
      'mạng chập chờn: thử lại giữ Idempotency-Key, xong thì đổi khóa',
      () async {
        repo.detail = sampleDetail();
        final c = make();
        await c.load();
        repo.issueError = const ApiException.network();
        await c.issueAll();
        expect(c.state.error!.retryable, isTrue);
        await pumpEventQueue();
        expect(results, isEmpty);
        await c.issueAll();
        expect(repo.keys[0], repo.keys[1]);
        await pumpEventQueue();
        expect(results, hasLength(1));
        // Lần chốt sau khi đã thành công dùng khóa mới.
        await c.issueAll();
        expect(repo.keys[2], isNot(repo.keys[0]));
        await c.close();
      },
    );

    test('lỗi không thử lại được (409) → khóa mới ở lần sau', () async {
      repo.detail = sampleDetail();
      final c = make();
      await c.load();
      repo.issueError = apiErr(ApiErrorCode.conflictStale);
      await c.issueAll();
      await c.issueAll();
      expect(repo.keys[0], isNot(repo.keys[1]));
      await c.close();
    });

    test(
      'PAYOUT_ACCOUNT_MISSING: báo lỗi, không có kết quả; chốt lại được',
      () async {
        repo.detail = sampleDetail();
        final c = make();
        await c.load();
        repo.issueError = apiErr(ApiErrorCode.payoutAccountMissing);
        await c.issueAll();
        expect(c.state.error!.code, ApiErrorCode.payoutAccountMissing);
        expect(c.state.issuing, isFalse);
        c.clearError();
        expect(c.state.error, isNull);
        await c.issueAll();
        await pumpEventQueue();
        expect(results.single.issuedCount, 2);
        await c.close();
      },
    );

    test(
      'chốt xong nhưng tải lại kỳ lỗi → vẫn báo đã gửi, giữ danh sách',
      () async {
        repo.detail = sampleDetail();
        final c = make();
        await c.load();
        repo.periodError = const ApiException.network();
        await c.issueAll();
        await pumpEventQueue();
        expect(results.single.issuedCount, 2);
        expect(c.state.error, isNull);
        expect(c.state.detail, isNotNull);
        await c.close();
      },
    );

    test('tải lỗi → failure', () async {
      repo.periodError = const ApiException.network();
      final c = make();
      await c.load();
      expect(c.state.load, BillingLoad.failure);
      await c.close();
    });
  });

  group('InvoiceCubit', () {
    InvoiceCubit make() => InvoiceCubit(repo, 'i1');

    test('load: đọc hóa đơn; lỗi → failure', () async {
      repo.invoice = sampleInvoice();
      final c = make();
      await c.load();
      expect(c.state.invoice!.totalAmount, 150000);
      repo.invoiceError = apiErr(ApiErrorCode.notFound);
      await c.load();
      expect(c.state.load, BillingLoad.failure);
      await c.close();
    });

    test('điều chỉnh: thiếu lý do → lỗi tại trường, không gọi API', () async {
      repo.invoice = sampleInvoice();
      final c = make();
      await c.load();
      await c.addAdjustment(
        const AdjustmentInput(amount: -50000, description: 'x', reason: ' '),
      );
      expect(c.state.clientErrors.keys, ['adjustmentReason']);
      expect(repo.adjustments, isEmpty);
      await c.addAdjustment(
        const AdjustmentInput(amount: 0, description: '', reason: 'r'),
      );
      expect(c.state.clientErrors.keys, ['amount', 'description']);
      await c.close();
    });

    test('điều chỉnh: tổng lấy từ phản hồi server, có khóa và done', () async {
      repo.invoice = sampleInvoice();
      final c = make();
      await c.load();
      await c.addAdjustment(
        const AdjustmentInput(
          amount: -100000,
          description: 'Giảm buổi học thử',
          reason: 'Đã thỏa thuận',
        ),
      );
      expect(c.state.done, InvoiceDone.adjusted);
      expect(c.state.invoice!.totalAmount, 50000);
      expect(
        c.state.invoice!.otherLines.single.adjustmentReason,
        'Đã thỏa thuận',
      );
      expect(repo.keys, hasLength(1));
      expect(c.state.busy, isFalse);
      await c.close();
    });

    test('điều chỉnh: 409 INVOICE_IMMUTABLE → lỗi chung, không done', () async {
      repo.invoice = sampleInvoice();
      final c = make();
      await c.load();
      repo.adjustError = apiErr(ApiErrorCode.invoiceImmutable);
      await c.addAdjustment(
        const AdjustmentInput(amount: 1000, description: 'd', reason: 'r'),
      );
      expect(c.state.error!.code, ApiErrorCode.invoiceImmutable);
      expect(c.state.done, isNull);
      expect(c.state.busy, isFalse);
      await c.close();
    });

    test('điều chỉnh: 422 theo trường vào đúng trường', () async {
      repo.invoice = sampleInvoice();
      final c = make();
      await c.load();
      repo.adjustError = fieldErr({
        'amount': ['Số tiền không hợp lệ'],
      });
      await c.addAdjustment(
        const AdjustmentInput(amount: 1000, description: 'd', reason: 'r'),
      );
      expect(c.state.serverErrors['amount'], ['Số tiền không hợp lệ']);
      expect(c.state.error, isNull);
      await c.close();
    });

    test('điều chỉnh: mạng lỗi rồi thử lại cùng nội dung giữ khóa', () async {
      repo.invoice = sampleInvoice();
      final c = make();
      await c.load();
      const input = AdjustmentInput(
        amount: 1000,
        description: 'd',
        reason: 'r',
      );
      repo.adjustError = const ApiException.network();
      await c.addAdjustment(input);
      await c.addAdjustment(input);
      expect(repo.keys[0], repo.keys[1]);
      expect(c.state.done, InvoiceDone.adjusted);
      await c.close();
    });

    test('hủy hóa đơn có lý do → trạng thái void', () async {
      repo.invoice = sampleInvoice(status: InvoiceStatus.issued);
      final c = make();
      await c.load();
      await c.voidInvoice(' Sai số buổi ');
      expect(repo.calls.last, 'void:i1: Sai số buổi ');
      expect(c.state.invoice!.status, InvoiceStatus.voided);
      expect(c.state.done, InvoiceDone.voided);
      await c.close();
    });

    test('hủy: 409 CONFLICT_STALE → báo lỗi, hóa đơn giữ nguyên', () async {
      repo.invoice = sampleInvoice(status: InvoiceStatus.issued);
      final c = make();
      await c.load();
      repo.voidError = apiErr(ApiErrorCode.conflictStale);
      await c.voidInvoice('lý do');
      expect(c.state.voidError!.code, ApiErrorCode.conflictStale);
      expect(c.state.invoice!.status, InvoiceStatus.issued);
      await c.close();
    });

    test('hủy lúc đang bận chỉ gọi một lần', () async {
      repo.invoice = sampleInvoice(status: InvoiceStatus.issued);
      final c = make();
      await c.load();
      await Future.wait([c.voidInvoice('a'), c.voidInvoice('a')]);
      expect(repo.calls.where((x) => x.startsWith('void')), hasLength(1));
      await c.close();
    });
  });

  test('model: giá trị lạ theo hợp đồng', () {
    expect(InvoiceStatus.fromWire('whatever'), InvoiceStatus.issued);
    expect(InvoiceLineKind.fromWire('whatever'), InvoiceLineKind.monthly);
    expect(BillingPeriodStatus.fromWire(null), BillingPeriodStatus.drafting);
    expect(formatSignedVnd(-150000), '−150.000 đ');
    expect(formatSignedVnd(150000, plus: true), '+150.000 đ');
    expect(formatSignedVnd(0, plus: true), '0 đ');
    expect(formatIsoDate('2026-11-01'), '01/11/2026');
  });
}
