import 'package:connectivity_plus/connectivity_plus.dart';

/// `true` khi máy có mạng (Wi-Fi/di động/…): trạng thái hiện tại rồi mỗi lần đổi.
/// Chỉ là gợi ý — có Wi-Fi chưa chắc tới được API, SyncEngine vẫn tự backoff.
/// Lỗi plugin (vd. trong test) bị bỏ qua: coi như không biết, không báo ngoại tuyến.
Stream<bool> onlineChanges([Connectivity? connectivity]) async* {
  final c = connectivity ?? Connectivity();
  bool up(List<ConnectivityResult> r) =>
      r.any((x) => x != ConnectivityResult.none);
  try {
    yield up(await c.checkConnectivity());
    yield* c.onConnectivityChanged.map(up);
  } catch (_) {}
}
