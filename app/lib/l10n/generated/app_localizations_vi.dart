// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'Tasco Shell';

  @override
  String get login => 'Đăng nhập';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get username => 'Tên đăng nhập';

  @override
  String get password => 'Mật khẩu';

  @override
  String get home => 'Trang chủ';

  @override
  String get loading => 'Đang tải...';

  @override
  String get error => 'Đã có lỗi xảy ra';

  @override
  String get retry => 'Thử lại';

  @override
  String get cancel => 'Hủy';

  @override
  String get confirm => 'Xác nhận';

  @override
  String get save => 'Lưu';

  @override
  String get delete => 'Xóa';

  @override
  String get search => 'Tìm kiếm';

  @override
  String get noData => 'Không có dữ liệu';

  @override
  String get tabHome => 'Trang chủ';

  @override
  String get tabExplore => 'Khám phá';

  @override
  String get tabNotification => 'Thông báo';

  @override
  String get tabProfile => 'Cá nhân';

  @override
  String get greetingMorning => 'Chào buổi sáng 👋';

  @override
  String get greetingAfternoon => 'Chào buổi chiều 👋';

  @override
  String get greetingEvening => 'Chào buổi tối 👋';

  @override
  String get homeQuickAccess => 'Truy cập nhanh';

  @override
  String get homeOverview => 'Tổng quan';

  @override
  String get homeMenuHrProfile => 'Hồ sơ\nnhân sự';

  @override
  String get homeMenuTraining => 'Đào tạo\nphát triển';

  @override
  String get homeMenuEvaluation => 'Đánh giá\nnhân sự';

  @override
  String get homeMenuCareerPath => 'Lộ trình\nphát triển';

  @override
  String get homeMenuCrossSale => 'Bán chéo\nhệ sinh thái';

  @override
  String get homeMenuSuggestions => 'Đề xuất\ncải tiến';

  @override
  String get homeMenuFavorites => 'Yêu\nthích';

  @override
  String get homeMenuViewMore => 'Xem\nthêm';

  @override
  String get homeStatInsuranceOrders => 'Đơn bảo hiểm';

  @override
  String get homeStatPending => 'Chờ xử lý';

  @override
  String get homeStatTodayTasks => 'Công việc hôm nay';

  @override
  String get homeStatNewNotifications => 'Thông báo mới';

  @override
  String get underConstructionTitle => 'Tính năng đang phát triển';

  @override
  String get underConstructionMessage =>
      'Chức năng này đang được xây dựng và sẽ sớm ra mắt trong phiên bản tiếp theo.';

  @override
  String get understood => 'Đã hiểu';

  @override
  String get demoModuleTitle => 'Mini App VueJS';

  @override
  String get demoModuleSubtitle => 'Demo web bundle mount qua ModuleSlot';

  @override
  String get notificationTitle => 'Thông báo';

  @override
  String get notificationMarkAllAsRead => 'Đã đọc tất cả';

  @override
  String get notificationFilterAll => 'Tất cả';

  @override
  String get notificationFilterSystem => 'Hệ thống';

  @override
  String get notificationFilterTransaction => 'Giao dịch';

  @override
  String get notificationFilterMiniApps => 'Mini Apps';

  @override
  String get notificationEmptyTitle => 'Không có thông báo';

  @override
  String get notificationEmptyMessage =>
      'Bạn chưa có thông báo nào trong mục này.';

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes phút trước';
  }

  @override
  String timeHoursAgo(int hours) {
    return '$hours giờ trước';
  }

  @override
  String timeDaysAgo(int days) {
    return '$days ngày trước';
  }

  @override
  String get profileStandardUser => 'Người dùng tiêu chuẩn';

  @override
  String get profilePermissionsTitle => 'Quyền hạn truy cập';

  @override
  String get profileStandardUserPermissions => 'QUYỀN NGƯỜI DÙNG TIÊU CHUẨN';

  @override
  String profileRole(String role) {
    return 'Vai trò: $role';
  }

  @override
  String profilePermissionsCount(int count) {
    return '$count quyền';
  }

  @override
  String profileShowMore(int count) {
    return 'Xem thêm ($count quyền) ▼';
  }

  @override
  String get profileShowLess => 'Thu gọn ▲';

  @override
  String get profileSettings => 'Cài đặt';

  @override
  String get profileNoPermissions => 'Chưa có quyền hạn nào';

  @override
  String get loginWelcomeTitle => 'Chào mừng trở lại! 👋';

  @override
  String get loginWelcomeSubtitle =>
      'Đăng nhập để tiếp tục trải nghiệm hệ sinh thái Tasco';

  @override
  String get loginSsoOr => 'HOẶC ĐĂNG NHẬP VỚI';

  @override
  String get loginGoogle => 'Google';

  @override
  String get loginApple => 'Apple';

  @override
  String get loginCorporateSso => 'Corporate SSO';

  @override
  String get loginBiometric => 'Đăng nhập sinh trắc học';

  @override
  String get loginUsernameRequired => 'Vui lòng nhập tên đăng nhập';

  @override
  String get loginPasswordRequired => 'Vui lòng nhập mật khẩu';

  @override
  String get loginFailed =>
      'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin.';

  @override
  String get loginNetworkError =>
      'Không thể kết nối tới máy chủ. Vui lòng kiểm tra kết nối mạng và thử lại.';

  @override
  String get settings => 'Cài đặt';

  @override
  String get settingsSecurity => 'Bảo mật & Xác thực';

  @override
  String get settingsBiometricTitle => 'Đăng nhập bằng Sinh trắc học';

  @override
  String get settingsBiometricSubtitleAvailable =>
      'Face ID / Touch ID cho các lần mở app sau';

  @override
  String get settingsBiometricSubtitleNotEnrolled =>
      'Vào Cài đặt thiết bị để đăng ký Face ID / Touch ID';

  @override
  String get settingsBiometricSubtitleUnsupported =>
      'Thiết bị không hỗ trợ sinh trắc học';

  @override
  String get settingsBiometricAuthReason =>
      'Xác minh danh tính để bật đăng nhập sinh trắc học';

  @override
  String get settingsBiometricEnabled => 'Đã bật đăng nhập sinh trắc học';

  @override
  String get settingsBiometricDisabled => 'Đã tắt đăng nhập sinh trắc học';

  @override
  String get settingsBiometricFailed => 'Xác minh sinh trắc học thất bại';

  @override
  String get settingsLanguage => 'Ngôn ngữ';

  @override
  String get settingsLanguageSystem => 'Theo hệ thống';

  @override
  String get settingsTheme => 'Giao diện';

  @override
  String get settingsThemeSystem => 'Theo hệ thống';

  @override
  String get settingsThemeLight => 'Sáng';

  @override
  String get settingsThemeDark => 'Tối';

  @override
  String get settingsAbout => 'Về ứng dụng';

  @override
  String get settingsAboutApp => 'Ứng dụng';

  @override
  String get settingsAboutVersion => 'Phiên bản';

  @override
  String get settingsAboutEnv => 'Môi trường';

  @override
  String get settingsAboutTerms => 'Điều khoản sử dụng';

  @override
  String get splashTagline => 'Hệ sinh thái Tasco';

  @override
  String get splashCopyright => '© 2026 Tasco Joint Stock Company';
}
