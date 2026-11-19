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
import '../features/auth/teachhub_user.dart';

/// HTTP inspector; `null` ở production.
Alice? alice;

/// Hai client theo spec §3.5:
/// - [TeachHubDiKey.api]: toàn bộ TeachHub API (`<base>/v1`), kể cả
///   `tasco_auth` (`/auth/*`) và `tasco_notifications` (`/push/*`).
/// - [TeachHubDiKey.objectStorage]: URL presigned R2 — không baseURL, không
///   Bearer, không pin (chứng chỉ R2 không phải của API).
Future<void> apiModule(GetIt getIt) async {
  final appEnv = getIt<AppEnv>();
  alice = appEnv.isProduction ? null : Alice();

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
          loadingManager: getIt<LoadingManager>(),
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
/// `RequestOptions` trước khi Auth/Retry gửi lại. [ErrorInterceptor] (overlay
/// loading) đứng trước Auth và Retry vì hai interceptor này kết thúc chuỗi
/// bằng `resolve` — đứng sau chúng thì overlay không bao giờ được ẩn.
@visibleForTesting
List<Interceptor> apiInterceptors({
  required TeachHubHeadersInterceptor headers,
  required LoadingManager loadingManager,
  required AuthInterceptor authInterceptor,
  required RetryInterceptor retryInterceptor,
}) => [
  headers,
  ErrorInterceptor(loadingManager: loadingManager),
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
