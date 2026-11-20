import 'package:dio/dio.dart';

/// `POST /auth/otp/send` (công khai, giới hạn 60 giây/lần ở API).
// TODO(S1-FL-11): ràng buộc 60 giây/lần chưa có trong contracts/openapi.json; thêm 429 + `retryAfterSec` vào hợp đồng.
typedef EmailOtpSender = Future<void> Function(String email);

EmailOtpSender emailOtpSender(Dio api) =>
    (email) => api.post<void>(
      '/auth/otp/send',
      data: {'email': email},
      // Endpoint công khai: AuthInterceptor không gắn token, không refresh.
      options: Options(extra: const {'requiresAuth': false}),
    );

/// `POST /auth/otp/send` với `purpose = delete_account`: mã chỉ dùng được cho
/// `DELETE /me` (mã đăng nhập không xóa được tài khoản và ngược lại).
EmailOtpSender deleteAccountOtpSender(Dio api) =>
    (email) => api.post<void>(
      '/auth/otp/send',
      data: {'email': email, 'purpose': 'delete_account'},
      options: Options(extra: const {'requiresAuth': false}),
    );
