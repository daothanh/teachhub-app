// Mini-app không được phụ thuộc lẫn nhau (spec §3.7, §8.3): chỉ dùng chung qua
// `teachhub_shared` và host shell. Kiểm cả pubspec (dependencies,
// dev_dependencies) lẫn `import`/`export`/`part of` trong lib/, test/,
// integration_test/ của từng mini-app.
//
//   dart tool/check_miniapp_imports.dart [thư mục gốc repo]   # mặc định .. (chạy trong app/)
//
// Thoát mã 1 và liệt kê vi phạm khi có import chéo — dùng làm bước CI (S0-FL-05).
import 'dart:io';

void main(List<String> args) {
  final root = Directory(args.firstOrNull ?? '..');
  final miniApps = Directory('${root.path}/mini_apps');
  if (!miniApps.existsSync()) {
    stderr.writeln('Không thấy ${miniApps.path}');
    exit(2);
  }

  // Tên gói của từng mini-app lấy từ `name:` trong pubspec.
  final packages = <String, Directory>{};
  for (final dir in miniApps.listSync().whereType<Directory>()) {
    final pubspec = File('${dir.path}/pubspec.yaml');
    if (!pubspec.existsSync()) continue;
    final name = RegExp(
      r'^name:\s*(\w+)',
      multiLine: true,
    ).firstMatch(pubspec.readAsStringSync())?.group(1);
    if (name != null) packages[name] = dir;
  }

  final violations = <String>[];
  for (final MapEntry(key: self, value: dir) in packages.entries) {
    final others = packages.keys.where((p) => p != self).toSet();

    final pubspec = File('${dir.path}/pubspec.yaml').readAsLinesSync();
    for (final (i, line) in pubspec.indexed) {
      final dep = RegExp(r'^\s{2}(\w+)\s*:').firstMatch(line)?.group(1);
      if (dep != null && others.contains(dep)) {
        violations.add(
          '${dir.path}/pubspec.yaml:${i + 1}: $self phụ thuộc mini-app $dep',
        );
      }
    }

    for (final sub in ['lib', 'test', 'integration_test']) {
      final src = Directory('${dir.path}/$sub');
      if (!src.existsSync()) continue;
      for (final file in src.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        for (final (i, line) in file.readAsLinesSync().indexed) {
          final pkg = RegExp(
            r'''^\s*(?:import|export|part\s+of)\s+['"]package:(\w+)/''',
          ).firstMatch(line)?.group(1);
          if (pkg != null && others.contains(pkg)) {
            violations.add('${file.path}:${i + 1}: $self import mini-app $pkg');
          }
        }
      }
    }
  }

  if (violations.isEmpty) {
    stdout.writeln(
      'OK: ${packages.length} mini-app (${packages.keys.join(', ')}) không import lẫn nhau.',
    );
    return;
  }
  stderr.writeln(
    'Mini-app import chéo (spec §3.7) — dùng teachhub_shared thay thế:',
  );
  violations.forEach(stderr.writeln);
  exit(1);
}
