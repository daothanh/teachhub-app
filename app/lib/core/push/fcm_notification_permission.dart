import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:parent/parent.dart';

/// Quyền thông báo thật (FCM) cho banner "bật thông báo" của P02.
class FcmNotificationPermission implements NotificationPermissionGate {
  FcmNotificationPermission({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  static bool _on(NotificationSettings s) =>
      s.authorizationStatus == AuthorizationStatus.authorized ||
      s.authorizationStatus == AuthorizationStatus.provisional;

  @override
  Future<bool> isEnabled() async =>
      _on(await _messaging.getNotificationSettings());

  @override
  Future<bool> request() async => _on(await _messaging.requestPermission());
}
