import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appName.
  ///
  /// In vi, this message translates to:
  /// **'TeachHub'**
  String get appName;

  /// No description provided for @retry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get retry;

  /// No description provided for @loginEmail.
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get loginEmail;

  /// No description provided for @loginEmailHint.
  ///
  /// In vi, this message translates to:
  /// **'ten@email.com'**
  String get loginEmailHint;

  /// No description provided for @loginEmailInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Email chưa đúng định dạng, ví dụ: ten@gmail.com'**
  String get loginEmailInvalid;

  /// No description provided for @loginSendOtp.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã đăng nhập'**
  String get loginSendOtp;

  /// No description provided for @loginGoogle.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục với Google'**
  String get loginGoogle;

  /// No description provided for @loginApple.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục với Apple'**
  String get loginApple;

  /// No description provided for @loginResend.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại mã'**
  String get loginResend;

  /// No description provided for @loginChangeEmail.
  ///
  /// In vi, this message translates to:
  /// **'Đổi email'**
  String get loginChangeEmail;

  /// No description provided for @loginRateLimited.
  ///
  /// In vi, this message translates to:
  /// **'Bạn thao tác quá nhanh, vui lòng thử lại sau.'**
  String get loginRateLimited;

  /// No description provided for @loginFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập không thành công. Vui lòng thử lại.'**
  String get loginFailed;

  /// No description provided for @loginUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống đang bận, vui lòng thử lại sau ít phút.'**
  String get loginUnavailable;

  /// No description provided for @loginEmailRequiresOtp.
  ///
  /// In vi, this message translates to:
  /// **'Email này cần đăng nhập bằng mã OTP. Nhập email bên dưới để nhận mã.'**
  String get loginEmailRequiresOtp;

  /// No description provided for @splashLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được vai trò của bạn.'**
  String get splashLoadFailed;

  /// No description provided for @roleWhoAreYou.
  ///
  /// In vi, this message translates to:
  /// **'Bạn là…?'**
  String get roleWhoAreYou;

  /// No description provided for @roleTeacher.
  ///
  /// In vi, this message translates to:
  /// **'Giáo viên'**
  String get roleTeacher;

  /// No description provided for @roleParent.
  ///
  /// In vi, this message translates to:
  /// **'Phụ huynh'**
  String get roleParent;

  /// No description provided for @roleStudent.
  ///
  /// In vi, this message translates to:
  /// **'Học sinh'**
  String get roleStudent;

  /// No description provided for @roleAddFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thêm được vai trò. Vui lòng thử lại.'**
  String get roleAddFailed;

  /// No description provided for @inviteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời tham gia lớp'**
  String get inviteTitle;

  /// No description provided for @inviteBody.
  ///
  /// In vi, this message translates to:
  /// **'Giáo viên đã mời bạn kết nối với lớp học của con.'**
  String get inviteBody;

  /// No description provided for @inviteAccept.
  ///
  /// In vi, this message translates to:
  /// **'Nhận lời mời'**
  String get inviteAccept;

  /// No description provided for @inviteInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời không tồn tại hoặc đã hết hạn.'**
  String get inviteInvalid;

  /// No description provided for @inviteFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không nhận được lời mời. Vui lòng thử lại.'**
  String get inviteFailed;

  /// No description provided for @inviteConsentTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đồng ý xử lý dữ liệu'**
  String get inviteConsentTitle;

  /// No description provided for @inviteConsentBody.
  ///
  /// In vi, this message translates to:
  /// **'Để xem thông tin học tập của con, bạn cần đồng ý với điều khoản và chính sách xử lý dữ liệu cá nhân của TeachHub.'**
  String get inviteConsentBody;

  /// No description provided for @inviteConsentAccept.
  ///
  /// In vi, this message translates to:
  /// **'Đồng ý và nhận lời mời'**
  String get inviteConsentAccept;

  /// No description provided for @settings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settings;

  /// No description provided for @settingsAbout.
  ///
  /// In vi, this message translates to:
  /// **'Về ứng dụng'**
  String get settingsAbout;

  /// No description provided for @settingsAboutApp.
  ///
  /// In vi, this message translates to:
  /// **'Ứng dụng'**
  String get settingsAboutApp;

  /// No description provided for @settingsAboutEnv.
  ///
  /// In vi, this message translates to:
  /// **'Môi trường'**
  String get settingsAboutEnv;

  /// No description provided for @settingsAboutTerms.
  ///
  /// In vi, this message translates to:
  /// **'Điều khoản sử dụng'**
  String get settingsAboutTerms;

  /// No description provided for @settingsAboutVersion.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản'**
  String get settingsAboutVersion;

  /// No description provided for @settingsBiometricAuthReason.
  ///
  /// In vi, this message translates to:
  /// **'Xác minh danh tính để bật đăng nhập sinh trắc học'**
  String get settingsBiometricAuthReason;

  /// No description provided for @settingsBiometricDisabled.
  ///
  /// In vi, this message translates to:
  /// **'Đã tắt đăng nhập sinh trắc học'**
  String get settingsBiometricDisabled;

  /// No description provided for @settingsBiometricEnabled.
  ///
  /// In vi, this message translates to:
  /// **'Đã bật đăng nhập sinh trắc học'**
  String get settingsBiometricEnabled;

  /// No description provided for @settingsBiometricFailed.
  ///
  /// In vi, this message translates to:
  /// **'Xác minh sinh trắc học thất bại'**
  String get settingsBiometricFailed;

  /// No description provided for @settingsBiometricSubtitleAvailable.
  ///
  /// In vi, this message translates to:
  /// **'Face ID / Touch ID cho các lần mở app sau'**
  String get settingsBiometricSubtitleAvailable;

  /// No description provided for @settingsBiometricSubtitleNotEnrolled.
  ///
  /// In vi, this message translates to:
  /// **'Vào Cài đặt thiết bị để đăng ký Face ID / Touch ID'**
  String get settingsBiometricSubtitleNotEnrolled;

  /// No description provided for @settingsBiometricSubtitleUnsupported.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị không hỗ trợ sinh trắc học'**
  String get settingsBiometricSubtitleUnsupported;

  /// No description provided for @settingsBiometricTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập bằng Sinh trắc học'**
  String get settingsBiometricTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In vi, this message translates to:
  /// **'Theo hệ thống'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsSecurity.
  ///
  /// In vi, this message translates to:
  /// **'Bảo mật & Xác thực'**
  String get settingsSecurity;

  /// No description provided for @settingsTheme.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện'**
  String get settingsTheme;

  /// No description provided for @settingsThemeDark.
  ///
  /// In vi, this message translates to:
  /// **'Tối'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeLight.
  ///
  /// In vi, this message translates to:
  /// **'Sáng'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In vi, this message translates to:
  /// **'Theo hệ thống'**
  String get settingsThemeSystem;

  /// No description provided for @logout.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get logout;

  /// No description provided for @logoutPendingTitle.
  ///
  /// In vi, this message translates to:
  /// **'Còn {count} buổi chưa đồng bộ'**
  String logoutPendingTitle(int count);

  /// No description provided for @logoutUnreadableTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không đọc được dữ liệu chưa đồng bộ'**
  String get logoutUnreadableTitle;

  /// No description provided for @logoutUnreadableBody.
  ///
  /// In vi, this message translates to:
  /// **'Nếu đăng xuất, dữ liệu trên máy sẽ bị xóa và có thể mất các buổi chưa đồng bộ.'**
  String get logoutUnreadableBody;

  /// No description provided for @logoutWipeFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đã đăng xuất, nhưng chưa xóa hết dữ liệu trên máy. Ứng dụng sẽ thử lại lần mở sau.'**
  String get logoutWipeFailed;

  /// No description provided for @logoutPendingBody.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất bây giờ sẽ xóa các buổi này khỏi máy. Hãy kết nối mạng để đồng bộ trước.'**
  String get logoutPendingBody;

  /// No description provided for @logoutPendingConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Vẫn đăng xuất'**
  String get logoutPendingConfirm;

  /// No description provided for @logoutPendingCancel.
  ///
  /// In vi, this message translates to:
  /// **'Ở lại'**
  String get logoutPendingCancel;

  /// No description provided for @loading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải...'**
  String get loading;

  /// No description provided for @loginSlogan.
  ///
  /// In vi, this message translates to:
  /// **'Kết nối thầy, trò và gia đình.'**
  String get loginSlogan;

  /// No description provided for @loginTagline.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý lớp dạy thêm thật đơn giản.'**
  String get loginTagline;

  /// No description provided for @loginOrEmail.
  ///
  /// In vi, this message translates to:
  /// **'hoặc dùng email'**
  String get loginOrEmail;

  /// No description provided for @loginEmailHelper.
  ///
  /// In vi, this message translates to:
  /// **'Chúng tôi gửi mã 6 số, không cần mật khẩu.'**
  String get loginEmailHelper;

  /// No description provided for @loginSending.
  ///
  /// In vi, this message translates to:
  /// **'Đang gửi mã…'**
  String get loginSending;

  /// No description provided for @loginTermsPrefix.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục nghĩa là bạn đồng ý với '**
  String get loginTermsPrefix;

  /// No description provided for @loginTerms.
  ///
  /// In vi, this message translates to:
  /// **'Điều khoản sử dụng'**
  String get loginTerms;

  /// No description provided for @loginTermsAnd.
  ///
  /// In vi, this message translates to:
  /// **' và '**
  String get loginTermsAnd;

  /// No description provided for @loginPrivacy.
  ///
  /// In vi, this message translates to:
  /// **'Chính sách dữ liệu'**
  String get loginPrivacy;

  /// No description provided for @loginTermsSuffix.
  ///
  /// In vi, this message translates to:
  /// **' của TeachHub.'**
  String get loginTermsSuffix;

  /// No description provided for @heroTeacher.
  ///
  /// In vi, this message translates to:
  /// **'Thầy cô'**
  String get heroTeacher;

  /// No description provided for @heroStudent.
  ///
  /// In vi, this message translates to:
  /// **'Học trò'**
  String get heroStudent;

  /// No description provided for @heroFamily.
  ///
  /// In vi, this message translates to:
  /// **'Gia đình'**
  String get heroFamily;

  /// No description provided for @heroAttended.
  ///
  /// In vi, this message translates to:
  /// **'Đã điểm danh'**
  String get heroAttended;

  /// No description provided for @heroInvoiceSent.
  ///
  /// In vi, this message translates to:
  /// **'Hóa đơn đã gửi'**
  String get heroInvoiceSent;

  /// No description provided for @heroAbsenceReported.
  ///
  /// In vi, this message translates to:
  /// **'Đã báo vắng'**
  String get heroAbsenceReported;

  /// No description provided for @otpTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xác thực email'**
  String get otpTitle;

  /// No description provided for @otpHeading.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã xác thực'**
  String get otpHeading;

  /// No description provided for @otpSentTo.
  ///
  /// In vi, this message translates to:
  /// **'Mã 6 số đã gửi tới {email}'**
  String otpSentTo(String email);

  /// No description provided for @otpCodeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mã xác thực 6 số'**
  String get otpCodeLabel;

  /// No description provided for @otpConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get otpConfirm;

  /// No description provided for @otpVerifying.
  ///
  /// In vi, this message translates to:
  /// **'Đang xác thực…'**
  String get otpVerifying;

  /// No description provided for @otpResendIn.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại mã sau {time}'**
  String otpResendIn(String time);

  /// No description provided for @otpInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Mã chưa đúng.'**
  String get otpInvalid;

  /// No description provided for @otpInvalidAttempts.
  ///
  /// In vi, this message translates to:
  /// **'Mã chưa đúng. Còn {count} lần thử.'**
  String otpInvalidAttempts(int count);

  /// No description provided for @otpLockedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhập sai 5 lần'**
  String get otpLockedTitle;

  /// No description provided for @otpLockedBody.
  ///
  /// In vi, this message translates to:
  /// **'Xác thực tạm khóa 15 phút để bảo vệ tài khoản.'**
  String get otpLockedBody;

  /// No description provided for @otpRetryIn.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại sau {time}'**
  String otpRetryIn(String time);

  /// No description provided for @otpLocked.
  ///
  /// In vi, this message translates to:
  /// **'Tạm khóa'**
  String get otpLocked;

  /// No description provided for @roleIntro.
  ///
  /// In vi, this message translates to:
  /// **'Chọn để TeachHub hiện đúng những gì bạn cần. Bạn có thể thêm vai trò khác sau.'**
  String get roleIntro;

  /// No description provided for @roleTeacherDesc.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý lớp, điểm danh, thu học phí'**
  String get roleTeacherDesc;

  /// No description provided for @roleParentDesc.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi việc học của con, đóng học phí'**
  String get roleParentDesc;

  /// No description provided for @roleStudentDesc.
  ///
  /// In vi, this message translates to:
  /// **'Xem lịch, nộp bài, xem điểm'**
  String get roleStudentDesc;

  /// No description provided for @roleCenterOwner.
  ///
  /// In vi, this message translates to:
  /// **'Chủ trung tâm'**
  String get roleCenterOwner;

  /// No description provided for @roleCenterOwnerDesc.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý nhiều giáo viên, nhiều lớp'**
  String get roleCenterOwnerDesc;

  /// No description provided for @roleComingSoon.
  ///
  /// In vi, this message translates to:
  /// **'Sắp ra mắt'**
  String get roleComingSoon;

  /// No description provided for @roleSelected.
  ///
  /// In vi, this message translates to:
  /// **'Đã chọn'**
  String get roleSelected;

  /// No description provided for @roleOwned.
  ///
  /// In vi, this message translates to:
  /// **'Đang có'**
  String get roleOwned;

  /// No description provided for @roleContinue.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get roleContinue;

  /// No description provided for @updateTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cần cập nhật TeachHub'**
  String get updateTitle;

  /// No description provided for @updateBody.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản bạn đang dùng không còn được hỗ trợ. Vui lòng cập nhật để tiếp tục.'**
  String get updateBody;

  /// No description provided for @updateAction.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật'**
  String get updateAction;

  /// No description provided for @roleSwitchTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển vai trò'**
  String get roleSwitchTitle;

  /// No description provided for @roleAdd.
  ///
  /// In vi, this message translates to:
  /// **'Thêm vai trò'**
  String get roleAdd;

  /// No description provided for @roleSwitchedTo.
  ///
  /// In vi, this message translates to:
  /// **'Đang ở vai trò {role}'**
  String roleSwitchedTo(String role);

  /// No description provided for @waitlistTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký sớm cho Chủ trung tâm'**
  String get waitlistTitle;

  /// No description provided for @waitlistIntro.
  ///
  /// In vi, this message translates to:
  /// **'Tính năng cho trung tâm sắp ra mắt. Để lại thông tin, chúng tôi sẽ liên hệ khi sẵn sàng.'**
  String get waitlistIntro;

  /// No description provided for @waitlistCenterName.
  ///
  /// In vi, this message translates to:
  /// **'Tên trung tâm'**
  String get waitlistCenterName;

  /// No description provided for @waitlistCenterNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tên trung tâm.'**
  String get waitlistCenterNameRequired;

  /// No description provided for @waitlistTeacherCount.
  ///
  /// In vi, this message translates to:
  /// **'Số giáo viên'**
  String get waitlistTeacherCount;

  /// No description provided for @waitlistTeacherCountInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Nhập số từ 1 đến 1000.'**
  String get waitlistTeacherCountInvalid;

  /// No description provided for @waitlistSubmit.
  ///
  /// In vi, this message translates to:
  /// **'Gửi đăng ký'**
  String get waitlistSubmit;

  /// No description provided for @waitlistTrialHint.
  ///
  /// In vi, this message translates to:
  /// **'Trong lúc chờ, bạn có thể dùng thử với vai trò Giáo viên.'**
  String get waitlistTrialHint;

  /// No description provided for @waitlistTrialAction.
  ///
  /// In vi, this message translates to:
  /// **'Dùng thử vai trò Giáo viên'**
  String get waitlistTrialAction;

  /// No description provided for @waitlistSent.
  ///
  /// In vi, this message translates to:
  /// **'Đã nhận đăng ký'**
  String get waitlistSent;

  /// No description provided for @waitlistSentBody.
  ///
  /// In vi, this message translates to:
  /// **'Cảm ơn bạn. Chúng tôi sẽ liên hệ sớm.'**
  String get waitlistSentBody;

  /// No description provided for @waitlistErrorBusy.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu đang xử lý. Thử lại sau giây lát.'**
  String get waitlistErrorBusy;

  /// No description provided for @waitlistErrorValidation.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin chưa hợp lệ. Kiểm tra lại các ô.'**
  String get waitlistErrorValidation;

  /// No description provided for @waitlistErrorNetwork.
  ///
  /// In vi, this message translates to:
  /// **'Không có mạng. Thử lại sau.'**
  String get waitlistErrorNetwork;

  /// No description provided for @waitlistErrorGeneric.
  ///
  /// In vi, this message translates to:
  /// **'Chưa gửi được đăng ký. Thử lại sau.'**
  String get waitlistErrorGeneric;

  /// No description provided for @settingsAccount.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản'**
  String get settingsAccount;

  /// No description provided for @deleteAccountEntry.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tài khoản'**
  String get deleteAccountEntry;

  /// No description provided for @deleteAccountEntrySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa vĩnh viễn tài khoản và dữ liệu cá nhân'**
  String get deleteAccountEntrySubtitle;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tài khoản'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountWarnHeading.
  ///
  /// In vi, this message translates to:
  /// **'Hành động này không thể hoàn tác'**
  String get deleteAccountWarnHeading;

  /// No description provided for @deleteAccountWarnBody.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản {email} và dữ liệu cá nhân sẽ bị xóa. Đăng nhập lại bằng email này sẽ tạo tài khoản mới và không thấy dữ liệu cũ. Chứng từ tài chính được giữ lại theo quy định.'**
  String deleteAccountWarnBody(String email);

  /// No description provided for @deleteAccountPendingWarn.
  ///
  /// In vi, this message translates to:
  /// **'Máy này còn {count} mục chưa đồng bộ (điểm danh, thay đổi). Xóa tài khoản sẽ làm mất các dữ liệu đó.'**
  String deleteAccountPendingWarn(int count);

  /// No description provided for @deleteAccountUnreadableWarn.
  ///
  /// In vi, this message translates to:
  /// **'Không kiểm tra được dữ liệu chưa đồng bộ trên máy này. Nếu có, dữ liệu đó sẽ mất.'**
  String get deleteAccountUnreadableWarn;

  /// No description provided for @deleteAccountSendCode.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã xác nhận'**
  String get deleteAccountSendCode;

  /// No description provided for @deleteAccountSending.
  ///
  /// In vi, this message translates to:
  /// **'Đang gửi mã…'**
  String get deleteAccountSending;

  /// No description provided for @deleteAccountCodeHeading.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã xác nhận'**
  String get deleteAccountCodeHeading;

  /// No description provided for @deleteAccountCodeSent.
  ///
  /// In vi, this message translates to:
  /// **'Mã 6 số đã gửi tới {email}. Mã dùng được trong 5 phút.'**
  String deleteAccountCodeSent(String email);

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tài khoản vĩnh viễn'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountDeleting.
  ///
  /// In vi, this message translates to:
  /// **'Đang xóa…'**
  String get deleteAccountDeleting;

  /// No description provided for @deleteAccountResend.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại mã'**
  String get deleteAccountResend;

  /// No description provided for @deleteAccountErrNetwork.
  ///
  /// In vi, this message translates to:
  /// **'Không có mạng. Thử lại sau.'**
  String get deleteAccountErrNetwork;

  /// No description provided for @deleteAccountErrRateLimited.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã quá nhiều lần. Thử lại sau {seconds} giây.'**
  String deleteAccountErrRateLimited(int seconds);

  /// No description provided for @deleteAccountErrRateLimitedNoTime.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã quá nhiều lần. Thử lại sau ít phút.'**
  String get deleteAccountErrRateLimitedNoTime;

  /// No description provided for @deleteAccountErrOwnerHasStaff.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang là chủ không gian còn giáo viên khác. Hãy chuyển quyền hoặc gỡ họ khỏi không gian trước khi xóa tài khoản.'**
  String get deleteAccountErrOwnerHasStaff;

  /// No description provided for @deleteAccountErrActiveClasses.
  ///
  /// In vi, this message translates to:
  /// **'Còn lớp đang hoạt động. Hãy lưu trữ hết các lớp trước khi xóa tài khoản.'**
  String get deleteAccountErrActiveClasses;

  /// No description provided for @deleteAccountErrStale.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu vừa thay đổi. Mở lại màn này rồi thử lại.'**
  String get deleteAccountErrStale;

  /// No description provided for @deleteAccountErrGeneric.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xóa được tài khoản. Thử lại sau.'**
  String get deleteAccountErrGeneric;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
