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

  @override
  String get invoiceTuitionTitle => 'Học phí';

  @override
  String invoiceTuitionUnpaid(int count, String total) {
    return '$count hóa đơn chưa đóng xong, tổng $total';
  }

  @override
  String invoiceTuitionUnpaidMore(int count) {
    return '$count+ hóa đơn chưa đóng xong';
  }

  @override
  String get invoiceTuitionNone => 'Không có hóa đơn nào cần đóng.';

  @override
  String get invoiceTuitionOpen => 'Xem hóa đơn';

  @override
  String get invoiceListTitle => 'Hóa đơn';

  @override
  String get invoiceFilterAll => 'Tất cả';

  @override
  String get invoiceStatusIssued => 'Chưa thanh toán';

  @override
  String get invoiceStatusPending => 'Chờ xác nhận';

  @override
  String get invoiceStatusPartial => 'Đã trả một phần';

  @override
  String get invoiceStatusPaid => 'Đã thanh toán';

  @override
  String get invoiceStatusVoid => 'Đã hủy';

  @override
  String get invoiceStatusUnknown => 'Khác';

  @override
  String get invoiceEmpty => 'Chưa có hóa đơn nào.';

  @override
  String get invoiceLoadMore => 'Xem thêm';

  @override
  String invoiceRowSubtitle(String student, String month) {
    return '$student, kỳ $month';
  }

  @override
  String invoiceDue(String date) {
    return 'Hạn $date';
  }

  @override
  String invoiceCodeLabel(String code) {
    return 'Mã $code';
  }

  @override
  String get invoiceLinesTitle => 'Các khoản';

  @override
  String get invoiceTotal => 'Tổng cộng';

  @override
  String get invoiceVoidNotice => 'Hóa đơn đã hủy, bạn không cần chuyển khoản.';

  @override
  String get invoicePayTitle => 'Chuyển khoản';

  @override
  String get invoiceQrHint => 'Quét mã bằng app ngân hàng.';

  @override
  String get invoiceSaveQr => 'Lưu ảnh QR';

  @override
  String get invoiceQrSaved => 'Đã lưu ảnh QR.';

  @override
  String get invoiceQrDenied =>
      'Chưa có quyền lưu ảnh. Mở Cài đặt để cho phép.';

  @override
  String get invoiceQrFailed => 'Không lưu được ảnh QR. Hãy thử lại.';

  @override
  String get invoiceCopyNote => 'Sao chép nội dung chuyển khoản';

  @override
  String get invoiceCopyAccount => 'Sao chép số tài khoản';

  @override
  String get invoiceCopied => 'Đã sao chép.';

  @override
  String get invoiceBank => 'Ngân hàng';

  @override
  String get invoiceAccountNo => 'Số tài khoản';

  @override
  String get invoiceAccountName => 'Chủ tài khoản';

  @override
  String get invoiceTransferNote => 'Nội dung chuyển khoản';

  @override
  String get invoiceNotFound => 'Không tìm thấy hóa đơn';

  @override
  String get invoiceNotFoundBody =>
      'Hóa đơn không tồn tại hoặc bạn không xem được.';

  @override
  String get invoiceLoadFailed => 'Không tải được hóa đơn. Hãy thử lại.';
}
