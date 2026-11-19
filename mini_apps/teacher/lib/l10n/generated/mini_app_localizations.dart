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

  /// No description provided for @classesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lớp học'**
  String get classesTitle;

  /// No description provided for @classesTabActive.
  ///
  /// In vi, this message translates to:
  /// **'Đang dạy'**
  String get classesTabActive;

  /// No description provided for @classesTabArchived.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu trữ'**
  String get classesTabArchived;

  /// No description provided for @classesEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lớp nào'**
  String get classesEmpty;

  /// No description provided for @classesEmptyHint.
  ///
  /// In vi, this message translates to:
  /// **'Tạo lớp đầu tiên để bắt đầu.'**
  String get classesEmptyHint;

  /// No description provided for @classesEmptyArchived.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lớp lưu trữ'**
  String get classesEmptyArchived;

  /// No description provided for @classesCreate.
  ///
  /// In vi, this message translates to:
  /// **'Tạo lớp'**
  String get classesCreate;

  /// No description provided for @classesRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get classesRetry;

  /// No description provided for @classesCancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get classesCancel;

  /// No description provided for @classesItemMeta.
  ///
  /// In vi, this message translates to:
  /// **'{subject} · Khối {grade}'**
  String classesItemMeta(String subject, int grade);

  /// No description provided for @classesStudentCount.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} học viên}}'**
  String classesStudentCount(int count);

  /// No description provided for @classesModeOffline.
  ///
  /// In vi, this message translates to:
  /// **'Tại chỗ'**
  String get classesModeOffline;

  /// No description provided for @classesModeOnline.
  ///
  /// In vi, this message translates to:
  /// **'Trực tuyến'**
  String get classesModeOnline;

  /// No description provided for @classesDetailTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết lớp'**
  String get classesDetailTitle;

  /// No description provided for @classesEdit.
  ///
  /// In vi, this message translates to:
  /// **'Sửa lớp'**
  String get classesEdit;

  /// No description provided for @classesArchive.
  ///
  /// In vi, this message translates to:
  /// **'Lưu trữ lớp'**
  String get classesArchive;

  /// No description provided for @classesArchiveConfirmTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lưu trữ lớp này?'**
  String get classesArchiveConfirmTitle;

  /// No description provided for @classesArchiveConfirmBody.
  ///
  /// In vi, this message translates to:
  /// **'Lớp sẽ ẩn khỏi danh sách và lịch. Dữ liệu vẫn được giữ.'**
  String get classesArchiveConfirmBody;

  /// No description provided for @classesArchivedBanner.
  ///
  /// In vi, this message translates to:
  /// **'Lớp đã lưu trữ.'**
  String get classesArchivedBanner;

  /// No description provided for @classesSectionInfo.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin'**
  String get classesSectionInfo;

  /// No description provided for @classesSectionSchedule.
  ///
  /// In vi, this message translates to:
  /// **'Lịch lặp'**
  String get classesSectionSchedule;

  /// No description provided for @classesSectionSessions.
  ///
  /// In vi, this message translates to:
  /// **'Buổi sắp tới'**
  String get classesSectionSessions;

  /// No description provided for @classesSectionStudents.
  ///
  /// In vi, this message translates to:
  /// **'Học viên'**
  String get classesSectionStudents;

  /// No description provided for @classesNoRules.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đặt lịch lặp.'**
  String get classesNoRules;

  /// No description provided for @classesNoSessions.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có buổi nào trong 2 tháng tới.'**
  String get classesNoSessions;

  /// No description provided for @classesSessionsLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được danh sách buổi.'**
  String get classesSessionsLoadFailed;

  /// No description provided for @classesNoStudents.
  ///
  /// In vi, this message translates to:
  /// **'Lớp chưa có học viên.'**
  String get classesNoStudents;

  /// No description provided for @classesAddStudent.
  ///
  /// In vi, this message translates to:
  /// **'Thêm học viên'**
  String get classesAddStudent;

  /// No description provided for @classesLabelLocation.
  ///
  /// In vi, this message translates to:
  /// **'Địa điểm'**
  String get classesLabelLocation;

  /// No description provided for @classesLabelCapacity.
  ///
  /// In vi, this message translates to:
  /// **'Sĩ số tối đa'**
  String get classesLabelCapacity;

  /// No description provided for @classesLabelStart.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu'**
  String get classesLabelStart;

  /// No description provided for @classesLabelEnd.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc'**
  String get classesLabelEnd;

  /// No description provided for @classesNoEnd.
  ///
  /// In vi, this message translates to:
  /// **'Không kỳ hạn'**
  String get classesNoEnd;

  /// No description provided for @classesRuleLine.
  ///
  /// In vi, this message translates to:
  /// **'{day} · {start} · {minutes} phút'**
  String classesRuleLine(String day, String start, int minutes);

  /// No description provided for @classesSessionLine.
  ///
  /// In vi, this message translates to:
  /// **'{date} · {start}–{end}'**
  String classesSessionLine(String date, String start, String end);

  /// No description provided for @classesSessionPlanned.
  ///
  /// In vi, this message translates to:
  /// **'Dự kiến'**
  String get classesSessionPlanned;

  /// No description provided for @classesSessionTaught.
  ///
  /// In vi, this message translates to:
  /// **'Đã dạy'**
  String get classesSessionTaught;

  /// No description provided for @classesSessionCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy'**
  String get classesSessionCancelled;

  /// No description provided for @classesSessionMakeup.
  ///
  /// In vi, this message translates to:
  /// **'Dạy bù'**
  String get classesSessionMakeup;

  /// No description provided for @classesStudentPaused.
  ///
  /// In vi, this message translates to:
  /// **'Tạm nghỉ'**
  String get classesStudentPaused;

  /// No description provided for @classesFormNewTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo lớp'**
  String get classesFormNewTitle;

  /// No description provided for @classesFormEditTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sửa lớp'**
  String get classesFormEditTitle;

  /// No description provided for @classesFieldName.
  ///
  /// In vi, this message translates to:
  /// **'Tên lớp'**
  String get classesFieldName;

  /// No description provided for @classesFieldSubject.
  ///
  /// In vi, this message translates to:
  /// **'Môn'**
  String get classesFieldSubject;

  /// No description provided for @classesFieldGrade.
  ///
  /// In vi, this message translates to:
  /// **'Khối (1–12)'**
  String get classesFieldGrade;

  /// No description provided for @classesFieldMode.
  ///
  /// In vi, this message translates to:
  /// **'Hình thức'**
  String get classesFieldMode;

  /// No description provided for @classesFieldLocation.
  ///
  /// In vi, this message translates to:
  /// **'Địa điểm'**
  String get classesFieldLocation;

  /// No description provided for @classesFieldCapacity.
  ///
  /// In vi, this message translates to:
  /// **'Sĩ số tối đa (không bắt buộc)'**
  String get classesFieldCapacity;

  /// No description provided for @classesFieldStart.
  ///
  /// In vi, this message translates to:
  /// **'Ngày bắt đầu'**
  String get classesFieldStart;

  /// No description provided for @classesFieldEnd.
  ///
  /// In vi, this message translates to:
  /// **'Ngày kết thúc (không bắt buộc)'**
  String get classesFieldEnd;

  /// No description provided for @classesPickDate.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngày'**
  String get classesPickDate;

  /// No description provided for @classesClearEnd.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ ngày kết thúc'**
  String get classesClearEnd;

  /// No description provided for @classesSave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get classesSave;

  /// No description provided for @classesFormSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu lớp.'**
  String get classesFormSaved;

  /// No description provided for @classesFormSavedSessions.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu lớp. Đã tạo {count, plural, other{{count} buổi}}.'**
  String classesFormSavedSessions(int count);

  /// No description provided for @classesErrRequired.
  ///
  /// In vi, this message translates to:
  /// **'Không được để trống.'**
  String get classesErrRequired;

  /// No description provided for @classesErrGrade.
  ///
  /// In vi, this message translates to:
  /// **'Khối từ 1 đến 12.'**
  String get classesErrGrade;

  /// No description provided for @classesErrCapacity.
  ///
  /// In vi, this message translates to:
  /// **'Sĩ số từ 1 đến 500.'**
  String get classesErrCapacity;

  /// No description provided for @classesErrEndBeforeStart.
  ///
  /// In vi, this message translates to:
  /// **'Ngày kết thúc không được trước ngày bắt đầu.'**
  String get classesErrEndBeforeStart;

  /// No description provided for @classesErrRulesDuplicate.
  ///
  /// In vi, this message translates to:
  /// **'Có hai buổi cùng thứ và giờ bắt đầu.'**
  String get classesErrRulesDuplicate;

  /// No description provided for @classesErrRulesOverflow.
  ///
  /// In vi, this message translates to:
  /// **'Buổi học không được kéo qua 24:00.'**
  String get classesErrRulesOverflow;

  /// No description provided for @classesErrRulesTooMany.
  ///
  /// In vi, this message translates to:
  /// **'Tối đa 14 buổi mỗi tuần.'**
  String get classesErrRulesTooMany;

  /// No description provided for @classesRulesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch lặp hằng tuần'**
  String get classesRulesTitle;

  /// No description provided for @classesRuleAdd.
  ///
  /// In vi, this message translates to:
  /// **'Thêm buổi'**
  String get classesRuleAdd;

  /// No description provided for @classesRuleRemove.
  ///
  /// In vi, this message translates to:
  /// **'Xóa buổi này'**
  String get classesRuleRemove;

  /// No description provided for @classesRuleTime.
  ///
  /// In vi, this message translates to:
  /// **'Giờ bắt đầu'**
  String get classesRuleTime;

  /// No description provided for @classesRuleDuration.
  ///
  /// In vi, this message translates to:
  /// **'Thời lượng (phút)'**
  String get classesRuleDuration;

  /// No description provided for @classesWeekday.
  ///
  /// In vi, this message translates to:
  /// **'{day, select, 1{Thứ Hai} 2{Thứ Ba} 3{Thứ Tư} 4{Thứ Năm} 5{Thứ Sáu} 6{Thứ Bảy} other{Chủ nhật}}'**
  String classesWeekday(String day);

  /// No description provided for @classesWeekdayShort.
  ///
  /// In vi, this message translates to:
  /// **'{day, select, 1{T2} 2{T3} 3{T4} 4{T5} 5{T6} 6{T7} other{CN}}'**
  String classesWeekdayShort(String day);

  /// No description provided for @classesErrNetwork.
  ///
  /// In vi, this message translates to:
  /// **'Không có mạng. Kiểm tra kết nối rồi thử lại.'**
  String get classesErrNetwork;

  /// No description provided for @classesErrPlanLimit.
  ///
  /// In vi, this message translates to:
  /// **'Gói hiện tại đã hết hạn mức. Nâng cấp gói để thêm tiếp.'**
  String get classesErrPlanLimit;

  /// No description provided for @classesErrStale.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu vừa thay đổi. Tải lại rồi thử lại.'**
  String get classesErrStale;

  /// No description provided for @classesErrBusy.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu đang được xử lý. Chờ một chút.'**
  String get classesErrBusy;

  /// No description provided for @classesErrForbidden.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không có quyền thực hiện việc này.'**
  String get classesErrForbidden;

  /// No description provided for @classesErrNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy lớp này.'**
  String get classesErrNotFound;

  /// No description provided for @classesErrValidation.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu chưa hợp lệ. Kiểm tra lại các trường.'**
  String get classesErrValidation;

  /// No description provided for @classesErrGeneric.
  ///
  /// In vi, this message translates to:
  /// **'Có lỗi xảy ra. Thử lại sau.'**
  String get classesErrGeneric;

  /// No description provided for @classesErrEnrollConflict.
  ///
  /// In vi, this message translates to:
  /// **'Lớp đã lưu trữ hoặc học viên đã nghỉ, không thể thêm.'**
  String get classesErrEnrollConflict;

  /// No description provided for @classesPickerTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thêm học viên'**
  String get classesPickerTitle;

  /// No description provided for @classesPickerSearchHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm theo họ tên'**
  String get classesPickerSearchHint;

  /// No description provided for @classesPickerTooShort.
  ///
  /// In vi, this message translates to:
  /// **'Gõ ít nhất 2 ký tự để tìm.'**
  String get classesPickerTooShort;

  /// No description provided for @classesPickerNone.
  ///
  /// In vi, this message translates to:
  /// **'Không thấy học viên nào khớp.'**
  String get classesPickerNone;

  /// No description provided for @classesPickerNoneHint.
  ///
  /// In vi, this message translates to:
  /// **'Học viên mới được thêm ở mục Học viên.'**
  String get classesPickerNoneHint;

  /// No description provided for @classesEnrolled.
  ///
  /// In vi, this message translates to:
  /// **'Đã thêm {name} vào lớp.'**
  String classesEnrolled(String name);

  /// No description provided for @classesAlreadyEnrolled.
  ///
  /// In vi, this message translates to:
  /// **'{name} đã có trong lớp.'**
  String classesAlreadyEnrolled(String name);

  /// No description provided for @classesErrRulesDuration.
  ///
  /// In vi, this message translates to:
  /// **'Thời lượng từ 15 đến 480 phút.'**
  String get classesErrRulesDuration;

  /// No description provided for @classesRuleN.
  ///
  /// In vi, this message translates to:
  /// **'Buổi {n}'**
  String classesRuleN(int n);

  /// No description provided for @classesRuleRemoveN.
  ///
  /// In vi, this message translates to:
  /// **'Xóa buổi {n}'**
  String classesRuleRemoveN(int n);

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

  /// No description provided for @todayTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get todayTitle;

  /// No description provided for @todayEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay không có buổi học'**
  String get todayEmpty;

  /// No description provided for @todayEmptyHint.
  ///
  /// In vi, this message translates to:
  /// **'Buổi học theo lịch của các lớp sẽ hiện ở đây.'**
  String get todayEmptyHint;

  /// No description provided for @todayClassesEntry.
  ///
  /// In vi, this message translates to:
  /// **'Lớp học'**
  String get todayClassesEntry;

  /// No description provided for @todaySessionAttended.
  ///
  /// In vi, this message translates to:
  /// **'Đã điểm danh'**
  String get todaySessionAttended;

  /// No description provided for @todaySessionNotAttended.
  ///
  /// In vi, this message translates to:
  /// **'Chưa điểm danh'**
  String get todaySessionNotAttended;

  /// No description provided for @todaySessionCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy'**
  String get todaySessionCancelled;

  /// No description provided for @todayTakeAttendance.
  ///
  /// In vi, this message translates to:
  /// **'Điểm danh'**
  String get todayTakeAttendance;

  /// No description provided for @todayPending.
  ///
  /// In vi, this message translates to:
  /// **'Chờ đồng bộ ({count})'**
  String todayPending(int count);

  /// No description provided for @todayRefreshFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa làm mới được. Kéo xuống để thử lại.'**
  String get todayRefreshFailed;

  /// No description provided for @todaySessionSemantics.
  ///
  /// In vi, this message translates to:
  /// **'{className}, {time}, {status}'**
  String todaySessionSemantics(String className, String time, String status);

  /// No description provided for @todayOnboardingTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bước làm quen bạn đã để sau'**
  String get todayOnboardingTitle;

  /// No description provided for @todayOnboardingOpen.
  ///
  /// In vi, this message translates to:
  /// **'Mở bước {step}'**
  String todayOnboardingOpen(String step);

  /// No description provided for @attendanceTitle.
  ///
  /// In vi, this message translates to:
  /// **'Điểm danh'**
  String get attendanceTitle;

  /// No description provided for @attendanceStatusPresent.
  ///
  /// In vi, this message translates to:
  /// **'Có mặt'**
  String get attendanceStatusPresent;

  /// No description provided for @attendanceStatusLate.
  ///
  /// In vi, this message translates to:
  /// **'Đi muộn'**
  String get attendanceStatusLate;

  /// No description provided for @attendanceStatusExcused.
  ///
  /// In vi, this message translates to:
  /// **'Vắng có phép'**
  String get attendanceStatusExcused;

  /// No description provided for @attendanceStatusUnexcused.
  ///
  /// In vi, this message translates to:
  /// **'Vắng không phép'**
  String get attendanceStatusUnexcused;

  /// No description provided for @attendanceStudentSemantics.
  ///
  /// In vi, this message translates to:
  /// **'{name}, {status}. Chạm để đổi trạng thái'**
  String attendanceStudentSemantics(String name, String status);

  /// No description provided for @attendanceSave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get attendanceSave;

  /// No description provided for @attendanceSaving.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu…'**
  String get attendanceSaving;

  /// No description provided for @attendanceSaveFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu được. Thử lại.'**
  String get attendanceSaveFailed;

  /// No description provided for @attendanceLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được danh sách học viên.'**
  String get attendanceLoadFailed;

  /// No description provided for @attendanceRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get attendanceRetry;

  /// No description provided for @attendanceEmptyRoster.
  ///
  /// In vi, this message translates to:
  /// **'Lớp này chưa có học viên.'**
  String get attendanceEmptyRoster;

  /// No description provided for @attendanceReadOnlyCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Buổi này đã hủy nên chỉ xem được.'**
  String get attendanceReadOnlyCancelled;

  /// No description provided for @attendanceReadOnlyWindow.
  ///
  /// In vi, this message translates to:
  /// **'Buổi này quá 7 ngày nên chỉ xem, không sửa được.'**
  String get attendanceReadOnlyWindow;

  /// No description provided for @attendanceOfflineNotice.
  ///
  /// In vi, this message translates to:
  /// **'Đang ngoại tuyến. Thay đổi lưu trên máy và gửi khi có mạng.'**
  String get attendanceOfflineNotice;

  /// No description provided for @attendanceNoteLabel.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú'**
  String get attendanceNoteLabel;

  /// No description provided for @attendanceNoteToggle.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú cho {name}'**
  String attendanceNoteToggle(String name);

  /// No description provided for @attendanceRejectedWindow.
  ///
  /// In vi, this message translates to:
  /// **'Đã quá hạn sửa 7 ngày nên thay đổi này không được nhận.'**
  String get attendanceRejectedWindow;

  /// No description provided for @attendanceRejectedPlan.
  ///
  /// In vi, this message translates to:
  /// **'Gói hiện tại chỉ cho xem nên thay đổi này không được nhận.'**
  String get attendanceRejectedPlan;

  /// No description provided for @attendanceRejectedNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Học viên không còn trong buổi này nên thay đổi không được nhận.'**
  String get attendanceRejectedNotFound;

  /// No description provided for @attendanceRejectedGeneric.
  ///
  /// In vi, this message translates to:
  /// **'Thay đổi này không được nhận.'**
  String get attendanceRejectedGeneric;

  /// No description provided for @attendanceBatchNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Buổi này không còn tồn tại nên chưa gửi được điểm danh.'**
  String get attendanceBatchNotFound;

  /// No description provided for @attendanceBatchCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Buổi này đã hủy nên chưa gửi được điểm danh.'**
  String get attendanceBatchCancelled;

  /// No description provided for @attendanceBatchGeneric.
  ///
  /// In vi, this message translates to:
  /// **'Chưa gửi được điểm danh của buổi này.'**
  String get attendanceBatchGeneric;

  /// No description provided for @attendanceDiscard.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ thay đổi bị từ chối'**
  String get attendanceDiscard;

  /// No description provided for @attendanceHistory.
  ///
  /// In vi, this message translates to:
  /// **'Nhật ký sửa'**
  String get attendanceHistory;

  /// No description provided for @historyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhật ký sửa'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Buổi này chưa có lần sửa nào.'**
  String get historyEmpty;

  /// No description provided for @historyLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được nhật ký.'**
  String get historyLoadFailed;

  /// No description provided for @historyLoadMore.
  ///
  /// In vi, this message translates to:
  /// **'Xem thêm'**
  String get historyLoadMore;

  /// No description provided for @historyChangedBy.
  ///
  /// In vi, this message translates to:
  /// **'{who} · {time}'**
  String historyChangedBy(String who, String time);

  /// No description provided for @historyUnknownUser.
  ///
  /// In vi, this message translates to:
  /// **'Không rõ người sửa'**
  String get historyUnknownUser;

  /// No description provided for @historyFirst.
  ///
  /// In vi, this message translates to:
  /// **'Điểm danh lần đầu'**
  String get historyFirst;

  /// No description provided for @historyNote.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú: {note}'**
  String historyNote(String note);

  /// No description provided for @historyNoNote.
  ///
  /// In vi, this message translates to:
  /// **'không có ghi chú'**
  String get historyNoNote;

  /// No description provided for @contactsAdd.
  ///
  /// In vi, this message translates to:
  /// **'Thêm từ danh bạ'**
  String get contactsAdd;

  /// No description provided for @contactsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thêm từ danh bạ'**
  String get contactsTitle;

  /// No description provided for @contactsDeniedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có quyền đọc danh bạ'**
  String get contactsDeniedTitle;

  /// No description provided for @contactsDeniedBody.
  ///
  /// In vi, this message translates to:
  /// **'TeachHub chỉ đọc danh bạ khi bạn bấm Thêm từ danh bạ, để chọn học viên và số của phụ huynh. Bạn vẫn có thể nhập từng học viên bằng tay.'**
  String get contactsDeniedBody;

  /// No description provided for @contactsAllow.
  ///
  /// In vi, this message translates to:
  /// **'Cho phép lại'**
  String get contactsAllow;

  /// No description provided for @contactsOpenSettings.
  ///
  /// In vi, this message translates to:
  /// **'Mở Cài đặt'**
  String get contactsOpenSettings;

  /// No description provided for @contactsManual.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tay'**
  String get contactsManual;

  /// No description provided for @contactsLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không đọc được danh bạ. Thử lại sau.'**
  String get contactsLoadFailed;

  /// No description provided for @contactsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Danh bạ chưa có liên hệ nào.'**
  String get contactsEmpty;

  /// No description provided for @contactsNoPhone.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có số điện thoại'**
  String get contactsNoPhone;

  /// No description provided for @contactsContinue.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục ({n})'**
  String contactsContinue(int n);

  /// No description provided for @contactsSaveAll.
  ///
  /// In vi, this message translates to:
  /// **'Lưu {n} học viên'**
  String contactsSaveAll(int n);

  /// No description provided for @contactsDone.
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get contactsDone;

  /// No description provided for @contactsBack.
  ///
  /// In vi, this message translates to:
  /// **'Chọn lại'**
  String get contactsBack;

  /// No description provided for @contactsRemoveRow.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ {name}'**
  String contactsRemoveRow(String name);

  /// No description provided for @contactsReviewHint.
  ///
  /// In vi, this message translates to:
  /// **'Họ tên liên hệ thành họ tên học viên, số điện thoại thành số của phụ huynh 1. Sửa hoặc bỏ từng dòng trước khi lưu.'**
  String get contactsReviewHint;

  /// No description provided for @contactsRowSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu'**
  String get contactsRowSaved;

  /// No description provided for @contactsRowSaving.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu…'**
  String get contactsRowSaving;

  /// No description provided for @contactsRowFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu được'**
  String get contactsRowFailed;

  /// No description provided for @contactsRowDuplicate.
  ///
  /// In vi, this message translates to:
  /// **'Có thể trùng hồ sơ'**
  String get contactsRowDuplicate;

  /// No description provided for @contactsRowReview.
  ///
  /// In vi, this message translates to:
  /// **'Xem hồ sơ trùng'**
  String get contactsRowReview;

  /// No description provided for @todayScheduleEntry.
  ///
  /// In vi, this message translates to:
  /// **'Lịch'**
  String get todayScheduleEntry;

  /// No description provided for @scheduleTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch'**
  String get scheduleTitle;

  /// No description provided for @scheduleModeDay.
  ///
  /// In vi, this message translates to:
  /// **'Ngày'**
  String get scheduleModeDay;

  /// No description provided for @scheduleModeWeek.
  ///
  /// In vi, this message translates to:
  /// **'Tuần'**
  String get scheduleModeWeek;

  /// No description provided for @schedulePrevious.
  ///
  /// In vi, this message translates to:
  /// **'Trước'**
  String get schedulePrevious;

  /// No description provided for @scheduleNext.
  ///
  /// In vi, this message translates to:
  /// **'Sau'**
  String get scheduleNext;

  /// No description provided for @scheduleToday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get scheduleToday;

  /// No description provided for @scheduleDayHeading.
  ///
  /// In vi, this message translates to:
  /// **'{weekday}, {date}'**
  String scheduleDayHeading(String weekday, String date);

  /// No description provided for @scheduleWeekRange.
  ///
  /// In vi, this message translates to:
  /// **'{from} – {to}'**
  String scheduleWeekRange(String from, String to);

  /// No description provided for @scheduleOfflineBanner.
  ///
  /// In vi, this message translates to:
  /// **'Đang ngoại tuyến. Lịch hiển thị là bản đã lưu gần nhất.'**
  String get scheduleOfflineBanner;

  /// No description provided for @scheduleEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Không có buổi nào trong khoảng này'**
  String get scheduleEmpty;

  /// No description provided for @scheduleLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tải được lịch.'**
  String get scheduleLoadFailed;

  /// No description provided for @scheduleRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get scheduleRetry;

  /// No description provided for @scheduleCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy'**
  String get scheduleCancelled;

  /// No description provided for @scheduleMakeup.
  ///
  /// In vi, this message translates to:
  /// **'Buổi bù'**
  String get scheduleMakeup;

  /// No description provided for @scheduleCancelReason.
  ///
  /// In vi, this message translates to:
  /// **'Lý do: {reason}'**
  String scheduleCancelReason(String reason);

  /// No description provided for @studentsEditTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sửa học viên'**
  String get studentsEditTitle;

  /// No description provided for @studentsGuardianRelation.
  ///
  /// In vi, this message translates to:
  /// **'Quan hệ'**
  String get studentsGuardianRelation;

  /// No description provided for @studentsRelationFather.
  ///
  /// In vi, this message translates to:
  /// **'Bố'**
  String get studentsRelationFather;

  /// No description provided for @studentsRelationMother.
  ///
  /// In vi, this message translates to:
  /// **'Mẹ'**
  String get studentsRelationMother;

  /// No description provided for @studentsRelationGuardian.
  ///
  /// In vi, this message translates to:
  /// **'Người giám hộ'**
  String get studentsRelationGuardian;

  /// No description provided for @inviteStatusNotInvited.
  ///
  /// In vi, this message translates to:
  /// **'Chưa mời'**
  String get inviteStatusNotInvited;

  /// No description provided for @inviteStatusInvited.
  ///
  /// In vi, this message translates to:
  /// **'Đã mời'**
  String get inviteStatusInvited;

  /// No description provided for @inviteStatusActivated.
  ///
  /// In vi, this message translates to:
  /// **'Đã kích hoạt'**
  String get inviteStatusActivated;

  /// No description provided for @inviteStatusExpired.
  ///
  /// In vi, this message translates to:
  /// **'Hết hạn'**
  String get inviteStatusExpired;

  /// No description provided for @inviteShare.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ link'**
  String get inviteShare;

  /// No description provided for @inviteResend.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại link'**
  String get inviteResend;

  /// No description provided for @rosterNoGuardians.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có phụ huynh. Chạm tên em để thêm.'**
  String get rosterNoGuardians;

  /// No description provided for @rosterGuardianLine.
  ///
  /// In vi, this message translates to:
  /// **'{relation}: {name}'**
  String rosterGuardianLine(String relation, String name);

  /// No description provided for @rosterGuardianSemantics.
  ///
  /// In vi, this message translates to:
  /// **'{who}, {status}'**
  String rosterGuardianSemantics(String who, String status);

  /// No description provided for @rosterEditSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Sửa học viên {name}'**
  String rosterEditSemantics(String name);

  /// No description provided for @inviteSheetFor.
  ///
  /// In vi, this message translates to:
  /// **'Mời {guardian}, phụ huynh của {student}'**
  String inviteSheetFor(String guardian, String student);

  /// No description provided for @inviteQrLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR lời mời'**
  String get inviteQrLabel;

  /// No description provided for @inviteCodeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mã nhập tay'**
  String get inviteCodeLabel;

  /// No description provided for @inviteCodeSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Mã mời: {code}'**
  String inviteCodeSemantics(String code);

  /// No description provided for @inviteExpiryNote.
  ///
  /// In vi, this message translates to:
  /// **'Link dùng được 7 ngày, mã nhập tay dùng được 48 giờ.'**
  String get inviteExpiryNote;

  /// No description provided for @inviteOldLinkNote.
  ///
  /// In vi, this message translates to:
  /// **'Link cũ của phụ huynh này (nếu có) không dùng được nữa.'**
  String get inviteOldLinkNote;

  /// No description provided for @inviteShareMessage.
  ///
  /// In vi, this message translates to:
  /// **'Chào {guardian}, mình mời bạn theo dõi việc học của {student} trên TeachHub.\nMở link để nhận lời mời: {url}\nHoặc nhập mã {code} trong ứng dụng TeachHub (mã dùng được 48 giờ).'**
  String inviteShareMessage(
    String guardian,
    String student,
    String url,
    String code,
  );

  /// No description provided for @inviteAllEntry.
  ///
  /// In vi, this message translates to:
  /// **'Mời tất cả phụ huynh chưa kích hoạt'**
  String get inviteAllEntry;

  /// No description provided for @inviteAllTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mời phụ huynh của lớp'**
  String get inviteAllTitle;

  /// No description provided for @inviteAllEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Không còn phụ huynh nào cần mời.'**
  String get inviteAllEmpty;

  /// No description provided for @inviteAllProgress.
  ///
  /// In vi, this message translates to:
  /// **'Đã tạo {done}/{total} link'**
  String inviteAllProgress(int done, int total);

  /// No description provided for @inviteAllHint.
  ///
  /// In vi, this message translates to:
  /// **'Bấm Chia sẻ để gửi lần lượt cho từng phụ huynh. Phụ huynh đang có lời mời còn hạn được bỏ qua.'**
  String get inviteAllHint;

  /// No description provided for @inviteAllPausedNetwork.
  ///
  /// In vi, this message translates to:
  /// **'Đã dừng vì lỗi mạng liên tiếp. Kiểm tra kết nối rồi bấm Tiếp tục.'**
  String get inviteAllPausedNetwork;

  /// No description provided for @inviteAllPausedRate.
  ///
  /// In vi, this message translates to:
  /// **'Đã dừng vì gửi quá nhiều yêu cầu. Chờ khoảng {seconds} giây rồi bấm Tiếp tục.'**
  String inviteAllPausedRate(int seconds);

  /// No description provided for @inviteAllPausedRateNoWait.
  ///
  /// In vi, this message translates to:
  /// **'Đã dừng vì gửi quá nhiều yêu cầu. Chờ một lát rồi bấm Tiếp tục.'**
  String get inviteAllPausedRateNoWait;

  /// No description provided for @inviteAllResume.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get inviteAllResume;

  /// No description provided for @inviteAllWaiting.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tạo'**
  String get inviteAllWaiting;

  /// No description provided for @inviteAllCreating.
  ///
  /// In vi, this message translates to:
  /// **'Đang tạo link…'**
  String get inviteAllCreating;

  /// No description provided for @inviteAllShareAgain.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ lại'**
  String get inviteAllShareAgain;

  /// No description provided for @inviteAllShowQr.
  ///
  /// In vi, this message translates to:
  /// **'Xem mã QR'**
  String get inviteAllShowQr;

  /// No description provided for @inviteAllSharedMark.
  ///
  /// In vi, this message translates to:
  /// **'Đã mở chia sẻ'**
  String get inviteAllSharedMark;

  /// No description provided for @sessionActionReschedule.
  ///
  /// In vi, this message translates to:
  /// **'Đổi giờ'**
  String get sessionActionReschedule;

  /// No description provided for @sessionActionCancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy buổi'**
  String get sessionActionCancel;

  /// No description provided for @sessionActionMakeup.
  ///
  /// In vi, this message translates to:
  /// **'Tạo buổi bù'**
  String get sessionActionMakeup;

  /// No description provided for @sessionRescheduleTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đổi giờ buổi học'**
  String get sessionRescheduleTitle;

  /// No description provided for @sessionCancelTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hủy buổi học?'**
  String get sessionCancelTitle;

  /// No description provided for @sessionCancelBody.
  ///
  /// In vi, this message translates to:
  /// **'Phụ huynh của lớp sẽ nhận thông báo buổi này đã hủy.'**
  String get sessionCancelBody;

  /// No description provided for @sessionMakeupTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo buổi bù'**
  String get sessionMakeupTitle;

  /// No description provided for @sessionPickDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày'**
  String get sessionPickDate;

  /// No description provided for @sessionPickTime.
  ///
  /// In vi, this message translates to:
  /// **'Giờ bắt đầu'**
  String get sessionPickTime;

  /// No description provided for @sessionReasonLabel.
  ///
  /// In vi, this message translates to:
  /// **'Lý do (không bắt buộc)'**
  String get sessionReasonLabel;

  /// No description provided for @sessionConfirmReschedule.
  ///
  /// In vi, this message translates to:
  /// **'Đổi giờ'**
  String get sessionConfirmReschedule;

  /// No description provided for @sessionConfirmCancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy buổi'**
  String get sessionConfirmCancel;

  /// No description provided for @sessionConfirmMakeup.
  ///
  /// In vi, this message translates to:
  /// **'Tạo buổi bù'**
  String get sessionConfirmMakeup;

  /// No description provided for @sessionClose.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get sessionClose;

  /// No description provided for @sessionErrPast.
  ///
  /// In vi, this message translates to:
  /// **'Giờ mới phải ở tương lai.'**
  String get sessionErrPast;

  /// No description provided for @sessionErrCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Buổi này đã hủy nên không đổi giờ được.'**
  String get sessionErrCancelled;

  /// No description provided for @sessionHasAttendanceTitle.
  ///
  /// In vi, this message translates to:
  /// **'Buổi đã có điểm danh'**
  String get sessionHasAttendanceTitle;

  /// No description provided for @sessionHasAttendanceBody.
  ///
  /// In vi, this message translates to:
  /// **'Buổi này đã có điểm danh nên chưa hủy được. Mở bảng điểm danh để sửa lại, rồi hủy buổi sau.'**
  String get sessionHasAttendanceBody;

  /// No description provided for @sessionOpenAttendance.
  ///
  /// In vi, this message translates to:
  /// **'Mở điểm danh'**
  String get sessionOpenAttendance;

  /// No description provided for @sessionDoneRescheduled.
  ///
  /// In vi, this message translates to:
  /// **'Đã đổi giờ buổi học.'**
  String get sessionDoneRescheduled;

  /// No description provided for @sessionDoneCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy buổi học.'**
  String get sessionDoneCancelled;

  /// No description provided for @sessionDoneMakeup.
  ///
  /// In vi, this message translates to:
  /// **'Đã tạo buổi bù.'**
  String get sessionDoneMakeup;

  /// No description provided for @sessionActionsLabel.
  ///
  /// In vi, this message translates to:
  /// **'Thao tác buổi {date} lúc {start}'**
  String sessionActionsLabel(String date, String start);

  /// No description provided for @sessionCancelReasonLine.
  ///
  /// In vi, this message translates to:
  /// **'Lý do hủy: {reason}'**
  String sessionCancelReasonLine(String reason);

  /// No description provided for @todaySettings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt và tài khoản'**
  String get todaySettings;
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
