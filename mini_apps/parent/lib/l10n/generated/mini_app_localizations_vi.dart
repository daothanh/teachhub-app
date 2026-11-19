// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'mini_app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class MiniAppLocalizationsVi extends MiniAppLocalizations {
  MiniAppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get spaceTitle => 'Phụ huynh';

  @override
  String get switchRole => 'Đổi vai trò';

  @override
  String get parentNoInviteTitle => 'Cần lời mời từ giáo viên';

  @override
  String get parentNoInviteBody =>
      'Giáo viên sẽ gửi link, mã hoặc mã QR để kết nối với lớp của con.';

  @override
  String get parentAddInvite => 'Thêm lời mời';

  @override
  String get parentLoadFailed =>
      'Không tải được thông tin của con. Vui lòng thử lại.';

  @override
  String get parentRetry => 'Thử lại';

  @override
  String get parentPickChild => 'Chọn con';

  @override
  String parentChildClasses(String classes) {
    return 'Lớp: $classes';
  }

  @override
  String get parentNoClasses => 'Con chưa ghi danh lớp nào.';

  @override
  String get attendanceWeekTitle => 'Chuyên cần tuần này';

  @override
  String attendanceWeekRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get attendancePresent => 'Có mặt';

  @override
  String get attendanceLate => 'Đi muộn';

  @override
  String get attendanceExcused => 'Vắng có phép';

  @override
  String get attendanceUnexcused => 'Vắng không phép';

  @override
  String get attendanceNotRecorded => 'Chưa điểm danh';

  @override
  String get attendanceUpcoming => 'Sắp học';

  @override
  String attendanceCount(String label, int count) {
    return '$label: $count';
  }

  @override
  String get attendanceNoSessions => 'Tuần này chưa có buổi học.';

  @override
  String get attendanceCancelled => 'Buổi đã hủy';

  @override
  String get attendanceMakeup => 'Buổi bù';

  @override
  String attendanceSessionLine(String className, String when) {
    return '$className, $when';
  }

  @override
  String get notificationBannerTitle => 'Bật thông báo';

  @override
  String get notificationBannerBody =>
      'Nhận tin điểm danh và thay đổi lịch của con ngay khi giáo viên cập nhật.';

  @override
  String get notificationBannerAction => 'Bật thông báo';
}
