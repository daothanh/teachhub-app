import 'package:flutter_test/flutter_test.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

void main() {
  test('cùng draft giữ một khóa, draft đổi hoặc done thì khóa mới', () {
    final k = DraftKeys();
    final a = k.of('claim', 'x');
    expect(k.pending('claim', 'x'), isTrue);
    expect(k.of('claim', 'x'), a);
    final b = k.of('claim', 'y');
    expect(b, isNot(a));
    k.done('claim');
    expect(k.pending('claim', 'y'), isFalse);
    expect(k.of('claim', 'y'), isNot(b));
  });
}
