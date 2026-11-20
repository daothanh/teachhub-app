// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'mini_app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class MiniAppLocalizationsVi extends MiniAppLocalizations {
  MiniAppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get spaceTitle => 'Giáo viên';

  @override
  String get switchRole => 'Đổi vai trò';

  @override
  String get offlineBanner =>
      'Ngoại tuyến — thay đổi được lưu trên máy và tự đồng bộ khi có mạng.';

  @override
  String get classesTitle => 'Lớp học';

  @override
  String get classesTabActive => 'Đang dạy';

  @override
  String get classesTabArchived => 'Đã lưu trữ';

  @override
  String get classesEmpty => 'Chưa có lớp nào';

  @override
  String get classesEmptyHint => 'Tạo lớp đầu tiên để bắt đầu.';

  @override
  String get classesEmptyArchived => 'Chưa có lớp lưu trữ';

  @override
  String get classesCreate => 'Tạo lớp';

  @override
  String get classesRetry => 'Thử lại';

  @override
  String get classesCancel => 'Hủy';

  @override
  String classesItemMeta(String subject, int grade) {
    return '$subject · Khối $grade';
  }

  @override
  String classesStudentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count học viên',
    );
    return '$_temp0';
  }

  @override
  String get classesModeOffline => 'Tại chỗ';

  @override
  String get classesModeOnline => 'Trực tuyến';

  @override
  String get classesDetailTitle => 'Chi tiết lớp';

  @override
  String get classesEdit => 'Sửa lớp';

  @override
  String get classesArchive => 'Lưu trữ lớp';

  @override
  String get classesArchiveConfirmTitle => 'Lưu trữ lớp này?';

  @override
  String get classesArchiveConfirmBody =>
      'Lớp sẽ ẩn khỏi danh sách và lịch. Dữ liệu vẫn được giữ.';

  @override
  String get classesArchivedBanner => 'Lớp đã lưu trữ.';

  @override
  String get classesSectionInfo => 'Thông tin';

  @override
  String get classesSectionSchedule => 'Lịch lặp';

  @override
  String get classesSectionSessions => 'Buổi sắp tới';

  @override
  String get classesSectionStudents => 'Học viên';

  @override
  String get classesNoRules => 'Chưa đặt lịch lặp.';

  @override
  String get classesNoSessions => 'Chưa có buổi nào trong 2 tháng tới.';

  @override
  String get classesSessionsLoadFailed => 'Không tải được danh sách buổi.';

  @override
  String get classesNoStudents => 'Lớp chưa có học viên.';

  @override
  String get classesAddStudent => 'Thêm học viên';

  @override
  String get classesLabelLocation => 'Địa điểm';

  @override
  String get classesLabelCapacity => 'Sĩ số tối đa';

  @override
  String get classesLabelStart => 'Bắt đầu';

  @override
  String get classesLabelEnd => 'Kết thúc';

  @override
  String get classesNoEnd => 'Không kỳ hạn';

  @override
  String classesRuleLine(String day, String start, int minutes) {
    return '$day · $start · $minutes phút';
  }

  @override
  String classesSessionLine(String date, String start, String end) {
    return '$date · $start–$end';
  }

  @override
  String get classesSessionPlanned => 'Dự kiến';

  @override
  String get classesSessionTaught => 'Đã dạy';

  @override
  String get classesSessionCancelled => 'Đã hủy';

  @override
  String get classesSessionMakeup => 'Dạy bù';

  @override
  String get classesStudentPaused => 'Tạm nghỉ';

  @override
  String get classesFormNewTitle => 'Tạo lớp';

  @override
  String get classesFormEditTitle => 'Sửa lớp';

  @override
  String get classesFieldName => 'Tên lớp';

  @override
  String get classesFieldSubject => 'Môn';

  @override
  String get classesFieldGrade => 'Khối (1–12)';

  @override
  String get classesFieldMode => 'Hình thức';

  @override
  String get classesFieldLocation => 'Địa điểm';

  @override
  String get classesFieldCapacity => 'Sĩ số tối đa (không bắt buộc)';

  @override
  String get classesFieldStart => 'Ngày bắt đầu';

  @override
  String get classesFieldEnd => 'Ngày kết thúc (không bắt buộc)';

  @override
  String get classesPickDate => 'Chọn ngày';

  @override
  String get classesClearEnd => 'Bỏ ngày kết thúc';

  @override
  String get classesSave => 'Lưu';

  @override
  String get classesFormSaved => 'Đã lưu lớp.';

  @override
  String classesFormSavedSessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count buổi',
    );
    return 'Đã lưu lớp. Đã tạo $_temp0.';
  }

  @override
  String get classesErrRequired => 'Không được để trống.';

  @override
  String get classesErrGrade => 'Khối từ 1 đến 12.';

  @override
  String get classesErrCapacity => 'Sĩ số từ 1 đến 500.';

  @override
  String get classesErrEndBeforeStart =>
      'Ngày kết thúc không được trước ngày bắt đầu.';

  @override
  String get classesErrRulesDuplicate => 'Có hai buổi cùng thứ và giờ bắt đầu.';

  @override
  String get classesErrRulesOverflow => 'Buổi học không được kéo qua 24:00.';

  @override
  String get classesErrRulesTooMany => 'Tối đa 14 buổi mỗi tuần.';

  @override
  String get classesRulesTitle => 'Lịch lặp hằng tuần';

  @override
  String get classesRuleAdd => 'Thêm buổi';

  @override
  String get classesRuleRemove => 'Xóa buổi này';

  @override
  String get classesRuleTime => 'Giờ bắt đầu';

  @override
  String get classesRuleDuration => 'Thời lượng (phút)';

  @override
  String classesWeekday(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'Thứ Hai',
      '2': 'Thứ Ba',
      '3': 'Thứ Tư',
      '4': 'Thứ Năm',
      '5': 'Thứ Sáu',
      '6': 'Thứ Bảy',
      'other': 'Chủ nhật',
    });
    return '$_temp0';
  }

  @override
  String classesWeekdayShort(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'T2',
      '2': 'T3',
      '3': 'T4',
      '4': 'T5',
      '5': 'T6',
      '6': 'T7',
      'other': 'CN',
    });
    return '$_temp0';
  }

  @override
  String get classesErrNetwork =>
      'Không có mạng. Kiểm tra kết nối rồi thử lại.';

  @override
  String get classesErrPlanLimit =>
      'Gói hiện tại đã hết hạn mức. Nâng cấp gói để thêm tiếp.';

  @override
  String get classesErrStale => 'Dữ liệu vừa thay đổi. Tải lại rồi thử lại.';

  @override
  String get classesErrBusy => 'Yêu cầu đang được xử lý. Chờ một chút.';

  @override
  String get classesErrForbidden => 'Bạn không có quyền thực hiện việc này.';

  @override
  String get classesErrNotFound => 'Không tìm thấy lớp này.';

  @override
  String get classesErrValidation =>
      'Dữ liệu chưa hợp lệ. Kiểm tra lại các trường.';

  @override
  String get classesErrGeneric => 'Có lỗi xảy ra. Thử lại sau.';

  @override
  String get classesErrEnrollConflict =>
      'Lớp đã lưu trữ hoặc học viên đã nghỉ, không thể thêm.';

  @override
  String get classesPickerTitle => 'Thêm học viên';

  @override
  String get classesPickerSearchHint => 'Tìm theo họ tên';

  @override
  String get classesPickerTooShort => 'Gõ ít nhất 2 ký tự để tìm.';

  @override
  String get classesPickerNone => 'Không thấy học viên nào khớp.';

  @override
  String get classesPickerNoneHint => 'Học viên mới được thêm ở mục Học viên.';

  @override
  String classesEnrolled(String name) {
    return 'Đã thêm $name vào lớp.';
  }

  @override
  String classesAlreadyEnrolled(String name) {
    return '$name đã có trong lớp.';
  }

  @override
  String get classesErrRulesDuration => 'Thời lượng từ 15 đến 480 phút.';

  @override
  String classesRuleN(int n) {
    return 'Buổi $n';
  }

  @override
  String classesRuleRemoveN(int n) {
    return 'Xóa buổi $n';
  }

  @override
  String get studentsFormTitle => 'Thêm học viên';

  @override
  String get studentsFullName => 'Họ và tên';

  @override
  String get studentsFullNameRequired => 'Nhập họ tên học viên.';

  @override
  String get studentsDob => 'Ngày sinh (không bắt buộc)';

  @override
  String get studentsSchool => 'Trường (không bắt buộc)';

  @override
  String get studentsNote => 'Ghi chú (không bắt buộc)';

  @override
  String studentsGuardianTitle(int n) {
    return 'Phụ huynh $n';
  }

  @override
  String get studentsGuardianName => 'Họ tên phụ huynh';

  @override
  String get studentsGuardianNameRequired => 'Nhập họ tên phụ huynh.';

  @override
  String get studentsGuardianPhone => 'Số điện thoại (không bắt buộc)';

  @override
  String get studentsGuardianPhoneInvalid => 'Số điện thoại chưa đúng.';

  @override
  String get studentsAddGuardian => 'Thêm phụ huynh';

  @override
  String studentsRemoveGuardian(int n) {
    return 'Xóa phụ huynh $n';
  }

  @override
  String get studentsSave => 'Lưu học viên';

  @override
  String get studentsSaving => 'Đang lưu…';

  @override
  String get studentsDuplicateTitle => 'Có phải cùng một em?';

  @override
  String get studentsDuplicateBody =>
      'Đã có hồ sơ trùng họ tên và ngày sinh. Chọn đúng em, hoặc thêm em mới.';

  @override
  String get studentsDuplicateSame => 'Đúng, là em này';

  @override
  String get studentsDuplicateNew => 'Không, thêm em mới';

  @override
  String get studentsDuplicateCancel => 'Quay lại sửa';

  @override
  String get studentsErrorLimit =>
      'Gói hiện tại đã đủ số học viên. Nâng cấp để thêm.';

  @override
  String get studentsErrorBusy => 'Yêu cầu đang xử lý. Thử lại sau giây lát.';

  @override
  String get studentsErrorValidation =>
      'Thông tin chưa hợp lệ. Kiểm tra lại các ô.';

  @override
  String get studentsErrorNetwork => 'Không có mạng. Thử lại sau.';

  @override
  String get studentsErrorGeneric => 'Chưa lưu được học viên. Thử lại sau.';

  @override
  String get onboardingTitle => 'Làm quen DayHoc';

  @override
  String onboardingProgress(int n, int total) {
    return 'Bước $n/$total';
  }

  @override
  String get onboardingStepCreateClass => 'Tạo lớp đầu tiên';

  @override
  String get onboardingStepAddStudents => 'Thêm học viên';

  @override
  String get onboardingStepSetSchedule => 'Đặt lịch học';

  @override
  String get onboardingStepPayoutAccount => 'Tài khoản nhận tiền';

  @override
  String get onboardingStepComplianceChecklist => 'Việc cần làm theo quy định';

  @override
  String get onboardingSkip => 'Để sau';

  @override
  String get onboardingMarkDone => 'Xong bước này';

  @override
  String get onboardingPlaceholderBody => 'Màn này đang được hoàn thiện.';

  @override
  String get onboardingComplianceBody =>
      'Xem các việc cần làm để dạy đúng quy định. Tính năng sắp có.';

  @override
  String get onboardingDoneTitle => 'Bạn đã xong phần làm quen';

  @override
  String get onboardingDoneBody => 'Vào xem lớp và học viên của bạn.';

  @override
  String get onboardingFinish => 'Vào DayHoc';

  @override
  String get onboardingLoadFailed => 'Không tải được tiến độ. Thử lại.';

  @override
  String get onboardingRetry => 'Thử lại';

  @override
  String get onboardingErrorBusy => 'Yêu cầu đang xử lý. Thử lại sau giây lát.';

  @override
  String get onboardingErrorValidation =>
      'Bước này chưa lưu được. Kiểm tra lại.';

  @override
  String get onboardingErrorNetwork => 'Không có mạng. Thử lại sau.';

  @override
  String get onboardingErrorGeneric => 'Chưa lưu được. Thử lại sau.';

  @override
  String get onboardingCreateClassPending => 'Màn tạo lớp sẽ được nối sau.';

  @override
  String get onboardingStudentSaved =>
      'Đã lưu học viên. Chưa ghi nhận được bước này.';

  @override
  String get todayTitle => 'Hôm nay';

  @override
  String get todayEmpty => 'Hôm nay không có buổi học';

  @override
  String get todayEmptyHint => 'Buổi học theo lịch của các lớp sẽ hiện ở đây.';

  @override
  String get todayClassesEntry => 'Lớp học';

  @override
  String get todaySessionAttended => 'Đã điểm danh';

  @override
  String get todaySessionNotAttended => 'Chưa điểm danh';

  @override
  String get todaySessionCancelled => 'Đã hủy';

  @override
  String get todayTakeAttendance => 'Điểm danh';

  @override
  String todayPending(int count) {
    return 'Chờ đồng bộ ($count)';
  }

  @override
  String get todayRefreshFailed => 'Chưa làm mới được. Kéo xuống để thử lại.';

  @override
  String todaySessionSemantics(String className, String time, String status) {
    return '$className, $time, $status';
  }

  @override
  String get todayOnboardingTitle => 'Bước làm quen bạn đã để sau';

  @override
  String todayOnboardingOpen(String step) {
    return 'Mở bước $step';
  }

  @override
  String get attendanceTitle => 'Điểm danh';

  @override
  String get attendanceStatusPresent => 'Có mặt';

  @override
  String get attendanceStatusLate => 'Đi muộn';

  @override
  String get attendanceStatusExcused => 'Vắng có phép';

  @override
  String get attendanceStatusUnexcused => 'Vắng không phép';

  @override
  String attendanceStudentSemantics(String name, String status) {
    return '$name, $status. Chạm để đổi trạng thái';
  }

  @override
  String get attendanceSave => 'Lưu';

  @override
  String get attendanceSaving => 'Đang lưu…';

  @override
  String get attendanceSaveFailed => 'Chưa lưu được. Thử lại.';

  @override
  String get attendanceLoadFailed => 'Không tải được danh sách học viên.';

  @override
  String get attendanceRetry => 'Thử lại';

  @override
  String get attendanceEmptyRoster => 'Lớp này chưa có học viên.';

  @override
  String get attendanceReadOnlyCancelled => 'Buổi này đã hủy nên chỉ xem được.';

  @override
  String get attendanceReadOnlyWindow =>
      'Buổi này quá 7 ngày nên chỉ xem, không sửa được.';

  @override
  String get attendanceOfflineNotice =>
      'Đang ngoại tuyến. Thay đổi lưu trên máy và gửi khi có mạng.';

  @override
  String get attendanceNoteLabel => 'Ghi chú';

  @override
  String attendanceNoteToggle(String name) {
    return 'Ghi chú cho $name';
  }

  @override
  String get attendanceRejectedWindow =>
      'Đã quá hạn sửa 7 ngày nên thay đổi này không được nhận.';

  @override
  String get attendanceRejectedPlan =>
      'Gói hiện tại chỉ cho xem nên thay đổi này không được nhận.';

  @override
  String get attendanceRejectedNotFound =>
      'Học viên không còn trong buổi này nên thay đổi không được nhận.';

  @override
  String get attendanceRejectedGeneric => 'Thay đổi này không được nhận.';

  @override
  String get attendanceBatchNotFound =>
      'Buổi này không còn tồn tại nên chưa gửi được điểm danh.';

  @override
  String get attendanceBatchCancelled =>
      'Buổi này đã hủy nên chưa gửi được điểm danh.';

  @override
  String get attendanceBatchGeneric => 'Chưa gửi được điểm danh của buổi này.';

  @override
  String get attendanceDiscard => 'Bỏ thay đổi bị từ chối';

  @override
  String get attendanceHistory => 'Nhật ký sửa';

  @override
  String get historyTitle => 'Nhật ký sửa';

  @override
  String get historyEmpty => 'Buổi này chưa có lần sửa nào.';

  @override
  String get historyLoadFailed => 'Không tải được nhật ký.';

  @override
  String get historyLoadMore => 'Xem thêm';

  @override
  String historyChangedBy(String who, String time) {
    return '$who · $time';
  }

  @override
  String get historyUnknownUser => 'Không rõ người sửa';

  @override
  String get historyFirst => 'Điểm danh lần đầu';

  @override
  String historyNote(String note) {
    return 'Ghi chú: $note';
  }

  @override
  String get historyNoNote => 'không có ghi chú';

  @override
  String get contactsAdd => 'Thêm từ danh bạ';

  @override
  String get contactsTitle => 'Thêm từ danh bạ';

  @override
  String get contactsDeniedTitle => 'Chưa có quyền đọc danh bạ';

  @override
  String get contactsDeniedBody =>
      'DayHoc chỉ đọc danh bạ khi bạn bấm Thêm từ danh bạ, để chọn học viên và số của phụ huynh. Bạn vẫn có thể nhập từng học viên bằng tay.';

  @override
  String get contactsAllow => 'Cho phép lại';

  @override
  String get contactsOpenSettings => 'Mở Cài đặt';

  @override
  String get contactsManual => 'Nhập tay';

  @override
  String get contactsLoadFailed => 'Không đọc được danh bạ. Thử lại sau.';

  @override
  String get contactsEmpty => 'Danh bạ chưa có liên hệ nào.';

  @override
  String get contactsNoPhone => 'Chưa có số điện thoại';

  @override
  String contactsContinue(int n) {
    return 'Tiếp tục ($n)';
  }

  @override
  String contactsSaveAll(int n) {
    return 'Lưu $n học viên';
  }

  @override
  String get contactsDone => 'Xong';

  @override
  String get contactsBack => 'Chọn lại';

  @override
  String contactsRemoveRow(String name) {
    return 'Bỏ $name';
  }

  @override
  String get contactsReviewHint =>
      'Họ tên liên hệ thành họ tên học viên, số điện thoại thành số của phụ huynh 1. Sửa hoặc bỏ từng dòng trước khi lưu.';

  @override
  String get contactsRowSaved => 'Đã lưu';

  @override
  String get contactsRowSaving => 'Đang lưu…';

  @override
  String get contactsRowFailed => 'Chưa lưu được';

  @override
  String get contactsRowDuplicate => 'Có thể trùng hồ sơ';

  @override
  String get contactsRowReview => 'Xem hồ sơ trùng';

  @override
  String get todayScheduleEntry => 'Lịch';

  @override
  String get scheduleTitle => 'Lịch';

  @override
  String get scheduleModeDay => 'Ngày';

  @override
  String get scheduleModeWeek => 'Tuần';

  @override
  String get schedulePrevious => 'Trước';

  @override
  String get scheduleNext => 'Sau';

  @override
  String get scheduleToday => 'Hôm nay';

  @override
  String scheduleDayHeading(String weekday, String date) {
    return '$weekday, $date';
  }

  @override
  String scheduleWeekRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get scheduleOfflineBanner =>
      'Đang ngoại tuyến. Lịch hiển thị là bản đã lưu gần nhất.';

  @override
  String get scheduleEmpty => 'Không có buổi nào trong khoảng này';

  @override
  String get scheduleLoadFailed => 'Chưa tải được lịch.';

  @override
  String get scheduleRetry => 'Thử lại';

  @override
  String get scheduleCancelled => 'Đã hủy';

  @override
  String get scheduleMakeup => 'Buổi bù';

  @override
  String scheduleCancelReason(String reason) {
    return 'Lý do: $reason';
  }

  @override
  String get studentsEditTitle => 'Sửa học viên';

  @override
  String get studentsGuardianRelation => 'Quan hệ';

  @override
  String get studentsRelationFather => 'Bố';

  @override
  String get studentsRelationMother => 'Mẹ';

  @override
  String get studentsRelationGuardian => 'Người giám hộ';

  @override
  String get inviteStatusNotInvited => 'Chưa mời';

  @override
  String get inviteStatusInvited => 'Đã mời';

  @override
  String get inviteStatusActivated => 'Đã kích hoạt';

  @override
  String get inviteStatusExpired => 'Hết hạn';

  @override
  String get inviteShare => 'Chia sẻ link';

  @override
  String get inviteResend => 'Gửi lại link';

  @override
  String get rosterNoGuardians => 'Chưa có phụ huynh. Chạm tên em để thêm.';

  @override
  String rosterGuardianLine(String relation, String name) {
    return '$relation: $name';
  }

  @override
  String rosterGuardianSemantics(String who, String status) {
    return '$who, $status';
  }

  @override
  String rosterEditSemantics(String name) {
    return 'Sửa học viên $name';
  }

  @override
  String inviteSheetFor(String guardian, String student) {
    return 'Mời $guardian, phụ huynh của $student';
  }

  @override
  String get inviteQrLabel => 'Mã QR lời mời';

  @override
  String get inviteCodeLabel => 'Mã nhập tay';

  @override
  String inviteCodeSemantics(String code) {
    return 'Mã mời: $code';
  }

  @override
  String get inviteExpiryNote =>
      'Link dùng được 7 ngày, mã nhập tay dùng được 48 giờ.';

  @override
  String get inviteOldLinkNote =>
      'Link cũ của phụ huynh này (nếu có) không dùng được nữa.';

  @override
  String inviteShareMessage(
    String guardian,
    String student,
    String url,
    String code,
  ) {
    return 'Chào $guardian, mình mời bạn theo dõi việc học của $student trên DayHoc.\nMở link để nhận lời mời: $url\nHoặc nhập mã $code trong ứng dụng DayHoc (mã dùng được 48 giờ).';
  }

  @override
  String get inviteAllEntry => 'Mời tất cả phụ huynh chưa kích hoạt';

  @override
  String get inviteAllTitle => 'Mời phụ huynh của lớp';

  @override
  String get inviteAllEmpty => 'Không còn phụ huynh nào cần mời.';

  @override
  String inviteAllProgress(int done, int total) {
    return 'Đã tạo $done/$total link';
  }

  @override
  String get inviteAllHint =>
      'Bấm Chia sẻ để gửi lần lượt cho từng phụ huynh. Phụ huynh đang có lời mời còn hạn được bỏ qua.';

  @override
  String get inviteAllPausedNetwork =>
      'Đã dừng vì lỗi mạng liên tiếp. Kiểm tra kết nối rồi bấm Tiếp tục.';

  @override
  String inviteAllPausedRate(int seconds) {
    return 'Đã dừng vì gửi quá nhiều yêu cầu. Chờ khoảng $seconds giây rồi bấm Tiếp tục.';
  }

  @override
  String get inviteAllPausedRateNoWait =>
      'Đã dừng vì gửi quá nhiều yêu cầu. Chờ một lát rồi bấm Tiếp tục.';

  @override
  String get inviteAllResume => 'Tiếp tục';

  @override
  String get inviteAllWaiting => 'Chưa tạo';

  @override
  String get inviteAllCreating => 'Đang tạo link…';

  @override
  String get inviteAllShareAgain => 'Chia sẻ lại';

  @override
  String get inviteAllShowQr => 'Xem mã QR';

  @override
  String get inviteAllSharedMark => 'Đã mở chia sẻ';

  @override
  String get sessionActionReschedule => 'Đổi giờ';

  @override
  String get sessionActionCancel => 'Hủy buổi';

  @override
  String get sessionActionMakeup => 'Tạo buổi bù';

  @override
  String get sessionRescheduleTitle => 'Đổi giờ buổi học';

  @override
  String get sessionCancelTitle => 'Hủy buổi học?';

  @override
  String get sessionCancelBody =>
      'Phụ huynh của lớp sẽ nhận thông báo buổi này đã hủy.';

  @override
  String get sessionMakeupTitle => 'Tạo buổi bù';

  @override
  String get sessionPickDate => 'Ngày';

  @override
  String get sessionPickTime => 'Giờ bắt đầu';

  @override
  String get sessionReasonLabel => 'Lý do (không bắt buộc)';

  @override
  String get sessionConfirmReschedule => 'Đổi giờ';

  @override
  String get sessionConfirmCancel => 'Hủy buổi';

  @override
  String get sessionConfirmMakeup => 'Tạo buổi bù';

  @override
  String get sessionClose => 'Đóng';

  @override
  String get sessionErrPast => 'Giờ mới phải ở tương lai.';

  @override
  String get sessionErrCancelled => 'Buổi này đã hủy nên không đổi giờ được.';

  @override
  String get sessionHasAttendanceTitle => 'Buổi đã có điểm danh';

  @override
  String get sessionHasAttendanceBody =>
      'Buổi này đã có điểm danh nên chưa hủy được. Mở bảng điểm danh để sửa lại, rồi hủy buổi sau.';

  @override
  String get sessionOpenAttendance => 'Mở điểm danh';

  @override
  String get sessionDoneRescheduled => 'Đã đổi giờ buổi học.';

  @override
  String get sessionDoneCancelled => 'Đã hủy buổi học.';

  @override
  String get sessionDoneMakeup => 'Đã tạo buổi bù.';

  @override
  String sessionActionsLabel(String date, String start) {
    return 'Thao tác buổi $date lúc $start';
  }

  @override
  String sessionCancelReasonLine(String reason) {
    return 'Lý do hủy: $reason';
  }

  @override
  String get todaySettings => 'Cài đặt và tài khoản';

  @override
  String get classesFeeSection => 'Học phí';

  @override
  String get classesFeeEnabled => 'Thu học phí';

  @override
  String get classesFeeTypeLabel => 'Cách tính';

  @override
  String get feeTypePerSession => 'Theo buổi';

  @override
  String get feeTypeMonthly => 'Theo tháng';

  @override
  String get feeTypeCourse => 'Trọn khóa';

  @override
  String get classesFeeAmountPerSession => 'Đơn giá mỗi buổi';

  @override
  String get classesFeeAmountMonthly => 'Học phí mỗi tháng';

  @override
  String get classesFeeAmountCourse => 'Tổng học phí cả khóa';

  @override
  String get classesFeeChargeExcused => 'Tính tiền buổi vắng có phép';

  @override
  String get classesFeeChargeUnexcused => 'Tính tiền buổi vắng không phép';

  @override
  String get classesFeeDeductCancelled => 'Trừ tiền buổi giáo viên hủy';

  @override
  String get classesFeeInstallments => 'Số đợt thu (1–36)';

  @override
  String get classesFeeNote =>
      'Đổi học phí chỉ áp dụng từ kỳ thu chưa chốt tiếp theo.';

  @override
  String get classesErrFeeAmountRequired => 'Nhập số tiền.';

  @override
  String get classesErrFeeAmountRange => 'Số tiền từ 1 đ đến 1.000.000.000 đ.';

  @override
  String get classesErrFeeInstallments =>
      'Số đợt từ 1 đến 36, chỉ dùng cho trọn khóa.';

  @override
  String get feesErrRateLimited =>
      'Bạn thao tác hơi nhanh. Chờ một lúc rồi thử lại.';

  @override
  String get rosterFeeOverrideBadge => 'Giá riêng';

  @override
  String get rosterFeeOverrideAction => 'Giá riêng cho học viên';

  @override
  String get feeOverrideTitle => 'Giá riêng';

  @override
  String feeOverrideFor(String name) {
    return 'Giá riêng của $name';
  }

  @override
  String get feeOverrideHint =>
      'Để trống mục nào thì mục đó theo cấu hình lớp.';

  @override
  String get feeOverrideAmount => 'Giá riêng';

  @override
  String get feeOverrideRulesTitle => 'Quy tắc vắng riêng';

  @override
  String get feeOverrideInherit => 'Theo lớp';

  @override
  String get feeOverrideYes => 'Tính';

  @override
  String get feeOverrideNo => 'Không tính';

  @override
  String get feeOverrideInstallments => 'Số đợt riêng (1–36)';

  @override
  String get feeOverrideDiscounts => 'Miễn giảm';

  @override
  String get feeOverrideAddDiscount => 'Thêm khoản miễn giảm';

  @override
  String get feeOverrideDiscountDesc => 'Mô tả';

  @override
  String get feeOverrideDiscountPercent => 'Theo %';

  @override
  String get feeOverrideDiscountAmount => 'Theo số tiền';

  @override
  String get feeOverrideDiscountPercentValue => 'Phần trăm (1–100)';

  @override
  String get feeOverrideDiscountAmountValue => 'Số tiền';

  @override
  String get feeOverrideRemoveDiscount => 'Xóa khoản miễn giảm';

  @override
  String get feeOverrideSave => 'Lưu giá riêng';

  @override
  String get feeOverrideClear => 'Xóa giá riêng';

  @override
  String get feeOverrideSaved => 'Đã lưu giá riêng.';

  @override
  String get feeOverrideCleared => 'Đã xóa giá riêng.';

  @override
  String get feeOverrideErrAmount => 'Số tiền không hợp lệ.';

  @override
  String get feeOverrideErrInstallments => 'Số đợt từ 1 đến 36.';

  @override
  String get feeOverrideErrDiscountDesc => 'Nhập mô tả, tối đa 100 ký tự.';

  @override
  String get feeOverrideErrDiscountValue => 'Giá trị không hợp lệ.';

  @override
  String get payoutTitle => 'Tài khoản nhận tiền';

  @override
  String get payoutEmpty => 'Chưa có tài khoản nhận tiền';

  @override
  String get payoutEmptyBody =>
      'Thêm tài khoản để phụ huynh biết chuyển học phí về đâu.';

  @override
  String get payoutAdd => 'Thêm tài khoản';

  @override
  String get payoutLimit => 'Tối đa 5 tài khoản.';

  @override
  String get payoutPrimaryBadge => 'Chính';

  @override
  String get payoutSetPrimary => 'Đặt làm chính';

  @override
  String get payoutEdit => 'Sửa';

  @override
  String get payoutDelete => 'Xóa';

  @override
  String get payoutCancel => 'Hủy';

  @override
  String get payoutDeleteTitle => 'Xóa tài khoản này?';

  @override
  String get payoutDeleteBody => 'Tài khoản sẽ bị gỡ khỏi danh sách nhận tiền.';

  @override
  String payoutLine(String bank, String masked) {
    return '$bank · $masked';
  }

  @override
  String payoutUnknownBank(String bin) {
    return 'Ngân hàng $bin';
  }

  @override
  String payoutSemantics(String name, String line) {
    return '$name, $line';
  }

  @override
  String payoutActionsSemantics(String name) {
    return 'Tác vụ cho tài khoản $name';
  }

  @override
  String get payoutContinue => 'Tiếp tục';

  @override
  String get payoutSaved => 'Đã lưu tài khoản.';

  @override
  String get payoutDeleted => 'Đã xóa tài khoản.';

  @override
  String get payoutPrimarySet => 'Đã đặt làm tài khoản chính.';

  @override
  String get payoutFormNewTitle => 'Thêm tài khoản';

  @override
  String get payoutFormEditTitle => 'Sửa tài khoản';

  @override
  String get payoutFieldBank => 'Ngân hàng';

  @override
  String get payoutPickBank => 'Chọn ngân hàng';

  @override
  String get payoutFieldAccountNo => 'Số tài khoản';

  @override
  String get payoutFieldAccountNoEditHint => 'Để trống nếu không đổi số';

  @override
  String get payoutFieldName => 'Tên chủ tài khoản';

  @override
  String get payoutFieldNameHint => 'Viết đúng như ngân hàng ghi';

  @override
  String get payoutOtpNeeded =>
      'Thêm tài khoản hoặc đổi ngân hàng, số tài khoản cần mã xác thực gửi qua email.';

  @override
  String get payoutSendCode => 'Gửi mã xác thực';

  @override
  String get payoutSave => 'Lưu';

  @override
  String get payoutOtpSent => 'Đã gửi mã tới email của bạn.';

  @override
  String get payoutOtpField => 'Mã xác thực (6 số)';

  @override
  String get payoutOtpConfirm => 'Xác nhận và lưu';

  @override
  String get payoutOtpResend => 'Gửi lại mã';

  @override
  String get payoutOtpBack => 'Sửa thông tin';

  @override
  String get payoutErrOtpInvalid =>
      'Mã chưa đúng. Kiểm tra lại mã trong email.';

  @override
  String get payoutErrOtpLocked =>
      'Bạn nhập sai quá nhiều lần. Vui lòng thử lại sau.';

  @override
  String get payoutErrMissing =>
      'Bạn chưa có tài khoản nhận tiền. Thêm tài khoản trước khi gửi hóa đơn.';

  @override
  String get payoutErrBank => 'Chọn ngân hàng.';

  @override
  String get payoutErrRequired => 'Không được để trống.';

  @override
  String get payoutErrAccountNo => 'Số tài khoản gồm 6 đến 19 chữ số.';

  @override
  String get payoutErrName => 'Tên tối đa 50 ký tự.';

  @override
  String get payoutLoadFailed => 'Không tải được danh sách tài khoản.';

  @override
  String get onboardingPayoutIntro =>
      'Thêm ít nhất một tài khoản để nhận học phí.';
}
