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
  String get loginSubtitle =>
      'Sign in with email, Google or Apple. No password needed.';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginEmailHint => 'you@example.com';

  @override
  String get loginEmailInvalid => 'Enter a valid email.';

  @override
  String get loginSendOtp => 'Send sign-in code';

  @override
  String get loginOr => 'or';

  @override
  String get loginGoogle => 'Continue with Google';

  @override
  String get loginApple => 'Continue with Apple';

  @override
  String loginOtpSentTo(String email) {
    return 'Enter the 6-digit code sent to $email';
  }

  @override
  String get loginOtpCode => 'Sign-in code';

  @override
  String get loginResend => 'Resend code';

  @override
  String loginResendIn(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get loginChangeEmail => 'Change email';

  @override
  String get loginOtpInvalid => 'The code is wrong or has expired.';

  @override
  String get loginRateLimited => 'Too many attempts, please try again later.';

  @override
  String get loginFailed => 'Sign-in failed. Please try again.';

  @override
  String get splashLoadFailed => 'Could not load your roles.';

  @override
  String get roleTitle => 'Roles';

  @override
  String get roleYours => 'Your roles';

  @override
  String get roleWhoAreYou => 'Who are you?';

  @override
  String get roleAdd => 'Add a role';

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
  String get loading => 'Loading...';

  @override
  String get login => 'Login';
}
