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
  String get onboardingTitle => 'Get started with DayHoc';

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
  String get onboardingComplianceBody =>
      'See what to do to teach within the rules. Coming soon.';

  @override
  String get onboardingDoneTitle => 'You are all set';

  @override
  String get onboardingDoneBody => 'Go see your classes and students.';

  @override
  String get onboardingFinish => 'Open DayHoc';

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
  String get onboardingSaved => 'Saved. This step could not be recorded yet.';

  @override
  String get onboardingStudentNotEnrolled =>
      'Student saved. Could not add to the class or record this step yet.';

  @override
  String get onboardingScheduleNoClass =>
      'There is no class to schedule yet. Create one in step 1.';

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
      'DayHoc only reads your contacts when you tap Add from contacts, so you can pick students and parent numbers. You can still add each student by hand.';

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
    return 'Hello $guardian, I would like to invite you to follow $student\'s learning on DayHoc.\nOpen the link to accept: $url\nOr enter code $code in the DayHoc app (the code works for 48 hours).';
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
  String get inviteAllPausedNetwork =>
      'Stopped after repeated network errors. Check your connection, then tap Continue.';

  @override
  String inviteAllPausedRate(int seconds) {
    return 'Stopped because of too many requests. Wait about $seconds seconds, then tap Continue.';
  }

  @override
  String get inviteAllPausedRateNoWait =>
      'Stopped because of too many requests. Wait a moment, then tap Continue.';

  @override
  String get inviteAllResume => 'Continue';

  @override
  String get inviteAllWaiting => 'Not created yet';

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

  @override
  String get todaySettings => 'Settings and account';

  @override
  String get classesFeeSection => 'Tuition';

  @override
  String get classesFeeEnabled => 'Charge tuition';

  @override
  String get classesFeeTypeLabel => 'Billing type';

  @override
  String get feeTypePerSession => 'Per session';

  @override
  String get feeTypeMonthly => 'Monthly';

  @override
  String get feeTypeCourse => 'Whole course';

  @override
  String get classesFeeAmountPerSession => 'Price per session';

  @override
  String get classesFeeAmountMonthly => 'Monthly tuition';

  @override
  String get classesFeeAmountCourse => 'Total course tuition';

  @override
  String get classesFeeChargeExcused => 'Charge excused absences';

  @override
  String get classesFeeChargeUnexcused => 'Charge unexcused absences';

  @override
  String get classesFeeDeductCancelled => 'Deduct cancelled sessions';

  @override
  String get classesFeeInstallments => 'Installments (1–36)';

  @override
  String get classesFeeNote =>
      'Fee changes apply from the next unclosed billing period.';

  @override
  String get classesErrFeeAmountRequired => 'Enter an amount.';

  @override
  String get classesErrFeeAmountRange =>
      'Amount must be between 1 and 1,000,000,000.';

  @override
  String get classesErrFeeInstallments =>
      'Installments: 1 to 36, whole course only.';

  @override
  String get classesErrFeeCourseSchedule =>
      'A whole-course fee needs an end date and at least one weekly session.';

  @override
  String get feesErrRateLimited =>
      'You are going too fast. Wait a moment and try again.';

  @override
  String get rosterFeeOverrideBadge => 'Custom price';

  @override
  String get rosterFeeOverrideAction => 'Set custom price';

  @override
  String get feeOverrideTitle => 'Custom price';

  @override
  String feeOverrideFor(String name) {
    return 'Custom price for $name';
  }

  @override
  String get feeOverrideHint => 'Leave a field empty to follow the class.';

  @override
  String get feeOverrideAmount => 'Custom price';

  @override
  String get feeOverrideRulesTitle => 'Absence rules';

  @override
  String get feeOverrideInherit => 'Class default';

  @override
  String get feeOverrideYes => 'Charge';

  @override
  String get feeOverrideNo => 'Do not charge';

  @override
  String get feeOverrideInstallments => 'Installments (1–36)';

  @override
  String get feeOverrideDiscounts => 'Discounts';

  @override
  String get feeOverrideAddDiscount => 'Add a discount';

  @override
  String get feeOverrideDiscountDesc => 'Description';

  @override
  String get feeOverrideDiscountPercent => 'Percent';

  @override
  String get feeOverrideDiscountAmount => 'Amount';

  @override
  String get feeOverrideDiscountPercentValue => 'Percent (1–100)';

  @override
  String get feeOverrideDiscountAmountValue => 'Amount';

  @override
  String get feeOverrideRemoveDiscount => 'Remove discount';

  @override
  String get feeOverrideSave => 'Save custom price';

  @override
  String get feeOverrideClear => 'Remove custom price';

  @override
  String get feeOverrideSaved => 'Custom price saved.';

  @override
  String get feeOverrideCleared => 'Custom price removed.';

  @override
  String get feeOverrideErrAmount => 'Invalid amount.';

  @override
  String get feeOverrideErrInstallments => 'Installments: 1 to 36.';

  @override
  String get feeOverrideErrDiscountDesc =>
      'Enter a description, up to 100 characters.';

  @override
  String get feeOverrideErrDiscountValue => 'Invalid value.';

  @override
  String get payoutTitle => 'Payout accounts';

  @override
  String get payoutEmpty => 'No payout account yet';

  @override
  String get payoutEmptyBody =>
      'Add an account so parents know where to send tuition.';

  @override
  String get payoutAdd => 'Add account';

  @override
  String get payoutLimit => 'Up to 5 accounts.';

  @override
  String get payoutPrimaryBadge => 'Primary';

  @override
  String get payoutSetPrimary => 'Make primary';

  @override
  String get payoutEdit => 'Edit';

  @override
  String get payoutDelete => 'Delete';

  @override
  String get payoutCancel => 'Cancel';

  @override
  String get payoutDeleteTitle => 'Delete this account?';

  @override
  String get payoutDeleteBody =>
      'The account will be removed from your payout list.';

  @override
  String get payoutDeleteLastBody =>
      'This is your only payout account. Once it is removed, you won\'t be able to close a billing period until you add another one.';

  @override
  String payoutLine(String bank, String masked) {
    return '$bank · $masked';
  }

  @override
  String payoutUnknownBank(String bin) {
    return 'Bank $bin';
  }

  @override
  String payoutSemantics(String name, String line) {
    return '$name, $line';
  }

  @override
  String payoutActionsSemantics(String name) {
    return 'Actions for account $name';
  }

  @override
  String get payoutContinue => 'Continue';

  @override
  String get payoutSaved => 'Account saved.';

  @override
  String get payoutDeleted => 'Account deleted.';

  @override
  String get payoutPrimarySet => 'Primary account updated.';

  @override
  String get payoutFormNewTitle => 'Add account';

  @override
  String get payoutFormEditTitle => 'Edit account';

  @override
  String get payoutFieldBank => 'Bank';

  @override
  String get payoutPickBank => 'Choose a bank';

  @override
  String get payoutFieldAccountNo => 'Account number';

  @override
  String get payoutFieldAccountNoEditHint => 'Leave empty to keep the number';

  @override
  String get payoutFieldName => 'Account holder';

  @override
  String get payoutFieldNameHint => 'Exactly as the bank shows it';

  @override
  String get payoutOtpNeeded =>
      'Adding an account or changing the bank or number needs a code sent by email.';

  @override
  String get payoutSendCode => 'Send code';

  @override
  String get payoutSave => 'Save';

  @override
  String get payoutOtpSent => 'We sent a code to your email.';

  @override
  String get payoutOtpField => 'Code (6 digits)';

  @override
  String get payoutOtpConfirm => 'Confirm and save';

  @override
  String get payoutOtpResend => 'Resend code';

  @override
  String get payoutOtpBack => 'Edit details';

  @override
  String get payoutErrOtpInvalid => 'Wrong code. Check the code in your email.';

  @override
  String get payoutErrOtpLocked => 'Too many wrong codes. Try again later.';

  @override
  String get payoutErrMissing =>
      'No payout account. Add one before issuing invoices.';

  @override
  String get payoutErrBank => 'Choose a bank.';

  @override
  String get payoutErrRequired => 'Required.';

  @override
  String get payoutErrAccountNo => 'Account number has 6 to 19 digits.';

  @override
  String get payoutErrName => 'Name is up to 50 characters.';

  @override
  String get payoutLoadFailed => 'Could not load accounts.';

  @override
  String get onboardingPayoutIntro =>
      'Add at least one account to receive tuition.';

  @override
  String get todayBillingEntry => 'Tuition periods';

  @override
  String get billingTitle => 'Tuition periods';

  @override
  String get billingPeriodsEmpty => 'No billing periods yet';

  @override
  String get billingPeriodsEmptyBody =>
      'On the closing date the app drafts the month\'s invoices so you can check them before sending.';

  @override
  String get billingLoadFailed => 'Could not load tuition data.';

  @override
  String billingPeriodMonth(int month, int year) {
    return '$month/$year';
  }

  @override
  String billingPeriodDates(String close, String due) {
    return 'Closes $close · Due $due';
  }

  @override
  String get billingPeriodDrafting => 'In progress';

  @override
  String get billingPeriodClosed => 'All issued';

  @override
  String billingDraftSummary(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count drafts',
      one: '1 draft',
    );
    return '$_temp0 · $amount';
  }

  @override
  String billingIssuedSummary(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invoices sent',
      one: '1 invoice sent',
    );
    return '$_temp0 · $amount';
  }

  @override
  String billingVoidSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count voided invoices',
      one: '1 voided invoice',
    );
    return '$_temp0';
  }

  @override
  String get billingIssueAll => 'Issue & send all';

  @override
  String get billingIssueOne => 'Issue & send';

  @override
  String get billingIssueConfirmTitle => 'Send invoices to parents?';

  @override
  String billingIssueAllConfirmBody(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invoices',
      one: '1 invoice',
    );
    return 'Issue $_temp0, $amount in total. Parents are notified right away and issued invoices cannot be edited.';
  }

  @override
  String get billingIssueZeroConfirmBody =>
      'Send the 0 đ drafts. Drafts with nothing charged stay as drafts; drafts fully covered by overpayment are sent and marked as covered by the balance.';

  @override
  String billingIssueOneConfirmBody(String student, String amount) {
    return 'Issue the invoice for $student, $amount. Parents are notified right away and issued invoices cannot be edited.';
  }

  @override
  String billingIssued(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invoices sent.',
      one: '1 invoice sent.',
    );
    return '$_temp0';
  }

  @override
  String get billingIssuedNone => 'No invoices needed sending.';

  @override
  String billingIssuedSkippedZero(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invoices',
      one: '1 invoice',
    );
    return '$_temp0 of 0 đ not sent.';
  }

  @override
  String get billingNoPayableDrafts => 'No drafts with an amount left to send.';

  @override
  String billingZeroDraftNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invoices',
      one: '1 invoice',
    );
    return '$_temp0 of 0 đ: not sent when nothing was charged.';
  }

  @override
  String get billingInvoicesEmpty => 'No invoices in this period.';

  @override
  String get billingNoSend => 'Not sent';

  @override
  String get billingHasOverride => 'Custom rate';

  @override
  String get billingStatusDraft => 'Draft';

  @override
  String get billingStatusIssued => 'Issued';

  @override
  String get billingStatusPending => 'Awaiting confirmation';

  @override
  String get billingStatusPartial => 'Partly paid';

  @override
  String get billingStatusPaid => 'Paid';

  @override
  String get billingStatusVoid => 'Voided';

  @override
  String get billingInvoiceTitle => 'Invoice';

  @override
  String get billingLinesSessions => 'Sessions';

  @override
  String get billingLinesOther => 'Other items';

  @override
  String billingSessionLine(String date, String className) {
    return '$date · $className';
  }

  @override
  String get billingSessionCharged => 'Charged';

  @override
  String billingSessionNotCharged(String reason) {
    return 'Not charged: $reason';
  }

  @override
  String get billingReasonExcused => 'excused absence';

  @override
  String get billingReasonUnexcused => 'unexcused absence';

  @override
  String get billingReasonCancelled => 'session cancelled';

  @override
  String get billingReasonMakeup => 'makeup session';

  @override
  String get billingReasonOther => 'per the class rules';

  @override
  String billingAdjustmentReasonLine(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get billingTotal => 'Total';

  @override
  String billingClamped(String amount) {
    return 'The adjustment made the total negative, so it is held at 0 đ; the negative part of $amount will be deducted next period.';
  }

  @override
  String get billingCarryTitle => 'Balance from earlier periods';

  @override
  String get billingCarryDebt => 'Previous balance owed';

  @override
  String get billingCarryCredit => 'Overpayment credited';

  @override
  String get billingPrevAdjustment => 'Adjustment for earlier period';

  @override
  String get billingCarryPreviewNote =>
      'This is calculated as of now and may change when you send it.';

  @override
  String get billingDraftPreviewNote =>
      'Each draft total already includes any previous balance or overpayment and may change when you send it.';

  @override
  String billingIssuedTotal(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invoices',
      one: '1 invoice',
    );
    return '$_temp0 sent, total $amount.';
  }

  @override
  String billingIssuedCovered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invoices were',
      one: '1 invoice was',
    );
    return '$_temp0 covered by the balance, nothing to collect.';
  }

  @override
  String get billingCoveredByBalance => 'Covered by balance';

  @override
  String get billingCoveredByBalanceHint =>
      'The student\'s overpayment already covers this period, so there is nothing more to collect.';

  @override
  String billingCarriedAmount(String amount) {
    return '$amount carried to the next period';
  }

  @override
  String get billingCarriedHint =>
      'This amount is now on the next period\'s invoice; collect it there.';

  @override
  String get billingAddAdjustment => 'Add adjustment';

  @override
  String get billingAdjustTitle => 'Adjust invoice';

  @override
  String get billingAdjustHint =>
      'Adjustments cannot be deleted yet. If you entered one wrongly, add a line with the opposite sign.';

  @override
  String get billingAdjustDecrease => 'Discount';

  @override
  String get billingAdjustIncrease => 'Surcharge';

  @override
  String get billingAdjustAmount => 'Amount';

  @override
  String get billingAdjustDescription => 'Description';

  @override
  String get billingAdjustReason => 'Reason (required)';

  @override
  String get billingAdjustSave => 'Save adjustment';

  @override
  String get billingAdjusted => 'Adjustment added.';

  @override
  String get billingErrAmount =>
      'Enter an amount above 0 and up to 1.000.000.000 đ.';

  @override
  String get billingErrDescription =>
      'Enter a description, up to 200 characters.';

  @override
  String get billingErrReason => 'Enter a reason, up to 300 characters.';

  @override
  String get billingErrImmutable =>
      'This invoice is already issued and cannot be edited. Void it and create a replacement.';

  @override
  String get billingErrStaleUnverified =>
      'Could not confirm the result. Pull to reload and check before sending again.';

  @override
  String get billingErrStale =>
      'This invoice just changed, so we loaded the latest status. Check it and try again.';

  @override
  String get billingVoid => 'Void invoice';

  @override
  String get billingVoidTitle => 'Void this invoice?';

  @override
  String get billingVoidBody =>
      'Parents will no longer see the invoice\'s QR code. A reason is required.';

  @override
  String get billingVoidReason => 'Reason for voiding';

  @override
  String get billingVoidKeep => 'Keep it';

  @override
  String get billingVoidConfirm => 'Void invoice';

  @override
  String get billingVoided => 'Invoice voided.';

  @override
  String billingVoidedBanner(String reason) {
    return 'Invoice voided. Reason: $reason';
  }

  @override
  String get billingPayoutMissingTitle => 'No payout account';

  @override
  String get billingPayoutMissingBody =>
      'Add a payout account so parents know where to send tuition. Come back here afterwards to continue.';

  @override
  String get billingPayoutMissingAction => 'Add account';

  @override
  String get payoutOtpActionTitle => 'Verify to continue';

  @override
  String get payoutOtpActionBody =>
      'Changing or deleting the primary payout account needs a verification code. We sent it to your email.';

  @override
  String get payoutOtpActionConfirm => 'Confirm';

  @override
  String get billingIssueAllConfirmAction => 'Send all';

  @override
  String get billingPaidAmount => 'Collected';

  @override
  String get billingRemainingAmount => 'Outstanding';

  @override
  String get billingPayRecord => 'Record payment';

  @override
  String get billingPayFull => 'Paid in full';

  @override
  String get billingPayPartial => 'Partial payment';

  @override
  String get billingPayFullTitle => 'Record payment in full';

  @override
  String get billingPayPartialTitle => 'Record a partial payment';

  @override
  String get billingPayAmount => 'Amount received';

  @override
  String get billingPayMethod => 'Payment method';

  @override
  String get billingPayMethodBank => 'Bank transfer';

  @override
  String get billingPayMethodCash => 'Cash';

  @override
  String get billingPayDate => 'Date received';

  @override
  String get billingPayConfirm => 'Confirm payment';

  @override
  String get billingPayOverHint =>
      'This is more than the amount owed. The extra is kept as credit for the next period.';

  @override
  String get billingErrPayAmount =>
      'Enter an amount above 0 and up to 100.000.000.000 đ.';

  @override
  String get billingErrPayDate => 'The date is invalid or after today.';

  @override
  String get billingErrNotPayable =>
      'This invoice can no longer take payments (already paid, voided or not issued). We loaded the latest status.';

  @override
  String get billingPaymentRecorded => 'Payment recorded.';

  @override
  String get billingPaymentsTitle => 'Payments';

  @override
  String billingPaymentLine(String method, String date) {
    return '$method · $date';
  }

  @override
  String billingPaymentBy(String name, String when) {
    return 'Recorded by $name at $when';
  }

  @override
  String billingPaymentAt(String when) {
    return 'Recorded at $when';
  }

  @override
  String get billingPaymentVoidedLabel => 'Voided';

  @override
  String billingPaymentVoidedBy(String name, String reason) {
    return 'Voided by $name. Reason: $reason';
  }

  @override
  String billingPaymentVoidedReason(String reason) {
    return 'Void reason: $reason';
  }

  @override
  String get billingPaymentVoidAction => 'Void payment';

  @override
  String get billingPaymentVoidTitle => 'Void this payment?';

  @override
  String billingPaymentVoidBody(String amount) {
    return 'The $amount payment will no longer count toward the invoice. A reason is required.';
  }

  @override
  String get billingPaymentVoidDone => 'Payment voided.';

  @override
  String get billingPayNote => 'Note (only you can see it)';

  @override
  String get billingErrPayNote => 'The note can be up to 300 characters.';

  @override
  String billingPayRemainingChanged(String amount) {
    return 'The amount owed just changed and is now $amount. Check it and confirm again.';
  }

  @override
  String get billingErrPayDateVn =>
      'The date is not valid in Vietnam time (it cannot be after today). Check the date on your device.';

  @override
  String get billingNoReason => 'No reason given';

  @override
  String get receivablesTitle => 'Receivables';

  @override
  String get receivablesSearchHint => 'Search by student name';

  @override
  String receivablesTotalOwed(String amount) {
    return 'Total owed $amount';
  }

  @override
  String get receivablesBucketAll => 'All';

  @override
  String get receivablesBucket030 => '0–30 days';

  @override
  String get receivablesBucket3160 => '31–60 days';

  @override
  String get receivablesBucketOver60 => 'Over 60 days';

  @override
  String receivablesBucketChip(String name, String amount) {
    return '$name · $amount';
  }

  @override
  String get receivablesSortDesc => 'Highest owed first';

  @override
  String get receivablesSortAsc => 'Lowest owed first';

  @override
  String receivablesRowOwed(String amount) {
    return 'Owes $amount';
  }

  @override
  String receivablesInvoiceOutstanding(String amount) {
    return 'Open invoices: $amount';
  }

  @override
  String receivablesLedgerDebt(String amount) {
    return 'Owed on the ledger: $amount';
  }

  @override
  String receivablesLedgerCredit(String amount) {
    return 'Overpaid: $amount';
  }

  @override
  String get receivablesNetHint =>
      'Net debt after overpayment credit or ledger debt; amounts already carried to the next period are not counted twice.';

  @override
  String receivablesRowMeta(String classes, int invoices) {
    String _temp0 = intl.Intl.pluralLogic(
      invoices,
      locale: localeName,
      other: '$invoices invoices',
      one: '1 invoice',
    );
    return '$classes · $_temp0';
  }

  @override
  String receivablesOverdue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days overdue',
      one: '1 day overdue',
      zero: 'Not overdue',
    );
    return '$_temp0';
  }

  @override
  String get receivablesEmpty => 'Nobody owes anything';

  @override
  String get receivablesEmptyBody =>
      'Every issued invoice has been paid in full.';

  @override
  String get receivablesEmptyFiltered => 'No students match the filter.';

  @override
  String get receivablesLoadFailed => 'Could not load receivables.';

  @override
  String get receivablesMoreFailed => 'Could not load more.';

  @override
  String get receivablesDunningSettings => 'Reminder settings';

  @override
  String get receivablesDetailTitle => 'Student receivables';

  @override
  String get receivablesInvoices => 'Invoices';

  @override
  String get receivablesPayments => 'Payments';

  @override
  String get receivablesReminders => 'Reminders';

  @override
  String get receivablesNoInvoices => 'No invoices yet.';

  @override
  String get receivablesNoPayments => 'No payments yet.';

  @override
  String get receivablesNoReminders => 'No reminders yet.';

  @override
  String receivablesInvoiceTitle(String code, int month, int year) {
    return '$code · $month/$year';
  }

  @override
  String receivablesInvoiceDue(String date) {
    return 'Due $date';
  }

  @override
  String receivablesInvoiceRemaining(String remaining, String total) {
    return '$remaining left of $total';
  }

  @override
  String receivablesPaymentLine(String amount, String method) {
    return '$amount · $method';
  }

  @override
  String receivablesPaymentDate(String date) {
    return 'Paid on $date';
  }

  @override
  String get receivablesPaymentVoided => 'Voided';

  @override
  String receivablesReminderLine(String label, String code) {
    return '$label · invoice $code';
  }

  @override
  String get receivablesNoCode => 'no code';

  @override
  String dunningOffsetBefore(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0 before due';
  }

  @override
  String get dunningOffsetOn => 'On the due date';

  @override
  String dunningOffsetAfter(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0 after due';
  }

  @override
  String dunningStepSent(String time) {
    return 'Sent $time';
  }

  @override
  String dunningStepPending(String time) {
    return 'Scheduled $time';
  }

  @override
  String get dunningStepCancelled => 'Cancelled';

  @override
  String get dunningStudentTitle => 'Reminders';

  @override
  String get dunningStudentOn => 'Reminders are on';

  @override
  String get dunningStudentOff => 'Reminders are off';

  @override
  String get dunningStudentHint =>
      'A student gets no reminders only when every current class is switched off.';

  @override
  String dunningClassSwitch(String className) {
    return 'Reminders for $className';
  }

  @override
  String get dunningToggledOn => 'Reminders turned on.';

  @override
  String get dunningToggledOff => 'Reminders turned off.';

  @override
  String get rosterDunningAction => 'Reminders';

  @override
  String rosterDunningTitle(String student) {
    return 'Reminders for $student';
  }

  @override
  String get invoiceDunningTitle => 'Payment reminders';

  @override
  String invoiceDunningLastSent(String time) {
    return 'Last reminded $time';
  }

  @override
  String get invoiceDunningNone => 'No reminder sent yet.';

  @override
  String invoiceDunningNext(String time) {
    return 'Next reminder: $time';
  }

  @override
  String get dunningReasonTenant =>
      'Reminders are turned off in your general settings.';

  @override
  String get dunningReasonStudent => 'Reminders are off for this student.';

  @override
  String get dunningReasonPaid => 'Paid in full, no more reminders.';

  @override
  String get dunningReasonVoid => 'Invoice voided, no more reminders.';

  @override
  String get dunningLoadFailed => 'Could not load the reminder status.';

  @override
  String get dunningSettingsTitle => 'Reminder settings';

  @override
  String get dunningSettingsEnabled => 'Automatic reminders';

  @override
  String get dunningSettingsEnabledHint =>
      'Reminds parents as an invoice nears or passes its due date. Sent between 07:00 and 21:30.';

  @override
  String get dunningSettingsOffsets => 'Reminder schedule';

  @override
  String get dunningSettingsOffsetsHint =>
      'Days relative to the due date. Changes only apply to invoices issued after you save.';

  @override
  String get dunningOffsetInput => 'Add a day (relative to due date)';

  @override
  String get dunningOffsetAdd => 'Add';

  @override
  String get dunningOffsetReset => 'Reset to default';

  @override
  String get dunningOffsetPreview => 'Preview';

  @override
  String get dunningOffsetRemove => 'Remove';

  @override
  String get dunningOffsetErrNumber => 'Enter a whole number.';

  @override
  String get dunningOffsetErrRange => 'Use a value from −7 to 30 days.';

  @override
  String get dunningOffsetErrDuplicate => 'That day is already in the list.';

  @override
  String get dunningOffsetErrTooMany => 'At most 6 reminders.';

  @override
  String get dunningOffsetErrTooFew => 'Keep at least one reminder.';

  @override
  String get dunningSave => 'Save';

  @override
  String get dunningSaved => 'Reminder settings saved.';

  @override
  String get dunningPreviewTitle => 'Sample reminder';

  @override
  String get dunningPreviewFailed => 'Could not load the sample.';

  @override
  String get dunningPreviewNote => 'Sample data, not a real name or amount.';

  @override
  String get dunningStepOther => 'Other status';

  @override
  String receivablesAgingLine(String bucket, String overdue) {
    return '$bucket · $overdue';
  }

  @override
  String receivablesPaymentMetaCode(String date, String code) {
    return 'Paid on $date · $code';
  }

  @override
  String dunningStepLine(String label, String status) {
    return '$label · $status';
  }

  @override
  String get receivablesClassAll => 'All classes';

  @override
  String receivablesClassFilter(String name) {
    return 'Class: $name';
  }

  @override
  String get receivablesClassPick => 'Choose a class';

  @override
  String get dunningDiscardTitle => 'Discard unsaved changes?';

  @override
  String get dunningDiscardBody =>
      'The reminder settings you changed will be lost.';

  @override
  String get dunningDiscardConfirm => 'Discard';

  @override
  String get dunningDiscardKeep => 'Keep editing';
}
