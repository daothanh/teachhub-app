import 'package:tasco_storage/tasco_storage.dart';

/// Cờ trong kho khóa (Keychain/Keystore) để app và isolate nền không dẫm nhau.
/// Giá trị là thời điểm (ms epoch); cờ quá hạn coi như không còn (app bị kill
/// giữa chừng không làm kẹt vĩnh viễn).
const backgroundRunningKey = 'teacher.bg_running';
const foregroundKey = 'teacher.app_foreground';

const foregroundMaxAge = Duration(minutes: 10);
const backgroundRunningMaxAge = Duration(minutes: 2);

Future<void> _flag(
  KeyValueStore keys,
  String key,
  bool on,
  DateTime now,
) async {
  try {
    on
        ? await keys.write(key, '${now.millisecondsSinceEpoch}')
        : await keys.delete(key);
  } catch (_) {
    // Keychain khóa màn hình: không ghi được thì cờ cũ tự hết hạn.
  }
}

Future<bool> _fresh(
  KeyValueStore keys,
  String key,
  Duration maxAge,
  DateTime now,
) async {
  final ms = int.tryParse(await keys.read(key) ?? '');
  if (ms == null) return false;
  final age = now.difference(DateTime.fromMillisecondsSinceEpoch(ms));
  return age < maxAge;
}

/// Shell gọi theo vòng đời app: `true` khi resumed, `false` khi rời foreground.
Future<void> markForeground(
  KeyValueStore keys,
  bool foreground, {
  DateTime? now,
}) => _flag(keys, foregroundKey, foreground, now ?? DateTime.now());

Future<bool> isForeground(KeyValueStore keys, {DateTime? now}) =>
    _fresh(keys, foregroundKey, foregroundMaxAge, now ?? DateTime.now());

Future<void> markBackgroundRunning(
  KeyValueStore keys,
  bool running, {
  DateTime? now,
}) => _flag(keys, backgroundRunningKey, running, now ?? DateTime.now());

Future<bool> isBackgroundRunning(KeyValueStore keys, {DateTime? now}) => _fresh(
  keys,
  backgroundRunningKey,
  backgroundRunningMaxAge,
  now ?? DateTime.now(),
);
