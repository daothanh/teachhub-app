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
  /// **'Phụ huynh'**
  String get spaceTitle;

  /// No description provided for @switchRole.
  ///
  /// In vi, this message translates to:
  /// **'Đổi vai trò'**
  String get switchRole;

  /// No description provided for @parentNoInviteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cần lời mời từ giáo viên'**
  String get parentNoInviteTitle;

  /// No description provided for @parentNoInviteBody.
  ///
  /// In vi, this message translates to:
  /// **'Giáo viên sẽ gửi link, mã hoặc mã QR để kết nối với lớp của con.'**
  String get parentNoInviteBody;

  /// No description provided for @parentAddInvite.
  ///
  /// In vi, this message translates to:
  /// **'Thêm lời mời'**
  String get parentAddInvite;

  /// No description provided for @parentLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được thông tin của con. Vui lòng thử lại.'**
  String get parentLoadFailed;

  /// No description provided for @parentRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get parentRetry;

  /// No description provided for @parentRefreshFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không làm mới được. Kéo xuống để thử lại.'**
  String get parentRefreshFailed;

  /// No description provided for @parentPickChild.
  ///
  /// In vi, this message translates to:
  /// **'Chọn con'**
  String get parentPickChild;

  /// No description provided for @parentChildClasses.
  ///
  /// In vi, this message translates to:
  /// **'Lớp: {classes}'**
  String parentChildClasses(String classes);

  /// No description provided for @parentNoClasses.
  ///
  /// In vi, this message translates to:
  /// **'Con chưa ghi danh lớp nào.'**
  String get parentNoClasses;

  /// No description provided for @attendanceWeekTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chuyên cần tuần này'**
  String get attendanceWeekTitle;

  /// No description provided for @attendanceWeekRange.
  ///
  /// In vi, this message translates to:
  /// **'{start} – {end}'**
  String attendanceWeekRange(String start, String end);

  /// No description provided for @attendancePresent.
  ///
  /// In vi, this message translates to:
  /// **'Có mặt'**
  String get attendancePresent;

  /// No description provided for @attendanceLate.
  ///
  /// In vi, this message translates to:
  /// **'Đi muộn'**
  String get attendanceLate;

  /// No description provided for @attendanceExcused.
  ///
  /// In vi, this message translates to:
  /// **'Vắng có phép'**
  String get attendanceExcused;

  /// No description provided for @attendanceUnexcused.
  ///
  /// In vi, this message translates to:
  /// **'Vắng không phép'**
  String get attendanceUnexcused;

  /// No description provided for @attendanceNotRecorded.
  ///
  /// In vi, this message translates to:
  /// **'Chưa điểm danh'**
  String get attendanceNotRecorded;

  /// No description provided for @attendanceUpcoming.
  ///
  /// In vi, this message translates to:
  /// **'Sắp học'**
  String get attendanceUpcoming;

  /// No description provided for @attendanceCount.
  ///
  /// In vi, this message translates to:
  /// **'{label}: {count}'**
  String attendanceCount(String label, int count);

  /// No description provided for @attendanceNoSessions.
  ///
  /// In vi, this message translates to:
  /// **'Tuần này chưa có buổi học.'**
  String get attendanceNoSessions;

  /// No description provided for @attendanceCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Buổi đã hủy'**
  String get attendanceCancelled;

  /// No description provided for @attendanceMakeup.
  ///
  /// In vi, this message translates to:
  /// **'Buổi bù'**
  String get attendanceMakeup;

  /// No description provided for @attendanceSessionLine.
  ///
  /// In vi, this message translates to:
  /// **'{className}, {when}'**
  String attendanceSessionLine(String className, String when);

  /// No description provided for @notificationBannerTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bật thông báo'**
  String get notificationBannerTitle;

  /// No description provided for @notificationBannerBody.
  ///
  /// In vi, this message translates to:
  /// **'Nhận tin điểm danh và thay đổi lịch của con ngay khi giáo viên cập nhật.'**
  String get notificationBannerBody;

  /// No description provided for @notificationBannerAction.
  ///
  /// In vi, this message translates to:
  /// **'Bật thông báo'**
  String get notificationBannerAction;

  /// No description provided for @invoiceTuitionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Học phí'**
  String get invoiceTuitionTitle;

  /// No description provided for @invoiceTuitionUnpaid.
  ///
  /// In vi, this message translates to:
  /// **'{count} hóa đơn chưa đóng xong, còn nợ {total}'**
  String invoiceTuitionUnpaid(int count, String total);

  /// No description provided for @invoiceTuitionUnpaidMore.
  ///
  /// In vi, this message translates to:
  /// **'{count}+ hóa đơn chưa đóng xong'**
  String invoiceTuitionUnpaidMore(int count);

  /// No description provided for @invoiceTuitionNone.
  ///
  /// In vi, this message translates to:
  /// **'Không có hóa đơn nào cần đóng.'**
  String get invoiceTuitionNone;

  /// No description provided for @invoiceTuitionFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được học phí.'**
  String get invoiceTuitionFailed;

  /// No description provided for @invoiceTuitionOpen.
  ///
  /// In vi, this message translates to:
  /// **'Xem hóa đơn'**
  String get invoiceTuitionOpen;

  /// No description provided for @invoiceListTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hóa đơn'**
  String get invoiceListTitle;

  /// No description provided for @invoiceFilterAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get invoiceFilterAll;

  /// No description provided for @invoiceStatusIssued.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thanh toán'**
  String get invoiceStatusIssued;

  /// No description provided for @invoiceStatusPending.
  ///
  /// In vi, this message translates to:
  /// **'Chờ xác nhận'**
  String get invoiceStatusPending;

  /// No description provided for @invoiceStatusPartial.
  ///
  /// In vi, this message translates to:
  /// **'Đã trả một phần'**
  String get invoiceStatusPartial;

  /// No description provided for @invoiceStatusPaid.
  ///
  /// In vi, this message translates to:
  /// **'Đã thanh toán'**
  String get invoiceStatusPaid;

  /// No description provided for @invoiceStatusVoid.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy'**
  String get invoiceStatusVoid;

  /// No description provided for @invoiceStatusUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get invoiceStatusUnknown;

  /// No description provided for @invoiceEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có hóa đơn nào.'**
  String get invoiceEmpty;

  /// No description provided for @invoiceLoadMore.
  ///
  /// In vi, this message translates to:
  /// **'Xem thêm'**
  String get invoiceLoadMore;

  /// No description provided for @invoiceRowSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'{student}, kỳ {month}'**
  String invoiceRowSubtitle(String student, String month);

  /// No description provided for @invoiceDue.
  ///
  /// In vi, this message translates to:
  /// **'Hạn {date}'**
  String invoiceDue(String date);

  /// No description provided for @invoiceCodeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mã {code}'**
  String invoiceCodeLabel(String code);

  /// No description provided for @invoiceLinesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Các khoản'**
  String get invoiceLinesTitle;

  /// No description provided for @invoiceTotal.
  ///
  /// In vi, this message translates to:
  /// **'Tổng cộng'**
  String get invoiceTotal;

  /// No description provided for @invoiceVoidNotice.
  ///
  /// In vi, this message translates to:
  /// **'Hóa đơn đã hủy, bạn không cần chuyển khoản.'**
  String get invoiceVoidNotice;

  /// No description provided for @invoicePayTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển khoản'**
  String get invoicePayTitle;

  /// No description provided for @invoiceQrHint.
  ///
  /// In vi, this message translates to:
  /// **'Quét mã bằng app ngân hàng.'**
  String get invoiceQrHint;

  /// No description provided for @invoiceSaveQr.
  ///
  /// In vi, this message translates to:
  /// **'Lưu ảnh QR'**
  String get invoiceSaveQr;

  /// No description provided for @invoiceQrSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu ảnh QR.'**
  String get invoiceQrSaved;

  /// No description provided for @invoiceQrDenied.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có quyền lưu ảnh. Mở Cài đặt để cho phép.'**
  String get invoiceQrDenied;

  /// No description provided for @invoiceQrFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không lưu được ảnh QR. Hãy thử lại.'**
  String get invoiceQrFailed;

  /// No description provided for @invoiceCopyNote.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép nội dung chuyển khoản'**
  String get invoiceCopyNote;

  /// No description provided for @invoiceCopyAccount.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép số tài khoản'**
  String get invoiceCopyAccount;

  /// No description provided for @invoiceCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép.'**
  String get invoiceCopied;

  /// No description provided for @invoiceBank.
  ///
  /// In vi, this message translates to:
  /// **'Ngân hàng'**
  String get invoiceBank;

  /// No description provided for @invoiceAccountNo.
  ///
  /// In vi, this message translates to:
  /// **'Số tài khoản'**
  String get invoiceAccountNo;

  /// No description provided for @invoiceAccountName.
  ///
  /// In vi, this message translates to:
  /// **'Chủ tài khoản'**
  String get invoiceAccountName;

  /// No description provided for @invoiceTransferNote.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung chuyển khoản'**
  String get invoiceTransferNote;

  /// No description provided for @invoiceNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy hóa đơn'**
  String get invoiceNotFound;

  /// No description provided for @invoiceNotFoundBody.
  ///
  /// In vi, this message translates to:
  /// **'Hóa đơn không tồn tại hoặc bạn không xem được.'**
  String get invoiceNotFoundBody;

  /// No description provided for @invoiceLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được hóa đơn. Hãy thử lại.'**
  String get invoiceLoadFailed;

  /// No description provided for @invoicePaidAmount.
  ///
  /// In vi, this message translates to:
  /// **'Đã thanh toán'**
  String get invoicePaidAmount;

  /// No description provided for @invoiceRemainingAmount.
  ///
  /// In vi, this message translates to:
  /// **'Còn nợ'**
  String get invoiceRemainingAmount;

  /// No description provided for @invoicePaidNotice.
  ///
  /// In vi, this message translates to:
  /// **'Học phí đã thanh toán đủ, bạn không cần chuyển khoản.'**
  String get invoicePaidNotice;

  /// No description provided for @invoiceStatusCarried.
  ///
  /// In vi, this message translates to:
  /// **'Đã chuyển sang kỳ sau'**
  String get invoiceStatusCarried;

  /// No description provided for @invoiceStatusCovered.
  ///
  /// In vi, this message translates to:
  /// **'Đã trừ vào số dư'**
  String get invoiceStatusCovered;

  /// No description provided for @invoiceLineCarryDebt.
  ///
  /// In vi, this message translates to:
  /// **'Nợ kỳ trước'**
  String get invoiceLineCarryDebt;

  /// No description provided for @invoiceLineCarryCredit.
  ///
  /// In vi, this message translates to:
  /// **'Trừ tiền trả thừa'**
  String get invoiceLineCarryCredit;

  /// No description provided for @invoiceLinePrevAdjustment.
  ///
  /// In vi, this message translates to:
  /// **'Điều chỉnh kỳ trước'**
  String get invoiceLinePrevAdjustment;

  /// No description provided for @invoiceCarriedAmount.
  ///
  /// In vi, this message translates to:
  /// **'Đã chuyển sang hóa đơn kỳ sau'**
  String get invoiceCarriedAmount;

  /// No description provided for @invoiceCarriedNotice.
  ///
  /// In vi, this message translates to:
  /// **'Khoản còn nợ của hóa đơn này đã chuyển sang hóa đơn kỳ sau. Bạn không cần chuyển khoản ở hóa đơn này, hãy thanh toán ở hóa đơn kỳ sau.'**
  String get invoiceCarriedNotice;

  /// No description provided for @invoiceCoveredNotice.
  ///
  /// In vi, this message translates to:
  /// **'Tiền đóng thừa trước đó đã trừ vào hóa đơn này, bạn không cần chuyển khoản.'**
  String get invoiceCoveredNotice;

  /// No description provided for @invoiceReceiptsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Biên nhận'**
  String get invoiceReceiptsTitle;

  /// No description provided for @invoiceReceiptLine.
  ///
  /// In vi, this message translates to:
  /// **'{method} · Ngày thu {date}'**
  String invoiceReceiptLine(String method, String date);

  /// No description provided for @invoiceReceiptVoided.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy'**
  String get invoiceReceiptVoided;

  /// No description provided for @invoiceMethodBank.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển khoản'**
  String get invoiceMethodBank;

  /// No description provided for @invoiceMethodCash.
  ///
  /// In vi, this message translates to:
  /// **'Tiền mặt'**
  String get invoiceMethodCash;

  /// No description provided for @invoicePartialHint.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR chỉ có số tiền của cả hóa đơn nên bạn đừng quét. Hãy chuyển đúng số còn lại theo thông tin bên dưới.'**
  String get invoicePartialHint;

  /// No description provided for @invoiceAmountToTransfer.
  ///
  /// In vi, this message translates to:
  /// **'Số cần chuyển: {amount}'**
  String invoiceAmountToTransfer(String amount);

  /// No description provided for @invoiceCopyAmount.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép số tiền'**
  String get invoiceCopyAmount;
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
