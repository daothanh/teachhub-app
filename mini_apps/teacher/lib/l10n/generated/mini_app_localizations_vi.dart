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
  String get classesErrFeeCourseSchedule =>
      'Trọn khóa cần có ngày kết thúc và ít nhất một lịch học hằng tuần.';

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
  String get payoutDeleteLastBody =>
      'Đây là tài khoản nhận tiền duy nhất. Xóa xong, bạn sẽ chưa chốt được kỳ học phí cho đến khi thêm tài khoản mới.';

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

  @override
  String get todayBillingEntry => 'Học phí kỳ thu';

  @override
  String get billingTitle => 'Học phí kỳ thu';

  @override
  String get billingPeriodsEmpty => 'Chưa có kỳ thu nào';

  @override
  String get billingPeriodsEmptyBody =>
      'Đến ngày chốt, app tự tạo bản nháp hóa đơn của tháng để bạn kiểm tra trước khi gửi.';

  @override
  String get billingLoadFailed => 'Không tải được dữ liệu học phí.';

  @override
  String billingPeriodMonth(int month, int year) {
    return 'Tháng $month/$year';
  }

  @override
  String billingPeriodDates(String close, String due) {
    return 'Chốt $close · Hạn $due';
  }

  @override
  String get billingPeriodDrafting => 'Đang soạn';

  @override
  String get billingPeriodClosed => 'Đã chốt hết';

  @override
  String billingDraftSummary(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bản nháp',
    );
    return '$_temp0 · $amount';
  }

  @override
  String billingIssuedSummary(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã gửi $count hóa đơn',
    );
    return '$_temp0 · $amount';
  }

  @override
  String billingVoidSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hóa đơn đã hủy',
    );
    return '$_temp0';
  }

  @override
  String get billingIssueAll => 'Chốt & gửi tất cả';

  @override
  String get billingIssueOne => 'Chốt & gửi';

  @override
  String get billingIssueConfirmTitle => 'Gửi hóa đơn cho phụ huynh?';

  @override
  String billingIssueAllConfirmBody(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hóa đơn',
    );
    return 'Chốt $_temp0, tổng $amount. Phụ huynh nhận thông báo ngay và hóa đơn không sửa được sau khi gửi.';
  }

  @override
  String get billingIssueZeroConfirmBody =>
      'Chốt các bản nháp 0 đ. Bản nháp không có khoản phát sinh được giữ lại; bản nháp mà tiền trả thừa trả đủ sẽ được chốt và ghi là đã trừ vào số dư.';

  @override
  String billingIssueOneConfirmBody(String student, String amount) {
    return 'Chốt hóa đơn của $student, $amount. Phụ huynh nhận thông báo ngay và hóa đơn không sửa được sau khi gửi.';
  }

  @override
  String billingIssued(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hóa đơn',
    );
    return 'Đã gửi $_temp0.';
  }

  @override
  String get billingIssuedNone => 'Không có hóa đơn nào cần gửi.';

  @override
  String billingIssuedSkippedZero(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hóa đơn',
    );
    return '$_temp0 0 đ không gửi.';
  }

  @override
  String get billingNoPayableDrafts => 'Không còn bản nháp nào có tiền để gửi.';

  @override
  String billingZeroDraftNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hóa đơn',
    );
    return '$_temp0 0 đ: nếu không có khoản phát sinh thì sẽ không được gửi.';
  }

  @override
  String get billingInvoicesEmpty => 'Kỳ này chưa có hóa đơn.';

  @override
  String get billingNoSend => 'Không gửi';

  @override
  String get billingHasOverride => 'Giá riêng';

  @override
  String get billingStatusDraft => 'Bản nháp';

  @override
  String get billingStatusIssued => 'Đã phát hành';

  @override
  String get billingStatusPending => 'Chờ xác nhận';

  @override
  String get billingStatusPartial => 'Đã thanh toán một phần';

  @override
  String get billingStatusPaid => 'Đã thanh toán';

  @override
  String get billingStatusVoid => 'Đã hủy';

  @override
  String get billingInvoiceTitle => 'Hóa đơn';

  @override
  String get billingLinesSessions => 'Các buổi học';

  @override
  String get billingLinesOther => 'Khoản khác';

  @override
  String billingSessionLine(String date, String className) {
    return '$date · $className';
  }

  @override
  String get billingSessionCharged => 'Tính tiền';

  @override
  String billingSessionNotCharged(String reason) {
    return 'Không tính: $reason';
  }

  @override
  String get billingReasonExcused => 'vắng có phép';

  @override
  String get billingReasonUnexcused => 'vắng không phép';

  @override
  String get billingReasonCancelled => 'buổi bị hủy';

  @override
  String get billingReasonMakeup => 'buổi dạy bù';

  @override
  String get billingReasonOther => 'theo quy tắc của lớp';

  @override
  String billingAdjustmentReasonLine(String reason) {
    return 'Lý do: $reason';
  }

  @override
  String get billingTotal => 'Tổng cộng';

  @override
  String billingClamped(String amount) {
    return 'Điều chỉnh làm tổng âm nên tổng được giữ ở 0 đ; phần âm $amount sẽ được trừ vào kỳ sau.';
  }

  @override
  String get billingCarryTitle => 'Số dư kỳ trước';

  @override
  String get billingCarryDebt => 'Nợ kỳ trước';

  @override
  String get billingCarryCredit => 'Trừ tiền trả thừa';

  @override
  String get billingPrevAdjustment => 'Điều chỉnh kỳ trước';

  @override
  String get billingCarryPreviewNote =>
      'Số này tính theo hiện tại, có thể thay đổi khi chốt.';

  @override
  String get billingDraftPreviewNote =>
      'Tổng mỗi bản nháp đã gồm nợ kỳ trước hoặc tiền trả thừa nếu có, có thể thay đổi khi chốt.';

  @override
  String billingIssuedTotal(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hóa đơn',
    );
    return 'Đã gửi $_temp0, tổng $amount.';
  }

  @override
  String billingIssuedCovered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hóa đơn',
    );
    return '$_temp0 đã trừ vào số dư, không cần thu.';
  }

  @override
  String get billingCoveredByBalance => 'Đã trừ vào số dư';

  @override
  String get billingCoveredByBalanceHint =>
      'Tiền trả thừa của học viên đã đủ trả kỳ này nên không cần thu thêm.';

  @override
  String billingCarriedAmount(String amount) {
    return 'Đã chuyển $amount sang kỳ sau';
  }

  @override
  String get billingCarriedHint =>
      'Khoản này đã nằm ở hóa đơn kỳ sau, hãy thu ở đó.';

  @override
  String get billingAddAdjustment => 'Thêm điều chỉnh';

  @override
  String get billingAdjustTitle => 'Điều chỉnh hóa đơn';

  @override
  String get billingAdjustHint =>
      'Dòng điều chỉnh chưa xóa được. Nhập sai thì thêm một dòng ngược dấu.';

  @override
  String get billingAdjustDecrease => 'Giảm trừ';

  @override
  String get billingAdjustIncrease => 'Phụ thu';

  @override
  String get billingAdjustAmount => 'Số tiền';

  @override
  String get billingAdjustDescription => 'Mô tả';

  @override
  String get billingAdjustReason => 'Lý do (bắt buộc)';

  @override
  String get billingAdjustSave => 'Lưu điều chỉnh';

  @override
  String get billingAdjusted => 'Đã thêm điều chỉnh.';

  @override
  String get billingErrAmount =>
      'Nhập số tiền lớn hơn 0 và không quá 1.000.000.000 đ.';

  @override
  String get billingErrDescription => 'Nhập mô tả, tối đa 200 ký tự.';

  @override
  String get billingErrReason => 'Nhập lý do, tối đa 300 ký tự.';

  @override
  String get billingErrImmutable =>
      'Hóa đơn đã phát hành nên không sửa được. Hãy hủy rồi tạo hóa đơn thay thế.';

  @override
  String get billingErrStaleUnverified =>
      'Chưa xác nhận được kết quả. Kéo để tải lại rồi kiểm tra trước khi chốt tiếp.';

  @override
  String get billingErrStale =>
      'Hóa đơn vừa có thay đổi, đã cập nhật trạng thái mới nhất. Kiểm tra lại rồi thử lần nữa.';

  @override
  String get billingVoid => 'Hủy hóa đơn';

  @override
  String get billingVoidTitle => 'Hủy hóa đơn này?';

  @override
  String get billingVoidBody =>
      'Phụ huynh sẽ không còn thấy mã QR của hóa đơn. Cần ghi lý do hủy.';

  @override
  String get billingVoidReason => 'Lý do hủy';

  @override
  String get billingVoidKeep => 'Giữ lại';

  @override
  String get billingVoidConfirm => 'Hủy hóa đơn';

  @override
  String get billingVoided => 'Đã hủy hóa đơn.';

  @override
  String billingVoidedBanner(String reason) {
    return 'Hóa đơn đã hủy. Lý do: $reason';
  }

  @override
  String get billingPayoutMissingTitle => 'Chưa có tài khoản nhận tiền';

  @override
  String get billingPayoutMissingBody =>
      'Thêm tài khoản nhận tiền để phụ huynh biết chuyển học phí về đâu. Thêm xong, quay lại đây để chốt tiếp.';

  @override
  String get billingPayoutMissingAction => 'Thêm tài khoản';

  @override
  String get payoutOtpActionTitle => 'Xác thực để tiếp tục';

  @override
  String get payoutOtpActionBody =>
      'Đổi hoặc xóa tài khoản nhận tiền chính cần mã xác thực. Mã đã gửi tới email của bạn.';

  @override
  String get payoutOtpActionConfirm => 'Xác nhận';

  @override
  String get billingIssueAllConfirmAction => 'Gửi tất cả';

  @override
  String get billingPaidAmount => 'Đã thu';

  @override
  String get billingRemainingAmount => 'Còn nợ';

  @override
  String get billingPayRecord => 'Thu tiền';

  @override
  String get billingPayFull => 'Đã thu đủ';

  @override
  String get billingPayPartial => 'Thu một phần';

  @override
  String get billingPayFullTitle => 'Ghi nhận đã thu đủ';

  @override
  String get billingPayPartialTitle => 'Ghi nhận thu một phần';

  @override
  String get billingPayAmount => 'Số tiền thu';

  @override
  String get billingPayMethod => 'Hình thức thu';

  @override
  String get billingPayMethodBank => 'Chuyển khoản';

  @override
  String get billingPayMethodCash => 'Tiền mặt';

  @override
  String get billingPayDate => 'Ngày thu';

  @override
  String get billingPayConfirm => 'Xác nhận đã thu';

  @override
  String get billingPayOverHint =>
      'Số tiền lớn hơn số còn nợ. Phần dư được ghi lại để trừ vào kỳ sau.';

  @override
  String get billingErrPayAmount =>
      'Nhập số tiền thu lớn hơn 0 và không quá 100.000.000.000 đ.';

  @override
  String get billingErrPayDate => 'Ngày thu không hợp lệ hoặc sau hôm nay.';

  @override
  String get billingErrNotPayable =>
      'Hóa đơn này không ghi thanh toán được nữa (đã thu đủ, đã hủy hoặc chưa phát hành). Đã cập nhật trạng thái mới nhất.';

  @override
  String get billingPaymentRecorded => 'Đã ghi nhận thanh toán.';

  @override
  String get billingPaymentsTitle => 'Các lần thu';

  @override
  String billingPaymentLine(String method, String date) {
    return '$method · $date';
  }

  @override
  String billingPaymentBy(String name, String when) {
    return 'Ghi bởi $name lúc $when';
  }

  @override
  String billingPaymentAt(String when) {
    return 'Ghi lúc $when';
  }

  @override
  String get billingPaymentVoidedLabel => 'Đã hủy';

  @override
  String billingPaymentVoidedBy(String name, String reason) {
    return 'Hủy bởi $name. Lý do: $reason';
  }

  @override
  String billingPaymentVoidedReason(String reason) {
    return 'Lý do hủy: $reason';
  }

  @override
  String get billingPaymentVoidAction => 'Hủy thanh toán';

  @override
  String get billingPaymentVoidTitle => 'Hủy thanh toán này?';

  @override
  String billingPaymentVoidBody(String amount) {
    return 'Khoản thu $amount sẽ không còn tính vào hóa đơn. Cần ghi lý do hủy.';
  }

  @override
  String get billingPaymentVoidDone => 'Đã hủy thanh toán.';

  @override
  String get billingPayNote => 'Ghi chú (chỉ bạn thấy)';

  @override
  String get billingErrPayNote => 'Ghi chú tối đa 300 ký tự.';

  @override
  String billingPayRemainingChanged(String amount) {
    return 'Số còn nợ vừa thay đổi, hiện là $amount. Kiểm tra lại rồi xác nhận.';
  }

  @override
  String get billingErrPayDateVn =>
      'Ngày thu không hợp lệ theo giờ Việt Nam (không được sau hôm nay). Kiểm tra ngày trên máy.';

  @override
  String get billingNoReason => 'Không ghi lý do';

  @override
  String get receivablesTitle => 'Công nợ';

  @override
  String get receivablesSearchHint => 'Tìm theo tên học viên';

  @override
  String receivablesTotalOwed(String amount) {
    return 'Tổng còn nợ $amount';
  }

  @override
  String get receivablesBucketAll => 'Tất cả';

  @override
  String get receivablesBucket030 => '0–30 ngày';

  @override
  String get receivablesBucket3160 => '31–60 ngày';

  @override
  String get receivablesBucketOver60 => 'Trên 60 ngày';

  @override
  String receivablesBucketChip(String name, String amount) {
    return '$name · $amount';
  }

  @override
  String get receivablesSortDesc => 'Nợ nhiều trước';

  @override
  String get receivablesSortAsc => 'Nợ ít trước';

  @override
  String receivablesRowOwed(String amount) {
    return 'Còn nợ $amount';
  }

  @override
  String receivablesInvoiceOutstanding(String amount) {
    return 'Hóa đơn còn nợ: $amount';
  }

  @override
  String receivablesLedgerDebt(String amount) {
    return 'Nợ ở sổ: $amount';
  }

  @override
  String receivablesLedgerCredit(String amount) {
    return 'Trả thừa: $amount';
  }

  @override
  String get receivablesNetHint =>
      'Nợ ròng đã trừ tiền trả thừa hoặc cộng nợ ở sổ, không đếm hai lần phần đã chuyển sang kỳ sau.';

  @override
  String receivablesRowMeta(String classes, int invoices) {
    String _temp0 = intl.Intl.pluralLogic(
      invoices,
      locale: localeName,
      other: '$invoices hóa đơn',
    );
    return '$classes · $_temp0';
  }

  @override
  String receivablesOverdue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Quá hạn $days ngày',
      zero: 'Chưa quá hạn',
    );
    return '$_temp0';
  }

  @override
  String get receivablesEmpty => 'Không ai còn nợ';

  @override
  String get receivablesEmptyBody =>
      'Mọi hóa đơn đã phát hành đều được thu đủ.';

  @override
  String get receivablesEmptyFiltered => 'Không có học viên nào khớp bộ lọc.';

  @override
  String get receivablesLoadFailed => 'Không tải được công nợ.';

  @override
  String get receivablesMoreFailed => 'Không tải thêm được.';

  @override
  String get receivablesDunningSettings => 'Cài đặt nhắc nợ';

  @override
  String get receivablesDetailTitle => 'Công nợ học viên';

  @override
  String get receivablesInvoices => 'Hóa đơn';

  @override
  String get receivablesPayments => 'Thanh toán';

  @override
  String get receivablesReminders => 'Nhắc nợ';

  @override
  String get receivablesNoInvoices => 'Chưa có hóa đơn.';

  @override
  String get receivablesNoPayments => 'Chưa có thanh toán.';

  @override
  String get receivablesNoReminders => 'Chưa có lần nhắc nào.';

  @override
  String receivablesInvoiceTitle(String code, int month, int year) {
    return '$code · $month/$year';
  }

  @override
  String receivablesInvoiceDue(String date) {
    return 'Hạn $date';
  }

  @override
  String receivablesInvoiceRemaining(String remaining, String total) {
    return 'Còn $remaining / $total';
  }

  @override
  String receivablesPaymentLine(String amount, String method) {
    return '$amount · $method';
  }

  @override
  String receivablesPaymentDate(String date) {
    return 'Ngày thu $date';
  }

  @override
  String get receivablesPaymentVoided => 'Đã hủy';

  @override
  String receivablesReminderLine(String label, String code) {
    return '$label · hóa đơn $code';
  }

  @override
  String get receivablesNoCode => 'chưa có mã';

  @override
  String dunningOffsetBefore(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days ngày',
    );
    return 'Trước hạn $_temp0';
  }

  @override
  String get dunningOffsetOn => 'Đúng hạn';

  @override
  String dunningOffsetAfter(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days ngày',
    );
    return 'Sau hạn $_temp0';
  }

  @override
  String dunningStepSent(String time) {
    return 'Đã gửi $time';
  }

  @override
  String dunningStepPending(String time) {
    return 'Chờ gửi $time';
  }

  @override
  String get dunningStepCancelled => 'Đã hủy';

  @override
  String get dunningStudentTitle => 'Nhắc nợ';

  @override
  String get dunningStudentOn => 'Đang bật nhắc nợ';

  @override
  String get dunningStudentOff => 'Đang tắt nhắc nợ';

  @override
  String get dunningStudentHint =>
      'Học viên chỉ không nhận nhắc nợ khi mọi lớp đang học đều tắt.';

  @override
  String dunningClassSwitch(String className) {
    return 'Nhắc nợ lớp $className';
  }

  @override
  String get dunningToggledOn => 'Đã bật nhắc nợ.';

  @override
  String get dunningToggledOff => 'Đã tắt nhắc nợ.';

  @override
  String get rosterDunningAction => 'Nhắc nợ';

  @override
  String rosterDunningTitle(String student) {
    return 'Nhắc nợ của $student';
  }

  @override
  String get invoiceDunningTitle => 'Nhắc nợ';

  @override
  String invoiceDunningLastSent(String time) {
    return 'Đã nhắc lúc $time';
  }

  @override
  String get invoiceDunningNone => 'Chưa nhắc lần nào.';

  @override
  String invoiceDunningNext(String time) {
    return 'Lần nhắc tới: $time';
  }

  @override
  String get dunningReasonTenant => 'Bạn đang tắt nhắc nợ trong cài đặt chung.';

  @override
  String get dunningReasonStudent => 'Đã tắt nhắc nợ cho học viên này.';

  @override
  String get dunningReasonPaid => 'Hóa đơn đã thu đủ, không nhắc nữa.';

  @override
  String get dunningReasonVoid => 'Hóa đơn đã hủy, không nhắc nữa.';

  @override
  String get dunningLoadFailed => 'Không tải được trạng thái nhắc nợ.';

  @override
  String get dunningSettingsTitle => 'Cài đặt nhắc nợ';

  @override
  String get dunningSettingsEnabled => 'Tự động nhắc nợ';

  @override
  String get dunningSettingsEnabledHint =>
      'Nhắc phụ huynh khi hóa đơn gần hoặc quá hạn. Tin gửi trong khung 07:00 đến 21:30.';

  @override
  String get dunningSettingsOffsets => 'Mốc nhắc';

  @override
  String get dunningSettingsOffsetsHint =>
      'Số ngày so với hạn thanh toán. Đổi mốc chỉ áp dụng cho hóa đơn gửi sau khi lưu.';

  @override
  String get dunningOffsetInput => 'Thêm mốc (ngày so với hạn)';

  @override
  String get dunningOffsetAdd => 'Thêm';

  @override
  String get dunningOffsetReset => 'Đặt lại mặc định';

  @override
  String get dunningOffsetPreview => 'Xem trước';

  @override
  String get dunningOffsetRemove => 'Xóa mốc';

  @override
  String get dunningOffsetErrNumber => 'Nhập một số nguyên.';

  @override
  String get dunningOffsetErrRange => 'Mốc từ −7 đến 30 ngày.';

  @override
  String get dunningOffsetErrDuplicate => 'Mốc này đã có.';

  @override
  String get dunningOffsetErrTooMany => 'Tối đa 6 mốc.';

  @override
  String get dunningOffsetErrTooFew => 'Cần ít nhất một mốc.';

  @override
  String get dunningSave => 'Lưu';

  @override
  String get dunningSaved => 'Đã lưu cài đặt nhắc nợ.';

  @override
  String get dunningPreviewTitle => 'Mẫu tin nhắc';

  @override
  String get dunningPreviewFailed => 'Không tải được mẫu tin.';

  @override
  String get dunningPreviewNote =>
      'Dữ liệu mẫu, không phải tên hay số tiền thật.';

  @override
  String get dunningStepOther => 'Trạng thái khác';

  @override
  String receivablesAgingLine(String bucket, String overdue) {
    return '$bucket · $overdue';
  }

  @override
  String receivablesPaymentMetaCode(String date, String code) {
    return 'Ngày thu $date · $code';
  }

  @override
  String dunningStepLine(String label, String status) {
    return '$label · $status';
  }

  @override
  String get receivablesClassAll => 'Tất cả lớp';

  @override
  String receivablesClassFilter(String name) {
    return 'Lớp: $name';
  }

  @override
  String get receivablesClassPick => 'Chọn lớp';

  @override
  String get dunningDiscardTitle => 'Bỏ thay đổi chưa lưu?';

  @override
  String get dunningDiscardBody => 'Cài đặt nhắc nợ bạn vừa sửa sẽ mất.';

  @override
  String get dunningDiscardConfirm => 'Bỏ thay đổi';

  @override
  String get dunningDiscardKeep => 'Ở lại';
}
