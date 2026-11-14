// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Tasco Shell';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get home => 'Home';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Something went wrong';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get search => 'Search';

  @override
  String get noData => 'No data';

  @override
  String get tabHome => 'Home';

  @override
  String get tabExplore => 'Explore';

  @override
  String get tabNotification => 'Notifications';

  @override
  String get tabProfile => 'Profile';

  @override
  String get greetingMorning => 'Good morning 👋';

  @override
  String get greetingAfternoon => 'Good afternoon 👋';

  @override
  String get greetingEvening => 'Good evening 👋';

  @override
  String get homeQuickAccess => 'Quick Access';

  @override
  String get homeOverview => 'Overview';

  @override
  String get homeMenuHrProfile => 'HR\nProfile';

  @override
  String get homeMenuTraining => 'Training &\nDevelopment';

  @override
  String get homeMenuEvaluation => 'Employee\nEvaluation';

  @override
  String get homeMenuCareerPath => 'Career\nRoadmap';

  @override
  String get homeMenuCrossSale => 'Ecosystem\nCross-sale';

  @override
  String get homeMenuSuggestions => 'Innovation\nIdeas';

  @override
  String get homeMenuFavorites => 'Favor-\nites';

  @override
  String get homeMenuViewMore => 'View\nMore';

  @override
  String get homeStatInsuranceOrders => 'Insurance Orders';

  @override
  String get homeStatPending => 'Pending';

  @override
  String get homeStatTodayTasks => 'Today\'s Tasks';

  @override
  String get homeStatNewNotifications => 'New Alerts';

  @override
  String get underConstructionTitle => 'Feature Under Development';

  @override
  String get underConstructionMessage =>
      'This feature is currently under construction and will be available in the next release.';

  @override
  String get understood => 'Understood';

  @override
  String get demoModuleTitle => 'VueJS Mini App';

  @override
  String get demoModuleSubtitle => 'Web bundle mounted via ModuleSlot demo';

  @override
  String get notificationTitle => 'Notifications';

  @override
  String get notificationMarkAllAsRead => 'Mark all as read';

  @override
  String get notificationFilterAll => 'All';

  @override
  String get notificationFilterSystem => 'System';

  @override
  String get notificationFilterTransaction => 'Transactions';

  @override
  String get notificationFilterMiniApps => 'Mini Apps';

  @override
  String get notificationEmptyTitle => 'No notifications';

  @override
  String get notificationEmptyMessage =>
      'You don\'t have any notifications in this category.';

  @override
  String timeMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String timeHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String timeDaysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get profileStandardUser => 'Standard User';

  @override
  String get profilePermissionsTitle => 'Access Permissions';

  @override
  String get profileStandardUserPermissions => 'STANDARD USER PERMISSIONS';

  @override
  String profileRole(String role) {
    return 'Role: $role';
  }

  @override
  String profilePermissionsCount(int count) {
    return '$count permissions';
  }

  @override
  String profileShowMore(int count) {
    return 'Show more ($count permissions) ▼';
  }

  @override
  String get profileShowLess => 'Show less ▲';

  @override
  String get profileSettings => 'Settings';

  @override
  String get profileNoPermissions => 'No permissions granted';

  @override
  String get loginWelcomeTitle => 'Welcome back! 👋';

  @override
  String get loginWelcomeSubtitle =>
      'Sign in to continue exploring the Tasco ecosystem';

  @override
  String get loginSsoOr => 'OR SIGN IN WITH';

  @override
  String get loginGoogle => 'Google';

  @override
  String get loginApple => 'Apple';

  @override
  String get loginCorporateSso => 'Corporate SSO';

  @override
  String get loginBiometric => 'Biometric Login';

  @override
  String get loginUsernameRequired => 'Please enter your username';

  @override
  String get loginPasswordRequired => 'Please enter your password';

  @override
  String get loginFailed => 'Login failed. Please check your credentials.';

  @override
  String get loginNetworkError =>
      'Can\'t reach the server. Please check your connection and try again.';

  @override
  String get settings => 'Settings';

  @override
  String get settingsSecurity => 'Security & Authentication';

  @override
  String get settingsBiometricTitle => 'Biometric Login';

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
  String get settingsBiometricAuthReason =>
      'Verify your identity to enable biometric login';

  @override
  String get settingsBiometricEnabled => 'Biometric login enabled';

  @override
  String get settingsBiometricDisabled => 'Biometric login disabled';

  @override
  String get settingsBiometricFailed => 'Biometric verification failed';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsTheme => 'Appearance';

  @override
  String get settingsThemeSystem => 'System default';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAboutApp => 'Application';

  @override
  String get settingsAboutVersion => 'Version';

  @override
  String get settingsAboutEnv => 'Environment';

  @override
  String get settingsAboutTerms => 'Terms of Use';

  @override
  String get splashTagline => 'Tasco Ecosystem';

  @override
  String get splashCopyright => '© 2026 Tasco Joint Stock Company';
}
