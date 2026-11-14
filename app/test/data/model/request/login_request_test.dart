import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/config/client_identity.dart';
import 'package:app/data/model/request/login_request.dart';

void main() {
  const client = ClientIdentity(
    appVersion: '3.4.5',
    deviceId: '0b7e4f1c-3c5d-4e8a-9f10-2a3b4c5d6e7f',
    deviceType: 'android',
    deviceName: 'Android',
  );

  group('LoginRequest.toJson', () {
    test('sends the credentials, the auth client and this installation', () {
      const request = LoginRequest(
        username: 'user',
        password: 'secret',
        clientId: 'PRODUCT_CLIENT',
        client: client,
      );

      expect(request.toJson(), {
        'clientId': 'PRODUCT_CLIENT',
        'deviceId': '0b7e4f1c-3c5d-4e8a-9f10-2a3b4c5d6e7f',
        'deviceName': 'Android',
        'deviceType': 'android',
        'isSecure': false,
        'username': 'user',
        'password': 'secret',
      });
    });

    test('leaves clientId out while AUTH_CLIENT_ID is unset', () {
      const request = LoginRequest(
        username: 'user',
        password: 'secret',
        clientId: '',
        client: client,
      );

      expect(request.toJson().containsKey('clientId'), isFalse);
    });

    test('sends no socketId', () {
      // The app holds no socket connection; the field used to carry Swagger's
      // example value, 'string'.
      const request = LoginRequest(
        username: 'user',
        password: 'secret',
        clientId: 'PRODUCT_CLIENT',
        client: client,
      );

      expect(request.toJson().containsKey('socketId'), isFalse);
    });
  });
}
