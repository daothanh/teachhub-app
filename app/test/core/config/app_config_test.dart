import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('frameworkVersion is a valid non-empty SemVer string', () {
      expect(AppConfig.frameworkVersion, isNotEmpty);
      final semverRegex = RegExp(r'^\d+\.\d+\.\d+(-[a-zA-Z0-9.]+)?$');
      expect(
        semverRegex.hasMatch(AppConfig.frameworkVersion),
        isTrue,
        reason: '${AppConfig.frameworkVersion} must match SemVer format',
      );
    });
  });
}
