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
  String get spaceComingSoon => 'Không gian này đang được xây dựng.';

  @override
  String get switchRole => 'Đổi vai trò';

  @override
  String get offlineBanner =>
      'Ngoại tuyến — thay đổi được lưu trên máy và tự đồng bộ khi có mạng.';

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
  String get studentsRemoveGuardian => 'Bỏ phụ huynh';

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
  String get onboardingTitle => 'Làm quen TeachHub';

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
  String get onboardingPayoutBody =>
      'Thêm tài khoản để nhận học phí. Tính năng sắp có.';

  @override
  String get onboardingComplianceBody =>
      'Xem các việc cần làm để dạy đúng quy định. Tính năng sắp có.';

  @override
  String get onboardingDoneTitle => 'Bạn đã xong phần làm quen';

  @override
  String get onboardingDoneBody => 'Vào xem lớp và học viên của bạn.';

  @override
  String get onboardingFinish => 'Vào TeachHub';

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
}
