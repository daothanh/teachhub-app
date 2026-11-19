import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:tasco_storage/tasco_storage.dart';

import '../local_db/teacher_database.dart';
import '../remote/teacher_api.dart';
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

/// Callback nền: mở CSDL mã hóa (khóa từ [keys]), đẩy outbox một lượt qua
/// [SyncEngine] rồi đóng. Trả `true` khi xong (hoặc không có gì để làm);
/// `false` khi còn mutation chờ để hệ điều hành thử lại.
///
/// Không tạo file CSDL mới: chưa có file nghĩa là chưa có gì để gửi.
Future<bool> runOutboxSyncOnce({
  required Dio dio,
  required KeyValueStore keys,
  required Directory directory,
  @visibleForTesting Future<TeacherDatabase> Function()? open,
}) async {
  if (!File('${directory.path}/$teacherDatabaseFile').existsSync()) {
    return true;
  }
  final db = await (open ?? () => TeacherDatabase.openEncrypted(keys))();
  try {
    final api = await loadTeacherApi(dio, keys);
    final report = await SyncEngine(db, api.sync).drain();
    return report.retryIn == null;
  } catch (e) {
    // Chỉ ghi loại lỗi, không ghi nội dung (có tên học viên).
    log('Đồng bộ nền lỗi: ${e.runtimeType}', name: 'teacher');
    return false;
  } finally {
    await db.close();
  }
}
