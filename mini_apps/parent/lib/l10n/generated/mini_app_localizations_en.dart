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
  String get parentRefreshFailed =>
      'Couldn\'t refresh. Pull down to try again.';

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
    return '$count invoices not settled, $total outstanding';
  }

  @override
  String get invoiceTuitionNone => 'No invoices to pay.';

  @override
  String get invoiceTuitionFailed => 'Couldn\'t load tuition.';

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

  @override
  String get invoicePaidAmount => 'Paid';

  @override
  String get invoiceRemainingAmount => 'Outstanding';

  @override
  String get invoicePaidNotice =>
      'This invoice is paid in full. No transfer needed.';

  @override
  String get invoiceStatusCarried => 'Moved to next period';

  @override
  String get invoiceStatusCovered => 'Covered by balance';

  @override
  String get invoiceLineCarryDebt => 'Previous balance owed';

  @override
  String get invoiceLineCarryCredit => 'Overpayment credited';

  @override
  String get invoiceLinePrevAdjustment => 'Adjustment for earlier period';

  @override
  String get invoiceCarriedAmount => 'Moved to next period\'s invoice';

  @override
  String get invoiceCarriedNotice =>
      'What was still owed on this invoice has moved to the next period\'s invoice. You do not need to transfer anything for this one; pay the next invoice instead.';

  @override
  String get invoiceCoveredNotice =>
      'Your earlier overpayment already covers this invoice, so you do not need to transfer anything.';

  @override
  String get invoiceReceiptsTitle => 'Receipts';

  @override
  String invoiceReceiptLine(String method, String date) {
    return '$method · Received $date';
  }

  @override
  String get invoiceReceiptVoided => 'Voided';

  @override
  String get invoiceMethodBank => 'Bank transfer';

  @override
  String get invoiceMethodCash => 'Cash';

  @override
  String get invoicePartialHint =>
      'The QR code carries the full invoice amount, so please do not scan it. Transfer exactly the remaining amount using the details below.';

  @override
  String invoiceAmountToTransfer(String amount) {
    return 'Amount to transfer: $amount';
  }

  @override
  String get invoiceCopyAmount => 'Copy amount';

  @override
  String get invoiceClaimButton => 'I have transferred';

  @override
  String get invoicePendingNotice =>
      'You reported the transfer. The teacher will check the receipt and confirm; the invoice updates when there is a result.';

  @override
  String get invoiceClaimTitle => 'Report a transfer';

  @override
  String get invoiceClaimHint =>
      'Pick the receipt or a screenshot of the transaction (JPEG, PNG or HEIC, up to 10 MB). The image is sent only to the teacher and is not saved to your photo library.';

  @override
  String get invoiceClaimPick => 'Choose receipt image';

  @override
  String get invoiceClaimChange => 'Choose another image';

  @override
  String get invoiceClaimImageLabel => 'Selected receipt image';

  @override
  String get invoiceClaimAmount => 'Amount transferred (VND)';

  @override
  String get invoiceClaimNote => 'Note for the teacher (optional)';

  @override
  String get invoiceClaimSubmit => 'Send report';

  @override
  String get invoiceClaimRetry => 'Try again';

  @override
  String invoiceClaimUploading(int percent) {
    return 'Uploading image… $percent%';
  }

  @override
  String get invoiceClaimVerifying => 'Checking image…';

  @override
  String get invoiceClaimSending => 'Sending report…';

  @override
  String get invoiceClaimDone => 'Transfer reported. The teacher will confirm.';

  @override
  String get invoiceClaimErrType =>
      'The image must be JPEG, PNG or HEIC. Choose another image.';

  @override
  String get invoiceClaimErrLarge =>
      'The image is larger than 10 MB. Choose a smaller one.';

  @override
  String get invoiceClaimErrAmount =>
      'Enter the amount transferred, greater than 0.';

  @override
  String get invoiceClaimErrNote => 'The note is at most 300 characters.';

  @override
  String get invoiceClaimErrOffline =>
      'No network connection. The image is kept; tap Try again when you are online.';

  @override
  String get invoiceClaimErrExpired =>
      'The upload session expired. Tap Try again to upload again.';

  @override
  String get invoiceClaimErrPending =>
      'This invoice already has a report awaiting the teacher\'s confirmation.';

  @override
  String get invoiceClaimErrNotPayable =>
      'This invoice no longer needs a transfer.';

  @override
  String get invoiceClaimErrNotFound => 'Invoice not found.';

  @override
  String get invoiceClaimErrRate =>
      'You are going too fast. Wait a moment and try again.';

  @override
  String get invoiceClaimErrFailed =>
      'Could not send yet. Tap Try again; the image will not be uploaded twice.';
}
