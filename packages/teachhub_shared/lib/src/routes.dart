/// Route của shell mà mini-app được điều hướng tới (điều hướng chéo chỉ bằng
/// route, spec §3.7).
abstract final class TeachHubRoutes {
  static const rolePicker = '/role-picker';

  /// Cài đặt của shell, gồm "Xóa tài khoản" (US-0.x, S4-FL-04).
  static const settings = '/settings';

  /// P05: phụ huynh chưa có lời mời nhập link, mã hoặc quét QR.
  static const inviteEntry = '/invite';
  static const teacher = '/t';
  static const parent = '/p';
  static const student = '/s';
}
