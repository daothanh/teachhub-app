import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:tasco_storage/tasco_storage.dart';

import '../local_db/teacher_database.dart';
import '../local_db/teacher_local_data.dart';
import '../remote/teacher_api.dart';
import 'background_flags.dart';
import 'sync_engine.dart';
import 'uuid.dart';

/// Móc hẹn/hủy đồng bộ nền do shell cài (workmanager Android, BGTask iOS);
/// mini-app không phụ thuộc plugin nền.
class BackgroundSyncHooks {
  const BackgroundSyncHooks({required this.schedule, required this.cancel});

  /// Hẹn một lượt đẩy outbox khi có mạng (gọi lại nhiều lần vẫn là một lịch).
  final Future<void> Function() schedule;

  /// Hủy lịch (outbox hết, đăng xuất, xóa dữ liệu).
  final Future<void> Function() cancel;
}

const teacherDeviceIdKey = 'teacher.device_id';

/// Mã thiết bị ổn định của máy này (không xóa khi đăng xuất: là của máy).
Future<TeacherApi> loadTeacherApi(Dio dio, KeyValueStore keys) async {
  var id = await keys.read(teacherDeviceIdKey);
  if (id == null) {
    id = newUuid();
    await keys.write(teacherDeviceIdKey, id);
  }
  return TeacherApi(dio, deviceId: id);
}

/// Kết quả một lượt nền.
enum BackgroundSyncOutcome {
  /// Xong, hoặc không có gì để làm.
  done,

  /// Còn mutation chờ (mất mạng, token hết hạn...): hệ điều hành thử lại.
  retry,

  /// Không được đồng bộ (đang xóa, sai chủ, mất phiên): hủy lịch.
  notAllowed,
}

/// Callback nền: mở CSDL mã hóa bằng khóa đã có trong [keys], đẩy outbox qua
/// [SyncEngine] rồi đóng.
///
/// - Chỉ ĐỌC khóa: chưa có khóa nghĩa là chưa có CSDL, không sinh khóa mới.
/// - [currentUserId] (người của token hiện tại) phải trùng chủ CSDL
///   ([TeacherLocalData.ownerKey]); đang xóa dở ([TeacherLocalData.wipePendingKey])
///   hoặc lệch chủ thì không đồng bộ. Kiểm trước khi mở và định kỳ trong lúc
///   gửi ([recheckEvery]); vi phạm giữa chừng thì dừng engine.
/// - App đang foreground thì bỏ lượt (engine trong app lo).
/// - Đặt cờ "đang chạy nền" để wipe chờ ta đóng CSDL.
Future<BackgroundSyncOutcome> runOutboxSyncOnce({
  required Dio dio,
  required KeyValueStore keys,
  required Directory directory,
  required Future<String?> Function() currentUserId,
  Duration recheckEvery = const Duration(seconds: 1),
  @visibleForTesting TeacherDatabase Function(String key)? open,
}) async {
  Future<BackgroundSyncOutcome?> gate() async {
    if (await keys.contains(TeacherLocalData.wipePendingKey)) {
      return BackgroundSyncOutcome.notAllowed;
    }
    final user = await currentUserId();
    if (user == null || await keys.read(TeacherLocalData.ownerKey) != user) {
      return BackgroundSyncOutcome.notAllowed;
    }
    return null;
  }

  if (!File('${directory.path}/$teacherDatabaseFile').existsSync()) {
    return BackgroundSyncOutcome.done;
  }
  final key = await readDatabaseKey(keys);
  if (key == null) return BackgroundSyncOutcome.done;
  final blocked = await gate();
  if (blocked != null) return blocked;
  if (await isForeground(keys)) return BackgroundSyncOutcome.done;

  await markBackgroundRunning(keys, true);
  TeacherDatabase? db;
  Timer? watch;
  var stoppedByGate = false;
  try {
    // Wipe có thể bắt đầu giữa lúc đặt cờ và mở: kiểm lại ngay sau cờ.
    final again = await gate();
    if (again != null) return again;
    db = (open ?? TeacherDatabase.openWithKey)(key);
    final api = await loadTeacherApi(dio, keys);
    final engine = SyncEngine(db, api.sync);
    var checking = false;
    watch = Timer.periodic(recheckEvery, (_) async {
      if (checking) return;
      checking = true;
      try {
        if (await gate() != null) {
          stoppedByGate = true;
          await engine.stop();
        }
      } catch (_) {
      } finally {
        checking = false;
      }
    });
    await engine.drain();
    if (stoppedByGate) return BackgroundSyncOutcome.notAllowed;
    return await pendingOutboxCount(db) == 0
        ? BackgroundSyncOutcome.done
        : BackgroundSyncOutcome.retry;
  } catch (e) {
    // Chỉ ghi loại lỗi, không ghi nội dung (có tên học viên).
    log('Đồng bộ nền lỗi: ${e.runtimeType}', name: 'teacher');
    return BackgroundSyncOutcome.retry;
  } finally {
    watch?.cancel();
    await db?.close();
    await markBackgroundRunning(keys, false);
  }
}
