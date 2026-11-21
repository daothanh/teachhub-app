import 'dart:async';
import 'dart:convert';

import 'package:app/core/push/foreground_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAndroid extends Fake
    implements AndroidFlutterLocalNotificationsPlugin {
  final channels = <AndroidNotificationChannel>[];

  @override
  Future<void> createNotificationChannel(
    AndroidNotificationChannel notificationChannel,
  ) async => channels.add(notificationChannel);
}

class _FakePlugin extends Fake implements FlutterLocalNotificationsPlugin {
  final android = _FakeAndroid();
  final shown =
      <({String? title, String? body, String? channel, String? payload})>[];
  void Function(NotificationResponse)? onResponse;
  NotificationAppLaunchDetails? launch;
  bool failInit = false;

  @override
  Future<bool?> initialize(
    InitializationSettings initializationSettings, {
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    if (failInit) throw StateError('init lỗi');
    onResponse = onDidReceiveNotificationResponse;
    return true;
  }

  @override
  T? resolvePlatformSpecificImplementation<
    T extends FlutterLocalNotificationsPlatform
  >() => android as T;

  @override
  Future<NotificationAppLaunchDetails?>
  getNotificationAppLaunchDetails() async => launch;

  @override
  Future<void> show(
    int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails, {
    String? payload,
  }) async => shown.add((
    title: title,
    body: body,
    channel: notificationDetails?.android?.channelId,
    payload: payload,
  ));
}

void main() {
  late _FakePlugin plugin;
  late StreamController<RemoteMessage> messages;
  late List<Map<String, dynamic>> taps;
  var iosPresented = 0;

  ForegroundNotifications build({bool android = true, Locale? locale}) =>
      ForegroundNotifications(
        plugin: plugin,
        messages: messages.stream,
        onTap: (d) async => taps.add(d),
        locale: () => locale ?? const Locale('vi'),
        presentOnIos: () async => iosPresented++,
        isAndroid: android,
      );

  RemoteMessage msg({String? channel, Map<String, String> data = const {}}) =>
      RemoteMessage(
        data: data,
        notification: RemoteNotification(
          title: 'Con vắng học',
          body: 'Bé An vắng buổi sáng',
          android: AndroidNotification(channelId: channel),
        ),
      );

  setUp(() {
    plugin = _FakePlugin();
    messages = StreamController<RemoteMessage>.broadcast();
    taps = [];
    iosPresented = 0;
  });

  tearDown(() => messages.close());

  test(
    'Android tạo 3 kênh, attendance quan trọng cao, tên theo ngôn ngữ',
    () async {
      await build().start();
      final c = plugin.android.channels;
      expect(c.map((e) => e.id), ['attendance', 'billing', 'general']);
      expect(c.first.importance, Importance.high);
      expect(c.map((e) => e.name), ['Điểm danh', 'Học phí', 'Thông báo chung']);
    },
  );

  test(
    'ngôn ngữ en đặt tên kênh tiếng Anh; ngôn ngữ lạ về tiếng Việt',
    () async {
      await build(locale: const Locale('en')).start();
      expect(plugin.android.channels.first.name, 'Attendance');
      plugin.android.channels.clear();
      await build(locale: const Locale('fr')).start();
      expect(plugin.android.channels.first.name, 'Điểm danh');
    },
  );

  test(
    'Android foreground: hiện local notification đúng kênh, kèm data',
    () async {
      await build().start();
      messages.add(
        msg(channel: 'attendance', data: {'type': 'student_absent'}),
      );
      await pumpEventQueue();
      expect(plugin.shown.single.title, 'Con vắng học');
      expect(plugin.shown.single.channel, 'attendance');
      expect(jsonDecode(plugin.shown.single.payload!), {
        'type': 'student_absent',
      });
    },
  );

  test(
    'kênh lạ hoặc thiếu → general; tin không có notification thì bỏ qua',
    () async {
      await build().start();
      messages
        ..add(msg(channel: 'abc'))
        ..add(msg())
        ..add(RemoteMessage(data: {'type': 'x'}));
      await pumpEventQueue();
      expect(plugin.shown.map((e) => e.channel), ['general', 'general']);
    },
  );

  test('chạm thông báo cục bộ → onTap với data gốc', () async {
    await build().start();
    plugin.onResponse!(
      const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: '{"type":"invoice_issued","notificationId":"n1"}',
      ),
    );
    await pumpEventQueue();
    expect(taps, [
      {'type': 'invoice_issued', 'notificationId': 'n1'},
    ]);
  });

  test('payload hỏng không làm app lỗi', () async {
    await build().start();
    plugin.onResponse!(
      const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: 'không phải json',
      ),
    );
    await pumpEventQueue();
    expect(taps, isEmpty);
  });

  test('app mở từ thông báo cục bộ lúc đã tắt → onTap', () async {
    plugin.launch = const NotificationAppLaunchDetails(
      true,
      notificationResponse: NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: '{"type":"billing_ready"}',
      ),
    );
    await build().start();
    expect(taps, [
      {'type': 'billing_ready'},
    ]);
  });

  test('initialize ném lỗi vẫn nhận và hiện tin', () async {
    plugin.failInit = true;
    await build().start();
    messages.add(msg(channel: 'billing'));
    await pumpEventQueue();
    expect(plugin.shown.single.channel, 'billing');
  });

  test('payload là JSON hợp lệ nhưng không phải Map: bỏ qua', () async {
    await build().start();
    plugin.onResponse!(
      const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: '[1,2]',
      ),
    );
    await pumpEventQueue();
    expect(taps, isEmpty);
  });

  test('stop() ngừng hiện tin', () async {
    final n = build();
    await n.start();
    await n.stop();
    messages.add(msg());
    await pumpEventQueue();
    expect(plugin.shown, isEmpty);
  });

  test(
    'iOS bật presentation options, không vẽ local, không tạo kênh',
    () async {
      await build(android: false).start();
      messages.add(msg(channel: 'attendance'));
      await pumpEventQueue();
      expect(iosPresented, 1);
      expect(plugin.shown, isEmpty);
      expect(plugin.android.channels, isEmpty);
    },
  );
}
