import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:app/core/config/client_identity.dart';
import 'package:tasco_storage/tasco_storage.dart';

Future<PackageInfo> _installed() async => PackageInfo(
  appName: 'Shell',
  packageName: 'vn.com.tasco.teachhub',
  version: '3.4.5',
  buildNumber: '67',
);

final _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  late InMemoryKeyValueStore store;

  setUp(() => store = InMemoryKeyValueStore());

  Future<ClientIdentity> resolve({
    TargetPlatform platform = TargetPlatform.android,
    String clientSource = '',
    Random? random,
  }) => ClientIdentity.resolve(
    store: store,
    clientSource: clientSource,
    packageInfo: _installed,
    platform: platform,
    random: random,
  );

  group('ClientIdentity.resolve', () {
    test('reports the installed version without the build number', () async {
      expect((await resolve()).appVersion, '3.4.5');
    });

    test(
      'creates a UUID installation id on first launch and keeps it',
      () async {
        final first = await resolve();
        final second = await resolve();

        expect(first.deviceId, matches(_uuidV4));
        expect(second.deviceId, first.deviceId);
        // The stored key is part of the contract: renaming it would give every
        // installation a new id, which the backend reads as a new device.
        expect(await store.read('device_id'), first.deviceId);
      },
    );

    test('two installations get different ids', () async {
      final one = await resolve(random: Random(1));
      store = InMemoryKeyValueStore();
      final other = await resolve(random: Random(2));

      expect(one.deviceId, isNot(other.deviceId));
    });

    test('replaces a blank stored id instead of sending it', () async {
      await store.write('device_id', '');

      final identity = await resolve();

      expect(identity.deviceId, matches(_uuidV4));
      expect(await store.read('device_id'), identity.deviceId);
    });

    test('derives the device type and name from the platform', () async {
      final ios = await resolve(platform: TargetPlatform.iOS);
      final android = await resolve(platform: TargetPlatform.android);

      expect((ios.deviceType, ios.deviceName), ('ios', 'iPhone'));
      expect((android.deviceType, android.deviceName), ('android', 'Android'));
    });
  });

  group('ClientIdentity wire format', () {
    const identity = ClientIdentity(
      appVersion: '3.4.5',
      deviceId: '0b7e4f1c-3c5d-4e8a-9f10-2a3b4c5d6e7f',
      deviceType: 'ios',
      deviceName: 'iPhone',
      clientSource: 'app_Product',
    );

    test('deviceInfo uses the backend field names', () {
      expect(identity.deviceInfo, {
        'deviceId': '0b7e4f1c-3c5d-4e8a-9f10-2a3b4c5d6e7f',
        'deviceName': 'iPhone',
        'deviceType': 'ios',
      });
    });

    test(
      'headers carry the version, the encoded device info and the source',
      () {
        final headers = identity.headers;

        expect(headers['X-App-Version'], '3.4.5');
        expect(headers['client_source'], 'app_Product');
        final deviceInfo = jsonDecode(
          utf8.decode(base64Decode(headers['X-Device-Info']!)),
        );
        expect(deviceInfo, identity.deviceInfo);
      },
    );

    test('client_source is left out while CLIENT_SOURCE is unset', () {
      const unconfigured = ClientIdentity(
        appVersion: '3.4.5',
        deviceId: 'id',
        deviceType: 'android',
        deviceName: 'Android',
      );

      expect(unconfigured.headers.keys, ['X-App-Version', 'X-Device-Info']);
    });
  });
}
