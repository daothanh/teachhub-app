/// Giờ tường `HH:mm` của buổi học, một chỗ dùng chung cho cache, điểm danh và
/// lịch. Không đổi sang múi giờ máy để ngày và giờ luôn khớp với tenant.
String _two(int n) => n.toString().padLeft(2, '0');

/// Từ thời điểm lưu trong cache và offset của tenant (phút); dòng cũ chưa có
/// offset ([tzOffsetMinutes] null) thì dùng giờ máy.
String wallTime(DateTime startsAt, int? tzOffsetMinutes) {
  final t = tzOffsetMinutes == null
      ? startsAt.toLocal()
      : startsAt.toUtc().add(Duration(minutes: tzOffsetMinutes));
  return '${_two(t.hour)}:${_two(t.minute)}';
}

/// Từ chuỗi ISO 8601 kèm offset của server: lấy nguyên `HH:mm` trong chuỗi.
String wallTimeFromIso(String iso) {
  final t = iso.indexOf('T');
  return t < 0 || iso.length < t + 6 ? iso : iso.substring(t + 1, t + 6);
}
