import 'dart:convert';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tasco_storage/tasco_storage.dart';

/// What this build, on this installation, tells the backend about itself.
///
/// Sent with every request ([headers]) and in the sign-in body ([deviceInfo]).
/// Resolved once at startup from the installed package and a stored
/// installation id, because as literals in source every app generated from
/// this template shipped the same version and the same device id.
final class ClientIdentity extends Equatable {
  const ClientIdentity({
    required this.appVersion,
    required this.deviceId,
    required this.deviceType,
    required this.deviceName,
    this.clientSource = '',
  });

  /// Reads the installed version and this installation's id, creating the id
  /// on first launch.
  ///
  /// [clientSource] is the product's `CLIENT_SOURCE` setting. [packageInfo],
  /// [platform] and [random] exist for tests.
  static Future<ClientIdentity> resolve({
    required KeyValueStore store,
    String clientSource = '',
    Future<PackageInfo> Function() packageInfo = PackageInfo.fromPlatform,
    TargetPlatform? platform,
    Random? random,
  }) async {
    final installed = await packageInfo();
    final isIOS = (platform ?? defaultTargetPlatform) == TargetPlatform.iOS;
    return ClientIdentity(
      appVersion: installed.version,
      deviceId: await _installationId(store, random ?? Random.secure()),
      deviceType: isIOS ? 'ios' : 'android',
      deviceName: isIOS ? 'iPhone' : 'Android',
      clientSource: clientSource,
    );
  }

  /// `version` from pubspec.yaml as installed, without the build number.
  final String appVersion;

  /// Random id created on this installation's first launch. It is not derived
  /// from the hardware, so it identifies an installation and nothing else.
  final String deviceId;

  /// `ios` or `android`.
  final String deviceType;

  /// A platform label (`iPhone`, `Android`), not the device model.
  final String deviceName;

  /// Which client the backend attributes requests to; empty while unset.
  final String clientSource;

  /// The device fields under the names the backend uses, in the
  /// `X-Device-Info` header and in the sign-in body alike.
  Map<String, String> get deviceInfo => {
    'deviceId': deviceId,
    'deviceName': deviceName,
    'deviceType': deviceType,
  };

  /// Headers every service client sends.
  ///
  /// `client_source` is left out while unset rather than sent empty, so an
  /// unconfigured app is refused by the backend instead of passing as another
  /// client.
  Map<String, String> get headers => {
    'X-App-Version': appVersion,
    'X-Device-Info': base64Encode(utf8.encode(jsonEncode(deviceInfo))),
    if (clientSource.isNotEmpty) 'client_source': clientSource,
  };

  /// Storage key of the installation id. Changing it gives every installation
  /// a new id, which the backend sees as a new device.
  static const _deviceIdKey = 'device_id';

  static Future<String> _installationId(
    KeyValueStore store,
    Random random,
  ) async {
    final stored = await store.read(_deviceIdKey);
    if (stored != null && stored.isNotEmpty) return stored;
    final created = _uuidV4(random);
    await store.write(_deviceIdKey, created);
    return created;
  }

  /// A random RFC 4122 version-4 UUID, the format device ids usually take.
  static String _uuidV4(Random random) {
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  @override
  List<Object?> get props => [
    appVersion,
    deviceId,
    deviceType,
    deviceName,
    clientSource,
  ];
}
