import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'mini_app_localizations_en.dart';
import 'mini_app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of MiniAppLocalizations
/// returned by `MiniAppLocalizations.of(context)`.
///
/// Applications need to include `MiniAppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/mini_app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: MiniAppLocalizations.localizationsDelegates,
///   supportedLocales: MiniAppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the MiniAppLocalizations.supportedLocales
/// property.
abstract class MiniAppLocalizations {
  MiniAppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static MiniAppLocalizations of(BuildContext context) {
    return Localizations.of<MiniAppLocalizations>(
      context,
      MiniAppLocalizations,
    )!;
  }

  static const LocalizationsDelegate<MiniAppLocalizations> delegate =
      _MiniAppLocalizationsDelegate();

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

  /// No description provided for @spaceTitle.
  ///
  /// In vi, this message translates to:
  /// **'Giáo viên'**
  String get spaceTitle;

  /// No description provided for @spaceComingSoon.
  ///
  /// In vi, this message translates to:
  /// **'Không gian này đang được xây dựng.'**
  String get spaceComingSoon;

  /// No description provided for @switchRole.
  ///
  /// In vi, this message translates to:
  /// **'Đổi vai trò'**
  String get switchRole;

  /// No description provided for @offlineBanner.
  ///
  /// In vi, this message translates to:
  /// **'Ngoại tuyến — thay đổi được lưu trên máy và tự đồng bộ khi có mạng.'**
  String get offlineBanner;

  /// No description provided for @studentsFormTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thêm học viên'**
  String get studentsFormTitle;

  /// No description provided for @studentsFullName.
  ///
  /// In vi, this message translates to:
  /// **'Họ và tên'**
  String get studentsFullName;

  /// No description provided for @studentsFullNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Nhập họ tên học viên.'**
  String get studentsFullNameRequired;

  /// No description provided for @studentsDob.
  ///
  /// In vi, this message translates to:
  /// **'Ngày sinh (không bắt buộc)'**
  String get studentsDob;

  /// No description provided for @studentsSchool.
  ///
  /// In vi, this message translates to:
  /// **'Trường (không bắt buộc)'**
  String get studentsSchool;

  /// No description provided for @studentsNote.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú (không bắt buộc)'**
  String get studentsNote;

  /// No description provided for @studentsGuardianTitle.
  ///
  /// In vi, this message translates to:
  /// **'Phụ huynh {n}'**
  String studentsGuardianTitle(int n);

  /// No description provided for @studentsGuardianName.
  ///
  /// In vi, this message translates to:
  /// **'Họ tên phụ huynh'**
  String get studentsGuardianName;

  /// No description provided for @studentsGuardianNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Nhập họ tên phụ huynh.'**
  String get studentsGuardianNameRequired;

  /// No description provided for @studentsGuardianPhone.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại (không bắt buộc)'**
  String get studentsGuardianPhone;

  /// No description provided for @studentsGuardianPhoneInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại chưa đúng.'**
  String get studentsGuardianPhoneInvalid;

  /// No description provided for @studentsAddGuardian.
  ///
  /// In vi, this message translates to:
  /// **'Thêm phụ huynh'**
  String get studentsAddGuardian;

  /// No description provided for @studentsRemoveGuardian.
  ///
  /// In vi, this message translates to:
  /// **'Xóa phụ huynh {n}'**
  String studentsRemoveGuardian(int n);

  /// No description provided for @studentsSave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu học viên'**
  String get studentsSave;

  /// No description provided for @studentsSaving.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu…'**
  String get studentsSaving;

  /// No description provided for @studentsDuplicateTitle.
  ///
  /// In vi, this message translates to:
  /// **'Có phải cùng một em?'**
  String get studentsDuplicateTitle;

  /// No description provided for @studentsDuplicateBody.
  ///
  /// In vi, this message translates to:
  /// **'Đã có hồ sơ trùng họ tên và ngày sinh. Chọn đúng em, hoặc thêm em mới.'**
  String get studentsDuplicateBody;

  /// No description provided for @studentsDuplicateSame.
  ///
  /// In vi, this message translates to:
  /// **'Đúng, là em này'**
  String get studentsDuplicateSame;

  /// No description provided for @studentsDuplicateNew.
  ///
  /// In vi, this message translates to:
  /// **'Không, thêm em mới'**
  String get studentsDuplicateNew;

  /// No description provided for @studentsDuplicateCancel.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại sửa'**
  String get studentsDuplicateCancel;

  /// No description provided for @studentsErrorLimit.
  ///
  /// In vi, this message translates to:
  /// **'Gói hiện tại đã đủ số học viên. Nâng cấp để thêm.'**
  String get studentsErrorLimit;

  /// No description provided for @studentsErrorBusy.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu đang xử lý. Thử lại sau giây lát.'**
  String get studentsErrorBusy;

