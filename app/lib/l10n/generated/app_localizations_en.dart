// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'DayHoc';

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
  String get loginUnavailable =>
      'The service is busy, please try again in a few minutes.';

  @override
  String get loginEmailRequiresOtp =>
      'This email needs a one-time code to sign in. Enter it below to get a code.';

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
  String get inviteAccept => 'Accept invitation';

  @override
  String inviteCardTitle(String teacher) {
    return 'Invitation from $teacher';
  }

  @override
  String inviteCardBody(String teacher, String student, String expires) {
    return '$teacher invites you to see $student\'s learning information. The link is valid until $expires.';
  }

  @override
  String get inviteInvalid =>
      'This invitation link has expired or can no longer be used. Message the teacher for a new link.';

  @override
  String get inviteEntryTitle => 'You need an invitation from a teacher';

  @override
  String get inviteEntryBody =>
      'Your child\'s teacher will send you a link, a code or a QR code. The app cannot search for students by name, school or phone number.';

  @override
  String get inviteScanQr => 'Scan QR code';

  @override
  String get inviteInputLabel => 'Paste the link or enter the invitation code';

  @override
  String get inviteInputSubmit => 'Continue';

  @override
  String get inviteInputBad =>
      'Link or code not recognised. Paste the whole link, or enter the 8-character code.';

  @override
  String get inviteCodeInvalid =>
      'The code is wrong or has expired. Message the teacher for a new code.';

  @override
  String inviteCodeLocked(int minutes) {
    return 'Too many wrong attempts. Try again in $minutes minutes.';
  }

  @override
  String get inviteRateLimited =>
      'You are going too fast, please try again later.';

  @override
  String get inviteAskTeacher => 'Message the teacher for a link';

  @override
  String get inviteAskMessage =>
      'Hello, I am a parent. Could you please resend the DayHoc invitation link so I can see my child\'s information? Thank you.';

  @override
  String get inviteAskCopied =>
      'Message copied. Paste it into Zalo to send it to the teacher.';

  @override
  String get inviteScanTitle => 'Scan the invitation QR code';

  @override
  String get inviteScanHint => 'Point the camera at the QR code.';

  @override
  String get inviteScanDenied =>
      'The app is not allowed to use the camera. You can paste the link or enter the code instead.';

  @override
  String get inviteScanNotInvite => 'This QR code is not a DayHoc invitation.';

  @override
  String get consentTitle => 'Consent to data processing';

  @override
  String get consentBody =>
      'To see your child\'s learning information, you need to agree that DayHoc processes your and your child\'s personal data under the terms and privacy policy.';

  @override
  String consentVersion(String version) {
    return 'Terms version: $version';
  }

  @override
  String get consentAccept => 'Agree and continue';

  @override
  String get consentTermsChanged =>
      'The terms were just updated. Please read them again, then agree.';

  @override
  String get consentFailed => 'Could not send. Please try again.';

  @override
  String get consentLoadFailed => 'Could not load the terms. Please try again.';

  @override
  String get inviteFailed =>
      'Could not accept the invitation. Please try again.';

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
  String get logoutUnreadableTitle => 'Can\'t read unsynced data';

  @override
  String get logoutUnreadableBody =>
      'If you log out, data on this device is deleted and unsynced sessions may be lost.';

  @override
  String get logoutWipeFailed =>
      'Logged out, but some data on this device wasn\'t deleted. The app will retry next time it opens.';

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
  String get loginTermsSuffix => ' of DayHoc.';

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
      'Choose so DayHoc shows what you need. You can add other roles later.';

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
  String get updateTitle => 'Update DayHoc';

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

  @override
  String get waitlistTitle => 'Early sign-up for Center owners';

  @override
  String get waitlistIntro =>
      'Center features are coming. Leave your details and we will contact you when ready.';

  @override
  String get waitlistCenterName => 'Center name';

  @override
  String get waitlistCenterNameRequired => 'Enter the center name.';

  @override
  String get waitlistTeacherCount => 'Number of teachers';

  @override
  String get waitlistTeacherCountInvalid => 'Enter a number from 1 to 1000.';

  @override
  String get waitlistSubmit => 'Send';

  @override
  String get waitlistTrialHint =>
      'While you wait, you can try the Teacher role.';

  @override
  String get waitlistTrialAction => 'Try the Teacher role';

  @override
  String get waitlistSent => 'Request received';

  @override
  String get waitlistSentBody => 'Thank you. We will be in touch soon.';

  @override
  String get waitlistErrorBusy => 'Still processing. Try again in a moment.';

  @override
  String get waitlistErrorValidation =>
      'Some details are invalid. Check the fields.';

  @override
  String get waitlistErrorNetwork => 'No connection. Try again later.';

  @override
  String get waitlistErrorGeneric => 'Could not send. Try again later.';

  @override
  String get settingsAccount => 'Account';

  @override
  String get deleteAccountEntry => 'Delete account';

  @override
  String get deleteAccountEntrySubtitle =>
      'Permanently delete your account and personal data';

  @override
  String get deleteAccountTitle => 'Delete account';

  @override
  String get deleteAccountWarnHeading => 'This cannot be undone';

  @override
  String deleteAccountWarnBody(String email) {
    return 'The account $email and your personal data will be deleted. Signing in again with this email creates a new account with none of the old data. Financial records are kept as required by regulation.';
  }

  @override
  String deleteAccountPendingWarn(int count) {
    return 'This device has $count unsynced items (attendance, changes). Deleting the account will lose them.';
  }

  @override
  String get deleteAccountUnreadableWarn =>
      'Could not check for unsynced data on this device. If there is any, it will be lost.';

  @override
  String get deleteAccountSendCode => 'Send confirmation code';

  @override
  String get deleteAccountSending => 'Sending code…';

  @override
  String get deleteAccountCodeHeading => 'Enter the confirmation code';

  @override
  String deleteAccountCodeSent(String email) {
    return 'A 6-digit code was sent to $email. It is valid for 5 minutes.';
  }

  @override
  String get deleteAccountConfirm => 'Delete account permanently';

  @override
  String get deleteAccountDeleting => 'Deleting…';

  @override
  String get deleteAccountResend => 'Resend code';

  @override
  String get deleteAccountErrNetwork => 'No connection. Try again later.';

  @override
  String deleteAccountErrRateLimited(int seconds) {
    return 'Too many codes requested. Try again in $seconds seconds.';
  }

  @override
  String get deleteAccountErrRateLimitedNoTime =>
      'Too many codes requested. Try again in a few minutes.';

  @override
  String get deleteAccountErrOwnerHasStaff =>
      'You own a workspace that still has other teachers. Transfer ownership or remove them before deleting your account.';

  @override
  String get deleteAccountErrActiveClasses =>
      'You still have active classes. Archive all classes before deleting your account.';

  @override
  String get deleteAccountErrStale =>
      'Data just changed. Reopen this screen and try again.';

  @override
  String get deleteAccountErrGeneric =>
      'Could not delete the account. Try again later.';

  @override
  String get consentLater => 'Later';
}
