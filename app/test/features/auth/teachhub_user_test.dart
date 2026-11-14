import 'package:app/features/auth/auth_config.dart';
import 'package:app/features/auth/teachhub_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const json = {
    'id': 'u1',
    'email': 'lan@example.com',
    'displayName': 'Cô Lan',
    'permissions': ['role:tenant_owner'],
  };

  test('login body: user sits under `user`', () {
    final user = teachHubAuthConfig.parseLoginUser({
      'access_token': 'a',
      'refresh_token': 'r',
      'user': json,
    });
    expect(user.id, 'u1');
    expect(user.permissions, ['role:tenant_owner']);
  });

  test('me body is the user itself and round-trips through storage', () {
    final user = teachHubAuthConfig.parseProfileUser(json);
    final again = TeachHubUser.fromJson(user.toJson());
    expect(again.email, 'lan@example.com');
    expect(again.displayName, 'Cô Lan');
  });

  test('email OTP credentials match the API body', () {
    expect(emailOtpCredentials(email: 'a@b.vn', code: '123456'), {
      'method': 'email_otp',
      'email': 'a@b.vn',
      'code': '123456',
    });
  });
}
