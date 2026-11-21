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
  /// **'Làm quen DayHoc'**
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
  /// **'Vào DayHoc'**
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
  /// **'DayHoc chỉ đọc danh bạ khi bạn bấm Thêm từ danh bạ, để chọn học viên và số của phụ huynh. Bạn vẫn có thể nhập từng học viên bằng tay.'**
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
  /// **'Chào {guardian}, mình mời bạn theo dõi việc học của {student} trên DayHoc.\nMở link để nhận lời mời: {url}\nHoặc nhập mã {code} trong ứng dụng DayHoc (mã dùng được 48 giờ).'**
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

  /// No description provided for @classesFeeSection.
  ///
  /// In vi, this message translates to:
  /// **'Học phí'**
  String get classesFeeSection;

  /// No description provided for @classesFeeEnabled.
  ///
  /// In vi, this message translates to:
  /// **'Thu học phí'**
  String get classesFeeEnabled;

  /// No description provided for @classesFeeTypeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Cách tính'**
  String get classesFeeTypeLabel;

  /// No description provided for @feeTypePerSession.
  ///
  /// In vi, this message translates to:
  /// **'Theo buổi'**
  String get feeTypePerSession;

  /// No description provided for @feeTypeMonthly.
  ///
  /// In vi, this message translates to:
  /// **'Theo tháng'**
  String get feeTypeMonthly;

  /// No description provided for @feeTypeCourse.
  ///
  /// In vi, this message translates to:
  /// **'Trọn khóa'**
  String get feeTypeCourse;

  /// No description provided for @classesFeeAmountPerSession.
  ///
  /// In vi, this message translates to:
  /// **'Đơn giá mỗi buổi'**
  String get classesFeeAmountPerSession;

  /// No description provided for @classesFeeAmountMonthly.
  ///
  /// In vi, this message translates to:
  /// **'Học phí mỗi tháng'**
  String get classesFeeAmountMonthly;

  /// No description provided for @classesFeeAmountCourse.
  ///
  /// In vi, this message translates to:
  /// **'Tổng học phí cả khóa'**
  String get classesFeeAmountCourse;

  /// No description provided for @classesFeeChargeExcused.
  ///
  /// In vi, this message translates to:
  /// **'Tính tiền buổi vắng có phép'**
  String get classesFeeChargeExcused;

  /// No description provided for @classesFeeChargeUnexcused.
  ///
  /// In vi, this message translates to:
  /// **'Tính tiền buổi vắng không phép'**
  String get classesFeeChargeUnexcused;

  /// No description provided for @classesFeeDeductCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Trừ tiền buổi giáo viên hủy'**
  String get classesFeeDeductCancelled;

  /// No description provided for @classesFeeInstallments.
  ///
  /// In vi, this message translates to:
  /// **'Số đợt thu (1–36)'**
  String get classesFeeInstallments;

  /// No description provided for @classesFeeNote.
  ///
  /// In vi, this message translates to:
  /// **'Đổi học phí chỉ áp dụng từ kỳ thu chưa chốt tiếp theo.'**
  String get classesFeeNote;

  /// No description provided for @classesErrFeeAmountRequired.
  ///
  /// In vi, this message translates to:
  /// **'Nhập số tiền.'**
  String get classesErrFeeAmountRequired;

  /// No description provided for @classesErrFeeAmountRange.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền từ 1 đ đến 1.000.000.000 đ.'**
  String get classesErrFeeAmountRange;

  /// No description provided for @classesErrFeeInstallments.
  ///
  /// In vi, this message translates to:
  /// **'Số đợt từ 1 đến 36, chỉ dùng cho trọn khóa.'**
  String get classesErrFeeInstallments;

  /// No description provided for @classesErrFeeCourseSchedule.
  ///
  /// In vi, this message translates to:
  /// **'Trọn khóa cần có ngày kết thúc và ít nhất một lịch học hằng tuần.'**
  String get classesErrFeeCourseSchedule;

  /// No description provided for @feesErrRateLimited.
  ///
  /// In vi, this message translates to:
  /// **'Bạn thao tác hơi nhanh. Chờ một lúc rồi thử lại.'**
  String get feesErrRateLimited;

  /// No description provided for @rosterFeeOverrideBadge.
  ///
  /// In vi, this message translates to:
  /// **'Giá riêng'**
  String get rosterFeeOverrideBadge;

  /// No description provided for @rosterFeeOverrideAction.
  ///
  /// In vi, this message translates to:
  /// **'Giá riêng cho học viên'**
  String get rosterFeeOverrideAction;

  /// No description provided for @feeOverrideTitle.
  ///
  /// In vi, this message translates to:
  /// **'Giá riêng'**
  String get feeOverrideTitle;

  /// No description provided for @feeOverrideFor.
  ///
  /// In vi, this message translates to:
  /// **'Giá riêng của {name}'**
  String feeOverrideFor(String name);

  /// No description provided for @feeOverrideHint.
  ///
  /// In vi, this message translates to:
  /// **'Để trống mục nào thì mục đó theo cấu hình lớp.'**
  String get feeOverrideHint;

  /// No description provided for @feeOverrideAmount.
  ///
  /// In vi, this message translates to:
  /// **'Giá riêng'**
  String get feeOverrideAmount;

  /// No description provided for @feeOverrideRulesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quy tắc vắng riêng'**
  String get feeOverrideRulesTitle;

  /// No description provided for @feeOverrideInherit.
  ///
  /// In vi, this message translates to:
  /// **'Theo lớp'**
  String get feeOverrideInherit;

  /// No description provided for @feeOverrideYes.
  ///
  /// In vi, this message translates to:
  /// **'Tính'**
  String get feeOverrideYes;

  /// No description provided for @feeOverrideNo.
  ///
  /// In vi, this message translates to:
  /// **'Không tính'**
  String get feeOverrideNo;

  /// No description provided for @feeOverrideInstallments.
  ///
  /// In vi, this message translates to:
  /// **'Số đợt riêng (1–36)'**
  String get feeOverrideInstallments;

  /// No description provided for @feeOverrideDiscounts.
  ///
  /// In vi, this message translates to:
  /// **'Miễn giảm'**
  String get feeOverrideDiscounts;

  /// No description provided for @feeOverrideAddDiscount.
  ///
  /// In vi, this message translates to:
  /// **'Thêm khoản miễn giảm'**
  String get feeOverrideAddDiscount;

  /// No description provided for @feeOverrideDiscountDesc.
  ///
  /// In vi, this message translates to:
  /// **'Mô tả'**
  String get feeOverrideDiscountDesc;

  /// No description provided for @feeOverrideDiscountPercent.
  ///
  /// In vi, this message translates to:
  /// **'Theo %'**
  String get feeOverrideDiscountPercent;

  /// No description provided for @feeOverrideDiscountAmount.
  ///
  /// In vi, this message translates to:
  /// **'Theo số tiền'**
  String get feeOverrideDiscountAmount;

  /// No description provided for @feeOverrideDiscountPercentValue.
  ///
  /// In vi, this message translates to:
  /// **'Phần trăm (1–100)'**
  String get feeOverrideDiscountPercentValue;

  /// No description provided for @feeOverrideDiscountAmountValue.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền'**
  String get feeOverrideDiscountAmountValue;

  /// No description provided for @feeOverrideRemoveDiscount.
  ///
  /// In vi, this message translates to:
  /// **'Xóa khoản miễn giảm'**
  String get feeOverrideRemoveDiscount;

  /// No description provided for @feeOverrideSave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu giá riêng'**
  String get feeOverrideSave;

  /// No description provided for @feeOverrideClear.
  ///
  /// In vi, this message translates to:
  /// **'Xóa giá riêng'**
  String get feeOverrideClear;

  /// No description provided for @feeOverrideSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu giá riêng.'**
  String get feeOverrideSaved;

  /// No description provided for @feeOverrideCleared.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa giá riêng.'**
  String get feeOverrideCleared;

  /// No description provided for @feeOverrideErrAmount.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền không hợp lệ.'**
  String get feeOverrideErrAmount;

  /// No description provided for @feeOverrideErrInstallments.
  ///
  /// In vi, this message translates to:
  /// **'Số đợt từ 1 đến 36.'**
  String get feeOverrideErrInstallments;

  /// No description provided for @feeOverrideErrDiscountDesc.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mô tả, tối đa 100 ký tự.'**
  String get feeOverrideErrDiscountDesc;

  /// No description provided for @feeOverrideErrDiscountValue.
  ///
  /// In vi, this message translates to:
  /// **'Giá trị không hợp lệ.'**
  String get feeOverrideErrDiscountValue;

  /// No description provided for @payoutTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản nhận tiền'**
  String get payoutTitle;

  /// No description provided for @payoutEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tài khoản nhận tiền'**
  String get payoutEmpty;

  /// No description provided for @payoutEmptyBody.
  ///
  /// In vi, this message translates to:
  /// **'Thêm tài khoản để phụ huynh biết chuyển học phí về đâu.'**
  String get payoutEmptyBody;

  /// No description provided for @payoutAdd.
  ///
  /// In vi, this message translates to:
  /// **'Thêm tài khoản'**
  String get payoutAdd;

  /// No description provided for @payoutLimit.
  ///
  /// In vi, this message translates to:
  /// **'Tối đa 5 tài khoản.'**
  String get payoutLimit;

  /// No description provided for @payoutPrimaryBadge.
  ///
  /// In vi, this message translates to:
  /// **'Chính'**
  String get payoutPrimaryBadge;

  /// No description provided for @payoutSetPrimary.
  ///
  /// In vi, this message translates to:
  /// **'Đặt làm chính'**
  String get payoutSetPrimary;

  /// No description provided for @payoutEdit.
  ///
  /// In vi, this message translates to:
  /// **'Sửa'**
  String get payoutEdit;

  /// No description provided for @payoutDelete.
  ///
  /// In vi, this message translates to:
  /// **'Xóa'**
  String get payoutDelete;

  /// No description provided for @payoutCancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get payoutCancel;

  /// No description provided for @payoutDeleteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tài khoản này?'**
  String get payoutDeleteTitle;

  /// No description provided for @payoutDeleteBody.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản sẽ bị gỡ khỏi danh sách nhận tiền.'**
  String get payoutDeleteBody;

  /// No description provided for @payoutDeleteLastBody.
  ///
  /// In vi, this message translates to:
  /// **'Đây là tài khoản nhận tiền duy nhất. Xóa xong, bạn sẽ chưa chốt được kỳ học phí cho đến khi thêm tài khoản mới.'**
  String get payoutDeleteLastBody;

  /// No description provided for @payoutLine.
  ///
  /// In vi, this message translates to:
  /// **'{bank} · {masked}'**
  String payoutLine(String bank, String masked);

  /// No description provided for @payoutUnknownBank.
  ///
  /// In vi, this message translates to:
  /// **'Ngân hàng {bin}'**
  String payoutUnknownBank(String bin);

  /// No description provided for @payoutSemantics.
  ///
  /// In vi, this message translates to:
  /// **'{name}, {line}'**
  String payoutSemantics(String name, String line);

  /// No description provided for @payoutActionsSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Tác vụ cho tài khoản {name}'**
  String payoutActionsSemantics(String name);

  /// No description provided for @payoutContinue.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get payoutContinue;

  /// No description provided for @payoutSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu tài khoản.'**
  String get payoutSaved;

  /// No description provided for @payoutDeleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa tài khoản.'**
  String get payoutDeleted;

  /// No description provided for @payoutPrimarySet.
  ///
  /// In vi, this message translates to:
  /// **'Đã đặt làm tài khoản chính.'**
  String get payoutPrimarySet;

  /// No description provided for @payoutFormNewTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thêm tài khoản'**
  String get payoutFormNewTitle;

  /// No description provided for @payoutFormEditTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sửa tài khoản'**
  String get payoutFormEditTitle;

  /// No description provided for @payoutFieldBank.
  ///
  /// In vi, this message translates to:
  /// **'Ngân hàng'**
  String get payoutFieldBank;

  /// No description provided for @payoutPickBank.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngân hàng'**
  String get payoutPickBank;

  /// No description provided for @payoutFieldAccountNo.
  ///
  /// In vi, this message translates to:
  /// **'Số tài khoản'**
  String get payoutFieldAccountNo;

  /// No description provided for @payoutFieldAccountNoEditHint.
  ///
  /// In vi, this message translates to:
  /// **'Để trống nếu không đổi số'**
  String get payoutFieldAccountNoEditHint;

  /// No description provided for @payoutFieldName.
  ///
  /// In vi, this message translates to:
  /// **'Tên chủ tài khoản'**
  String get payoutFieldName;

  /// No description provided for @payoutFieldNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Viết đúng như ngân hàng ghi'**
  String get payoutFieldNameHint;

  /// No description provided for @payoutOtpNeeded.
  ///
  /// In vi, this message translates to:
  /// **'Thêm tài khoản hoặc đổi ngân hàng, số tài khoản cần mã xác thực gửi qua email.'**
  String get payoutOtpNeeded;

  /// No description provided for @payoutSendCode.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã xác thực'**
  String get payoutSendCode;

  /// No description provided for @payoutSave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get payoutSave;

  /// No description provided for @payoutOtpSent.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi mã tới email của bạn.'**
  String get payoutOtpSent;

  /// No description provided for @payoutOtpField.
  ///
  /// In vi, this message translates to:
  /// **'Mã xác thực (6 số)'**
  String get payoutOtpField;

  /// No description provided for @payoutOtpConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận và lưu'**
  String get payoutOtpConfirm;

  /// No description provided for @payoutOtpResend.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại mã'**
  String get payoutOtpResend;

  /// No description provided for @payoutOtpBack.
  ///
  /// In vi, this message translates to:
  /// **'Sửa thông tin'**
  String get payoutOtpBack;

  /// No description provided for @payoutErrOtpInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Mã chưa đúng. Kiểm tra lại mã trong email.'**
  String get payoutErrOtpInvalid;

  /// No description provided for @payoutErrOtpLocked.
  ///
  /// In vi, this message translates to:
  /// **'Bạn nhập sai quá nhiều lần. Vui lòng thử lại sau.'**
  String get payoutErrOtpLocked;

  /// No description provided for @payoutErrMissing.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa có tài khoản nhận tiền. Thêm tài khoản trước khi gửi hóa đơn.'**
  String get payoutErrMissing;

  /// No description provided for @payoutErrBank.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngân hàng.'**
  String get payoutErrBank;

  /// No description provided for @payoutErrRequired.
  ///
  /// In vi, this message translates to:
  /// **'Không được để trống.'**
  String get payoutErrRequired;

  /// No description provided for @payoutErrAccountNo.
  ///
  /// In vi, this message translates to:
  /// **'Số tài khoản gồm 6 đến 19 chữ số.'**
  String get payoutErrAccountNo;

  /// No description provided for @payoutErrName.
  ///
  /// In vi, this message translates to:
  /// **'Tên tối đa 50 ký tự.'**
  String get payoutErrName;

  /// No description provided for @payoutLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được danh sách tài khoản.'**
  String get payoutLoadFailed;

  /// No description provided for @onboardingPayoutIntro.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ít nhất một tài khoản để nhận học phí.'**
  String get onboardingPayoutIntro;

  /// No description provided for @todayBillingEntry.
  ///
  /// In vi, this message translates to:
  /// **'Học phí kỳ thu'**
  String get todayBillingEntry;

  /// No description provided for @billingTitle.
  ///
  /// In vi, this message translates to:
  /// **'Học phí kỳ thu'**
  String get billingTitle;

  /// No description provided for @billingPeriodsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có kỳ thu nào'**
  String get billingPeriodsEmpty;

  /// No description provided for @billingPeriodsEmptyBody.
  ///
  /// In vi, this message translates to:
  /// **'Đến ngày chốt, app tự tạo bản nháp hóa đơn của tháng để bạn kiểm tra trước khi gửi.'**
  String get billingPeriodsEmptyBody;

  /// No description provided for @billingLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được dữ liệu học phí.'**
  String get billingLoadFailed;

  /// No description provided for @billingPeriodMonth.
  ///
  /// In vi, this message translates to:
  /// **'Tháng {month}/{year}'**
  String billingPeriodMonth(int month, int year);

  /// No description provided for @billingPeriodDates.
  ///
  /// In vi, this message translates to:
  /// **'Chốt {close} · Hạn {due}'**
  String billingPeriodDates(String close, String due);

  /// No description provided for @billingPeriodDrafting.
  ///
  /// In vi, this message translates to:
  /// **'Đang soạn'**
  String get billingPeriodDrafting;

  /// No description provided for @billingPeriodClosed.
  ///
  /// In vi, this message translates to:
  /// **'Đã chốt hết'**
  String get billingPeriodClosed;

  /// No description provided for @billingDraftSummary.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} bản nháp}} · {amount}'**
  String billingDraftSummary(int count, String amount);

  /// No description provided for @billingIssuedSummary.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{Đã gửi {count} hóa đơn}} · {amount}'**
  String billingIssuedSummary(int count, String amount);

  /// No description provided for @billingVoidSummary.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} hóa đơn đã hủy}}'**
  String billingVoidSummary(int count);

  /// No description provided for @billingIssueAll.
  ///
  /// In vi, this message translates to:
  /// **'Chốt & gửi tất cả'**
  String get billingIssueAll;

  /// No description provided for @billingIssueOne.
  ///
  /// In vi, this message translates to:
  /// **'Chốt & gửi'**
  String get billingIssueOne;

  /// No description provided for @billingIssueConfirmTitle.
  ///
  /// In vi, this message translates to:
  /// **'Gửi hóa đơn cho phụ huynh?'**
  String get billingIssueConfirmTitle;

  /// No description provided for @billingIssueAllConfirmBody.
  ///
  /// In vi, this message translates to:
  /// **'Chốt {count, plural, other{{count} hóa đơn}}, tổng {amount}. Phụ huynh nhận thông báo ngay và hóa đơn không sửa được sau khi gửi.'**
  String billingIssueAllConfirmBody(int count, String amount);

  /// No description provided for @billingIssueOneConfirmBody.
  ///
  /// In vi, this message translates to:
  /// **'Chốt hóa đơn của {student}, {amount}. Phụ huynh nhận thông báo ngay và hóa đơn không sửa được sau khi gửi.'**
  String billingIssueOneConfirmBody(String student, String amount);

  /// No description provided for @billingIssued.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi {count, plural, other{{count} hóa đơn}}.'**
  String billingIssued(int count);

  /// No description provided for @billingIssuedNone.
  ///
  /// In vi, this message translates to:
  /// **'Không có hóa đơn nào cần gửi.'**
  String get billingIssuedNone;

  /// No description provided for @billingIssuedSkippedZero.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} hóa đơn}} 0 đ không gửi.'**
  String billingIssuedSkippedZero(int count);

  /// No description provided for @billingNoPayableDrafts.
  ///
  /// In vi, this message translates to:
  /// **'Không còn bản nháp nào có tiền để gửi.'**
  String get billingNoPayableDrafts;

  /// No description provided for @billingZeroDraftNote.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} hóa đơn}} 0 đ sẽ không được gửi.'**
  String billingZeroDraftNote(int count);

  /// No description provided for @billingInvoicesEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Kỳ này chưa có hóa đơn.'**
  String get billingInvoicesEmpty;

  /// No description provided for @billingNoSend.
  ///
  /// In vi, this message translates to:
  /// **'Không gửi'**
  String get billingNoSend;

  /// No description provided for @billingHasOverride.
  ///
  /// In vi, this message translates to:
  /// **'Giá riêng'**
  String get billingHasOverride;

  /// No description provided for @billingStatusDraft.
  ///
  /// In vi, this message translates to:
  /// **'Bản nháp'**
  String get billingStatusDraft;

  /// No description provided for @billingStatusIssued.
  ///
  /// In vi, this message translates to:
  /// **'Đã phát hành'**
  String get billingStatusIssued;

  /// No description provided for @billingStatusPending.
  ///
  /// In vi, this message translates to:
  /// **'Chờ xác nhận'**
  String get billingStatusPending;

  /// No description provided for @billingStatusPartial.
  ///
  /// In vi, this message translates to:
  /// **'Đã thanh toán một phần'**
  String get billingStatusPartial;

  /// No description provided for @billingStatusPaid.
  ///
  /// In vi, this message translates to:
  /// **'Đã thanh toán'**
  String get billingStatusPaid;

  /// No description provided for @billingStatusVoid.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy'**
  String get billingStatusVoid;

  /// No description provided for @billingInvoiceTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hóa đơn'**
  String get billingInvoiceTitle;

  /// No description provided for @billingLinesSessions.
  ///
  /// In vi, this message translates to:
  /// **'Các buổi học'**
  String get billingLinesSessions;

  /// No description provided for @billingLinesOther.
  ///
  /// In vi, this message translates to:
  /// **'Khoản khác'**
  String get billingLinesOther;

  /// No description provided for @billingSessionLine.
  ///
  /// In vi, this message translates to:
  /// **'{date} · {className}'**
  String billingSessionLine(String date, String className);

  /// No description provided for @billingSessionCharged.
  ///
  /// In vi, this message translates to:
  /// **'Tính tiền'**
  String get billingSessionCharged;

  /// No description provided for @billingSessionNotCharged.
  ///
  /// In vi, this message translates to:
  /// **'Không tính: {reason}'**
  String billingSessionNotCharged(String reason);

  /// No description provided for @billingReasonExcused.
  ///
  /// In vi, this message translates to:
  /// **'vắng có phép'**
  String get billingReasonExcused;

  /// No description provided for @billingReasonUnexcused.
  ///
  /// In vi, this message translates to:
  /// **'vắng không phép'**
  String get billingReasonUnexcused;

  /// No description provided for @billingReasonCancelled.
  ///
  /// In vi, this message translates to:
  /// **'buổi bị hủy'**
  String get billingReasonCancelled;

  /// No description provided for @billingReasonMakeup.
  ///
  /// In vi, this message translates to:
  /// **'buổi dạy bù'**
  String get billingReasonMakeup;

  /// No description provided for @billingReasonOther.
  ///
  /// In vi, this message translates to:
  /// **'theo quy tắc của lớp'**
  String get billingReasonOther;

  /// No description provided for @billingAdjustmentReasonLine.
  ///
  /// In vi, this message translates to:
  /// **'Lý do: {reason}'**
  String billingAdjustmentReasonLine(String reason);

  /// No description provided for @billingTotal.
  ///
  /// In vi, this message translates to:
  /// **'Tổng cộng'**
  String get billingTotal;

  /// No description provided for @billingClamped.
  ///
  /// In vi, this message translates to:
  /// **'Điều chỉnh làm tổng âm nên tổng được giữ ở 0 đ; phần âm {amount} chưa được chuyển sang kỳ sau.'**
  String billingClamped(String amount);

  /// No description provided for @billingAddAdjustment.
  ///
  /// In vi, this message translates to:
  /// **'Thêm điều chỉnh'**
  String get billingAddAdjustment;

  /// No description provided for @billingAdjustTitle.
  ///
  /// In vi, this message translates to:
  /// **'Điều chỉnh hóa đơn'**
  String get billingAdjustTitle;

  /// No description provided for @billingAdjustHint.
  ///
  /// In vi, this message translates to:
  /// **'Dòng điều chỉnh chưa xóa được. Nhập sai thì thêm một dòng ngược dấu.'**
  String get billingAdjustHint;

  /// No description provided for @billingAdjustDecrease.
  ///
  /// In vi, this message translates to:
  /// **'Giảm trừ'**
  String get billingAdjustDecrease;

  /// No description provided for @billingAdjustIncrease.
  ///
  /// In vi, this message translates to:
  /// **'Phụ thu'**
  String get billingAdjustIncrease;

  /// No description provided for @billingAdjustAmount.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền'**
  String get billingAdjustAmount;

  /// No description provided for @billingAdjustDescription.
  ///
  /// In vi, this message translates to:
  /// **'Mô tả'**
  String get billingAdjustDescription;

  /// No description provided for @billingAdjustReason.
  ///
  /// In vi, this message translates to:
  /// **'Lý do (bắt buộc)'**
  String get billingAdjustReason;

  /// No description provided for @billingAdjustSave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu điều chỉnh'**
  String get billingAdjustSave;

  /// No description provided for @billingAdjusted.
  ///
  /// In vi, this message translates to:
  /// **'Đã thêm điều chỉnh.'**
  String get billingAdjusted;

  /// No description provided for @billingErrAmount.
  ///
  /// In vi, this message translates to:
  /// **'Nhập số tiền lớn hơn 0 và không quá 1.000.000.000 đ.'**
  String get billingErrAmount;

  /// No description provided for @billingErrDescription.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mô tả, tối đa 200 ký tự.'**
  String get billingErrDescription;

  /// No description provided for @billingErrReason.
  ///
  /// In vi, this message translates to:
  /// **'Nhập lý do, tối đa 300 ký tự.'**
  String get billingErrReason;

  /// No description provided for @billingErrImmutable.
  ///
  /// In vi, this message translates to:
  /// **'Hóa đơn đã phát hành nên không sửa được. Hãy hủy rồi tạo hóa đơn thay thế.'**
  String get billingErrImmutable;

  /// No description provided for @billingErrStaleUnverified.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác nhận được kết quả. Kéo để tải lại rồi kiểm tra trước khi chốt tiếp.'**
  String get billingErrStaleUnverified;

  /// No description provided for @billingErrStale.
  ///
  /// In vi, this message translates to:
  /// **'Hóa đơn vừa có thay đổi, đã cập nhật trạng thái mới nhất. Kiểm tra lại rồi thử lần nữa.'**
  String get billingErrStale;

  /// No description provided for @billingVoid.
  ///
  /// In vi, this message translates to:
  /// **'Hủy hóa đơn'**
  String get billingVoid;

  /// No description provided for @billingVoidTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hủy hóa đơn này?'**
  String get billingVoidTitle;

  /// No description provided for @billingVoidBody.
  ///
  /// In vi, this message translates to:
  /// **'Phụ huynh sẽ không còn thấy mã QR của hóa đơn. Cần ghi lý do hủy.'**
  String get billingVoidBody;

  /// No description provided for @billingVoidReason.
  ///
  /// In vi, this message translates to:
  /// **'Lý do hủy'**
  String get billingVoidReason;

  /// No description provided for @billingVoidKeep.
  ///
  /// In vi, this message translates to:
  /// **'Giữ lại'**
  String get billingVoidKeep;

  /// No description provided for @billingVoidConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Hủy hóa đơn'**
  String get billingVoidConfirm;

  /// No description provided for @billingVoided.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy hóa đơn.'**
  String get billingVoided;

  /// No description provided for @billingVoidedBanner.
  ///
  /// In vi, this message translates to:
  /// **'Hóa đơn đã hủy. Lý do: {reason}'**
  String billingVoidedBanner(String reason);

  /// No description provided for @billingPayoutMissingTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tài khoản nhận tiền'**
  String get billingPayoutMissingTitle;

  /// No description provided for @billingPayoutMissingBody.
  ///
  /// In vi, this message translates to:
  /// **'Thêm tài khoản nhận tiền để phụ huynh biết chuyển học phí về đâu. Thêm xong, quay lại đây để chốt tiếp.'**
  String get billingPayoutMissingBody;

  /// No description provided for @billingPayoutMissingAction.
  ///
  /// In vi, this message translates to:
  /// **'Thêm tài khoản'**
  String get billingPayoutMissingAction;

  /// No description provided for @payoutOtpActionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xác thực để tiếp tục'**
  String get payoutOtpActionTitle;

  /// No description provided for @payoutOtpActionBody.
  ///
  /// In vi, this message translates to:
  /// **'Đổi hoặc xóa tài khoản nhận tiền chính cần mã xác thực. Mã đã gửi tới email của bạn.'**
  String get payoutOtpActionBody;

  /// No description provided for @payoutOtpActionConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get payoutOtpActionConfirm;

  /// No description provided for @billingIssueAllConfirmAction.
  ///
  /// In vi, this message translates to:
  /// **'Gửi tất cả'**
  String get billingIssueAllConfirmAction;
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
