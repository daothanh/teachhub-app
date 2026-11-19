import 'dart:async';
import 'dart:developer';

/// Kết quả [LogoutService.logout].
enum LogoutResult {
  /// Đã đăng xuất và xóa CSDL cục bộ.
  done,

  /// Người dùng ở lại.
  cancelled,

  /// Đã đăng xuất nhưng xóa CSDL lỗi; sẽ xóa nốt ở lần khởi động sau.
  wipeFailed,
}

/// Đăng xuất kèm xóa CSDL cục bộ (spec §6.4): outbox trống thì xóa; còn dữ
/// liệu chưa đồng bộ (hoặc không đọc được) thì chỉ xóa khi người dùng xác nhận.
class LogoutService {
  LogoutService({
    required Future<void> Function() logout,
    required Future<int> Function() pendingCount,
    required Future<void> Function() wipeLocalData,
  }) : _logout = logout,
       _pendingCount = pendingCount,
       _wipe = wipeLocalData;

  final Future<void> Function() _logout;
  final Future<int> Function() _pendingCount;
  final Future<void> Function() _wipe;
  Future<bool>? _expiredRun;

  /// `null` = không đọc được (CSDL hỏng, mất khóa).
  Future<int?> _count() async {
    try {
      return await _pendingCount();
    } catch (e, st) {
      log('Đọc outbox lỗi', name: 'logout', error: e, stackTrace: st);
      return null;
    }
  }

  /// Số buổi chưa đồng bộ trên máy, `null` khi không đọc được (xóa tài khoản
  /// dùng để cảnh báo trước khi gọi `DELETE /me`).
  Future<int?> pendingCount() => _count();

  /// [confirmDiscard] nhận số buổi chưa đồng bộ, hoặc `null` khi không đọc
  /// được; trả `false` là ở lại (không đăng xuất, không xóa gì). Sau khi xác
  /// nhận, đếm lại: số tăng lên thì hỏi lại với số mới.
  Future<LogoutResult> logout({
    required Future<bool> Function(int? pending) confirmDiscard,
  }) async {
    var asked = await _count();
    while (asked != 0) {
      if (!await confirmDiscard(asked)) return LogoutResult.cancelled;
      final now = await _count();
      if (asked == null || now == null || now <= asked) break;
      asked = now;
    }
    await _logout();
    return await _safeWipe() ? LogoutResult.done : LogoutResult.wipeFailed;
  }

  /// Phiên hết hạn (refresh hỏng): không còn token để đồng bộ và không hỏi
  /// được người dùng, nên chỉ xóa khi outbox trống; còn dữ liệu (hoặc không
  /// đọc được) thì giữ để đồng bộ sau lần đăng nhập kế tiếp của cùng người.
  /// Nhiều sự kiện liên tiếp chỉ chạy một lần.
  Future<bool> onSessionExpired() =>
      _expiredRun ??= _expired().whenComplete(() => _expiredRun = null);

  Future<bool> _expired() async {
    if (await _count() != 0) return false;
    return _safeWipe();
  }

  Future<bool> _safeWipe() async {
    try {
      await _wipe();
      return true;
    } catch (e, st) {
      log('Xóa CSDL cục bộ lỗi', name: 'logout', error: e, stackTrace: st);
      return false;
    }
  }
}
