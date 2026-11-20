import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Bản chép `contracts/openapi.json` phải khớp backend (chạy đúng logic của
/// `dart run tool/sync_openapi.dart --check`).
void main() {
  const backend = '../../../teachhub-backend/contracts/openapi.json';
  final hasBackend = File(backend).existsSync();

  test(
    'bản chép openapi.json khớp teachhub-backend',
    () {
      final r = Process.runSync('dart', [
        'run',
        'tool/sync_openapi.dart',
        '--check',
      ]);
      expect(r.exitCode, 0, reason: '${r.stderr}');
    },
    skip: hasBackend
        ? false
        : 'không có $backend (repo backend không nằm cạnh repo app, vd. CI)',
  );
}
