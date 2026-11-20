// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'mini_app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class MiniAppLocalizationsEn extends MiniAppLocalizations {
  MiniAppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get spaceTitle => 'Parent';

  @override
  String get switchRole => 'Switch role';

  @override
  String get parentNoInviteTitle => 'You need an invitation from a teacher';

  @override
  String get parentNoInviteBody =>
      'The teacher sends a link, a code or a QR code to connect you to your child\'s class.';

  @override
  String get parentAddInvite => 'Add invitation';

  @override
  String get parentLoadFailed =>
      'Could not load your child\'s information. Please try again.';

  @override
  String get parentRetry => 'Try again';

  @override
  String get parentPickChild => 'Choose child';

  @override
  String parentChildClasses(String classes) {
    return 'Classes: $classes';
  }

  @override
  String get parentNoClasses => 'Your child is not enrolled in any class.';

  @override
  String get attendanceWeekTitle => 'Attendance this week';

  @override
  String attendanceWeekRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get attendancePresent => 'Present';

  @override
  String get attendanceLate => 'Late';

  @override
  String get attendanceExcused => 'Excused absence';

  @override
  String get attendanceUnexcused => 'Unexcused absence';

  @override
  String get attendanceNotRecorded => 'Not recorded';

  @override
  String get attendanceUpcoming => 'Upcoming';

  @override
  String attendanceCount(String label, int count) {
    return '$label: $count';
  }

  @override
  String get attendanceNoSessions => 'No classes this week.';

  @override
  String get attendanceCancelled => 'Cancelled';

  @override
  String get attendanceMakeup => 'Make-up class';

  @override
  String attendanceSessionLine(String className, String when) {
    return '$className, $when';
  }

  @override
  String get notificationBannerTitle => 'Turn on notifications';

  @override
  String get notificationBannerBody =>
      'Get attendance and schedule updates for your child as soon as the teacher posts them.';

  @override
  String get notificationBannerAction => 'Turn on notifications';

  @override
  String get invoiceTuitionTitle => 'Tuition';

  @override
  String invoiceTuitionUnpaid(int count, String total) {
    return '$count invoices not settled, $total in total';
  }

  @override
  String invoiceTuitionUnpaidMore(int count) {
    return '$count+ invoices not settled';
  }

  @override
  String get invoiceTuitionNone => 'No invoices to pay.';

  @override
  String get invoiceTuitionOpen => 'View invoices';

  @override
  String get invoiceListTitle => 'Invoices';

  @override
  String get invoiceFilterAll => 'All';

  @override
  String get invoiceStatusIssued => 'Unpaid';

  @override
  String get invoiceStatusPending => 'Awaiting confirmation';

  @override
  String get invoiceStatusPartial => 'Partially paid';

  @override
  String get invoiceStatusPaid => 'Paid';

  @override
  String get invoiceStatusVoid => 'Cancelled';

  @override
  String get invoiceStatusUnknown => 'Other';

  @override
  String get invoiceEmpty => 'No invoices yet.';

  @override
  String get invoiceLoadMore => 'Load more';

  @override
  String invoiceRowSubtitle(String student, String month) {
    return '$student, $month';
  }

  @override
  String invoiceDue(String date) {
    return 'Due $date';
  }

  @override
  String invoiceCodeLabel(String code) {
    return 'Code $code';
  }

  @override
  String get invoiceLinesTitle => 'Items';

  @override
  String get invoiceTotal => 'Total';

  @override
  String get invoiceVoidNotice =>
      'This invoice was cancelled. No payment needed.';

  @override
  String get invoicePayTitle => 'Bank transfer';

  @override
  String get invoiceQrHint => 'Scan with your banking app.';

  @override
  String get invoiceSaveQr => 'Save QR image';

  @override
  String get invoiceQrSaved => 'QR image saved.';

  @override
  String get invoiceQrDenied =>
      'No permission to save photos. Allow it in Settings.';

  @override
  String get invoiceQrFailed =>
      'Couldn\'t save the QR image. Please try again.';

  @override
  String get invoiceCopyNote => 'Copy transfer note';

  @override
  String get invoiceCopyAccount => 'Copy account number';

  @override
  String get invoiceCopied => 'Copied.';

  @override
  String get invoiceBank => 'Bank';

  @override
  String get invoiceAccountNo => 'Account number';

  @override
  String get invoiceAccountName => 'Account holder';

  @override
  String get invoiceTransferNote => 'Transfer note';

  @override
  String get invoiceNotFound => 'Invoice not found';

  @override
  String get invoiceNotFoundBody =>
      'This invoice doesn\'t exist or you can\'t view it.';

  @override
  String get invoiceLoadFailed =>
      'Couldn\'t load the invoice. Please try again.';
}
