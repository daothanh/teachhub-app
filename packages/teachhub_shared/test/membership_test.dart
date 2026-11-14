import 'package:flutter_test/flutter_test.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

void main() {
  test('parses a known role and maps it to its permission and root route', () {
    final m = Membership.fromJson({
      'id': 'm1',
      'role': 'tenant_owner',
      'label': 'Giáo viên',
      'tenantId': 't1',
    })!;
    expect(m.role, MembershipRole.tenantOwner);
    expect(m.role.permission, 'role:tenant_owner');
    expect(m.role.rootRoute, '/t');
  });

  test('ignores roles this app does not know', () {
    expect(Membership.fromJson({'id': 'm1', 'role': 'center_owner'}), isNull);
    expect(Membership.fromJson({'role': 'parent'}), isNull);
  });
}
