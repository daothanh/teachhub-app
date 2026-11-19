/// Route của shell mà mini-app được điều hướng tới (điều hướng chéo chỉ bằng
/// route, spec §3.7).
abstract final class TeachHubRoutes {
  static const rolePicker = '/role-picker';

  /// P05: phụ huynh chưa có lời mời nhập link, mã hoặc quét QR.
  static const inviteEntry = '/invite';
  static const teacher = '/t';
  static const parent = '/p';
  static const student = '/s';
}
