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
  String get spaceComingSoon => 'This space is under construction.';

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
}
