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

  /// No description provided for @loginSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập bằng email, Google hoặc Apple. Không cần mật khẩu.'**
  String get loginSubtitle;

  /// No description provided for @loginEmail.
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get loginEmail;

  /// No description provided for @loginEmailHint.
  ///
  /// In vi, this message translates to:
  /// **'ban@example.com'**
  String get loginEmailHint;

  /// No description provided for @loginEmailInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Email chưa đúng định dạng.'**
  String get loginEmailInvalid;

  /// No description provided for @loginSendOtp.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã đăng nhập'**
  String get loginSendOtp;

  /// No description provided for @loginOr.
  ///
  /// In vi, this message translates to:
  /// **'hoặc'**
  String get loginOr;

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

  /// No description provided for @loginOtpSentTo.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã 6 số đã gửi tới {email}'**
  String loginOtpSentTo(String email);

  /// No description provided for @loginOtpCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã đăng nhập'**
  String get loginOtpCode;

  /// No description provided for @loginResend.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại mã'**
  String get loginResend;

  /// No description provided for @loginResendIn.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại mã sau {seconds} giây'**
  String loginResendIn(int seconds);

  /// No description provided for @loginChangeEmail.
  ///
  /// In vi, this message translates to:
  /// **'Đổi email'**
  String get loginChangeEmail;

  /// No description provided for @loginOtpInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Mã đăng nhập không đúng hoặc đã hết hạn.'**
  String get loginOtpInvalid;

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

  /// No description provided for @splashLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được vai trò của bạn.'**
  String get splashLoadFailed;

  /// No description provided for @roleTitle.
  ///
  /// In vi, this message translates to:
  /// **'Vai trò'**
  String get roleTitle;

  /// No description provided for @roleYours.
  ///
  /// In vi, this message translates to:
  /// **'Vai trò của bạn'**
  String get roleYours;

  /// No description provided for @roleWhoAreYou.
  ///
  /// In vi, this message translates to:
  /// **'Bạn là…?'**
  String get roleWhoAreYou;

  /// No description provided for @roleAdd.
  ///
  /// In vi, this message translates to:
  /// **'Thêm vai trò'**
  String get roleAdd;

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

  /// No description provided for @loading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải...'**
  String get loading;

  /// No description provided for @login.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get login;
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
