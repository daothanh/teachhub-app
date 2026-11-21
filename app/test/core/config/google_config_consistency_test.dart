import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Kiểm chéo cấu hình Google Sign-In giữa các file theo flavor, để lẫn môi
/// trường (dev dùng client của staging…) làm test đỏ.
const _flavors = {
  'development': 'vn.dayhoc.app.dev',
  'staging': 'vn.dayhoc.app.stg',
  'production': 'vn.dayhoc.app',
};
const _suffix = '.apps.googleusercontent.com';

String _plistValue(String plist, String key) => RegExp(
  '<key>$key</key>\\s*<string>([^<]*)</string>',
).firstMatch(plist)!.group(1)!;

/// Build setting `name` của các configuration `*-<flavor>` của target Runner
/// (bundle id = [bundleId]); trả về tập giá trị khác nhau.
Set<String> _pbxValues(String pbx, String name, String bundleId) {
  final values = <String>{};
  final configs = RegExp(
    r'isa = XCBuildConfiguration;.*?\n\t\t\};\n',
    dotAll: true,
  );
  for (final m in configs.allMatches(pbx)) {
    final block = m.group(0)!;
    if (!block.contains('PRODUCT_BUNDLE_IDENTIFIER = $bundleId;')) continue;
    values.add(RegExp('$name = "([^"]*)";').firstMatch(block)!.group(1)!);
  }
  return values;
}

void main() {
  final pbx = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();

  group('Google client ID khớp theo flavor', () {
    for (final MapEntry(key: flavor, value: bundleId) in _flavors.entries) {
      test(flavor, () {
        final plist = File(
          'ios/config/$flavor/GoogleService-Info.plist',
        ).readAsStringSync();
        final json =
            jsonDecode(
                  File(
                    'android/app/src/$flavor/google-services.json',
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        final client = (json['client'] as List).single as Map<String, dynamic>;
        final oauth = (client['oauth_client'] as List)
            .cast<Map<String, dynamic>>();
        final env = File('assets/.env.$flavor').readAsStringSync();

        // Bundle / package khớp flavor.
        expect(_plistValue(plist, 'BUNDLE_ID'), bundleId);
        expect(
          client['client_info']['android_client_info']['package_name'],
          bundleId,
        );

        // iOS: plist == build setting của mọi configuration cùng bundle id.
        final iosId = _plistValue(plist, 'CLIENT_ID');
        final reversed = _plistValue(plist, 'REVERSED_CLIENT_ID');
        expect(iosId, endsWith(_suffix));
        expect(
          reversed,
          'com.googleusercontent.apps.${iosId.replaceAll(_suffix, '')}',
        );
        expect(_pbxValues(pbx, 'GOOGLE_CLIENT_ID', bundleId), {iosId});
        expect(_pbxValues(pbx, 'GOOGLE_REVERSED_CLIENT_ID', bundleId), {
          reversed,
        });

        // Android: google-services.json có client iOS (type 2), Web (type 3).
        final ios = oauth.where((c) => c['client_type'] == 2);
        final web = oauth.where((c) => c['client_type'] == 3);
        expect(web, hasLength(1));
        final webId = web.single['client_id'] as String;
        expect(
          ios.map((c) => c['client_id']),
          anyOf(isEmpty, contains(iosId)),
          reason:
              'client iOS trong google-services.json phải là client của flavor',
        );

        // Web client ID == GOOGLE_SERVER_CLIENT_ID; cùng project number với iOS.
        expect(env, contains('GOOGLE_SERVER_CLIENT_ID=$webId'));
        expect(webId.split('-').first, iosId.split('-').first);
      });
    }

    test('ba flavor dùng ba client khác nhau', () {
      final ids = _flavors.keys.map((f) {
        final env = File('assets/.env.$f').readAsStringSync();
        return RegExp(
          r'GOOGLE_SERVER_CLIENT_ID=(\S+)',
        ).firstMatch(env)!.group(1);
      });
      expect(ids.toSet(), hasLength(3));
    });
  });
}
