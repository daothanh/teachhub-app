/// Quyền thông báo của hệ điều hành. Host gắn bản thật (FCM); mini-app không
/// phụ thuộc firebase. Không có bản gắn thì banner bật thông báo ẩn.
abstract interface class NotificationPermissionGate {
  Future<bool> isEnabled();

  /// Xin quyền; trả `true` khi đã được bật.
  Future<bool> request();
}
