import 'package:dio/dio.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../core/network/api_error.dart';

abstract class CenterWaitlistRepository {
  /// `POST /center-waitlist`; lỗi API ném [ApiException].
  Future<void> join({required String centerName, required int teacherCount});
}

class DioCenterWaitlistRepository implements CenterWaitlistRepository {
  DioCenterWaitlistRepository(this._api);
  final Dio _api;

  @override
  Future<void> join({
    required String centerName,
    required int teacherCount,
  }) async {
    try {
      await _api.post<void>(
        '/center-waitlist',
        data: {'centerName': centerName, 'teacherCount': teacherCount},
      );
    } on DioException catch (e) {
      throw apiException(e) ?? e;
    }
  }
}
