import 'package:tasco_auth/tasco_auth.dart';

import 'teachhub_user.dart';

/// Endpoint xác thực của TeachHub API, đúng đường dẫn mặc định của
/// `tasco_auth` (spec §2.11 G1), tương đối với base URL `/v1`.
final teachHubAuthConfig = AuthConfig<TeachHubUser>(
  loginPath: '/auth/login',
  refreshPath: '/auth/refresh',
  mePath: '/auth/me',
  logoutPath: '/auth/logout',
  ssoPathBuilder: (provider) => '/auth/sso/$provider',
  parseLoginUser: (body) =>
      TeachHubUser.fromJson(body['user'] as Map<String, dynamic>),
  parseProfileUser: TeachHubUser.fromJson,
);

/// Body `POST /auth/login` cho email OTP (T01a).
Map<String, dynamic> emailOtpCredentials({
  required String email,
  required String code,
}) => {'method': 'email_otp', 'email': email, 'code': code};
