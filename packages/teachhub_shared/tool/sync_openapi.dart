// Chép `contracts/openapi.json` của teachhub-backend (nguồn duy nhất, spec §5)
// vào `contracts/openapi.json` để test mô hình auth/membership đối chiếu.
//
//   dart run tool/sync_openapi.dart [đường dẫn openapi.json]
//   dart run tool/sync_openapi.dart --check   # đỏ nếu bản chép lệch backend
import 'dart:io';

const _snapshot = 'contracts/openapi.json';

void main(List<String> args) {
  final source =
      args.where((a) => !a.startsWith('--')).firstOrNull ??
      '../../../teachhub-backend/contracts/openapi.json';
  final raw = File(source).readAsStringSync();
  if (args.contains('--check')) {
    if (!File(_snapshot).existsSync() ||
        File(_snapshot).readAsStringSync() != raw) {
      stderr.writeln(
        '$_snapshot lệch backend — chạy dart run tool/sync_openapi.dart',
      );
      exit(1);
    }
    return;
  }
  File(_snapshot).writeAsStringSync(raw);
  stdout.writeln('Đã chép openapi.json → $_snapshot');
}
