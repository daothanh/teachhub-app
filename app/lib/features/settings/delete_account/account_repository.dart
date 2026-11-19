import 'package:dio/dio.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../auth/email_otp_sender.dart';

/// Xóa tài khoản (US-0.x, S4-FL-04): gửi OTP `delete_account` rồi `DELETE /me`.
/// Lỗi API ném [ApiException].
abstract class AccountRepository {
  Future<void> sendDeleteOtp(String email);

  /// [idempotencyKey] giữ nguyên khi thử lại cùng mã OTP (cubit quản).
  Future<void> deleteAccount({
    required String otp,
    required String idempotencyKey,
  });
}

class DioAccountRepository implements AccountRepository {
  DioAccountRepository(this._api) : _send = deleteAccountOtpSender(_api);
  final Dio _api;
  final EmailOtpSender _send;

  @override
  Future<void> sendDeleteOtp(String email) => _guard(() => _send(email));

  @override
  Future<void> deleteAccount({
    required String otp,
    required String idempotencyKey,
  }) => _guard(
    () => _api.delete<void>(
      '/me',
      data: {'otp': otp},
      // Interceptor chỉ tự gắn khóa cho POST/PATCH nên DELETE phải gắn tay.
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    ),
  );

  Future<void> _guard(Future<void> Function() run) async {
    try {
      await run();
    } on DioException catch (e) {
      throw ApiException.fromDio(e)!;
    }
  }
}
