// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'TeachHub';

  @override
  String get retry => 'Retry';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginEmailHint => 'name@email.com';

  @override
  String get loginEmailInvalid => 'Email is not valid, e.g. name@gmail.com';

  @override
  String get loginSendOtp => 'Send sign-in code';

  @override
  String get loginGoogle => 'Continue with Google';

  @override
  String get loginApple => 'Continue with Apple';

  @override
  String get loginResend => 'Resend code';

  @override
  String get loginChangeEmail => 'Change email';

  @override
  String get loginRateLimited => 'Too many attempts, please try again later.';

  @override
  String get loginFailed => 'Sign-in failed. Please try again.';

  @override
  String get splashLoadFailed => 'Could not load your roles.';

  @override
  String get roleWhoAreYou => 'Who are you?';

  @override
  String get roleTeacher => 'Teacher';

  @override
  String get roleParent => 'Parent';

  @override
  String get roleStudent => 'Student';

  @override
  String get roleAddFailed => 'Could not add the role. Please try again.';

  @override
  String get inviteTitle => 'Class invitation';

  @override
  String get inviteBody =>
      'A teacher invited you to connect with your child\'s class.';

  @override
  String get inviteAccept => 'Accept invitation';

  @override
  String get inviteInvalid => 'This invitation does not exist or has expired.';

  @override
  String get inviteFailed =>
      'Could not accept the invitation. Please try again.';

  @override
  String get inviteConsentTitle => 'Data processing consent';

  @override
  String get inviteConsentBody =>
      'To see your child\'s learning information, you need to agree to TeachHub\'s terms and personal data policy.';

  @override
  String get inviteConsentAccept => 'Agree and accept';

  @override
  String get settings => 'Settings';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAboutApp => 'Application';

  @override
  String get settingsAboutEnv => 'Environment';

  @override
  String get settingsAboutTerms => 'Terms of Use';

  @override
  String get settingsAboutVersion => 'Version';

  @override
  String get settingsBiometricAuthReason =>
      'Verify your identity to enable biometric login';

  @override
  String get settingsBiometricDisabled => 'Biometric login disabled';

  @override
  String get settingsBiometricEnabled => 'Biometric login enabled';

  @override
  String get settingsBiometricFailed => 'Biometric verification failed';

  @override
  String get settingsBiometricSubtitleAvailable =>
      'Face ID / Touch ID for subsequent app opens';

  @override
  String get settingsBiometricSubtitleNotEnrolled =>
      'Go to device Settings to register Face ID / Touch ID';

  @override
  String get settingsBiometricSubtitleUnsupported =>
      'Device does not support biometrics';

  @override
  String get settingsBiometricTitle => 'Biometric Login';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsSecurity => 'Security & Authentication';

  @override
  String get settingsTheme => 'Appearance';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeSystem => 'System default';

  @override
  String get logout => 'Logout';

  @override
  String logoutPendingTitle(int count) {
    return '$count sessions not synced yet';
  }

  @override
  String get logoutPendingBody =>
      'Logging out now deletes them from this device. Connect to the internet to sync first.';

  @override
  String get logoutPendingConfirm => 'Log out anyway';

  @override
  String get logoutPendingCancel => 'Stay';

  @override
  String get loading => 'Loading...';

  @override
  String get loginSlogan => 'Connecting teachers, students and families.';

  @override
  String get loginTagline => 'Tutoring classes, made simple.';

  @override
  String get loginOrEmail => 'or use email';

  @override
  String get loginEmailHelper => 'We send a 6-digit code, no password needed.';

  @override
  String get loginSending => 'Sending code…';

  @override
  String get loginTermsPrefix => 'By continuing you agree to the ';

  @override
  String get loginTerms => 'Terms of use';

  @override
  String get loginTermsAnd => ' and ';

  @override
  String get loginPrivacy => 'Data policy';

  @override
  String get loginTermsSuffix => ' of TeachHub.';

  @override
  String get heroTeacher => 'Teacher';

  @override
  String get heroStudent => 'Student';

  @override
  String get heroFamily => 'Family';

  @override
  String get heroAttended => 'Attended';

  @override
  String get heroInvoiceSent => 'Invoice sent';

  @override
  String get heroAbsenceReported => 'Absence reported';

  @override
  String get otpTitle => 'Verify email';

  @override
  String get otpHeading => 'Enter verification code';

  @override
  String otpSentTo(String email) {
    return '6-digit code sent to $email';
  }

  @override
  String get otpCodeLabel => '6-digit verification code';

  @override
  String get otpConfirm => 'Confirm';

  @override
  String get otpVerifying => 'Verifying…';

  @override
  String otpResendIn(String time) {
    return 'Resend code in $time';
  }

  @override
  String get otpInvalid => 'Wrong code.';

  @override
  String otpInvalidAttempts(int count) {
    return 'Wrong code. $count attempts left.';
  }

  @override
  String get otpLockedTitle => '5 wrong attempts';

  @override
  String get otpLockedBody =>
      'Verification is locked for 15 minutes to protect your account.';

  @override
  String otpRetryIn(String time) {
    return 'Try again in $time';
  }

  @override
  String get otpLocked => 'Locked';

  @override
  String get roleIntro =>
      'Choose so TeachHub shows what you need. You can add other roles later.';

  @override
  String get roleTeacherDesc => 'Manage classes, attendance, tuition';

  @override
  String get roleParentDesc => 'Follow your child\'s learning, pay tuition';

  @override
  String get roleStudentDesc => 'View schedule, submit work, see grades';

  @override
  String get roleCenterOwner => 'Center owner';

  @override
  String get roleCenterOwnerDesc => 'Manage many teachers and classes';

  @override
  String get roleComingSoon => 'Coming soon';

  @override
  String get roleSelected => 'Selected';

  @override
  String get roleOwned => 'Already yours';

  @override
  String get roleContinue => 'Continue';

  @override
  String get updateTitle => 'Update TeachHub';

  @override
  String get updateBody =>
      'This version is no longer supported. Please update to continue.';

  @override
  String get updateAction => 'Update';

  @override
  String get roleSwitchTitle => 'Switch role';

  @override
  String get roleAdd => 'Add a role';

  @override
  String roleSwitchedTo(String role) {
    return 'Now in the $role role';
  }
}
