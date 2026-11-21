import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/config/app_env.dart';
import 'package:tasco_core/tasco_core.dart';

void main() {
  googleClientIdPerFlavorTests();
  test('reads the API url, pins and Google server client id', () {
    final env = AppEnv(Env.staging, {
      'TEACHHUB_API_URL': ' https://api-staging.dayhoc.app/v1 ',
      'CERT_PINS': 'aa, bb,,aa',
      'GOOGLE_SERVER_CLIENT_ID': 'web.apps.googleusercontent.com',
    });
    expect(env.apiUrl, 'https://api-staging.dayhoc.app/v1');
    expect(env.certificatePins, {'aa', 'bb'});
    expect(env.googleServerClientId, 'web.apps.googleusercontent.com');
    expect(env.isProduction, isFalse);
  });

  test('fails fast when the API url is missing', () {
    expect(() => AppEnv(Env.production, {}), throwsStateError);
  });

  test('blank optional values read as unset', () {
    final env = AppEnv(Env.production, {
      'TEACHHUB_API_URL': 'https://api.dayhoc.app/v1',
      'GOOGLE_SERVER_CLIENT_ID': ' ',
    });
    expect(env.googleServerClientId, isNull);
    expect(env.certificatePins, isEmpty);
    expect(env.isProduction, isTrue);
  });

  test(
    '--dart-define TEACHHUB_API_URL ghi đè ở dev/staging, không ở production',
    () {
      const file = {'TEACHHUB_API_URL': 'https://api.dayhoc.app/v1'};
      const mock = 'http://localhost:4010/v1';
      expect(
        AppEnv.withApiOverride(Env.development, file, mock)['TEACHHUB_API_URL'],
        mock,
      );
      expect(
        AppEnv.withApiOverride(Env.production, file, mock)['TEACHHUB_API_URL'],
        'https://api.dayhoc.app/v1',
      );
      expect(AppEnv.withApiOverride(Env.staging, file, ''), file);
    },
  );
}

void googleClientIdPerFlavorTests() {
  const web = {
    'development':
        '305225338991-7vf98anmjogm9jksgd9kdije4ah8ncgk.apps.googleusercontent.com',
    'staging':
        '753323722874-khh3u3aobf813cib4l2m6bvotebld0q7.apps.googleusercontent.com',
    'production':
        '432762025168-e2lo4mengjqb64e8bc2sdoat1vbqpdl8.apps.googleusercontent.com',
  };
  for (final env in Env.values) {
    test('assets/.env.${env.name} có Web client ID đúng flavor', () {
      final text = File('assets/.env.${env.name}').readAsStringSync();
      expect(text, contains('GOOGLE_SERVER_CLIENT_ID=${web[env.name]}'));
    });
  }
}
