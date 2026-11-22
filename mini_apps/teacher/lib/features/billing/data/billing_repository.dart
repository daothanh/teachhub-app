import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'billing_models.dart';
import 'claim_models.dart';

/// API kỳ thu và hóa đơn của giáo viên (US-7.2, US-7.3). Mọi lỗi ra ngoài là
/// [ApiException]; test thay bằng bản giả của lớp này.
///
/// Lệnh ghi nhận [idempotencyKey]: giữ nguyên khi thử lại để server phát lại
/// kết quả thay vì làm hai lần.
abstract class BillingRepository {
  /// `GET /billing-periods`, mới nhất trước.
  Future<List<BillingPeriod>> listPeriods();

  /// `GET /billing-periods/{id}`; gộp mọi trang hóa đơn thành một danh sách.
  Future<BillingPeriodDetail> getPeriod(String id);

  Future<Invoice> getInvoice(String id);

  /// `POST /invoices/{id}/adjustments`: trả hóa đơn đã tính lại.
  Future<Invoice> addAdjustment(
    String invoiceId,
    AdjustmentInput input, {
    required String idempotencyKey,
  });

  /// `POST /billing-periods/{id}/issue`; [invoiceIds] `null` = chốt tất cả.
  Future<IssueResult> issue(
    String periodId, {
    List<String>? invoiceIds,
    required String idempotencyKey,
  });

  /// `POST /invoices/{id}/void`: trả hóa đơn sau khi hủy.
  Future<Invoice> voidInvoice(
    String invoiceId, {
    required String reason,
    required String idempotencyKey,
  });

  /// `GET /invoices/{id}/payments`: mới ghi trước, gồm cả thanh toán đã hủy.
  /// Bản nháp trả 404, nên chỉ gọi cho hóa đơn đã phát hành.
  Future<List<Payment>> listPayments(String invoiceId);

  /// `POST /invoices/{id}/payments` (US-7.4 AC1, AC2): thu đủ hay một phần suy
  /// ra từ số tiền.
  Future<PaymentResult> recordPayment(
    String invoiceId,
    PaymentInput input, {
    required String idempotencyKey,
  });

  /// `POST /payments/{id}/void` (US-7.4 AC4): lý do bắt buộc.
  Future<PaymentResult> voidPayment(
    String paymentId, {
    required String reason,
    required String idempotencyKey,
  });

  /// `GET /invoices/{id}/payment-claims` (US-7.7): mới nhất trước. Bản nháp trả 404.
  Future<List<PaymentClaim>> listClaims(String invoiceId);

  /// `POST /payment-claims/{id}/resolve`: xác nhận (sinh thanh toán
  /// `bank_transfer`) hoặc từ chối có lý do. 409 `CONFLICT_STALE` khi lần báo
  /// không còn chờ.
  Future<ClaimResolveResult> resolveClaim(
    String claimId,
    ClaimResolution resolution, {
    required String idempotencyKey,
  });

  /// `GET /files/{id}/download-url`: URL xem biên lai, sống 10 phút. Không giữ lâu.
  Future<String> receiptUrl(String fileId);
}

BillingRepository billingRepository() =>
    GetIt.I.isRegistered<BillingRepository>()
    ? GetIt.I<BillingRepository>()
    : DioBillingRepository(GetIt.I<Dio>(instanceName: TeachHubDiKey.api));

/// Hợp đồng cho phép tới 100 hóa đơn mỗi trang.
const _pageSize = 100;

class DioBillingRepository implements BillingRepository {
  DioBillingRepository(this._dio);
  final Dio _dio;

  @override
  Future<List<BillingPeriod>> listPeriods() => _call(() async {
    final r = await _dio.get<Map<String, dynamic>>(
      '/billing-periods',
      queryParameters: {'pageSize': _pageSize},
    );
    return [
      for (final e in r.data!['items'] as List)
        BillingPeriod.fromJson(e as Map<String, dynamic>),
    ];
  });

  @override
  Future<BillingPeriodDetail> getPeriod(String id) => _call(() async {
    BillingPeriodPageData? first;
    final all = <InvoiceSummary>[];
    for (var page = 1; ; page++) {
      final r = await _dio.get<Map<String, dynamic>>(
        '/billing-periods/$id',
        queryParameters: {'page': page, 'pageSize': _pageSize},
      );
      final data = BillingPeriodPageData.fromJson(r.data!);
      first ??= data;
      all.addAll(data.items);
      // Trang rỗng cũng dừng để không lặp vô hạn khi server đếm lệch.
      if (data.items.isEmpty || all.length >= data.total) break;
    }
    return BillingPeriodDetail(
      period: first.period,
      invoices: all,
      invoiceTotal: first.total,
    );
  });

