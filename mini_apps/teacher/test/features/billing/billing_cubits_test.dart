import 'dart:async';

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

    test('refresh lỗi giữ danh sách đang có', () async {
      repo.periods = [samplePeriod()];
      final c = BillingPeriodsCubit(repo);
      await c.load();
      repo.listError = const ApiException.network();
      await c.refresh();
      expect(c.state.load, BillingLoad.ready);
      expect(c.state.periods, hasLength(1));
      await c.close();
      await c.refresh();
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

    test(
      '409 CONFLICT_STALE → tải lại kỳ, không tự gửi lại, khóa mới',
      () async {
        repo.detail = sampleDetail();
        final c = make();
        await c.load();
        repo.calls.clear();
        repo.detail = sampleDetail(invoices: [sampleSummary(id: 'i9')]);
        repo.issueError = apiErr(ApiErrorCode.conflictStale);
        await c.issueAll();
        expect(c.state.error!.code, ApiErrorCode.conflictStale);
        expect(c.state.issuing, isFalse);
        expect(c.state.detail!.invoices.single.id, 'i9');
        expect(c.state.staleUnverified, isFalse);
        expect(repo.calls, ['issue:$periodId', 'getPeriod:$periodId']);
        await c.issueAll();
        expect(repo.keys[0], isNot(repo.keys[1]));
        await c.close();
      },
    );

    test('409 CONFLICT_STALE mà tải lại kỳ cũng lỗi → chưa xác nhận', () async {
      repo.detail = sampleDetail();
      final c = make();
      await c.load();
      final before = c.state.detail;
      repo.issueError = apiErr(ApiErrorCode.conflictStale);
      repo.periodError = const ApiException.network();
      await c.issueAll();
      expect(c.state.error!.code, ApiErrorCode.conflictStale);
      expect(c.state.staleUnverified, isTrue);
      expect(c.state.detail, before);
      expect(c.state.issuing, isFalse);
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

    test('refresh khi đang chốt: giữ issuing, không mở lại nút', () async {
      repo.detail = sampleDetail();
      final c = make();
      await c.load();
      final gate = repo.issueGate = Completer<void>();
      final issuing = c.issueAll();
      await pumpEventQueue();
      expect(c.state.issuing, isTrue);
      await c.refresh();
      expect(c.state.issuing, isTrue);
      expect(c.state.load, BillingLoad.ready);
      gate.complete();
      await issuing;
      expect(c.state.issuing, isFalse);
      await c.close();
    });

    test('refresh lỗi giữ danh sách, báo lỗi; không hiện vòng tải', () async {
      repo.detail = sampleDetail();
      final c = make();
      await c.load();
      repo.periodError = const ApiException.network();
      await c.refresh();
      expect(c.state.load, BillingLoad.ready);
      expect(c.state.detail, isNotNull);
      expect(c.state.error!.kind, ApiErrorKind.network);
      await c.close();
    });

    test('đã đóng: load/refresh/clearError không ném', () async {
      repo.detail = sampleDetail();
      final c = make();
      await c.close();
      await c.load();
      await c.refresh();
      c.clearError();
    });

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

    test('điều chỉnh: INVOICE_IMMUTABLE tải lại hóa đơn, giữ lỗi', () async {
      repo.invoice = sampleInvoice();
      final c = make();
      await c.load();
      repo
        ..adjustError = apiErr(ApiErrorCode.invoiceImmutable)
        ..invoiceAfterError = sampleInvoice(status: InvoiceStatus.issued);
      await c.addAdjustment(
        const AdjustmentInput(amount: 1000, description: 'd', reason: 'r'),
      );
      expect(c.state.invoice!.status, InvoiceStatus.issued);
      expect(c.state.error!.code, ApiErrorCode.invoiceImmutable);
      expect(repo.calls.where((x) => x.startsWith('getInvoice')), hasLength(2));
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
      // Tải lại hóa đơn, không tự gửi lại; lần bấm sau dùng khóa mới.
      expect(repo.calls, [
        'getInvoice:i1',
        'listPayments:i1',
        'void:i1:lý do',
        'getInvoice:i1',
      ]);
      await c.voidInvoice('lý do');
      expect(repo.keys[0], isNot(repo.keys[1]));
      await c.close();
    });

    test('hủy: 409 mà tải lại hóa đơn cũng lỗi → chưa xác nhận', () async {
      repo.invoice = sampleInvoice(status: InvoiceStatus.issued);
      final c = make();
      await c.load();
      repo.voidError = apiErr(ApiErrorCode.conflictStale);
      repo.invoiceError = const ApiException.network();
      await c.voidInvoice('lý do');
      expect(c.state.voidError!.code, ApiErrorCode.conflictStale);
      expect(c.state.staleUnverified, isTrue);
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

  group('InvoiceCubit thanh toán (US-7.4)', () {
    InvoiceCubit make() =>
        InvoiceCubit(repo, 'i1', now: () => DateTime(2026, 11, 5));
    PaymentInput pay(int amount, {PaymentMethod? method, String? on}) =>
        PaymentInput(
          amount: amount,
          method: method ?? PaymentMethod.bankTransfer,
          paidOn: on ?? '2026-11-05',
        );
    setUp(
      () => repo.invoice = sampleInvoice(
        status: InvoiceStatus.issued,
        total: 1200000,
      ),
    );

    test(
      'load: hóa đơn đã phát hành kèm thanh toán; bản nháp không gọi',
      () async {
        repo.payments = [
          samplePayment(),
          samplePayment(id: 'p0', voided: true),
        ];
        final c = make();
        await c.load();
        expect(c.state.payments.map((p) => p.id), ['p1', 'p0']);
        expect(c.today, '2026-11-05');
        repo.invoice = sampleInvoice();
        repo.calls.clear();
        await c.load();
        expect(repo.calls, ['getInvoice:i1']);
        expect(c.state.payments, isEmpty);
        await c.close();
      },
    );

    test('thu một phần: số liệu lấy từ phản hồi, thanh toán lên đầu', () async {
      final c = make();
      await c.load();
      await c.recordPayment(pay(500000, method: PaymentMethod.cash));
      final s = c.state;
      expect(s.done, InvoiceDone.paymentRecorded);
      expect(s.invoice!.status, InvoiceStatus.partiallyPaid);
      expect(
        [s.invoice!.paidAmount, s.invoice!.remainingAmount],
        [500000, 700000],
      );
      expect(s.invoice!.canRecordPayment, isTrue);
      expect(s.payments.single.method, PaymentMethod.cash);
      expect(repo.paymentInputs.single.toJson(), {
        'amount': 500000,
        'method': 'cash',
        'paidOn': '2026-11-05',
      });
      await c.close();
    });

    test(
      'thu nốt → đã thu đủ, không ghi thêm được; thu thừa vẫn nhận',
      () async {
        final c = make();
        await c.load();
        await c.recordPayment(pay(500000));
        await c.recordPayment(pay(700000));
        expect(c.state.invoice!.status, InvoiceStatus.paid);
        expect(c.state.invoice!.remainingAmount, 0);
        expect(c.state.invoice!.canRecordPayment, isFalse);
        expect(c.state.payments, hasLength(2));

        repo.invoice = sampleInvoice(
          status: InvoiceStatus.issued,
          total: 100000,
        );
        repo.payments = [];
        final over = make();
        await over.load();
        await over.recordPayment(pay(150000));
        expect(over.state.invoice!.status, InvoiceStatus.paid);
        expect(over.state.invoice!.paidAmount, 150000);
        await c.close();
        await over.close();
      },
    );

    test('số tiền không dương: báo ở trường, không gọi API', () async {
      final c = make();
      await c.load();
      await c.recordPayment(pay(0));
      expect(c.state.payClientErrors, {'amount'});
      expect(repo.calls.where((x) => x.startsWith('pay')), isEmpty);
      await c.close();
    });

    test('chặn double-tap: bấm lúc đang gửi chỉ gọi API một lần', () async {
      final c = make();
      await c.load();
      repo.payGate = Completer<void>();
      final first = c.recordPayment(pay(500000));
      await c.recordPayment(pay(500000));
      repo.payGate!.complete();
      await first;
      expect(repo.calls.where((x) => x.startsWith('pay')), hasLength(1));
      expect(c.state.payments, hasLength(1));
      await c.close();
    });

    test(
      'mạng lỗi rồi thử lại cùng nội dung giữ khóa; lần thu sau khóa mới',
      () async {
        final c = make();
        await c.load();
        repo.payError = const ApiException.network();
        await c.recordPayment(pay(500000));
        expect(c.state.error!.retryable, isTrue);
        expect(c.state.done, isNull);
        await c.recordPayment(pay(500000));
        expect(repo.keys[0], repo.keys[1]);
        expect(c.state.payments, hasLength(1));
        await c.recordPayment(pay(200000));
        expect(repo.keys[2], isNot(repo.keys[1]));
        await c.close();
      },
    );

    test('đổi nội dung sau lỗi mạng: khóa mới', () async {
      final c = make();
      await c.load();
      repo.payError = const ApiException.network();
      await c.recordPayment(pay(500000));
      await c.recordPayment(pay(400000));
      expect(repo.keys[0], isNot(repo.keys[1]));
      await c.close();
    });

    test('422 theo trường vào đúng trường, không báo chung', () async {
      final c = make();
      await c.load();
      repo.payError = fieldErr({
        'paidOn': ['Ngày thu không được sau hôm nay'],
        'khac': ['x'],
      });
      await c.recordPayment(pay(500000));
      expect(c.state.serverErrors.keys, ['paidOn']);
      expect(c.state.error, isNull);
      await c.close();
    });

    test(
      'INVOICE_NOT_PAYABLE: tải lại hóa đơn và thanh toán, giữ lỗi',
      () async {
        final c = make();
        await c.load();
        repo.payError = apiErr(ApiErrorCode.invoiceNotPayable);
        // Thiết bị khác vừa ghi thu đủ.
        repo.payments = [samplePayment(amount: 1200000)];
        repo.invoiceAfterError = sampleInvoice(
          status: InvoiceStatus.paid,
          total: 1200000,
          paid: 1200000,
        );
        await c.recordPayment(pay(500000));
        expect(c.state.error!.code, ApiErrorCode.invoiceNotPayable);
        expect(c.state.invoice!.status, InvoiceStatus.paid);
        expect(c.state.payments, hasLength(1));
        expect(c.state.invoice!.canRecordPayment, isFalse);
        await c.close();
      },
    );

    test(
      'CONFLICT_STALE: tải lại; tải lại cũng lỗi thì chưa xác nhận',
      () async {
        final c = make();
        await c.load();
        repo.payError = apiErr(ApiErrorCode.conflictStale);
        await c.recordPayment(pay(500000));
        expect(c.state.error!.code, ApiErrorCode.conflictStale);
        expect(c.state.staleUnverified, isFalse);
        expect(
          repo.calls.where((x) => x == 'getInvoice:i1'),
          hasLength(2),
          reason: 'tải lại sau 409',
        );
        // Lần bấm sau dùng khóa mới vì lỗi 409 không thử lại.
        repo.payError = apiErr(ApiErrorCode.conflictStale);
        repo.invoiceError = const ApiException.network();
        await c.recordPayment(pay(500000));
        expect(repo.keys[0], isNot(repo.keys[1]));
        expect(c.state.staleUnverified, isTrue);
        await c.close();
      },
    );

    Invoice owed(int paid, {int total = 1200000}) => sampleInvoice(
      status: paid == 0 ? InvoiceStatus.issued : InvoiceStatus.partiallyPaid,
      total: total,
      paid: paid,
    );
    int sends() => repo.calls.where((x) => x.startsWith('pay:')).length;

    test(
      'reloadForPayment: cập nhật số còn nợ; đã paid thì báo và trả false',
      () async {
        final c = make();
        await c.load();
        repo.invoice = owed(200000);
        expect(await c.reloadForPayment(), isTrue);
        expect(c.state.invoice!.remainingAmount, 1000000);
        expect(c.state.busy, isFalse);
        repo.invoice = sampleInvoice(
          status: InvoiceStatus.paid,
          total: 1200000,
          paid: 1200000,
        );
        expect(await c.reloadForPayment(), isFalse);
        expect(c.state.notice, PayNotice.notPayable);
        repo.invoiceError = const ApiException.network();
        expect(await c.reloadForPayment(), isFalse);
        expect(c.state.voidError, isNotNull);
        await c.close();
      },
    );

    for (final (name, fresh, remaining) in [
      ('nhỏ hơn', 200000, 1000000),
      ('lớn hơn', -300000, 1500000),
    ]) {
      test(
        'thu đủ khi số còn nợ đã $name: không gửi, báo, xác nhận lại với số mới',
        () async {
          final c = make();
          await c.load();
          // Số người dùng đã thấy: 1.200.000.
          repo.invoiceAfterError = fresh > 0
              ? owed(fresh)
              : owed(0, total: 1200000 - fresh);
          await c.recordPayment(pay(1200000), expectedRemaining: 1200000);
          expect(sends(), 0);
          expect(c.state.notice, PayNotice.remainingChanged);
          expect(c.state.invoice!.remainingAmount, remaining);
          expect(c.state.busy, isFalse);
          await c.recordPayment(pay(remaining), expectedRemaining: remaining);
          expect(sends(), 1);
          expect(repo.paymentInputs.single.amount, remaining);
          expect(c.state.done, InvoiceDone.paymentRecorded);
          await c.close();
        },
      );
    }

    test('thu đủ khi hóa đơn đã paid: không gửi, báo không ghi được', () async {
      final c = make();
      await c.load();
      repo.invoiceAfterError = sampleInvoice(
        status: InvoiceStatus.paid,
        total: 1200000,
        paid: 1200000,
      );
      await c.recordPayment(pay(1200000), expectedRemaining: 1200000);
      expect(sends(), 0);
      expect(c.state.notice, PayNotice.notPayable);
      expect(c.state.invoice!.canRecordPayment, isFalse);
      await c.close();
    });

    test(
      'thu đủ lỗi mạng rồi thử lại mà hóa đơn đã paid (khoản của mình): gửi lại cùng khóa, 1 thanh toán',
      () async {
        final c = make();
        await c.load();
        repo.payError = const ApiException.network();
        await c.recordPayment(pay(1200000), expectedRemaining: 1200000);
        // Server đã ghi nhưng phản hồi mất: hóa đơn nay là đã thu đủ.
        repo.invoice = sampleInvoice(
          status: InvoiceStatus.paid,
          total: 1200000,
          paid: 1200000,
        );
        await c.recordPayment(pay(1200000), expectedRemaining: 1200000);
        expect(sends(), 2);
        expect(repo.keys[0], repo.keys[1]);
        expect(c.state.notice, isNull);
        expect(c.state.done, InvoiceDone.paymentRecorded);
        await c.close();
      },
    );

    test(
      'thử lại sau lỗi mạng mà máy khác đã thu một phần: không gửi, báo số mới, khóa mới',
      () async {
        final c = make();
        await c.load();
        repo.payError = const ApiException.network();
        await c.recordPayment(pay(1200000), expectedRemaining: 1200000);
        repo.invoice = owed(200000); // khoản của mình chưa tới server
        await c.recordPayment(pay(1200000), expectedRemaining: 1200000);
        expect(sends(), 1);
        expect(c.state.notice, PayNotice.remainingChanged);
        expect(c.state.invoice!.remainingAmount, 1000000);
        await c.recordPayment(pay(1000000), expectedRemaining: 1000000);
        expect(sends(), 2);
        expect(repo.keys[1], isNot(repo.keys[0]));
        await c.close();
      },
    );

    test(
      'thử lại sau lỗi mạng mà tải lại lỗi: vẫn gửi lại cùng khóa',
      () async {
        final c = make();
        await c.load();
        repo.payError = const ApiException.network();
        await c.recordPayment(pay(1200000), expectedRemaining: 1200000);
        repo.invoiceError = const ApiException.network();
        await c.recordPayment(pay(1200000), expectedRemaining: 1200000);
        expect(sends(), 2);
        expect(repo.keys[0], repo.keys[1]);
        expect(c.state.done, InvoiceDone.paymentRecorded);
        await c.close();
      },
    );

    test('thu đủ mà không kiểm lại được số còn nợ: không gửi', () async {
      final c = make();
      await c.load();
      repo.invoiceError = const ApiException.network();
      await c.recordPayment(pay(1200000), expectedRemaining: 1200000);
      expect(sends(), 0);
      expect(c.state.error!.retryable, isTrue);
      await c.close();
    });

    test(
      'INVOICE_NOT_PAYABLE mà tải lại lỗi → chưa xác nhận trạng thái',
      () async {
        final c = make();
        await c.load();
        repo.payError = apiErr(ApiErrorCode.invoiceNotPayable);
        repo.invoiceError = const ApiException.network();
        await c.recordPayment(pay(500000));
        expect(c.state.staleUnverified, isTrue);
        expect(c.state.error!.code, ApiErrorCode.invoiceNotPayable);
        await c.close();
      },
    );

    test(
      'khóa: đổi cách thu, ngày hoặc ghi chú → khóa mới; thử lại y nguyên → khóa cũ',
      () async {
        final c = make();
        await c.load();
        for (final input in [
          pay(500000),
          pay(500000, method: PaymentMethod.cash),
          pay(500000, on: '2026-11-04'),
          PaymentInput(
            amount: 500000,
            method: PaymentMethod.bankTransfer,
            paidOn: '2026-11-05',
            note: 'Đóng cho cả tháng',
          ),
        ]) {
          repo.payError = const ApiException.network();
          await c.recordPayment(input);
        }
        expect(repo.keys.toSet(), hasLength(4));
        repo.payError = const ApiException.network();
        await c.recordPayment(pay(500000));
        repo.payError = const ApiException.network();
        await c.recordPayment(pay(500000));
        expect(repo.keys[4], repo.keys[5], reason: 'y nguyên');
        expect(repo.keys[4], isNot(repo.keys[3]));
        await c.close();
      },
    );

    test(
      'hủy thanh toán: đổi lý do → khóa mới; thử lại y nguyên → khóa cũ',
      () async {
        final c = make();
        await c.load();
        await c.recordPayment(pay(500000));
        repo.keys.clear();
        for (final r in ['Ghi nhầm', 'Ghi nhầm', 'Sai số']) {
          repo.voidPaymentError = const ApiException.network();
          await c.voidPayment('p1', r);
        }
        expect(repo.keys[0], repo.keys[1]);
        expect(repo.keys[2], isNot(repo.keys[1]));
        await c.close();
      },
    );

    test('busy không mở lại khi đang tải lại sau lỗi 409', () async {
      final c = make();
      await c.load();
      repo.payError = apiErr(ApiErrorCode.invoiceNotPayable);
      repo.invoiceGate = Completer<void>();
      final first = c.recordPayment(pay(500000));
      await pumpEventQueue();
      expect(c.state.busy, isTrue, reason: 'đang tải lại');
      await c.recordPayment(pay(500000));
      expect(sends(), 1);
      repo.invoiceGate!.complete();
      await first;
      expect(c.state.busy, isFalse);
      await c.close();
    });

    test('clearErrors không reset busy', () async {
      final c = make();
      await c.load();
      repo.payGate = Completer<void>();
      final first = c.recordPayment(pay(500000));
      await pumpEventQueue();
      c.clearErrors();
      expect(c.state.busy, isTrue);
      repo.payGate!.complete();
      await first;
      await c.close();
    });

    test('biên số tiền: 0, sát trần, 12 chữ số, ghi chú quá dài', () async {
      final c = make();
      await c.load();
      await c.recordPayment(pay(0));
      expect(c.state.payClientErrors, {'amount'});
      await c.recordPayment(pay(100000000001));
      expect(c.state.payClientErrors, {'amount'});
      await c.recordPayment(pay(123456789012));
      expect(c.state.payClientErrors, {'amount'});
      await c.recordPayment(
        PaymentInput(
          amount: 1000,
          method: PaymentMethod.cash,
          paidOn: '2026-11-05',
          note: 'x' * 301,
        ),
      );
      expect(c.state.payClientErrors, {'note'});
      expect(sends(), 0);
      await c.recordPayment(pay(100000000000));
      expect(sends(), 1, reason: 'đúng trần thì gửi');
      await c.close();
    });

    test('hủy thanh toán: về đã phát hành, thanh toán gạch, có khóa', () async {
      final c = make();
      await c.load();
      await c.recordPayment(pay(500000));
      await c.voidPayment('p1', ' Ghi nhầm ');
      expect(c.state.done, InvoiceDone.paymentVoided);
      expect(c.state.invoice!.status, InvoiceStatus.issued);
      expect(c.state.invoice!.paidAmount, 0);
      expect(c.state.payments.single.isVoided, isTrue);
      expect(repo.calls.last, 'voidPayment:p1: Ghi nhầm ');
      await c.close();
    });

    test('hủy thanh toán lỗi mạng: báo lỗi, thử lại giữ khóa', () async {
      final c = make();
      await c.load();
      await c.recordPayment(pay(500000));
      repo.voidPaymentError = const ApiException.network();
      await c.voidPayment('p1', 'Ghi nhầm');
      expect(c.state.voidError, isNotNull);
      expect(c.state.payments.single.isVoided, isFalse);
      await c.voidPayment('p1', 'Ghi nhầm');
      expect(repo.keys[1], repo.keys[2]);
      expect(c.state.payments.single.isVoided, isTrue);
      await c.close();
    });
  });

  test('model: giá trị lạ theo hợp đồng', () {
    expect(InvoiceStatus.fromWire('whatever'), InvoiceStatus.issued);
    expect(InvoiceLineKind.fromWire('whatever'), InvoiceLineKind.monthly);
    expect(BillingPeriodStatus.fromWire(null), BillingPeriodStatus.drafting);
    expect(formatIsoDate('2026-11-01'), '01/11/2026');
  });
}
