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
  String get studentsRemoveGuardian => 'Remove parent';

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
}
