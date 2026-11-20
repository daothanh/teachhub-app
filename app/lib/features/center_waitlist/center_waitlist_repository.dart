import 'package:dio/dio.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

abstract class CenterWaitlistRepository {
  /// `POST /center-waitlist`. [idempotencyKey] giữ nguyên khi thử lại cùng nội
  /// dung (cubit quản). Lỗi API ném [ApiException].
  Future<void> join({
    required String centerName,
    required int teacherCount,
    required String idempotencyKey,
  });
}

class DioCenterWaitlistRepository implements CenterWaitlistRepository {
  DioCenterWaitlistRepository(this._api);
  final Dio _api;

  @override
  Future<void> join({
    required String centerName,
    required int teacherCount,
    required String idempotencyKey,
  }) async {
    try {
      await _api.post<void>(
        '/center-waitlist',
        data: {'centerName': centerName, 'teacherCount': teacherCount},
        options: Options(headers: {'Idempotency-Key': idempotencyKey}),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e)!;
    }
  }
}
