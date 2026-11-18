import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Dựng repo giả: mini_apps/{a,b}, [pubspecDeps] thêm vào pubspec của `a`,
/// [source] là nội dung `a/lib/a.dart`.
Future<ProcessResult> _run({
  String pubspecDeps = '',
  String source = '',
}) async {
  final root = Directory.systemTemp.createTempSync('miniapp_check');
  addTearDown(() => root.deleteSync(recursive: true));
  for (final name in ['a', 'b']) {
    Directory('${root.path}/mini_apps/$name/lib').createSync(recursive: true);
    File('${root.path}/mini_apps/$name/pubspec.yaml').writeAsStringSync(
      'name: $name\ndependencies:\n  flutter:\n    sdk: flutter\n'
      '  teachhub_shared:\n    path: ../../packages/teachhub_shared\n'
      '${name == 'a' ? pubspecDeps : ''}',
    );
  }
  File('${root.path}/mini_apps/a/lib/a.dart').writeAsStringSync(source);
  return Process.run('dart', ['tool/check_miniapp_imports.dart', root.path]);
}

void main() {
  test('repo thật: không mini-app nào import lẫn nhau', () async {
    final r = await Process.run('dart', [
      'tool/check_miniapp_imports.dart',
      '..',
    ]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect('${r.stdout}', contains('teacher'));
  });

  test('chỉ dùng teachhub_shared → đạt', () async {
    final r = await _run(
      source: "import 'package:teachhub_shared/teachhub_shared.dart';",
    );
    expect(r.exitCode, 0, reason: '${r.stderr}');
  });

  test('import package của mini-app khác → đỏ, chỉ rõ file và dòng', () async {
    final r = await _run(source: "\nimport 'package:b/b.dart';");
    expect(r.exitCode, 1);
    expect('${r.stderr}', contains('a/lib/a.dart:2: a import mini-app b'));
  });

  test('export hoặc khai phụ thuộc mini-app khác trong pubspec → đỏ', () async {
    expect((await _run(source: "export 'package:b/b.dart';")).exitCode, 1);
    final r = await _run(pubspecDeps: '  b:\n    path: ../b\n');
    expect(r.exitCode, 1);
    expect('${r.stderr}', contains('a phụ thuộc mini-app b'));
  });
}
