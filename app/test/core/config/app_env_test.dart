import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/config/app_env.dart';
import 'package:tasco_core/tasco_core.dart';

void main() {
  test('reads the API url, pins and Google server client id', () {
    final env = AppEnv(Env.staging, {
      'TEACHHUB_API_URL': ' https://api-stg.teachhub.vn/v1 ',
      'CERT_PINS': 'aa, bb,,aa',
      'GOOGLE_SERVER_CLIENT_ID': 'web.apps.googleusercontent.com',
    });
    expect(env.apiUrl, 'https://api-stg.teachhub.vn/v1');
    expect(env.certificatePins, {'aa', 'bb'});
    expect(env.googleServerClientId, 'web.apps.googleusercontent.com');
    expect(env.isProduction, isFalse);
  });

  test('fails fast when the API url is missing', () {
    expect(() => AppEnv(Env.production, {}), throwsStateError);
  });

  test('blank optional values read as unset', () {
    final env = AppEnv(Env.production, {
      'TEACHHUB_API_URL': 'https://api.teachhub.vn/v1',
      'GOOGLE_SERVER_CLIENT_ID': ' ',
    });
    expect(env.googleServerClientId, isNull);
    expect(env.certificatePins, isEmpty);
    expect(env.isProduction, isTrue);
  });

  test(
    '--dart-define TEACHHUB_API_URL ghi đè ở dev/staging, không ở production',
    () {
      const file = {'TEACHHUB_API_URL': 'https://api.teachhub.vn/v1'};
      const mock = 'http://localhost:4010/v1';
      expect(
        AppEnv.withApiOverride(Env.development, file, mock)['TEACHHUB_API_URL'],
        mock,
      );
      expect(
        AppEnv.withApiOverride(Env.production, file, mock)['TEACHHUB_API_URL'],
        'https://api.teachhub.vn/v1',
      );
      expect(AppEnv.withApiOverride(Env.staging, file, ''), file);
    },
  );
}
