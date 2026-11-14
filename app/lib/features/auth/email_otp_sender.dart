import 'package:dio/dio.dart';

/// `POST /auth/otp/send` (công khai, giới hạn 60 giây/lần ở API).
typedef EmailOtpSender = Future<void> Function(String email);

EmailOtpSender emailOtpSender(Dio api) =>
    (email) => api.post<void>(
      '/auth/otp/send',
      data: {'email': email},
      // Endpoint công khai: AuthInterceptor không gắn token, không refresh.
      options: Options(extra: const {'requiresAuth': false}),
    );
