import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'receivable_models.dart';

/// API công nợ (T11, US-8.3) và nhắc nợ (US-7.5). Mọi lỗi ra ngoài là
/// [ApiException]; test thay bằng bản giả của lớp này. Các lệnh `PUT` ở đây
/// idempotent theo giá trị nên hợp đồng không đòi `Idempotency-Key`.
abstract class ReceivablesRepository {
  /// `GET /receivables`: một trang học viên còn nợ kèm tổng theo nhóm.
  /// [agingBucket] chỉ lọc danh sách, tổng theo nhóm không bị lọc.
  Future<ReceivablePage> list({
    int page = 1,
    int pageSize = 20,
    AgingBucket? agingBucket,
    String? query,
    ReceivableSort sort = ReceivableSort.amount,
    bool ascending = false,
  });

  /// `GET /receivables/{studentId}`: hóa đơn, thanh toán, nhắc nợ của em đó.
  Future<StudentReceivableHistory> history(String studentId);

  /// `GET /tenant/settings/dunning`.
  Future<DunningSettings> getSettings();

  /// `PUT /tenant/settings/dunning`: thay toàn bộ cài đặt; sai → 422 tại trường.
  Future<DunningSettings> putSettings(DunningSettings settings);

  /// `GET /tenant/settings/dunning/preview`: mẫu tin của một mốc, dữ liệu mẫu.
  Future<DunningPreview> preview(int offsetDays);

  /// `PUT /enrollments/{id}/dunning`: bật/tắt nhắc nợ của một ghi danh.
  Future<EnrollmentDunningResult> setEnrollmentDunning(
    String enrollmentId, {
    required bool enabled,
  });

  /// `GET /invoices/{id}/dunning`.
  Future<InvoiceDunning> invoiceDunning(String invoiceId);
}

ReceivablesRepository receivablesRepository() =>
    GetIt.I.isRegistered<ReceivablesRepository>()
    ? GetIt.I<ReceivablesRepository>()
    : DioReceivablesRepository(GetIt.I<Dio>(instanceName: TeachHubDiKey.api));

class DioReceivablesRepository implements ReceivablesRepository {
  DioReceivablesRepository(this._dio);
  final Dio _dio;

  @override
  Future<ReceivablePage> list({
    int page = 1,
    int pageSize = 20,
    AgingBucket? agingBucket,
    String? query,
    ReceivableSort sort = ReceivableSort.amount,
    bool ascending = false,
  }) => _call(() async {
    final r = await _dio.get<Map<String, dynamic>>(
      '/receivables',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        'agingBucket': ?agingBucket?.wire,
        'q': ?query,
        'sortField': sort.wire,
        'sortOrder': ascending ? 'asc' : 'desc',
      },
    );
    return ReceivablePage.fromJson(r.data!);
  });

  @override
  Future<StudentReceivableHistory> history(String studentId) => _call(() async {
    final r = await _dio.get<Map<String, dynamic>>('/receivables/$studentId');
    return StudentReceivableHistory.fromJson(r.data!);
  });

  @override
  Future<DunningSettings> getSettings() => _call(() async {
    final r = await _dio.get<Map<String, dynamic>>('/tenant/settings/dunning');
    return DunningSettings.fromJson(r.data!);
  });

  @override
  Future<DunningSettings> putSettings(DunningSettings settings) =>
      _call(() async {
        final r = await _dio.put<Map<String, dynamic>>(
          '/tenant/settings/dunning',
          data: settings.toJson(),
        );
        return DunningSettings.fromJson(r.data!);
      });

  @override
  Future<DunningPreview> preview(int offsetDays) => _call(() async {
    final r = await _dio.get<Map<String, dynamic>>(
      '/tenant/settings/dunning/preview',
      queryParameters: {'offsetDays': offsetDays},
    );
    return DunningPreview.fromJson(r.data!);
  });

  @override
  Future<EnrollmentDunningResult> setEnrollmentDunning(
    String enrollmentId, {
    required bool enabled,
  }) => _call(() async {
    final r = await _dio.put<Map<String, dynamic>>(
      '/enrollments/$enrollmentId/dunning',
      data: {'enabled': enabled},
    );
    return EnrollmentDunningResult.fromJson(r.data!);
  });

  @override
  Future<InvoiceDunning> invoiceDunning(String invoiceId) => _call(() async {
    final r = await _dio.get<Map<String, dynamic>>(
      '/invoices/$invoiceId/dunning',
    );
    return InvoiceDunning.fromJson(r.data!);
  });
}

/// Mọi lỗi ra ngoài là [ApiException]; lỗi đọc phản hồi thành lỗi máy chủ chung
/// (giống `BillingRepository`) để cubit không kẹt ở trạng thái đang tải.
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
