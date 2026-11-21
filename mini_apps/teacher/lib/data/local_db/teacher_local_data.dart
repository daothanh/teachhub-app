import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;

import 'package:tasco_storage/tasco_storage.dart';

import '../../features/onboarding/data/onboarding_draft.dart';
import '../sync/background_flags.dart';
import 'teacher_database.dart';

/// Dữ liệu cục bộ của teacher gắn với phiên đăng nhập (spec §6.4): đếm buổi
/// chưa đồng bộ, xóa khi đăng xuất, và không để người đăng nhập sau thấy dữ
/// liệu của người trước. Mọi thao tác chạy tuần tự qua một hàng đợi.
class TeacherLocalData {
  TeacherLocalData({
    required KeyValueStore keyStore,
    required Future<Directory> Function() directory,
    required Future<TeacherDatabase> Function() database,
    required Future<void> Function() close,
    required Future<void> Function() reopen,
    Future<void> Function()? pauseSync,
    Future<void> Function()? resumeSync,
  }) : _pauseSync = pauseSync,
       _resumeSync = resumeSync,
       _keys = keyStore,
       _dir = directory,
       _db = database,
       _close = close,
       _reopen = reopen;

  final KeyValueStore _keys;
  final Future<Directory> Function() _dir;
  final Future<TeacherDatabase> Function() _db;
  final Future<void> Function() _close;
  final Future<void> Function() _reopen;

  /// Dừng SyncEngine và chờ lượt đang chạy xong, trước khi đóng CSDL; chạy
  /// lại sau khi mở lại CSDL. Không để sync ghi vào CSDL đang bị xóa.
  final Future<void> Function()? _pauseSync;
  final Future<void> Function()? _resumeSync;

  static const ownerKey = 'teacher.db_owner';

  /// Có ở đây = lần xóa trước chưa xong, phải xóa nốt trước khi dùng tiếp.
  static const wipePendingKey = 'teacher.wipe_pending';

  Future<void> _tail = Future.value();
  Future<T> _serial<T>(Future<T> Function() job) {
    final run = _tail.then((_) => job());
    _tail = run.then<void>((_) {}, onError: (_) {});
    return run;
  }

  /// Số buổi chưa đồng bộ. Chưa có file CSDL thì 0 và không tạo file.
  Future<int> pendingSyncCount() => _serial(_count);

  /// Số mutation bị từ chối/lô lỗi: cảnh báo khi đăng xuất, cho phép bỏ.
  Future<int> failedSyncCount() => _serial(() async {
    final dir = await _dir();
    if (!File('${dir.path}/$teacherDatabaseFile').existsSync()) return 0;
    return failedOutboxCount(await _db());
  });

  Future<void> discardFailed() => _serial(() async {
    final dir = await _dir();
    if (!File('${dir.path}/$teacherDatabaseFile').existsSync()) return;
    await discardFailedOutbox(await _db());
  });

  Future<int> _count() async {
    final dir = await _dir();
    if (!File('${dir.path}/$teacherDatabaseFile').existsSync()) return 0;
    return pendingOutboxCount(await _db());
  }

  /// Đặt cờ xóa trước khi gọi `DELETE /me`: app chết sau khi server đã xóa thì
  /// lần khởi động sau [retryPendingWipe] vẫn dọn máy.
  Future<void> markWipePending() =>
      _serial(() => _keys.write(wipePendingKey, '1'));

  /// Bỏ cờ khi `DELETE /me` bị từ chối hẳn (tài khoản còn nguyên).
  Future<void> clearWipePending() =>
      _serial(() => _keys.delete(wipePendingKey));

  /// Xóa CSDL và khóa. Ghi cờ trước: lỗi giữa chừng thì [retryPendingWipe]
  /// xóa nốt ở lần sau. Gọi đồng thời nhiều lần chỉ chạy lần lượt.
  Future<void> wipe() => _serial(_wipe);

  Future<void> _wipe() async {
    await _keys.write(wipePendingKey, '1');
    // Isolate nền thấy cờ trên và tự dừng; chờ ngắn cho nó đóng CSDL (quá hạn
    // thì xóa luôn: nền không ghi gì sau khi cờ wipe đã đặt).
    await _waitBackgroundIdle();
    await _pauseSync?.call();
    await _close();
    try {
      await deleteTeacherDatabase(_keys, await _dir());
      await _keys.delete(ownerKey);
      await _keys.delete(OnboardingDraftStore.key);
    } finally {
      await _reopen(); // lỗi xóa vẫn để mini-app dùng lại được CSDL
      await _resumeSync?.call();
    }
    await _keys.delete(wipePendingKey);
  }

  Future<void> _waitBackgroundIdle() async {
    for (var i = 0; i < waitSteps; i++) {
      if (!await isBackgroundRunning(_keys)) return;
      await Future<void>.delayed(waitStep);
    }
    // Quá hạn mà nền vẫn báo chạy: xóa luôn (không ghi dữ liệu cá nhân).
    log('Wipe: nền chưa đóng CSDL sau khi chờ, xóa luôn', name: 'teacher');
  }

  /// Chờ nền đóng CSDL tối đa [waitSteps] × [waitStep].
  @visibleForTesting
  int waitSteps = 25;
  @visibleForTesting
  Duration waitStep = const Duration(milliseconds: 200);

  /// Xóa nốt nếu lần xóa trước dở dang. Gọi khi khởi động.
  Future<void> retryPendingWipe() => _serial(_retry);

  Future<void> _retry() async {
    if (await _keys.contains(wipePendingKey)) await _wipe();
  }

  /// Gọi khi [userId] đăng nhập, trước khi vào mini-app. CSDL còn của người
  /// khác thì xóa: token của họ đã mất nên outbox đó không đồng bộ hợp lệ
  /// được, và dữ liệu có tên học sinh không được lộ cho người sau.
  Future<void> claimFor(String userId) => _serial(() async {
    await _retry();
    final owner = await _keys.read(ownerKey);
    if (owner != null && owner != userId) {
      int? lost;
      try {
        lost = await _count();
      } catch (_) {}
      log(
        'Teacher DB của người dùng khác, xóa (bỏ ${lost ?? 'không rõ'} mutation chưa đồng bộ)',
        name: 'teacher',
      );
      await _wipe();
    }
    await _keys.write(ownerKey, userId);
  });
}
