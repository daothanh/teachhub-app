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
}
