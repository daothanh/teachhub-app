import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../receivables/data/receivables_repository.dart' show asApiException;
import 'plan_models.dart';

/// API gói và dùng thử của giáo viên (T14, US-0.7, US-0.8). Mọi lỗi ra ngoài là
/// [ApiException]; test thay bằng bản giả của lớp này.
abstract class PlanRepository {
  /// `GET /plan-usage`.
  Future<PlanUsage> usage();

  /// `POST /subscription/trial`: giữ nguyên [idempotencyKey] khi thử lại. Đã
  /// dùng thử → 422 `TRIAL_ALREADY_USED`, đang Pro → 409 `CONFLICT_STALE`.
  Future<PlanUsage> startTrial({required String idempotencyKey});
}

PlanRepository planRepository() => GetIt.I.isRegistered<PlanRepository>()
    ? GetIt.I<PlanRepository>()
    : DioPlanRepository(GetIt.I<Dio>(instanceName: TeachHubDiKey.api));

class DioPlanRepository implements PlanRepository {
  DioPlanRepository(this._dio);
  final Dio _dio;

  @override
  Future<PlanUsage> usage() =>
      _call(() => _dio.get<Map<String, dynamic>>('/plan-usage'));

  @override
  Future<PlanUsage> startTrial({required String idempotencyKey}) => _call(
    () => _dio.post<Map<String, dynamic>>(
      '/subscription/trial',
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    ),
  );

  Future<PlanUsage> _call(
    Future<Response<Map<String, dynamic>>> Function() run,
  ) async {
    try {
      return PlanUsage.fromJson((await run()).data!);
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
}
