// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'mini_app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class MiniAppLocalizationsEn extends MiniAppLocalizations {
  MiniAppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get spaceTitle => 'Teacher';

  @override
  String get switchRole => 'Switch role';

  @override
  String get offlineBanner =>
      'Offline — changes are saved on this device and sync when you are back online.';

  @override
  String get classesTitle => 'Classes';

  @override
  String get classesTabActive => 'Active';

  @override
  String get classesTabArchived => 'Archived';

  @override
  String get classesEmpty => 'No classes yet';

  @override
  String get classesEmptyHint => 'Create your first class to get started.';

  @override
  String get classesEmptyArchived => 'No archived classes';

  @override
  String get classesCreate => 'Create class';

  @override
  String get classesRetry => 'Try again';

  @override
  String get classesCancel => 'Cancel';

  @override
  String classesItemMeta(String subject, int grade) {
    return '$subject · Grade $grade';
  }

  @override
  String classesStudentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count students',
      one: '1 student',
    );
    return '$_temp0';
  }

  @override
  String get classesModeOffline => 'In person';

  @override
  String get classesModeOnline => 'Online';

  @override
  String get classesDetailTitle => 'Class details';

  @override
  String get classesEdit => 'Edit class';

  @override
  String get classesArchive => 'Archive class';

  @override
  String get classesArchiveConfirmTitle => 'Archive this class?';

  @override
  String get classesArchiveConfirmBody =>
      'The class will be hidden from the list and the calendar. Its data is kept.';

  @override
  String get classesArchivedBanner => 'This class is archived.';

  @override
  String get classesSectionInfo => 'Details';

  @override
  String get classesSectionSchedule => 'Weekly schedule';

  @override
  String get classesSectionSessions => 'Upcoming sessions';

  @override
  String get classesSectionStudents => 'Students';

  @override
  String get classesNoRules => 'No weekly schedule yet.';

  @override
  String get classesNoSessions => 'No sessions in the next two months.';

  @override
  String get classesSessionsLoadFailed => 'Could not load the sessions.';

  @override
  String get classesNoStudents => 'No students in this class yet.';

  @override
  String get classesAddStudent => 'Add student';

  @override
  String get classesLabelLocation => 'Location';

  @override
  String get classesLabelCapacity => 'Capacity';

  @override
  String get classesLabelStart => 'Starts';

  @override
  String get classesLabelEnd => 'Ends';

  @override
  String get classesNoEnd => 'Open-ended';

  @override
  String classesRuleLine(String day, String start, int minutes) {
    return '$day · $start · $minutes min';
  }

  @override
  String classesSessionLine(String date, String start, String end) {
    return '$date · $start–$end';
  }

  @override
  String get classesSessionPlanned => 'Planned';

  @override
  String get classesSessionTaught => 'Taught';

  @override
  String get classesSessionCancelled => 'Cancelled';

  @override
  String get classesSessionMakeup => 'Make-up';

  @override
  String get classesStudentPaused => 'On break';

  @override
  String get classesFormNewTitle => 'New class';

  @override
  String get classesFormEditTitle => 'Edit class';

  @override
  String get classesFieldName => 'Class name';

  @override
  String get classesFieldSubject => 'Subject';

  @override
  String get classesFieldGrade => 'Grade (1–12)';

  @override
  String get classesFieldMode => 'Format';

  @override
  String get classesFieldLocation => 'Location';

  @override
  String get classesFieldCapacity => 'Capacity (optional)';

  @override
  String get classesFieldStart => 'Start date';

  @override
  String get classesFieldEnd => 'End date (optional)';

  @override
  String get classesPickDate => 'Pick a date';

  @override
  String get classesClearEnd => 'Clear end date';

  @override
  String get classesSave => 'Save';

  @override
  String get classesFormSaved => 'Class saved.';

  @override
  String classesFormSavedSessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
    );
    return 'Class saved. $_temp0 created.';
  }

  @override
  String get classesErrRequired => 'This is required.';

  @override
  String get classesErrGrade => 'Grade must be 1 to 12.';

  @override
  String get classesErrCapacity => 'Capacity must be 1 to 500.';

  @override
  String get classesErrEndBeforeStart =>
      'The end date cannot be before the start date.';

  @override
  String get classesErrRulesDuplicate =>
      'Two sessions share the same day and start time.';

  @override
  String get classesErrRulesOverflow => 'A session cannot run past 24:00.';

  @override
  String get classesErrRulesTooMany => 'At most 14 sessions per week.';

  @override
  String get classesRulesTitle => 'Weekly schedule';

  @override
  String get classesRuleAdd => 'Add session';

  @override
  String get classesRuleRemove => 'Remove this session';

  @override
  String get classesRuleTime => 'Start time';

  @override
  String get classesRuleDuration => 'Duration (min)';

  @override
  String classesWeekday(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'Monday',
      '2': 'Tuesday',
      '3': 'Wednesday',
      '4': 'Thursday',
      '5': 'Friday',
      '6': 'Saturday',
      'other': 'Sunday',
    });
    return '$_temp0';
  }

  @override
  String classesWeekdayShort(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'Mon',
      '2': 'Tue',
      '3': 'Wed',
      '4': 'Thu',
      '5': 'Fri',
      '6': 'Sat',
      'other': 'Sun',
    });
    return '$_temp0';
  }

  @override
  String get classesErrNetwork =>
      'No connection. Check your network and try again.';

  @override
  String get classesErrPlanLimit =>
      'Your plan limit is reached. Upgrade to add more.';

  @override
  String get classesErrStale => 'The data just changed. Reload and try again.';

  @override
  String get classesErrBusy =>
      'Your request is still processing. Wait a moment.';

  @override
  String get classesErrForbidden => 'You do not have permission to do this.';

  @override
  String get classesErrNotFound => 'This class was not found.';

  @override
  String get classesErrValidation =>
      'Some data is not valid. Check the fields.';

  @override
  String get classesErrGeneric => 'Something went wrong. Try again later.';

  @override
  String get classesErrEnrollConflict =>
      'The class is archived or the student has left, so they cannot be added.';

  @override
  String get classesPickerTitle => 'Add student';

  @override
  String get classesPickerSearchHint => 'Search by name';

  @override
  String get classesPickerTooShort => 'Type at least 2 characters to search.';

  @override
  String get classesPickerNone => 'No matching students.';

  @override
  String get classesPickerNoneHint =>
      'New students are added from the Students section.';

  @override
  String classesEnrolled(String name) {
    return '$name was added to the class.';
  }

  @override
  String classesAlreadyEnrolled(String name) {
    return '$name is already in the class.';
  }

  @override
  String get classesErrRulesDuration => 'Duration must be 15 to 480 minutes.';

  @override
  String classesRuleN(int n) {
    return 'Session $n';
  }

  @override
  String classesRuleRemoveN(int n) {
    return 'Remove session $n';
  }

  @override
  String get studentsFormTitle => 'Add student';

  @override
  String get studentsFullName => 'Full name';

  @override
  String get studentsFullNameRequired => 'Enter the student\'s name.';

  @override
  String get studentsDob => 'Date of birth (optional)';

  @override
  String get studentsSchool => 'School (optional)';

  @override
  String get studentsNote => 'Note (optional)';

  @override
  String studentsGuardianTitle(int n) {
    return 'Parent $n';
  }

  @override
  String get studentsGuardianName => 'Parent\'s name';

  @override
  String get studentsGuardianNameRequired => 'Enter the parent\'s name.';

  @override
  String get studentsGuardianPhone => 'Phone (optional)';

  @override
  String get studentsGuardianPhoneInvalid => 'The phone number looks wrong.';

  @override
  String get studentsAddGuardian => 'Add parent';

  @override
  String studentsRemoveGuardian(int n) {
    return 'Remove parent $n';
  }

  @override
  String get studentsSave => 'Save student';

  @override
  String get studentsSaving => 'Saving…';

  @override
  String get studentsDuplicateTitle => 'Is this the same student?';

  @override
  String get studentsDuplicateBody =>
      'A record with the same name and birth date exists. Pick the student, or add a new one.';

  @override
  String get studentsDuplicateSame => 'Yes, same student';

  @override
  String get studentsDuplicateNew => 'No, add as new';

  @override
  String get studentsDuplicateCancel => 'Back to edit';

  @override
  String get studentsErrorLimit =>
      'Your plan has no room for more students. Upgrade to add more.';

  @override
  String get studentsErrorBusy => 'Still processing. Try again in a moment.';

  @override
  String get studentsErrorValidation =>
      'Some details are invalid. Check the fields.';

  @override
  String get studentsErrorNetwork => 'No connection. Try again later.';

  @override
  String get studentsErrorGeneric =>
      'Could not save the student. Try again later.';

  @override
  String get onboardingTitle => 'Get started with TeachHub';

  @override
  String onboardingProgress(int n, int total) {
    return 'Step $n/$total';
  }

  @override
  String get onboardingStepCreateClass => 'Create your first class';

  @override
  String get onboardingStepAddStudents => 'Add students';

  @override
  String get onboardingStepSetSchedule => 'Set the schedule';

  @override
  String get onboardingStepPayoutAccount => 'Payout account';

  @override
  String get onboardingStepComplianceChecklist => 'Compliance checklist';

  @override
  String get onboardingSkip => 'Later';

  @override
  String get onboardingMarkDone => 'Done with this step';

  @override
  String get onboardingPlaceholderBody => 'This screen is being finished.';

  @override
  String get onboardingPayoutBody =>
      'Add an account to receive tuition. Coming soon.';

  @override
  String get onboardingComplianceBody =>
      'See what to do to teach within the rules. Coming soon.';

  @override
  String get onboardingDoneTitle => 'You are all set';

  @override
  String get onboardingDoneBody => 'Go see your classes and students.';

  @override
  String get onboardingFinish => 'Open TeachHub';

  @override
  String get onboardingLoadFailed => 'Could not load progress. Try again.';

  @override
  String get onboardingRetry => 'Retry';

  @override
  String get onboardingErrorBusy => 'Still processing. Try again in a moment.';

  @override
  String get onboardingErrorValidation =>
      'This step could not be saved. Check it.';

  @override
  String get onboardingErrorNetwork => 'No connection. Try again later.';

  @override
  String get onboardingErrorGeneric => 'Could not save. Try again later.';

  @override
  String get onboardingCreateClassPending =>
      'The class screen will be connected later.';

  @override
  String get onboardingStudentSaved =>
      'Student saved. This step could not be recorded yet.';

  @override
  String get todayTitle => 'Today';

  @override
  String get todayEmpty => 'No sessions today';

  @override
  String get todayEmptyHint =>
      'Scheduled sessions of your classes show up here.';

  @override
  String get todayClassesEntry => 'Classes';

  @override
  String get todaySessionAttended => 'Attendance taken';

  @override
  String get todaySessionNotAttended => 'Not taken yet';

  @override
  String get todaySessionCancelled => 'Cancelled';

  @override
  String get todayTakeAttendance => 'Take attendance';

  @override
  String todayPending(int count) {
    return 'Waiting to sync ($count)';
  }

  @override
  String get todayRefreshFailed => 'Could not refresh. Pull down to retry.';

  @override
  String todaySessionSemantics(String className, String time, String status) {
    return '$className, $time, $status';
  }

  @override
  String get todayOnboardingTitle => 'Setup steps you skipped';

  @override
  String todayOnboardingOpen(String step) {
    return 'Open step $step';
  }

  @override
  String get attendanceTitle => 'Attendance';

  @override
  String get attendanceStatusPresent => 'Present';

  @override
  String get attendanceStatusLate => 'Late';

  @override
  String get attendanceStatusExcused => 'Excused absence';

  @override
  String get attendanceStatusUnexcused => 'Unexcused absence';

  @override
  String attendanceStudentSemantics(String name, String status) {
    return '$name, $status. Tap to change status';
  }

  @override
  String get attendanceSave => 'Save';

  @override
  String get attendanceSaving => 'Saving…';

  @override
  String get attendanceSaveFailed => 'Could not save. Try again.';

  @override
  String get attendanceLoadFailed => 'Could not load the student list.';

  @override
  String get attendanceRetry => 'Retry';

  @override
  String get attendanceEmptyRoster => 'This class has no students yet.';

  @override
  String get attendanceReadOnlyCancelled =>
      'This session was cancelled, so it is view only.';

  @override
  String get attendanceReadOnlyWindow =>
      'This session is older than 7 days, so it is view only.';

  @override
  String get attendanceOfflineNotice =>
      'You are offline. Changes are saved on this device and sent when you are back online.';

  @override
  String get attendanceNoteLabel => 'Note';

  @override
  String attendanceNoteToggle(String name) {
    return 'Note for $name';
  }

  @override
  String get attendanceRejectedWindow =>
      'The 7-day edit window has closed; the change was not accepted.';

  @override
  String get attendanceRejectedPlan =>
      'Your current plan is view only; the change was not accepted.';

  @override
  String get attendanceRejectedNotFound =>
      'The student is no longer in this session; the change was not accepted.';

  @override
  String get attendanceRejectedGeneric => 'This change was not accepted.';

  @override
  String get attendanceBatchNotFound =>
      'This session no longer exists, so attendance could not be sent.';

  @override
  String get attendanceBatchCancelled =>
      'This session was cancelled, so attendance could not be sent.';

  @override
  String get attendanceBatchGeneric =>
      'Attendance for this session could not be sent.';

  @override
  String get attendanceDiscard => 'Discard rejected changes';

  @override
  String get attendanceHistory => 'Edit history';

  @override
  String get historyTitle => 'Edit history';

  @override
  String get historyEmpty => 'No edits for this session yet.';

  @override
  String get historyLoadFailed => 'Could not load the history.';

  @override
  String get historyLoadMore => 'Load more';

  @override
  String historyChangedBy(String who, String time) {
    return '$who · $time';
  }

  @override
  String get historyUnknownUser => 'Unknown editor';

  @override
  String get historyFirst => 'First attendance';

  @override
  String historyNote(String note) {
    return 'Note: $note';
  }

  @override
  String get historyNoNote => 'no note';

  @override
  String get contactsAdd => 'Add from contacts';

  @override
  String get contactsTitle => 'Add from contacts';

  @override
  String get contactsDeniedTitle => 'No access to contacts';

  @override
  String get contactsDeniedBody =>
      'TeachHub only reads your contacts when you tap Add from contacts, so you can pick students and parent numbers. You can still add each student by hand.';

  @override
  String get contactsAllow => 'Allow again';

  @override
  String get contactsOpenSettings => 'Open Settings';

  @override
  String get contactsManual => 'Add by hand';

  @override
  String get contactsLoadFailed =>
      'Could not read your contacts. Try again later.';

  @override
  String get contactsEmpty => 'You have no contacts yet.';

  @override
  String get contactsNoPhone => 'No phone number';

  @override
  String contactsContinue(int n) {
    return 'Continue ($n)';
  }

  @override
  String contactsSaveAll(int n) {
    return 'Save $n students';
  }

  @override
  String get contactsDone => 'Done';

  @override
  String get contactsBack => 'Pick again';

  @override
  String contactsRemoveRow(String name) {
    return 'Remove $name';
  }

  @override
  String get contactsReviewHint =>
      'The contact name becomes the student name and the phone number becomes parent 1\'s number. Edit or remove rows before saving.';

  @override
  String get contactsRowSaved => 'Saved';

  @override
  String get contactsRowSaving => 'Saving…';

  @override
  String get contactsRowFailed => 'Not saved';

  @override
  String get contactsRowDuplicate => 'Possible duplicate';

  @override
  String get contactsRowReview => 'Review duplicate';

  @override
  String get todayScheduleEntry => 'Schedule';

  @override
  String get scheduleTitle => 'Schedule';

  @override
  String get scheduleModeDay => 'Day';

  @override
  String get scheduleModeWeek => 'Week';

  @override
  String get schedulePrevious => 'Previous';

  @override
  String get scheduleNext => 'Next';

  @override
  String get scheduleToday => 'Today';

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
      'You\'re offline. This is the last saved schedule.';

  @override
  String get scheduleEmpty => 'No sessions in this period';

  @override
  String get scheduleLoadFailed => 'Could not load the schedule.';

  @override
  String get scheduleRetry => 'Try again';

  @override
  String get scheduleCancelled => 'Cancelled';

  @override
  String get scheduleMakeup => 'Make-up session';

  @override
  String scheduleCancelReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get studentsEditTitle => 'Edit student';

  @override
  String get studentsGuardianRelation => 'Relationship';

  @override
  String get studentsRelationFather => 'Father';

  @override
  String get studentsRelationMother => 'Mother';

  @override
  String get studentsRelationGuardian => 'Guardian';

  @override
  String get inviteStatusNotInvited => 'Not invited';

  @override
  String get inviteStatusInvited => 'Invited';

  @override
  String get inviteStatusActivated => 'Activated';

  @override
  String get inviteStatusExpired => 'Expired';

  @override
  String get inviteShare => 'Share link';

  @override
  String get inviteResend => 'Resend link';

  @override
  String get rosterNoGuardians =>
      'No parent yet. Tap the student name to add one.';

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
    return 'Edit student $name';
  }

  @override
  String inviteSheetFor(String guardian, String student) {
    return 'Invite $guardian, parent of $student';
  }

  @override
  String get inviteQrLabel => 'Invitation QR code';

  @override
  String get inviteCodeLabel => 'Code to type in';

  @override
  String inviteCodeSemantics(String code) {
    return 'Invitation code: $code';
  }

  @override
  String get inviteExpiryNote =>
      'The link works for 7 days and the typed code for 48 hours.';

  @override
  String get inviteOldLinkNote =>
      'This parent\'s previous link, if any, no longer works.';

  @override
  String inviteShareMessage(
    String guardian,
    String student,
    String url,
    String code,
  ) {
    return 'Hello $guardian, I would like to invite you to follow $student\'s learning on TeachHub.\nOpen the link to accept: $url\nOr enter code $code in the TeachHub app (the code works for 48 hours).';
  }

  @override
  String get inviteAllEntry => 'Invite all parents not yet activated';

  @override
  String get inviteAllTitle => 'Invite class parents';

  @override
  String get inviteAllEmpty => 'No parents left to invite.';

  @override
  String inviteAllProgress(int done, int total) {
    return 'Created $done/$total links';
  }

  @override
  String get inviteAllHint =>
      'Tap Share to send to each parent in turn. Parents with a valid invitation are skipped.';

  @override
  String get inviteAllCreating => 'Creating link…';

  @override
  String get inviteAllShareAgain => 'Share again';

  @override
  String get inviteAllShowQr => 'Show QR code';

  @override
  String get inviteAllSharedMark => 'Share opened';

  @override
  String get sessionActionReschedule => 'Reschedule';

  @override
  String get sessionActionCancel => 'Cancel session';

  @override
  String get sessionActionMakeup => 'Add makeup';

  @override
  String get sessionRescheduleTitle => 'Reschedule session';

  @override
  String get sessionCancelTitle => 'Cancel this session?';

  @override
  String get sessionCancelBody =>
      'The class\'s parents will be notified that this session is cancelled.';

  @override
  String get sessionMakeupTitle => 'Add makeup session';

  @override
  String get sessionPickDate => 'Date';

  @override
  String get sessionPickTime => 'Start time';

  @override
  String get sessionReasonLabel => 'Reason (optional)';

  @override
  String get sessionConfirmReschedule => 'Reschedule';

  @override
  String get sessionConfirmCancel => 'Cancel session';

  @override
  String get sessionConfirmMakeup => 'Add makeup';

  @override
  String get sessionClose => 'Close';

  @override
  String get sessionErrPast => 'The new time must be in the future.';

  @override
  String get sessionErrCancelled =>
      'This session is cancelled, so it cannot be rescheduled.';

  @override
  String get sessionHasAttendanceTitle => 'Attendance already taken';

  @override
  String get sessionHasAttendanceBody =>
      'This session has attendance, so it cannot be cancelled yet. Open the attendance sheet to fix it, then cancel the session.';

  @override
  String get sessionOpenAttendance => 'Open attendance';

  @override
  String get sessionDoneRescheduled => 'Session rescheduled.';

  @override
  String get sessionDoneCancelled => 'Session cancelled.';

  @override
  String get sessionDoneMakeup => 'Makeup session added.';

  @override
  String sessionActionsLabel(String date, String start) {
    return 'Actions for session on $date at $start';
  }

  @override
  String sessionCancelReasonLine(String reason) {
    return 'Cancel reason: $reason';
  }
}
