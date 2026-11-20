import 'package:app/features/invite/invite_input.dart';
import 'package:flutter_test/flutter_test.dart';

const _token = 'q3Zp8mT1xV0kLw5Hn2RcYb7JdFgSaE9uXoIiKtUeMhA';

String? _tok(String s) => switch (InviteInput.parse(s)) {
  InviteToken(:final value) => value,
  _ => null,
};
String? _code(String s) => switch (InviteInput.parse(s)) {
  InviteCode(:final value) => value,
  _ => null,
};

void main() {
  test('link <base>#t=<token> (dán hoặc quét QR)', () {
    expect(_tok('https://dayhoc.app/i#t=$_token'), _token);
    expect(_tok('  https://dayhoc.app/#t=$_token\n'), _token);
  });

  test('link /i/<token> và token trần', () {
    expect(_tok('https://dayhoc.app/i/$_token'), _token);
    expect(_tok(_token), _token);
  });

  test('mã ngắn 8 ký tự: bỏ khoảng trắng, gạch nối; không nhận ký tự U', () {
    expect(_code('7K3QZ9XM'), '7K3QZ9XM');
    expect(_code(' 7k3q-z9xm '), '7k3qz9xm');
    expect(InviteInput.parse('7K3QZ9XU'), isNull);
    expect(InviteInput.parse('7K3QZ9X'), isNull);
  });

  test('không phải lời mời', () {
    for (final s in [
      '',
      '   ',
      'xin chào',
      'https://example.com/trang',
      'abc',
    ]) {
      expect(InviteInput.parse(s), isNull, reason: s);
    }
  });

  test('toString không lộ bí mật', () {
    expect('${InviteInput.parse(_token)}', isNot(contains(_token)));
    expect('${InviteInput.parse('7K3QZ9XM')}', isNot(contains('7K3Q')));
  });
}
