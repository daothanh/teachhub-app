import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/config/app_env.dart';
import 'package:tasco_core/tasco_core.dart';

// Loads a specific .env file for each Env variant.
// In the test environment, the real asset files exist under apps/shell/assets/.
void main() {
  group('AppEnv', () {
    tearDown(() => dotenv.clean());

    test(
      'current=development, isDevelopment=true, isProduction=false',
      () async {
        final env = AppEnv();
        await env.init(Env.development);

        expect(env.current, Env.development);
        expect(env.isDevelopment, isTrue);
        expect(env.isProduction, isFalse);
      },
    );

    test('current=staging, isDevelopment=false, isProduction=false', () async {
      final env = AppEnv();
      await env.init(Env.staging);

      expect(env.current, Env.staging);
      expect(env.isDevelopment, isFalse);
      expect(env.isProduction, isFalse);
    });

    test(
      'current=production, isProduction=true, isDevelopment=false',
      () async {
        final env = AppEnv();
        await env.init(Env.production);

        expect(env.current, Env.production);
        expect(env.isProduction, isTrue);
        expect(env.isDevelopment, isFalse);
      },
    );

    test('url getters return string (empty or non-empty) from dotenv', () async {
      final env = AppEnv();
      await env.init(Env.development);

      // Values come from real .env.development; we only check the type contract.
      expect(env.authUrl, isA<String>());
      expect(env.crmUrl, isA<String>());
      expect(env.hrmUrl, isA<String>());
      expect(env.ticketUrl, isA<String>());
    });

    // The client identity is product data too: a generated app starts with
    // these keys blank, and blank must read as "not configured", not as a
    // value to send.
    group('client identity keys', () {
      test('are read from AUTH_CLIENT_ID and CLIENT_SOURCE', () {
        dotenv.testLoad(
          fileInput: 'AUTH_CLIENT_ID=PRODUCT_CLIENT\nCLIENT_SOURCE=app_Product',
        );

        expect(AppEnv().authClientId, 'PRODUCT_CLIENT');
        expect(AppEnv().clientSource, 'app_Product');
      });

      test('are empty while unset', () {
        dotenv.testLoad(fileInput: 'AUTH_URL=https://api.test');

        expect(AppEnv().authClientId, isEmpty);
        expect(AppEnv().clientSource, isEmpty);
      });
    });

    // Pins are the product's data, so the app supplies them per flavor. What
    // matters here is that a malformed or absent value degrades to "no pins"
    // rather than to a pin set containing junk — a junk pin would reject every
    // certificate and take the app offline.
    group('certificatePins', () {
      test('absent CERT_PINS means no pinning', () async {
        dotenv.testLoad(fileInput: 'AUTH_URL=https://api.test');

        expect(AppEnv().certificatePins, isEmpty);
      });

      test('an empty CERT_PINS means no pinning', () async {
        dotenv.testLoad(fileInput: 'CERT_PINS=');

        expect(AppEnv().certificatePins, isEmpty);
      });

      test('a single pin is read', () async {
        dotenv.testLoad(fileInput: 'CERT_PINS=aabbcc');

        expect(AppEnv().certificatePins, <String>{'aabbcc'});
      });

      test('several pins are split and trimmed', () async {
        // Two pins is the normal case: current leaf plus the next one, so a
        // certificate rotation does not brick installed apps.
        dotenv.testLoad(fileInput: 'CERT_PINS= aabbcc , AA:BB:CC ');

        expect(AppEnv().certificatePins, <String>{'aabbcc', 'AA:BB:CC'});
      });

      test('blank entries are dropped, not turned into empty pins', () async {
        dotenv.testLoad(fileInput: 'CERT_PINS=aabbcc,,  ,');

        expect(AppEnv().certificatePins, <String>{'aabbcc'});
      });

      test('the shipped .env files parse to a pin set', () async {
        final env = AppEnv();
        await env.init(Env.production);

        expect(env.certificatePins, isA<Set<String>>());
      });
    });
  });
}
