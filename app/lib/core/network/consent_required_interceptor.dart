import 'package:dio/dio.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

/// 403 `CONSENT_REQUIRED` ở bất kỳ API nào → báo [onRequired] kèm
/// `details.termsVersion`; router đưa người dùng về màn đồng ý (US-0.3 AC2).
/// Lỗi vẫn đi tiếp tới nơi gọi.
class ConsentRequiredInterceptor extends Interceptor {
  ConsentRequiredInterceptor(this.onRequired);

  final void Function(String? termsVersion) onRequired;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final error = ApiException.fromDio(err);
    if (error?.code == ApiErrorCode.consentRequired) {
      final version = error!.details['termsVersion'];
      onRequired(version is String ? version : null);
    }
    handler.next(err);
  }
}
