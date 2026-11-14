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
  /// **'Tasco Shell'**
  String get appName;

  /// No description provided for @login.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get logout;

  /// No description provided for @username.
  ///
  /// In vi, this message translates to:
  /// **'Tên đăng nhập'**
  String get username;

  /// No description provided for @password.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu'**
  String get password;

  /// No description provided for @home.
  ///
  /// In vi, this message translates to:
  /// **'Trang chủ'**
  String get home;

  /// No description provided for @loading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In vi, this message translates to:
  /// **'Đã có lỗi xảy ra'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In vi, this message translates to:
  /// **'Xóa'**
  String get delete;

  /// No description provided for @search.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm'**
  String get search;

  /// No description provided for @noData.
  ///
  /// In vi, this message translates to:
  /// **'Không có dữ liệu'**
  String get noData;

  /// No description provided for @tabHome.
  ///
  /// In vi, this message translates to:
  /// **'Trang chủ'**
  String get tabHome;

  /// No description provided for @tabExplore.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá'**
  String get tabExplore;

  /// No description provided for @tabNotification.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get tabNotification;

  /// No description provided for @tabProfile.
  ///
  /// In vi, this message translates to:
  /// **'Cá nhân'**
  String get tabProfile;

  /// No description provided for @greetingMorning.
  ///
  /// In vi, this message translates to:
  /// **'Chào buổi sáng 👋'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In vi, this message translates to:
  /// **'Chào buổi chiều 👋'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In vi, this message translates to:
  /// **'Chào buổi tối 👋'**
  String get greetingEvening;

  /// No description provided for @homeQuickAccess.
  ///
  /// In vi, this message translates to:
  /// **'Truy cập nhanh'**
  String get homeQuickAccess;

  /// No description provided for @homeOverview.
  ///
  /// In vi, this message translates to:
  /// **'Tổng quan'**
  String get homeOverview;

  /// No description provided for @homeMenuHrProfile.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ\nnhân sự'**
  String get homeMenuHrProfile;

  /// No description provided for @homeMenuTraining.
  ///
  /// In vi, this message translates to:
  /// **'Đào tạo\nphát triển'**
  String get homeMenuTraining;

  /// No description provided for @homeMenuEvaluation.
  ///
  /// In vi, this message translates to:
  /// **'Đánh giá\nnhân sự'**
  String get homeMenuEvaluation;

  /// No description provided for @homeMenuCareerPath.
  ///
  /// In vi, this message translates to:
  /// **'Lộ trình\nphát triển'**
  String get homeMenuCareerPath;

  /// No description provided for @homeMenuCrossSale.
  ///
  /// In vi, this message translates to:
  /// **'Bán chéo\nhệ sinh thái'**
  String get homeMenuCrossSale;

  /// No description provided for @homeMenuSuggestions.
  ///
  /// In vi, this message translates to:
  /// **'Đề xuất\ncải tiến'**
  String get homeMenuSuggestions;

  /// No description provided for @homeMenuFavorites.
  ///
  /// In vi, this message translates to:
  /// **'Yêu\nthích'**
  String get homeMenuFavorites;

  /// No description provided for @homeMenuViewMore.
  ///
  /// In vi, this message translates to:
  /// **'Xem\nthêm'**
  String get homeMenuViewMore;

  /// No description provided for @homeStatInsuranceOrders.
  ///
  /// In vi, this message translates to:
  /// **'Đơn bảo hiểm'**
  String get homeStatInsuranceOrders;

  /// No description provided for @homeStatPending.
  ///
  /// In vi, this message translates to:
  /// **'Chờ xử lý'**
  String get homeStatPending;

  /// No description provided for @homeStatTodayTasks.
  ///
  /// In vi, this message translates to:
  /// **'Công việc hôm nay'**
  String get homeStatTodayTasks;

  /// No description provided for @homeStatNewNotifications.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo mới'**
  String get homeStatNewNotifications;

  /// No description provided for @underConstructionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tính năng đang phát triển'**
  String get underConstructionTitle;

  /// No description provided for @underConstructionMessage.
  ///
  /// In vi, this message translates to:
  /// **'Chức năng này đang được xây dựng và sẽ sớm ra mắt trong phiên bản tiếp theo.'**
  String get underConstructionMessage;

  /// No description provided for @understood.
  ///
  /// In vi, this message translates to:
  /// **'Đã hiểu'**
  String get understood;

  /// No description provided for @demoModuleTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mini App VueJS'**
  String get demoModuleTitle;

  /// No description provided for @demoModuleSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Demo web bundle mount qua ModuleSlot'**
  String get demoModuleSubtitle;

  /// No description provided for @notificationTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get notificationTitle;

  /// No description provided for @notificationMarkAllAsRead.
  ///
  /// In vi, this message translates to:
  /// **'Đã đọc tất cả'**
  String get notificationMarkAllAsRead;

  /// No description provided for @notificationFilterAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get notificationFilterAll;

  /// No description provided for @notificationFilterSystem.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống'**
  String get notificationFilterSystem;

  /// No description provided for @notificationFilterTransaction.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch'**
  String get notificationFilterTransaction;

  /// No description provided for @notificationFilterMiniApps.
  ///
  /// In vi, this message translates to:
  /// **'Mini Apps'**
  String get notificationFilterMiniApps;

  /// No description provided for @notificationEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không có thông báo'**
  String get notificationEmptyTitle;

  /// No description provided for @notificationEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa có thông báo nào trong mục này.'**
  String get notificationEmptyMessage;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In vi, this message translates to:
  /// **'{minutes} phút trước'**
  String timeMinutesAgo(int minutes);

  /// No description provided for @timeHoursAgo.
  ///
  /// In vi, this message translates to:
  /// **'{hours} giờ trước'**
  String timeHoursAgo(int hours);

  /// No description provided for @timeDaysAgo.
  ///
  /// In vi, this message translates to:
  /// **'{days} ngày trước'**
  String timeDaysAgo(int days);

  /// No description provided for @profileStandardUser.
  ///
  /// In vi, this message translates to:
  /// **'Người dùng tiêu chuẩn'**
  String get profileStandardUser;

  /// No description provided for @profilePermissionsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quyền hạn truy cập'**
  String get profilePermissionsTitle;

  /// No description provided for @profileStandardUserPermissions.
  ///
  /// In vi, this message translates to:
  /// **'QUYỀN NGƯỜI DÙNG TIÊU CHUẨN'**
  String get profileStandardUserPermissions;

  /// No description provided for @profileRole.
  ///
  /// In vi, this message translates to:
  /// **'Vai trò: {role}'**
  String profileRole(String role);

  /// No description provided for @profilePermissionsCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} quyền'**
  String profilePermissionsCount(int count);

  /// No description provided for @profileShowMore.
  ///
  /// In vi, this message translates to:
  /// **'Xem thêm ({count} quyền) ▼'**
  String profileShowMore(int count);

  /// No description provided for @profileShowLess.
  ///
  /// In vi, this message translates to:
  /// **'Thu gọn ▲'**
  String get profileShowLess;

  /// No description provided for @profileSettings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get profileSettings;

  /// No description provided for @profileNoPermissions.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có quyền hạn nào'**
  String get profileNoPermissions;

  /// No description provided for @loginWelcomeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chào mừng trở lại! 👋'**
  String get loginWelcomeTitle;

  /// No description provided for @loginWelcomeSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để tiếp tục trải nghiệm hệ sinh thái Tasco'**
  String get loginWelcomeSubtitle;

  /// No description provided for @loginSsoOr.
  ///
  /// In vi, this message translates to:
  /// **'HOẶC ĐĂNG NHẬP VỚI'**
  String get loginSsoOr;

  /// No description provided for @loginGoogle.
  ///
  /// In vi, this message translates to:
  /// **'Google'**
  String get loginGoogle;

  /// No description provided for @loginApple.
  ///
  /// In vi, this message translates to:
  /// **'Apple'**
  String get loginApple;

  /// No description provided for @loginCorporateSso.
  ///
  /// In vi, this message translates to:
  /// **'Corporate SSO'**
  String get loginCorporateSso;

  /// No description provided for @loginBiometric.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập sinh trắc học'**
  String get loginBiometric;

  /// No description provided for @loginUsernameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên đăng nhập'**
  String get loginUsernameRequired;

  /// No description provided for @loginPasswordRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mật khẩu'**
  String get loginPasswordRequired;

  /// No description provided for @loginFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin.'**
  String get loginFailed;

  /// No description provided for @loginNetworkError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể kết nối tới máy chủ. Vui lòng kiểm tra kết nối mạng và thử lại.'**
  String get loginNetworkError;

  /// No description provided for @settings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settings;

  /// No description provided for @settingsSecurity.
  ///
  /// In vi, this message translates to:
  /// **'Bảo mật & Xác thực'**
  String get settingsSecurity;

  /// No description provided for @settingsBiometricTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập bằng Sinh trắc học'**
  String get settingsBiometricTitle;

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

  /// No description provided for @settingsBiometricAuthReason.
  ///
  /// In vi, this message translates to:
  /// **'Xác minh danh tính để bật đăng nhập sinh trắc học'**
  String get settingsBiometricAuthReason;

  /// No description provided for @settingsBiometricEnabled.
  ///
  /// In vi, this message translates to:
  /// **'Đã bật đăng nhập sinh trắc học'**
  String get settingsBiometricEnabled;

  /// No description provided for @settingsBiometricDisabled.
  ///
  /// In vi, this message translates to:
  /// **'Đã tắt đăng nhập sinh trắc học'**
  String get settingsBiometricDisabled;

  /// No description provided for @settingsBiometricFailed.
  ///
  /// In vi, this message translates to:
  /// **'Xác minh sinh trắc học thất bại'**
  String get settingsBiometricFailed;

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

  /// No description provided for @settingsTheme.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In vi, this message translates to:
  /// **'Theo hệ thống'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In vi, this message translates to:
  /// **'Sáng'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In vi, this message translates to:
  /// **'Tối'**
  String get settingsThemeDark;

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

  /// No description provided for @settingsAboutVersion.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản'**
  String get settingsAboutVersion;

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

  /// No description provided for @splashTagline.
  ///
  /// In vi, this message translates to:
  /// **'Hệ sinh thái Tasco'**
  String get splashTagline;

  /// No description provided for @splashCopyright.
  ///
  /// In vi, this message translates to:
  /// **'© 2026 Tasco Joint Stock Company'**
  String get splashCopyright;
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
