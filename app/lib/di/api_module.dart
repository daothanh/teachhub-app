import 'package:alice/alice.dart';
import 'package:alice_dio/alice_dio_adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:tasco_auth/tasco_auth.dart';
import 'package:tasco_core/tasco_core.dart';
import 'package:tasco_storage/tasco_storage.dart';

import '../core/config/app_env.dart';
import '../core/config/client_identity.dart';
import '../data/model/user_model.dart';
import 'const_key.dart';

Alice? alice;

Future<void> apiModule(GetIt getIt) async {
  final appEnv = getIt<AppEnv>();

  if (!appEnv.isProduction) {
    alice = Alice();
  }

  // Pinning: cơ chế ở framework, fingerprint là dữ liệu sản phẩm (theo flavor).
  // Dựng adapter MỘT lần rồi dùng chung, để service client và retry client của
  // AuthInterceptor cùng một chính sách TLS. Pins rỗng ⇒ không pin.
  final pins = appEnv.certificatePins;
  final pinnedAdapter = pins.isEmpty
      ? null
      : CertificatePinning.adapter(allowedSha256: pins);

  // Đăng ký lazy: factory chỉ chạy ở lần resolve đầu tiên (thời điểm gọi mạng /
  // sau khi bootstrap dựng xong DI), nên RefreshTokenUseCase/AuthRepository ở
  // module sau đã sẵn sàng dù apiModule chạy trước.
  getIt
    ..registerLazySingleton<TokenRefresher>(
      () => TokenRefresher(
        // Delegate to the auth repository (core stays app-agnostic).
        refresh: () => getIt<AuthRepository<UserModel>>().refreshToken(),
        authEventBus: getIt<AuthEventBus>(),
      ),
    )
    ..registerLazySingleton<AuthInterceptor>(
      () => AuthInterceptor(
        // Inject token reader; core does not depend on app's TokenStore.
        () => getIt<TokenStore>().getAccessToken(),
        // Thunk: chỉ resolve TokenRefresher khi xử lý 401 (tránh vòng DI).
        () => getIt<TokenRefresher>(),
        // Retry chạy NGOÀI stack interceptor của service Dio (cố ý — để không
        // đệ quy), nên nó cũng nằm ngoài những gì service Dio đặt ở tầng
        // client: timeout và adapter đã pin. Dựng tường minh, nếu không thì
        // đúng request mang token vừa refresh lại là request duy nhất đi trên
        // TLS không pinned và không có timeout.
        retryClient: AuthInterceptor.buildRetryClient(adapter: pinnedAdapter),
        // Refresh thật xong, retry vẫn 401 ⇒ phiên hết cứu. Không truyền bus
        // thì nhánh force-logout này chết lặng.
        authEventBus: getIt<AuthEventBus>(),
      ),
    );

  final clientHeaders = getIt<ClientIdentity>().headers;

  Dio buildClient(String baseUrl) => _buildDio(
    baseUrl,
    pinnedAdapter,
    serviceInterceptors(
      loadingManager: getIt<LoadingManager>(),
      authInterceptor: getIt<AuthInterceptor>(),
      // Same reasoning as the retry client above: retries run outside this
      // Dio's interceptor chain, so they are also outside its timeout and
      // pinned adapter. The retried request still carries the Authorization
      // header, so an un-pinned default would send the bearer token over
      // unverified TLS.
      retryInterceptor: RetryInterceptor(
        retryClient: RetryInterceptor.buildRetryClient(adapter: pinnedAdapter),
      ),
    ),
    headers: clientHeaders,
  );

  getIt
    ..registerLazySingleton<Dio>(
      () => buildClient(appEnv.authUrl),
      instanceName: DiKey.authDio,
    )
    ..registerLazySingleton<Dio>(
      () => buildClient(appEnv.crmUrl),
      instanceName: DiKey.crmDio,
    )
    ..registerLazySingleton<Dio>(
      () => buildClient(appEnv.hrmUrl),
      instanceName: DiKey.hrmDio,
    )
    ..registerLazySingleton<Dio>(
      () => buildClient(appEnv.ticketUrl),
      instanceName: DiKey.ticketDio,
    );
}

/// The interceptors every service client carries, in the order they run.
///
/// [ErrorInterceptor] (the loading overlay) goes first. [AuthInterceptor]
/// replays a 401 and [RetryInterceptor] retries a transient failure, and both
/// end the chain by resolving from `onError`: no interceptor after them sees
/// the outcome. Behind them, the overlay's `hide()` never ran and the overlay
/// stayed up until `LoadingManager`'s 5-second safety timer.
///
/// [RetryInterceptor] retries timeouts, connection errors and 502-504 with
/// backoff; a 401 is left to [AuthInterceptor] ahead of it.
@visibleForTesting
List<Interceptor> serviceInterceptors({
  required LoadingManager loadingManager,
  required AuthInterceptor authInterceptor,
  required RetryInterceptor retryInterceptor,
}) => [
  ErrorInterceptor(loadingManager: loadingManager),
  authInterceptor,
  retryInterceptor,
  LoggingInterceptor(),
];

Dio _buildDio(
  String baseUrl,
  HttpClientAdapter? pinnedAdapter,
  List<Interceptor> interceptors, {
  required Map<String, String> headers,
}) {
  // Standard timeout policy from the framework (NetworkDefaults).
  final dio = Dio(NetworkDefaults.baseOptions(baseUrl: baseUrl));
  // Adapter đã pin (nếu app khai CERT_PINS) — đặt trước khi thêm interceptor,
  // vì nó thay thế httpClientAdapter của client.
  if (pinnedAdapter != null) dio.httpClientAdapter = pinnedAdapter;

  // App version, installation and client source (ClientIdentity).
  dio.options.headers.addAll(headers);

  if (alice != null) {
    final aliceDioAdapter = AliceDioAdapter();
    alice!.addAdapter(aliceDioAdapter);
    dio.interceptors.add(aliceDioAdapter);
  }
  dio.interceptors.addAll(interceptors);
  return dio;
}
