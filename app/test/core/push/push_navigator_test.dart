import 'package:app/core/push/push_navigator.dart';
import 'package:app/core/routing/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasco_core/tasco_core.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

const teacher = Membership(
  id: 'm-t',
  role: MembershipRole.tenantOwner,
  label: 'GV',
);
const parent = Membership(id: 'm-p', role: MembershipRole.parent, label: 'PH');

class _Harness {
  _Harness({
    this.authenticated = true,
    this.memberships = const [teacher, parent],
    this.active = teacher,
  });

  bool authenticated;
  List<Membership> memberships;
  Membership? active;
  final selected = <String>[];
  final routes = <String>[];

  late final nav = PushNavigator(
    resolve: (uri) => uri.scheme == 'teachhub' && uri.host == 'p'
        ? DeepLinkTarget(path: '/p${uri.path}')
        : null,
    isAuthenticated: () => authenticated,
    memberships: () => memberships,
    active: () => active,
    select: (m) async {
      selected.add(m.id);
      active = m;
    },
    go: routes.add,
  );
}

void main() {
  setUp(PendingDeepLink.clear);

  test(
    'báo vắng khi đang mở vai trò giáo viên: chuyển sang phụ huynh rồi mở /p',
    () async {
      final h = _Harness();
      await h.nav.handle({'notificationId': 'n1', 'type': 'student_absent'});
      expect(h.selected, ['m-p']);
      expect(h.routes, ['/p']);
    },
  );

  test(
    'invoice_issued (chỉ có notificationId và type) mở danh sách hóa đơn',
    () async {
      final h = _Harness(active: parent);
      await h.nav.handle({'notificationId': 'n1', 'type': 'invoice_issued'});
      expect(h.routes, ['/p/invoices']);
    },
  );

  test(
    'billing_ready (chỉ có notificationId và type) mở kỳ thu của giáo viên',
    () async {
      final h = _Harness(active: parent);
      await h.nav.handle({'notificationId': 'n1', 'type': 'billing_ready'});
      expect(h.selected, ['m-t']);
      expect(h.routes, ['/t/billing']);
    },
  );

  test('đã ở đúng vai trò thì không đổi vai trò', () async {
    final h = _Harness(active: parent);
    await h.nav.handle({
      'notificationId': 'n1',
      'type': 'student_absent_correction',
    });
    expect(h.selected, isEmpty);
    expect(h.routes, ['/p']);
  });

  test(
    'membershipId trong payload chọn đúng vai trò; deepLink mở màn đích',
    () async {
      const parent2 = Membership(
        id: 'm-p2',
        role: MembershipRole.parent,
        label: 'PH2',
      );
      final h = _Harness(memberships: const [teacher, parent, parent2]);
      await h.nav.handle({
        'type': 'student_absent',
        'membershipId': 'm-p2',
        'deepLink': 'teachhub://p/children/1',
      });
      expect(h.selected, ['m-p2']);
      expect(h.routes, ['/p/children/1']);
    },
  );

  test('deepLink không mini-app nào nhận: về trang chủ vai trò', () async {
    final h = _Harness(active: parent);
    await h.nav.handle({
      'type': 'student_absent',
      'deepLink': 'teachhub://p-unknown/x',
    });
    expect(h.routes, ['/p']);
  });

  test('chưa đăng nhập: lưu link chờ và về màn đăng nhập', () async {
    final h = _Harness(authenticated: false, active: null);
    await h.nav.handle({'type': 'student_absent'});
    expect(h.routes, [AppRoutes.login]);
    expect(PendingDeepLink.current?.path, '/p');
    expect(h.selected, isEmpty);
  });

  test('không còn vai trò đích: về trang chủ vai trò đang mở', () async {
    final h = _Harness(memberships: const [teacher]);
    await h.nav.handle({'type': 'student_absent'});
    expect(h.selected, isEmpty);
    expect(h.routes, ['/t']);
  });

  test('loại lạ hoặc payload rỗng bị bỏ qua', () async {
    final h = _Harness();
    await h.nav.handle({'type': 'something_new'});
    await h.nav.handle({});
    expect(h.routes, isEmpty);
    expect(h.selected, isEmpty);
  });

  test('chờ phiên sẵn sàng rồi mới điều hướng', () async {
    final h = _Harness();
    final order = <String>[];
    final nav = PushNavigator(
      resolve: (_) => null,
      isAuthenticated: () => true,
      memberships: () => h.memberships,
      active: () => parent,
      select: (_) async {},
      go: (p) => order.add('go:$p'),
      whenReady: () async {
        order.add('ready');
        return true;
      },
    );
    await nav.handle({'type': 'student_absent'});
    expect(order, ['ready', 'go:/p']);
  });

  test('quá hạn chờ phiên: lưu link chờ, không điều hướng', () async {
    final h = _Harness();
    final nav = PushNavigator(
      resolve: (_) => null,
      isAuthenticated: () => true,
      memberships: () => h.memberships,
      active: () => teacher,
      select: (m) async => h.selected.add(m.id),
      go: h.routes.add,
      whenReady: () async => false,
    );
    await nav.handle({'type': 'student_absent'});
    expect(h.routes, isEmpty);
    expect(h.selected, isEmpty);
    expect(PendingDeepLink.current?.path, '/p');
  });

  test('chưa có vai trò đang mở: không tự chọn thay người dùng', () async {
    final h = _Harness(active: null);
    await h.nav.handle({'type': 'student_absent'});
    expect(h.selected, isEmpty);
    expect(h.routes, ['/p']);
  });
}
