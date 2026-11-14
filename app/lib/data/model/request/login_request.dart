import '../../../core/config/client_identity.dart';

/// Body of the password sign-in sent to `AuthConfig.loginPath`.
///
/// Besides what the user typed, it names the auth client this app signs in as
/// and the installation it signs in from, the same one the Dio clients
/// announce in `X-Device-Info`.
final class LoginRequest {
  const LoginRequest({
    required this.username,
    required this.password,
    required this.clientId,
    required this.client,
  });

  final String username;
  final String password;

  /// The auth client this app signs in as (`AUTH_CLIENT_ID`); empty while
  /// unset.
  final String clientId;

  final ClientIdentity client;

  Map<String, dynamic> toJson() => {
    // Left out while unset, so an unconfigured app is refused rather than
    // signing in as some other app's client.
    if (clientId.isNotEmpty) 'clientId': clientId,
    ...client.deviceInfo,
    // Part of the sign-in contract. Nothing in this app sets it, so it is
    // always false.
    'isSecure': false,
    // No `socketId`: the app holds no socket connection, and the value sent
    // here before was the Swagger example string.
    'username': username,
    'password': password,
  };
}