  @override
  Future<Invoice> getInvoice(String id) => _call(() async {
    final r = await _dio.get<Map<String, dynamic>>('/invoices/$id');
    return Invoice.fromJson(r.data!);
  });

  @override
  Future<Invoice> addAdjustment(
    String invoiceId,
    AdjustmentInput input, {
    required String idempotencyKey,
  }) => _call(() async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/invoices/$invoiceId/adjustments',
      data: input.toJson(),
      options: _key(idempotencyKey),
    );
    return Invoice.fromJson(r.data!);
  });

  @override
  Future<IssueResult> issue(
    String periodId, {
    List<String>? invoiceIds,
    required String idempotencyKey,
  }) => _call(() async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/billing-periods/$periodId/issue',
      // Hợp đồng bắt buộc có khóa `invoiceIds`, kể cả null.
      data: {'invoiceIds': invoiceIds},
      options: _key(idempotencyKey),
    );
    return IssueResult.fromJson(r.data!);
  });

  @override
  Future<Invoice> voidInvoice(
    String invoiceId, {
    required String reason,
    required String idempotencyKey,
  }) => _call(() async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/invoices/$invoiceId/void',
      data: {'reason': reason.trim()},
      options: _key(idempotencyKey),
    );
    return Invoice.fromJson(r.data!['invoice'] as Map<String, dynamic>);
  });

  @override
  Future<List<Payment>> listPayments(String invoiceId) => _call(() async {
    final r = await _dio.get<Map<String, dynamic>>(
      '/invoices/$invoiceId/payments',
    );
    return [
      for (final e in r.data!['items'] as List)
        Payment.fromJson(e as Map<String, dynamic>),
    ];
  });

  @override
  Future<PaymentResult> recordPayment(
    String invoiceId,
    PaymentInput input, {
    required String idempotencyKey,
  }) => _call(() async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/invoices/$invoiceId/payments',
      data: input.toJson(),
      options: _key(idempotencyKey),
    );
    return PaymentResult.fromJson(r.data!);
  });

  @override
  Future<PaymentResult> voidPayment(
    String paymentId, {
    required String reason,
    required String idempotencyKey,
  }) => _call(() async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/payments/$paymentId/void',
      data: {'reason': reason.trim()},
      options: _key(idempotencyKey),
    );
    return PaymentResult.fromJson(r.data!);
  });

  @override
  Future<List<PaymentClaim>> listClaims(String invoiceId) => _call(() async {
    final r = await _dio.get<Map<String, dynamic>>(
      '/invoices/$invoiceId/payment-claims',
    );
    return [
      for (final e in r.data!['items'] as List)
        PaymentClaim.fromJson(e as Map<String, dynamic>),
    ];
  });

  @override
  Future<ClaimResolveResult> resolveClaim(
    String claimId,
    ClaimResolution resolution, {
    required String idempotencyKey,
  }) => _call(() async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/payment-claims/$claimId/resolve',
      data: resolution.toJson(),
      options: _key(idempotencyKey),
    );
    return ClaimResolveResult.fromJson(r.data!);
  });

  @override
  Future<String> receiptUrl(String fileId) => _call(() async {
    final r = await _dio.get<Map<String, dynamic>>(
      '/files/$fileId/download-url',
    );
    return r.data!['url'] as String;
  });
}

Options _key(String key) => Options(headers: {'Idempotency-Key': key});

/// Mọi lỗi ra ngoài là [ApiException]; lỗi đọc phản hồi thành lỗi máy chủ chung
/// (giống `FeeRepository`) để cubit không kẹt ở trạng thái đang tải.
Future<T> _call<T>(Future<T> Function() run) async {
  try {
    return await run();
  } on Object catch (e) {
    final parseFailure =
        e is TypeError ||
        e is FormatException ||
        (e is DioException &&
            (e.error is TypeError || e.error is FormatException));
    throw (parseFailure ? null : ApiException.fromDio(e)) ??
        const ApiException.unexpected();
  }
}
