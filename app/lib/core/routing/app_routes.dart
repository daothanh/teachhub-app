import 'package:teachhub_shared/teachhub_shared.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const rolePicker = TeachHubRoutes.rolePicker;
  static const settings = '/settings';
  static const centerWaitlist = '/center-waitlist';
  static const updateRequired = '/update-required';
  static const inviteEntry = TeachHubRoutes.inviteEntry;
  static const inviteScan = '/invite/scan';
  static const consent = '/consent';
  static const invitePattern = '/invite/:token';
  static String invite(String token) => '/invite/$token';
}
