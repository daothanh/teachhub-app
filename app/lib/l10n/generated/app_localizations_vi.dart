// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'TeachHub';

  @override
  String get retry => 'Thử lại';

  @override
  String get loginSubtitle =>
      'Đăng nhập bằng email, Google hoặc Apple. Không cần mật khẩu.';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginEmailHint => 'ban@example.com';

  @override
  String get loginEmailInvalid => 'Email chưa đúng định dạng.';

  @override
  String get loginSendOtp => 'Gửi mã đăng nhập';

  @override
  String get loginOr => 'hoặc';

  @override
  String get loginGoogle => 'Tiếp tục với Google';

  @override
  String get loginApple => 'Tiếp tục với Apple';

  @override
  String loginOtpSentTo(String email) {
    return 'Nhập mã 6 số đã gửi tới $email';
  }

  @override
  String get loginOtpCode => 'Mã đăng nhập';

  @override
  String get loginResend => 'Gửi lại mã';

  @override
  String loginResendIn(int seconds) {
    return 'Gửi lại mã sau $seconds giây';
  }

  @override
  String get loginChangeEmail => 'Đổi email';

  @override
  String get loginOtpInvalid => 'Mã đăng nhập không đúng hoặc đã hết hạn.';

  @override
  String get loginRateLimited =>
      'Bạn thao tác quá nhanh, vui lòng thử lại sau.';

  @override
  String get loginFailed => 'Đăng nhập không thành công. Vui lòng thử lại.';

  @override
  String get splashLoadFailed => 'Không tải được vai trò của bạn.';

  @override
  String get roleTitle => 'Vai trò';

  @override
  String get roleYours => 'Vai trò của bạn';

  @override
  String get roleWhoAreYou => 'Bạn là…?';

  @override
  String get roleAdd => 'Thêm vai trò';

  @override
  String get roleTeacher => 'Giáo viên';

  @override
  String get roleParent => 'Phụ huynh';

  @override
  String get roleStudent => 'Học sinh';

  @override
  String get roleAddFailed => 'Không thêm được vai trò. Vui lòng thử lại.';

  @override
  String get inviteTitle => 'Lời mời tham gia lớp';

  @override
  String get inviteBody => 'Giáo viên đã mời bạn kết nối với lớp học của con.';

  @override
  String get inviteAccept => 'Nhận lời mời';

  @override
  String get inviteInvalid => 'Lời mời không tồn tại hoặc đã hết hạn.';

  @override
  String get inviteFailed => 'Không nhận được lời mời. Vui lòng thử lại.';

  @override
  String get inviteConsentTitle => 'Đồng ý xử lý dữ liệu';

  @override
  String get inviteConsentBody =>
      'Để xem thông tin học tập của con, bạn cần đồng ý với điều khoản và chính sách xử lý dữ liệu cá nhân của TeachHub.';

  @override
  String get inviteConsentAccept => 'Đồng ý và nhận lời mời';

  @override
  String get settings => 'Cài đặt';

  @override
  String get settingsAbout => 'Về ứng dụng';

  @override
  String get settingsAboutApp => 'Ứng dụng';

  @override
  String get settingsAboutEnv => 'Môi trường';

  @override
  String get settingsAboutTerms => 'Điều khoản sử dụng';

  @override
  String get settingsAboutVersion => 'Phiên bản';

  @override
  String get settingsBiometricAuthReason =>
      'Xác minh danh tính để bật đăng nhập sinh trắc học';

  @override
  String get settingsBiometricDisabled => 'Đã tắt đăng nhập sinh trắc học';

  @override
  String get settingsBiometricEnabled => 'Đã bật đăng nhập sinh trắc học';

  @override
  String get settingsBiometricFailed => 'Xác minh sinh trắc học thất bại';

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
  String get settingsBiometricTitle => 'Đăng nhập bằng Sinh trắc học';

  @override
  String get settingsLanguage => 'Ngôn ngữ';

  @override
  String get settingsLanguageSystem => 'Theo hệ thống';

  @override
  String get settingsSecurity => 'Bảo mật & Xác thực';

  @override
  String get settingsTheme => 'Giao diện';

  @override
  String get settingsThemeDark => 'Tối';

  @override
  String get settingsThemeLight => 'Sáng';

  @override
  String get settingsThemeSystem => 'Theo hệ thống';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get loading => 'Đang tải...';

  @override
  String get login => 'Đăng nhập';
}
