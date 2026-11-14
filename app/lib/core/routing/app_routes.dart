import 'package:teachhub_shared/teachhub_shared.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const rolePicker = TeachHubRoutes.rolePicker;
  static const settings = '/settings';
  static const invitePattern = '/invite/:token';
  static String invite(String token) => '/invite/$token';
}
