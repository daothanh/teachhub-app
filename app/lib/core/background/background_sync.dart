import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasco_core/tasco_core.dart';
import 'package:tasco_storage/tasco_storage.dart';
import 'package:teacher/teacher.dart';
import 'package:workmanager/workmanager.dart';

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

/// `inputData` của tác vụ: isolate nền không có `GetIt`/dotenv nên mang theo
/// cấu hình mạng. Việc bắt buộc pin KHÔNG đi qua đây (xem [syncOutboxFromInput]).
@visibleForTesting
Map<String, Object?> backgroundInput({
  required String apiUrl,
  required Set<String> pins,
}) => {_apiUrlKey: apiUrl, _pinsKey: pins.join(',')};

Future<void> _schedule(Map<String, Object?> input) =>
    Workmanager().registerOneOffTask(
      outboxSyncTask,
      outboxSyncTask,
      constraints: Constraints(networkType: NetworkType.connected),
      // Android: lượt đang chờ/đang chạy giữ nguyên, lượt chạy hỏng tự thử lại
      // (backoff). iOS: BGTask chỉ chạy một lần nên [runBackgroundTask] tự hẹn
      // lại khi còn dòng.
      existingWorkPolicy: ExistingWorkPolicy.keep,
      inputData: input,
    );

/// Móc hẹn/hủy cho mini-app teacher. Lỗi plugin chỉ ghi log, không chặn luồng
/// chính.
BackgroundSyncHooks workmanagerSyncHooks({
  required String apiUrl,
  required Set<String> pins,
}) => BackgroundSyncHooks(
  schedule: () =>
      _guard(() => _schedule(backgroundInput(apiUrl: apiUrl, pins: pins))),
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
  Workmanager().executeTask((task, input) {
    final keys = SecureStore();
    final tokens = TokenStore(keys);
    return runBackgroundTask(
      task: task,
      hasSession: () async => await tokens.getAccessToken() != null,
      sync: () => syncOutboxFromInput(
        input ?? const {},
        keys: keys,
        accessToken: tokens.getAccessToken,
        userId: _cachedUserId,
        directory: getApplicationDocumentsDirectory,
        clientInfo: TeachHubHeadersInterceptor.resolveClientInfo,
      ),
      cancel: () =>
          _guard(() => Workmanager().cancelByUniqueName(outboxSyncTask)),
      reschedule: () => _guard(() => _schedule(Map.of(input ?? const {}))),
    );
  });
}

Future<String?> _cachedUserId() async {
  final prefs = await SharedPreferences.getInstance();
  final user = await JsonStore<TeachHubUser>(
    store: SharedPrefsStore(prefs),
    key: _userKey,
    fromJson: TeachHubUser.fromJson,
    toJson: (u) => u.toJson(),
  ).read();
  return user?.id;
}

/// Quyết định có chạy không, tách khỏi plugin để test. Trả `true` = xong (hệ
/// điều hành không thử lại), `false` = thử lại.
///
/// Chưa đăng nhập → không chạy, không xin thử lại. Đọc Keychain lỗi (máy khóa
/// màn hình, `WhenUnlocked`) → `false`: đợi lần sau. Còn dòng chờ trên iOS thì
/// hẹn lại, vì BGTask không tự lặp.
@visibleForTesting
Future<bool> runBackgroundTask({
  required String task,
  required Future<bool> Function() hasSession,
  required Future<BackgroundSyncOutcome> Function() sync,
  required Future<void> Function() cancel,
  required Future<void> Function() reschedule,
  bool? isIOS,
}) async {
  if (task != outboxSyncTask) return true;
  try {
    if (!await hasSession()) return true;
    switch (await sync()) {
      case BackgroundSyncOutcome.done:
        return true;
      case BackgroundSyncOutcome.notAllowed:
        await cancel();
        return true;
      case BackgroundSyncOutcome.retry:
        if (isIOS ?? Platform.isIOS) await reschedule();
        return false;
    }
  } catch (e) {
    log('Đồng bộ nền bỏ lượt (${e.runtimeType})', name: 'background');
    return false;
  }
}

/// Phần thuần Dart của callback nền: dựng Dio rồi chạy một lượt. Thiếu cấu
/// hình thì không gửi gì.
@visibleForTesting
Future<BackgroundSyncOutcome> syncOutboxFromInput(
  Map<String, dynamic> input, {
  required KeyValueStore keys,
  required Future<String?> Function() accessToken,
  required Future<String?> Function() userId,
  required Future<Directory> Function() directory,
  required Future<String> Function() clientInfo,
  @visibleForTesting
  Future<BackgroundSyncOutcome> Function({
    required Dio dio,
    required KeyValueStore keys,
    required Directory directory,
    required Future<String?> Function() currentUserId,
  })?
  runner,
}) async {
  final apiUrl = input[_apiUrlKey] as String?;
  if (apiUrl == null || apiUrl.isEmpty) return BackgroundSyncOutcome.done;
  final dio = buildBackgroundDio(
    apiUrl: apiUrl,
    pins: {
      for (final p in (input[_pinsKey] as String? ?? '').split(','))
        if (p.trim().isNotEmpty) p.trim(),
    },
    accessToken: accessToken,
    clientInfo: await clientInfo(),
  );
  return (runner ?? _defaultRunner)(
    dio: dio,
    keys: keys,
    directory: await directory(),
    currentUserId: userId,
  );
}

Future<BackgroundSyncOutcome> _defaultRunner({
  required Dio dio,
  required KeyValueStore keys,
  required Directory directory,
  required Future<String?> Function() currentUserId,
}) => runOutboxSyncOnce(
  dio: dio,
  keys: keys,
  directory: directory,
  currentUserId: currentUserId,
);

/// Client API cho isolate nền: cùng header như client của shell và Bearer là
/// access token hiện có. KHÔNG làm mới token (làm mới ở isolate thứ hai sẽ
/// đua với app, phát `sessionExpired`/xóa token): 401 chỉ là một lỗi, lượt này
/// bỏ và hệ điều hành thử lại sau khi app mở. Pin giống client của shell: có
/// [pins] thì pin, rỗng thì TLS thường (MVP chưa bật pin, Tech Spec §bảo mật).
@visibleForTesting
Dio buildBackgroundDio({
  required String apiUrl,
  required Set<String> pins,
  required Future<String?> Function() accessToken,
  required String clientInfo,
}) {
  final dio = Dio(NetworkDefaults.baseOptions(baseUrl: apiUrl));
  if (pins.isNotEmpty) {
    dio.httpClientAdapter = CertificatePinning.adapter(allowedSha256: pins);
  }
  dio.interceptors.addAll([
    TeachHubHeadersInterceptor(clientInfo: clientInfo),
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await accessToken();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
    ),
  ]);
  return dio;
}

/// Khi nào hủy lịch nền theo trạng thái phiên. Không hủy ở state ban đầu
/// (đang kiểm phiên lúc khởi động nguội: chưa biết là có hay không), chỉ khi
/// vừa đăng xuất/hết phiên hoặc kiểm xong mà không có phiên.
///
/// Kiểm phiên có thể `failure` khi mất mạng lúc khởi động nguội (chưa có user
/// cache) dù token vẫn còn trong kho: nên chỉ coi là "không có phiên" khi kho
/// không còn token ([hasStoredToken] = false).
bool shouldCancelBackgroundSync({
  required bool wasAuthenticated,
  required bool isAuthenticated,
  required bool sessionChecked,
  required bool hasStoredToken,
}) =>
    !isAuthenticated &&
    (wasAuthenticated || (sessionChecked && !hasStoredToken));
