import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasco_auth/tasco_auth.dart';
import 'package:tasco_core/tasco_core.dart';
import 'package:tasco_storage/tasco_storage.dart';
import 'package:teacher/teacher.dart';
import 'package:workmanager/workmanager.dart';

import '../../features/auth/auth_config.dart';
import '../../features/auth/teachhub_user.dart';
import '../network/teachhub_headers_interceptor.dart';

/// Tên tác vụ nền đẩy outbox. Trên iOS đây cũng là định danh BGTask, nên phải
/// khớp `BGTaskSchedulerPermittedIdentifiers` trong Info.plist.
const outboxSyncTask = 'vn.dayhoc.app.sync-outbox';

const _apiUrlKey = 'apiUrl';
const _pinsKey = 'pins';
const _userKey = 'user_info';

bool get _supported => Platform.isAndroid || Platform.isIOS;

/// Khai báo dispatcher nền với workmanager. Gọi một lần khi khởi động, trước
/// khi hẹn lịch. Máy tính (test, desktop) bỏ qua.
Future<void> initBackgroundSync() async {
  if (!_supported) return;
  await Workmanager().initialize(teachHubBackgroundDispatcher);
}

/// Móc hẹn/hủy cho mini-app teacher. Hẹn một lượt khi có mạng (Android:
/// WorkManager; iOS: BGProcessingTask); lỗi plugin chỉ ghi log, không chặn
/// luồng chính. [apiUrl] và [pins] truyền qua `inputData` vì isolate nền không
/// có `GetIt`/dotenv.
BackgroundSyncHooks workmanagerSyncHooks({
  required String apiUrl,
  required Set<String> pins,
}) => BackgroundSyncHooks(
  schedule: () => _guard(
    () => Workmanager().registerOneOffTask(
      outboxSyncTask,
      outboxSyncTask,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      inputData: {_apiUrlKey: apiUrl, _pinsKey: pins.join(',')},
    ),
  ),
  cancel: () => _guard(() => Workmanager().cancelByUniqueName(outboxSyncTask)),
);

Future<void> _guard(Future<void> Function() job) async {
  if (!_supported) return;
  try {
    await job();
  } catch (e) {
    log('Đồng bộ nền: plugin lỗi (${e.runtimeType})', name: 'background');
  }
}

/// Điểm vào của isolate nền (cả Android lẫn iOS).
@pragma('vm:entry-point')
void teachHubBackgroundDispatcher() {
  Workmanager().executeTask(
    (task, input) => runBackgroundTask(
      task: task,
      hasSession: _hasSession,
      sync: () => _syncOutbox(input ?? const {}),
    ),
  );
}

/// Quyết định có chạy không, tách khỏi plugin để test. Chưa đăng nhập (hoặc
/// đã đăng xuất, token bị xóa) thì không chạy và không xin thử lại. Trả về
/// kết quả của [sync]: `false` để hệ điều hành thử lại.
@visibleForTesting
Future<bool> runBackgroundTask({
  required String task,
  required Future<bool> Function() hasSession,
  required Future<bool> Function() sync,
}) async {
  if (task != outboxSyncTask) return true;
  if (!await hasSession()) return true;
  return sync();
}

Future<bool> _hasSession() async {
  final tokens = TokenStore(SecureStore());
  return await tokens.getAccessToken() != null ||
      await tokens.getRefreshToken() != null;
}

Future<bool> _syncOutbox(Map<String, dynamic> input) async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiUrl = input[_apiUrlKey] as String?;
  if (apiUrl == null || apiUrl.isEmpty) return true;
  final pins = {
    for (final p in (input[_pinsKey] as String? ?? '').split(','))
      if (p.trim().isNotEmpty) p.trim(),
  };
  final keys = SecureStore();
  final dio = await _buildBackgroundDio(apiUrl, pins);
  return runOutboxSyncOnce(
    dio: dio,
    keys: keys,
    directory: await getApplicationDocumentsDirectory(),
  );
}

/// Client API cho isolate nền: cùng header và làm mới token như client của
/// shell, nhưng không có overlay loading, alice hay `GetIt`.
Future<Dio> _buildBackgroundDio(String apiUrl, Set<String> pins) async {
  final adapter = pins.isEmpty
      ? null
      : CertificatePinning.adapter(allowedSha256: pins);
  final tokens = TokenStore(SecureStore());
  final bus = AuthEventBus();
  final prefs = await SharedPreferences.getInstance();
  final auth = DioAuthRepository<TeachHubUser>(
    dio: Dio(NetworkDefaults.baseOptions(baseUrl: apiUrl)),
    tokenStore: tokens,
    config: teachHubAuthConfig,
    userCache: JsonStore<TeachHubUser>(
      store: SharedPrefsStore(prefs),
      key: _userKey,
      fromJson: TeachHubUser.fromJson,
      toJson: (u) => u.toJson(),
    ),
    settingsStore: SharedPrefsStore(prefs),
  );
  final refresher = TokenRefresher(
    refresh: () => auth.refreshToken(),
    authEventBus: bus,
  );
  final dio = Dio(NetworkDefaults.baseOptions(baseUrl: apiUrl));
  if (adapter != null) dio.httpClientAdapter = adapter;
  dio.interceptors.addAll([
    TeachHubHeadersInterceptor(
      clientInfo: await TeachHubHeadersInterceptor.resolveClientInfo(),
    ),
    AuthInterceptor(
      () => tokens.getAccessToken(),
      () => refresher,
      retryClient: AuthInterceptor.buildRetryClient(adapter: adapter),
      authEventBus: bus,
    ),
    RetryInterceptor(
      retryClient: RetryInterceptor.buildRetryClient(adapter: adapter),
    ),
  ]);
  return dio;
}
