import 'package:teachhub_shared/teachhub_shared.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const rolePicker = TeachHubRoutes.rolePicker;
  static const settings = TeachHubRoutes.settings;
  static const deleteAccount = '/settings/delete-account';
  static const centerWaitlist = '/center-waitlist';
  static const updateRequired = '/update-required';
  static const inviteEntry = TeachHubRoutes.inviteEntry;
  static const inviteScan = '/invite/scan';

  /// Thẻ lời mời mở từ P05; token truyền qua `extra`.
  static const inviteCard = '/invite/card';
  static const consent = '/consent';
  static const invitePattern = '/invite/:token';
  static String invite(String token) => '/invite/$token';
}
