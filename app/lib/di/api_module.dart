import 'package:alice/alice.dart';
import 'package:alice_dio/alice_dio_adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:tasco_auth/tasco_auth.dart';
import 'package:tasco_core/tasco_core.dart';
import 'package:tasco_storage/tasco_storage.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../core/config/app_env.dart';
import '../core/network/teachhub_headers_interceptor.dart';
import '../core/network/teachhub_logging_interceptor.dart';
import '../core/network/consent_required_interceptor.dart';
import '../features/auth/teachhub_user.dart';
import '../features/consent/consent_cubit.dart';

/// HTTP inspector; chỉ có ở development — staging dùng dữ liệu thật, không
/// để lộ Authorization/OTP/token qua màn inspector.
Alice? alice;

/// Hai client theo spec §3.5:
/// - [TeachHubDiKey.api]: toàn bộ TeachHub API (`<base>/v1`), kể cả
///   `tasco_auth` (`/auth/*`) và `tasco_notifications` (`/push/*`).
/// - [TeachHubDiKey.objectStorage]: URL presigned R2 — không baseURL, không
///   Bearer, không pin (chứng chỉ R2 không phải của API).
Future<void> apiModule(GetIt getIt) async {
  final appEnv = getIt<AppEnv>();
  alice = appEnv.isDevelopment ? Alice() : null;

  // Pin cho API (theo flavor). Retry client dùng chung adapter này, nếu không
  // request gửi lại — vẫn mang Bearer — sẽ đi trên TLS không pin.
  final pins = appEnv.certificatePins;
  final pinnedAdapter = pins.isEmpty
      ? null
      : CertificatePinning.adapter(allowedSha256: pins);
  final clientInfo = await TeachHubHeadersInterceptor.resolveClientInfo();

  getIt
    ..registerLazySingleton<TokenRefresher>(
      () => TokenRefresher(
        refresh: () => getIt<AuthRepository<TeachHubUser>>().refreshToken(),
        authEventBus: getIt<AuthEventBus>(),
      ),
    )
    ..registerLazySingleton<AuthInterceptor>(
      () => AuthInterceptor(
        () => getIt<TokenStore>().getAccessToken(),
        () => getIt<TokenRefresher>(),
        retryClient: AuthInterceptor.buildRetryClient(adapter: pinnedAdapter),
        authEventBus: getIt<AuthEventBus>(),
      ),
    )
    ..registerLazySingleton<Dio>(
      () => _buildDio(
        NetworkDefaults.baseOptions(baseUrl: appEnv.apiUrl),
        pinnedAdapter,
        apiInterceptors(
          headers: TeachHubHeadersInterceptor(clientInfo: clientInfo),
          // Lazy: ConsentCubit cần chính Dio này, chỉ tra khi có lỗi 403.
          consentRequired: ConsentRequiredInterceptor(
            (v) => getIt<ConsentCubit>().markRequired(v),
          ),
          authInterceptor: getIt<AuthInterceptor>(),
          retryInterceptor: RetryInterceptor(
            retryClient: RetryInterceptor.buildRetryClient(
              adapter: pinnedAdapter,
            ),
          ),
        ),
      ),
      instanceName: TeachHubDiKey.api,
    )
    ..registerLazySingleton<Dio>(
      () => _buildDio(NetworkDefaults.baseOptions(baseUrl: ''), null, [
        LoggingInterceptor(),
      ]),
      instanceName: TeachHubDiKey.objectStorage,
    );
}

/// Chuỗi interceptor của client API, theo thứ tự chạy.
///
/// Header đứng đầu để `Idempotency-Key`/`x-request-id` có trong
/// `RequestOptions` trước khi Auth/Retry gửi lại. Không gắn `ErrorInterceptor`
/// của Tasco: overlay loading toàn cục (màu Tasco) chồng lên trạng thái tải
/// riêng của từng màn DayHoc thành hai vòng tải (Owner báo 23/11/2026).
@visibleForTesting
List<Interceptor> apiInterceptors({
  required TeachHubHeadersInterceptor headers,
  required ConsentRequiredInterceptor consentRequired,
  required AuthInterceptor authInterceptor,
  required RetryInterceptor retryInterceptor,
}) => [
  headers,
  consentRequired,
  authInterceptor,
  retryInterceptor,
  TeachHubLoggingInterceptor(),
];

Dio _buildDio(
  BaseOptions options,
  HttpClientAdapter? adapter,
  List<Interceptor> interceptors,
) {
  final dio = Dio(options);
  if (adapter != null) dio.httpClientAdapter = adapter;
  final inspector = alice;
  if (inspector != null) {
    final aliceDioAdapter = AliceDioAdapter();
    inspector.addAdapter(aliceDioAdapter);
    dio.interceptors.add(aliceDioAdapter);
  }
  dio.interceptors.addAll(interceptors);
  return dio;
}