  /// No description provided for @studentsErrorValidation.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin chưa hợp lệ. Kiểm tra lại các ô.'**
  String get studentsErrorValidation;

  /// No description provided for @studentsErrorNetwork.
  ///
  /// In vi, this message translates to:
  /// **'Không có mạng. Thử lại sau.'**
  String get studentsErrorNetwork;

  /// No description provided for @studentsErrorGeneric.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu được học viên. Thử lại sau.'**
  String get studentsErrorGeneric;

  /// No description provided for @onboardingTitle.
  ///
  /// In vi, this message translates to:
  /// **'Làm quen TeachHub'**
  String get onboardingTitle;

  /// No description provided for @onboardingProgress.
  ///
  /// In vi, this message translates to:
  /// **'Bước {n}/{total}'**
  String onboardingProgress(int n, int total);

  /// No description provided for @onboardingStepCreateClass.
  ///
  /// In vi, this message translates to:
  /// **'Tạo lớp đầu tiên'**
  String get onboardingStepCreateClass;

  /// No description provided for @onboardingStepAddStudents.
  ///
  /// In vi, this message translates to:
  /// **'Thêm học viên'**
  String get onboardingStepAddStudents;

  /// No description provided for @onboardingStepSetSchedule.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lịch học'**
  String get onboardingStepSetSchedule;

  /// No description provided for @onboardingStepPayoutAccount.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản nhận tiền'**
  String get onboardingStepPayoutAccount;

  /// No description provided for @onboardingStepComplianceChecklist.
  ///
  /// In vi, this message translates to:
  /// **'Việc cần làm theo quy định'**
  String get onboardingStepComplianceChecklist;

  /// No description provided for @onboardingSkip.
  ///
  /// In vi, this message translates to:
  /// **'Để sau'**
  String get onboardingSkip;

  /// No description provided for @onboardingMarkDone.
  ///
  /// In vi, this message translates to:
  /// **'Xong bước này'**
  String get onboardingMarkDone;

  /// No description provided for @onboardingPlaceholderBody.
  ///
  /// In vi, this message translates to:
  /// **'Màn này đang được hoàn thiện.'**
  String get onboardingPlaceholderBody;

  /// No description provided for @onboardingPayoutBody.
  ///
  /// In vi, this message translates to:
  /// **'Thêm tài khoản để nhận học phí. Tính năng sắp có.'**
  String get onboardingPayoutBody;

  /// No description provided for @onboardingComplianceBody.
  ///
  /// In vi, this message translates to:
  /// **'Xem các việc cần làm để dạy đúng quy định. Tính năng sắp có.'**
  String get onboardingComplianceBody;

  /// No description provided for @onboardingDoneTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã xong phần làm quen'**
  String get onboardingDoneTitle;

  /// No description provided for @onboardingDoneBody.
  ///
  /// In vi, this message translates to:
  /// **'Vào xem lớp và học viên của bạn.'**
  String get onboardingDoneBody;

  /// No description provided for @onboardingFinish.
  ///
  /// In vi, this message translates to:
  /// **'Vào TeachHub'**
  String get onboardingFinish;

  /// No description provided for @onboardingLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được tiến độ. Thử lại.'**
  String get onboardingLoadFailed;

  /// No description provided for @onboardingRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get onboardingRetry;

  /// No description provided for @onboardingErrorBusy.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu đang xử lý. Thử lại sau giây lát.'**
  String get onboardingErrorBusy;

  /// No description provided for @onboardingErrorValidation.
  ///
  /// In vi, this message translates to:
  /// **'Bước này chưa lưu được. Kiểm tra lại.'**
  String get onboardingErrorValidation;

  /// No description provided for @onboardingErrorNetwork.
  ///
  /// In vi, this message translates to:
  /// **'Không có mạng. Thử lại sau.'**
  String get onboardingErrorNetwork;

  /// No description provided for @onboardingErrorGeneric.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu được. Thử lại sau.'**
  String get onboardingErrorGeneric;

  /// No description provided for @onboardingCreateClassPending.
  ///
  /// In vi, this message translates to:
  /// **'Màn tạo lớp sẽ được nối sau.'**
  String get onboardingCreateClassPending;

  /// No description provided for @onboardingStudentSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu học viên. Chưa ghi nhận được bước này.'**
  String get onboardingStudentSaved;
}

class _MiniAppLocalizationsDelegate
    extends LocalizationsDelegate<MiniAppLocalizations> {
  const _MiniAppLocalizationsDelegate();

  @override
  Future<MiniAppLocalizations> load(Locale locale) {
    return SynchronousFuture<MiniAppLocalizations>(
      lookupMiniAppLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_MiniAppLocalizationsDelegate old) => false;
}

MiniAppLocalizations lookupMiniAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return MiniAppLocalizationsEn();
    case 'vi':
      return MiniAppLocalizationsVi();
  }

  throw FlutterError(
    'MiniAppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
