import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io' show Platform;
import 'dart:ui' show Locale;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../l10n/l10n.dart';

/// Kênh thông báo Android; backend gửi `channelId` thuộc nhóm này.
const pushChannelIds = ['attendance', 'billing', 'general'];

/// Hiện thông báo khi app đang mở và đưa cú chạm về cùng đường với thông báo
/// hệ thống.
///
/// - Android: FCM không tự vẽ khi app ở foreground, nên vẽ bằng local
///   notification đúng kênh; chạm → [onTap] với `data` của tin.
/// - iOS: bật presentation options để hệ thống tự vẽ (không vẽ thêm, tránh trùng);
///   chạm đi qua `onMessageOpenedApp`.
class ForegroundNotifications {
  ForegroundNotifications({
    required this.onTap,
    required this.locale,
    FlutterLocalNotificationsPlugin? plugin,
    Stream<RemoteMessage>? messages,
    Future<void> Function()? presentOnIos,
    bool? isAndroid,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _messages = messages ?? FirebaseMessaging.onMessage,
       _presentOnIos =
           presentOnIos ??
           (() => FirebaseMessaging.instance
               .setForegroundNotificationPresentationOptions(
                 alert: true,
                 badge: true,
                 sound: true,
               )),
       _isAndroid = isAndroid ?? Platform.isAndroid;

  final Future<void> Function(Map<String, dynamic> data) onTap;
  final Locale Function() locale;
  final FlutterLocalNotificationsPlugin _plugin;
  final Stream<RemoteMessage> _messages;
  final Future<void> Function() _presentOnIos;
  final bool _isAndroid;
  StreamSubscription<RemoteMessage>? _sub;
  var _nextId = 0;

  Future<void> start() async {
    if (!_isAndroid) {
      await _presentOnIos();
      return;
    }
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (r) => _tap(r.payload),
    );
    await createChannels();
    _sub = _messages.listen(
      (m) => unawaited(_show(m)),
      onError: (Object e) => log('Foreground push lỗi: $e', name: 'push'),
    );
    // App bị tắt rồi người dùng chạm thông báo cục bộ còn trên khay.
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _tap(launch!.notificationResponse?.payload);
    }
  }

  Future<void> stop() async => _sub?.cancel();

  Future<void> createChannels() async {
    final l10n = lookupAppLocalizations(_supported(locale()));
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    for (final (id, name, importance) in [
      ('attendance', l10n.pushChannelAttendance, Importance.high),
      ('billing', l10n.pushChannelBilling, Importance.defaultImportance),
      ('general', l10n.pushChannelGeneral, Importance.defaultImportance),
    ]) {
      await android?.createNotificationChannel(
        AndroidNotificationChannel(id, name, importance: importance),
      );
    }
  }

  Future<void> _show(RemoteMessage m) async {
    final n = m.notification;
    if (n == null) return;
    final hinted = n.android?.channelId;
    final channel = pushChannelIds.contains(hinted) ? hinted! : 'general';
    try {
      await _plugin.show(
        _nextId++,
        n.title,
        n.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel,
            channel,
            importance: channel == 'attendance'
                ? Importance.high
                : Importance.defaultImportance,
            priority: channel == 'attendance'
                ? Priority.high
                : Priority.defaultPriority,
          ),
        ),
        payload: jsonEncode(m.data),
      );
    } catch (e) {
      log('Hiện thông báo foreground lỗi: ${e.runtimeType}', name: 'push');
    }
  }

  void _tap(String? payload) {
    if (payload == null) return;
    try {
      final data = (jsonDecode(payload) as Map).cast<String, dynamic>();
      unawaited(onTap(data));
    } catch (e) {
      log('Payload thông báo lỗi: ${e.runtimeType}', name: 'push');
    }
  }

  static Locale _supported(Locale l) =>
      AppLocalizations.supportedLocales.any(
        (s) => s.languageCode == l.languageCode,
      )
      ? Locale(l.languageCode)
      : const Locale('vi');
}
