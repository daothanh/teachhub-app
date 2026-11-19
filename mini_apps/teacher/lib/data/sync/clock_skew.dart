/// Lệch giữa đồng hồ máy và đồng hồ server, đo từ `serverTime` của API
/// (`POST /attendance/sync`, `GET /sessions/{id}/attendance`).
///
/// Dùng [now] khi gắn `clientUpdatedAt` cho thay đổi mới, để LWW của server so
/// sánh trên cùng một đồng hồ dù máy chỉnh sai giờ. Chỉ giữ trong bộ nhớ:
/// lần gọi API đầu tiên của phiên sẽ đo lại.
class ClockSkew {
  ClockSkew({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  /// `serverTime - giờ máy`; 0 khi chưa đo.
  Duration offset = Duration.zero;

  /// Giờ server ước lượng, theo đồng hồ máy cộng [offset].
  DateTime now() => _now().add(offset);

  /// [sentAt]/[receivedAt]: giờ máy lúc gửi và lúc nhận; server đóng dấu
  /// `serverTime` ở giữa chuyến đi nên so với điểm giữa.
  void observe(
    DateTime serverTime, {
    required DateTime sentAt,
    required DateTime receivedAt,
  }) {
    final midpoint = sentAt.add(receivedAt.difference(sentAt) ~/ 2);
    offset = serverTime.difference(midpoint);
  }
}
