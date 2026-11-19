import 'package:app/core/network/teachhub_logging_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('che họ tên, SĐT, ngày sinh, ghi chú, tên trung tâm, guardians', () {
    final out = TeachHubLoggingInterceptor.redactBody({
      'fullName': 'Nguyễn Minh Anh',
      'dob': '2011-05-20',
      'school': 'THCS',
      'note': 'dị ứng',
      'confirmNew': true,
      'guardians': [
        {'fullName': 'Hải', 'phone': '0912345678'},
      ],
      'centerName': 'Ánh Dương',
      'teacherCount': 8,
      'password': 'x',
    });
    expect(out, {
      'fullName': '***',
      'dob': '***',
      'school': '***',
      'note': '***',
      'confirmNew': true,
      'guardians': '***',
      'centerName': '***',
      'teacherCount': 8,
      'password': '***',
    });
    expect(out.toString(), isNot(contains('Hải')));
  });

  test('che token mời và mã ngắn (bí mật, US-0.12)', () {
    final out = TeachHubLoggingInterceptor.redactBody([
      {'token': 'q3Zp8mT1xV0kLw5Hn2RcYb7JdFgSaE9uXoIiKtUeMhA'},
      {'code': '7K3QZ9XM'},
      {'shortCode': 'ABCD2345', 'url': 'https://dayhoc.app/i#t=SECRETTOK'},
    ]);
    expect(out.toString(), isNot(contains('q3Zp')));
    expect(out.toString(), isNot(contains('7K3Q')));
    expect(out.toString(), isNot(contains('ABCD2345')));
    expect(out.toString(), isNot(contains('SECRETTOK')));
  });
}
