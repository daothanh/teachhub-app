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
}
