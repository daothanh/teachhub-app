import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../receivables/data/receivables_repository.dart' show asApiException;
import 'report_models.dart';

/// API báo cáo của giáo viên (T12/T12a, US-8.1, US-8.2), chỉ đọc. [month] là
/// `YYYY-MM`; bỏ trống = tháng hiện tại theo múi giờ tenant. Mọi lỗi ra ngoài
/// là [ApiException]; test thay bằng bản giả của lớp này.
abstract class ReportsRepository {
  /// `GET /reports/month-overview`.
  Future<MonthOverview> monthOverview({String? month});

  /// `GET /reports/payments`: sổ thu của tháng, mới nhất trước.
  Future<RevenueEntryPage> payments({
    String? month,
    int page = 1,
    int pageSize = 20,
  });

  /// `GET /reports/revenue-by-class`.
  Future<RevenueByClass> revenueByClass({String? month});

  /// `GET /reports/revenue-12m`.
  Future<Revenue12m> revenue12m({String? month});
}

ReportsRepository reportsRepository() =>
    GetIt.I.isRegistered<ReportsRepository>()
    ? GetIt.I<ReportsRepository>()
    : DioReportsRepository(GetIt.I<Dio>(instanceName: TeachHubDiKey.api));

class DioReportsRepository implements ReportsRepository {
  DioReportsRepository(this._dio);
  final Dio _dio;

  Future<T> _get<T>(
    String path,
    Map<String, Object?> query,
    T Function(Map<String, dynamic>) parse,
  ) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: {
          for (final MapEntry(:key, :value) in query.entries) key: ?value,
        },
      );
      return parse(r.data!);
    } on Object catch (e) {
      // Lỗi đọc phản hồi thành lỗi máy chủ chung để cubit không kẹt đang tải.
      final parseFailure =
          e is TypeError ||
          e is FormatException ||
          (e is DioException &&
              (e.error is TypeError || e.error is FormatException));
      throw (parseFailure ? null : ApiException.fromDio(e)) ??
          asApiException(e);
    }
  }

  @override
  Future<MonthOverview> monthOverview({String? month}) =>
      _get('/reports/month-overview', {'month': month}, MonthOverview.fromJson);

  @override
  Future<RevenueEntryPage> payments({
    String? month,
    int page = 1,
    int pageSize = 20,
  }) => _get('/reports/payments', {
    'month': month,
    'page': page,
    'pageSize': pageSize,
  }, RevenueEntryPage.fromJson);

  @override
  Future<RevenueByClass> revenueByClass({String? month}) => _get(
    '/reports/revenue-by-class',
    {'month': month},
    RevenueByClass.fromJson,
  );

  @override
  Future<Revenue12m> revenue12m({String? month}) =>
      _get('/reports/revenue-12m', {'month': month}, Revenue12m.fromJson);
}
