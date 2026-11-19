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
  String get loginEmail => 'Email';

  @override
  String get loginEmailHint => 'ten@email.com';

  @override
  String get loginEmailInvalid =>
      'Email chưa đúng định dạng, ví dụ: ten@gmail.com';

  @override
  String get loginSendOtp => 'Gửi mã đăng nhập';

  @override
  String get loginGoogle => 'Tiếp tục với Google';

  @override
  String get loginApple => 'Tiếp tục với Apple';

  @override
  String get loginResend => 'Gửi lại mã';

  @override
  String get loginChangeEmail => 'Đổi email';

  @override
  String get loginRateLimited =>
      'Bạn thao tác quá nhanh, vui lòng thử lại sau.';

  @override
  String get loginFailed => 'Đăng nhập không thành công. Vui lòng thử lại.';

  @override
  String get splashLoadFailed => 'Không tải được vai trò của bạn.';

  @override
  String get roleWhoAreYou => 'Bạn là…?';

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
  String logoutPendingTitle(int count) {
    return 'Còn $count buổi chưa đồng bộ';
  }

  @override
  String get logoutUnreadableTitle => 'Không đọc được dữ liệu chưa đồng bộ';

  @override
  String get logoutUnreadableBody =>
      'Nếu đăng xuất, dữ liệu trên máy sẽ bị xóa và có thể mất các buổi chưa đồng bộ.';

  @override
  String get logoutWipeFailed =>
      'Đã đăng xuất, nhưng chưa xóa hết dữ liệu trên máy. Ứng dụng sẽ thử lại lần mở sau.';

  @override
  String get logoutPendingBody =>
      'Đăng xuất bây giờ sẽ xóa các buổi này khỏi máy. Hãy kết nối mạng để đồng bộ trước.';

  @override
  String get logoutPendingConfirm => 'Vẫn đăng xuất';

  @override
  String get logoutPendingCancel => 'Ở lại';

  @override
  String get loading => 'Đang tải...';

  @override
  String get loginSlogan => 'Kết nối thầy, trò và gia đình.';

  @override
  String get loginTagline => 'Quản lý lớp dạy thêm thật đơn giản.';

  @override
  String get loginOrEmail => 'hoặc dùng email';

  @override
  String get loginEmailHelper => 'Chúng tôi gửi mã 6 số, không cần mật khẩu.';

  @override
  String get loginSending => 'Đang gửi mã…';

  @override
  String get loginTermsPrefix => 'Tiếp tục nghĩa là bạn đồng ý với ';

  @override
  String get loginTerms => 'Điều khoản sử dụng';

  @override
  String get loginTermsAnd => ' và ';

  @override
  String get loginPrivacy => 'Chính sách dữ liệu';

  @override
  String get loginTermsSuffix => ' của TeachHub.';

  @override
  String get heroTeacher => 'Thầy cô';

  @override
  String get heroStudent => 'Học trò';

  @override
  String get heroFamily => 'Gia đình';

  @override
  String get heroAttended => 'Đã điểm danh';

  @override
  String get heroInvoiceSent => 'Hóa đơn đã gửi';

  @override
  String get heroAbsenceReported => 'Đã báo vắng';

  @override
  String get otpTitle => 'Xác thực email';

  @override
  String get otpHeading => 'Nhập mã xác thực';

  @override
  String otpSentTo(String email) {
    return 'Mã 6 số đã gửi tới $email';
  }

  @override
  String get otpCodeLabel => 'Mã xác thực 6 số';

  @override
  String get otpConfirm => 'Xác nhận';

  @override
  String get otpVerifying => 'Đang xác thực…';

  @override
  String otpResendIn(String time) {
    return 'Gửi lại mã sau $time';
  }

  @override
  String get otpInvalid => 'Mã chưa đúng.';

  @override
  String otpInvalidAttempts(int count) {
    return 'Mã chưa đúng. Còn $count lần thử.';
  }

  @override
  String get otpLockedTitle => 'Nhập sai 5 lần';

  @override
  String get otpLockedBody => 'Xác thực tạm khóa 15 phút để bảo vệ tài khoản.';

  @override
  String otpRetryIn(String time) {
    return 'Thử lại sau $time';
  }

  @override
  String get otpLocked => 'Tạm khóa';

  @override
  String get roleIntro =>
      'Chọn để TeachHub hiện đúng những gì bạn cần. Bạn có thể thêm vai trò khác sau.';

  @override
  String get roleTeacherDesc => 'Quản lý lớp, điểm danh, thu học phí';

  @override
  String get roleParentDesc => 'Theo dõi việc học của con, đóng học phí';

  @override
  String get roleStudentDesc => 'Xem lịch, nộp bài, xem điểm';

  @override
  String get roleCenterOwner => 'Chủ trung tâm';

  @override
  String get roleCenterOwnerDesc => 'Quản lý nhiều giáo viên, nhiều lớp';

  @override
  String get roleComingSoon => 'Sắp ra mắt';

  @override
  String get roleSelected => 'Đã chọn';

  @override
  String get roleOwned => 'Đang có';

  @override
  String get roleContinue => 'Tiếp tục';

  @override
  String get updateTitle => 'Cần cập nhật TeachHub';

  @override
  String get updateBody =>
      'Phiên bản bạn đang dùng không còn được hỗ trợ. Vui lòng cập nhật để tiếp tục.';

  @override
  String get updateAction => 'Cập nhật';

  @override
  String get roleSwitchTitle => 'Chuyển vai trò';

  @override
  String get roleAdd => 'Thêm vai trò';

  @override
  String roleSwitchedTo(String role) {
    return 'Đang ở vai trò $role';
  }
}
