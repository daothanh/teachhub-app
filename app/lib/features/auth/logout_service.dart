/// Đăng xuất kèm xóa CSDL cục bộ (spec §6.4): outbox trống thì xóa; còn dữ
/// liệu chưa đồng bộ thì chỉ xóa khi người dùng xác nhận.
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

  /// Trả `false` khi người dùng bỏ qua cảnh báo "Còn N buổi chưa đồng bộ" —
  /// khi đó không đăng xuất, không xóa gì. [confirmDiscard] nhận N.
  Future<bool> logout({
    required Future<bool> Function(int pending) confirmDiscard,
  }) async {
    final pending = await _pendingCount();
    if (pending > 0 && !await confirmDiscard(pending)) return false;
    await _logout();
    await _wipe();
    return true;
  }

  /// Phiên hết hạn (refresh hỏng): không còn token để đồng bộ và không hỏi
  /// được người dùng, nên chỉ xóa khi outbox trống; còn dữ liệu thì giữ để
  /// đồng bộ sau lần đăng nhập kế tiếp.
  Future<bool> onSessionExpired() async {
    if (await _pendingCount() > 0) return false;
    await _wipe();
    return true;
  }
}
