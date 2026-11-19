import 'package:flutter/widgets.dart';
import 'package:tasco_storage/tasco_storage.dart';
import 'package:teacher/teacher.dart';

/// Ghi cờ "app đang foreground" vào kho khóa để callback nền bỏ lượt khi app
/// đang tự đồng bộ (tránh hai isolate cùng ghi CSDL).
class ForegroundTracker with WidgetsBindingObserver {
  ForegroundTracker(this._keys);

  final KeyValueStore _keys;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    final s = WidgetsBinding.instance.lifecycleState;
    markForeground(_keys, s == null || s == AppLifecycleState.resumed);
  }

  void stop() => WidgetsBinding.instance.removeObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    markForeground(_keys, state == AppLifecycleState.resumed);
  }
}
