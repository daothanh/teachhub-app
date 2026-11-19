import 'package:dio/dio.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'invoice_models.dart';

/// API `/family/invoices` (US-7.3). Lỗi ra ngoài là [ApiException]; 404 là
/// [ApiErrorKind.notFound], 403 `CONSENT_REQUIRED` đã được host chuyển về màn đồng ý.
abstract interface class InvoiceRepository {
  Future<InvoicePage> list({
    String? cursor,
    InvoiceStatus? status,
    String? studentId,
    int limit = 20,
  });

  Future<InvoiceDetail> detail(String id);
}

class DioInvoiceRepository implements InvoiceRepository {
  DioInvoiceRepository(this._dio);
  final Dio _dio;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw ApiException.fromDio(e) ?? e;
    }
  }

  @override
  Future<InvoicePage> list({
    String? cursor,
    InvoiceStatus? status,
    String? studentId,
    int limit = 20,
  }) => _guard(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/family/invoices',
      queryParameters: {
        'limit': limit,
        'cursor': ?cursor,
        if (status != null) 'status': status.wire,
        'studentId': ?studentId,
      },
    );
    final data = res.data;
    if (data == null) throw const ApiException.unexpected();
    return InvoicePage.fromJson(data);
  });

  @override
  Future<InvoiceDetail> detail(String id) => _guard(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/family/invoices/${Uri.encodeComponent(id)}',
    );
    final data = res.data;
    if (data == null) throw const ApiException.unexpected();
    return InvoiceDetail.fromJson(data);
  });
}
