import 'package:dio/dio.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'onboarding_models.dart';

abstract class OnboardingRepository {
  /// Lỗi API ném [ApiException].
  Future<Onboarding> get();
  Future<Onboarding> patchStep(OnboardingStep step, OnboardingStatus status);
}

class DioOnboardingRepository implements OnboardingRepository {
  DioOnboardingRepository(this._api);
  final Dio _api;

  @override
  Future<Onboarding> get() =>
      _call(() => _api.get<Map<String, dynamic>>('/onboarding'));

  @override
  Future<Onboarding> patchStep(OnboardingStep step, OnboardingStatus status) =>
      _call(
        () => _api.patch<Map<String, dynamic>>(
          '/onboarding/steps/${step.wire}',
          data: {'status': status.name},
        ),
      );

  Future<Onboarding> _call(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      return Onboarding.fromJson((await request()).data!);
    } on DioException catch (e) {
      final res = e.response;
      throw res == null
          ? const ApiException.network()
          : ApiException.fromResponse(
              res.statusCode,
              res.data,
              retryAfterHeader: res.headers.value('retry-after'),
            );
    }
  }
}
